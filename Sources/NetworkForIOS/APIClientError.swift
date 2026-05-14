import Foundation

public enum APIClientError: Error, Equatable, Sendable {
    case invalidEndpoint
    case encodingFailed
    case emptyResponseBody(statusCode: Int)
    case decodingFailed(statusCode: Int)
    case unacceptableStatusCode(statusCode: Int, publicMessage: String?)
}

extension APIClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "The request endpoint is invalid."
        case .encodingFailed:
            return "The request body could not be encoded."
        case .emptyResponseBody:
            return "The server returned an empty response."
        case .decodingFailed:
            return "The server response could not be decoded."
        case let .unacceptableStatusCode(_, publicMessage):
            return publicMessage ?? "The request failed."
        }
    }
}

public protocol APIErrorResponseDecoding: Sendable {
    func publicMessage(from data: Data, response: HTTPURLResponse) -> String?
}

public struct JSONAPIErrorResponseDecoder: APIErrorResponseDecoding {
    public init() {}

    public func publicMessage(from data: Data, response: HTTPURLResponse) -> String? {
        guard !data.isEmpty,
              let payload = try? JSONDecoder.networkDefault.decode(Payload.self, from: data) else {
            return nil
        }
        return payload.publicMessage?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }
}

private struct Payload: Decodable {
    let publicMessage: String?

    enum CodingKeys: String, CodingKey {
        case publicMessage
        case publicMessageSnake = "public_message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        publicMessage = try container.decodeIfPresent(String.self, forKey: .publicMessageSnake)
            ?? container.decodeIfPresent(String.self, forKey: .publicMessage)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
