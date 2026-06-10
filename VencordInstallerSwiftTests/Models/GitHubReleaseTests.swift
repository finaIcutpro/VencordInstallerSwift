import Foundation
import Testing
@testable import VencordInstallerSwift

struct GitHubReleaseTests {
    @Test func decodesGitHubJSON() throws {
        let release = try TestFixtures.decodeRelease()
        #expect(release.name == "DevBuild 9f2e6e7")
        #expect(release.tagName == "devbuild")
        #expect(release.assets.count == 5)
        #expect(release.assets.first?.name == "patcher.js")
    }

    @Test func latestHashUsesSubstringAfterLastSpace() throws {
        let release = try TestFixtures.decodeRelease()
        #expect(release.latestHash == "9f2e6e7")
    }

    @Test func latestHashWithoutSpaceReturnsFullName() throws {
        let json = #"{"name":"ContinuousBuild","tag_name":"cb","assets":[]}"#
        let release = try JSONDecoder().decode(GitHubRelease.self, from: Data(json.utf8))
        #expect(release.latestHash == "ContinuousBuild")
    }
}
