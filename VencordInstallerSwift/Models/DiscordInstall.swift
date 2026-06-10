import Foundation

struct DiscordInstall: Identifiable, Hashable, Sendable {
    let id: String
    let path: URL
    let branch: String
    let appPath: URL
    var isPatched: Bool

    var resourcesPath: URL {
        path.appendingPathComponent("Contents/Resources", isDirectory: true)
    }

    var asarDirectory: URL {
        resourcesPath
    }

    var displayName: String {
        let branchLabel = branch.prefix(1).uppercased() + branch.dropFirst()
        let patchedLabel = isPatched ? " [PATCHED]" : ""
        return "\(branchLabel) - \(path.path)\(patchedLabel)"
    }

    static func parse(at appURL: URL, branch: String? = nil) -> DiscordInstall? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: appURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }

        let resources = appURL.appendingPathComponent("Contents/Resources", isDirectory: true)
        guard FileManager.default.fileExists(atPath: resources.path) else {
            return nil
        }

        let resolvedBranch = branch ?? Self.branch(from: appURL)
        let appPath = resources.appendingPathComponent("app", isDirectory: true)
        let isPatched = FileManager.default.fileExists(
            atPath: resources.appendingPathComponent("_app.asar").path
        )

        return DiscordInstall(
            id: appURL.path,
            path: appURL,
            branch: resolvedBranch,
            appPath: appPath,
            isPatched: isPatched
        )
    }

    private static func branch(from appURL: URL) -> String {
        let name = appURL.deletingPathExtension().lastPathComponent.lowercased()
        for candidate in ["canary", "development", "dev", "ptb"] {
            if name.contains(candidate) {
                return candidate == "dev" ? "development" : candidate
            }
        }
        return "stable"
    }
}
