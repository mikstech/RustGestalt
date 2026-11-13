# RustGestalt

![Status](https://img.shields.io/badge/status-alpha-orange)
![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![License](https://img.shields.io/badge/license-GPL--3.0--only-blue)

An iOS and iPadOS customization toolkit with a companion macOS application.

> **This is an alpha build.** It has not been tested across devices or iOS
> versions. Nothing in this README is a compatibility guarantee — see
> [Known limitations](#known-limitations) and
> [`docs/KNOWN-ISSUES.md`](docs/KNOWN-ISSUES.md).

## What this is

RustGestalt pairs an iPhone/iPad app with a macOS Desktop Companion to explore
device customization: MobileGestalt capability inspection, icon theming, and
retro iOS presentation. This repository currently contains **the iPhone app
only**. The macOS companion is a separate, not-yet-published part of the
project.

The broader goal is a platform for device customization, experimentation,
technical research, and technology content creation. What's below is what
exists in this app today — not the long-term vision.

## Feature overview

| Area | Status |
|---|---|
| QR pairing to Desktop Companion | Implemented |
| Home / Tweak Library / Detail / Settings | Implemented |
| Theme system (7 presets, light/dark) | Implemented |
| Reference tweak catalog (33 entries, read-only) | Implemented |
| MobileGestalt Studio (on-device read/write) | Implemented, narrow device gate |
| Logo Shelf → Web Clip export | Implemented |
| Retro Launch Studio | Implemented (visual simulation only) |
| macOS Companion | Not in this repo |
| Backup sync to iPhone | Not implemented |
| Bonjour auto-discovery of pairing host | Not implemented |

### Pairing

The iPhone app scans a QR code shown by the Desktop Companion
(`rustgestalt://pair?code=XXXX&host=<ip>&fp=<fingerprint>`), or accepts a
manual 4-digit code. It pins the companion's self-signed certificate to the
fingerprint from the QR code, completes a one-time HTTPS handshake, and
stores the resulting session in Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
Once paired, it polls the companion for device name, product identifier,
hardware identifier, iOS version, and exact build string.

There is no automatic discovery yet — you need the host IP from the QR code
or the manual code flow, and the companion app running and reachable on the
local network.

### MobileGestalt Studio

A screen for on-device MobileGestalt capability inspection and editing,
built on an on-device access layer adapted from the GestaltX project (see
[Credits and third-party licenses](#credits-and-third-party-licenses)). It
supports staged before/after review, a backup written before any write, and
read-back verification after writing, with matching restore from a saved
backup.

Access is currently gated to the iOS 27.0–27.2.1 range plus one exact iOS
27.3 beta 1 build (`24C5037i`); other builds are blocked in the UI. That
gate reflects what the upstream project reports working with — it is not a
claim that RustGestalt has tested every device or build inside that range,
and nothing outside it has been tried at all. Requires a physical iPhone and
a provisioning profile that includes the `group.com.rustgestalt.app` App
Group.

### Logo Shelf & Web Clip export

409 supplied icon images across iOS 6, 7, 18, and 26 styles (iOS 18 adds
separate Light/Dark/Tinted sets). You pick an image, give it a label and a
URL, and export a Web Clip configuration profile the user installs through
iOS Settings. A Web Clip is a separate Home Screen shortcut — it does not
replace or retheme an existing app's real icon.

See [`RustGestalt/LogoPacks/Artwork-Sources.txt`](RustGestalt/LogoPacks/Artwork-Sources.txt):
this artwork comes from user-supplied community icon packs, and the original
creators retain their rights. Review each pack's terms before distributing a
build that bundles this artwork.

### Retro Launch Studio

An animated role-play of iOS 6/7/18/26 Home Screens built from the Logo
Shelf artwork. Tapping an icon opens a visual preview of what tapping that
app used to look like — it does not install, launch, or otherwise touch any
real app.

## iOS / iPadOS compatibility

- Deployment target: iOS 17.0+ (the codebase uses `NavigationStack`,
  the two-parameter `onChange(of:)`, and recent `ToolbarItem` APIs — lower
  the deployment target only after adjusting those call sites).
- Requires `arm64` (`UIRequiredDeviceCapabilities`).
- MobileGestalt Studio's write path is additionally gated to the specific
  iOS 27.x builds listed above, independent of the app's deployment target.
- No device or build outside what's stated above has been verified.

## macOS Companion

The macOS Desktop Companion is part of the overall RustGestalt project but
is **not included in this repository**. The iPhone app expects it to be
running on the local network during pairing and during MobileGestalt status
polling; nothing here bundles or redistributes it.

## Installation

RustGestalt is source-only right now — there's no signed release build to
install. To run it, build it yourself (see below) and install it on your own
device through Xcode with your own Apple Developer account.

## Building

1. Open `RustGestalt.xcodeproj` in Xcode.
2. In **Signing & Capabilities**, select your own team and a bundle
   identifier you control.
3. Add **App Groups**, and register/select `group.com.rustgestalt.app`. Your
   provisioning profile must include that group or the on-device access
   layer will refuse access.
4. Add the camera and local-network usage descriptions from
   [`RustGestalt/Resources/InfoPlist-Additions.xml`](RustGestalt/Resources/InfoPlist-Additions.xml)
   to the target's Info settings if they aren't already present.
5. Build and run on a **physical iPhone** — the simulator has no camera, so
   QR pairing can't be exercised there. A `#if DEBUG` button renders a test
   QR code for scanning from a second device or a printed screenshot; it
   cannot complete a real pairing by itself.
6. Review the icon-pack terms in `Artwork-Sources.txt` before distributing
   any build that contains `RustGestalt/LogoPacks`.

## Device pairing documentation

See [Pairing](#pairing) above for the protocol and payload format. There is
currently no written spec for the Desktop Companion side of the handshake in
this repository, since the companion isn't published here yet.

## Backup and recovery

MobileGestalt Studio writes a verified backup before applying any change on
device, and can restore a matching backup. Backups are **not** currently
synchronized off the device — if you lose the device or reinstall the app,
you lose the backup with it. There is no cloud or Desktop Companion backup
path yet.

## Known limitations

- No device or iOS build has been through real compatibility testing by this
  project; the version gate in MobileGestalt Studio reflects upstream's
  stated range, not RustGestalt's own verification.
- The Desktop Companion remains read-only for MobileGestalt data; on-device
  read/write only happens in this iPhone app.
- Web Clip profiles are separate shortcuts, not real icon replacement.
- Logo Shelf artwork licensing has not been reviewed pack-by-pack; see
  `Artwork-Sources.txt`.
- No backup sync to the iPhone, and no Bonjour/local-network auto-discovery
  for pairing — you need the host address from the QR code or a manual code.
- See [`docs/KNOWN-ISSUES.md`](docs/KNOWN-ISSUES.md) for the rest.

## Security considerations

- Pairing pins the companion's certificate by SHA-256 fingerprint from the
  QR code and stores the session in Keychain with
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- MobileGestalt Studio's write path requires a signed App Group entitlement
  and runs only on a physical device.
- This repository bundles source adapted from the GestaltX project under its
  GPL-3.0-only license, including an on-device access routine whose upstream
  origin is a sandbox-escape proof-of-concept. See
  [`RustGestalt/Upstream/GestaltX/UPSTREAM-NOTICE.md`](RustGestalt/Upstream/GestaltX/UPSTREAM-NOTICE.md)
  for exactly which files, their provenance, and the scope RustGestalt
  restricts them to. See also [`SECURITY.md`](SECURITY.md).
- Never commit `embedded.mobileprovision`, signing certificates, or any
  built `.ipa`/`.dSYM` to this repository — `.gitignore` excludes them, but
  double-check before pushing.

## Credits and third-party licenses

- **GestaltX** (GPL-3.0-only) — selected on-device MobileGestalt
  implementation and access-layer files are adapted from the approved fork
  at <https://github.com/thsrite/gestaltx> (commit
  `c6c22fc44da67e5c22e6fd7cf00a1cece4b4376d`), itself a fork of
  `huamidev/GestaltX`. Full provenance, included files, and scope
  restrictions are documented in
  [`RustGestalt/Upstream/GestaltX/UPSTREAM-NOTICE.md`](RustGestalt/Upstream/GestaltX/UPSTREAM-NOTICE.md).
  No Erosion or Nugget implementation source is included.
- **Logo Shelf artwork** — user-supplied community icon packs (iOS 6, iOS 7,
  iOS 18 FR, iOS 26). Original creators retain their rights; see
  `RustGestalt/LogoPacks/Artwork-Sources.txt`.

Because this repository incorporates GPL-3.0-only code, the iPhone app and
its corresponding source as a whole are distributed under GPL-3.0-only — see
[`LICENSE`](LICENSE).

## Development status

**Alpha.** Functionality described above exists in the code, but none of it
has been verified across real devices or iOS builds beyond what's stated.
Expect missing error handling, untested edge cases, and features that work
on one build and not another. Report problems — see
[`CONTRIBUTING.md`](CONTRIBUTING.md).
