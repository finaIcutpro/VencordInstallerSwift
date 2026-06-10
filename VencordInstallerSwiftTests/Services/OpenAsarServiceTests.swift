import Foundation
import Testing
@testable import VencordInstallerSwift

@Suite(.serialized)
struct OpenAsarServiceTests {
    @Test func detectsOpenAsarMarker() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            let openAsarData = Data("prefix OpenAsar suffix".utf8)
            let context = try DiscordAppFixture.create(in: temp.url, appAsarContents: openAsarData)
            let install = try DiscordAppFixture.install(context)

            let service = OpenAsarService(session: MockURLSession.make())
            #expect(await service.isOpenAsar(install: install))
        }
    }

    @Test func doesNotDetectVanillaAsar() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            let context = try DiscordAppFixture.create(
                in: temp.url,
                appAsarContents: Data("regular discord asar".utf8)
            )
            let install = try DiscordAppFixture.install(context)

            let service = OpenAsarService(session: MockURLSession.make())
            #expect(await service.isOpenAsar(install: install) == false)
        }
    }

    @Test func installBacksUpAndReplacesAsar() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            let original = Data("vanilla".utf8)
            let context = try DiscordAppFixture.create(in: temp.url, appAsarContents: original)
            let install = try DiscordAppFixture.install(context)
            let replacement = Data("open-asar-binary".utf8)

            try await MockURLProtocol.withHandler({ request in
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, replacement)
            }) {
                let service = OpenAsarService(session: MockURLSession.make())
                try await service.install(install: install)

                let backup = try Data(contentsOf: context.resourcesURL.appendingPathComponent("app.asar.backup"))
                let current = try Data(contentsOf: context.resourcesURL.appendingPathComponent("app.asar"))
                #expect(backup == original)
                #expect(current == replacement)
            }
        }
    }

    @Test func uninstallRestoresBackup() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            let context = try DiscordAppFixture.create(
                in: temp.url,
                appAsarContents: Data("current".utf8)
            )
            let install = try DiscordAppFixture.install(context)
            let backupURL = context.resourcesURL.appendingPathComponent("app.asar.backup")
            try Data("restored".utf8).write(to: backupURL)

            let service = OpenAsarService(session: MockURLSession.make())
            try await service.uninstall(install: install)

            let restored = try Data(contentsOf: context.resourcesURL.appendingPathComponent("app.asar"))
            #expect(restored == Data("restored".utf8))
        }
    }

    @Test func uninstallThrowsWhenNoBackupExists() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            let context = try DiscordAppFixture.create(in: temp.url)
            let install = try DiscordAppFixture.install(context)
            let service = OpenAsarService(session: MockURLSession.make())

            await #expect(throws: InstallerError.self) {
                try await service.uninstall(install: install)
            }
        }
    }
}
