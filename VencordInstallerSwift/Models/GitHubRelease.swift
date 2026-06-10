import Foundation

struct GitHubRelease: Decodable, Sendable {
    let name: String
    let tagName: String
    let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case name
        case tagName = "tag_name"
        case assets
    }

    struct Asset: Decodable, Sendable {
        let name: String
        let downloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case downloadURL = "browser_download_url"
        }
    }

    var latestHash: String {
        guard let lastSpace = name.lastIndex(of: " ") else { return name }
        return String(name[name.index(after: lastSpace)...])
    }
}
