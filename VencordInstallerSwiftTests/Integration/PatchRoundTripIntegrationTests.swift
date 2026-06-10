import Foundation
import Testing
@testable import VencordInstallerSwift

@Suite(.serialized)
struct PatchRoundTripIntegrationTests {
    @Test func downloadPatchAndUnpatch() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            try await VencordPathsTestSupport.withBaseDirectory(temp.url) {
                try await MockURLProtocol.withHandler({ request in
                    let name = request.url!.lastPathComponent
                    let body = Data(name.utf8)
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Length": "\(body.count)"]
                    )!
                    return (response, body)
                }) {
                    let context = try DiscordAppFixture.create(
                        in: temp.file("apps"),
                        appAsarContents: Data("discord-original".utf8)
                    )
                    var install = try DiscordAppFixture.install(context)

                    let release = try TestFixtures.decodeRelease()
                    let downloader = VencordDownloadService(session: MockURLSession.make())
                    _ = try await downloader.installLatestBuilds(from: release)

                    let patcher = PatchService()
                    install = try await patcher.patch(install: install, patcherPath: VencordPaths.patcherPath)
                    install = try await patcher.unpatch(install: install)

                    let restored = try Data(contentsOf: context.resourcesURL.appendingPathComponent("app.asar"))
                    #expect(restored == Data("discord-original".utf8))
                    #expect(FileManager.default.fileExists(atPath: VencordPaths.patcherPath.path))
                }
            }
        }
    }
}
