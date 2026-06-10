import CoreServices
import Foundation

final class DiscordUpdateWatcher: @unchecked Sendable {
    private let queue = DispatchQueue(label: "dev.vendicated.vencordinstaller.fsevents")
    private var stream: FSEventStreamRef?
    private var watchedPaths: [String] = []
    var onResourcesChanged: (@Sendable (String) -> Void)?

    func start(watching installs: [DiscordInstall]) {
        stop()
        let paths = installs.map(\.resourcesPath.path)
        guard !paths.isEmpty else { return }

        watchedPaths = paths
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes
        )

        stream = FSEventStreamCreate(
            nil,
            Self.eventCallback,
            &context,
            paths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            flags
        )

        guard let stream else { return }
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
        watchedPaths = []
    }

    private static let eventCallback: FSEventStreamCallback = { _, clientInfo, numEvents, eventPaths, eventFlags, _ in
        guard let clientInfo, let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }
        let watcher = Unmanaged<DiscordUpdateWatcher>.fromOpaque(clientInfo).takeUnretainedValue()

        for index in 0 ..< numEvents {
            let path = paths[index]
            let flags = eventFlags[index]
            guard flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified) != 0 else { continue }
            guard path.hasSuffix("app.asar") || path.hasSuffix("_app.asar") else { continue }
            guard let resourcesPath = watcher.matchingResourcesPath(for: path) else { continue }
            watcher.onResourcesChanged?(resourcesPath)
        }
    }

    private func matchingResourcesPath(for changedPath: String) -> String? {
        watchedPaths.first { changedPath.hasPrefix($0) }
    }
}
