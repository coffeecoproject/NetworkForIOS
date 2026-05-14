import XCTest
@testable import NetworkForIOS

final class URLSessionHTTPClientTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        StubURLProtocol.reset()
    }

    func testRetriesRetriableStatusCode() async throws {
        StubURLProtocol.setResponses([
            (Data(), HTTPURLResponse(
                url: URL(string: "https://api.example.com/events")!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!),
            (Data(#"{"ok":true}"#.utf8), HTTPURLResponse(
                url: URL(string: "https://api.example.com/events")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!)
        ])
        let session = makeStubbedSession()
        let logger = RecordingNetworkLogger()
        let client = URLSessionHTTPClient(
            session: session,
            configuration: HTTPClientConfiguration(
                timeoutInterval: 5,
                retryPolicy: HTTPClientRetryPolicy(
                    maxRetryCount: 1,
                    initialBackoffSeconds: 0,
                    backoffMultiplier: 1,
                    retriableStatusCodes: [503],
                    retriableURLErrorCodes: []
                )
            ),
            logger: logger
        )

        let request = URLRequest(url: URL(string: "https://api.example.com/events?trace=redacted")!)
        let (_, response) = try await client.send(request)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(StubURLProtocol.requestCount, 2)
        XCTAssertEqual(logger.events.count, 1)
        XCTAssertEqual(logger.events.first?.category, .retryStatus)
        XCTAssertEqual(logger.events.first?.host, "api.example.com")
        XCTAssertEqual(logger.events.first?.path, "/events")
    }

    func testDefaultPolicyDoesNotRetryPostRequest() async throws {
        StubURLProtocol.setResponses([
            (Data(), HTTPURLResponse(
                url: URL(string: "https://api.example.com/events")!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!),
            (Data(#"{"ok":true}"#.utf8), HTTPURLResponse(
                url: URL(string: "https://api.example.com/events")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!)
        ])
        let client = URLSessionHTTPClient(
            session: makeStubbedSession(),
            configuration: HTTPClientConfiguration(
                timeoutInterval: 5,
                retryPolicy: HTTPClientRetryPolicy(
                    maxRetryCount: 1,
                    initialBackoffSeconds: 0,
                    backoffMultiplier: 1,
                    retriableStatusCodes: [503],
                    retriableURLErrorCodes: []
                )
            )
        )
        var request = URLRequest(url: URL(string: "https://api.example.com/events")!)
        request.httpMethod = "POST"

        let (_, response) = try await client.send(request)

        XCTAssertEqual(response.statusCode, 503)
        XCTAssertEqual(StubURLProtocol.requestCount, 1)
    }

    func testPostRequestRetriesOnlyWhenExplicitlyAllowed() async throws {
        StubURLProtocol.setResponses([
            (Data(), HTTPURLResponse(
                url: URL(string: "https://api.example.com/events")!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: ["Retry-After": "120"]
            )!),
            (Data(#"{"ok":true}"#.utf8), HTTPURLResponse(
                url: URL(string: "https://api.example.com/events")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!)
        ])
        let client = URLSessionHTTPClient(
            session: makeStubbedSession(),
            configuration: HTTPClientConfiguration(
                timeoutInterval: 5,
                retryPolicy: HTTPClientRetryPolicy(
                    maxRetryCount: 1,
                    initialBackoffSeconds: 0,
                    backoffMultiplier: 1,
                    maximumRetryDelaySeconds: 0,
                    retriableStatusCodes: [503],
                    retriableURLErrorCodes: [],
                    retriableMethods: [.post]
                )
            )
        )
        var request = URLRequest(url: URL(string: "https://api.example.com/events")!)
        request.httpMethod = "POST"

        let (_, response) = try await client.send(request)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(StubURLProtocol.requestCount, 2)
    }

    func testThrowsNonHTTPResponse() async throws {
        StubURLProtocol.setResponses([(Data(), URLResponse(
            url: URL(string: "https://api.example.com/events")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        ))])
        let client = URLSessionHTTPClient(session: makeStubbedSession())

        do {
            _ = try await client.send(URLRequest(url: URL(string: "https://api.example.com/events")!))
            XCTFail("Expected non HTTP response")
        } catch let error as HTTPClientError {
            XCTAssertEqual(error, .nonHTTPResponse)
        }
    }
}

private func makeStubbedSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return URLSession(configuration: configuration)
}

private final class RecordingNetworkLogger: NetworkEventLogger, @unchecked Sendable {
    private(set) var events: [NetworkLogEvent] = []

    func log(_ event: NetworkLogEvent) {
        events.append(event)
    }
}

private final class StubURLProtocol: URLProtocol {
    private static let store = StubURLProtocolStore()

    static var requestCount: Int {
        store.requestCount
    }

    static func reset() {
        store.reset()
    }

    static func setResponses(_ responses: [(Data, URLResponse)]) {
        store.setResponses(responses)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let (data, response) = Self.store.nextResponse() else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class StubURLProtocolStore: @unchecked Sendable {
    private let lock = NSLock()
    private var responses: [(Data, URLResponse)] = []
    private var count = 0

    var requestCount: Int {
        lock.withLock { count }
    }

    func reset() {
        lock.withLock {
            responses = []
            count = 0
        }
    }

    func setResponses(_ values: [(Data, URLResponse)]) {
        lock.withLock {
            responses = values
            count = 0
        }
    }

    func nextResponse() -> (Data, URLResponse)? {
        lock.withLock {
            count += 1
            guard !responses.isEmpty else {
                return nil
            }
            return responses.removeFirst()
        }
    }
}
