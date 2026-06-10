import Foundation

enum AsarReader {
    struct Parsed {
        let dataSize: UInt32
        let headerSize: UInt32
        let headerObjectSize: UInt32
        let headerStringSize: UInt32
        let headerJSON: String
        let payload: String
    }

    static func parse(_ data: Data) throws -> Parsed {
        guard data.count >= 16 else {
            throw AsarReaderError.truncatedHeader
        }

        let dataSize = readUInt32LE(data, offset: 0)
        let headerSize = readUInt32LE(data, offset: 4)
        let headerObjectSize = readUInt32LE(data, offset: 8)
        let headerStringSize = readUInt32LE(data, offset: 12)

        let headerEnd = 16 + Int(headerStringSize)
        guard data.count >= headerEnd else {
            throw AsarReaderError.truncatedHeaderJSON
        }

        let headerJSON = String(data: data.subdata(in: 16 ..< headerEnd), encoding: .utf8) ?? ""
        let payloadStart = 16 + Int(headerObjectSize - 4)
        guard payloadStart <= data.count else {
            throw AsarReaderError.truncatedPayload
        }

        let payload = String(data: data.subdata(in: payloadStart ..< data.count), encoding: .utf8) ?? ""

        return Parsed(
            dataSize: dataSize,
            headerSize: headerSize,
            headerObjectSize: headerObjectSize,
            headerStringSize: headerStringSize,
            headerJSON: headerJSON,
            payload: payload
        )
    }

    static func readUInt32LE(_ data: Data, offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}

enum AsarReaderError: Error {
    case truncatedHeader
    case truncatedHeaderJSON
    case truncatedPayload
}
