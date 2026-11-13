import SwiftUI
import UIKit

struct TweakLibraryView: View {
    @Environment(\.theme) private var theme
    @State private var searchText: String = ""
    @State private var selectedCategory: TweakCategory? = nil

    private var filtered: [Tweak] {
        CapabilityCatalog.tweaks.filter { tweak in
            let matchesCategory = selectedCategory == nil || tweak.category == selectedCategory
            let matchesSearch = searchText.isEmpty
                || tweak.title.localizedCaseInsensitiveContains(searchText)
                || tweak.summary.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink {
                MobileGestaltStudioView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(theme.accent)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Open MobileGestalt Studio").font(.headline)
                        Text("Read, review, apply, and restore on this iPhone")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(theme.accent)
                }
                .padding(14)
                .background(theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.accent.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 12)

            categoryChips

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(filtered) { tweak in
                        NavigationLink(value: tweak) {
                            TweakRow(tweak: tweak)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }

        }
        .background(theme.surface.ignoresSafeArea())
        .searchable(text: $searchText, prompt: "Search tweaks")
        .navigationTitle("Tweak Library")
        .navigationDestination(for: Tweak.self) { tweak in
            TweakDetailView(tweak: tweak)
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", isSelected: selectedCategory == nil) { selectedCategory = nil }
                ForEach(TweakCategory.allCases) { category in
                    chip(title: category.rawValue, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(isSelected ? theme.accent : Color.secondary.opacity(0.15)))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

}

struct IconLibraryView: View {
    @Environment(\.theme) private var theme
    private let logos = LogoArtwork.providedPacks
    private let eraNames = ["iOS 6", "iOS 7", "iOS 18", "iOS 26"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Logo Shelf").font(.largeTitle.bold())
                    Text("Browse icon packs by iOS generation, then choose an appearance.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                ForEach(eraNames, id: \.self) { era in
                    let count = logos.filter { $0.era == era }.count
                    NavigationLink {
                        LogoVariantMenu(era: era, logos: logos.filter { $0.era == era })
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.title2).foregroundStyle(theme.accent)
                                .frame(width: 48, height: 48)
                                .background(theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(era).font(.headline).foregroundStyle(.primary)
                                Text(count == 0 ? "No artwork found" : "\(count) supplied icons")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(theme.accent.opacity(0.12), lineWidth: 1))
                    }
                }
                limitationCard
            }
            .padding(20)
        }
        .background(theme.surface.ignoresSafeArea())
        .navigationTitle("Logo Shelf")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var limitationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How web clip icons work", systemImage: "info.circle.fill")
                .font(.subheadline.weight(.semibold)).foregroundStyle(theme.accent)
            Text("A web clip adds a separate Home Screen shortcut with this artwork. It does not replace the original app icon. Enter a web address or universal link, export the profile, then install it from Settings. Remove the profile in Settings to remove its web clip.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct LogoVariantMenu: View {
    @Environment(\.theme) private var theme
    let era: String
    let logos: [LogoArtwork]

    private var variants: [String] {
        let order = ["Light", "Dark", "Tinted", "Original", "Extras"]
        return order.filter { variant in logos.contains { $0.variant == variant } }
    }

    var body: some View {
        List {
            ForEach(variants, id: \.self) { variant in
                let count = logos.filter { $0.variant == variant }.count
                NavigationLink {
                    LogoPackGrid(era: era, variant: variant, logos: logos.filter { $0.variant == variant })
                } label: {
                    HStack(spacing: 12) {
                        if let sample = logos.first(where: { $0.variant == variant }) {
                            Image(uiImage: sample.previewImage).resizable().scaledToFit().frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(variant).font(.headline)
                            Text("\(count) icons").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(theme.accent)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(era)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LogoPackGrid: View {
    @Environment(\.theme) private var theme
    @State private var selectedLogo: LogoArtwork?
    @State private var search = ""
    let era: String
    let variant: String
    let logos: [LogoArtwork]
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    private var filtered: [LogoArtwork] {
        search.isEmpty ? logos : logos.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(filtered) { logo in
                    Button { selectedLogo = logo } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(uiImage: logo.previewImage).resizable().scaledToFit()
                                .frame(maxWidth: .infinity).frame(height: 112)
                                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                            Text(logo.title).font(.headline).foregroundStyle(.primary).lineLimit(2)
                            Label("Make web clip", systemImage: "plus.app")
                                .font(.caption.weight(.semibold)).foregroundStyle(theme.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                        .background(theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }.buttonStyle(.plain)
                }
            }.padding(16)
        }
        .background(theme.surface.ignoresSafeArea())
        .searchable(text: $search, prompt: "Search \(variant.lowercased()) icons")
        .navigationTitle("\(era) · \(variant)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedLogo) { LogoWebClipComposer(logo: $0) }
    }
}

private struct LogoArtwork: Identifiable {
    let url: URL
    let era: String
    let variant: String
    var id: String { url.path }
    var title: String {
        url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "-large", with: "")
            .replacingOccurrences(of: "_", with: " ")
    }
    var previewImage: UIImage { UIImage(contentsOfFile: url.path) ?? UIImage(systemName: "app.fill") ?? UIImage() }

    static let providedPacks = loadProvidedPacks()

    static func loadProvidedPacks() -> [LogoArtwork] {
        guard let root = Bundle.main.resourceURL?.appendingPathComponent("LogoPacks", isDirectory: true),
              let folders = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return [] }
        return folders.flatMap { folder -> [LogoArtwork] in
            guard let files = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil) else { return [] }
            return files.compactMap { item -> LogoArtwork? in
                guard let url = item as? URL, ["png", "jpg", "jpeg"].contains(url.pathExtension.lowercased()) else { return nil }
                let parent = url.deletingLastPathComponent().lastPathComponent
                let variant = parent == folder.lastPathComponent ? "Original" : parent
                return LogoArtwork(url: url, era: folder.lastPathComponent, variant: variant)
            }
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }
}

private struct LogoWebClipComposer: View {
    @Environment(\.dismiss) private var dismiss
    let logo: LogoArtwork
    @State private var label = ""
    @State private var destination = ""
    @State private var profileURL: URL?
    @State private var errorMessage: String?

    private var validDestination: Bool {
        guard let parts = URLComponents(string: destination.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = parts.scheme?.lowercased(), ["https", "http"].contains(scheme),
              parts.host?.isEmpty == false else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Selected artwork") {
                    HStack(spacing: 14) {
                        Image(uiImage: logo.previewImage).resizable().scaledToFit().frame(width: 76, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(logo.title).font(.headline)
                            Text(logo.era).font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 4)
                }
                Section("Shortcut details") {
                    TextField("Home Screen name", text: $label)
                        .textInputAutocapitalization(.words).onAppear { if label.isEmpty { label = logo.title } }
                    TextField("https://address", text: $destination)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Text("A web clip opens this link. Use a universal link if you want iOS to open the matching installed app.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section {
                    if let profileURL {
                        ShareLink(item: profileURL) { Label("Share or Save Profile", systemImage: "square.and.arrow.up") }
                        Text("Save the .mobileconfig file, then open Settings → Profile Downloaded → Install.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Button { createProfile() } label: {
                            Label("Create Web Clip Profile", systemImage: "person.crop.square.badge.plus")
                        }.disabled(!validDestination || label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.red) }
                }
                Section {
                    Label("Removable", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("The profile asks for permission during installation. Remove the web clip by deleting it from the Home Screen or remove the profile in Settings → General → VPN & Device Management.")
                        .font(.caption).foregroundStyle(.secondary)
                } header: { Text("Install and restore") }
            }
            .navigationTitle("Create Web Clip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.large])
    }

    private func createProfile() {
        do {
            let iconData = try makeProfileIcon()
            let webClipID = UUID().uuidString
            let profileID = UUID().uuidString
            let webClip: [String: Any] = [
                "FullScreen": false,
                "Icon": iconData,
                "IsRemovable": true,
                "Label": label.trimmingCharacters(in: .whitespacesAndNewlines),
                "PayloadIdentifier": "com.rustgestalt.webclip.\(webClipID)",
                "PayloadType": "com.apple.webClip.managed",
                "PayloadUUID": webClipID,
                "PayloadVersion": 1,
                "Precomposed": true,
                "URL": destination.trimmingCharacters(in: .whitespacesAndNewlines)
            ]
            let profile: [String: Any] = [
                "PayloadContent": [webClip],
                "PayloadDisplayName": "RustGestalt — \(label.trimmingCharacters(in: .whitespacesAndNewlines))",
                "PayloadIdentifier": "com.rustgestalt.webclip.profile.\(profileID)",
                "PayloadRemovalDisallowed": false,
                "PayloadType": "Configuration",
                "PayloadUUID": profileID,
                "PayloadVersion": 1
            ]
            let data = try PropertyListSerialization.data(fromPropertyList: profile, format: .xml, options: 0)
            let safeName = label.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "/", with: "-")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("RustGestalt-\(safeName).mobileconfig")
            try data.write(to: url, options: .atomic)
            profileURL = url
            errorMessage = nil
        } catch {
            errorMessage = "Could not create the profile: \(error.localizedDescription)"
        }
    }

    private func makeProfileIcon() throws -> Data {
        guard let source = UIImage(contentsOfFile: logo.url.path) else {
            throw NSError(domain: "RustGestaltLogo", code: 1, userInfo: [NSLocalizedDescriptionKey: "The selected artwork could not be opened."])
        }
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        let square = renderer.image { _ in source.draw(in: CGRect(origin: .zero, size: size)) }
        guard let data = square.pngData(), data.count < 1_000_000 else {
            throw NSError(domain: "RustGestaltLogo", code: 2, userInfo: [NSLocalizedDescriptionKey: "The icon could not be prepared as a small PNG."])
        }
        return data
    }
}
