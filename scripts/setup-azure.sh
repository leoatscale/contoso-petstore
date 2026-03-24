#!/bin/bash
# =============================================================================
# Contoso Pet Store - Azure Infrastructure Setup
# Run this ONCE to create all Azure resources for the demo
# =============================================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
RESOURCE_GROUP="rg-petstore-demo"
LOCATION="eastus2"
ACR_NAME="contosopetstore$(openssl rand -hex 3)"    # Must be globally unique
AKS_CLUSTER="aks-petstore-demo"
APP_INSIGHTS="appi-petstore-demo"
LOG_ANALYTICS="log-petstore-demo"

echo "============================================"
echo " Contoso Pet Store - Infrastructure Setup"
echo "============================================"
echo ""
echo "Resource Group:    $RESOURCE_GROUP"
echo "Location:          $LOCATION"
echo "ACR:               $ACR_NAME"
echo "AKS:               $AKS_CLUSTER"
echo ""

# ── 1. Resource Group ────────────────────────────────────────────────────────
echo "▶ Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output none

# ── 2. Azure Container Registry ─────────────────────────────────────────────
echo "▶ Creating Azure Container Registry..."
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Standard \
    --admin-enabled false \
    --output none

# ── 3. Log Analytics Workspace (required for App Insights & AKS monitoring) ─
echo "▶ Creating Log Analytics Workspace..."
LOG_ANALYTICS_ID=$(az monitor log-analytics workspace create \
    --resource-group $RESOURCE_GROUP \
    --workspace-name $LOG_ANALYTICS \
    --location $LOCATION \
    --query id -o tsv)

# ── 4. Application Insights ─────────────────────────────────────────────────
echo "▶ Creating Application Insights..."
APPINSIGHTS_CONN=$(az monitor app-insights component create \
    --app $APP_INSIGHTS \
    --location $LOCATION \
    --resource-group $RESOURCE_GROUP \
    --workspace $LOG_ANALYTICS_ID \
    --application-type web \
    --query connectionString -o tsv)

echo "   App Insights Connection String saved."

# ── 5. AKS Cluster ──────────────────────────────────────────────────────────
echo "▶ Creating AKS Cluster (this takes ~5 minutes)..."
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER \
    --node-count 2 \
    --node-vm-size Standard_B2s \
    --enable-managed-identity \
    --attach-acr $ACR_NAME \
    --enable-addons monitoring \
    --workspace-resource-id $LOG_ANALYTICS_ID \
    --generate-ssh-keys \
    --output none

# ── 6. Get AKS Credentials ──────────────────────────────────────────────────
echo "▶ Fetching AKS credentials..."
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER \
    --overwrite-existing

# ── 7. Install NGINX Ingress Controller ──────────────────────────────────────
echo "▶ Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# ── 8. Create Kubernetes Secret for App Insights ─────────────────────────────
echo "▶ Creating K8s namespace and secrets..."
kubectl create namespace petstore --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic petstore-secrets \
    --namespace petstore \
    --from-literal=appinsights-connection-string="$APPINSIGHTS_CONN" \
    --dry-run=client -o yaml | kubectl apply -f -

# ── 9. Create Service Principal for GitHub Actions ───────────────────────────
echo "▶ Creating Service Principal for GitHub Actions..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

SP_JSON=$(az ad sp create-for-rbac \
    --name "sp-petstore-github" \
    --role contributor \
    --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
    --json-auth)

# ── 10. Summary ──────────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo " ✅ Infrastructure Created Successfully!"
echo "============================================"
echo ""
echo "📋 Add these to your GitHub Repository:"
echo ""
echo "── Secrets ──────────────────────────────"
echo "AZURE_CREDENTIALS:"
echo "$SP_JSON"
echo ""
echo "── Variables ─────────────────────────────"
echo "ACR_NAME=$ACR_NAME"
echo "AKS_CLUSTER=$AKS_CLUSTER"
echo "AKS_RG=$RESOURCE_GROUP"
echo ""
echo "── App Insights ─────────────────────────"
echo "Connection String: $APPINSIGHTS_CONN"
echo ""
echo "── Next Steps ───────────────────────────"
echo "1. Go to GitHub repo > Settings > Secrets and Variables > Actions"
echo "2. Add AZURE_CREDENTIALS as a Secret (JSON above)"
echo "3. Add ACR_NAME, AKS_CLUSTER, AKS_RG as Variables"
echo "4. Push code to trigger the pipeline!"
echo ""
echo "── Cleanup ──────────────────────────────"
echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"
