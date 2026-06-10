import Foundation

enum InstallerError: LocalizedError {
    case discordNotFound
    case discordRunning
    case permissionDenied(path: String)
    case githubFetchFailed(String)
    case downloadFailed(String)
    case patchFailed(String)
    case openAsarFailed(String)
    case noOpenAsarBackup
    case vencordDataUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .discordNotFound:
            "No valid Discord install found at the selected location."
        case .discordRunning:
            "Cannot patch because Discord's files are used by a different process.\nMake sure you close Discord before trying to patch!"
        case .permissionDenied(let path):
            """
            Permission denied. Please grant the installer Full Disk Access in System Settings (Privacy & Security).

            If that also doesn't work, try running the following command in your terminal:
            sudo chown -R "${USER}:wheel" \(path)
            """
        case .githubFetchFailed(let message):
            "Failed to fetch Vencord release data: \(message)"
        case .downloadFailed(let message):
            "Failed to download Vencord files: \(message)"
        case .patchFailed(let message):
            message
        case .openAsarFailed(let message):
            message
        case .noOpenAsarBackup:
            "No app.asar.backup. Reinstall Discord."
        case .vencordDataUnavailable(let message):
            "Failed to prepare Vencord data directory: \(message)"
        }
    }

    static func fromFileError(_ error: Error, path: String) -> InstallerError {
        let nsError = error as NSError
        if nsError.domain == NSPOSIXErrorDomain && (nsError.code == Int(EPERM) || nsError.code == Int(EACCES)) {
            return .permissionDenied(path: path)
        }
        if nsError.domain == NSCocoaErrorDomain &&
            (nsError.code == NSFileWriteNoPermissionError || nsError.code == NSFileReadNoPermissionError) {
            return .permissionDenied(path: path)
        }
        if nsError.domain == NSPOSIXErrorDomain && nsError.code == Int(EBUSY) {
            return .discordRunning
        }
        return .patchFailed(error.localizedDescription)
    }
}
