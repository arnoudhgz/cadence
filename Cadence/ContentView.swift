import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(PlaybackController.self) private var controller
    @Environment(PlaybackState.self) private var state
    @State private var occlusionObserver: WindowOcclusionObserver?

    var body: some View {
        WebViewContainer(webView: controller.webView)
            .ignoresSafeArea(.container, edges: [.leading, .trailing, .bottom])
            .navigationTitle(windowTitle)
            .toolbarBackground(Self.titleBarColor, for: .windowToolbar)
            .toolbarBackground(.visible, for: .windowToolbar)
            .toolbarColorScheme(.dark, for: .windowToolbar)
            .background(WindowAccessor { window in
                attachOcclusionObserver(to: window)
            })
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button {
                        controller.goBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .disabled(!controller.canGoBack)
                    .keyboardShortcut("[", modifiers: .command)
                    .help("Back")

                    Button {
                        controller.goForward()
                    } label: {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(!controller.canGoForward)
                    .keyboardShortcut("]", modifiers: .command)
                    .help("Forward")
                }
            }
    }

    private func attachOcclusionObserver(to window: NSWindow) {
        guard occlusionObserver == nil else { return }
        occlusionObserver = WindowOcclusionObserver(window: window) { [controller] visible in
            controller.setActive(visible)
        }
    }

    private var windowTitle: String {
        if state.title.isEmpty {
            return "Cadence"
        }
        if state.artist.isEmpty {
            return state.title
        }
        return "\(state.title) — \(state.artist)"
    }

    /// Deep synthwave purple sampled from the Cadence brand icon — sits between
    /// pure black and the YT Music near-black so the title bar reads as chrome
    /// rather than as part of the content.
    private static let titleBarColor = Color(red: 0.18, green: 0.11, blue: 0.26)
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
