import SwiftUI
import UIKit
import Darwin

struct MobileGestaltStudioView: View {
    @StateObject private var manager = GestaltManager()
    @AppStorage("RustGestalt.MGWarningAccepted") private var acceptedRiskNotice = false
    @State private var showingRiskNotice = false
    @State private var showingReview = false
    @State private var confirmingApply = false
    @State private var restoreCandidate: BackupRecord?
    @State private var confirmingRestore = false

    private var osVersion: OperatingSystemVersion { ProcessInfo.processInfo.operatingSystemVersion }
    private var currentBuild: String { Self.kernelBuild ?? "Unavailable" }
    private var buildReference: String? {
        let known: [String: String] = [
            "24A437": "iOS 27.0",
            "24A446": "iOS 27.0.1",
            "24B119": "iOS 27.2",
            "24B91020": "iOS 27.2",
            "24B156": "iOS 27.2.1",
            "24B91034": "iOS 27.2.1",
            "24C5037i": "iOS 27.3 beta 1"
        ]
        return known[currentBuild]
    }
    private var deviceProductType: String {
        manager.snapshot?.document.extra[GestaltKeys.productType] as? String ?? "Read the device cache to identify"
    }
    private var isWithinUpstreamVersionRange: Bool {
        guard osVersion.majorVersion == 27, currentBuild != "Unavailable" else { return false }
        if osVersion.minorVersion < 2 { return true }
        if osVersion.minorVersion == 2 { return osVersion.patchVersion <= 1 }
        return osVersion.minorVersion == 3 && currentBuild == "24C5037i"
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("On-device MobileGestalt access")
                        .font(.headline)
                    Text("GestaltX’s GPL-3.0 implementation reads the device cache, stages changes, saves a verified pre-write backup, and checks the result after writing.")
                        .font(.footnote).foregroundStyle(.secondary)
                    LabeledContent("iOS", value: "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")
                    LabeledContent("Build", value: currentBuild)
                    LabeledContent("Build check", value: buildReference ?? "No exact reference match")
                    if manager.hasDocument { LabeledContent("Device", value: deviceProductType) }
                    Text(isWithinUpstreamVersionRange
                         ? "This version is within Erosion’s stated range. RustGestalt has not independently verified this exact build or device."
                         : "This exact version/build is outside the upstream range RustGestalt is allowing. Access and writes are disabled.")
                        .font(.caption).foregroundStyle(isWithinUpstreamVersionRange ? .orange : .secondary)
                    Button {
                        if acceptedRiskNotice { connect() } else { showingRiskNotice = true }
                    } label: {
                        Label(manager.deviceAccessible ? "Refresh MobileGestalt" : "Read MobileGestalt", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(manager.isBusy || !isWithinUpstreamVersionRange)
                }
                .padding(.vertical, 4)
            } header: { Text("Device access") }

            if manager.deviceAccessible, manager.hasDocument {
                Section {
                    Label("MobileGestalt cache read complete", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("RustGestalt checked this iOS version, exact build string, device product type, and the current value of every shown MobileGestalt key. Erosion’s version range is not a per-build or per-feature guarantee; hardware, region, and Apple services can still affect each feature.")
                        .font(.footnote).foregroundStyle(.secondary)
                } header: { Text("Gestalt and compatibility checks") }

                ForEach(CapabilityCategory.allCases.filter { $0 != .advanced && (UIDevice.current.userInterfaceIdiom == .pad || $0 != .ipad) }) { category in
                    let entries = Capability.all.filter { $0.category == category }
                    if !entries.isEmpty {
                        Section(category.rawValue) {
                            ForEach(entries) { capability in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(capability.title).font(.subheadline.weight(.medium))
                                    Text(capability.detail).font(.caption).foregroundStyle(.secondary)
                                    Text(currentValues(for: capability))
                                        .font(.caption2.monospaced()).foregroundStyle(.secondary)
                                    Label(capability.category == .ipad ? "iPad feature; exact device support unverified" : (capability.caution ? "Extra device/build check needed" : "Key read; feature behavior remains device-specific"), systemImage: "questionmark.circle")
                                        .font(.caption2).foregroundStyle(.orange)
                                    Picker("Change", selection: Binding(
                                        get: { manager.choices[capability.id] ?? .keep },
                                        set: { manager.choices[capability.id] = $0 }
                                    )) {
                                        ForEach(capability.availableChoices) { choice in
                                            Text(choice.title).tag(choice)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    if capability.caution {
                                        Label("Experimental or device-sensitive", systemImage: "exclamationmark.triangle.fill")
                                            .font(.caption2).foregroundStyle(.orange)
                                    }
                                }
                                .padding(.vertical, 3)
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Staged changes")
                        Spacer()
                        Text("\(manager.changeCount)").foregroundStyle(.secondary)
                    }
                    Button("Review before applying") { showingReview = true }
                        .disabled(manager.changeCount == 0 || manager.isBusy)
                    Button("Discard staged changes", role: .destructive) { manager.clearStaged() }
                        .disabled(manager.changeCount == 0 || manager.isBusy)
                } header: { Text("Review") }

                Section {
                    Button("Create MobileGestalt backup") { Task { await manager.backup() } }
                        .disabled(manager.isBusy)
                    if manager.backups.isEmpty {
                        Text("The first device read creates an initial backup. Each write also saves a backup first.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(manager.backups) { backup in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(backup.reason).font(.subheadline)
                                Text("\(backup.date.formatted()) · \(ByteCountFormatter.string(fromByteCount: Int64(backup.byteCount), countStyle: .file))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Restore") {
                                restoreCandidate = backup
                                confirmingRestore = true
                            }
                            .disabled(manager.isBusy)
                        }
                    }
                } header: { Text("Backups and restore") } footer: {
                    Text("Restore is limited to backups created for this installation and matching device/cache identity.")
                }
            } else {
                Section {
                    Text(manager.status)
                        .foregroundStyle(.secondary)
                    Text("Reading is only available on a physical iPhone. The Simulator cannot access the system MobileGestalt cache.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }

            if !manager.logs.isEmpty {
                Section("Recent access activity") {
                    ForEach(Array(manager.logs.suffix(12).enumerated()), id: \.offset) { item in
                        Text(item.element).font(.caption.monospaced()).textSelection(.enabled)
                    }
                }
            }
        }
        .navigationTitle("MobileGestalt Studio")
        .navigationBarTitleDisplayMode(.inline)
        .task { await manager.reloadBackups() }
        .sheet(isPresented: $showingReview) {
            NavigationStack {
                reviewSheet
            }
        }
        .alert("MobileGestalt Studio", isPresented: Binding(
            get: { manager.message != nil },
            set: { if !$0 { manager.message = nil } }
        )) {
            Button("OK", role: .cancel) { manager.message = nil }
        } message: { Text(manager.message ?? "") }
        .alert("Use on-device MobileGestalt access?", isPresented: $showingRiskNotice) {
            Button("Cancel", role: .cancel) {}
            Button("Continue") {
                acceptedRiskNotice = true
                connect()
            }
        } message: {
            Text("This uses GestaltX’s worse_query sandbox-escape implementation to access the system cache. Incorrect values can affect device behavior. Back up first, review each change, and keep the phone’s passcode and Apple Account under your control. RustGestalt has not tested this exact build/device combination.")
        }
        .confirmationDialog("Restore this MobileGestalt backup?", isPresented: $confirmingRestore, titleVisibility: .visible) {
            Button("Restore backup", role: .destructive) {
                if let restoreCandidate { Task { await manager.restore(restoreCandidate) } }
            }
            Button("Cancel", role: .cancel) { restoreCandidate = nil }
        } message: {
            Text("The current cache is backed up before restoration, and the restored data is verified after writing.")
        }
    }

    private var reviewSheet: some View {
        List {
            Section {
                Label("Before and after", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
                Text("The live cache changes only after you choose Apply. GestaltX creates and verifies a pre-write backup first.")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("Device build: \(currentBuild) · RustGestalt exact-build result: unverified")
                    .font(.caption).foregroundStyle(.orange)
            }
            ForEach(manager.changeKeys, id: \.self) { key in
                Section(key) {
                    valueRow("Before", value: manager.snapshot?.document.extra[key])
                    valueRow("After", value: manager.preview?.extra[key])
                }
            }
            ForEach(manager.cacheDataChanges) { change in
                Section("CacheData · \(change.name)") {
                    valueRow("Before", value: NSNumber(value: change.before))
                    valueRow("After", value: NSNumber(value: change.after))
                }
            }
        }
        .navigationTitle("Review changes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { showingReview = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Apply") { confirmingApply = true }
                    .disabled(manager.changeCount == 0 || manager.isBusy)
            }
        }
        .confirmationDialog("Apply these changes to this iPhone?", isPresented: $confirmingApply, titleVisibility: .visible) {
            Button("Apply changes", role: .destructive) {
                Task {
                    await manager.apply()
                    if manager.changeCount == 0 { showingReview = false }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("iOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion) · build \(currentBuild). The exact build/device is not verified by RustGestalt. A verified MobileGestalt backup is made before writing. Some changes need a restart.")
        }
    }

    private func valueRow(_ title: String, value: Any?) -> some View {
        HStack(alignment: .top) {
            Text(title).foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value.map { PlistValueKind.detect($0).text(for: $0) } ?? "Not present")
                .font(.caption.monospaced()).multilineTextAlignment(.trailing).textSelection(.enabled)
        }
    }

    private func currentValues(for capability: Capability) -> String {
        capability.keys.map { key in
            guard let value = manager.snapshot?.document.extra[key] else { return "\(key): absent" }
            let text = PlistValueKind.detect(value).text(for: value)
            return "\(key): \(text.count > 64 ? String(text.prefix(61)) + "…" : text)"
        }.joined(separator: " · ")
    }

    private func connect() {
        guard isWithinUpstreamVersionRange else { return }
        Task { await manager.connect() }
    }

    private static var kernelBuild: String? {
        var size = 0
        guard sysctlbyname("kern.osversion", nil, &size, nil, 0) == 0, size > 1 else { return nil }
        var bytes = [CChar](repeating: 0, count: size)
        return bytes.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress,
                  sysctlbyname("kern.osversion", baseAddress, &size, nil, 0) == 0 else { return nil }
            return String(cString: baseAddress)
        }
    }
}
