import Foundation

enum BuildInfo {
    static var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    static var userAgent: String {
        "VencordInstallerSwift/\(marketingVersion) (build \(buildNumber))"
    }
}
