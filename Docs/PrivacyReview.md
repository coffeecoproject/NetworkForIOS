# Privacy Review / 隐私审查

## Scope / 范围

This review covers the reusable NetworkForIOS package.

本审查覆盖可复用的 NetworkForIOS 包。

## Data Collection / 数据采集

NetworkForIOS does not collect, persist, or transmit data by itself. It sends requests that the host app constructs.

NetworkForIOS 自身不采集、持久化或主动上传数据。它只发送宿主 App 构造的请求。

## Sensitive Data Handling / 敏感数据处理

| Area | Result | 结果 |
| --- | --- | --- |
| Token storage | Not included | 不包含 |
| Keychain access | Not included | 不包含 |
| Device ID collection | Not included | 不包含 |
| Analytics SDK | Not included | 不包含 |
| Cookie management | Not included beyond URLSession behavior | 除 URLSession 默认行为外不额外管理 |
| Request/response body logging | Not included | 不包含 |
| Header logging | Not included | 不包含 |
| Query-string logging | Not included | 不包含 |
| Automatic write retries | Disabled by default | 默认关闭 |

## Error Disclosure / 错误披露

The default error decoder only reads `public_message`. It ignores raw `message`, `error`, stack traces, SQL details, vendor responses, and full response bodies.

默认错误解码器只读取 `public_message`，忽略原始 `message`、`error`、堆栈、SQL 细节、厂商响应与完整响应体。

## Logging Baseline / 日志基线

Retry logs are opt-in and sanitized. They may include:

重试日志是可选的，并且已脱敏。可以包含：

1. HTTP method.
2. Host.
3. Path without query string.
4. Status code or URL error code.
5. Retry attempt count.

They must not include:

禁止包含：

1. Authorization header.
2. Cookie header.
3. Query string.
4. Request body.
5. Response body.
6. Access token, refresh token, verification code, phone, email, address, ID card, bank account, or device identifier.

## App Responsibilities / App 侧责任

Host apps must still review what they put into requests, headers, and query items.

宿主 App 仍需审查自己放入请求、Header 和 query 的数据。

Recommended controls:

建议控制项：

1. Keep credentials in Keychain or another secure storage boundary.
2. Use short-lived access tokens.
3. Keep refresh logic in an auth module.
4. Avoid placing PII or secrets in query strings.
5. Use HTTPS in production.
6. Enable write retries only with backend idempotency protection.

## Current Risk Assessment / 当前风险判断

No embedded secrets, app identifiers, backend private URLs, personal data, or project-specific credentials are present in this package.

本包未包含硬编码密钥、App 标识、后端私有 URL、个人数据或项目专用凭据。
