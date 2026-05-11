import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(PlaybackState.self) private var state
    @Environment(PlaybackController.self) private var controller

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ArtworkView(url: state.artworkURL)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text(state.title.isEmpty ? "Not playing" : state.title)
                        .font(.headline)
                        .lineLimit(1)
                    if !state.artist.isEmpty {
                        Text(state.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            HStack(spacing: 28) {
                Button {
                    controller.previous()
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                }

                Button {
                    controller.togglePlayPause()
                } label: {
                    Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }

                Button {
                    controller.next()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            Divider()

            HStack {
                Button("Show Cadence") {
                    showMainWindow()
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 300)
    }

    private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
            return
        }
    }
}

private struct ArtworkView: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty, .failure:
                placeholder
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            @unknown default:
                placeholder
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.gray.opacity(0.15)
            Image(systemName: "music.note")
                .foregroundStyle(.secondary)
        }
    }
}
