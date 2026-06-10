import Foundation
@testable import VencordInstallerSwift

enum TestFixtures {
    static let vencordReleaseJSON = """
    {
      "name": "DevBuild 9f2e6e7",
      "tag_name": "devbuild",
      "assets": [
        {
          "name": "patcher.js",
          "browser_download_url": "https://example.com/patcher.js"
        },
        {
          "name": "preload.js",
          "browser_download_url": "https://example.com/preload.js"
        },
        {
          "name": "renderer.js",
          "browser_download_url": "https://example.com/renderer.js"
        },
        {
          "name": "renderer.css",
          "browser_download_url": "https://example.com/renderer.css"
        },
        {
          "name": "source.zip",
          "browser_download_url": "https://example.com/source.zip"
        }
      ]
    }
    """

    static func decodeRelease() throws -> GitHubRelease {
        try JSONDecoder().decode(GitHubRelease.self, from: Data(vencordReleaseJSON.utf8))
    }
}
