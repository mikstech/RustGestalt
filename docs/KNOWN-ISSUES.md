# Known Issues

Findings from a source-level audit of this repository (no build/run testing
was performed — no Xcode toolchain was available to do that). Nothing here
is a confirmed runtime bug; these are things to verify or watch for.

## Compatibility

- **No device or build has actually been tested.** The MobileGestalt Studio
  version gate (iOS 27.0–27.2.1, plus exact build `24C5037i`) reflects what
  the upstream GestaltX project reports, not anything RustGestalt itself has
  verified. Treat every build inside that range as unverified until someone
  actually tries it and reports back.
- The app's own deployment target is iOS 17.0+, but MobileGestalt Studio's
  write path only functions on the much narrower iOS 27.x range above — the
  rest of the app (pairing, theming, Logo Shelf, Retro Launch Studio) is not
  restricted by that gate.

## Pairing

- There's no automatic discovery of the Desktop Companion's host address —
  you need the IP from the QR code or the manual-code flow. If the
  companion's IP changes (new network, DHCP lease renewal), pairing has to
  be redone.
- The `#if DEBUG` test-QR button is for exercising the scanner only; it
  can't complete a real handshake. Don't rely on it to validate pairing
  end-to-end.

## Backups

- MobileGestalt Studio backups are on-device only, unencrypted in app
  storage, and not synced anywhere. Losing or wiping the device loses the
  backup.

## Licensing / distribution

- Logo Shelf artwork (`RustGestalt/LogoPacks/`) is from four user-supplied
  community packs. None of their individual license terms have been
  reviewed by this project — see `Artwork-Sources.txt`. Don't redistribute
  a build containing this artwork until that's checked.
- `worse_query` (under `Upstream/GestaltX/`) is upstream-labeled as a
  sandbox-escape proof-of-concept. It's included here under its original
  GPL-3.0-only license, scoped to RustGestalt's own App Group. See
  `RustGestalt/Upstream/GestaltX/UPSTREAM-NOTICE.md` and `SECURITY.md`
  before building on or extending that part of the code.

## Source-level observations (not necessarily bugs)

- A small number of force-unwraps (`!`) exist in the GestaltX bridge files
  (`DevicePlistIdentity.swift`, `SharedPlistInbox.swift`) — these are
  adapted upstream code, not newly introduced, but worth keeping an eye on
  if crashes show up during on-device testing.
- No automated tests exist in this repository yet.

---

Found something else? Please file it as a GitHub issue rather than adding it
directly here — see [`CONTRIBUTING.md`](../CONTRIBUTING.md).
