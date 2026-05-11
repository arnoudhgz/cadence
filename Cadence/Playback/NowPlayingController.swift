import Foundation
import MediaPlayer
import AppKit

@MainActor
final class NowPlayingController {
    private let state: PlaybackState
    private var artworkCache: [URL: NSImage] = [:]
    private var lastArtworkURL: URL?

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

    private func applyToNowPlayingCenter() {
        let center = MPNowPlayingInfoCenter.default()
        var info = center.nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = state.title
        info[MPMediaItemPropertyArtist] = state.artist
        info[MPMediaItemPropertyAlbumTitle] = state.album
        info[MPMediaItemPropertyPlaybackDuration] = state.duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = state.elapsed
        info[MPNowPlayingInfoPropertyPlaybackRate] = state.isPlaying ? 1.0 : 0.0
        center.nowPlayingInfo = info
        center.playbackState = state.isPlaying ? .playing : .paused

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
        if let cached = artworkCache[url] {
            completion(cached)
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            Task { @MainActor in
                self?.artworkCache[url] = image
                completion(image)
            }
        }.resume()
    }
}
