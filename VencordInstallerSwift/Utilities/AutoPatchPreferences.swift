import Foundation

enum AutoPatchPreferences {
    private static let enabledKey = "autoRepatchEnabled"
    private static let relaunchKey = "autoRelaunchDiscord"
    private static let launchAtLoginKey = "launchAtLogin"
    private static let watchedInstallsKey = "watchedInstallIDs"

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var relaunchDiscord: Bool {
        get { UserDefaults.standard.object(forKey: relaunchKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: relaunchKey) }
    }

    static var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: launchAtLoginKey) }
        set { UserDefaults.standard.set(newValue, forKey: launchAtLoginKey) }
    }

    static var watchedInstallIDs: Set<String> {
        get {
            Set(UserDefaults.standard.stringArray(forKey: watchedInstallsKey) ?? [])
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: watchedInstallsKey)
        }
    }

    static func watch(install: DiscordInstall) {
        var ids = watchedInstallIDs
        ids.insert(install.id)
        watchedInstallIDs = ids
    }

    static func unwatch(install: DiscordInstall) {
        var ids = watchedInstallIDs
        ids.remove(install.id)
        watchedInstallIDs = ids
    }
}
