import Foundation
@testable import VencordInstallerSwift

enum VencordPathsTestSupport {
    private static let lock = NSLock()
    private static let operationLock = NSLock()
    private static var providerStack: [@Sendable () -> URL] = []

    static func useBaseDirectory(_ url: URL) {
        lock.lock()
        defer { lock.unlock() }
        providerStack.append(VencordPaths.baseDirectoryProvider)
        VencordPaths.baseDirectoryProvider = { url }
    }

    static func restore() {
        lock.lock()
        defer { lock.unlock() }
        guard let previous = providerStack.popLast() else { return }
        VencordPaths.baseDirectoryProvider = previous
    }
}

extension VencordPathsTestSupport {
    static func withBaseDirectory<T>(
        _ url: URL,
        _ operation: () throws -> T
    ) throws -> T {
        operationLock.lock()
        defer { operationLock.unlock() }
        useBaseDirectory(url)
        defer { restore() }
        return try operation()
    }

    static func withBaseDirectory<T>(
        _ url: URL,
        _ operation: () async throws -> T
    ) async throws -> T {
        operationLock.lock()
        defer { operationLock.unlock() }
        useBaseDirectory(url)
        defer { restore() }
        return try await operation()
    }
}
