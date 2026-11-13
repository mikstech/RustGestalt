# Contributing to RustGestalt

Thanks for taking a look. This project is in **alpha** — expect rough edges,
and please file issues rather than assuming something is intentional.

## Reporting bugs

Open an issue with:
- Device model and exact iOS build (Settings → General → About → look for
  the build number, not just the version).
- Whether you're on this repo's `main` branch or a fork/modified build.
- Steps to reproduce, and what you expected vs. what happened.
- For MobileGestalt Studio issues specifically: the exact build string shown
  on that screen, since access there is gated by build, not just version.

## Reporting a vulnerability

See [`SECURITY.md`](SECURITY.md) — please do not open a public issue for a
security problem.

## Code contributions

1. Fork and branch from `main`.
2. Keep changes scoped — a PR that touches pairing, theming, and the
   GestaltX bridge all at once is hard to review.
3. If your change touches `RustGestalt/Upstream/GestaltX/`, say so explicitly
   in the PR description, and note whether you're modifying adapted upstream
   code or writing new RustGestalt-only code. This keeps the provenance
   notes in `UPSTREAM-NOTICE.md` accurate.
4. Because this repository includes GPL-3.0-only code, any contribution you
   submit is understood to be offered under GPL-3.0-only terms as well.
5. Don't add compatibility claims, device support, or "tested on" notes to
   the README unless you've actually verified them yourself.

## What not to submit

- New sandbox-escape, jailbreak-exploit, or other vulnerability code. The
  one upstream file of that kind already in this repo (`worse_query`) is
  here under its original license with its scope documented in
  `UPSTREAM-NOTICE.md` — this project isn't a place to add more exploit
  code or to extend what that file does.
- Signing certificates, provisioning profiles, API keys, or any other
  secrets. `.gitignore` tries to catch these, but check your diff before
  opening a PR.
- Redistributed Logo Shelf artwork from packs whose terms you haven't
  checked — see `RustGestalt/LogoPacks/Artwork-Sources.txt`.
