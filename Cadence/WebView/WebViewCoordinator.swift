import Foundation
import WebKit

final class WebViewCoordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    private let state: PlaybackState

    init(state: PlaybackState) {
        self.state = state
        super.init()
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage,
    ) {
        guard message.name == "cadence",
              let body = message.body as? [String: Any] else {
            return
        }

        let type = body["type"] as? String ?? ""

        Task { @MainActor [state] in
            switch type {
            case "state":
                if let value = body["isPlaying"] as? Bool {
                    state.isPlaying = value
                }
                if let value = body["elapsed"] as? Double {
                    state.elapsed = value
                }
                if let value = body["duration"] as? Double {
                    state.duration = value
                }
                if let value = body["title"] as? String {
                    state.title = value
                }
                if let value = body["artist"] as? String {
                    state.artist = value
                }
                if let value = body["album"] as? String {
                    state.album = value
                }
                if let value = body["artwork"] as? String, !value.isEmpty {
                    state.artworkURL = URL(string: value)
                }
            case "ready":
                #if DEBUG
                print("[Cadence] bridge ready")
                #endif
            default:
                break
            }
        }
    }
}
