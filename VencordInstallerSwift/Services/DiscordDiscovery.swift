import Foundation

enum DiscordDiscovery {
    private static let macOSNames: [(branch: String, dirname: String)] = [
        ("stable", "Discord.app"),
        ("ptb", "Discord PTB.app"),
        ("canary", "Discord Canary.app"),
        ("development", "Discord Development.app"),
    ]

    static func findInstalls() -> [DiscordInstall] {
        let bases = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true),
        ]

        var installs: [DiscordInstall] = []
        for (branch, dirname) in macOSNames {
            for base in bases {
                let appURL = base.appendingPathComponent(dirname, isDirectory: true)
                if let install = DiscordInstall.parse(at: appURL, branch: branch) {
                    installs.append(install)
                }
            }
        }
        return installs
    }
}
