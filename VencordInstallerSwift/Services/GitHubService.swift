import Foundation

actor GitHubService {
    static let releaseURL = URL(string: "https://api.github.com/repos/Vendicated/Vencord/releases/latest")!
    static let releaseFallbackURL = URL(string: "https://vencord.dev/releases/vencord")!

    private let session: URLSession
    private let userAgent: String

    init(session: URLSession = .shared) {
        self.session = session
        self.userAgent = "\(BuildInfo.userAgent) (https://github.com/Vencord/Installer)"
    }

    func fetchLatestRelease() async throws -> GitHubRelease {
        do {
            return try await fetchRelease(from: Self.releaseURL, allowFallback: true)
        } catch {
            throw InstallerError.githubFetchFailed(error.localizedDescription)
        }
    }

    nonisolated func installedHash() -> String {
        guard let data = try? Data(contentsOf: VencordPaths.patcherPath),
              let firstLine = String(data: data, encoding: .utf8)?
                .split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
                .first else {
            return "None"
        }

        let line = String(firstLine)
        guard line.hasPrefix("// Vencord ") else { return "None" }
        return String(line.dropFirst("// Vencord ".count))
    }

    private func fetchRelease(from url: URL, allowFallback: Bool) async throws -> GitHubRelease {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if http.statusCode >= 300 {
            let isRateLimited = [401, 403, 429].contains(http.statusCode)
            if isRateLimited && allowFallback && url != Self.releaseFallbackURL {
                return try await fetchRelease(from: Self.releaseFallbackURL, allowFallback: false)
            }
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }
}
