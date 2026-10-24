# Azure Container Apps setup

One-time setup for deploying to an Azure Container App with the [azure-container-app-deploy](../.github/workflows/azure-container-app-deploy.yml) workflow or the [deploy-container-app](../actions/deploy-container-app/) action. The same steps set up the catalog's own `catalog-sandbox`, which the live tests deploy to on push to `main`, and a consumer repo's `production` app.

GitHub logs in to Azure with OIDC, so there's no client secret to store or rotate. The app pulls from Azure Container Registry with its own managed identity, so there's no registry password either.

You need the `az` CLI logged in to the target subscription as Owner (or Contributor plus User Access Administrator), because the steps assign roles, and `gh` logged in with admin on the repo.

## 1. Variables

```sh
LOCATION=uksouth
RG=rg-catalog-sandbox
ACR=catalogsandboxacr        # Globally unique, letters and digits only
CAE=cae-catalog-sandbox      # Container Apps environment
APP=ca-catalog-sandbox
REPO=JosephSearle/workflow-catalog
GH_ENV=catalog-sandbox       # GitHub environment that may deploy
```

## 2. Registry, environment and app

```sh
az group create --name "$RG" --location "$LOCATION"
az acr create --resource-group "$RG" --name "$ACR" --sku Basic --admin-enabled false

# Also creates a Log Analytics workspace for the app's logs.
az containerapp env create --resource-group "$RG" --name "$CAE" --location "$LOCATION"

# Start from the public quickstart image. The first deploy replaces it.
az containerapp create --resource-group "$RG" --name "$APP" --environment "$CAE" \
  --image mcr.microsoft.com/k8se/quickstart:latest \
  --ingress external --target-port 80 \
  --min-replicas 0 --max-replicas 1 \
  --revisions-mode single \
  --system-assigned
```

`--target-port` must match the port your image listens on. The catalog sandbox uses 80, because the Microsoft sample images its live tests deploy listen there.

Let the app pull from the registry with its managed identity:

```sh
APP_PRINCIPAL=$(az containerapp show --resource-group "$RG" --name "$APP" --query identity.principalId --output tsv)
ACR_ID=$(az acr show --name "$ACR" --query id --output tsv)
az role assignment create --assignee-object-id "$APP_PRINCIPAL" --assignee-principal-type ServicePrincipal \
  --role AcrPull --scope "$ACR_ID"
az containerapp registry set --resource-group "$RG" --name "$APP" --server "$ACR.azurecr.io" --identity system
```

## 3. Deploy identity for GitHub

Create an app registration and service principal, then trust GitHub's OIDC tokens for one GitHub environment. Calls from catalog reusable workflows work the same way: the token's subject is the **caller's** repo and environment.

```sh
CLIENT_ID=$(az ad app create --display-name "github-$GH_ENV-deploy" --query appId --output tsv)
SP_ID=$(az ad sp create --id "$CLIENT_ID" --query id --output tsv)

az ad app federated-credential create --id "$CLIENT_ID" --parameters "{
  \"name\": \"$GH_ENV\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:$REPO:environment:$GH_ENV\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}"
```

Give it the least privilege: it can write this one app and push to this one registry.

```sh
APP_ID=$(az containerapp show --resource-group "$RG" --name "$APP" --query id --output tsv)
az role assignment create --assignee-object-id "$SP_ID" --assignee-principal-type ServicePrincipal \
  --role Contributor --scope "$APP_ID"
az role assignment create --assignee-object-id "$SP_ID" --assignee-principal-type ServicePrincipal \
  --role AcrPush --scope "$ACR_ID"
```

If a deploy fails with `does not have authorization to perform action 'Microsoft.App/managedEnvironments/join/action'`, grant only that action, on the environment only. A custom role's assignable scope can't be a single resource, so the role is defined at the resource group and assigned at the environment. Role names are unique per tenant, so the name includes the GitHub environment.

```sh
RG_ID=$(az group show --name "$RG" --query id --output tsv)
CAE_ID=$(az containerapp env show --resource-group "$RG" --name "$CAE" --query id --output tsv)
az role definition create --role-definition "{
  \"Name\": \"Container Apps Environment Joiner ($GH_ENV)\",
  \"Actions\": [\"Microsoft.App/managedEnvironments/join/action\", \"Microsoft.App/managedEnvironments/read\"],
  \"AssignableScopes\": [\"$RG_ID\"]
}"
az role assignment create --assignee-object-id "$SP_ID" --assignee-principal-type ServicePrincipal \
  --role "Container Apps Environment Joiner ($GH_ENV)" --scope "$CAE_ID"
```

## 4. GitHub environment

Create the environment, and allow only `main` to deploy from it. The federated credential trusts any run in this environment, whatever its branch, so this policy is what stops PR branches getting an Azure token. Use a custom branch policy rather than "protected branches": that option allows every branch when no classic branch protection rule exists, and this repo protects `main` with a ruleset.

```sh
gh api -X PUT "repos/$REPO/environments/$GH_ENV" --input - <<'EOF'
{"deployment_branch_policy": {"protected_branches": false, "custom_branch_policies": true}}
EOF
gh api -X POST "repos/$REPO/environments/$GH_ENV/deployment-branch-policies" -f name=main -f type=branch

gh secret set AZURE_CLIENT_ID --repo "$REPO" --env "$GH_ENV" --body "$CLIENT_ID"
gh secret set AZURE_TENANT_ID --repo "$REPO" --env "$GH_ENV" --body "$(az account show --query tenantId --output tsv)"
gh secret set AZURE_SUBSCRIPTION_ID --repo "$REPO" --env "$GH_ENV" --body "$(az account show --query id --output tsv)"
```

For a `production` environment in a consumer repo, also add required reviewers in **Settings → Environments**.

The catalog's live tests also read three repo variables, and stay skipped until they're set:

```sh
gh variable set AZURE_SANDBOX_RESOURCE_GROUP --repo "$REPO" --body "$RG"
gh variable set AZURE_SANDBOX_CONTAINER_APP --repo "$REPO" --body "$APP"
gh variable set AZURE_SANDBOX_REGISTRY --repo "$REPO" --body "$ACR.azurecr.io"
```

## 5. Deploy on release

The [caller example](../examples/callers/azure-container-app-deploy.yml) runs the deploy as a job in the repo's release-please workflow, gated on `release_created`, and passes `tag_name` as `image-tags`. It runs on the `main` push that merges the release PR, so it matches the federated credential and the `main`-only branch policy.

Don't use a separate workflow triggered by `release` or tag events. Releases created with `GITHUB_TOKEN` don't trigger workflows, and a tag ref fails the branch policy.

In a monorepo using release-please's manifest mode, gate each app's deploy job on its own path's output, e.g. `needs.release-please.outputs['apps/api--release_created']`, and pass `apps/api--tag_name`.

## 6. Cost

With `--min-replicas 0`, the sandbox app costs close to nothing when idle. ACR Basic is the main fixed cost, plus a little Log Analytics ingestion. To remove everything:

```sh
az group delete --name "$RG"
az ad app delete --id "$CLIENT_ID"
# Only if you created the custom role in step 3:
az role definition delete --name "Container Apps Environment Joiner ($GH_ENV)"
```
