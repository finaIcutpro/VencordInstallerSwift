import Foundation
@testable import VencordInstallerSwift

enum DiscordAppFixture {
    enum Variant: String {
        case stable = "Discord.app"
        case ptb = "Discord PTB.app"
        case canary = "Discord Canary.app"
        case development = "Discord Development.app"
    }

    struct Context {
        let root: URL
        let appURL: URL
        let resourcesURL: URL
    }

    static func create(
        in root: URL,
        variant: Variant = .stable,
        includeAppAsar: Bool = true,
        includeBackupAsar: Bool = false,
        appAsarContents: Data = Data("original-discord-asar".utf8)
    ) throws -> Context {
        let appURL = root.appendingPathComponent(variant.rawValue, isDirectory: true)
        let resourcesURL = appURL
            .appendingPathComponent("Contents/Resources", isDirectory: true)

        try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

        if includeAppAsar {
            try appAsarContents.write(to: resourcesURL.appendingPathComponent("app.asar"))
        }
        if includeBackupAsar {
            try appAsarContents.write(to: resourcesURL.appendingPathComponent("_app.asar"))
        }

        return Context(root: root, appURL: appURL, resourcesURL: resourcesURL)
    }

    static func install(_ context: Context) throws -> DiscordInstall {
        guard let install = DiscordInstall.parse(at: context.appURL) else {
            throw FixtureError.invalidInstall
        }
        return install
    }
}

enum FixtureError: Error {
    case invalidInstall
}
