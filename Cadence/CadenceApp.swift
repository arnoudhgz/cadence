import SwiftUI

@main
struct CadenceApp: App {
    @State private var state: PlaybackState
    @State private var controller: PlaybackController
    @State private var nowPlaying: NowPlayingController
    @State private var remoteCommands: RemoteCommandController

    init() {
        let state = PlaybackState()
        let controller = PlaybackController(state: state)
        let nowPlaying = NowPlayingController(state: state)
        let remoteCommands = RemoteCommandController(controller: controller)

        nowPlaying.start()
        remoteCommands.start()

        _state = State(initialValue: state)
        _controller = State(initialValue: controller)
        _nowPlaying = State(initialValue: nowPlaying)
        _remoteCommands = State(initialValue: remoteCommands)
    }

    var body: some Scene {
        WindowGroup("Cadence") {
            ContentView()
                .environment(state)
                .environment(controller)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowResizability(.contentMinSize)
        .commands {
            AboutCommand()
            CommandGroup(replacing: .newItem) {}
        }

        Window("About Cadence", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        MenuBarExtra {
            MenuBarView()
                .environment(state)
                .environment(controller)
        } label: {
            Image(systemName: state.isPlaying ? "play.circle.fill" : "music.note")
        }
        .menuBarExtraStyle(.window)
    }
}

private struct AboutCommand: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About Cadence") {
                openWindow(id: "about")
            }
        }
    }
}
