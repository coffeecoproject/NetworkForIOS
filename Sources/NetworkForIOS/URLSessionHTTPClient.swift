import Foundation

public struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let configuration: HTTPClientConfiguration
    private let logger: NetworkEventLogger?

    public init(
        session: URLSession = .shared,
        configuration: HTTPClientConfiguration = .default,
        logger: NetworkEventLogger? = nil
    ) {
        self.session = session
        self.configuration = configuration
        self.logger = logger
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var preparedRequest = request
        if preparedRequest.timeoutInterval <= 0, configuration.timeoutInterval > 0 {
            preparedRequest.timeoutInterval = configuration.timeoutInterval
        }

        var attempt = 0
        while true {
            do {
                let (data, response) = try await session.data(for: preparedRequest)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw HTTPClientError.nonHTTPResponse
                }

                if shouldRetry(responseStatus: httpResponse.statusCode, request: preparedRequest, attempt: attempt) {
                    let delay = retryDelaySeconds(for: attempt, response: httpResponse)
                    logger?.log(Self.makeLogEvent(
                        category: .retryStatus,
                        request: preparedRequest,
                        response: httpResponse,
                        error: nil,
                        attempt: attempt + 1
                    ))
                    try await sleep(seconds: delay)
                    attempt += 1
                    continue
                }

                return (data, httpResponse)
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as URLError {
                if shouldRetry(errorCode: error.code, request: preparedRequest, attempt: attempt) {
                    let delay = retryDelaySeconds(for: attempt, response: nil)
                    logger?.log(Self.makeLogEvent(
                        category: .retryTransportError,
                        request: preparedRequest,
                        response: nil,
                        error: error,
                        attempt: attempt + 1
                    ))
                    try await sleep(seconds: delay)
                    attempt += 1
                    continue
                }
                throw error
            }
        }
    }

    private func shouldRetry(responseStatus: Int, request: URLRequest, attempt: Int) -> Bool {
        guard attempt < configuration.retryPolicy.maxRetryCount else {
            return false
        }
        return canRetry(request)
            && configuration.retryPolicy.retriableStatusCodes.contains(responseStatus)
    }

    private func shouldRetry(errorCode: URLError.Code, request: URLRequest, attempt: Int) -> Bool {
        guard attempt < configuration.retryPolicy.maxRetryCount else {
            return false
        }
        return canRetry(request)
            && configuration.retryPolicy.retriableURLErrorCodes.contains(errorCode)
    }

    private func canRetry(_ request: URLRequest) -> Bool {
        guard let method = Self.httpMethod(from: request) else {
            return false
        }
        return configuration.retryPolicy.retriableMethods.contains(method)
    }

    private func retryDelaySeconds(for attempt: Int, response: HTTPURLResponse?) -> TimeInterval {
        if let headerValue = response?.value(forHTTPHeaderField: "Retry-After"),
           let retryAfterSeconds = Self.retryAfterSeconds(from: headerValue),
           retryAfterSeconds > 0 {
            return clampedRetryDelay(retryAfterSeconds)
        }

        let base = configuration.retryPolicy.initialBackoffSeconds
        let multiplier = configuration.retryPolicy.backoffMultiplier
        return clampedRetryDelay(base * pow(multiplier, Double(attempt)))
    }

    private static func retryAfterSeconds(from headerValue: String) -> TimeInterval? {
        if let seconds = TimeInterval(headerValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return seconds
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        guard let date = formatter.date(from: headerValue) else {
            return nil
        }
        return date.timeIntervalSinceNow
    }

    private func sleep(seconds: TimeInterval) async throws {
        guard seconds > 0 else { return }
        let maximumTaskSleepSeconds = TimeInterval(UInt64.max / 1_000_000_000)
        let safeSeconds = min(seconds, maximumTaskSleepSeconds)
        let nanoseconds = UInt64(safeSeconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
    }

    private func clampedRetryDelay(_ seconds: TimeInterval) -> TimeInterval {
        guard seconds.isFinite else {
            return configuration.retryPolicy.maximumRetryDelaySeconds
        }
        return min(max(0, seconds), configuration.retryPolicy.maximumRetryDelaySeconds)
    }

    private static func httpMethod(from request: URLRequest) -> HTTPMethod? {
        guard let value = request.httpMethod, !value.isEmpty else {
            return .get
        }
        return HTTPMethod(rawValue: value.uppercased())
    }

    private static func makeLogEvent(
        category: NetworkLogEvent.Category,
        request: URLRequest,
        response: HTTPURLResponse?,
        error: URLError?,
        attempt: Int
    ) -> NetworkLogEvent {
        NetworkLogEvent(
            category: category,
            method: request.httpMethod,
            host: request.url?.host,
            path: request.url?.path,
            statusCode: response?.statusCode,
            urlErrorCode: error?.errorCode,
            attempt: attempt
        )
    }
}
