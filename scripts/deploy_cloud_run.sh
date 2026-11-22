#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${GOOGLE_CLOUD_PROJECT:?Set GOOGLE_CLOUD_PROJECT first}"
REGION="${GCP_REGION:-asia-south1}"
API_SERVICE="${FORGEMIND_API_SERVICE:-forgemind-api}"
WEB_SERVICE="${FORGEMIND_WEB_SERVICE:-forgemind-web}"

gcloud run deploy "$API_SERVICE" \
  --project "$PROJECT_ID" \
  --region "$REGION" \
  --source backend \
  --allow-unauthenticated \
  --cpu 1 \
  --memory 512Mi \
  --concurrency 20 \
  --timeout 60 \
  --min-instances 0 \
  --max-instances 1 \
  --set-env-vars 'DATABASE_URL=sqlite:////tmp/forgemind.db,AI_PROVIDER=local,RETRIEVAL_BACKEND=local,DOCUMENT_STORAGE_BACKEND=local' \
  --quiet

API_URL="$(gcloud run services describe "$API_SERVICE" --project "$PROJECT_ID" --region "$REGION" --format='value(status.url)')"
[[ "$API_URL" == https://* ]] || { echo "ForgeMind API URL unavailable" >&2; exit 2; }

gcloud run deploy "$WEB_SERVICE" \
  --project "$PROJECT_ID" \
  --region "$REGION" \
  --source frontend \
  --allow-unauthenticated \
  --cpu 1 \
  --memory 512Mi \
  --concurrency 40 \
  --timeout 60 \
  --min-instances 0 \
  --max-instances 1 \
  --set-env-vars "BACKEND_API_URL=$API_URL" \
  --quiet

gcloud run services describe "$WEB_SERVICE" \
  --project "$PROJECT_ID" \
  --region "$REGION" \
  --format='value(status.url)'
