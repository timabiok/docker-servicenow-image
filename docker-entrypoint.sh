#!/bin/bash
set -euo pipefail

# Run install script if required env vars are set (S3 install)
if [[ -n "${BUCKET:-}" && -n "${KEY:-}" ]]; then
    echo "Running ServiceNow install from s3://${BUCKET}/${KEY} ..."
    /app/install.sh
    echo "Install completed."
else
    echo "BUCKET/KEY not set; skipping install (assuming pre-installed /glide/nodes)."
fi

# Start the requested node (foreground)
NODE_DIR="/glide/nodes/sn_${NODE_PORT:-8443}"
if [[ ! -x "${NODE_DIR}/startup.sh" ]]; then
    echo "Error: ${NODE_DIR}/startup.sh not found or not executable. Check BUCKET/KEY and install." >&2
    exit 1
fi

echo "Starting ServiceNow node on port ${NODE_PORT:-8443} ..."
exec "${NODE_DIR}/startup.sh"
