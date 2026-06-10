import Foundation
import Testing
@testable import VencordInstallerSwift

struct AppAsarWriterTests {
    @Test func writesValidAsarStructure() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let patcherPath = "/Users/test/Library/Application Support/Vencord/dist/patcher.js"
        let outFile = tempDir.appendingPathComponent("app.asar")

        try AppAsarWriter.write(to: outFile, patcherPath: patcherPath)

        let data = try Data(contentsOf: outFile)
        let dataSize = readUInt32LE(data, offset: 0)
        let headerObjectSize = readUInt32LE(data, offset: 8)
        let payloadStart = 16 + Int(headerObjectSize - 4)
        let payload = String(data: data.subdata(in: payloadStart ..< data.count), encoding: .utf8) ?? ""

        #expect(dataSize == 4)
        #expect(payload.hasPrefix("require("))
        #expect(payload.contains(patcherPath))
        #expect(payload.contains("discord"))
    }

    private func readUInt32LE(_ data: Data, offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}
