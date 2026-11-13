# Security Policy

RustGestalt is an alpha-stage hobby project, not production software. Use it
on devices and data you're willing to risk.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for a security problem. Instead,
contact the maintainer privately (open a private security advisory on this
repository, if GitHub's private vulnerability reporting is enabled for it,
or reach out through whatever contact method the repository's profile
lists). Include:

- What you found and how to reproduce it.
- Which build/commit you tested against.
- Your assessment of impact, if you have one.

There's no bug bounty here — this is an independent project.

## Scope notes

- **Pairing:** the iPhone app pins the Desktop Companion's certificate by
  SHA-256 fingerprint from the QR code and stores the session in Keychain.
  If you find a way to bypass the pinning or forge a pairing handshake,
  that's in scope and worth reporting.
- **MobileGestalt Studio / GestaltX bridge:** this feature incorporates
  files adapted from the GestaltX project (GPL-3.0-only), documented in
  [`RustGestalt/Upstream/GestaltX/UPSTREAM-NOTICE.md`](RustGestalt/Upstream/GestaltX/UPSTREAM-NOTICE.md).
  One of those files, `worse_query`, is upstream-labeled by its own author as
  a sandbox-escape proof-of-concept for iOS 26/27. It is included here under
  its original GPL-3.0-only license with its scope restricted to a signed
  App Group container RustGestalt itself provisions — not as new exploit
  work by this project, and not extended beyond what the upstream file
  already does. If you believe RustGestalt's integration of it introduces a
  *new* risk beyond the upstream file's own documented behavior (for
  example, exposing it somewhere a user didn't ask for, or outside the App
  Group it's scoped to), please report that.
- **Backups:** MobileGestalt Studio backups live only on-device, unencrypted
  in the app's own storage. Physical device access or another app with
  access to the same container is a relevant threat model.

## Known-risky, not treated as a vulnerability

- The MobileGestalt Studio build/version gate is a UI-level allowlist, not a
  security boundary — it exists to limit the app to builds its upstream
  claims support, not to prevent determined misuse.
- Nothing in this repo has been audited by a third party.
