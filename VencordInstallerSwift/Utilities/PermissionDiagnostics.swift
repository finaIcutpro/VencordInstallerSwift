import AppKit
import Foundation

enum PermissionDiagnostics {
    /// Returns whether the installer can write inside the Discord bundle (App Management / FDA).
    static func canModify(install: DiscordInstall) -> Bool {
        let probe = install.asarDirectory.appendingPathComponent(".vencord-installer-probe")
        do {
            try Data().write(to: probe, options: .atomic)
            try? FileManager.default.removeItem(at: probe)
            return true
        } catch {
            return false
        }
    }

    static func runningFromTransientLocation() -> Bool {
        Bundle.main.bundlePath.contains("/DerivedData/")
            || Bundle.main.bundlePath.contains("/Xcode/")
            || Bundle.main.bundlePath.contains("/Build/Products/")
    }

    static var appLocationHint: String {
        if runningFromTransientLocation() {
            return """
            You appear to be running a build from Xcode or DerivedData. macOS ties App Management permission to a specific app on disk — rebuilds and Xcode runs use a different path each time, so the toggle will keep resetting.

            Install the release .app to /Applications and run that copy instead.
            """
        }
        return "Enable this app in System Settings, then quit and reopen the installer."
    }
}

enum SystemSettingsOpener {
    static func openAppManagement() {
        open("x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AppBundles")
            ?? open("x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles")
    }

    static func openFullDiskAccess() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
    }

    @discardableResult
    private static func open(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return NSWorkspace.shared.open(url)
    }
}
