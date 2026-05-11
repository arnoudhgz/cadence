import Foundation
import WebKit
import Observation

@Observable
@MainActor
final class PlaybackController {
    @ObservationIgnored let webView: WKWebView
    @ObservationIgnored private let state: PlaybackState
    @ObservationIgnored private let coordinator: WebViewCoordinator

    init(state: PlaybackState) {
        self.state = state

        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .default()

        let contentController = WKUserContentController()
        config.userContentController = contentController

        let coordinator = WebViewCoordinator(state: state)
        self.coordinator = coordinator
        contentController.add(coordinator, name: "cadence")

        if let url = Bundle.main.url(forResource: "bridge", withExtension: "js"),
           let source = try? String(contentsOf: url, encoding: .utf8) {
            let script = WKUserScript(
                source: source,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true,
            )
            contentController.addUserScript(script)
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = Self.desktopSafariUA
        webView.navigationDelegate = coordinator
        #if DEBUG
        webView.isInspectable = true
        #endif
        self.webView = webView

        if let url = URL(string: "https://music.youtube.com") {
            webView.load(URLRequest(url: url))
        }
    }

    func play() {
        evaluate("window.cadenceBridge && window.cadenceBridge.play()")
    }

    func pause() {
        evaluate("window.cadenceBridge && window.cadenceBridge.pause()")
    }

    func togglePlayPause() {
        evaluate("window.cadenceBridge && window.cadenceBridge.togglePlayPause()")
    }

    func next() {
        evaluate("window.cadenceBridge && window.cadenceBridge.next()")
    }

    func previous() {
        evaluate("window.cadenceBridge && window.cadenceBridge.previous()")
    }

    func seek(to seconds: TimeInterval) {
        evaluate("window.cadenceBridge && window.cadenceBridge.seekTo(\(seconds))")
    }

    private func evaluate(_ js: String) {
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                #if DEBUG
                print("[Cadence] JS eval error: \(error.localizedDescription)")
                #endif
            }
        }
    }

    private static let desktopSafariUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
}
