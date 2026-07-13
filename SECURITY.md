# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.2.x   | ✅        |
| < 1.2   | ❌        |

## Reporting a Vulnerability

If you discover a security vulnerability in Panevo, please report it privately:

- **GitHub**: use [private vulnerability reporting](https://github.com/bkrdmrcioglu/panevo/security/advisories/new) (preferred)
- **Email**: demirbaserkan1@gmail.com

Please do **not** open a public issue for security vulnerabilities.

You can expect an initial response within 72 hours. Once the issue is confirmed and fixed, a patched release will be published and the report will be credited (unless you prefer to stay anonymous).

## Scope Notes

Panevo requires the macOS **Accessibility permission** to move and resize other applications' windows — this is inherent to all window managers. Panevo:

- makes **no network connections**,
- collects **no data**,
- stores settings **locally only** (UserDefaults),
- ships **signed and notarized** by Apple.

Any behavior contradicting the above would be considered a security issue — please report it.
