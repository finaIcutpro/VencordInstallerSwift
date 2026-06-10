import Foundation

enum VencordPaths {
    static var baseDirectoryProvider: @Sendable () -> URL = {
        resolveBaseDirectory(using: ProcessInfo.processInfo.environment)
    }

    static var baseDirectory: URL {
        baseDirectoryProvider()
    }

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

    static func resolveBaseDirectory(using environment: [String: String]) -> URL {
        if let custom = environment["VENCORD_USER_DATA_DIR"], !custom.isEmpty {
            return URL(fileURLWithPath: custom, isDirectory: true)
        }
        if let discordData = environment["DISCORD_USER_DATA_DIR"], !discordData.isEmpty {
            return URL(fileURLWithPath: discordData, isDirectory: true)
                .deletingLastPathComponent()
                .appendingPathComponent("VencordData", isDirectory: true)
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Vencord", isDirectory: true)
    }
}
