# Integration Guide / 接入指南

## 1. Create A Transport / 创建传输层

```swift
let transport = URLSessionHTTPClient(
    configuration: HTTPClientConfiguration(
        timeoutInterval: 15,
        retryPolicy: .default
    )
)
```

`URLSessionHTTPClient` retries transient status codes such as `429`, `500`, `502`, `503`, and `504`, and selected transient `URLError.Code` values.

`URLSessionHTTPClient` 会重试 `429`、`500`、`502`、`503`、`504` 等临时状态码，以及部分临时 `URLError.Code`。

By default, retries only apply to idempotent methods: `GET`, `HEAD`, and `OPTIONS`.

默认情况下，自动重试只作用于幂等方法：`GET`、`HEAD`、`OPTIONS`。

Write methods such as `POST`, `PUT`, `PATCH`, and `DELETE` are not retried unless the app explicitly opts in through `retriableMethods`.

`POST`、`PUT`、`PATCH`、`DELETE` 等写操作默认不会重试，除非 App 通过 `retriableMethods` 显式开启。

```swift
let retryingPostPolicy = HTTPClientRetryPolicy(
    maxRetryCount: 1,
    initialBackoffSeconds: 0.35,
    backoffMultiplier: 2,
    maximumRetryDelaySeconds: 30,
    retriableStatusCodes: [429, 503],
    retriableURLErrorCodes: [.timedOut],
    retriableMethods: [.post]
)
```

Only enable write retries when the backend enforces idempotency, for example through an `Idempotency-Key` header.

只有当后端具备幂等保护时才开启写操作重试，例如通过 `Idempotency-Key` Header。

## 2. Create An API Client / 创建 API Client

```swift
let apiClient = APIClient(
    baseURL: URL(string: "https://api.example.com")!,
    pathPrefix: "/api/v1",
    httpClient: transport
)
```

The client joins `baseURL.path`, `pathPrefix`, and request `path` safely.

Client 会安全拼接 `baseURL.path`、`pathPrefix` 与请求 `path`。

## 3. Define Requests / 定义请求

```swift
struct Profile: Decodable, Sendable {
    let id: String
    let displayName: String
}

let request = JSONAPIRequest<Profile, EmptyRequestBody>(
    method: .get,
    path: "/profiles/me"
)

let profile = try await apiClient.send(request)
```

For JSON bodies:

对于 JSON 请求体：

```swift
struct UpdateProfileRequest: Encodable, Sendable {
    let displayName: String
}

let request = JSONAPIRequest<Profile, UpdateProfileRequest>(
    method: .patch,
    path: "/profiles/me",
    body: UpdateProfileRequest(displayName: "Alex")
)
```

## 4. Add Authorization / 添加授权

```swift
let headersProvider = BearerTokenHeadersProvider {
    try await sessionStore.currentAccessToken()
}

let apiClient = APIClient(
    baseURL: URL(string: "https://api.example.com")!,
    pathPrefix: "/api/v1",
    headersProvider: headersProvider
)
```

The token provider must not print, cache, or expose the token outside secure runtime boundaries.

Token provider 不应打印、缓存或在安全运行边界之外暴露 token。

## 5. Handle Errors / 处理错误

```swift
do {
    let profile = try await apiClient.send(request)
} catch let error as APIClientError {
    showToast(error.localizedDescription)
}
```

For non-2xx responses, `APIClientError.unacceptableStatusCode` only uses backend `public_message`. Internal fields such as `message`, `error`, stack traces, SQL details, and raw response bodies are ignored.

对于非 2xx 响应，`APIClientError.unacceptableStatusCode` 只使用后端 `public_message`。内部字段如 `message`、`error`、堆栈、SQL 细节、原始响应体都会被忽略。

## 6. Logging / 日志

`NetworkEventLogger` receives sanitized retry events only:

`NetworkEventLogger` 只接收已脱敏的重试事件：

```swift
struct AppNetworkLogger: NetworkEventLogger {
    func log(_ event: NetworkLogEvent) {
        appLogger.info("network retry status=\(event.statusCode ?? -1) path=\(event.path ?? "-")")
    }
}
```

Do not enrich log events with request headers, query strings, request bodies, response bodies, cookies, or tokens.

不要向日志事件追加 Header、query、请求体、响应体、cookie 或 token。
