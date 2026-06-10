import Foundation

final class MockURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let handlerLock = NSLock()
    private static let operationLock = NSLock()
    nonisolated(unsafe) private static var handler: Handler?

    static func setHandler(_ handler: Handler?) {
        handlerLock.lock()
        defer { handlerLock.unlock() }
        self.handler = handler
    }

    static func withHandler<T>(
        _ handler: @escaping Handler,
        _ operation: () async throws -> T
    ) async rethrows -> T {
        operationLock.lock()
        defer { operationLock.unlock() }
        setHandler(handler)
        defer { setHandler(nil) }
        return try await operation()
    }

    override class func canInit(with request: URLRequest) -> Bool {
        handlerLock.lock()
        defer { handlerLock.unlock() }
        return handler != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.handlerLock.lock()
        let handler = Self.handler
        Self.handlerLock.unlock()

        guard let handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

enum MockURLSession {
    static func make() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

extension MockURLProtocol {
    static func reset() {
        setHandler(nil)
    }
}
