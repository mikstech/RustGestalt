# GestaltX integration notice

RustGestalt's iPhone target incorporates selected implementation files from the approved
GestaltX project under GPL-3.0-only. The source files retain their SPDX and copyright
headers; the full license is `LICENSE` and is included in the app bundle.

Approved fork: <https://github.com/thsrite/gestaltx>

Source checked: fork `main`, commit
`c6c22fc44da67e5c22e6fd7cf00a1cece4b4376d` (2026-11-13 audit). GestaltX is a fork of
`huamidev/GestaltX`; its latest checked published parent release is `v1.0.7`, commit
`dfd4a7e3a8b8a89e76ac025a2a37242a7ed4c41f`. The upstream project states iOS/iPadOS 27.x
as its on-device MobileGestalt target. RustGestalt does not claim all 27.x builds or
devices work.

## Included GestaltX files

- Swift core: `Capabilities.swift`, `DeviceBoundPlist.swift`, `DeviceCacheOptions.swift`,
  `DevicePlistIdentity.swift`, `GestaltDocument.swift`, `GestaltManager.swift`,
  `Localization.swift`, `MobileGestaltCacheLayout.swift`, `SharedImportQueue.swift`,
  `SharedPlistInbox.swift`, `TemporaryExport.swift`, and `VersionSupport.swift`.
- Objective-C access and bridge: `worse_query.h/.m`, `GXCacheDirectory.h/.m`,
  `GXDeviceIdentity.h/.m`, `GXEntitlementsReader.h/.m`, and `GXMobileGestaltImage.h/.m`.
- The feature UI in `Views/MobileGestaltStudioView.swift` and Xcode/App Group wiring are
  RustGestalt integration code; they are not copied GestaltX files.

The included `Capabilities.swift` upstream header says its public key mappings were
cross-checked against MGKeys, Nugget, and mond, and that preset behavior is implemented in
GestaltX. RustGestalt selected GestaltX as the upstream implementation; this notice
preserves the source's stated key-mapping provenance. Nugget source, code, and presets
were not used as a fallback or copied into the app. Erosion was inspected for its support
range but no Erosion implementation source was copied.

The app uses the signed `group.com.rustgestalt.app` entitlement so GestaltX's upstream
access routine can select a group actually present in RustGestalt's provisioning. Register
that App Group for the chosen Apple Developer team and ensure the provisioning profile
contains it. No GestaltX signing identifier is reused.

The integrated manager records originals, stages before/after changes, saves a verified
backup before a write, verifies the write by reading back the file, and supports restoring
matching saved backups. RustGestalt's UI further limits access to the upstream-reported
iOS 27.0–27.2.1 version range and the exact iOS 27.3 beta 1 build `24C5037i`; exact-build
and device behavior remains unverified by RustGestalt until tested on those combinations.

The Advanced preset category is not exposed in RustGestalt's UI. The repository still
contains its upstream source file intact, with its provenance and license.
