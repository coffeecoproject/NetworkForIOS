# NetworkForIOS

NetworkForIOS is a reusable Swift networking and API client module for iOS apps.

NetworkForIOS 是一套可复用的 iOS Swift 网络请求与 API Client 模块。

It provides a small, app-neutral runtime for building typed API clients without coupling to any host app, auth module, design system, backend vendor, or logging framework.

它提供一套轻量、与 App 无关的运行时能力，用于构建类型化 API Client，同时不绑定任何宿主 App、登录模块、设计系统、后端厂商或日志框架。

## What It Provides / 能力范围

1. `HTTPClient`: minimal async transport abstraction. / 最小化异步传输协议。
2. `URLSessionHTTPClient`: URLSession transport with timeout and retry policy. / 基于 URLSession 的超时与重试传输实现。
3. `HTTPClientRetryPolicy`: retry policy for methods, status codes, `URLError.Code`, and maximum delay. / 针对 HTTP 方法、状态码、`URLError.Code` 与最大等待时间的重试策略。
4. `APIClient`: typed request builder, sender, status validator, and decoder. / 类型化请求构造、发送、状态校验与解码。
5. `JSONAPIRequest`: reusable JSON request wrapper. / 可复用 JSON 请求封装。
6. `RequestHeadersProvider`: async header injection for auth, locale, app version, or trace IDs. / 用于认证、语言、版本、追踪 ID 的异步 Header 注入。
7. `BearerTokenHeadersProvider`: optional bearer-token header provider. / 可选 Bearer token Header 提供器。
8. `JSONAPIErrorResponseDecoder`: user-safe error message extraction from `public_message`. / 仅从 `public_message` 提取可展示错误文案。
9. `NetworkEventLogger`: sanitized retry-event logging hook. / 已脱敏的重试事件日志钩子。

## Installation / 安装

Add this package with Swift Package Manager:

通过 Swift Package Manager 添加本包：

```swift
.package(url: "https://github.com/coffeecoproject/NetworkForIOS.git", from: "0.1.0")
```

Then add `NetworkForIOS` to the app target.

然后把 `NetworkForIOS` 添加到 App target。

## Basic Usage / 基础用法

```swift
import NetworkForIOS

struct Event: Decodable, Sendable {
    let id: String
    let title: String
}

let client = APIClient(
    baseURL: URL(string: "https://api.example.com")!,
    pathPrefix: "/api/v1",
    httpClient: URLSessionHTTPClient()
)

let request = JSONAPIRequest<Event, EmptyRequestBody>(
    method: .get,
    path: "/events/123"
)

let event = try await client.send(request)
```

## Auth Integration / 登录模块接入

NetworkForIOS does not depend on an auth package. Apps can inject authorization through `RequestHeadersProvider`.

NetworkForIOS 不依赖任何登录包。App 可以通过 `RequestHeadersProvider` 注入授权 Header。

```swift
let headersProvider = BearerTokenHeadersProvider {
    try await sessionStore.currentAccessToken()
}

let client = APIClient(
    baseURL: URL(string: "https://api.example.com")!,
    pathPrefix: "/api/v1",
    headersProvider: headersProvider
)
```

If the app uses OpenAuthKit, keep refresh/session invalidation in OpenAuthKit and only pass the latest access token into NetworkForIOS.

如果 App 使用 OpenAuthKit，刷新与会话失效逻辑仍应留在 OpenAuthKit，NetworkForIOS 只接收最新 access token。

## Security Defaults / 安全默认值

1. Error responses only expose `public_message`; raw `message` and `error` fields are ignored. / 错误响应只展示 `public_message`，忽略原始 `message` 和 `error` 字段。
2. Retry logs do not include headers, query strings, request bodies, response bodies, tokens, or cookies. / 重试日志不包含 Header、query、请求体、响应体、token 或 cookie。
3. Only `http` and `https` base URLs are accepted by `APIClient`. / `APIClient` 只接受 `http` 与 `https` Base URL。
4. Header providers are applied last, so centralized auth headers cannot be accidentally overwritten by request-local headers. / Header Provider 最后应用，避免集中认证 Header 被单个请求误覆盖。
5. Default retry is limited to idempotent methods: `GET`, `HEAD`, and `OPTIONS`. / 默认重试只作用于幂等方法：`GET`、`HEAD`、`OPTIONS`。
6. Retrying write methods such as `POST`, `PUT`, `PATCH`, and `DELETE` requires explicit opt-in and backend idempotency protection. / `POST`、`PUT`、`PATCH`、`DELETE` 等写操作重试必须显式开启，并由后端幂等保护兜底。
7. Retry delay is capped by `maximumRetryDelaySeconds`. / 重试等待时间受 `maximumRetryDelaySeconds` 上限约束。
8. No persistent storage, Keychain access, analytics SDK, or device identifier collection is included. / 本包不包含持久化存储、Keychain、分析 SDK 或设备标识采集。

## Documentation / 文档

1. [Integration Guide / 接入指南](Docs/IntegrationGuide.md)
2. [Backend Contract / 后端契约](Docs/BackendContract.md)
3. [Architecture / 架构说明](Docs/Architecture.md)
4. [Privacy Review / 隐私审查](Docs/PrivacyReview.md)
5. [Release Readiness / 发布审查](Docs/ReleaseReadiness.md)
6. [Changelog / 更新日志](CHANGELOG.md)
7. [Contributing / 贡献指南](CONTRIBUTING.md)
8. [Security Policy / 安全策略](SECURITY.md)
9. [License / 授权协议](LICENSE)

## Non-Goals / 非目标

1. No app-specific repositories or DTOs. / 不包含具体 App 的 Repository 或 DTO。
2. No auth session refresh state machine. / 不包含登录会话刷新状态机。
3. No direct database client in iOS code. / iOS 端不直接连接数据库。
4. No upload-vendor-specific implementation such as OSS/S3. / 不包含 OSS/S3 等厂商上传实现。
5. No token, cookie, request body, response body, phone, email, or device identifier logging. / 不记录 token、cookie、请求体、响应体、手机号、邮箱或设备标识。
