import Foundation
import Testing
@testable import VencordInstallerSwift

struct DiscordInstallTests {
    @Test func parseReturnsNilForMissingBundle() throws {
        try TemporaryDirectory.withDirectory { temp in
            #expect(DiscordInstall.parse(at: temp.file("Missing.app")) == nil)
        }
    }

    @Test func parseReturnsNilWithoutResourcesDirectory() throws {
        try TemporaryDirectory.withDirectory { temp in
            let appURL = temp.file("Discord.app")
            try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
            #expect(DiscordInstall.parse(at: appURL) == nil)
        }
    }

    @Test func parseDetectsStableInstall() throws {
        try TemporaryDirectory.withDirectory { temp in
            let context = try DiscordAppFixture.create(in: temp.url)
            let install = try DiscordAppFixture.install(context)

            #expect(install.branch == "stable")
            #expect(install.isPatched == false)
            #expect(install.asarDirectory == context.resourcesURL)
        }
    }

    @Test func parseDetectsPatchedInstall() throws {
        try TemporaryDirectory.withDirectory { temp in
            let context = try DiscordAppFixture.create(in: temp.url, includeBackupAsar: true)
            let install = try DiscordAppFixture.install(context)
            #expect(install.isPatched == true)
        }
    }

    @Test(
        arguments: [
            (DiscordAppFixture.Variant.canary, "canary"),
            (DiscordAppFixture.Variant.ptb, "ptb"),
            (DiscordAppFixture.Variant.development, "development"),
        ]
    )
    func parseInfersBranchFromAppName(variant: DiscordAppFixture.Variant, expectedBranch: String) throws {
        try TemporaryDirectory.withDirectory { temp in
            let context = try DiscordAppFixture.create(in: temp.url, variant: variant)
            let install = try DiscordAppFixture.install(context)
            #expect(install.branch == expectedBranch)
        }
    }

    @Test func displayNameIncludesPatchedBadge() throws {
        let install = DiscordInstall(
            id: "/Applications/Discord.app",
            path: URL(fileURLWithPath: "/Applications/Discord.app"),
            branch: "stable",
            appPath: URL(fileURLWithPath: "/Applications/Discord.app/Contents/Resources/app"),
            isPatched: true
        )
        #expect(install.displayName.contains("[PATCHED]"))
        #expect(install.displayName.hasPrefix("Stable"))
    }
}
