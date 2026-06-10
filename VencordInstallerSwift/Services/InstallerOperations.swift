import Foundation

actor InstallerOperations {
    static let shared = InstallerOperations()

    private let githubService = GitHubService()
    private let downloadService = VencordDownloadService()
    private let patchService = PatchService()

    func install(install discordInstall: DiscordInstall, forceDownload: Bool = false) async throws -> DiscordInstall {
        try assertCanModify(discordInstall)
        try prepareVencordDataDirectory()
        let release = try await githubService.fetchLatestRelease()
        let installedHash = githubService.installedHash()

        if forceDownload || release.latestHash != installedHash {
            _ = try await downloadService.installLatestBuilds(from: release)
        }

        return try await patchService.patch(
            install: discordInstall,
            patcherPath: VencordPaths.patcherPath
        )
    }

    func repair(install discordInstall: DiscordInstall) async throws -> DiscordInstall {
        try await install(install: discordInstall, forceDownload: true)
    }

    func uninstall(install discordInstall: DiscordInstall) async throws -> DiscordInstall {
        try assertCanModify(discordInstall)
        return try await patchService.unpatch(install: discordInstall)
    }

    func status() async -> (latestHash: String, installedHash: String) {
        let installed = githubService.installedHash()
        guard let release = try? await githubService.fetchLatestRelease() else {
            return ("Unknown", installed)
        }
        return (release.latestHash, installed)
    }

    private func prepareVencordDataDirectory() throws {
        do {
            try VencordPaths.ensureDistDirectory()
        } catch {
            throw InstallerError.vencordDataUnavailable(error.localizedDescription)
        }
    }

    private func assertCanModify(_ discordInstall: DiscordInstall) throws {
        guard PermissionDiagnostics.canModify(install: discordInstall) else {
            throw InstallerError.permissionDenied(
                path: discordInstall.path.path,
                transientLocation: PermissionDiagnostics.runningFromTransientLocation()
            )
        }
    }
}
