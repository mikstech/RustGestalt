import Foundation
import Combine
import CoreImage.CIFilterBuiltins
import UIKit
import CryptoKit
import Security

enum PairingState: Equatable {
    case idle
    case scanning
    case validating(PairingPayload)
    case connecting(PairingPayload)
    case paired(PairingPayload)
    case failed(String)
}

struct PairingSession: Codable {
    let host: String
    let fingerprint: String
    let token: String

    var payload: PairingPayload {
        PairingPayload(code: "", host: host, fingerprint: fingerprint)
    }
}

/// Owns the pairing flow end to end: receiving a scanned/typed code, parsing it into a
/// `PairingPayload`, then connecting with the companion certificate fingerprint
/// supplied in the QR code.
@MainActor
final class PairingManager: ObservableObject {
    @Published private(set) var state: PairingState = .idle
    @Published var manualCode: String = ""
    var onSessionAvailable: ((PairingSession) -> Void)?

    private var connectionTask: Task<Void, Never>?

    func handleScannedString(_ raw: String) {
        guard case .scanning = state else { return }
        do {
            let payload = try PairingPayload.parse(raw)
            state = .validating(payload)
            connect(to: payload)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func beginScanning() {
        state = .scanning
    }

    func restoreSessionIfAvailable() {
        guard let session = Self.loadSession() else { return }
        state = .paired(session.payload)
        onSessionAvailable?(session)
    }

    func cancel() {
        connectionTask?.cancel()
        state = .idle
    }

    /// Manual-entry fallback: per the project spec, the 4-digit code maps to the same
    /// short-lived pairing mechanism as the QR — it is not a separate code path. Since
    /// there's no discovery mechanism yet to resolve a bare 4-digit code to a host, this
    /// expects the user to have host/fingerprint from the Companion window too (e.g. it
    /// could show "192.168.1.42 · 4821" alongside its QR). Once local network service
    /// discovery (Bonjour) is added on the Companion side, this can resolve host
    /// automatically from the code alone.
    func submitManualEntry(host: String, fingerprint: String) {
        guard manualCode.count == 4, manualCode.allSatisfy(\.isNumber) else {
            state = .failed("Enter the 4-digit code shown in the Desktop Companion window.")
            return
        }
        let payload = PairingPayload(code: manualCode, host: host, fingerprint: fingerprint)
        state = .validating(payload)
        connect(to: payload)
    }

    private func connect(to payload: PairingPayload) {
        connectionTask?.cancel()
        connectionTask = Task { [weak self] in
            guard let self else { return }
            self.state = .connecting(payload)
            do {
                let token = try await Self.attemptHandshake(payload)
                if Task.isCancelled { return }
                let session = PairingSession(host: payload.host, fingerprint: payload.fingerprint.lowercased(), token: token)
                try Self.storeSession(session)
                self.state = .paired(payload)
                self.onSessionAvailable?(session)
            } catch {
                if Task.isCancelled { return }
                self.state = .failed("Pairing failed: \(error.localizedDescription)")
            }
        }
    }

    private static func attemptHandshake(_ payload: PairingPayload) async throws -> String {
        let hostParts = payload.host.split(separator: ":", omittingEmptySubsequences: false)
        guard !hostParts.isEmpty,
              let port = hostParts.count > 1 ? Int(hostParts[1]) : 51820,
              (1...65535).contains(port),
              payload.fingerprint.count == 64,
              payload.fingerprint.allSatisfy({ $0.isHexDigit }) else {
            throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "The pairing address or certificate fingerprint is invalid."])
        }
        var components = URLComponents()
        components.scheme = "https"
        components.host = String(hostParts[0])
        components.port = port
        components.path = "/rustgestalt/handshake"
        components.queryItems = [URLQueryItem(name: "code", value: payload.code)]
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let delegate = FingerprintPinningDelegate(expectedFingerprint: payload.fingerprint.lowercased())
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        let result = try JSONDecoder().decode(HandshakeResponse.self, from: data)
        guard http.statusCode == 200, result.status == "paired",
              let token = result.token, token.count == 64 else {
            let message = result.status == "locked" ? "The Mac temporarily locked pairing after incorrect codes." :
                result.status == "expired" ? "The pairing code expired. Display a new code on the Mac and scan again." :
                "The Mac rejected the pairing code (HTTP \(http.statusCode))."
            throw URLError(.userAuthenticationRequired, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return token
    }

    private struct HandshakeResponse: Decodable {
        let status: String
        let token: String?
    }

    private static let sessionAccount = "desktop-companion-session"

    private static func storeSession(_ session: PairingSession) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.rustgestalt.app",
                                    kSecAttrAccount as String: sessionAccount]
        SecItemDelete(query as CFDictionary)
        var item = query
        item[kSecValueData as String] = try JSONEncoder().encode(session)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
            throw URLError(.cannotWriteToFile, userInfo: [NSLocalizedDescriptionKey: "The trusted Desktop Companion session could not be saved securely."])
        }
    }

    private static func loadSession() -> PairingSession? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.rustgestalt.app",
                                    kSecAttrAccount as String: sessionAccount,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(PairingSession.self, from: data)
    }

    static func clearStoredSession() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.rustgestalt.app",
                                    kSecAttrAccount as String: sessionAccount]
        SecItemDelete(query as CFDictionary)
    }
}

final class FingerprintPinningDelegate: NSObject, URLSessionDelegate {
    private let expectedFingerprint: String

    init(expectedFingerprint: String) {
        self.expectedFingerprint = expectedFingerprint
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust,
              let certificates = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let leaf = certificates.first else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let fingerprint = SHA256.hash(data: SecCertificateCopyData(leaf) as Data)
            .map { String(format: "%02x", $0) }.joined()
        guard fingerprint == expectedFingerprint else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
}

/// Dev-only helper so the Pairing screen is testable before a real Desktop Companion
/// exists: renders a `PairingPayload` as an actual scannable QR image using CoreImage,
/// so you can display it on a second device/simulator and scan it with this app. This
/// is NOT how pairing works in production (the Companion generates the real one) — it's
/// purely so the scan -> parse -> connect pipeline can be exercised end to end today.
enum DevQRCodeGenerator {
    static func image(for payload: PairingPayload, scale: CGFloat = 10) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.url.absoluteString.utf8)
        guard let outputImage = filter.outputImage else { return nil }
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
