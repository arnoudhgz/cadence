import Foundation
import MediaPlayer

@MainActor
final class RemoteCommandController {
    private let controller: PlaybackController

    init(controller: PlaybackController) {
        self.controller = controller
    }

    func start() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.controller.play()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.controller.pause()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.controller.togglePlayPause()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.controller.next()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.controller.previous()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.controller.seek(to: event.positionTime)
            return .success
        }

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true
        center.changePlaybackPositionCommand.isEnabled = true
    }
}
