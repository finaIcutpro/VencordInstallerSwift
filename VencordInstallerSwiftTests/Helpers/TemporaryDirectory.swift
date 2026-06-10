import Foundation

struct TemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("VencordInstallerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func file(_ name: String) -> URL {
        url.appendingPathComponent(name)
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}

extension TemporaryDirectory {
    static func withDirectory<T>(
        _ operation: (TemporaryDirectory) throws -> T
    ) throws -> T {
        let directory = try TemporaryDirectory()
        defer { directory.remove() }
        return try operation(directory)
    }

    static func withDirectory<T>(
        _ operation: (TemporaryDirectory) async throws -> T
    ) async throws -> T {
        let directory = try TemporaryDirectory()
        defer { directory.remove() }
        return try await operation(directory)
    }
}
