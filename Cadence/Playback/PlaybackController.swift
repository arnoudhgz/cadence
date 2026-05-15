import Foundation
import WebKit
import Observation

@Observable
@MainActor
final class PlaybackController {
    @ObservationIgnored let webView: WKWebView
    @ObservationIgnored private let state: PlaybackState
    @ObservationIgnored private let coordinator: WebViewCoordinator
    @ObservationIgnored private var backObserver: NSKeyValueObservation?
    @ObservationIgnored private var forwardObserver: NSKeyValueObservation?

    var canGoBack: Bool = false
    var canGoForward: Bool = false

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

        // CSS skin layers — injected at documentStart so they apply before YT
        // Music first paints. Sub-frames included so any iframes (e.g. account
        // chooser) get the same treatment.
        for resource in ["scrollbars", "playerbar"] {
            if let script = Self.cssUserScript(named: resource) {
                contentController.addUserScript(script)
            }
        }

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
        webView.allowsBackForwardNavigationGestures = true
        #if DEBUG
        webView.isInspectable = true
        #endif
        self.webView = webView

        backObserver = webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.canGoBack = webView.canGoBack
            }
        }
        forwardObserver = webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] webView, _ in
            Task { @MainActor in
                self?.canGoForward = webView.canGoForward
            }
        }

        if let url = URL(string: "https://music.youtube.com") {
            webView.load(URLRequest(url: url))
        }
    }

    func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    func goForward() {
        if webView.canGoForward {
            webView.goForward()
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

    /// Toggles whether the JS bridge emits periodic state. Set false when the
    /// host window is occluded — bridge keeps responding to media commands but
    /// stops the timeupdate / metadata-poll telemetry. Sets window.__cadenceActive
    /// directly so the value sticks even if the bridge hasn't finished loading.
    func setActive(_ active: Bool) {
        let value = active ? "true" : "false"
        evaluate("window.__cadenceActive = \(value); window.cadenceBridge && window.cadenceBridge.setActive(\(value));")
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

    /// Loads a bundled .css resource and wraps it in a WKUserScript that
    /// appends a <style> element to the document head at documentStart.
    private static func cssUserScript(named name: String) -> WKUserScript? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "css"),
              let css = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        let escaped = css
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        let source = """
        (function () {
            var s = document.createElement('style');
            s.setAttribute('data-cadence', '\(name)');
            s.textContent = `\(escaped)`;
            (document.head || document.documentElement).appendChild(s);
        })();
        """
        return WKUserScript(
            source: source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false,
        )
    }

    private static let desktopSafariUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15"
}
