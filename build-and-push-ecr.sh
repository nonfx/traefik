#!/bin/bash

# Traefik Docker Build and Push to ECR Script
set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
AWS_REGION=${AWS_REGION:-"ap-southeast-1"}
ECR_REPOSITORY="traefik"
VERSION_TAG="v3.6.7"
STABLE_TAG="main-stable"

echo "🔍 Getting AWS Account ID using STS..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Error: Failed to get AWS Account ID using STS"
    exit 1
fi

echo "✅ AWS Account ID: ${AWS_ACCOUNT_ID}"

echo "🔐 Logging into AWS ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "🏗️  Building and pushing multi-architecture Traefik image with tag ${VERSION_TAG}..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${VERSION_TAG} \
  --push \
  -f "${SCRIPT_DIR}/Dockerfile" \
  "${SCRIPT_DIR}/"

echo "🏗️  Building and pushing multi-architecture Traefik image with tag ${STABLE_TAG}..."
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${STABLE_TAG} \
  --push \
  -f "${SCRIPT_DIR}/Dockerfile" \
  "${SCRIPT_DIR}/"

echo "✅ Successfully pushed Traefik images to ECR:"
echo "   📦 ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${VERSION_TAG}"
echo "   📦 ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${STABLE_TAG}"


echo "🔍 Inspecting the Traefik image to see if it's multi-arch..."
docker manifest inspect ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${VERSION_TAG}
docker manifest inspect ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${STABLE_TAG}

