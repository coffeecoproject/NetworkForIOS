import Foundation

public struct HTTPClientRetryPolicy: Equatable, Sendable {
    public let maxRetryCount: Int
    public let initialBackoffSeconds: TimeInterval
    public let backoffMultiplier: Double
    public let maximumRetryDelaySeconds: TimeInterval
    public let retriableStatusCodes: Set<Int>
    public let retriableURLErrorCodes: Set<URLError.Code>
    public let retriableMethods: Set<HTTPMethod>

    public init(
        maxRetryCount: Int,
        initialBackoffSeconds: TimeInterval,
        backoffMultiplier: Double,
        maximumRetryDelaySeconds: TimeInterval = 30,
        retriableStatusCodes: Set<Int>,
        retriableURLErrorCodes: Set<URLError.Code>,
        retriableMethods: Set<HTTPMethod> = [.get, .head, .options]
    ) {
        self.maxRetryCount = max(0, maxRetryCount)
        self.initialBackoffSeconds = max(0, initialBackoffSeconds)
        self.backoffMultiplier = max(1, backoffMultiplier)
        self.maximumRetryDelaySeconds = max(0, maximumRetryDelaySeconds)
        self.retriableStatusCodes = retriableStatusCodes
        self.retriableURLErrorCodes = retriableURLErrorCodes
        self.retriableMethods = retriableMethods
    }

    public static let `default` = HTTPClientRetryPolicy(
        maxRetryCount: 2,
        initialBackoffSeconds: 0.35,
        backoffMultiplier: 2,
        maximumRetryDelaySeconds: 30,
        retriableStatusCodes: [408, 429, 500, 502, 503, 504],
        retriableURLErrorCodes: [
            .timedOut,
            .networkConnectionLost,
            .notConnectedToInternet,
            .cannotConnectToHost
        ],
        retriableMethods: [.get, .head, .options]
    )

    public static let noRetry = HTTPClientRetryPolicy(
        maxRetryCount: 0,
        initialBackoffSeconds: 0,
        backoffMultiplier: 1,
        maximumRetryDelaySeconds: 0,
        retriableStatusCodes: [],
        retriableURLErrorCodes: [],
        retriableMethods: []
    )
}

public struct HTTPClientConfiguration: Equatable, Sendable {
    public let timeoutInterval: TimeInterval
    public let retryPolicy: HTTPClientRetryPolicy

    public init(
        timeoutInterval: TimeInterval,
        retryPolicy: HTTPClientRetryPolicy = .default
    ) {
        self.timeoutInterval = max(0, timeoutInterval)
        self.retryPolicy = retryPolicy
    }

    public static let `default` = HTTPClientConfiguration(
        timeoutInterval: 15,
        retryPolicy: .default
    )
}
