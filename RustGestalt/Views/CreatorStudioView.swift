import SwiftUI

private enum CreatorStatus: String, CaseIterable, Codable, Identifiable {
    case idea = "Idea", research = "Research", planning = "Planning", scripting = "Scripting", recording = "Recording", editing = "Editing", thumbnail = "Thumbnail", ready = "Ready to publish", published = "Published"
    var id: String { rawValue }
}
private enum CreatorPlatform: String, CaseIterable, Codable, Identifiable {
    case youtube = "YouTube", shorts = "YouTube Shorts", tiktok = "TikTok", reels = "Instagram Reels", posts = "Instagram Posts", x = "X", other = "Other"
    var id: String { rawValue }
}
private struct CreatorItem: Identifiable, Codable {
    var id = UUID(); var title: String; var details = ""; var script = ""; var platform = CreatorPlatform.youtube; var customPlatform = ""; var format = "Review"; var status = CreatorStatus.idea; var category = "iOS"; var publishDate: Date?; var references = ""; var notes = ""; var updatedAt = Date()
}
private struct CreatorDevice: Identifiable, Codable { var id = UUID(); var name: String; var model = ""; var software = ""; var notes = "" }
private struct CreatorTest: Identifiable, Codable { var id = UUID(); var title: String; var device: String; var result = "Observed"; var notes = ""; var date = Date() }
private struct CreatorData: Codable { var items: [CreatorItem] = []; var devices: [CreatorDevice] = []; var tests: [CreatorTest] = []; var savedTrends: [String] = []; var order = ["Upcoming", "Ideas", "Projects", "Device Lab", "Trend Radar", "Activity", "Stats"]; var hidden: [String] = [] }
@MainActor private final class CreatorStore: ObservableObject {
    @Published private(set) var data: CreatorData
    init() { let url = Self.url; data = (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode(CreatorData.self, from: $0) } ?? CreatorData() }
    private static var url: URL { FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("RustGestalt/CreatorStudio.json") }
    private func save() { do { try FileManager.default.createDirectory(at: Self.url.deletingLastPathComponent(), withIntermediateDirectories: true); try JSONEncoder().encode(data).write(to: Self.url, options: .atomic) } catch { print("Creator Studio save failed: \(error)") } }
    func add(_ item: CreatorItem) { data.items.insert(item, at: 0); save() }
    func update(_ item: CreatorItem) { if let i = data.items.firstIndex(where: { $0.id == item.id }) { data.items[i] = item; data.items[i].updatedAt = .now; save() } }
    func add(_ device: CreatorDevice) { data.devices.insert(device, at: 0); save() }
    func add(_ test: CreatorTest) { data.tests.insert(test, at: 0); save() }
    func toggleTrend(_ title: String) { if data.savedTrends.contains(title) { data.savedTrends.removeAll { $0 == title } } else { data.savedTrends.append(title) }; save() }
    func moveWidget(_ id: String, by delta: Int) { guard let i = data.order.firstIndex(of: id) else { return }; let j = max(0, min(data.order.count - 1, i + delta)); data.order.swapAt(i, j); save() }
    func toggleWidget(_ id: String) { if data.hidden.contains(id) { data.hidden.removeAll { $0 == id } } else { data.hidden.append(id) }; save() }
}

