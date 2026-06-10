import Foundation
import Testing
@testable import VencordInstallerSwift

@Suite(.serialized)
struct VencordDownloadServiceTests {
    @Test func downloadsRequiredAssetsOnly() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            try await VencordPathsTestSupport.withBaseDirectory(temp.url) {
                try await MockURLProtocol.withHandler({ request in
                    let name = request.url!.lastPathComponent
                    let body = Data("// \(name)".utf8)
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Length": "\(body.count)"]
                    )!
                    return (response, body)
                }) {
                    let release = try TestFixtures.decodeRelease()
                    let service = VencordDownloadService(session: MockURLSession.make())
                    let hash = try await service.installLatestBuilds(from: release)

                    #expect(hash == "9f2e6e7")
                    #expect(FileManager.default.fileExists(atPath: VencordPaths.patcherPath.path))
                    #expect(FileManager.default.fileExists(atPath: VencordPaths.distDirectory.appendingPathComponent("preload.js").path))
                    #expect(FileManager.default.fileExists(atPath: VencordPaths.distDirectory.appendingPathComponent("renderer.js").path))
                    #expect(FileManager.default.fileExists(atPath: VencordPaths.distDirectory.appendingPathComponent("renderer.css").path))
                    #expect(FileManager.default.fileExists(atPath: VencordPaths.packageJSONPath.path))
                    #expect(!FileManager.default.fileExists(atPath: VencordPaths.distDirectory.appendingPathComponent("source.zip").path))
                }
            }
        }
    }

    @Test func rejectsTruncatedDownloads() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            try await VencordPathsTestSupport.withBaseDirectory(temp.url) {
                try await MockURLProtocol.withHandler({ request in
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: ["Content-Length": "999"]
                    )!
                    return (response, Data("short".utf8))
                }) {
                    let release = try TestFixtures.decodeRelease()
                    let service = VencordDownloadService(session: MockURLSession.make())

                    await #expect(throws: InstallerError.self) {
                        try await service.installLatestBuilds(from: release)
                    }
                }
            }
        }
    }
}
