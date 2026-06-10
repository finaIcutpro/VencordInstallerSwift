import Foundation

enum VencordPaths {
    static let baseDirectory: URL = {
        if let custom = ProcessInfo.processInfo.environment["VENCORD_USER_DATA_DIR"], !custom.isEmpty {
            return URL(fileURLWithPath: custom, isDirectory: true)
        }
        if let discordData = ProcessInfo.processInfo.environment["DISCORD_USER_DATA_DIR"], !discordData.isEmpty {
            return URL(fileURLWithPath: discordData, isDirectory: true)
                .deletingLastPathComponent()
                .appendingPathComponent("VencordData", isDirectory: true)
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Vencord", isDirectory: true)
    }()

    static var distDirectory: URL {
        baseDirectory.appendingPathComponent("dist", isDirectory: true)
    }

    static var patcherPath: URL {
        distDirectory.appendingPathComponent("patcher.js")
    }

    static var packageJSONPath: URL {
        distDirectory.appendingPathComponent("package.json")
    }

    static func ensureDistDirectory() throws {
        try FileManager.default.createDirectory(at: distDirectory, withIntermediateDirectories: true)
    }
}
