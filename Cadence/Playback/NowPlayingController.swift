import Foundation
import MediaPlayer
import AppKit

@MainActor
final class NowPlayingController {
    private let state: PlaybackState
    private let artworkCache: NSCache<NSURL, NSImage> = {
        let cache = NSCache<NSURL, NSImage>()
        cache.countLimit = 16
        return cache
    }()
    private var lastArtworkURL: URL?
    private var lastApplied: Snapshot?

    init(state: PlaybackState) {
        self.state = state
    }

    func start() {
        observe()
    }

    private func observe() {
        withObservationTracking { [state] in
            // Touch every property we care about so the tracker registers them.
            _ = state.title
            _ = state.artist
            _ = state.album
            _ = state.artworkURL
            _ = state.isPlaying
            _ = state.elapsed
            _ = state.duration
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.applyToNowPlayingCenter()
                self.observe()
            }
        }
        applyToNowPlayingCenter()
    }

    private struct Snapshot {
        var title: String
        var artist: String
        var album: String
        var duration: TimeInterval
        var isPlaying: Bool
        var elapsed: TimeInterval
        var appliedAt: TimeInterval
    }

    private func applyToNowPlayingCenter() {
        let now = ProcessInfo.processInfo.systemUptime
        let current = Snapshot(
            title: state.title,
            artist: state.artist,
            album: state.album,
            duration: state.duration,
            isPlaying: state.isPlaying,
            elapsed: state.elapsed,
            appliedAt: now,
        )
        let prev = lastApplied
        defer { lastApplied = current }

        let titleChanged = prev?.title != current.title
        let artistChanged = prev?.artist != current.artist
        let albumChanged = prev?.album != current.album
        let durationChanged = prev?.duration != current.duration
        let rateChanged = prev?.isPlaying != current.isPlaying
        let metadataChanged = titleChanged || artistChanged || albumChanged || durationChanged

        // Steady-state ticks rely on PlaybackRate-based extrapolation in
        // Control Center — pushing elapsed every second is wasted IPC. Push it
        // only when something interesting happened: play/pause flip, track
        // change, or a detected seek (elapsed jumps away from extrapolation).
        let elapsedDriftAbs: TimeInterval = {
            guard let prev = prev else { return 0 }
            let extrapolated = prev.isPlaying
                ? prev.elapsed + (now - prev.appliedAt)
                : prev.elapsed
            return abs(current.elapsed - extrapolated)
        }()
        let seekDetected = prev != nil && elapsedDriftAbs > 1.5
        let elapsedPushNeeded = rateChanged || metadataChanged || seekDetected

        let center = MPNowPlayingInfoCenter.default()
        var info = center.nowPlayingInfo ?? [:]
        var changed = false

        if titleChanged {
            info[MPMediaItemPropertyTitle] = current.title
            changed = true
        }
        if artistChanged {
            info[MPMediaItemPropertyArtist] = current.artist
            changed = true
        }
        if albumChanged {
            info[MPMediaItemPropertyAlbumTitle] = current.album
            changed = true
        }
        if durationChanged {
            info[MPMediaItemPropertyPlaybackDuration] = current.duration
            changed = true
        }
        if rateChanged {
            info[MPNowPlayingInfoPropertyPlaybackRate] = current.isPlaying ? 1.0 : 0.0
            changed = true
        }
        if elapsedPushNeeded {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = current.elapsed
            changed = true
        }

        if changed {
            center.nowPlayingInfo = info
        }
        if rateChanged {
            center.playbackState = current.isPlaying ? .playing : .paused
        }

        if let url = state.artworkURL, url != lastArtworkURL {
            lastArtworkURL = url
            loadArtwork(url: url) { [weak self] image in
                guard let self else { return }
                guard self.state.artworkURL == url else { return }
                var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                info[MPMediaItemPropertyArtwork] = artwork
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
        }
    }

    private func loadArtwork(url: URL, completion: @escaping @MainActor (NSImage) -> Void) {
        if let cached = artworkCache.object(forKey: url as NSURL) {
            completion(cached)
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            Task { @MainActor in
                self?.artworkCache.setObject(image, forKey: url as NSURL)
                completion(image)
            }
        }.resume()
    }
}
