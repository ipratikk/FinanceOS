# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in FinanceOS, please do **not** open a public issue. Instead, please report it responsibly by emailing:

**[ipratikgoel@gmail.com](mailto:ipratikgoel@gmail.com)**

Include the following information:

1. **Vulnerability description** — What is the issue?
2. **Location** — Which file(s) or component(s)?
3. **Severity** — Critical, high, medium, or low
4. **Reproduction steps** — How to trigger the vulnerability
5. **Impact** — What could an attacker do?
6. **Suggested fix** — If you have one

## Response Timeline

We will:

1. **Acknowledge receipt** within 24 hours
2. **Provide initial assessment** within 48 hours
3. **Keep you updated** on progress
4. **Work with you** to coordinate disclosure
5. **Release a fix** as soon as possible

## Security Considerations

### Data Handling

- FinanceOS processes sensitive financial data
- Bank credentials should never be stored in code
- User data should be encrypted at rest
- Passwords/tokens should use secure storage (Keychain on macOS)

### Code Security

We follow these practices:

- **Input validation** — Sanitize all user inputs and file paths
- **SQL injection prevention** — Use parameterized queries (GRDB handles this)
- **XSS prevention** — Not applicable (native app)
- **CSRF prevention** — Not applicable (no web forms)
- **Secure defaults** — HTTPS for any external connections
- **Dependency updates** — Regular updates for security patches

### Parser Security

Bank statement parsers must:

- Validate file structure before parsing
- Handle malformed files gracefully
- Avoid arbitrary code execution
- Sanitize cell values and dates
- Reject suspicious patterns

### Authentication & Authorization

- No hardcoded credentials
- Use macOS Keychain for sensitive data
- Validate file access permissions
- Implement proper error handling (don't leak sensitive info)

## Security in Development

### Pre-Commit Checks

- Code review before merge (all changes)
- Automated linting and testing
- No secrets in git history

### Dependencies

- Regularly update Swift packages
- Monitor security advisories
- Remove unused dependencies
- Use dependency scanning tools

### Testing

- Fuzz testing for parsers (malformed files)
- Input validation tests
- File permission tests
- Error handling tests

## Scope of Security Support

We provide security support for:

- Current version of FinanceOS (main branch)
- Last 2 previous minor versions (if applicable)

Once a new version is released, prior versions enter maintenance mode and receive security patches only for critical vulnerabilities.

## Third-Party Components

FinanceOS uses the following key dependencies:

- **SwiftUI** — Apple's native UI framework
- **GRDB** — SQLite database access
- **CodableCSV** — CSV parsing
- **CoreXLSX** — XLSX parsing

For vulnerabilities in third-party libraries, please report to the respective project maintainers.

## Security Best Practices for Users

If you're using FinanceOS:

1. **Keep macOS updated** — Use the latest OS version
2. **Protect your files** — Use FileVault encryption
3. **Secure bank access** — Use strong, unique passwords
4. **Review statement files** — Verify file sources before importing
5. **Report suspicious activity** — Contact your bank immediately

## Public Disclosure

Once a vulnerability is fixed and patched:

1. We will acknowledge the researcher (if desired)
2. We may include the fix in release notes
3. We will not disclose details for 90 days (unless publicly exploited sooner)

## Questions?

For security questions that aren't vulnerabilities, please email [ipratikgoel@gmail.com](mailto:ipratikgoel@gmail.com).

---

**Last Updated:** 2026-05-22  
**Policy Version:** 1.0
