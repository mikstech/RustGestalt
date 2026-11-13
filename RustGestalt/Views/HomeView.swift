import SwiftUI

struct HomeView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                compatibilityBanner
                deviceStatusCard
                quickStatsRow
                appliedModificationsSection
            }
            .padding(20)
        }
        .background(theme.surface.ignoresSafeArea())
        .navigationTitle("RustGestalt")
    }

    private var compatibilityBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: appState.device.isConnected && appState.statusError == nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.statusError == nil && appState.device.isConnected ? "Device details synced" : "Device details unavailable")
                        .font(.subheadline.bold()).foregroundStyle(.white)
                    Text(appState.statusError ?? appState.statusMessage ?? (appState.isPaired ? "Waiting for the Mac to report its connected iPhone." : "Pair with the Desktop Companion to sync the device."))
                        .font(.caption).foregroundStyle(.white.opacity(0.9))
                }
            }
            if appState.isPaired {
                Button {
                    appState.retryStatusSync()
                } label: {
                    if appState.isRefreshingStatus { ProgressView().tint(.white) }
                    else { Label("Retry device sync", systemImage: "arrow.clockwise").font(.caption.weight(.semibold)) }
                }
                .disabled(appState.isRefreshingStatus)
                .tint(.white)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(appState.statusError == nil && appState.device.isConnected ? Color.green.opacity(0.82) : Color.red.opacity(0.85)))
    }

    private var deviceStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.device.name)
                        .font(.headline)
                    Text(appState.device.isConnected
                         ? "Model ID \(appState.device.productType) · iOS \(appState.device.iosVersion) (\(appState.device.build))"
                         : "\(appState.computerName) · waiting for iPhone details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if appState.device.isConnected && !appState.device.hardwareModel.isEmpty {
                        Text("Hardware ID \(appState.device.hardwareModel)")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                statusPill
            }
            Divider()
            HStack {
                Label(appState.isPaired ? "Desktop Companion connected" : "Desktop Companion not paired",
                      systemImage: appState.isPaired ? "checkmark.circle.fill" : "xmark.circle")
                    .font(.footnote)
                    .foregroundStyle(appState.isPaired ? .green : .secondary)
                Spacer()
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.ultraThinMaterial))
    }

    private var statusPill: some View {
        Text(appState.compatibilityLabel)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.gray.opacity(0.16)))
            .foregroundStyle(.secondary)
    }

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            statTile(value: "0", label: "Applied")
            statTile(value: "\(MockTweakData.tweaks.count)", label: "Reference entries")
            statTile(value: appState.device.build.isEmpty ? "—" : appState.device.build, label: "Detected build")
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
    }

    private var appliedModificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MobileGestalt Studio")
                .font(.headline)
            Text("Open MobileGestalt Studio to read the on-device cache, review GestaltX presets, and restore a saved MobileGestalt backup.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
        }
    }
}
