# Backend Contract / 后端契约

## Success Responses / 成功响应

NetworkForIOS expects successful responses to match the app-defined `Decodable` response type.

NetworkForIOS 期望成功响应能够匹配 App 自己定义的 `Decodable` 响应类型。

```json
{
  "id": "event-123",
  "title": "Coffee Meetup"
}
```

Use `EmptyResponse` for `204 No Content` or other successful responses without a body.

对于 `204 No Content` 或其他无响应体成功结果，使用 `EmptyResponse`。

## Error Responses / 错误响应

Backends should expose user-safe copy through `public_message`.

后端应通过 `public_message` 暴露可展示给用户的安全文案。

```json
{
  "code": "rate_limited",
  "public_message": "Please try again later."
}
```

The default decoder intentionally ignores raw `message`, `error`, stack traces, SQL errors, upstream vendor payloads, and response bodies that do not contain `public_message`.

默认解码器会有意忽略原始 `message`、`error`、堆栈、SQL 错误、上游厂商 payload，以及不包含 `public_message` 的响应体。

## Retry Contract / 重试契约

For rate limiting or temporary overload, the backend may return `Retry-After`.

对于限流或临时过载，后端可以返回 `Retry-After`。

Supported formats:

支持格式：

1. Seconds, such as `3`.
2. RFC 1123 HTTP date, such as `Wed, 21 Oct 2015 07:28:00 GMT`.

The client caps retry delay with `maximumRetryDelaySeconds`, so very large `Retry-After` values will not block the app indefinitely.

Client 会通过 `maximumRetryDelaySeconds` 限制重试等待时间，因此过大的 `Retry-After` 不会让 App 无限等待。

By default, automatic retries apply only to `GET`, `HEAD`, and `OPTIONS`.

默认情况下，自动重试只作用于 `GET`、`HEAD`、`OPTIONS`。

If a backend requires retry support for write endpoints, it should provide an idempotency mechanism.

如果后端要求写接口支持重试，应提供幂等机制。

Recommended write retry header:

推荐写操作重试 Header：

```http
Idempotency-Key: <client-generated-unique-key>
```

The backend should treat duplicate requests with the same idempotency key as the same operation.

后端应将相同 idempotency key 的重复请求视为同一次操作。

## Auth Contract / 认证契约

NetworkForIOS only injects headers. It does not refresh sessions or persist credentials.

NetworkForIOS 只注入 Header，不刷新会话，也不持久化凭据。

Recommended authorization header:

推荐授权 Header：

```http
Authorization: Bearer <access-token>
```

Token refresh, logout, revocation, session invalidation, and Keychain storage should stay in the app's auth module.

Token 刷新、退出登录、撤销、会话失效与 Keychain 存储应留在 App 的登录模块。
