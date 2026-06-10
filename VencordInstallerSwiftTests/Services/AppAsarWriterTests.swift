import Foundation
import Testing
@testable import VencordInstallerSwift

struct AppAsarWriterTests {
    @Test func writesValidAsarStructure() throws {
        try TemporaryDirectory.withDirectory { temp in
            let patcherPath = "/Users/test/Library/Application Support/Vencord/dist/patcher.js"
            let outFile = temp.file("app.asar")

            try AppAsarWriter.write(to: outFile, patcherPath: patcherPath)

            let parsed = try AsarReader.parse(Data(contentsOf: outFile))
            #expect(parsed.dataSize == 4)
            #expect(parsed.headerSize == parsed.headerObjectSize + 4)
            #expect(parsed.headerJSON.contains("index.js"))
            #expect(parsed.headerJSON.contains("package.json"))
            #expect(parsed.payload.hasPrefix("require("))
            #expect(parsed.payload.contains(patcherPath))
            #expect(parsed.payload.contains("\"name\": \"discord\""))
        }
    }

    @Test func escapesSpecialCharactersInPatcherPath() throws {
        try TemporaryDirectory.withDirectory { temp in
            let patcherPath = "/tmp/quote\"backslash\\test/patcher.js"
            let outFile = temp.file("app.asar")

            try AppAsarWriter.write(to: outFile, patcherPath: patcherPath)

            let parsed = try AsarReader.parse(Data(contentsOf: outFile))
            #expect(parsed.payload.contains(#"require("/tmp/quote\"backslash\\test/patcher.js")"#))
        }
    }

    @Test func headerIsAlignedToFourBytes() throws {
        try TemporaryDirectory.withDirectory { temp in
            let outFile = temp.file("app.asar")
            try AppAsarWriter.write(to: outFile, patcherPath: "/short/path.js")

            let data = try Data(contentsOf: outFile)
            let parsed = try AsarReader.parse(data)
            let alignedSize = parsed.headerObjectSize - 4
            #expect(alignedSize % 4 == 0)
            #expect(16 + Int(alignedSize) + parsed.payload.utf8.count == data.count)
        }
    }

    @Test func overwritesExistingFile() throws {
        try TemporaryDirectory.withDirectory { temp in
            let outFile = temp.file("app.asar")
            try Data("old".utf8).write(to: outFile)

            try AppAsarWriter.write(to: outFile, patcherPath: "/patcher.js")

            let parsed = try AsarReader.parse(Data(contentsOf: outFile))
            #expect(parsed.payload.hasPrefix("require("))
        }
    }
}
