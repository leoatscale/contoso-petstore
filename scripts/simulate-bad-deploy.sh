#!/bin/bash
# =============================================================================
# Simulate a bad deployment to trigger SRE auto-rollback
#
# What this does:
#   1. Deploys a "broken" version (nginx returning 500s) to petstore namespace
#   2. The SRE health check in the pipeline will detect high error rate
#   3. Auto-rollback kicks in and restores the previous version
#
# Usage: ./scripts/simulate-bad-deploy.sh
# =============================================================================

set -euo pipefail

NAMESPACE="petstore"
DEPLOYMENT="petstore-api"

echo "============================================"
echo "  🔥 Simulating Bad Deployment"
echo "============================================"
echo ""

# Save current image for manual recovery if needed
CURRENT_IMAGE=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE \
    -o jsonpath='{.spec.template.spec.containers[0].image}')
echo "📦 Current image (safe): $CURRENT_IMAGE"
echo "   Save this in case you need manual recovery."
echo ""

# Deploy a broken image (nginx configured to return 500)
echo "🚀 Deploying broken image..."
kubectl set image deployment/$DEPLOYMENT \
    $DEPLOYMENT=nginx:alpine \
    -n $NAMESPACE

kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE --timeout=120s

echo ""
echo "✅ Broken version deployed!"
echo ""
echo "What happens next:"
echo "  1. The nginx container will respond with 404 (no /api/pets route)"
echo "  2. App Insights will see error rate spike"
echo "  3. If pipeline is running, SRE job will detect and rollback"
echo ""
echo "To manually restore:"
echo "  kubectl set image deployment/$DEPLOYMENT $DEPLOYMENT=$CURRENT_IMAGE -n $NAMESPACE"
echo ""
echo "To trigger the pipeline (which will auto-rollback):"
echo "  git commit --allow-empty -m 'ci: test rollback' && git push"
