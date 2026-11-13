import SwiftUI
import UIKit

private struct RetroArtwork: Identifiable {
    let url: URL
    let era: String
    let variant: String
    var id: String { url.path }
    var title: String {
        url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: "-large", with: "")
            .replacingOccurrences(of: "_", with: " ")
    }
    var image: UIImage { UIImage(contentsOfFile: url.path) ?? UIImage(systemName: "app.fill") ?? UIImage() }

    static let all: [Self] = {
        guard let root = Bundle.main.resourceURL?.appendingPathComponent("LogoPacks", isDirectory: true),
              let folders = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return [] }
        return folders.flatMap { folder in
            (FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)?.allObjects ?? []).compactMap { item -> Self? in
                guard let url = item as? URL, ["png", "jpg", "jpeg"].contains(url.pathExtension.lowercased()) else { return nil }
                let parent = url.deletingLastPathComponent().lastPathComponent
                return Self(url: url, era: folder.lastPathComponent, variant: parent == folder.lastPathComponent ? "Original" : parent)
            }
        }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }()
}

struct RetroLaunchStudioView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var era = "iOS 6"
    @State private var variant = "Original"
    @State private var page = 0
    @State private var editing = false
    @State private var launched: RetroArtwork?
    @State private var showingIntro = true
    @State private var clock = Date.now

    private let eras = ["iOS 6", "iOS 7", "iOS 18", "iOS 26"]
    private let artwork = RetroArtwork.all
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    private var variants: [String] {
        let preferred = ["Light", "Dark", "Tinted", "Original", "Extras"]
        let values = Set(artwork.filter { $0.era == era }.map(\.variant))
        return preferred.filter(values.contains) + values.subtracting(preferred).sorted()
    }
    private var selectedIcons: [RetroArtwork] { artwork.filter { $0.era == era && $0.variant == variant } }
    private var pages: [[RetroArtwork]] {
        let chunks = stride(from: 0, to: max(selectedIcons.count, 1), by: 20).map { Array(selectedIcons.dropFirst($0).prefix(20)) }
        return chunks.isEmpty ? [[]] : chunks
    }
    private var dockIcons: [RetroArtwork] { Array(selectedIcons.prefix(4)) }
    private var wallpaper: [Color] {
        switch era {
        case "iOS 6": [Color(red: 0.12, green: 0.20, blue: 0.34), Color(red: 0.82, green: 0.42, blue: 0.23)]
        case "iOS 7": [Color(red: 0.08, green: 0.61, blue: 0.83), Color(red: 0.20, green: 0.83, blue: 0.78)]
        case "iOS 18": [Color(red: 0.98, green: 0.56, blue: 0.49), Color(red: 0.45, green: 0.34, blue: 0.78)]
        default: [Color(red: 0.32, green: 0.64, blue: 0.94), Color(red: 0.66, green: 0.36, blue: 0.89)]
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                controls
                phonePreview
                Text("A visual role-play preview made from your supplied artwork. It does not install or change iOS.")
                    .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 12)
            }
            .padding(16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Retro Launch Studio")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if showingIntro {
                introCard.transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .zIndex(2)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.84), value: showingIntro)
        .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.82), value: era)
        .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.82), value: variant)
        .animation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.86), value: page)
        .sheet(item: $launched) { icon in
            RetroAppLaunchView(icon: icon, era: era, colors: wallpaper)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: era) { _, _ in
            page = 0
            if let first = variants.first { variant = first }
        }
        .onChange(of: variant) { _, _ in page = 0 }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                clock = .now
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Retro Launch Studio").font(.title2.bold())
                Text("Step into four iOS eras.").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button(editing ? "Done" : "Edit") {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) { editing.toggle() }
            }
            .buttonStyle(.bordered)
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Picker("iOS era", selection: $era) {
                ForEach(eras, id: \.self) { Text($0).tag($0) }
            }.pickerStyle(.segmented)
            if variants.count > 1 {
                Picker("Icon appearance", selection: $variant) {
                    ForEach(variants, id: \.self) { Text($0).tag($0) }
                }.pickerStyle(.segmented)
            } else {
                Label("\(variant) icon set", systemImage: "square.grid.2x2")
                    .font(.caption.weight(.medium)).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var phonePreview: some View {
        ZStack {
            LinearGradient(colors: wallpaper, startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [.white.opacity(0.36), .clear], center: .topTrailing, startRadius: 8, endRadius: 310)
            VStack(spacing: 0) {
                statusBar
                Text(clock, format: .dateTime.hour().minute())
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundStyle(.white).shadow(color: .black.opacity(0.2), radius: 8, y: 3)
                Text(clock.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.subheadline.weight(.medium)).foregroundStyle(.white.opacity(0.94))
                    .padding(.top, 2).padding(.bottom, 20)
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, icons in
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(icons) { iconButton($0, index: index) }
                        }
                        .padding(.horizontal, 16).padding(.top, 4).frame(maxHeight: .infinity, alignment: .top)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                pageIndicators
                HStack(spacing: 12) {
                    ForEach(dockIcons) { iconButton($0, index: 99) }
                    if dockIcons.isEmpty { Text("Add supplied icons to see the dock").font(.caption).foregroundStyle(.white) }
                }
                .padding(.horizontal, 12).padding(.vertical, 11)
                .background(.ultraThinMaterial.opacity(0.82), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
                .padding(.horizontal, 22).padding(.bottom, 22)
            }
            .overlay(alignment: .top) {
                if era == "iOS 26" {
                    Capsule().fill(.white.opacity(0.22)).frame(width: 82, height: 22).padding(.top, 5)
                }
            }
            if selectedIcons.isEmpty {
                ContentUnavailableView("No icons in this set", systemImage: "square.grid.2x2", description: Text("Choose another appearance or add artwork to this era."))
                    .padding(20)
            }
        }
        .frame(width: 350, height: 675)
        .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 42, style: .continuous).stroke(.white.opacity(0.78), lineWidth: 5))
        .overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(.black.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.20), radius: 24, y: 13)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    private var statusBar: some View {
        HStack {
            Text("9:41").font(.caption.weight(.semibold))
            Spacer()
            Image(systemName: "antenna.radiowaves.left.and.right")
            Image(systemName: "wifi")
            Image(systemName: "battery.100percent")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 25).padding(.top, 18).padding(.bottom, 12)
    }

    private var pageIndicators: some View {
        HStack(spacing: 7) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule().fill(index == page ? .white : .white.opacity(0.42))
                    .frame(width: index == page ? 17 : 6, height: 6)
                    .onTapGesture { withAnimation { page = index } }
            }
        }.padding(.vertical, 12)
    }

    @ViewBuilder private func iconButton(_ icon: RetroArtwork, index: Int) -> some View {
        Button {
            if !editing {
                launched = icon
            }
        } label: {
            VStack(spacing: 4) {
                Image(uiImage: icon.image).resizable().scaledToFill()
                    .frame(width: 57, height: 57).clipShape(RoundedRectangle(cornerRadius: era == "iOS 6" ? 13 : 15, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.16), lineWidth: 0.6))
                    .shadow(color: .black.opacity(0.2), radius: era == "iOS 7" ? 0 : 4, y: 3)
                    .rotationEffect(.degrees(editing ? (index.isMultiple(of: 2) ? 2 : -2) : 0))
                    .animation(editing && !reduceMotion ? .easeInOut(duration: 0.11).repeatForever(autoreverses: true) : .default, value: editing)
                if index != 99 {
                    Text(icon.title).font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white).lineLimit(1).shadow(color: .black.opacity(0.7), radius: 3, y: 1)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(editing ? "Editing \(icon.title) in preview mode" : "Open preview for \(icon.title)")
    }

    private var introCard: some View {
        VStack(spacing: 15) {
            Image(systemName: "sparkles.rectangle.stack.fill").font(.system(size: 38)).symbolRenderingMode(.palette)
                .foregroundStyle(.white, .orange)
            Text("Your time machine is ready.").font(.title2.bold()).multilineTextAlignment(.center)
            Text("Choose an iOS look, browse the home screen, and tap an icon to open its preview.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button {
                withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.82)) { showingIntro = false }
            } label: {
                Text("Enter Home Screen").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
            }.buttonStyle(.borderedProminent).tint(.orange)
        }
        .padding(22).frame(maxWidth: 330)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 28, y: 14)
    }
}

private struct RetroAppLaunchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let icon: RetroArtwork
    let era: String
    let colors: [Color]
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(uiImage: icon.image).resizable().scaledToFill().frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                Text(icon.title).font(.title.bold()).foregroundStyle(.white)
                Text("\(era) app preview").font(.subheadline).foregroundStyle(.white.opacity(0.82))
                Text("This is a visual demo. It does not launch or install the real app.")
                    .font(.footnote).foregroundStyle(.white.opacity(0.78)).multilineTextAlignment(.center)
                Button("Back to Home Screen") { dismiss() }
                    .buttonStyle(.borderedProminent).tint(.white.opacity(0.24))
                    .foregroundStyle(.white).padding(.top, 6)
            }
            .scaleEffect(appeared ? 1 : 0.82).opacity(appeared ? 1 : 0)
        }
        .onAppear { withAnimation(reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.78)) { appeared = true } }
        .onDisappear { appeared = false }
    }
}
