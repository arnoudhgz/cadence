# Changelog

All notable changes to Cadence are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-05-15

### Added
- Back / forward web history navigation in the window title bar with ⌘[ / ⌘] keyboard shortcuts. Two-finger trackpad swipe-back/forward also enabled.
- Window occlusion awareness — when Cadence's main window is hidden, minimized, or fully covered by other apps, the JS bridge stops emitting periodic state and the metadata poll pauses. Media keys, AirPods stem clicks, and the menubar mini-player keep working unchanged.
- Window title shows the current track ("{title} — {artist}") so ⌘-Tab and Mission Control surface what's playing without opening the window.
- Hovering the menubar C-icon shows the current track as a tooltip.

### Changed
- Menubar uses a custom Cadence brand icon (C-shape with play triangle) instead of a generic SF Symbol.
- Window title bar painted Cadence purple (`#2D1B43`, sampled from the brand icon) so the chrome matches the new player bar instead of using the default system grey.
- YT Music's bottom player bar is themed in Cadence's palette: same `#2D1B43` purple background and every control icon (play / pause / skip / like / dislike / volume / repeat / shuffle / menu / eject) tinted neon cyan with a soft outer glow.
- Document scrollbar track tinted to match the title bar so the right edge of the window reads as branded chrome rather than the WebView's default grey gutter.
- Now Playing updates are incremental — the info dictionary is only patched with keys that actually changed, and elapsed time is pushed only on play/pause, track-change, or detected seeks. Control Center extrapolates the scrubber from PlaybackRate between updates.
- The JS bridge's `MutationObserver` disconnects after attaching to the YT Music `<video>` element instead of watching the whole document subtree forever. Reattaches automatically if YT Music swaps the element on navigation.
- Artwork cache in `NowPlayingController` is now an `NSCache` bounded to 16 entries (was unbounded), keeping memory flat across long sessions.

### Fixed
- WebKit native scrollbars rendered as chunky white tracks against YT Music's dark theme on systems set to "Always show scrollbars". Cadence now ships a slim translucent scrollbar style that respects the dark theme.
- YT Music's per-carousel scroll-position indicators (chunky light bars under each tile row) no longer show — the carousel arrow buttons provide navigation, so the indicator just added visual noise on the dark theme.

## [0.1.0] - 2026-05-11

First public release.

### Added
- Native SwiftUI shell wrapping `music.youtube.com` in a `WKWebView`.
- Native macOS Now Playing integration via `MPNowPlayingInfoCenter` — current track, artist, artwork, and scrubber show in Control Center.
- Media-key support (F7 / F8 / F9), AirPods stem clicks, and Bluetooth headset remote control via `MPRemoteCommandCenter`.
- Menubar mini-player with current-track display and play / pause / previous / next controls.
- Persistent login across app launches (cookies stored in `WKWebsiteDataStore`).
- Custom About panel with clickable GitHub + Ko-fi links.
- Universal binary (Apple Silicon + Intel) — runs on any Mac that meets the macOS 14 requirement.
