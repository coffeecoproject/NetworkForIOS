import Foundation

public struct APIClient {
    private let baseURL: URL
    private let pathPrefix: String
    private let httpClient: HTTPClient
    private let defaultHeaders: [String: String]
    private let headersProvider: RequestHeadersProvider?
    private let encoderFactory: @Sendable () -> JSONEncoder
    private let errorResponseDecoder: APIErrorResponseDecoding

    public init(
        baseURL: URL,
        pathPrefix: String = "",
        httpClient: HTTPClient = URLSessionHTTPClient(),
        defaultHeaders: [String: String] = [:],
        headersProvider: RequestHeadersProvider? = nil,
        encoderFactory: @escaping @Sendable () -> JSONEncoder = { .networkDefault },
        errorResponseDecoder: APIErrorResponseDecoding = JSONAPIErrorResponseDecoder()
    ) {
        self.baseURL = baseURL
        self.pathPrefix = pathPrefix
        self.httpClient = httpClient
        self.defaultHeaders = defaultHeaders
        self.headersProvider = headersProvider
        self.encoderFactory = encoderFactory
        self.errorResponseDecoder = errorResponseDecoder
    }

    public func send<Request: APIRequest>(_ request: Request) async throws -> Request.Response {
        var urlRequest = try makeURLRequest(for: request)
        let context = APIRequestContext(
            method: request.method,
            url: urlRequest.url ?? baseURL,
            path: request.path
        )
        let providerHeaders = try await headersProvider?.headers(for: context) ?? [:]
        applyHeaders(defaultHeaders, to: &urlRequest)
        applyHeaders(request.headers, to: &urlRequest)
        applyHeaders(providerHeaders, to: &urlRequest)

        do {
            if let body = try request.makeBody(encoder: encoderFactory()) {
                urlRequest.httpBody = body
                if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            }
        } catch {
            throw APIClientError.encodingFailed
        }

        if urlRequest.value(forHTTPHeaderField: "Accept") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        }

        let (data, response) = try await httpClient.send(urlRequest)
        guard request.successfulStatusCodes.contains(response.statusCode) else {
            throw APIClientError.unacceptableStatusCode(
                statusCode: response.statusCode,
                publicMessage: errorResponseDecoder.publicMessage(from: data, response: response)
            )
        }

        if Request.Response.self == EmptyResponse.self {
            return EmptyResponse() as! Request.Response
        }

        guard !data.isEmpty else {
            throw APIClientError.emptyResponseBody(statusCode: response.statusCode)
        }

        do {
            return try request.makeDecoder().decode(Request.Response.self, from: data)
        } catch {
            throw APIClientError.decodingFailed(statusCode: response.statusCode)
        }
    }

    private func makeURLRequest<Request: APIRequest>(for request: Request) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              components.host?.isEmpty == false else {
            throw APIClientError.invalidEndpoint
        }

        components.path = Self.joinPaths(components.path, pathPrefix, request.path)
        components.queryItems = request.queryItems.isEmpty ? nil : request.queryItems

        guard let url = components.url else {
            throw APIClientError.invalidEndpoint
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        return urlRequest
    }

    private func applyHeaders(_ headers: [String: String], to request: inout URLRequest) {
        for (field, value) in headers where !field.isEmpty {
            request.setValue(value, forHTTPHeaderField: field)
        }
    }

    private static func joinPaths(_ parts: String...) -> String {
        let trimmedParts = parts
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }
            .filter { !$0.isEmpty }
        guard !trimmedParts.isEmpty else {
            return "/"
        }
        return "/" + trimmedParts.joined(separator: "/")
    }
}
