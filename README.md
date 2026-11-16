[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/mlflow-1?utm_medium=integration&utm_source=button&utm_campaign=mlflow)

# MLflow on Railway

Railway template for the [MLflow](https://mlflow.org) tracking server: experiments, runs, metrics, artifacts, the model registry and GenAI tracing, behind MLflow's built-in login.

- **Version:** MLflow 3.18.0, official image `ghcr.io/mlflow/mlflow:v3.18.0-full@sha256:a8459ca08b1e8a0dc287b4e226d4f2338f56052d7e2d333a4aa5891be0670919`
- **Services:** `mlflow` (built from this repo, public domain, volume at `/mlartifacts`) and Railway Postgres (runs and model registry)
- **Template:** `mlflow-1` in the Railway marketplace

## What the wrapper does

`start.sh` writes the basic-auth config from the variables, then runs `mlflow server` with:

- the Postgres backend store and proxied artifact storage on the volume (clients need no cloud credentials);
- `--app-name basic-auth`: the admin account is created on first start, new users get `READ` by default;
- `--allowed-hosts` and `--cors-allowed-origins` built from `RAILWAY_PUBLIC_DOMAIN` and `RAILWAY_PRIVATE_DOMAIN`, so the web UI can write and private-network clients can connect;
- 2 workers, and MLflow's background job runners off, which keeps an idle server around 0.7 GB of RAM instead of about 5 GB.

## Variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `MLFLOW_ADMIN_USERNAME` | `admin` | Admin user, created on first start |
| `MLFLOW_ADMIN_PASSWORD` | generated | Admin password, applied only when the auth database is first created |
| `MLFLOW_FLASK_SERVER_SECRET_KEY` | generated | Secret for the auth app's CSRF protection |
| `MLFLOW_BACKEND_STORE_URI` | `${{Postgres.DATABASE_URL}}` | Runs and model registry |
| `PORT` | `5000` | Listen port |
| `MLFLOW_WORKERS` | `2` | Uvicorn worker processes |
| `MLFLOW_SERVER_ENABLE_JOB_EXECUTION` | `false` | Set `true` for online LLM-judge scoring, issue detection and other background jobs (adds about 2 GB of RAM) |
| `MLFLOW_EXTRA_ALLOWED_HOSTS` | empty | Extra Host headers, for example a custom domain |
| `MLFLOW_EXTRA_CORS_ORIGINS` | empty | Extra origins, for example `https://mlflow.example.com` |
| `MLFLOW_DEFAULT_PERMISSION` | `READ` | Permission new users get on existing resources |

## Updates

Deployers get Railway's "update available" notice when `main` changes. Read `CHANGELOG.md` before applying an update: MLflow migrates the Postgres schema on start, so back up the database first.
