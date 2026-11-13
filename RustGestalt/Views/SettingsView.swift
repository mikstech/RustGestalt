import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var appState: AppState
    @AppStorage("themePreset") private var presetRaw: String = ThemePreset.rust.rawValue
    @State private var previewPreset: ThemePreset?

    var body: some View {
        List {
            Section("Appearance") {
                ThemePickerRow(selected: Binding(
                    get: { ThemePreset(rawValue: presetRaw) ?? .rust },
                    set: { presetRaw = $0.rawValue }
                )) { previewPreset = $0 }
            }

            Section("Desktop Companion") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(appState.isPaired ? "Connected" : "Not paired")
                        .foregroundStyle(appState.isPaired ? .green : .secondary)
                }
                if appState.isPaired {
                    Button("Unpair", role: .destructive) {
                        appState.isPaired = false
                    }
                }
            }

            Section("Backup & Restore") {
                NavigationLink("Backup History") {
                    BackupHistoryView()
                }
                Text("The Mac's full-device backup history is separate from MobileGestalt Studio's on-device cache backups.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("About") {
                LabeledContent("Version", value: "0.1.0 (beta)")
                Text("MobileGestalt Studio includes selected GestaltX implementation source under GPL-3.0-only. Its exact-build behavior is not yet tested by RustGestalt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .sheet(item: $previewPreset) { preset in
            ThemePreviewSheet(preset: preset, selected: ThemePreset(rawValue: presetRaw) ?? .rust) {
                presetRaw = preset.rawValue
            }
        }
    }
}

private struct ThemePickerRow: View {
    @Binding var selected: ThemePreset
    var onPreview: (ThemePreset) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 14) {
            ForEach(ThemePreset.gallery) { preset in
                Button {
                    onPreview(preset)
                } label: {
                    VStack(spacing: 6) {
                        Circle()
                            .fill(preset.swatch)
                            .frame(width: 32, height: 32)
                            .overlay {
                                if preset == selected {
                                    Circle().stroke(.primary, lineWidth: 2).padding(-3)
                                }
                            }
                        Text(preset.displayName).font(.caption2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
          }
        }
        .padding(.vertical, 6)
    }
}

private struct ThemePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let preset: ThemePreset
    let selected: ThemePreset
    let apply: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text(preset.description).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    previewCard(scheme: .light, label: "Light")
                    previewCard(scheme: .dark, label: "Dark")
                }
                Button(selected == preset ? "Selected" : "Apply Theme") { apply(); dismiss() }
                    .buttonStyle(.borderedProminent).tint(preset.accent)
                    .disabled(selected == preset)
                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle(preset.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium])
    }

    private func previewCard(scheme: ColorScheme, label: String) -> some View {
        let colors = Theme.resolve(preset, scheme: scheme)
        return VStack(alignment: .leading, spacing: 10) {
            Text(label).font(.caption.weight(.semibold))
                .foregroundStyle(scheme == .dark ? .white : .primary)
            RoundedRectangle(cornerRadius: 12).fill(colors.surfaceElevated)
                .frame(height: 70)
                .overlay(alignment: .leading) {
                    HStack(spacing: 8) {
                        Circle().fill(colors.accent).frame(width: 24, height: 24)
                        Text("RustGestalt").font(.caption.weight(.medium))
                            .foregroundStyle(scheme == .dark ? .white : .primary)
                    }.padding(10)
                }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(colors.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct BackupHistoryView: View {
    var body: some View {
        List {
            ContentUnavailableView("Backup history isn't connected", systemImage: "externaldrive.badge.questionmark",
                                    description: Text("The Mac companion manages supported device backups. Their history is not yet synchronized to this iPhone screen."))
        }
        .navigationTitle("Backup History")
    }
}
