import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(PlaybackController.self) private var controller
    @State private var occlusionObserver: WindowOcclusionObserver?

    var body: some View {
        WebViewContainer(webView: controller.webView)
            .ignoresSafeArea()
            .background(WindowAccessor { window in
                attachOcclusionObserver(to: window)
            })
    }

    private func attachOcclusionObserver(to window: NSWindow) {
        guard occlusionObserver == nil else { return }
        occlusionObserver = WindowOcclusionObserver(window: window) { [controller] visible in
            controller.setActive(visible)
        }
    }
}

/// Briefly bridges SwiftUI to the underlying NSWindow so we can attach
/// observers that need a concrete NSWindow reference (occlusion state, etc).
private struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindow(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onWindow(window)
            }
        }
    }
}
