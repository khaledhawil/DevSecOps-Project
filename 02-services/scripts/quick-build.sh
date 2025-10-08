#!/bin/bash

################################################################################
# Quick Build - Build All Services Without Push
################################################################################
#
# Purpose: Quick local build of all services for testing
#
# Usage: ./quick-build.sh [tag]
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG=${1:-latest}

echo "========================================="
echo "Quick Build - All Services"
echo "Tag: ${TAG}"
echo "========================================="
echo ""

"${SCRIPT_DIR}/build-and-push.sh" --tag "${TAG}" --no-push

echo ""
echo "✅ Local build complete!"
echo "Images tagged as: khaledhawil/*:${TAG}"
