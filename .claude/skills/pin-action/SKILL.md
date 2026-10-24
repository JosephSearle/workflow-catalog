---
name: pin-action
description: Pin a third-party GitHub Action to a full commit SHA with a version comment, check it against the repo's allowlist and Dependabot cooldown, and sync templates/. Use when adding or upgrading a third-party `uses:` in a workflow, action or template.
argument-hint: <owner/repo[/path]>@<vX.Y.Z>
allowed-tools: Read, Grep, Edit, Bash(gh api repos/*/commits/*), Bash(gh api repos/*/git/ref/*), Bash(gh api repos/*/releases/*), Bash(make template-pins), Bash(make sync-template-pins)
---

# Pin an action

The target is `$ARGUMENTS`, e.g. `actions/checkout@v7.0.1`. Split it into `<owner>/<repo>`, an optional sub-path and `<tag>`. If no exact `vX.Y.Z` tag is given, find the latest release with `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name` and confirm it with the user.

## 1. Resolve the SHA

```sh
gh api repos/<owner>/<repo>/commits/<tag> --jq .sha
```

This dereferences annotated tags to the commit. The result must be 40 hex characters.

## 2. Check policy

- **Allowlist.** Repo settings only allow actions created by GitHub, actions by Marketplace verified creators, and the allowlist in [docs/security.md](../../../docs/security.md) under "Actions → General". If the action doesn't fit any of these, warn the user that it will fail in CI until the allowlist and that doc are updated.
- **Cooldown.** Get the release date with `gh api repos/<owner>/<repo>/releases/tags/<tag> --jq .published_at`. If it's less than 7 days old, warn that Dependabot uses a 7-day cooldown and suggest the previous release.
- **Consistency.** Grep `.github/workflows/` and `actions/` for other pins of the same action. If they use a different SHA, ask whether to update them all to the same SHA, because `scripts/template-pins.sh` can't sync templates while live pins disagree.

## 3. Write it

Use this exact form, keeping the existing quoting and indentation:

```yaml
uses: <owner>/<repo>[/path]@<sha> # <tag>
```

Then run `make template-pins`. If it reports drift, run `make sync-template-pins`.
