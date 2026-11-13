import SwiftUI

struct PairingView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var appState: AppState
    @StateObject private var pairing = PairingManager()
    @State private var showManualEntry = false
    @State private var showDevHelper = false

    var body: some View {
        ZStack {
            theme.surface.ignoresSafeArea()

            VStack(spacing: 24) {
                header

                switch pairing.state {
                case .idle:
                    idleCard
                case .scanning:
                    scannerCard
                case .validating, .connecting:
                    connectingCard
                case .paired(let payload):
                    pairedCard(payload)
                case .failed(let message):
                    failedCard(message)
                }

                Spacer()

                Button {
                    showManualEntry = true
                } label: {
                    Text("Enter code manually")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(theme.accent)
                }

                #if DEBUG
                Button {
                    showDevHelper = true
                } label: {
                    Text("Dev: show a test pairing QR")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button {
                    appState.isPaired = true
                } label: {
                    Text("Dev: skip pairing to preview the rest of the app")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                #endif
            }
            .padding(24)
        }
        .onAppear {
            pairing.onSessionAvailable = { session in appState.startStatusSync(session) }
            pairing.restoreSessionIfAvailable()
        }
        .onChange(of: pairing.state) { _, newState in
            if case .paired = newState { appState.isPaired = true }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntrySheet(pairing: pairing)
        }
        #if DEBUG
        .sheet(isPresented: $showDevHelper) {
            DevQRPreviewSheet()
        }
        #endif
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 36))
                .foregroundStyle(theme.accent)
            Text("Pair with Desktop Companion")
                .font(.title2.bold())
            Text("Pair with the Desktop Companion to sync the iPhone model and exact iOS build. The reference library is read-only; on-device edits live in MobileGestalt Studio.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var idleCard: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(height: 280)
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 48))
                            .foregroundStyle(theme.accent)
                        Text("Ready to scan")
                            .font(.headline)
                    }
                }
            Button {
                pairing.beginScanning()
            } label: {
                Label("Scan Pairing Code", systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.accent)
        }
    }

    private var scannerCard: some View {
        VStack(spacing: 16) {
            ZStack {
                QRScannerView { code in
                    pairing.handleScannedString(code)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(theme.accent, lineWidth: 3)
                    .padding(40)
            }
            .frame(height: 340)

            Text("Point your camera at the QR code in the Desktop Companion window.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Cancel", role: .cancel) { pairing.cancel() }
                .font(.footnote)
        }
    }

    private var connectingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Connecting to Desktop Companion…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Cancel", role: .cancel) { pairing.cancel() }
                .font(.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func pairedCard(_ payload: PairingPayload) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Paired")
                .font(.title3.bold())
            Text(payload.host)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func failedCard(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                pairing.cancel()
            }
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 30)
    }
}

private struct ManualEntrySheet: View {
    @ObservedObject var pairing: PairingManager
    @Environment(\.dismiss) private var dismiss
    @State private var host: String = ""
    @State private var fingerprint: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("4-digit code", text: $pairing.manualCode)
                        .keyboardType(.numberPad)
                    TextField("Host (e.g. 192.168.1.42)", text: $host)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                    TextField("Fingerprint", text: $fingerprint)
                        .autocorrectionDisabled()
                } header: {
                    Text("From the Desktop Companion window")
                } footer: {
                    Text("These three values come from the same pairing session as the QR code — not a separate mechanism.")
                }
            }
            .navigationTitle("Enter Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        pairing.submitManualEntry(host: host, fingerprint: fingerprint)
                        dismiss()
                    }
                    .disabled(host.isEmpty || fingerprint.isEmpty)
                }
            }
        }
    }
}

#if DEBUG
/// Dev-only: renders a real scannable QR for a made-up test payload so the scan
/// pipeline can be exercised without a built Desktop Companion.
private struct DevQRPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let samplePayload = PairingPayload(code: "4821", host: "192.168.1.42:51820", fingerprint: "SHA256:TESTFINGERPRINTONLY")

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = DevQRCodeGenerator.image(for: samplePayload) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                }
                Text(samplePayload.url.absoluteString)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text("This is a fake payload for testing the scanner only — there's no real Companion behind it, so pairing will fail at the connect step. That's expected.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Dev Test QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
#endif
