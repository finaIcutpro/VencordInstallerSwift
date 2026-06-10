import Foundation

enum AppAsarError: LocalizedError {
    case createFailed(String, Error)
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .createFailed(let path, let error):
            "Failed to create \(path): \(error.localizedDescription)"
        case .writeFailed(let error):
            "Failed to write asar data: \(error.localizedDescription)"
        }
    }
}

enum AppAsarWriter {
    private static let packageJSON = """
    {
    \t"name": "discord",
    \t"main": "index.js"
    }
    """

    static func write(to outFile: URL, patcherPath: String) throws {
        let patcherPathString = jsonString(patcherPath)

        let indexJsContents = "require(\(patcherPathString))"
        let indexJsBytes = indexJsContents.utf8.count
        let packageJsonBytes = packageJSON.utf8.count

        var headerString = String(data: try JSONSerialization.data(withJSONObject: [
            "files": [
                "index.js": ["size": indexJsBytes, "offset": "0"],
                "package.json": ["size": packageJsonBytes, "offset": String(indexJsBytes)],
            ],
        ] as [String: Any], options: []), encoding: .utf8)!
        let headerStringSize = UInt32(headerString.utf8.count)
        let dataSize: UInt32 = 4
        let alignedSize = (headerStringSize + dataSize - 1) & ~(dataSize - 1)
        let headerSize = alignedSize + 8
        let headerObjectSize = alignedSize + dataSize
        let diff = alignedSize - headerStringSize
        if diff > 0 {
            headerString += String(repeating: "0", count: Int(diff))
        }

        let fileContents = indexJsContents + packageJSON
        let headerBytes = headerString.utf8.count
        let payloadBytes = fileContents.utf8.count
        var data = Data(capacity: 16 + headerBytes + payloadBytes)

        for value in [dataSize, headerSize, headerObjectSize, headerStringSize] {
            var le = value.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }

        data.append(contentsOf: headerString.utf8)
        data.append(contentsOf: fileContents.utf8)

        do {
            try data.write(to: outFile, options: .atomic)
        } catch {
            throw AppAsarError.writeFailed(error)
        }
    }

    private static func jsonString(_ value: String) -> String {
        var result = "\""
        for character in value {
            switch character {
            case "\\": result += "\\\\"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default: result.append(character)
            }
        }
        result += "\""
        return result
    }
}
