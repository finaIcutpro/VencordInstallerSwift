import Foundation

actor InstallerOperations {
    static let shared = InstallerOperations()

    private let githubService = GitHubService()
    private let downloadService = VencordDownloadService()
    private let patchService = PatchService()

    func install(install: DiscordInstall, forceDownload: Bool = false) async throws -> DiscordInstall {
        try prepareVencordDataDirectory()
        let release = try await githubService.fetchLatestRelease()
        let installedHash = githubService.installedHash()

        if forceDownload || release.latestHash != installedHash {
            _ = try await downloadService.installLatestBuilds(from: release)
        }

        return try await patchService.patch(
            install: install,
            patcherPath: VencordPaths.patcherPath
        )
    }

    func repair(install: DiscordInstall) async throws -> DiscordInstall {
        try await install(install: install, forceDownload: true)
    }

    func uninstall(install: DiscordInstall) async throws -> DiscordInstall {
        try await patchService.unpatch(install: install)
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
}
