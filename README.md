# docker-servicenow-image

Production Docker image for ServiceNow nodes, built from `install.sh`. Pushed to **Amazon ECR** for use in ECS, EKS, or Lambda-style workloads.

## Prerequisites

- Docker
- AWS CLI configured (credentials with ECR push permission)
- ECR repository created (see below)

## One-time: Create ECR repository

```bash
AWS_REGION=us-east-1
aws ecr create-repository --repository-name servicenow --region "$AWS_REGION"
# Note the repositoryUri from the output, e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/servicenow
```

## Build and push to ECR

Set your ECR URI and optionally region/tag, then run:

```bash
export ECR_URI=123456789012.dkr.ecr.us-east-1.amazonaws.com/servicenow
export AWS_REGION=us-east-1   # optional, default us-east-1

./build-push-ecr.sh           # pushes as :latest
./build-push-ecr.sh v1.0.0    # pushes as :v1.0.0
```

Or in one line:

```bash
ECR_URI=123456789012.dkr.ecr.us-east-1.amazonaws.com/servicenow ./build-push-ecr.sh v1.0.0
```

## Runtime environment variables

When running the container (e.g. in ECS task definition), set:

| Variable        | Required | Description |
|----------------|----------|-------------|
| `BUCKET`       | Yes*     | S3 bucket containing the ServiceNow zip |
| `KEY`          | Yes*     | S3 key of the zip (e.g. `artifacts/sn.zip`) |
| `JSON_PORTS`   | Yes      | JSON array of ports, e.g. `"[8443,9443]"` |
| `NODE_PORT`    | No       | Which node to start (default `8443`; use `9443` for worker) |
| `JAVA_INSTALLER` | No    | Override Java package (default `java-11-amazon-corretto-devel`) |

\* If `BUCKET` and `KEY` are not set, the entrypoint skips install and starts the node under `/glide/nodes` (for pre-baked images).

## Run locally (after push)

```bash
# Ensure AWS auth for ECR pull
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com

docker run -e BUCKET=my-bucket -e KEY=path/sn.zip -e JSON_PORTS='[8443,9443]' -e NODE_PORT=8443 \
  -p 8443:8443 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/servicenow:latest
```

## Files

- **Dockerfile** – Amazon Linux 2 base, installs deps + Java, runs `install.sh` at container start via entrypoint.
- **docker-entrypoint.sh** – Runs `install.sh` when `BUCKET`/`KEY` are set, then starts the chosen node’s `startup.sh` in the foreground.
- **build-push-ecr.sh** – Builds the image and pushes it to ECR (requires `ECR_URI`).
