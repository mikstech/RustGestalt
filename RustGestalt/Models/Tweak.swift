import Foundation

enum TweakCategory: String, CaseIterable, Identifiable {
    case displayVisuals = "Display & Appearance"
    case batteryCharging = "Battery & Power"
    case deviceFeatures = "Device Capabilities"
    case systemInterface = "System & Interface"
    case ipad = "iPad"
    case intelligence = "Intelligence"
    case advanced = "Advanced & Experimental"
    var id: String { rawValue }
    var symbolName: String {
        switch self {
        case .displayVisuals: "sparkles.rectangle.stack"
        case .batteryCharging: "battery.100.bolt"
        case .deviceFeatures: "cpu"
        case .systemInterface: "slider.horizontal.3"
        case .ipad: "ipad.landscape"
        case .intelligence: "sparkles"
        case .advanced: "exclamationmark.triangle"
        }
    }
}

enum RiskLevel: String, CaseIterable, Comparable {
    case low = "Low", medium = "Medium", high = "High"
    private var sortOrder: Int { switch self { case .low: 0; case .medium: 1; case .high: 2 } }
    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool { lhs.sortOrder < rhs.sortOrder }
}

enum VerificationStatus: String {
    case verified = "Cross-referenced"
    case experimental = "Experimental"
    case unknown = "Unknown"
    case requiresSetup = "Requires additional setup"
    var detail: String {
        switch self {
        case .verified: "The key appears in multiple supplied reference catalogs; this does not establish that the change works on this device or OS build."
        case .experimental: "The source describes this entry as experimental. Device and OS behavior are unverified."
        case .unknown: "The supplied sources do not establish runtime compatibility for this entry."
        case .requiresSetup: "This quick-reference entry is not wired to apply directly. Open MobileGestalt Studio for GestaltX presets; exact device and build behavior remains unverified."
        }
    }
}

enum CompatibilityStatus: String {
    case supported = "Supported"
    case experimental = "Experimental"
    case unsupported = "Unsupported"
    case unknown = "Unknown"
    case requiresSetup = "Requires additional setup"
}

/// Quick-reference entry. Device edits are staged and applied in MobileGestalt Studio.
struct Tweak: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let category: TweakCategory
    let risk: RiskLevel
    let status: VerificationStatus
    let minimumiOS: String
    let maximumiOS: String
    let iPhoneOnly: Bool
    let plistKey: String
    let isKeyVerified: Bool
    let deviceConditions: String
    let restartRequired: Bool
    let sourceReferences: String
    let sourceCompatibility: String
    let ios18: CompatibilityStatus
    let ios26: CompatibilityStatus
    let ios27: CompatibilityStatus
    var isEnabled: Bool = false

    var compatibilityLabel: String { "Runtime compatibility: Unknown" }
}

