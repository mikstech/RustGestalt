# Architecture

This describes the iPhone app target as it exists in this repository. There
is no server-side or macOS code here to document yet.

## Project layout

```
RustGestalt/
├── RustGestaltApp.swift          # App entry point
├── Models/
│   ├── PairingPayload.swift      # QR payload parsing (rustgestalt://pair?...)
│   ├── Theme.swift                # Theme presets, resolved via environment
│   └── Tweak.swift                # Reference capability catalog model
├── Services/
│   ├── AppState.swift             # App-wide observable state
│   ├── PairingManager.swift       # Handshake, cert pinning, Keychain session
│   └── QRScannerView.swift        # AVFoundation camera scanning
├── Views/
│   ├── RootView.swift
│   ├── HomeView.swift
│   ├── PairingView.swift
│   ├── TweakLibraryView.swift
│   ├── TweakDetailView.swift
│   ├── TweakRow.swift
│   ├── MobileGestaltStudioView.swift   # On-device read/write UI
│   ├── CreatorStudioView.swift          # Logo Shelf / Web Clip export
│   ├── RetroLaunchStudioView.swift
│   └── SettingsView.swift
├── Upstream/GestaltX/              # Adapted third-party source — see
│                                    # UPSTREAM-NOTICE.md in this folder
├── LogoPacks/                       # Supplied icon artwork (see
│                                    # Artwork-Sources.txt)
├── Resources/
│   └── InfoPlist-Additions.xml      # Usage-description strings to merge in
└── Assets.xcassets/
```

## Data flow, roughly

1. **Pairing:** `QRScannerView` → `PairingPayload` (parse) →
   `PairingManager` (cert-pinned handshake, Keychain session) → `AppState`.
2. **Status polling:** `PairingManager` polls the companion's authenticated
   status endpoint; results flow into `AppState` and render in `HomeView`.
3. **Tweak Library:** `Tweak.swift` holds a static, read-only reference
   catalog — this does not read or write the device; it's informational.
4. **MobileGestalt Studio:** reads/writes happen on-device through the
   `Upstream/GestaltX` bridge (`GestaltManager`, `DeviceBoundPlist`, the
   Objective-C `worse_query`/`GXCacheDirectory` layer). This path requires
   the `group.com.rustgestalt.app` App Group entitlement and a physical
   device; it does not depend on the Desktop Companion.
5. **Creator Studio / Logo Shelf:** reads `LogoPacks/`, builds a Web Clip
   configuration profile for export — no device write involved.
6. **Retro Launch Studio:** purely presentational; reads `LogoPacks/` for
   artwork and renders a role-play UI, no real app interaction.

## Why GestaltX is a separate folder

`Upstream/GestaltX/` is kept as its own folder, with its own `LICENSE` and
`UPSTREAM-NOTICE.md`, specifically so the adapted third-party source stays
easy to tell apart from RustGestalt's own code — both for license
compliance (GPL-3.0-only requires preserving notices) and so contributors
know which files come from upstream provenance tracked in that notice file
versus which are fair game to redesign freely.
