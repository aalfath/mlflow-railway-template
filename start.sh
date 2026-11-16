#!/bin/sh
# Start the MLflow tracking server with the basic-auth app, sized for Railway.
set -eu

PORT="${PORT:-5000}"
MLFLOW_ADMIN_USERNAME="${MLFLOW_ADMIN_USERNAME:-admin}"
MLFLOW_ARTIFACTS_DIR="${MLFLOW_ARTIFACTS_DIR:-/mlartifacts}"
MLFLOW_WORKERS="${MLFLOW_WORKERS:-2}"
MLFLOW_DEFAULT_PERMISSION="${MLFLOW_DEFAULT_PERMISSION:-READ}"
# Background job runners (online LLM-judge scoring, issue detection, prompt
# optimisation) add about 2 GB of RAM, so they are off unless asked for.
export MLFLOW_SERVER_ENABLE_JOB_EXECUTION="${MLFLOW_SERVER_ENABLE_JOB_EXECUTION:-false}"

if [ -z "${MLFLOW_ADMIN_PASSWORD:-}" ]; then
  echo "MLFLOW_ADMIN_PASSWORD is not set" >&2; exit 1
fi
if [ -z "${MLFLOW_FLASK_SERVER_SECRET_KEY:-}" ]; then
  echo "MLFLOW_FLASK_SERVER_SECRET_KEY is not set" >&2; exit 1
fi

mkdir -p "$MLFLOW_ARTIFACTS_DIR"
BACKEND="${MLFLOW_BACKEND_STORE_URI:-sqlite:///${MLFLOW_ARTIFACTS_DIR}/mlflow.db}"

# Host header allow list: the Railway public and private domains, Railway's
# health checker and localhost, plus anything in MLFLOW_EXTRA_ALLOWED_HOSTS.
HOSTS="healthcheck.railway.app,localhost,localhost:${PORT},127.0.0.1:${PORT}"
ORIGINS=""
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  HOSTS="${HOSTS},${RAILWAY_PUBLIC_DOMAIN}"
  ORIGINS="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
if [ -n "${RAILWAY_PRIVATE_DOMAIN:-}" ]; then
  HOSTS="${HOSTS},${RAILWAY_PRIVATE_DOMAIN},${RAILWAY_PRIVATE_DOMAIN}:${PORT}"
fi
[ -n "${MLFLOW_EXTRA_ALLOWED_HOSTS:-}" ] && HOSTS="${HOSTS},${MLFLOW_EXTRA_ALLOWED_HOSTS}"
# The UI sends an Origin header on every write, so its own origin must be allowed.
[ -n "${MLFLOW_EXTRA_CORS_ORIGINS:-}" ] && ORIGINS="${ORIGINS:+${ORIGINS},}${MLFLOW_EXTRA_CORS_ORIGINS}"
[ -z "$ORIGINS" ] && ORIGINS="http://localhost:${PORT}"

# Auth config. configparser treats % specially, so double it.
esc() { printf '%s' "$1" | sed 's/%/%%/g'; }
AUTH_INI=/tmp/mlflow-basic-auth.ini
umask 077
cat > "$AUTH_INI" <<INI
[mlflow]
default_permission = ${MLFLOW_DEFAULT_PERMISSION}
database_uri = sqlite:///${MLFLOW_ARTIFACTS_DIR}/basic_auth.db
admin_username = $(esc "$MLFLOW_ADMIN_USERNAME")
admin_password = $(esc "$MLFLOW_ADMIN_PASSWORD")
authorization_function = mlflow.server.auth:authenticate_request_basic_auth
INI
export MLFLOW_AUTH_CONFIG_PATH="$AUTH_INI"

echo "Starting MLflow $(python -c 'import mlflow; print(mlflow.__version__)') on port ${PORT} with ${MLFLOW_WORKERS} worker(s), background jobs: ${MLFLOW_SERVER_ENABLE_JOB_EXECUTION}"
exec mlflow server \
  --host 0.0.0.0 \
  --port "$PORT" \
  --workers "$MLFLOW_WORKERS" \
  --backend-store-uri "$BACKEND" \
  --artifacts-destination "$MLFLOW_ARTIFACTS_DIR" \
  --serve-artifacts \
  --app-name basic-auth \
  --allowed-hosts "$HOSTS" \
  --cors-allowed-origins "$ORIGINS"
