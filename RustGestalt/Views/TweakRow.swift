import SwiftUI

struct TweakRow: View {
    @Environment(\.theme) private var theme
    let tweak: Tweak
    var onToggle: ((Bool) -> Void)? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: tweak.category.symbolName)
                .font(.system(size: 18))
                .foregroundStyle(theme.accent)
                .frame(width: 32, height: 32)
                .background(Circle().fill(theme.accent.opacity(0.15)))

            VStack(alignment: .leading, spacing: 4) {
                Text(tweak.title)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
                    badge(text: tweak.status.rawValue, color: .orange)
                    badge(text: tweak.risk.rawValue + " risk", color: riskColor(tweak.risk))
                }
            }

            Spacer()

            if let onToggle {
                Toggle("", isOn: Binding(get: { tweak.isEnabled }, set: onToggle))
                    .labelsHidden()
                    .tint(theme.accent)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial))
    }

    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    private func riskColor(_ risk: RiskLevel) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
