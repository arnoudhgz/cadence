import SwiftUI

struct ContentView: View {
    @Environment(PlaybackController.self) private var controller

    var body: some View {
        WebViewContainer(webView: controller.webView)
            .ignoresSafeArea()
    }
}
