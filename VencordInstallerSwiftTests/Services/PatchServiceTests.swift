import Foundation
import Testing
@testable import VencordInstallerSwift

struct PatchServiceTests {
    @Test func patchCreatesBackupAndStubAsar() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            let context = try DiscordAppFixture.create(in: temp.url)
            var install = try DiscordAppFixture.install(context)
            let patcherPath = temp.file("patcher.js")
            try "// Vencord test".write(to: patcherPath, atomically: true, encoding: .utf8)

            let service = PatchService()
            install = try await service.patch(install: install, patcherPath: patcherPath)

            let resources = context.resourcesURL
            #expect(install.isPatched)
            #expect(FileManager.default.fileExists(atPath: resources.appendingPathComponent("_app.asar").path))
            let parsed = try AsarReader.parse(Data(contentsOf: resources.appendingPathComponent("app.asar")))
            #expect(parsed.payload.contains(patcherPath.path))
        }
    }

    @Test func unpatchRestoresOriginalAsar() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            let original = Data("original-asar-contents".utf8)
            let context = try DiscordAppFixture.create(in: temp.url, appAsarContents: original)
            var install = try DiscordAppFixture.install(context)
            let patcherPath = temp.file("patcher.js")
            try "require('x')".write(to: patcherPath, atomically: true, encoding: .utf8)

            let service = PatchService()
            install = try await service.patch(install: install, patcherPath: patcherPath)
            install = try await service.unpatch(install: install)

            let restored = try Data(contentsOf: context.resourcesURL.appendingPathComponent("app.asar"))
            #expect(restored == original)
            #expect(install.isPatched == false)
            #expect(!FileManager.default.fileExists(atPath: context.resourcesURL.appendingPathComponent("_app.asar").path))
        }
    }

    @Test func patchLeavesOriginalIntactWhenDirectoryIsReadOnly() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            let original = Data("keep-me".utf8)
            let context = try DiscordAppFixture.create(in: temp.url, appAsarContents: original)
            let install = try DiscordAppFixture.install(context)
            let patcherPath = temp.file("patcher.js")
            try "patcher".write(to: patcherPath, atomically: true, encoding: .utf8)

            try FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: 0o555)],
                ofItemAtPath: context.resourcesURL.path
            )
            defer {
                try? FileManager.default.setAttributes(
                    [.posixPermissions: NSNumber(value: 0o755)],
                    ofItemAtPath: context.resourcesURL.path
                )
            }

            let service = PatchService()
            await #expect(throws: Error.self) {
                _ = try await service.patch(install: install, patcherPath: patcherPath)
            }

            #expect(FileManager.default.fileExists(atPath: context.resourcesURL.appendingPathComponent("app.asar").path))
            #expect(!FileManager.default.fileExists(atPath: context.resourcesURL.appendingPathComponent("_app.asar").path))
            let contents = try Data(contentsOf: context.resourcesURL.appendingPathComponent("app.asar"))
            #expect(contents == original)
        }
    }

    @Test func repatchUninstallsBeforePatchingAgain() async throws {
        try await TemporaryDirectory.withDirectory { temp in
            let context = try DiscordAppFixture.create(in: temp.url, appAsarContents: Data("v1".utf8))
            var install = try DiscordAppFixture.install(context)
            let patcherPath = temp.file("patcher.js")
            try "patcher".write(to: patcherPath, atomically: true, encoding: .utf8)

            let service = PatchService()
            install = try await service.patch(install: install, patcherPath: patcherPath)
            install.isPatched = true
            install = try await service.patch(install: install, patcherPath: patcherPath)

            let backup = try Data(contentsOf: context.resourcesURL.appendingPathComponent("_app.asar"))
            #expect(backup == Data("v1".utf8))
        }
    }
}
