import SwiftUI

struct TweakDetailView: View {
    @Environment(\.theme) private var theme
    let tweak: Tweak

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                plistKeyCard
                compatibilityCard
                implementationNotice
            }
            .padding(20)
        }
        .background(theme.surface.ignoresSafeArea())
        .navigationTitle(tweak.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                badge(tweak.risk.rawValue, riskColor(tweak.risk))
                badge(tweak.status.rawValue, tweak.status == .experimental ? .orange : .green)
            }
            Text(tweak.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var plistKeyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reference keys").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack {
                Text(tweak.plistKey)
                    .font(.footnote.monospaced())
                if !tweak.isKeyVerified {
                    badge("Unverified", .red)
                }
            }
            Text(tweak.isKeyVerified
                 ? "Appears in multiple supplied source catalogs. This confirms the reference mapping only, not whether the change works on your device."
                 : "Appears in one supplied source catalog only; independent key confirmation is missing.")
                .font(.caption2).foregroundStyle(.secondary)
            Text(tweak.sourceReferences).font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
    }

    private var compatibilityCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compatibility").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            compatibilityRow("iOS 18", tweak.ios18)
            compatibilityRow("iOS 26", tweak.ios26)
            compatibilityRow("iOS 27", tweak.ios27)
            Text(tweak.sourceCompatibility).font(.caption).foregroundStyle(.secondary)
            Text("Device requirements: \(tweak.deviceConditions)").font(.caption).foregroundStyle(.secondary)
            Text(tweak.restartRequired ? "A device restart may be required." : "A restart requirement is not established.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
    }

    private var implementationNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Reference only", systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold)).foregroundStyle(theme.accent)
            Text(tweak.status.detail)
                .font(.footnote).foregroundStyle(.secondary)
            Text("This reference screen did not make a change. Use MobileGestalt Studio to stage and apply supported GestaltX presets.")
                .font(.caption.weight(.medium)).foregroundStyle(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
    }

    private func compatibilityRow(_ title: String, _ status: CompatibilityStatus) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(status.rawValue).foregroundStyle(status == .unsupported ? .red : .secondary)
        }.font(.subheadline)
    }

    private func badge(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.15)))
            .foregroundStyle(color)
    }

    private func riskColor(_ risk: RiskLevel) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
