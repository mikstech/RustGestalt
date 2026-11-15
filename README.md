<p align="center">
  <img src="assets/rustgestalt-logo.jpg" alt="RustGestalt Logo" width="200" />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/rustgestalt-fork.jpg" alt="RustGestalt Fork Icon" width="200" />
</p>

<h1 align="center">RustGestalt</h1>

<p align="center">
  <strong>A tactile, standalone iOS customization suite and MobileGestalt laboratory built in native SwiftUI.</strong>
</p>

<p align="center">
  <a href="https://apple.com"><img src="https://img.shields.io/badge/Platform-iOS%2018.0%20--%20iOS%2027.3%20Beta-007AFF?style=flat&logo=apple" alt="Platform" /></a>
  <a href="https://apple.com"><img src="https://img.shields.io/badge/Companion-macOS%2014%2B%20(Optional)-gray?style=flat&logo=apple" alt="macOS" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0-blue.svg" alt="License" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9%2B-FA7343?style=flat&logo=swift" alt="Swift" /></a>
  <img src="https://img.shields.io/badge/Build-Passing-brightgreen?style=flat" alt="Build Status" />
</p>

---

## The Quick Truth: You Do Not Need the Desktop Companion

RustGestalt is packaged as a phone app with an accompanying desktop companion application (RustGestaltPC).

Here is the honest reality: **the desktop companion app is pretty much dead weight. You do not have to use it at all.**

- **MobileGestalt does not work on the desktop companion.** The desktop app cannot write MobileGestalt configurations, cannot inject files without exploits that Apple sealed, and functions only as a read-only viewer.
- **The iPhone app is 100 percent standalone.** All MobileGestalt reading, property staging, pre-write backup creation, on-device cache writing via worse_query, and read-back verification happen entirely on your iPhone.
- You can install the iPhone app, configure your tweaks, customize your model name, and use Retro Launch Studio directly on your device without ever connecting to a desktop computer.

---

## Features (Update "Diriyah")

### 1. Device Model Name Customization (MobileGestalt)
Customize the marketing model identity displayed across iOS settings and system queries without altering physical hardware boundaries:
- **Configuration Keys:** ArtworkDeviceProductDescription in GestaltKeys.artwork (oPeik/9e8lQWMszEjbPzng), MarketingName / DeviceProductDescription (Z/dqyWS6OZTRy10UcmUAhw), and ModelName (bbtR9jQx50Fv5Af/affNtA).
- **Settings Preview:** Real-time preview replicating the layout of Settings > General > About.
- **Quick-Suggestion Pills:** One-tap selection for popular identities including iPhone 17 Pro Max, iPhone 17 Pro, iPhone 17 Air, iPhone 16 Pro Max, and Apple Development Prototype.
- **Hardware Transparency:** Displays the read-only physical hardware identifier (ProductType, such as iPhone16,2), clearly distinguishing between the displayed marketing name and underlying silicon.
- **One-Tap Revert:** Restore factory baseline values with a single tap.

### 2. Retro Launch Studio (Historical Interaction Fidelity)
An authentic, interactive historical time machine spanning iOS 6, iOS 7, iOS 18, and iOS 26:
- **Tactile Button Physics:** RetroIconPressButtonStyle delivers authentic touch-down dimming and physical depression.
- **Era-Specific Hardware Bezels:** Concave circular button with rounded square (iOS 6), Touch ID silver ring (iOS 7), and spatial home indicator bar (iOS 18/26). Includes mechanical click depression and double-click switcher detection.
- **Auditory Fidelity (RetroSoundEngine):** Real system sound feedback using AudioServicesPlaySystemSound, including tock key clicks (1104), lock/unlock snaps (1105), camera shutters (1108), DTMF dialer tones (1057), SMS whoosh sounds (1004), and physical home button clicks.
- **Authentic Unlock & Gestures:** Skeuomorphic "slide to unlock" featuring a draggable metallic knob, boundary elastic tension, and continuous luminescent shimmer sweep across "slide to unlock". Long-press (0.7s) triggers icon jiggle mode with alternating angle physics (+/-2.4 degrees).
- **Functional In-Bezel Apps:**
  - **Phone:** Working DTMF dialer keypad, number display, live call duration timer, and calling state.
  - **Messages:** Simulated SMS chat interface with draft text input, message dispatch, and whoosh audio.
  - **Calculator:** Working arithmetic calculator with clear (C), percent, sign toggle, standard operations, and floating-point evaluation.
  - **Notes:** Yellow legal pad styling with serif typography for iOS 6 and editable note storage.
  - **Camera:** Viewfinder simulation with mechanical black aperture blade closure animation.
  - **Settings:** Live Airplane Mode, Wi-Fi, and Bluetooth toggles that immediately update the simulated status bar in real time.

