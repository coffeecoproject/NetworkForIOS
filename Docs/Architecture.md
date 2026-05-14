# Architecture / 架构说明

## Boundary / 边界

NetworkForIOS owns generic request transport and typed API calling.

NetworkForIOS 只负责通用请求传输与类型化 API 调用。

It does not own:

它不负责：

1. Login UI or auth session lifecycle. / 登录 UI 或认证会话生命周期。
2. Business repositories or DTOs. / 业务 Repository 或 DTO。
3. Secure storage. / 安全存储。
4. Analytics or telemetry SDK integration. / 分析或埋点 SDK 集成。
5. Vendor-specific upload clients. / 厂商专用上传客户端。

## Layers / 分层

```text
App Feature
    |
    | JSONAPIRequest<Response, Body>
    v
APIClient
    |
    | URLRequest
    v
HTTPClient
    |
    v
URLSessionHTTPClient
```

## Header Injection / Header 注入

`RequestHeadersProvider` is async so apps can read tokens or runtime context before sending a request.

`RequestHeadersProvider` 是异步接口，因此 App 可以在请求发送前读取 token 或运行时上下文。

Provider headers are applied after default and request-local headers. This prevents request-local code from accidentally replacing centralized authorization headers.

Provider Header 会在默认 Header 与请求局部 Header 之后应用，避免单个请求误覆盖集中授权 Header。

## Retry Model / 重试模型

Retries are conservative by default.

默认重试策略是保守的。

`HTTPClientRetryPolicy.default` retries transient failures only for idempotent methods: `GET`, `HEAD`, and `OPTIONS`.

`HTTPClientRetryPolicy.default` 只会对幂等方法的临时失败进行重试：`GET`、`HEAD`、`OPTIONS`。

Write methods can be added to `retriableMethods`, but host apps should only do this when the backend provides idempotency protection.

写操作可以加入 `retriableMethods`，但宿主 App 只有在后端提供幂等保护时才应这样做。

All retry delays are capped by `maximumRetryDelaySeconds`, including values parsed from `Retry-After`.

所有重试等待时间都会被 `maximumRetryDelaySeconds` 限制，包括从 `Retry-After` 解析出来的值。

## Error Handling / 错误处理

`APIClient` separates transport, status validation, and decoding:

`APIClient` 将传输、状态校验与解码分离：

1. Transport errors are thrown by `HTTPClient`. / 传输错误由 `HTTPClient` 抛出。
2. Non-success status codes become `APIClientError.unacceptableStatusCode`. / 非成功状态码转为 `APIClientError.unacceptableStatusCode`。
3. User-facing messages come only from `public_message`. / 用户可见文案只来自 `public_message`。
4. Decoding failures never include the raw response body. / 解码失败不会携带原始响应体。

## Logging / 日志

The module emits no logs by default.

模块默认不输出日志。

When a `NetworkEventLogger` is provided, only sanitized retry events are emitted. Events include method, host, path, status code or URL error code, and attempt count. Events do not include query strings, headers, cookies, request bodies, response bodies, or credentials.

当提供 `NetworkEventLogger` 时，模块只输出已脱敏的重试事件。事件包含 method、host、path、状态码或 URL 错误码、尝试次数，不包含 query、Header、cookie、请求体、响应体或凭据。
