import Foundation
import ServiceManagement

@MainActor
final class AutoPatchService {
    static let shared = AutoPatchService()

    private let watcher = DiscordUpdateWatcher()
    private var debounceTask: Task<Void, Never>?
    private var isPatching = false

    var onPatchStarted: (() -> Void)?
    var onPatchFinished: ((Result<String, Error>) -> Void)?

    private init() {
        watcher.onResourcesChanged = { [weak self] resourcesPath in
            Task { @MainActor in
                self?.handleResourcesChanged(resourcesPath)
            }
        }
    }

    func syncFromPreferences() {
        if AutoPatchPreferences.isEnabled {
            startWatching()
        } else {
            stopWatching()
        }
        syncLoginItem(AutoPatchPreferences.launchAtLogin)
    }

    func setEnabled(_ enabled: Bool, for install: DiscordInstall?) {
        AutoPatchPreferences.isEnabled = enabled
        if enabled {
            if let install {
                AutoPatchPreferences.watch(install: install)
            }
            startWatching()
        } else {
            stopWatching()
        }
    }

    func setRelaunchDiscord(_ enabled: Bool) {
        AutoPatchPreferences.relaunchDiscord = enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        AutoPatchPreferences.launchAtLogin = enabled
        syncLoginItem(enabled)
    }

    func registerInstallForWatching(_ install: DiscordInstall) {
        guard AutoPatchPreferences.isEnabled else { return }
        AutoPatchPreferences.watch(install: install)
        startWatching()
    }

    private func selectedInstallID() -> String? {
        AutoPatchPreferences.watchedInstallIDs.first
    }

    private func startWatching() {
        let watched = DiscordDiscovery.findInstalls()
            .filter { AutoPatchPreferences.watchedInstallIDs.contains($0.id) }
        watcher.start(watching: watched)
    }

    private func stopWatching() {
        watcher.stop()
        debounceTask?.cancel()
    }

    private func handleResourcesChanged(_ resourcesPath: String) {
        guard AutoPatchPreferences.isEnabled, !isPatching else { return }

        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await evaluateAndPatch(resourcesPath: resourcesPath)
        }
    }

    private func evaluateAndPatch(resourcesPath: String) async {
        guard let install = DiscordDiscovery.findInstalls().first(where: { $0.resourcesPath.path == resourcesPath }) else {
            return
        }
        guard AutoPatchPreferences.watchedInstallIDs.contains(install.id) else { return }
        guard !install.isPatched else { return }

        await autoPatch(install: install)
    }

    private func autoPatch(install: DiscordInstall) async {
        guard !isPatching else { return }
        isPatching = true
        onPatchStarted?()

        do {
            if DiscordLaunchService.isRunning(install: install) {
                await DiscordLaunchService.quit(install: install)
            }

            _ = try await InstallerOperations.shared.repair(install: install)

            if AutoPatchPreferences.relaunchDiscord {
                DiscordLaunchService.launch(install: install)
            }

            onPatchFinished?(.success("Re-patched \(install.displayName) after a Discord update."))
        } catch {
            onPatchFinished?(.failure(error))
        }

        isPatching = false
    }

    private func syncLoginItem(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // can fail w/o signed build
        }
    }
}
