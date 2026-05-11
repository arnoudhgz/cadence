import Foundation
import Observation

@Observable
@MainActor
final class PlaybackState {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artworkURL: URL?
    var isPlaying: Bool = false
    var elapsed: TimeInterval = 0
    var duration: TimeInterval = 0
}
