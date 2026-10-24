#!/usr/bin/env bash
# Updates an Azure Container App to IMAGE, waits for the new revision to be
# provisioned and healthy, then optionally GETs HEALTH_CHECK_PATH on that
# revision over HTTPS. Writes result=deployed|unhealthy|invalid-input|error,
# and exits non-zero unless deployed. Expects az to be logged in already
# (azure/login).
set -euo pipefail

result=""
# Anything that exits before a result is set counts as an error, so the
# result output is always set.
trap 'if [ -z "$result" ]; then echo "result=error" >> "$GITHUB_OUTPUT"; fi' EXIT

fail() {
  echo "::error::$2"
  result="$1"
  echo "result=$1" >> "$GITHUB_OUTPUT"
  exit 1
}

# Inputs first, so bad inputs fail the same way with or without Azure.
if [ -z "$RESOURCE_GROUP" ]; then
  fail invalid-input "resource-group is required."
fi
if [ -z "$CONTAINER_APP" ]; then
  fail invalid-input "container-app is required."
fi
if [ -z "$IMAGE" ]; then
  fail invalid-input "image is required."
fi
# No leading zeros: bash arithmetic would read them as octal.
case "$WAIT_TIMEOUT_SECONDS" in
  '' | *[!0-9]* | 0?*) fail invalid-input "wait-timeout-seconds must be a whole number of seconds, got '$WAIT_TIMEOUT_SECONDS'." ;;
esac
if [ -n "$HEALTH_CHECK_PATH" ] && [ "${HEALTH_CHECK_PATH#/}" = "$HEALTH_CHECK_PATH" ]; then
  fail invalid-input "health-check-path must start with '/', got '$HEALTH_CHECK_PATH'."
fi
case "$IMAGE" in
  *@sha256:*) ;;
  *) echo "::warning::image '$IMAGE' isn't pinned by digest, so the revision runs whatever the tag points to when it starts." ;;
esac

for tool in az jq curl; do
  if ! command -v "$tool" >/dev/null; then
    fail error "$tool isn't on PATH. deploy-container-app needs az, jq and curl, which ubuntu-latest ships."
  fi
done
if ! az account show --output none 2>/dev/null; then
  fail error "az isn't logged in. Run azure/login before this action."
fi

app_args=(--resource-group "$RESOURCE_GROUP" --name "$CONTAINER_APP")
if ! app="$(az containerapp show "${app_args[@]}" --output json)"; then
  fail error "Couldn't read Container App '$CONTAINER_APP' in resource group '$RESOURCE_GROUP'. Check both names and that the logged-in identity can read the app."
fi

previous="$(jq -r '.properties.latestReadyRevisionName // ""' <<<"$app")"
fqdn="$(jq -r '.properties.configuration.ingress.fqdn // ""' <<<"$app")"
external="$(jq -r '.properties.configuration.ingress.external // false' <<<"$app")"
min_replicas="$(jq -r '.properties.template.scale.minReplicas // 0' <<<"$app")"
url="${fqdn:+https://$fqdn}"
echo "previous-revision=$previous" >> "$GITHUB_OUTPUT"
echo "url=$url" >> "$GITHUB_OUTPUT"

# Check the inputs against the app before changing anything.
count="$(jq '.properties.template.containers // [] | length' <<<"$app")"
containers="$(jq -r '.properties.template.containers // [] | map(.name) | join(" ")' <<<"$app")"
if [ -z "$CONTAINER_NAME" ]; then
  if [ "$count" -ne 1 ]; then
    fail invalid-input "'$CONTAINER_APP' has $count containers (${containers:-none}), so container-name must say which to update."
  fi
  container="$containers"
elif jq -e --arg name "$CONTAINER_NAME" '.properties.template.containers // [] | any(.name == $name)' <<<"$app" >/dev/null; then
  container="$CONTAINER_NAME"
else
  fail invalid-input "'$CONTAINER_APP' has no container named '$CONTAINER_NAME'. Its containers: ${containers:-none}."
fi
if [ -n "$HEALTH_CHECK_PATH" ] && [ "$external" != true ]; then
  fail invalid-input "health-check-path needs external ingress, but '$CONTAINER_APP' has none, so the runner can't reach it."
fi

revision=""
show_diagnostics() {
  local rev
  rev="$(az containerapp revision show "${app_args[@]}" --revision "$revision" --output json 2>/dev/null || echo '{}')"
  echo "::group::Revision $revision"
  jq '.properties // {} | {provisioningState, provisioningError, runningState, runningStateDetails, healthState, replicas}' <<<"$rev" || true
  echo "::endgroup::"
  echo "::group::System logs for $revision"
  az containerapp logs show "${app_args[@]}" --revision "$revision" --type system --tail 50 --format text || true
  echo "::endgroup::"
}

