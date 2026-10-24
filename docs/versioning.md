# Versioning and releases

## Policy

- One version for the whole repo, using semantic versioning.
- **Major:** an input, output or secret is removed or renamed, a workflow or action file is renamed or removed, a default changes behaviour, or required caller permissions increase.
- **Minor:** a new workflow, action, optional input or output.
- **Patch:** fixes and dependency bumps with no contract change.
- Before `v1.0.0`, breaking changes bump the minor version. Cut `v1.0.0` once the first public workflow is stable.

## How a release happens

1. PRs are squash-merged with Conventional Commit titles.
2. `_release.yml` runs release-please on every push to `main`. It keeps one release PR open with the next version and changelog.
3. Merging the release PR tags `vX.Y.Z`, publishes a GitHub release and updates `CHANGELOG.md`.
4. From `v1.0.0` on, the same workflow moves `vX` to the release commit. There's no `v0` tag, because before 1.0.0 breaking changes ship as minor releases.

`vX.Y.Z` releases are immutable once published. `vX` is a plain tag that only the release app can move.

## Deprecation

1. Mark the input, workflow or action as deprecated in its description and README.
2. Print `::warning::<thing> is deprecated and will be removed in vN. Use <replacement>.` when it's used.
3. Keep it working for the rest of the current major.
4. Remove it in the next major, listed under the release's breaking changes.

## Release app setup

release-please has to create its PR with an app token. PRs created with `GITHUB_TOKEN` don't trigger workflows, so `ci-ok` would never run on them.

1. Create a GitHub App owned by your account. Repository permissions: Contents read/write, Pull requests read/write, Issues read/write. No webhook.
2. Install it on `workflow-catalog` only.
3. Add repository variable `RELEASE_APP_CLIENT_ID` and secret `RELEASE_APP_PRIVATE_KEY`.
4. Add the app as a bypass actor on the tag ruleset (see [security.md](security.md)).
