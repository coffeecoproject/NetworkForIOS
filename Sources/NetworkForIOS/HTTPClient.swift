import Foundation

public protocol HTTPClient: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public enum HTTPClientError: Error, Equatable, Sendable {
    case nonHTTPResponse
}

extension HTTPClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .nonHTTPResponse:
            return "The server returned an invalid response."
        }
    }
}
