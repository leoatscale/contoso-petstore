# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do NOT** open a public issue
2. Use GitHub's **Private Vulnerability Reporting** (Security tab > Report a vulnerability)
3. Include steps to reproduce the issue

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | ✅        |

## Security Measures

This project uses:
- **GitHub CodeQL** for static analysis (SAST)
- **Secret Scanning** with push protection
- **Dependency Review** on all pull requests
- **Trivy** for container image scanning
- **Non-root containers** in production
