import Foundation

public protocol NetworkEventLogger: Sendable {
    func log(_ event: NetworkLogEvent)
}

public struct NetworkLogEvent: Equatable, Sendable {
    public enum Category: String, Sendable {
        case retryStatus
        case retryTransportError
    }

    public let category: Category
    public let method: String?
    public let host: String?
    public let path: String?
    public let statusCode: Int?
    public let urlErrorCode: Int?
    public let attempt: Int

    public init(
        category: Category,
        method: String?,
        host: String?,
        path: String?,
        statusCode: Int?,
        urlErrorCode: Int?,
        attempt: Int
    ) {
        self.category = category
        self.method = method
        self.host = host
        self.path = path
        self.statusCode = statusCode
        self.urlErrorCode = urlErrorCode
        self.attempt = attempt
    }
}
