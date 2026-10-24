# deploy-container-app

Updates an Azure Container App to an image and waits for the new revision to be provisioned and healthy. With `health-check-path`, it also GETs that path on the new revision until it returns 2xx. If the revision fails or times out, the log shows its provisioning error and the last 50 system log lines.

The action doesn't log in. Run [`azure/login`](https://github.com/Azure/login) first, ideally with OIDC, so the deploy uses whatever identity your job chose. [docs/azure-container-apps.md](../../docs/azure-container-apps.md) sets up the app, the identity and its roles.

Pin the image by digest (`registry/name@sha256:…`) so the revision runs exactly what you built. A tag-only reference works, but gets a warning.

The [azure-container-app-deploy](../../.github/workflows/azure-container-app-deploy.yml) workflow is built on this action. It adds the image build and push.

## Usage

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: azure/login@<sha> # vX.Y.Z
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - id: deploy
        uses: JosephSearle/workflow-catalog/actions/deploy-container-app@<sha> # vX.Y.Z
        with:
          resource-group: rg-my-app
          container-app: ca-my-app
          image: myacr.azurecr.io/my-app@${{ needs.build.outputs.digest }}
          health-check-path: /healthz
```

To roll back, shift traffic to `steps.deploy.outputs.previous-revision`, or redeploy its image. In single revision mode, a revision that fails to provision never takes traffic, so the previous one keeps serving. In multiple revision mode, the action deploys and checks the new revision but doesn't move traffic to it. The health check uses the revision's own FQDN, so it always tests the new revision, whatever the traffic split.

## Inputs

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `resource-group` | yes | | Resource group of the Container App. |
| `container-app` | yes | | Name of the Container App. |
| `image` | yes | | Full image reference, ideally pinned by digest. |
| `container-name` | no | `""` | Container to update. Empty updates the app's only container, and fails when it has more than one. |
| `health-check-path` | no | `""` | Path starting with `/`. When set, `GET https://<fqdn><path>` must return 2xx, which needs external ingress. |
| `wait-timeout-seconds` | no | `"600"` | How long to wait for the revision to be provisioned and healthy. |

## Outputs

| Name | Description |
| --- | --- |
| `revision` | Revision now running the image. Empty if the update didn't happen. When the app already ran this exact configuration, no new revision is created, and this is the existing one. |
| `previous-revision` | Latest ready revision before the update. |
| `url` | `https://<fqdn>`, or empty when the app has no ingress. |
| `result` | `deployed`, `unhealthy` (revision failed, timed out or failed the health check), `invalid-input` (bad inputs, or inputs that don't match the app) or `error` (az not logged in, the app couldn't be read, or the update was rejected). Always set, even when the action fails. |

## Supported runners

`ubuntu-latest`, which ships `az`, `jq` and `curl`. Apps that scale to zero report no health until a replica starts. Set `health-check-path` to start one and check it.
