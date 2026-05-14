# Changelog / 更新日志

All notable changes to this project will be documented in this file.

本文件记录项目后续版本的主要变化。

## 0.1.0 - 2026-05-14

Initial reusable networking package.

首个可复用网络模块版本。

### Added / 新增

1. `HTTPClient` transport abstraction.
2. `URLSessionHTTPClient` with timeout, conservative retry policy, retry method allow-list, maximum retry delay, and `Retry-After` support.
3. `APIClient` typed request pipeline.
4. `JSONAPIRequest`, `EmptyRequestBody`, and `EmptyResponse`.
5. Async `RequestHeadersProvider` and `BearerTokenHeadersProvider`.
6. Safe `public_message` error decoding.
7. Sanitized retry-event logging hook.
8. Unit tests and bilingual documentation.

### Security / 安全

1. Default retry applies only to idempotent methods: `GET`, `HEAD`, and `OPTIONS`.
2. Write retries require explicit opt-in through `retriableMethods`.
3. Retry delay is capped by `maximumRetryDelaySeconds`.
4. Test infrastructure passes strict concurrency checks.
