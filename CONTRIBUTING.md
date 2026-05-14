# Contributing / 贡献指南

Thank you for considering a contribution.

感谢你考虑参与贡献。

## Goals / 目标

NetworkForIOS should stay small, app-neutral, and safe by default.

NetworkForIOS 应保持小型、与 App 无关，并默认安全。

Accepted contribution areas:

可接受贡献方向：

1. Transport reliability improvements.
2. Typed API request ergonomics.
3. Safer error handling.
4. Tests.
5. Documentation.

Avoid adding:

避免加入：

1. App-specific DTOs or repositories.
2. Login UI or session refresh state machines.
3. Analytics SDKs.
4. Vendor-specific upload clients.
5. Logging of headers, query strings, request bodies, response bodies, tokens, cookies, or PII.
6. Default retries for write methods without idempotency protection.

## Development / 开发

```bash
swift test
```

## Pull Request Checklist / PR 清单

Before opening a pull request:

提交 PR 前：

1. Run `swift test`.
2. Add or update tests for behavior changes.
3. Keep public APIs documented in README or Docs.
4. Confirm no secrets, private URLs, personal data, tokens, or credentials are included.
5. Confirm error handling does not expose raw backend `message`, stack traces, SQL details, or response bodies to users.
6. Confirm retry changes do not enable write retries by default.

## Privacy Rule / 隐私规则

Use placeholder values such as `https://api.example.com` in tests and docs. Do not commit real project identifiers, backend hosts, phone numbers, emails, device IDs, tokens, or cookies.

测试和文档中使用 `https://api.example.com` 等占位值。不要提交真实项目标识、后端域名、手机号、邮箱、设备 ID、token 或 cookie。
