import Foundation

public struct APIRequestContext: Equatable, Sendable {
    public let method: HTTPMethod
    public let url: URL
    public let path: String

    public init(method: HTTPMethod, url: URL, path: String) {
        self.method = method
        self.url = url
        self.path = path
    }
}

public protocol RequestHeadersProvider: Sendable {
    func headers(for context: APIRequestContext) async throws -> [String: String]
}

public struct StaticRequestHeadersProvider: RequestHeadersProvider {
    private let values: [String: String]

    public init(_ values: [String: String]) {
        self.values = values
    }

    public func headers(for context: APIRequestContext) async throws -> [String: String] {
        values
    }
}

public struct BearerTokenHeadersProvider: RequestHeadersProvider {
    private let tokenProvider: @Sendable () async throws -> String?

    public init(tokenProvider: @escaping @Sendable () async throws -> String?) {
        self.tokenProvider = tokenProvider
    }

    public func headers(for context: APIRequestContext) async throws -> [String: String] {
        guard let token = try await tokenProvider(), !token.isEmpty else {
            return [:]
        }
        return ["Authorization": "Bearer \(token)"]
    }
}
