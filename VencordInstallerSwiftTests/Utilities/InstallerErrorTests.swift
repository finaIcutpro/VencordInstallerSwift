import Foundation
import Testing
@testable import VencordInstallerSwift

struct InstallerErrorTests {
    @Test func mapsPermissionDeniedFromPOSIX() {
        let error = InstallerError.fromFileError(
            NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM)),
            path: "/Applications/Discord.app"
        )
        guard case .permissionDenied(let path) = error else {
            Issue.record("Expected permissionDenied")
            return
        }
        #expect(path == "/Applications/Discord.app")
    }

    @Test func mapsDiscordRunningFromEBUSY() {
        let error = InstallerError.fromFileError(
            NSError(domain: NSPOSIXErrorDomain, code: Int(EBUSY)),
            path: "/Applications/Discord.app"
        )
        guard case .discordRunning = error else {
            Issue.record("Expected discordRunning")
            return
        }
    }

    @Test func mapsUnknownErrorsToPatchFailed() {
        let error = InstallerError.fromFileError(
            NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "boom"]),
            path: "/Applications/Discord.app"
        )
        guard case .patchFailed(let message) = error else {
            Issue.record("Expected patchFailed")
            return
        }
        #expect(message == "boom")
    }
}
