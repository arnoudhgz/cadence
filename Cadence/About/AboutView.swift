import SwiftUI
import AppKit

struct AboutView: View {
    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 96, height: 96)

            VStack(spacing: 2) {
                Text("Cadence")
                    .font(.system(size: 22, weight: .semibold))
                Text("Version \(version)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Text("Unofficial YouTube Music player for macOS.\nNot affiliated with Google or YouTube.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Divider()
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("Made by")
                        .foregroundStyle(.secondary)
                    Link("arnoudhgz", destination: URL(string: "https://github.com/arnoudhgz")!)
                }
                .font(.callout)

                Link(destination: URL(string: "https://ko-fi.com/arnoudhgz")!) {
                    Label("Support me on Ko-fi", systemImage: "cup.and.saucer.fill")
                        .font(.callout)
                }
            }

            Text("MIT licensed · © 2026")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 36)
        .frame(width: 360)
    }
}
