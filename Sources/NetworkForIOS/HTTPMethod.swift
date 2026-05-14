import Foundation

public enum HTTPMethod: String, CaseIterable, Sendable {
    case delete = "DELETE"
    case get = "GET"
    case head = "HEAD"
    case options = "OPTIONS"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
}

public struct HTTPStatusCodeSet: Equatable, Sendable {
    public let ranges: [ClosedRange<Int>]

    public init(ranges: [ClosedRange<Int>]) {
        self.ranges = ranges
    }

    public init(_ range: ClosedRange<Int>) {
        self.ranges = [range]
    }

    public func contains(_ statusCode: Int) -> Bool {
        ranges.contains { $0.contains(statusCode) }
    }

    public static let success = HTTPStatusCodeSet(200...299)
}
