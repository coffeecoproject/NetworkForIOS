# Security Policy / 安全策略

## Supported Versions / 支持版本

| Version | Supported |
| --- | --- |
| 0.1.x | Yes |

## Reporting A Vulnerability / 报告安全问题

Please report vulnerabilities through GitHub private vulnerability reporting or a private maintainer channel.

请通过 GitHub 私有漏洞报告或维护者私有渠道报告安全问题。

Do not open a public issue with exploit details, secrets, tokens, private URLs, or personal data.

不要在公开 issue 中提交利用细节、密钥、token、私有 URL 或个人数据。

## Security Expectations / 安全预期

NetworkForIOS must not:

NetworkForIOS 不得：

1. Log authorization headers, cookies, tokens, request bodies, response bodies, or query strings.
2. Persist credentials.
3. Collect device identifiers.
4. Expose raw backend `message`, `error`, stack traces, SQL errors, or vendor payloads as user-facing copy.
5. Depend on host-app private modules.
6. Retry write methods by default.

## Retry Safety / 重试安全

Automatic retry is enabled by default only for idempotent methods: `GET`, `HEAD`, and `OPTIONS`.

默认自动重试只作用于幂等方法：`GET`、`HEAD`、`OPTIONS`。

Write retries must be explicitly configured and should be used only when the backend enforces idempotency.

写操作重试必须显式配置，并且只应在后端具备幂等保护时使用。

## Disclosure Handling / 披露处理

For confirmed vulnerabilities, maintainers should:

对于确认的漏洞，维护者应：

1. Reproduce the issue.
2. Patch the root cause.
3. Add regression tests.
4. Update release notes.
5. Publish a patched version.