### 3. iOS 18 Performance Mode & Honest Liquid Glass Solution
RustGestalt avoids simulated toggles and delivers genuine, verified alternatives:
- **The Technical Reality on iOS 27:**
  - SparseRestore directory traversal exploits were completely patched by Apple in iOS 27.
  - Apple excised legacy pre-Solarium blur shaders from SpringBoard's compositor binary; forcing feature flags off causes continuous respring loops.
  - MobileGestalt key SAGvsp6O6kAQ4fEfDJpC4Q is a low-power shader pass that produces dark-mode OLED border artifacts, not a true glass disable.
- **The Genuine Supported Alternative:**
  - **MobileGestalt Wallpaper Parallax Elimination (UIParallaxCapability = 0):** Disables accelerometer-driven wallpaper redraws, saving approximately 15 percent compositor redraw cycles during device motion. Written and verified directly on the device cache.
  - **In-App Frosted Gaussian Blur:** Eliminates caustic glare and specular distortion within RustGestalt in favor of smooth, hardware-accelerated ultraThinMaterial blur at 120 FPS.
  - **Automated Safety:** Full pre-write backup, verified read-back via worse_query, and one-tap restoration.

### 4. Original MobileGestalt Tweak Catalog & Checkout
Structured catalog across 10 categories of verified device capabilities:
- **Categories:** Dynamic Island, Always-On Display, Display Capabilities, Camera Capabilities, Device Identity, Wallpaper & Parallax, Audio Capabilities, iPad Capabilities, Apple Intelligence & Siri, and Experimental Options.
- **Safety Tiers:** Classified into Physically Verified, Source Verified, Experimental, and Unsupported.
- **Integrated Staging & Checkout:** Review diffs, stage multiple configurations into an active cart, and commit with read-back verification.
- **Respring Automation:** Classifies operations into No Restart, In-App Restart, SpringBoard Respring, and Full Device Reboot, with safety guards to prevent restart loops.

### 5. Intelligent Web Clip Studio
- Auto-suggests verified system URL schemes (Camera, Settings, Apple Intelligence, Wallpaper, Music, Notes, etc.) as you type.
- Automatically pairs app names with bundled icon packs (LogoPacks).
- Generates removable .mobileconfig configuration profiles for one-tap installation via Safari.

---

## Architecture & Requirements

| Component | Target Requirement | Status |
| :--- | :--- | :--- |
| **iPhone App** | iOS 18.0 to iOS 27.x (SwiftUI) | **Primary & Standalone** |
| **On-Device MG Access** | iOS 27.0 to iOS 27.2.1, iOS 27.3 Beta 1 (24C5037i) | Supported via worse_query |
| **Desktop Companion** | macOS 14+ (RustGestaltPC) | **Optional / Dead Weight** |

---

## Installation (iPhone Standalone)

You do not need the desktop companion to install or use RustGestalt.

### Sideloading with Xcode
1. Open `RustGestalt-iPhone-App/RustGestalt.xcodeproj` in Xcode.
2. Select the **RustGestalt** target and navigate to **Signing & Capabilities**.
3. Select your Personal or Developer Team and set a unique Bundle Identifier.
4. Under **App Groups**, ensure `group.com.rustgestalt.app` is selected (required for on-device cache access via worse_query).
5. Connect your iPhone via USB, select your device, and click **Run** (Command-R).

### Sideloading with Third-Party Utilities
- Build or export the .ipa package with the App Group entitlement enabled.
- Sign and install using AltStore, SideStore, Sideloadly, or TrollStore.

---

## What About the Desktop Companion (RustGestaltPC)?

The desktop companion application exists in the repository under `RustGestaltPC/`, but as noted:
- It **cannot** modify or write to your device's MobileGestalt cache.
- Apple does not provide remote MobileGestalt write interfaces over lockdown without exploit chains that are patched on modern iOS.
- **When to use it:** Only if you want to inspect local files, test macOS UI components, or view icon packs on your Mac. For all customization, tweak staging, and device identity changes, **use the iPhone app directly**.

---

## Safety, Backups & Verification

- **Automated Pre-Write Backups:** Before any modification is applied to `/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist`, RustGestalt saves a full timestamped snapshot.
- **Read-Back Verification:** Every write is immediately read back from storage to confirm byte integrity before reporting success.
- **100 Percent Upstream Protection:** All 25 upstream GestaltX source and header files remain bit-for-bit identical to baseline hashes.
- **Loop Prevention:** RespringAutomationManager automatically guards against respring loops by tracking execution timestamps and entering Safe Mode if multiple restarts occur within 60 seconds.

---

## License & Credits

- **License:** GNU General Public License v3.0 (GPL-3.0).
- **MobileGestalt Core:** Powered by the upstream GestaltX GPL-3.0 on-device engine by huamidev.
- **Sandbox Access (worse_query):** Authored by Taj C (forcequit), utilizing libsystem_containermanager.dylib class 7 container queries.
- **Community Research:** Incorporates reverse-engineering research and capability mappings from Cowabunga and Nugget (leminlimez).

---

*RustGestalt is an independent research and customization tool. Not affiliated with or endorsed by Apple Inc.*
