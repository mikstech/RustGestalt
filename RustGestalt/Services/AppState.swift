import Foundation
import Combine
import CryptoKit
import Security

struct DeviceInfo {
    var name: String
    var productType: String
    var hardwareModel: String
    var iosVersion: String
    var build: String
    var isConnected: Bool
}

/// The paired Mac is the source of USB device details. This state polls its authenticated
/// status endpoint and keeps device detection separate from per-tweak compatibility.
@MainActor
final class AppState: ObservableObject {
    @Published var device = DeviceInfo(name: "No device data", productType: "", hardwareModel: "", iosVersion: "", build: "", isConnected: false)
    @Published var isPaired: Bool = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var statusError: String?
    @Published private(set) var computerName = "Desktop Companion"
    @Published private(set) var lastSync: Date?
    @Published private(set) var isRefreshingStatus = false

    private var pairingSession: PairingSession?
    private var statusTask: Task<Void, Never>?

    var compatibilityLabel: String {
        guard isPaired else { return "Not paired" }
        if statusError != nil { return "Device details unavailable" }
        guard device.isConnected else { return "iPhone not detected" }
        guard !device.productType.isEmpty, !device.iosVersion.isEmpty, !device.build.isEmpty else { return "Device details incomplete" }
        return "Build identified · see MobileGestalt Studio"
    }

    func startStatusSync(_ session: PairingSession) {
        pairingSession = session
        isPaired = true
        statusTask?.cancel()
        statusTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshDeviceStatus()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard !Task.isCancelled else { break }
                await self.refreshDeviceStatus()
            }
        }
    }

    func retryStatusSync() {
        Task { await refreshDeviceStatus() }
    }

    private func refreshDeviceStatus() async {
        guard let pairingSession, !isRefreshingStatus else { return }
        isRefreshingStatus = true
        defer { isRefreshingStatus = false }
        do {
            let parts = pairingSession.host.split(separator: ":", omittingEmptySubsequences: false)
            guard let host = parts.first, !host.isEmpty,
                  let port = parts.count > 1 ? Int(parts[1]) : 51820,
                  (1...65535).contains(port),
                  pairingSession.fingerprint.count == 64,
                  pairingSession.fingerprint.allSatisfy({ $0.isHexDigit }) else {
                throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "The saved companion address or certificate fingerprint is invalid."])
            }
            var components = URLComponents()
            components.scheme = "https"
            components.host = String(host)
            components.port = port
            components.path = "/rustgestalt/status"
            guard let url = components.url else { throw URLError(.badURL) }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10
            request.setValue("Bearer \(pairingSession.token)", forHTTPHeaderField: "Authorization")

            let delegate = FingerprintPinningDelegate(expectedFingerprint: pairingSession.fingerprint.lowercased())
            let urlSession = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
            defer { urlSession.finishTasksAndInvalidate() }
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            if http.statusCode == 401 {
                statusTask?.cancel()
                pairingSession = nil
                isPaired = false
                statusError = "The Desktop Companion revoked this pairing. Pair again to reconnect."
                PairingManager.clearStoredSession()
                return
            }
            guard http.statusCode == 200 else {
                throw URLError(.badServerResponse, userInfo: [NSLocalizedDescriptionKey: "The Desktop Companion status request returned HTTP \(http.statusCode)."])
            }
            let result = try JSONDecoder().decode(CompanionStatus.self, from: data)
            guard result.status == "ok" else {
                throw URLError(.cannotParseResponse, userInfo: [NSLocalizedDescriptionKey: "The Desktop Companion returned an invalid status response."])
            }
            computerName = result.computerName ?? "Desktop Companion"
            lastSync = Date()
            guard result.deviceConnected == true else {
                device = DeviceInfo(name: "No iPhone detected", productType: "", hardwareModel: "", iosVersion: "", build: "", isConnected: false)
                statusError = result.deviceError ?? "The Mac is paired, but it cannot currently see an iPhone over USB. Connect and trust the iPhone, then retry."
                statusMessage = nil
                return
            }
            let missing = [
                result.deviceName == nil ? "device name" : nil,
                result.productType == nil ? "product model identifier" : nil,
                result.iosVersion == nil ? "iOS version" : nil,
                result.build == nil ? "exact build number" : nil
            ].compactMap { $0 }
            device = DeviceInfo(name: result.deviceName ?? "Connected iPhone",
                                productType: result.productType ?? "",
                                hardwareModel: result.hardwareModel ?? "",
                                iosVersion: result.iosVersion ?? "",
                                build: result.build ?? "",
                                isConnected: true)
            if !missing.isEmpty {
                statusError = "The Mac detected the iPhone but its status response is missing: \(missing.joined(separator: ", "))."
                statusMessage = nil
            } else {
                statusError = nil
                statusMessage = "Device details synced. Per-feature MobileGestalt compatibility is still unknown, and RustGestalt has no apply path."
            }
        } catch {
            statusError = "Could not sync device details: \(error.localizedDescription)"
            statusMessage = nil
        }
    }
}

private struct CompanionStatus: Decodable {
    let status: String
    let computerName: String?
    let deviceConnected: Bool?
    let deviceName: String?
    let productType: String?
    let hardwareModel: String?
    let iosVersion: String?
    let build: String?
    let deviceError: String?
}
