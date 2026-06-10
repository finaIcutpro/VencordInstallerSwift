import AppKit
import Foundation

enum DiscordLaunchService {
    static func isRunning(install: DiscordInstall) -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            app.bundleURL?.path == install.path.path
        }
    }

    static func quit(install: DiscordInstall) async {
        let apps = NSWorkspace.shared.runningApplications.filter { $0.bundleURL?.path == install.path.path }
        guard !apps.isEmpty else { return }

        for app in apps {
            app.terminate()
        }

        for _ in 0 ..< 50 {
            if !isRunning(install: install) { return }
            try? await Task.sleep(for: .milliseconds(200))
        }

        for app in apps where !app.isTerminated {
            app.forceTerminate()
        }

        try? await Task.sleep(for: .milliseconds(500))
    }

    static func launch(install: DiscordInstall) {
        NSWorkspace.shared.open(install.path)
    }
}
