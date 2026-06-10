import Foundation

actor OpenAsarService {
    private static let downloadURL = URL(
        string: "https://github.com/GooseMod/OpenAsar/releases/download/nightly/app.asar"
    )!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func isOpenAsar(install: DiscordInstall) -> Bool {
        let directory = install.asarDirectory
        for filename in ["_app.asar", "app.asar"] {
            let fileURL = directory.appendingPathComponent(filename)
            guard let data = try? readPrefix(of: fileURL, maxBytes: 256 * 1024) else { continue }
            if data.contains(Data("OpenAsar".utf8)) {
                return true
            }
        }
        return false
    }

    func install(install: DiscordInstall) async throws {
        let directory = install.asarDirectory
        let asarFile = try findAsarFile(in: directory)
        let backupURL = directory.appendingPathComponent("app.asar.backup")

        try moveItem(from: asarFile, to: backupURL)

        do {
            let (tempURL, response) = try await session.download(from: Self.downloadURL)
            defer { try? FileManager.default.removeItem(at: tempURL) }

            guard let http = response as? HTTPURLResponse, http.statusCode < 300 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw InstallerError.openAsarFailed("Failed to fetch OpenAsar - \(code)")
            }

            let data = try Data(contentsOf: tempURL)
            try data.write(to: asarFile, options: .atomic)
        } catch {
            try? moveItem(from: backupURL, to: asarFile)
            throw error
        }
    }

    func uninstall(install: DiscordInstall) throws {
        let directory = install.asarDirectory
        for backupName in ["app.asar.backup", "app.asar.original"] {
            let backupURL = directory.appendingPathComponent(backupName)
            guard FileManager.default.fileExists(atPath: backupURL.path) else { continue }

            let asarFile = try findAsarFile(in: directory)
            try moveItem(from: backupURL, to: asarFile)
            return
        }
        throw InstallerError.noOpenAsarBackup
    }

    private func findAsarFile(in directory: URL) throws -> URL {
        for filename in ["_app.asar", "app.asar"] {
            let fileURL = directory.appendingPathComponent(filename)
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
               !isDirectory.boolValue {
                return fileURL
            }
        }
        throw InstallerError.openAsarFailed("Install at \(directory.path) has no asar file")
    }

    private func readPrefix(of url: URL, maxBytes: Int) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return handle.readData(ofLength: maxBytes)
    }

    private func moveItem(from source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: source, to: destination)
    }
}