echo "::group::az containerapp update ($container → $IMAGE)"
if ! updated="$(az containerapp update "${app_args[@]}" --container-name "$container" --image "$IMAGE" --output json)"; then
  echo "::endgroup::"
  # az fails the update when the new revision fails to provision. If a new
  # revision exists, that's an unhealthy deploy rather than a rejected one.
  latest="$(az containerapp show "${app_args[@]}" --query properties.latestRevisionName --output tsv 2>/dev/null || true)"
  if [ -n "$latest" ] && [ "$latest" != "$previous" ]; then
    revision="$latest"
    echo "revision=$revision" >> "$GITHUB_OUTPUT"
    show_diagnostics
    fail unhealthy "Revision '$revision' failed to provision. The previous revision '${previous:-none}' keeps serving in single revision mode."
  fi
  fail error "az containerapp update was rejected. Check the error above, and that the identity can write the app."
fi
echo "::endgroup::"
revision="$(jq -r '.properties.latestRevisionName // ""' <<<"$updated")"
if [ -z "$revision" ]; then
  fail error "az containerapp update didn't report a revision."
fi
echo "revision=$revision" >> "$GITHUB_OUTPUT"
if [ "$revision" = "$previous" ]; then
  echo "::notice::The app already ran this configuration, so no new revision was created. Checking '$revision' instead."
fi

# Poll until the revision is provisioned and healthy. Failures end the wait
# early. Unhealthy keeps polling, because probes can recover while the app
# starts.
deadline=$((SECONDS + 10#$WAIT_TIMEOUT_SECONDS))
while :; do
  rev="$(az containerapp revision show "${app_args[@]}" --revision "$revision" --output json 2>/dev/null || echo '{}')"
  provisioning="$(jq -r '.properties.provisioningState // ""' <<<"$rev")"
  running="$(jq -r '.properties.runningState // ""' <<<"$rev")"
  health="$(jq -r '.properties.healthState // ""' <<<"$rev")"
  replicas="$(jq -r '.properties.replicas // 0' <<<"$rev")"
  revision_fqdn="$(jq -r '.properties.fqdn // ""' <<<"$rev")"
  echo "$revision: provisioning=${provisioning:-?} running=${running:-?} health=${health:-?} replicas=$replicas"

  case "$provisioning/$running" in
    Failed/* | */Failed | */ActivationFailed)
      show_diagnostics
      fail unhealthy "Revision '$revision' failed. The previous revision '${previous:-none}' keeps serving in single revision mode."
      ;;
  esac
  if [ "$provisioning" = Provisioned ]; then
    if [ "$health" = Healthy ]; then
      break
    fi
    # Without health probes there's no health state, so a running replica
    # is the best signal.
    if { [ -z "$health" ] || [ "$health" = None ]; } && [ "$replicas" -gt 0 ] && [[ "$running" == Running* ]]; then
      break
    fi
    # An app that scales to zero may have no replica to report health. The
    # health check below starts one when it's set.
    if [ "$min_replicas" = 0 ] && [ "$replicas" = 0 ] && { [ -z "$health" ] || [ "$health" = None ]; }; then
      echo "::notice::'$revision' is provisioned and scaled to zero, so its health can't be checked here. Set health-check-path to start a replica and check it."
      break
    fi
  fi
  if [ "$SECONDS" -ge "$deadline" ]; then
    show_diagnostics
    fail unhealthy "Revision '$revision' wasn't healthy after ${WAIT_TIMEOUT_SECONDS}s (provisioning=${provisioning:-?}, health=${health:-?})."
  fi
  sleep 10
done

if [ -n "$HEALTH_CHECK_PATH" ]; then
  # Check the revision's own FQDN, so the check hits the new revision even
  # when the app's traffic still goes to an older one.
  target="https://${revision_fqdn:-$fqdn}$HEALTH_CHECK_PATH"
  echo "Checking $target"
  # Retries cover a cold start from zero replicas and DNS settling.
  if ! curl --fail --silent --show-error --output /dev/null --max-time 30 \
    --retry 10 --retry-delay 6 --retry-all-errors "$target"; then
    show_diagnostics
    fail unhealthy "GET $target didn't return 2xx."
  fi
fi

result=deployed
echo "result=deployed" >> "$GITHUB_OUTPUT"
echo "Deployed $IMAGE to $CONTAINER_APP as revision $revision${url:+ ($url)}."