enum CapabilityCatalog {
    private static let common = "Listed in the GestaltX capability catalog; RustGestalt runtime behavior is unverified."
    private static let gestaltXOnly = "Listed in GestaltX's iOS 27.x catalog; not independently verified on a device or build."
    private static let setup: VerificationStatus = .requiresSetup
    private static let unknownOS: CompatibilityStatus = .requiresSetup
    static let tweaks: [Tweak] = [
        .init(id:"dynamic-island",title:"Dynamic Island",summary:"Capability flag for Dynamic Island-dependent system UI; it cannot add the physical display cutout.",category:.displayVisuals,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"YlEtTtHlNesRBMal1CqRaA",isKeyVerified:true,deviceConditions:"Hardware and display layout determine whether any system surface can use this capability.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Reference claims conflict by source and release; see the project compatibility report.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"always-on-display",title:"Always-On Display",summary:"Advertises Always-On Display capability. The panel must support the feature; forcing it can increase power use and burn-in risk.",category:.displayVisuals,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"2OOJf1VhaM7NxfRok3HbWQ, j8/Omm6s1lsmTDFsXjsBfA",isKeyVerified:true,deviceConditions:"Display hardware support is required. Unsupported panels may behave incorrectly.",restartRequired:true,sourceReferences:common,sourceCompatibility:"GestaltX documents iOS 27.x on-device access; exact build and device compatibility in RustGestalt remain unverified.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"aod-vibrancy",title:"Always-On Display Vibrancy",summary:"A rendering capability associated with the Always-On Display path.",category:.displayVisuals,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"ykpu7qyhqFweVMKtxNylWA",isKeyVerified:true,deviceConditions:"Requires an Always-On capable display and matching system implementation.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Conflicting source release ranges; no RustGestalt device verification.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"aod-high-luminance",title:"High-Luminance Always-On Display",summary:"Advertises a higher-brightness Always-On mode; the panel and system build determine any effect.",category:.displayVisuals,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"7brdL5xrEUWnlF9C0kdg5A",isKeyVerified:false,deviceConditions:"Panel-specific; effect and power impact are unknown.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX catalog only; exact build support unknown.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"aod-flipbook",title:"Always-On Display Flipbook",summary:"A capability associated with flipbook widgets on the Lock Screen.",category:.displayVisuals,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"aoJSd/MXk7M40NgXTM6x+g",isKeyVerified:false,deviceConditions:"Depends on the display and Lock Screen implementation.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX catalog only; exact build support unknown.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"aod-flipbook-count",title:"Always-On Flipbook Limit",summary:"A count value for Always-On flipbook entries; the source notes that accepted ranges vary by build.",category:.displayVisuals,risk:.high,status:.experimental,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"qqrspu7CpuPdZwSDxNY+Fg",isKeyVerified:false,deviceConditions:"Accepted value range is build-specific and not established.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"Experimental source entry; no exact supported builds documented.",ios18:.unknown,ios26:.unknown,ios27:.experimental),
        .init(id:"wallpaper-parallax",title:"Wallpaper Parallax",summary:"A Boolean capability reported to control wallpaper motion with device movement.",category:.displayVisuals,risk:.low,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"UIParallaxCapability",isKeyVerified:true,deviceConditions:"Effect may vary by wallpaper and system version.",restartRequired:false,sourceReferences:common,sourceCompatibility:"Listed across source catalogs; runtime behavior is not verified by RustGestalt.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"hdr-photo-display",title:"HDR Photo Display",summary:"Capability flag associated with HDR photo rendering.",category:.displayVisuals,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"a1r7npIrhXsZ7SmKRKC1eA",isKeyVerified:false,deviceConditions:"HDR display and matching system rendering support are required.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX catalog only; exact build support unknown.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"pwm-display",title:"PWM Display Capability",summary:"Advertises a panel dimming capability; setting a flag does not change the physical display.",category:.displayVisuals,risk:.high,status:.experimental,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"6IejgN+1Fmu5/QrZFOIeNw",isKeyVerified:false,deviceConditions:"Panel-specific; can create incorrect feature reporting.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"Experimental GestaltX entry; exact build support unknown.",ios18:.unknown,ios26:.unknown,ios27:.experimental),
        .init(id:"displayport",title:"DisplayPort Capability",summary:"Advertises external display output; compatible hardware is still required.",category:.displayVisuals,risk:.high,status:.experimental,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"CoWnN4xo783YGn4wLrUatA",isKeyVerified:false,deviceConditions:"Compatible USB-C/display hardware and OS support are required.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"Experimental GestaltX entry; exact build support unknown.",ios18:.unknown,ios26:.unknown,ios27:.experimental),
        .init(id:"liquid-glass-low-power",title:"Liquid Glass Low-Power Rendering",summary:"Capability associated with reduced-cost Liquid Glass rendering on newer systems.",category:.displayVisuals,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"SAGvsp6O6kAQ4fEfDJpC4Q",isKeyVerified:true,deviceConditions:"Only meaningful where Liquid Glass is present; the device and renderer affect behavior.",restartRequired:true,sourceReferences:"GestaltX capability catalog; RustGestalt runtime behavior is unverified.",sourceCompatibility:"GestaltX targets iOS 27.x on-device access; exact build and device compatibility in RustGestalt remain unverified.",ios18:.unsupported,ios26:unknownOS,ios27:unknownOS),
        .init(id:"boot-chime",title:"Boot and Shutdown Chime",summary:"Advertises the boot and shutdown sound capability; does not add hardware.",category:.deviceFeatures,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"QHxt+hGLaBPbQJbXiUJX3w",isKeyVerified:true,deviceConditions:"Hardware, region, and system sound policy may affect availability.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Listed by all three reference catalogs; no RustGestalt runtime verification.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"charge-limit",title:"Charge Limit Settings",summary:"Capability for displaying charge-limit settings; actual charge control depends on device hardware.",category:.batteryCharging,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"37NVydb//GP/GrhuTN+exg",isKeyVerified:true,deviceConditions:"Battery and charging hardware must support charge limits.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Listed by all three references; setting visibility does not establish charging behavior.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"tap-to-wake",title:"Tap to Wake",summary:"Capability associated with waking the display by touch on models where it is hidden.",category:.deviceFeatures,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"yZf3GTRMGTuwSV/lD7Cagw",isKeyVerified:true,deviceConditions:"Display digitizer and device support required.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Listed by all three references; device/build behavior unverified by RustGestalt.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"camera-control",title:"Camera Control Settings",summary:"Capability for Camera Control settings; cannot add a physical camera button.",category:.deviceFeatures,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"CwvKxM2cEogD3p+HYgaW0Q, oOV1jhJbdV3AddkcCg0AEA",isKeyVerified:true,deviceConditions:"Physical Camera Control hardware is required for button behavior.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Reference release ranges differ; exact target build is unknown.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"action-button",title:"Action Button Settings",summary:"Capability for Action Button settings; it does not add the physical button.",category:.deviceFeatures,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"cT44WE1EohiwRzhsZ8xEsw",isKeyVerified:true,deviceConditions:"Physical Action Button is required for button behavior.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Reference release ranges differ; exact target build is unknown.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"collision-sos",title:"Collision SOS",summary:"Capability for collision detection in Emergency SOS settings; requires supported sensors and hardware.",category:.deviceFeatures,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"HCzWusHQwZDea6nNhaKndw",isKeyVerified:true,deviceConditions:"Safety-critical hardware and calibration are required; a flag cannot create them.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Listed by supplied references; no device validation in RustGestalt.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"audio-mix",title:"Audio Mix Capability",summary:"Capability associated with supported media audio mixing.",category:.deviceFeatures,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"aVL5GE3tx0LSCI/ErfrJGA",isKeyVerified:false,deviceConditions:"Audio hardware, media format, and OS implementation dependent.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX catalog only; exact build support unknown.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"spatial-facetime-audio",title:"Spatial FaceTime Audio",summary:"Capability associated with spatial audio playback in FaceTime.",category:.deviceFeatures,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"/EVOCjM/Nmb2roP5ebtEFA",isKeyVerified:false,deviceConditions:"Compatible audio hardware and FaceTime implementation required.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX catalog only; exact build support unknown.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"apple-pencil",title:"Apple Pencil Settings",summary:"Capability for exposing Pencil settings; compatible iPad and Pencil hardware are required.",category:.ipad,risk:.medium,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"yhHcB0iH0d1XzPO/CFd3ow",isKeyVerified:true,deviceConditions:"iPad and compatible Apple Pencil hardware required.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Source references differ by OS; no RustGestalt runtime verification.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"stage-manager",title:"Stage Manager",summary:"Capability for Stage Manager; layout and performance depend on iPad hardware.",category:.ipad,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"qeaj75wk3HF4DwQ8qbIi7g",isKeyVerified:true,deviceConditions:"iPad display, memory, and hardware support are required.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Listed in supplied catalogs; supported model list is not verified here.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"ipad-app-compatibility",title:"iPad App Compatibility",summary:"Capability associated with iPad app compatibility types on iPhone.",category:.ipad,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:true,plistKey:"9MZ5AdH43csAUajl/dU+IQ",isKeyVerified:true,deviceConditions:"App compatibility and layout may break when the device family differs.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Source methods differ; no RustGestalt runtime verification.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"apple-intelligence",title:"Apple Intelligence Capability",summary:"Capability flag for generative model features; hardware, language, region, and Apple services remain independent requirements.",category:.intelligence,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"A62OafQ85EJAiiqKn4agtg",isKeyVerified:false,deviceConditions:"Compatible device, language/region, model availability, and Apple services required.",restartRequired:true,sourceReferences:"GestaltX capability catalog reference; independent confirmation is missing.",sourceCompatibility:"Not a supported RustGestalt operation; runtime behavior and compatibility are unverified.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"siri-on-device",title:"On-Device Siri Capability",summary:"Device-specific Siri capability. Changing its value may affect system Siri and Apple Intelligence behavior.",category:.intelligence,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"K/R1GfGfCkXvEhaPS2Vrng",isKeyVerified:false,deviceConditions:"Preserve the original value/type; effect depends on device and language models.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX catalog only; exact build support unknown.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"audio-intelligence",title:"Audio Intelligence",summary:"Capability flag for audio intelligence features.",category:.intelligence,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"rb2tKZxlj0Gm2tBmUQSLqQ",isKeyVerified:false,deviceConditions:"Model, language, services, and OS support unknown.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX describes this as an iOS 27 capability; exact build support unknown.",ios18:.unsupported,ios26:.unsupported,ios27:unknownOS),
        .init(id:"personal-translator",title:"Personal Translator",summary:"Capability flag associated with personal translation features.",category:.intelligence,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"M1n2sAqf33NAOgZRGxQYBA",isKeyVerified:false,deviceConditions:"Language model, device, and service requirements unknown.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX catalog only; exact build support unknown.",ios18:.unsupported,ios26:.unsupported,ios27:unknownOS),
        .init(id:"photos-clean-up",title:"Photos Clean Up",summary:"Capability flag associated with Photos image cleanup.",category:.intelligence,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"XNCjqOupLM/S8fNyxRNQTA",isKeyVerified:false,deviceConditions:"Hardware and Apple Intelligence availability required.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX catalog only; exact build support unknown.",ios18:.unsupported,ios26:unknownOS,ios27:unknownOS),
        .init(id:"handwriting-synthesis",title:"Handwriting Synthesis",summary:"Capability flag associated with handwriting synthesis models.",category:.intelligence,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"YgYIIViDt1kgzyIsIV61vA",isKeyVerified:false,deviceConditions:"Compatible hardware, language, and model support required.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX catalog only; exact build support unknown.",ios18:.unsupported,ios26:unknownOS,ios27:unknownOS),
        .init(id:"always-listening-siri",title:"Always-Listening Siri",summary:"Capability flag associated with always-listening voice activation.",category:.intelligence,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"TusANsf9Lfe3P/9fIXXSrQ",isKeyVerified:false,deviceConditions:"Microphones, language, privacy settings, and OS support required.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX catalog only; exact build support unknown.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"internal-features",title:"Apple Internal Features",summary:"Capability for internal menus and diagnostics. System services may behave differently.",category:.advanced,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"EqrsVvjcYDdxHBiQmGhAWw",isKeyVerified:true,deviceConditions:"Internal-only behavior; unexpected system changes possible.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Listed by supplied catalogs; exact effects and support vary by build.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"internal-build",title:"Internal Build Flag",summary:"System-wide internal-build capability. It is not merely a cosmetic storage setting.",category:.advanced,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"LBJfwOEzExRxzlAnSuI7eg",isKeyVerified:true,deviceConditions:"May alter behavior of multiple system services; high risk.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Listed by supplied catalogs; exact effects and support vary by build.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"security-research-device",title:"Security Research Device Flag",summary:"Changes a capability flag; it does not make a device an authorized Apple Security Research Device.",category:.advanced,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"XYlJKKkj2hztRP1NWWnhlw",isKeyVerified:true,deviceConditions:"Does not grant security-research entitlements or device status.",restartRequired:true,sourceReferences:common,sourceCompatibility:"Listed by supplied catalogs; no effect is established by the key listing alone.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS),
        .init(id:"internal-settings",title:"Internal Settings Bundle",summary:"Capability for Apple's internal Settings bundle; system behavior may change unexpectedly.",category:.advanced,risk:.high,status:.requiresSetup,minimumiOS:"unknown",maximumiOS:"unknown",iPhoneOnly:false,plistKey:"Oji6HRoPi7rH7HPdWVakuw",isKeyVerified:false,deviceConditions:"Internal-only system component; effect and safety are unknown.",restartRequired:true,sourceReferences:gestaltXOnly,sourceCompatibility:"GestaltX catalog only; exact build support unknown.",ios18:unknownOS,ios26:unknownOS,ios27:unknownOS)
    ]
}

typealias MockTweakData = CapabilityCatalog
