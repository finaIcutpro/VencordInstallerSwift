import Foundation

actor PatchService {
    func patch(install: DiscordInstall, patcherPath: URL) throws -> DiscordInstall {
        var current = install
        if current.isPatched {
            current = try unpatch(install: current)
        }
        try patchAppAsar(in: current.asarDirectory, patcherPath: patcherPath.path)
        var updated = current
        updated.isPatched = true
        return updated
    }

    func unpatch(install: DiscordInstall) throws -> DiscordInstall {
        try unpatchAppAsar(in: install.asarDirectory)
        var updated = install
        updated.isPatched = false
        return updated
    }

    private func patchAppAsar(in directory: URL, patcherPath: String) throws {
        let appAsar = directory.appendingPathComponent("app.asar")
        let backupAsar = directory.appendingPathComponent("_app.asar")
        let discordPath = directory.deletingLastPathComponent().deletingLastPathComponent().path

        var renamesDone: [(from: URL, to: URL)] = []
        var patchError: Error?

        do {
            try moveItem(from: appAsar, to: backupAsar)
            renamesDone.append((from: appAsar, to: backupAsar))
            try AppAsarWriter.write(to: appAsar, patcherPath: patcherPath)
        } catch {
            patchError = error
        }

        if let patchError {
            rollbackRenames(renamesDone)
            throw InstallerError.fromFileError(patchError, path: discordPath)
        }
    }

    private func unpatchAppAsar(in directory: URL) throws {
        let appAsar = directory.appendingPathComponent("app.asar")
        let tempAsar = directory.appendingPathComponent("app.asar.tmp")
        let backupAsar = directory.appendingPathComponent("_app.asar")

        var renamesDone: [(from: URL, to: URL)] = []
        var succeeded = false
        defer {
            if !succeeded {
                rollbackRenames(renamesDone)
            } else {
                try? FileManager.default.removeItem(at: tempAsar)
            }
        }

        do {
            try moveItem(from: appAsar, to: tempAsar)
            renamesDone.append((from: appAsar, to: tempAsar))

            try moveItem(from: backupAsar, to: appAsar)
            renamesDone.append((from: backupAsar, to: appAsar))

            succeeded = true
        } catch {
            throw InstallerError.fromFileError(error, path: directory.deletingLastPathComponent().path)
        }
    }

    private func moveItem(from source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: source, to: destination)
    }

    private func rollbackRenames(_ renames: [(from: URL, to: URL)]) {
        for rename in renames.reversed() {
            do {
                try moveItem(from: rename.to, to: rename.from)
            } catch {
                // best effort rollback here, original error is more important
            }
        }
    }
}
