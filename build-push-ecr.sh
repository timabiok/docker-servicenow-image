#!/usr/bin/env bash
# Build the ServiceNow Docker image and push to Amazon ECR.
# Usage:
#   ./build-push-ecr.sh [IMAGE_TAG]
#   AWS_REGION=eu-west-1 ECR_URI=123456789.dkr.ecr.eu-west-1.amazonaws.com/my-repo ./build-push-ecr.sh v1.0.0
set -euo pipefail

ECR_URI="${ECR_URI:?Set ECR_URI (e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/servicenow)}"
AWS_REGION="${AWS_REGION:-us-east-1}"
IMAGE_TAG="${1:-latest}"
IMAGE_NAME="servicenow"

echo "Logging into ECR..."
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_URI%/*}"

echo "Building image..."
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" -f Dockerfile .

echo "Tagging for ECR..."
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_URI}:${IMAGE_TAG}"

echo "Pushing to ECR..."
docker push "${ECR_URI}:${IMAGE_TAG}"

echo "Done. Image: ${ECR_URI}:${IMAGE_TAG}"
