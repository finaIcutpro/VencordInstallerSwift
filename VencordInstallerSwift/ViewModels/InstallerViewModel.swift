import Foundation
import Observation

enum AlertInfo: Identifiable {
    case success(String, String)
    case error(String, String)
    case permissionRequired(String)
    case openAsarConfirm

    var id: String {
        switch self {
        case .success(let title, let message): "success-\(title)-\(message)"
        case .error(let title, let message): "error-\(title)-\(message)"
        case .permissionRequired(let message): "permission-\(message)"
        case .openAsarConfirm: "openasar-confirm"
        }
    }

    var title: String {
        switch self {
        case .success(let title, _), .error(let title, _): title
        case .permissionRequired: "Permission Required"
        case .openAsarConfirm: "OpenAsar"
        }
    }

    var message: String {
        switch self {
        case .success(_, let message), .error(_, let message): message
        case .permissionRequired(let message): message
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
    var autoRepatchEnabled = AutoPatchPreferences.isEnabled
    var autoRelaunchDiscord = AutoPatchPreferences.relaunchDiscord
    var launchAtLogin = AutoPatchPreferences.launchAtLogin
    var isAutoPatching = false

    private let githubService = GitHubService()
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
        configureAutoPatchCallbacks()
        AutoPatchService.shared.syncFromPreferences()
        autoRepatchEnabled = AutoPatchPreferences.isEnabled
        autoRelaunchDiscord = AutoPatchPreferences.relaunchDiscord
        launchAtLogin = AutoPatchPreferences.launchAtLogin

        Task {
            await fetchReleaseData()
        }
    }

    func setAutoRepatchEnabled(_ enabled: Bool) {
        autoRepatchEnabled = enabled
        AutoPatchService.shared.setEnabled(enabled, for: selectedInstall)
    }

    func setAutoRelaunchDiscord(_ enabled: Bool) {
        autoRelaunchDiscord = enabled
        AutoPatchService.shared.setRelaunchDiscord(enabled)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        AutoPatchService.shared.setLaunchAtLogin(enabled)
    }

    func updateAutoPatchWatchTarget() {
        guard autoRepatchEnabled, let install = selectedInstall else { return }
        AutoPatchPreferences.watch(install: install)
        AutoPatchService.shared.syncFromPreferences()
    }

    private func configureAutoPatchCallbacks() {
        let service = AutoPatchService.shared
        service.onPatchStarted = { [weak self] in
            self?.isAutoPatching = true
            self?.workingTitle = "Re-patching Discord"
            self?.workingDetail = "Discord updated — restoring Vencord…"
        }
        service.onPatchFinished = { [weak self] result in
            guard let self else { return }
            self.isAutoPatching = false
            self.refreshDiscords()
            Task { await self.fetchReleaseData() }
            switch result {
            case .success(let message):
                self.activeAlert = .success("Auto-patched", message)
            case .failure(let error):
                if let installerError = error as? InstallerError,
                   case .permissionDenied = installerError {
                    self.activeAlert = .permissionRequired(error.localizedDescription)
                } else {
                    self.activeAlert = .error("Auto-patch Failed", error.localizedDescription)
                }
            }
        }
    }

    func refreshDiscords() {
        discords = DiscordDiscovery.findInstalls()
        if selectedInstallID == nil {
            selectedInstallID = discords.first?.id
        }
        if autoRepatchEnabled, let install = selectedInstall {
            AutoPatchPreferences.watch(install: install)
            AutoPatchService.shared.syncFromPreferences()
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
            guard let install = self.selectedInstall else { throw InstallerError.discordNotFound }
            let updated = try await InstallerOperations.shared.install(install: install)
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
            guard let install = self.selectedInstall else { throw InstallerError.discordNotFound }
            let updated = try await InstallerOperations.shared.repair(install: install)
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
            let updated = try await InstallerOperations.shared.uninstall(install: install)
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
        guard let install = selectedInstall else {
            activeAlert = .error("OpenAsar", InstallerError.discordNotFound.localizedDescription)
            return
        }
        guard PermissionDiagnostics.canModify(install: install) else {
            activeAlert = .permissionRequired(
                InstallerError.permissionDenied(
                    path: install.path.path,
                    transientLocation: PermissionDiagnostics.runningFromTransientLocation()
                ).localizedDescription ?? "Permission required."
            )
            return
        }

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
                await fetchReleaseData()
                if let install = self.selectedInstall, self.autoRepatchEnabled {
                    AutoPatchService.shared.registerInstallForWatching(install)
                }
                activeAlert = .success(title, "Successfully completed for the selected Discord install.")
            } catch let error as InstallerError {
                switch error {
                case .permissionDenied(_, _):
                    activeAlert = .permissionRequired(error.localizedDescription ?? "Permission required.")
                default:
                    activeAlert = .error("Operation Failed", error.localizedDescription)
                }
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
