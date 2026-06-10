import Foundation
import Observation

enum AlertInfo: Identifiable {
    case success(String, String)
    case error(String, String)
    case openAsarConfirm

    var id: String {
        switch self {
        case .success(let title, let message): "success-\(title)-\(message)"
        case .error(let title, let message): "error-\(title)-\(message)"
        case .openAsarConfirm: "openasar-confirm"
        }
    }

    var title: String {
        switch self {
        case .success(let title, _), .error(let title, _): title
        case .openAsarConfirm: "OpenAsar"
        }
    }

    var message: String {
        switch self {
        case .success(_, let message), .error(_, let message): message
        case .openAsarConfirm:
            """
            OpenAsar is an open-source alternative of Discord desktop's app.asar.

            Installing it will replace your current app.asar with OpenAsar. \
            A backup will be saved as app.asar.backup.

            Do you want to continue?
            """
        }
    }
}

@MainActor
@Observable
final class InstallerViewModel {
    var discords: [DiscordInstall] = []
    var selectedInstallID: String?
    var customPath: URL?
    var isWorking = false
    var workingTitle = ""
    var workingDetail = ""
    var latestHash = "Unknown"
    var installedHash = "None"
    var activeAlert: AlertInfo?
    var isOpenAsarInstalled = false
    var vencordDataError: String?

    private let githubService = GitHubService()
    private let downloadService = VencordDownloadService()
    private let patchService = PatchService()
    private let openAsarService = OpenAsarService()
    private var latestRelease: GitHubRelease?

    var selectedInstall: DiscordInstall? {
        if let customPath, let install = DiscordInstall.parse(at: customPath) {
            return install
        }
        guard let selectedInstallID else { return discords.first }
        return discords.first { $0.id == selectedInstallID } ?? discords.first
    }

    func load() {
        refreshDiscords()
        installedHash = githubService.installedHash()

        Task {
            await fetchReleaseData()
        }
    }

    func refreshDiscords() {
        discords = DiscordDiscovery.findInstalls()
        if selectedInstallID == nil {
            selectedInstallID = discords.first?.id
        }
        updateOpenAsarState()
    }

    func selectCustomLocation(_ url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        customPath = url
        selectedInstallID = nil
        updateOpenAsarState()
    }

    func install() {
        performAction(
            title: "Installed",
            workingTitle: "Installing Vencord",
            workingDetail: "Preparing…"
        ) {
            self.setWorkingDetail("Downloading latest builds…")
            try await self.ensureLatestBuilds()
            self.setWorkingDetail("Patching Discord…")
            guard let install = self.selectedInstall else { throw InstallerError.discordNotFound }
            let updated = try await self.patchService.patch(
                install: install,
                patcherPath: VencordPaths.patcherPath
            )
            self.applyInstallUpdate(updated)
        }
    }

    func repair() {
        performAction(
            title: "Repaired",
            workingTitle: "Repairing Vencord",
            workingDetail: "Preparing…"
        ) {
            self.setWorkingDetail("Downloading latest builds…")
            try await self.ensureLatestBuilds(force: true)
            self.setWorkingDetail("Patching Discord…")
            guard let install = self.selectedInstall else { throw InstallerError.discordNotFound }
            let updated = try await self.patchService.patch(
                install: install,
                patcherPath: VencordPaths.patcherPath
            )
            self.applyInstallUpdate(updated)
        }
    }

    func uninstall() {
        performAction(
            title: "Uninstalled",
            workingTitle: "Uninstalling Vencord",
            workingDetail: "Restoring Discord…"
        ) {
            guard let install = self.selectedInstall else { throw InstallerError.discordNotFound }
            let updated = try await self.patchService.unpatch(install: install)
            self.applyInstallUpdate(updated)
        }
    }

    func toggleOpenAsar() {
        guard let install = selectedInstall else {
            activeAlert = .error("OpenAsar", InstallerError.discordNotFound.localizedDescription)
            return
        }

        if isOpenAsarInstalled {
            performAction(
                title: "OpenAsar Removed",
                workingTitle: "Removing OpenAsar",
                workingDetail: "Restoring original app.asar…"
            ) {
                try await self.openAsarService.uninstall(install: install)
                self.isOpenAsarInstalled = false
            }
        } else {
            activeAlert = .openAsarConfirm
        }
    }

    func confirmOpenAsarInstall() {
        performAction(
            title: "OpenAsar Installed",
            workingTitle: "Installing OpenAsar",
            workingDetail: "Downloading OpenAsar…"
        ) {
            guard let install = self.selectedInstall else { throw InstallerError.discordNotFound }
            try await self.openAsarService.install(install: install)
            self.isOpenAsarInstalled = true
        }
    }

    private func setWorkingDetail(_ detail: String) {
        workingDetail = detail
    }

    private func performAction(
        title: String,
        workingTitle: String,
        workingDetail: String,
        operation: @escaping () async throws -> Void
    ) {
        guard !isWorking else { return }
        isWorking = true
        self.workingTitle = workingTitle
        self.workingDetail = workingDetail

        Task {
            do {
                try await operation()
                activeAlert = .success(title, "Successfully completed for the selected Discord install.")
            } catch {
                activeAlert = .error("Operation Failed", error.localizedDescription)
            }
            isWorking = false
            refreshDiscords()
        }
    }

    private func fetchReleaseData() async {
        do {
            let release = try await githubService.fetchLatestRelease()
            latestRelease = release
            latestHash = release.latestHash
            installedHash = githubService.installedHash()
        } catch {
            // no need 2 catch here
        }
    }

    private func ensureLatestBuilds(force: Bool = false) async throws {
        if vencordDataError != nil {
            throw InstallerError.vencordDataUnavailable(vencordDataError ?? "")
        }

        do {
            try VencordPaths.ensureDistDirectory()
        } catch {
            vencordDataError = error.localizedDescription
            throw InstallerError.vencordDataUnavailable(error.localizedDescription)
        }

        if latestRelease == nil {
            latestRelease = try await githubService.fetchLatestRelease()
            latestHash = latestRelease?.latestHash ?? latestHash
        }

        guard let release = latestRelease else {
            throw InstallerError.githubFetchFailed("No release data available")
        }

        installedHash = githubService.installedHash()
        if force || latestHash != installedHash {
            setWorkingDetail("Downloading latest builds…")
            installedHash = try await downloadService.installLatestBuilds(from: release)
            latestHash = release.latestHash
        }
    }

    private func applyInstallUpdate(_ install: DiscordInstall) {
        if let index = discords.firstIndex(where: { $0.id == install.id }) {
            discords[index] = install
        }
        selectedInstallID = install.id
        customPath = nil
        updateOpenAsarState()
    }

    private func updateOpenAsarState() {
        guard let install = selectedInstall else {
            isOpenAsarInstalled = false
            return
        }
        Task {
            isOpenAsarInstalled = await openAsarService.isOpenAsar(install: install)
        }
    }
}
