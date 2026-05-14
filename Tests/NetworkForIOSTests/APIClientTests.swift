import XCTest
@testable import NetworkForIOS

final class APIClientTests: XCTestCase {
    func testSendsJSONRequestAndDecodesResponse() async throws {
        let httpClient = RecordingHTTPClient(
            data: Data(#"{"id":"event-1","title":"Coffee Meetup"}"#.utf8),
            statusCode: 200
        )
        let client = APIClient(
            baseURL: URL(string: "https://api.example.com/root")!,
            pathPrefix: "/api/v1",
            httpClient: httpClient,
            defaultHeaders: ["X-App-Version": "1.0"],
            headersProvider: StaticRequestHeadersProvider(["Authorization": "Bearer provider-token"])
        )
        let request = JSONAPIRequest<EventResponse, CreateEventRequest>(
            method: .post,
            path: "events",
            queryItems: [URLQueryItem(name: "include", value: "owner")],
            headers: ["X-Request-ID": "request-1"],
            body: CreateEventRequest(title: "Coffee Meetup")
        )

        let response = try await client.send(request)

        XCTAssertEqual(response, EventResponse(id: "event-1", title: "Coffee Meetup"))
        let recordedRequest = try XCTUnwrap(httpClient.requests.first)
        XCTAssertEqual(recordedRequest.httpMethod, "POST")
        XCTAssertEqual(recordedRequest.url?.absoluteString, "https://api.example.com/root/api/v1/events?include=owner")
        XCTAssertEqual(recordedRequest.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(recordedRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(recordedRequest.value(forHTTPHeaderField: "X-App-Version"), "1.0")
        XCTAssertEqual(recordedRequest.value(forHTTPHeaderField: "X-Request-ID"), "request-1")
        XCTAssertEqual(recordedRequest.value(forHTTPHeaderField: "Authorization"), "Bearer provider-token")
        XCTAssertEqual(
            String(data: try XCTUnwrap(recordedRequest.httpBody), encoding: .utf8),
            #"{"title":"Coffee Meetup"}"#
        )
    }

    func testProviderHeadersOverrideRequestHeadersForAuthorization() async throws {
        let httpClient = RecordingHTTPClient(data: Data(#"{"id":"1","title":"Done"}"#.utf8), statusCode: 200)
        let client = APIClient(
            baseURL: URL(string: "https://api.example.com")!,
            httpClient: httpClient,
            headersProvider: StaticRequestHeadersProvider(["Authorization": "Bearer provider-token"])
        )
        let request = JSONAPIRequest<EventResponse, EmptyRequestBody>(
            method: .get,
            path: "/events/1",
            headers: ["Authorization": "Bearer request-token"]
        )

        _ = try await client.send(request)

        XCTAssertEqual(
            httpClient.requests.first?.value(forHTTPHeaderField: "Authorization"),
            "Bearer provider-token"
        )
    }

    func testUnacceptableStatusUsesOnlyPublicMessage() async throws {
        let httpClient = RecordingHTTPClient(
            data: Data(#"{"message":"database stack detail","public_message":"Try again later."}"#.utf8),
            statusCode: 500
        )
        let client = APIClient(baseURL: URL(string: "https://api.example.com")!, httpClient: httpClient)
        let request = JSONAPIRequest<EventResponse, EmptyRequestBody>(method: .get, path: "/events/1")

        do {
            _ = try await client.send(request)
            XCTFail("Expected request to fail")
        } catch let error as APIClientError {
            XCTAssertEqual(error, .unacceptableStatusCode(statusCode: 500, publicMessage: "Try again later."))
            XCTAssertEqual(error.localizedDescription, "Try again later.")
        }
    }

    func testUnacceptableStatusIgnoresRawMessageWhenPublicMessageMissing() async throws {
        let httpClient = RecordingHTTPClient(
            data: Data(#"{"message":"internal account id 12345"}"#.utf8),
            statusCode: 400
        )
        let client = APIClient(baseURL: URL(string: "https://api.example.com")!, httpClient: httpClient)
        let request = JSONAPIRequest<EventResponse, EmptyRequestBody>(method: .get, path: "/events/1")

        do {
            _ = try await client.send(request)
            XCTFail("Expected request to fail")
        } catch let error as APIClientError {
            XCTAssertEqual(error, .unacceptableStatusCode(statusCode: 400, publicMessage: nil))
            XCTAssertEqual(error.localizedDescription, "The request failed.")
        }
    }

    func testEmptyResponseAllowsNoBody() async throws {
        let httpClient = RecordingHTTPClient(data: Data(), statusCode: 204)
        let client = APIClient(baseURL: URL(string: "https://api.example.com")!, httpClient: httpClient)
        let request = JSONAPIRequest<EmptyResponse, EmptyRequestBody>(
            method: .delete,
            path: "/sessions/current",
            successfulStatusCodes: HTTPStatusCodeSet(204...204)
        )

        let response = try await client.send(request)

        XCTAssertEqual(response, EmptyResponse())
    }

    func testBearerTokenProviderOmitsAuthorizationWhenTokenIsMissing() async throws {
        let provider = BearerTokenHeadersProvider { nil }
        let context = APIRequestContext(
            method: .get,
            url: URL(string: "https://api.example.com/me")!,
            path: "/me"
        )

        let headers = try await provider.headers(for: context)

        XCTAssertTrue(headers.isEmpty)
    }

    func testInvalidBaseURLSchemeIsRejected() async {
        let httpClient = RecordingHTTPClient(data: Data(), statusCode: 200)
        let client = APIClient(baseURL: URL(string: "file:///tmp/api")!, httpClient: httpClient)
        let request = JSONAPIRequest<EmptyResponse, EmptyRequestBody>(method: .get, path: "/me")

        do {
            _ = try await client.send(request)
            XCTFail("Expected invalid endpoint")
        } catch let error as APIClientError {
            XCTAssertEqual(error, .invalidEndpoint)
            XCTAssertTrue(httpClient.requests.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private struct EventResponse: Decodable, Equatable, Sendable {
    let id: String
    let title: String
}

private struct CreateEventRequest: Encodable, Sendable {
    let title: String
}

private final class RecordingHTTPClient: HTTPClient, @unchecked Sendable {
    private let data: Data
    private let statusCode: Int
    private(set) var requests: [URLRequest] = []

    init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://api.example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }
}
