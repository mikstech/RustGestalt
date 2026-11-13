# Changelog

All notable changes to this project are recorded here. This project is in
alpha and does not yet follow a formal release/versioning scheme — entries
are dated, not numbered, until a first tagged release exists.

## [Unreleased]

### Added
- Real QR pairing to a Desktop Companion: AVFoundation scanning, certificate
  pinning by fingerprint, manual 4-digit fallback, Keychain session storage.
- Home, Tweak Library, Tweak Detail, and Settings screens with search,
  categories, and risk/compatibility display.
- Theme system with 7 presets (Rust, Midnight, Frost, Lavender, Forest,
  Monochrome, Sunset), light/dark previews, persisted via `@AppStorage`.
- Reference capability catalog: 33 source-referenced entries with risk,
  device conditions, and conservative iOS 18/26/27 status fields.
- MobileGestalt Studio: on-device read, staged GestaltX-derived presets,
  before/after review, verified pre-write backup, read-back verification,
  and matching restore. Gated to iOS 27.0–27.2.1 and exact build `24C5037i`.
- Logo Shelf: 409 supplied icons across iOS 6, 7, 18, and 26 styles (iOS 18
  split into Light/Dark/Tinted), with Web Clip configuration-profile export.
- Retro Launch Studio: animated Home Screen role-play for iOS 6/7/18/26.
- GitHub repository scaffolding: README, LICENSE, CONTRIBUTING, SECURITY,
  this changelog, `.gitignore`/`.gitattributes`, `docs/`, `screenshots/`.

### Known gaps (not yet implemented)
- No device-tested compatibility results for any build or model.
- Desktop Companion remains read-only for MobileGestalt; not included in
  this repository.
- No backup sync to the iPhone.
- No Bonjour/local-network auto-discovery for the pairing host.
- Logo Shelf artwork licensing not reviewed pack-by-pack.

See [`docs/KNOWN-ISSUES.md`](docs/KNOWN-ISSUES.md) for more detail.
