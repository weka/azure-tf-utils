#!/usr/bin/env bash
#
# Create a fresh Azure service principal for the terraform-azure-weka CI and
# populate all GitHub secrets the workflow (.github/workflows/workflow.yaml) needs.
#
# Fixes failures like:
#   AADSTS7000222: The provided client secret keys for app '***' are expired.
#
# Usage:
#   ./ci/create-ci-service-principal.sh <SUBSCRIPTION_ID_OR_NAME> [options]
#
# Options:
#   --sp-name <name>     Service principal display name (default: github-ci-terraform-azure-weka)
#   --repo <owner/repo>  GitHub repo for secrets (default: weka/terraform-azure-weka)
#   --scope <scope>      RBAC scope (default: the whole subscription)
#   --role <role>        RBAC role (default: Contributor)
#   --no-github          Only create the SP and print creds; do not set GitHub secrets
#   -h, --help           Show this help
#
# Requirements:
#   - az CLI, gh CLI, jq installed and on PATH
#   - Azure: rights to register an app (Application Administrator) and to assign
#     roles on the subscription (Owner or User Access Administrator)
#   - GitHub: admin on the target repo (to set secrets)

set -euo pipefail

# ---- defaults ---------------------------------------------------------------
SP_NAME="github-ci-terraform-azure-weka"
REPO="weka/terraform-azure-weka"
ROLE="Contributor"
SCOPE=""
SET_GITHUB=1
SUBSCRIPTION=""

usage() { sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

# ---- parse args -------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sp-name)   SP_NAME="$2"; shift 2 ;;
    --repo)      REPO="$2"; shift 2 ;;
    --scope)     SCOPE="$2"; shift 2 ;;
    --role)      ROLE="$2"; shift 2 ;;
    --no-github) SET_GITHUB=0; shift ;;
    -h|--help)   usage 0 ;;
    -*)          echo "Unknown option: $1" >&2; usage 1 ;;
    *)
      if [[ -z "$SUBSCRIPTION" ]]; then SUBSCRIPTION="$1"; shift
      else echo "Unexpected argument: $1" >&2; usage 1; fi
      ;;
  esac
done

if [[ -z "$SUBSCRIPTION" ]]; then
  echo "ERROR: subscription id or name is required." >&2
  usage 1
fi

# ---- preflight --------------------------------------------------------------
for bin in az jq; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERROR: '$bin' not found on PATH." >&2; exit 1; }
done
if [[ "$SET_GITHUB" -eq 1 ]]; then
  command -v gh >/dev/null 2>&1 || { echo "ERROR: 'gh' not found on PATH (use --no-github to skip)." >&2; exit 1; }
fi

# ---- azure context ----------------------------------------------------------
echo ">> Ensuring Azure login..."
az account show >/dev/null 2>&1 || az login >/dev/null

echo ">> Selecting subscription: $SUBSCRIPTION"
az account set --subscription "$SUBSCRIPTION"

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
TENANT_ID="$(az account show --query tenantId -o tsv)"
SUB_NAME="$(az account show --query name -o tsv)"
[[ -z "$SCOPE" ]] && SCOPE="/subscriptions/$SUBSCRIPTION_ID"

echo "   Subscription: $SUB_NAME ($SUBSCRIPTION_ID)"
echo "   Tenant:       $TENANT_ID"
echo "   Role/Scope:   $ROLE @ $SCOPE"

# ---- create service principal ----------------------------------------------
echo ">> Creating service principal '$SP_NAME' (with client secret + role assignment)..."
SP_JSON="$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "$ROLE" \
  --scopes "$SCOPE")"

CLIENT_ID="$(echo "$SP_JSON"     | jq -r .appId)"
CLIENT_SECRET="$(echo "$SP_JSON" | jq -r .password)"

if [[ -z "$CLIENT_ID" || "$CLIENT_ID" == "null" ]]; then
  echo "ERROR: failed to create service principal." >&2
  echo "$SP_JSON" >&2
  exit 1
fi

echo "   App (clientId): $CLIENT_ID"

# ---- build azure/login creds blob -------------------------------------------
CREDS_JSON="$(jq -n \
  --arg cid "$CLIENT_ID" \
  --arg sec "$CLIENT_SECRET" \
  --arg sub "$SUBSCRIPTION_ID" \
  --arg ten "$TENANT_ID" \
  '{clientId:$cid, clientSecret:$sec, subscriptionId:$sub, tenantId:$ten}')"

# ---- set github secrets -----------------------------------------------------
if [[ "$SET_GITHUB" -eq 1 ]]; then
  echo ">> Setting GitHub secrets on $REPO..."
  # azure/login JSON blobs
  printf '%s' "$CREDS_JSON"      | gh secret set RND_AZURE_CREDENTIALS --repo "$REPO"
  printf '%s' "$CREDS_JSON"      | gh secret set AZURE_CREDENTIALS     --repo "$REPO"
  # individual fields used by the terraform deploy/destroy steps
  printf '%s' "$CLIENT_ID"       | gh secret set CLIENT_ID             --repo "$REPO"
  printf '%s' "$CLIENT_SECRET"   | gh secret set CLIENT_SECRET         --repo "$REPO"
  printf '%s' "$TENANT_ID"       | gh secret set TENANT_ID             --repo "$REPO"
  printf '%s' "$SUBSCRIPTION_ID" | gh secret set AZURE_SUBSCRIPTION_ID --repo "$REPO"
  echo "   Done. Secrets set: RND_AZURE_CREDENTIALS, AZURE_CREDENTIALS, CLIENT_ID, CLIENT_SECRET, TENANT_ID, AZURE_SUBSCRIPTION_ID"
else
  echo ">> --no-github set; not touching GitHub. Credentials JSON below:"
  echo "$CREDS_JSON"
fi

echo
echo ">> All set. Re-run the failed CI job with:"
echo "   gh run rerun <RUN_ID> --repo $REPO --failed"
