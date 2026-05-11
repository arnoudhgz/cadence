# Changelog

All notable changes to Cadence are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
