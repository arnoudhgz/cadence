import AppKit

/// Watches a single NSWindow's occlusion state and pushes a Bool
/// (true = visible, false = occluded) to the supplied callback whenever
/// it changes. Fires once on init so the consumer gets the current state.
@MainActor
final class WindowOcclusionObserver {
    private weak var window: NSWindow?
    private let onChange: (Bool) -> Void
    private var token: NSObjectProtocol?
    private var lastReported: Bool?

    init(window: NSWindow, onChange: @escaping (Bool) -> Void) {
        self.window = window
        self.onChange = onChange
        token = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: window,
            queue: .main,
        ) { [weak self] _ in
            Task { @MainActor in
                self?.emit()
            }
        }
        emit()
    }

    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }

    private func emit() {
        guard let window else { return }
        let visible = window.occlusionState.contains(.visible)
        if lastReported == visible { return }
        lastReported = visible
        onChange(visible)
    }
}
