# Releasing with release-please

[`release-please.yml`](../.github/workflows/release-please.yml) runs [release-please](https://github.com/googleapis/release-please) for any repo. It keeps one release PR open on the default branch. Merging that PR tags `vX.Y.Z`, publishes a GitHub release and updates `CHANGELOG.md`. The catalog releases itself the same way, from [`_release.yml`](../.github/workflows/_release.yml).

The workflow writes with a GitHub App token, never `GITHUB_TOKEN`. A PR created with `GITHUB_TOKEN` doesn't trigger workflows, so the release PR's required checks would never run.

## 1. Create the release app (once per account)

Skip this if the catalog's release app already exists. Reuse it for every repo.

1. Create a GitHub App owned by your account. Repository permissions: Contents read/write, Pull requests read/write, Issues read/write (for release labels). No webhook.
2. Note the app's **Client ID** and generate a **private key**.

Add the Workflows permission only if release-please must edit files under `.github/workflows/`, e.g. through `extra-files`. Most repos don't need it.

## 2. Give a repo access

1. In the app's installation settings, add the repo under **Only select repositories**. Install on the repos that release, not all of them.
2. Set the variable and secret on the repo. A personal account has no organization-level secrets, so each repo needs its own:

   ```sh
   REPO=JosephSearle/<repo>
   gh variable set RELEASE_APP_CLIENT_ID --repo "$REPO" --body "<client id>"
   gh secret set RELEASE_APP_PRIVATE_KEY --repo "$REPO" < path/to/private-key.pem
   ```

3. If the repo protects `v*` tags with a ruleset, add the app as a bypass actor, as the catalog does (see [security.md](security.md)).

If the repo limits which actions can run, allow `actions/create-github-app-token@*` and `googleapis/release-please-action@*`. A called workflow's actions are checked against the caller's policy.

The workflow scopes each token to the calling repo, so one repo's run can't write to another repo the app is installed on.

## 3. Add a config and manifest

At the repo root, `release-please-config.json`. This starter matches the catalog's own changelog sections. Set `release-type` to `node` (bumps `package.json`), `python` (bumps `pyproject.toml`) or `simple` (only `CHANGELOG.md` and the tag):

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "simple",
  "include-v-in-tag": true,
  "bump-minor-pre-major": true,
  "pull-request-title-pattern": "chore: release ${version}",
  "changelog-sections": [
    { "type": "feat", "section": "Added" },
    { "type": "fix", "section": "Fixed" },
    { "type": "perf", "section": "Changed" },
    { "type": "refactor", "section": "Changed" },
    { "type": "deps", "section": "Changed" },
    { "type": "revert", "section": "Removed" },
    { "type": "docs", "section": "Docs", "hidden": true },
    { "type": "chore", "section": "Chores", "hidden": true },
    { "type": "ci", "section": "CI", "hidden": true },
    { "type": "test", "section": "Tests", "hidden": true }
  ],
  "packages": {
    ".": {}
  }
}
```

And `.release-please-manifest.json` with the current version, or `0.0.0` for a repo that has never released:

```json
{
  ".": "0.0.0"
}
```

release-please has no way to extend a shared remote config, so each repo keeps its own copy.

## 4. Add the caller

Copy [examples/callers/release-please.yml](../examples/callers/release-please.yml) to `.github/workflows/` and pin it to a release. To check the config without the app, run it once with `dry-run: true`.

release-please builds the changelog from commit messages on the default branch. Squash-merge PRs and give them Conventional Commit titles (`feat:`, `fix:` and so on), and add a check that enforces them.

## Deploy on release

Add a job with `needs: release-please` and `if: needs.release-please.outputs.release-created == 'true'`, and pass `tag-name` on. [examples/callers/azure-container-app-deploy.yml](../examples/callers/azure-container-app-deploy.yml) does this. Don't use a separate workflow triggered by `release` or tag events: it won't fire for releases created with `GITHUB_TOKEN`, and a tag ref fails a `main`-only environment branch policy.

In a monorepo, the root-package outputs (`release-created`, `tag-name`, `version` and so on) only cover path `.`. Use `releases` instead, a JSON object keyed by package path:

```yaml
if: fromJSON(needs.release-please.outputs.releases)['apps/api'] != null
with:
  image-tags: ${{ fromJSON(needs.release-please.outputs.releases)['apps/api'].tag-name }}
```

## Floating major tag

`move-major-tag: true` creates or moves a plain `vN` tag to each root-package release from 1.0.0 on. Use it for repos that others pin by major version, like this catalog. Most app repos don't need it.
