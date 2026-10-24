# Security policy

## Supported versions

Only the latest release of the current major version gets fixes. Older majors get fixes for critical issues for 3 months after the next major ships.

## Report a vulnerability

Report privately through [GitHub private vulnerability reporting](https://github.com/JosephSearle/workflow-catalog/security/advisories/new). Do not open a public issue.

Include the affected workflow or action, the version, and steps to reproduce. Expect an acknowledgement within 7 days.

## Scope

In scope: anything that lets a caller's secrets, tokens or code be exposed or modified through a catalog workflow or action, e.g. script injection, over-broad permissions or unpinned dependencies.

Out of scope: misconfiguration in a consumer repo that the catalog docs already warn against.
