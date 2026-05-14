import Foundation

public protocol APIRequest: Sendable {
    associatedtype Response: Decodable & Sendable

    var method: HTTPMethod { get }
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
    var successfulStatusCodes: HTTPStatusCodeSet { get }

    func makeBody(encoder: JSONEncoder) throws -> Data?
    func makeDecoder() -> JSONDecoder
}

public extension APIRequest {
    var queryItems: [URLQueryItem] { [] }
    var headers: [String: String] { [:] }
    var successfulStatusCodes: HTTPStatusCodeSet { .success }

    func makeDecoder() -> JSONDecoder {
        JSONDecoder.networkDefault
    }
}

public struct EmptyRequestBody: Encodable, Sendable {
    public init() {}
}

public struct EmptyResponse: Decodable, Equatable, Sendable {
    public init() {}
}

public struct JSONAPIRequest<Response: Decodable & Sendable, Body: Encodable & Sendable>: APIRequest {
    public let method: HTTPMethod
    public let path: String
    public let queryItems: [URLQueryItem]
    public let headers: [String: String]
    public let successfulStatusCodes: HTTPStatusCodeSet
    public let body: Body?
    private let decoderFactory: @Sendable () -> JSONDecoder

    public init(
        method: HTTPMethod,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        successfulStatusCodes: HTTPStatusCodeSet = .success,
        body: Body?,
        decoderFactory: @escaping @Sendable () -> JSONDecoder = { .networkDefault }
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.headers = headers
        self.successfulStatusCodes = successfulStatusCodes
        self.body = body
        self.decoderFactory = decoderFactory
    }

    public func makeBody(encoder: JSONEncoder) throws -> Data? {
        guard let body else {
            return nil
        }
        return try encoder.encode(body)
    }

    public func makeDecoder() -> JSONDecoder {
        decoderFactory()
    }
}

public extension JSONAPIRequest where Body == EmptyRequestBody {
    init(
        method: HTTPMethod,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        successfulStatusCodes: HTTPStatusCodeSet = .success,
        decoderFactory: @escaping @Sendable () -> JSONDecoder = { .networkDefault }
    ) {
        self.init(
            method: method,
            path: path,
            queryItems: queryItems,
            headers: headers,
            successfulStatusCodes: successfulStatusCodes,
            body: nil,
            decoderFactory: decoderFactory
        )
    }
}

extension JSONEncoder {
    public static var networkDefault: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    public static var networkDefault: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
