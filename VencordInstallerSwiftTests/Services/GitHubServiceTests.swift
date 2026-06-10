import Foundation
import Testing
@testable import VencordInstallerSwift

@Suite(.serialized)
struct GitHubServiceTests {
    @Test func fetchLatestReleaseDecodesResponse() async throws {
        try await MockURLProtocol.withHandler({ request in
            #expect(request.value(forHTTPHeaderField: "User-Agent")?.contains("VencordInstallerSwift") == true)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(TestFixtures.vencordReleaseJSON.utf8))
        }) {
            let service = GitHubService(session: MockURLSession.make())
            let release = try await service.fetchLatestRelease()
            #expect(release.latestHash == "9f2e6e7")
        }
    }

    @Test func fetchFallsBackOnRateLimit() async throws {
        var requestCount = 0
        try await MockURLProtocol.withHandler({ request in
            requestCount += 1
            let status = request.url?.host == "api.github.com" ? 403 : 200
            let body = status == 200 ? TestFixtures.vencordReleaseJSON : "{}"
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(body.utf8))
        }) {
            let service = GitHubService(session: MockURLSession.make())
            let release = try await service.fetchLatestRelease()
            #expect(requestCount == 2)
            #expect(release.tagName == "devbuild")
        }
    }

    @Test func installedHashReadsPatcherHeader() throws {
        try TemporaryDirectory.withDirectory { temp in
            try VencordPathsTestSupport.withBaseDirectory(temp.url) {
                try VencordPaths.ensureDistDirectory()
                let patcher = "// Vencord deadbeef\nconsole.log('hi')"
                try patcher.write(to: VencordPaths.patcherPath, atomically: true, encoding: .utf8)

                let service = GitHubService(session: MockURLSession.make())
                #expect(service.installedHash() == "deadbeef")
            }
        }
    }

    @Test func installedHashReturnsNoneWhenMissing() throws {
        try TemporaryDirectory.withDirectory { temp in
            try VencordPathsTestSupport.withBaseDirectory(temp.url) {
                let service = GitHubService(session: MockURLSession.make())
                #expect(service.installedHash() == "None")
            }
        }
    }
}
