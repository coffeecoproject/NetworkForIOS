# Release Readiness / 发布审查

## Checklist / 清单

| Item | Status | 状态 |
| --- | --- | --- |
| SwiftPM package builds | Passed locally | 本地通过 |
| Unit tests | Passed locally | 本地通过 |
| No dependency on host apps | Passed | 通过 |
| No dependency on OpenAuthKit | Passed | 通过 |
| No app-specific DTOs | Passed | 通过 |
| No hardcoded backend URL | Passed | 通过 |
| No secrets or credentials | Passed | 通过 |
| No token/header/body logging | Passed | 通过 |
| Default write retries disabled | Passed | 通过 |
| Retry delay cap | Passed | 通过 |
| Bilingual README | Present | 已提供 |
| Bilingual docs | Present | 已提供 |
| LICENSE | MIT | MIT |
| CHANGELOG | Present | 已提供 |
| CONTRIBUTING | Present | 已提供 |
| SECURITY | Present | 已提供 |

## Local Verification / 本地验证

```bash
swift test
```

Latest local result:

最近一次本地结果：

```text
Executed 11 tests, with 0 failures.
```

Strict concurrency verification:

严格并发验证：

```bash
swift test --scratch-path /private/tmp/networkforios-governance-strict-test -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
```

Latest local result:

最近一次本地结果：

```text
Executed 11 tests, with 0 failures.
```

## Privacy Gate / 隐私门禁

The package must not include:

本包不得包含：

1. Real API hosts from private projects.
2. Access tokens or refresh tokens.
3. Verification codes.
4. Personal phone numbers or emails.
5. Device identifiers.
6. Raw response body logs.
7. Authorization or Cookie header logs.

## Security Gate / 安全门禁

Before release, confirm:

发布前确认：

1. Error display uses `public_message` only.
2. Production apps use HTTPS.
3. Header providers do not print or persist tokens.
4. Retry policy does not retry unsafe business operations unless backend idempotency is guaranteed.
5. Apps do not put secrets or PII in query strings.
6. `maximumRetryDelaySeconds` is set to a bounded value for custom retry policies.
