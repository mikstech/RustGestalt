import Foundation

/// The payload encoded in a Desktop Companion pairing QR code, per the project spec:
/// rustgestalt://pair?code=XXXX&host=<local-ip>&fp=<device-fingerprint>
///
/// Validated address and pin for the Desktop Companion's trusted connection.
struct PairingPayload: Equatable {
    let code: String
    let host: String
    let fingerprint: String

    static let scheme = "rustgestalt"
    static let host_ = "pair"

    enum ParseError: LocalizedError {
        case notRustGestaltURL
        case missingField(String)
        case malformedCode

        var errorDescription: String? {
            switch self {
            case .notRustGestaltURL:
                return "That QR code isn't a RustGestalt pairing code."
            case .missingField(let field):
                return "Pairing code is missing its \(field)."
            case .malformedCode:
                return "Pairing code format looks wrong."
            }
        }
    }

    /// Parses a scanned string (from a QR code or manual 4-digit-code flow) into a payload.
    static func parse(_ raw: String) throws -> PairingPayload {
        guard let url = URL(string: raw),
              url.scheme?.lowercased() == scheme,
              (url.host?.lowercased() == host_) else {
            throw ParseError.notRustGestaltURL
        }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        func value(_ name: String) throws -> String {
            guard let v = items.first(where: { $0.name == name })?.value, !v.isEmpty else {
                throw ParseError.missingField(name)
            }
            return v
        }
        let code = try value("code")
        let host = try value("host")
        let fp = try value("fp")
        guard code.count == 4, code.allSatisfy(\.isNumber) else {
            throw ParseError.malformedCode
        }
        return PairingPayload(code: code, host: host, fingerprint: fp)
    }

    /// Builds the pairing URL for the Desktop Companion QR flow.
    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host_
        components.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "host", value: host),
            URLQueryItem(name: "fp", value: fingerprint),
        ]
        return components.url!
    }
}
