import Foundation

actor VencordDownloadService {
    private static let assetPrefixes = ["patcher.js", "preload.js", "renderer.js", "renderer.css"]

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func installLatestBuilds(from release: GitHubRelease) async throws -> String {
        try VencordPaths.ensureDistDirectory()

        let packageData = Data("{}".utf8)
        try packageData.write(to: VencordPaths.packageJSONPath, options: .atomic)

        let assets = release.assets.filter { asset in
            Self.assetPrefixes.contains { asset.name.hasPrefix($0) }
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for asset in assets {
                group.addTask {
                    try await self.downloadAsset(asset)
                }
            }
            try await group.waitForAll()
        }

        return release.latestHash
    }

    private func downloadAsset(_ asset: GitHubRelease.Asset) async throws {
        let (tempURL, response) = try await session.download(from: asset.downloadURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        guard let http = response as? HTTPURLResponse, http.statusCode < 300 else {
            throw InstallerError.downloadFailed("Failed to download \(asset.name)")
        }

        let destination = VencordPaths.distDirectory.appendingPathComponent(asset.name)
        let data = try Data(contentsOf: tempURL)

        if let contentLength = http.value(forHTTPHeaderField: "Content-Length"),
           let expected = Int(contentLength),
           data.count != expected {
            throw InstallerError.downloadFailed(
                "Unexpected end of input for \(asset.name). Content-Length was \(expected), but read \(data.count)"
            )
        }

        try data.write(to: destination, options: .atomic)
    }
}