struct CreatorStudioView: View {
    @StateObject private var store = CreatorStore()
    @State private var sheet: CreatorSheet?
    @State private var editing: CreatorItem?
    @State private var showPlanner = false
    @State private var showRetro = false
    @State private var showCustomize = false
    private let trends = ["What changed in the latest iOS beta?", "On-device AI: what works offline?", "iPhone camera feature field test", "iOS 27 compatibility watch", "Old iPhone versus current model", "A week with a new accessibility feature"]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) { VStack(alignment: .leading, spacing: 6) { Text("Creator Studio").font(.largeTitle.bold()); Text("Your workspace for making technology stories.").foregroundStyle(.secondary) }; Spacer(); Menu { Button("New video idea", systemImage: "lightbulb") { sheet = .idea }; Button("New content project", systemImage: "folder.badge.plus") { sheet = .item }; Button("Write a script", systemImage: "doc.text") { sheet = .script }; Button("Add a device", systemImage: "iphone.gen3") { sheet = .device }; Button("Record an iOS feature test", systemImage: "checkmark.seal") { sheet = .test }; Button("Create a comparison", systemImage: "rectangle.split.2x1") { sheet = .comparison }; Button("Open Retro Launch Studio", systemImage: "sparkles") { showRetro = true } } label: { Label("Quick create", systemImage: "plus").font(.headline).padding(12).background(.orange.opacity(0.15), in: Capsule()) } }
                HStack { Label("Creator workspace", systemImage: "sparkles").font(.subheadline.weight(.semibold)); Spacer(); Button("Customize") { showCustomize = true }.font(.subheadline) }.padding(14).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                ForEach(store.data.order.filter { !store.data.hidden.contains($0) }, id: \.self) { section in
                    widget(section).transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity.combined(with: .scale(scale: 0.96))))
                }
                Button { showPlanner = true } label: { Label("Open Content Planner", systemImage: "calendar").frame(maxWidth: .infinity).padding() }.buttonStyle(.borderedProminent).tint(.orange)
            }.padding()
        }
        .navigationTitle("Creator Studio")
        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: store.data.order)
        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: store.data.hidden)
        .sheet(item: $sheet) { kind in NavigationStack { CreatorForm(kind: kind, devices: store.data.devices) { value in switch value { case .item(let item): store.add(item); case .device(let device): store.add(device); case .test(let test): store.add(test) } } } }
        .sheet(item: $editing) { item in NavigationStack { CreatorForm(kind: .edit, devices: store.data.devices, existing: item) { value in if case .item(let updated) = value { store.update(updated) } } } }
        .sheet(isPresented: $showPlanner) { NavigationStack { CreatorPlanner(store: store, onEdit: { editing = $0 }, onNew: { sheet = .item }) } }
        .sheet(isPresented: $showRetro) { NavigationStack { RetroLaunchStudioView() } }
        .sheet(isPresented: $showCustomize) { NavigationStack { CreatorCustomize(store: store) } }
    }
    @ViewBuilder private func widget(_ name: String) -> some View {
        switch name {
        case "Upcoming": card(name, "calendar") { let today = Calendar.current.startOfDay(for: .now); let upcoming = store.data.items.filter { item in guard let date = item.publishDate else { return false }; return date >= today && item.status != .published }.sorted { ($0.publishDate ?? .distantFuture) < ($1.publishDate ?? .distantFuture) }.prefix(3); if upcoming.isEmpty { empty("No scheduled content yet") } else { ForEach(Array(upcoming)) { item in itemRow(item) } } }
        case "Ideas": card("Saved video ideas", "lightbulb") { let ideas = store.data.items.filter { $0.status == .idea }.prefix(3); if ideas.isEmpty { empty("Capture your next tech story") } else { ForEach(Array(ideas)) { item in itemRow(item) } } }
        case "Projects": card("Current projects", "film") { let projects = store.data.items.filter { $0.status != .idea && $0.status != .published }.prefix(3); if projects.isEmpty { empty("Your in-progress work will show here") } else { ForEach(Array(projects)) { item in itemRow(item) } } }
        case "Device Lab": card(name, "iphone.gen3") { HStack { Label("\(store.data.devices.count) devices", systemImage: "iphone"); Spacer(); Label("\(store.data.tests.count) tests", systemImage: "checkmark.seal") }; if store.data.devices.isEmpty { empty("Add devices to track your review lab") }; Button("Add device") { sheet = .device }.buttonStyle(.bordered) }
        case "Trend Radar": card(name, "waveform.path") { Text("Ideas to investigate").font(.caption).foregroundStyle(.secondary); ForEach(trends.prefix(4), id: \.self) { trend in HStack { Text(trend).font(.subheadline); Spacer(); Button { store.toggleTrend(trend) } label: { Image(systemName: store.data.savedTrends.contains(trend) ? "bookmark.fill" : "bookmark") }.buttonStyle(.plain).accessibilityLabel("Save trend") } } }
        case "Activity": card("Recent testing activity", "clock") { if store.data.tests.isEmpty { empty("Feature tests you record appear here") } else { ForEach(store.data.tests.prefix(3)) { test in VStack(alignment: .leading, spacing: 4) { Text(test.title).font(.subheadline.weight(.medium)); Text("\(test.device) · \(test.result) · \(test.date.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(.secondary) } } }; Button("Record feature test") { sheet = .test }.buttonStyle(.bordered) }
        case "Stats": card("Creator stats", "chart.bar") { HStack { stat("Planned", "\(store.data.items.filter { $0.status != .published }.count)"); stat("Published", "\(store.data.items.filter { $0.status == .published }.count)"); stat("Tests", "\(store.data.tests.count)") } }
        default: EmptyView()
        }
    }
    private func card<Content: View>(_ title: String, _ icon: String, @ViewBuilder content: () -> Content) -> some View { VStack(alignment: .leading, spacing: 12) { Label(title, systemImage: icon).font(.headline); content() }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18)) }
    private func itemRow(_ item: CreatorItem) -> some View { Button { editing = item } label: { HStack { VStack(alignment: .leading, spacing: 3) { Text(item.title).font(.subheadline.weight(.medium)); Text("\(item.platform == .other && !item.customPlatform.isEmpty ? item.customPlatform : item.platform.rawValue) · \(item.format) · \(item.status.rawValue)\(item.publishDate.map { " · \($0.formatted(date: .abbreviated, time: .omitted))" } ?? "")").font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary) } }.buttonStyle(.plain) }
    private func empty(_ text: String) -> some View { Text(text).font(.subheadline).foregroundStyle(.secondary) }
    private func stat(_ label: String, _ value: String) -> some View { VStack(alignment: .leading) { Text(value).font(.title2.bold()); Text(label).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading) }
}

private enum CreatorSheet: String, Identifiable { case idea = "New idea", item = "New project", script = "Write a script", device = "Add a device", test = "Record feature test", comparison = "Create comparison", edit = "Edit content"; var id: String { rawValue } }
private enum CreatorSave { case item(CreatorItem), device(CreatorDevice), test(CreatorTest) }
private struct CreatorForm: View {
    let kind: CreatorSheet; let devices: [CreatorDevice]; var existing: CreatorItem? = nil; let onSave: (CreatorSave) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""; @State private var details = ""; @State private var script = ""; @State private var platform = CreatorPlatform.youtube; @State private var customPlatform = ""; @State private var format = "Review"; @State private var status = CreatorStatus.idea; @State private var category = "iOS"; @State private var date = Date(); @State private var schedule = false; @State private var references = ""; @State private var notes = ""; @State private var deviceName = ""; @State private var model = ""; @State private var software = ""; @State private var result = "Observed"; @State private var selectedDevice = ""
    var body: some View { Form { switch kind { case .device: Section("Device") { TextField("Device name", text: $deviceName); TextField("Model", text: $model); TextField("iOS / build", text: $software); TextField("Lab notes", text: $notes, axis: .vertical) }
        case .test: Section("Feature test") { TextField("Feature or test title", text: $title); if devices.isEmpty { TextField("Device", text: $deviceName) } else { Picker("Device", selection: $selectedDevice) { ForEach(devices) { Text($0.name).tag($0.name) } } }; TextField("Result", text: $result); TextField("Observations", text: $notes, axis: .vertical) }
        default: Section("Content") { TextField("Title", text: $title); TextField("Description", text: $details, axis: .vertical).lineLimit(3...6); Picker("Platform", selection: $platform) { ForEach(CreatorPlatform.allCases) { Text($0.rawValue).tag($0) } }; if platform == .other { TextField("Custom platform", text: $customPlatform) }; TextField("Format (review, comparison, tutorial…)", text: $format); Picker("Status", selection: $status) { ForEach(CreatorStatus.allCases) { Text($0.rawValue).tag($0) } }; TextField("Category", text: $category); Toggle("Set publishing date", isOn: $schedule); if schedule { DatePicker("Publish", selection: $date, displayedComponents: .date) }; TextField("Reference links", text: $references, axis: .vertical); TextField("Notes", text: $notes, axis: .vertical); if kind == .script || kind == .edit { TextField("Script draft", text: $script, axis: .vertical).lineLimit(6...14) } } }
        }.navigationTitle(kind.rawValue).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(kind == .device ? deviceName.isEmpty : title.isEmpty) } }.onAppear { if let item = existing { title = item.title; details = item.details; script = item.script; platform = item.platform; customPlatform = item.customPlatform; format = item.format; status = item.status; category = item.category; date = item.publishDate ?? .now; schedule = item.publishDate != nil; references = item.references; notes = item.notes } else { title = kind == .comparison ? "iPhone comparison" : ""; if kind == .idea { status = .idea }; if kind == .script { status = .scripting }; if kind == .item || kind == .comparison { status = .planning }; if kind == .comparison { category = "Device comparison"; format = "Comparison" }; if kind == .test, let first = devices.first { selectedDevice = first.name } } }
    private func save() { switch kind { case .device: onSave(.device(CreatorDevice(name: deviceName, model: model, software: software, notes: notes))); case .test: onSave(.test(CreatorTest(title: title, device: devices.isEmpty ? deviceName : selectedDevice, result: result, notes: notes))); default: onSave(.item(CreatorItem(id: existing?.id ?? UUID(), title: title, details: details, script: script, platform: platform, customPlatform: customPlatform, format: format, status: status, category: category, publishDate: schedule ? date : nil, references: references, notes: notes))) }; dismiss() }
}

private struct CreatorPlanner: View {
    @ObservedObject var store: CreatorStore; let onEdit: (CreatorItem) -> Void; let onNew: () -> Void
    @State private var mode = "List"; @State private var selectedDate = Date(); private let modes = ["List", "Board", "Calendar"]
    var body: some View { VStack { Picker("View", selection: $mode) { ForEach(modes, id: \.self) { Text($0) } }.pickerStyle(.segmented).padding(); if mode == "List" { List(store.data.items) { item in Button { onEdit(item) } label: { line(item) } } } else if mode == "Board" { ScrollView(.horizontal) { HStack(alignment: .top, spacing: 12) { ForEach(CreatorStatus.allCases) { status in VStack(alignment: .leading) { Text(status.rawValue).font(.headline); ForEach(store.data.items.filter { $0.status == status }) { item in Button { onEdit(item) } label: { line(item).padding(10).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12)) }.buttonStyle(.plain) } }.frame(width: 220, alignment: .leading) } }.padding() } } else { VStack { DatePicker("Publishing calendar", selection: $selectedDate, displayedComponents: .date).datePickerStyle(.graphical).padding(.horizontal); let dayItems = store.data.items.filter { item in guard let date = item.publishDate else { return false }; return Calendar.current.isDate(date, inSameDayAs: selectedDate) }; if dayItems.isEmpty { ContentUnavailableView("Nothing scheduled", systemImage: "calendar", description: Text("Choose a date with scheduled content, or set a publishing date on a project.")) } else { List(dayItems) { item in Button { onEdit(item) } label: { line(item) } } } } }.navigationTitle("Content Planner").toolbar { Button(action: onNew) { Image(systemName: "plus") } } }
    private func line(_ item: CreatorItem) -> some View { VStack(alignment: .leading, spacing: 4) { Text(item.title).font(.headline); Text("\(item.status.rawValue) · \(item.platform == .other && !item.customPlatform.isEmpty ? item.customPlatform : item.platform.rawValue) · \(item.format) · \(item.category)").font(.caption).foregroundStyle(.secondary); if let date = item.publishDate { Text(date.formatted(date: .long, time: .omitted)).font(.caption) } } }
}
private struct CreatorCustomize: View {
    @ObservedObject var store: CreatorStore; @Environment(\.dismiss) private var dismiss
    var body: some View { List { ForEach(store.data.order, id: \.self) { item in let index = store.data.order.firstIndex(of: item) ?? 0; HStack { VStack(alignment: .leading) { Text(item); Text(store.data.hidden.contains(item) ? "Hidden from dashboard" : "Shown on dashboard").font(.caption).foregroundStyle(.secondary) }; Spacer(); Button { store.toggleWidget(item) } label: { Image(systemName: store.data.hidden.contains(item) ? "eye.slash" : "eye") }; Button { store.moveWidget(item, by: -1) } label: { Image(systemName: "arrow.up") }.disabled(index == 0); Button { store.moveWidget(item, by: 1) } label: { Image(systemName: "arrow.down") }.disabled(index == store.data.order.count - 1) } } }.navigationTitle("Customize Dashboard").toolbar { Button("Done") { dismiss() } } }
}
