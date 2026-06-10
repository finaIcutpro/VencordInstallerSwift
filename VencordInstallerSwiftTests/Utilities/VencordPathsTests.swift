import Foundation
import Testing
@testable import VencordInstallerSwift

@Suite(.serialized)
struct VencordPathsTests {
    @Test func prefersVencordUserDataDir() {
        let base = VencordPaths.resolveBaseDirectory(using: [
            "VENCORD_USER_DATA_DIR": "/tmp/custom-vencord",
        ])
        #expect(base.path == "/tmp/custom-vencord")
    }

    @Test func derivesFromDiscordUserDataDir() {
        let base = VencordPaths.resolveBaseDirectory(using: [
            "DISCORD_USER_DATA_DIR": "/Users/test/Library/Application Support/discord",
        ])
        #expect(base.path == "/Users/test/Library/Application Support/VencordData")
    }

    @Test func ensureDistDirectoryCreatesHierarchy() throws {
        try TemporaryDirectory.withDirectory { temp in
            try VencordPathsTestSupport.withBaseDirectory(temp.url) {
                try VencordPaths.ensureDistDirectory()
                var isDirectory: ObjCBool = false
                #expect(FileManager.default.fileExists(atPath: VencordPaths.distDirectory.path, isDirectory: &isDirectory))
                #expect(isDirectory.boolValue)
            }
        }
    }
}
