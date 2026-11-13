import SwiftUI

/// The RustGestalt palette names and colors are intentionally mirrored in the iOS
/// and Mac targets so both apps share the same visual identity.
enum ThemePreset: String, CaseIterable, Identifiable {
    case rust, midnight, frost, lavender, forest, monochrome, sunset
    // Retained for users upgrading from the first theme picker.
    case cream, slate, sage

    static let gallery: [ThemePreset] = [.rust, .midnight, .frost, .lavender, .forest, .monochrome, .sunset]
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rust: "Rust"
        case .midnight: "Midnight"
        case .frost: "Frost"
        case .lavender: "Lavender"
        case .forest: "Forest"
        case .monochrome: "Monochrome"
        case .sunset: "Sunset"
        case .cream: "Cream"
        case .slate: "Slate"
        case .sage: "Sage"
        }
    }

    var description: String {
        switch self {
        case .rust: "Warm rust, cream, and soft glass."
        case .midnight: "Charcoal surfaces with a warm copper accent."
        case .frost: "Cool whites and clear blue accents."
        case .lavender: "Soft violet tones with quiet contrast."
        case .forest: "Muted greens and natural paper surfaces."
        case .monochrome: "A restrained palette of black, white, and grey."
        case .sunset: "Warm coral, amber, and evening cream."
        case .cream: "A legacy warm cream palette."
        case .slate: "A legacy cool slate palette."
        case .sage: "A legacy muted green palette."
        }
    }

    var accent: Color {
        switch self {
        case .rust: Color(red: 0.79, green: 0.39, blue: 0.22)
        case .midnight: Color(red: 0.85, green: 0.55, blue: 0.36)
        case .frost: Color(red: 0.25, green: 0.48, blue: 0.75)
        case .lavender: Color(red: 0.55, green: 0.42, blue: 0.74)
        case .forest, .sage: Color(red: 0.31, green: 0.48, blue: 0.35)
        case .monochrome: Color(red: 0.28, green: 0.29, blue: 0.31)
        case .sunset: Color(red: 0.82, green: 0.30, blue: 0.22)
        case .cream: Color(red: 0.84, green: 0.57, blue: 0.32)
        case .slate: Color(red: 0.36, green: 0.47, blue: 0.58)
        }
    }

    var swatch: Color { accent }
    var lightSurface: Color {
        switch self {
        case .rust, .cream: Color(red: 0.98, green: 0.96, blue: 0.92)
        case .midnight: Color(red: 0.94, green: 0.93, blue: 0.92)
        case .frost, .slate: Color(red: 0.94, green: 0.97, blue: 0.99)
        case .lavender: Color(red: 0.97, green: 0.95, blue: 0.99)
        case .forest, .sage: Color(red: 0.95, green: 0.97, blue: 0.93)
        case .monochrome: Color(white: 0.95)
        case .sunset: Color(red: 1.0, green: 0.95, blue: 0.91)
        }
    }
    var darkSurface: Color {
        switch self {
        case .rust, .cream: Color(red: 0.13, green: 0.11, blue: 0.10)
        case .midnight: Color(red: 0.07, green: 0.08, blue: 0.11)
        case .frost, .slate: Color(red: 0.08, green: 0.11, blue: 0.15)
        case .lavender: Color(red: 0.12, green: 0.09, blue: 0.16)
        case .forest, .sage: Color(red: 0.08, green: 0.12, blue: 0.09)
        case .monochrome: Color(white: 0.08)
        case .sunset: Color(red: 0.16, green: 0.09, blue: 0.08)
        }
    }
    var lightElevated: Color { .white }
    var darkElevated: Color {
        switch self {
        case .midnight: Color(red: 0.13, green: 0.14, blue: 0.18)
        case .frost, .slate: Color(red: 0.13, green: 0.17, blue: 0.22)
        case .lavender: Color(red: 0.18, green: 0.14, blue: 0.23)
        case .forest, .sage: Color(red: 0.13, green: 0.18, blue: 0.14)
        case .sunset: Color(red: 0.22, green: 0.13, blue: 0.11)
        default: Color(white: 0.14)
        }
    }
}

struct Theme: Equatable {
    var accent: Color
    var surface: Color
    var surfaceElevated: Color
    var preset: ThemePreset

    static func resolve(_ preset: ThemePreset, scheme: ColorScheme) -> Theme {
        let dark = scheme == .dark
        return Theme(accent: preset.accent,
                     surface: dark ? preset.darkSurface : preset.lightSurface,
                     surfaceElevated: dark ? preset.darkElevated : preset.lightElevated,
                     preset: preset)
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.resolve(.rust, scheme: .dark)
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

struct ThemedRoot<Content: View>: View {
    @AppStorage("themePreset") private var presetRaw: String = ThemePreset.rust.rawValue
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }
    private var preset: ThemePreset { ThemePreset(rawValue: presetRaw) ?? .rust }

    var body: some View {
        content.environment(\.theme, Theme.resolve(preset, scheme: colorScheme)).tint(preset.accent)
    }
}
