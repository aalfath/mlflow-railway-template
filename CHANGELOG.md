# Changelog

## 3.18.0, README (2026-11-16)

- README: Deploy on Railway button for the published template `mlflow-1`. No change to the image or start script.

## 3.18.0 (2026-11-16)

First repo-based version of the `mlflow-1` template, replacing the image service that ran MLflow 3.16.1.

- MLflow 3.18.0, official `-full` image pinned by digest.
- Fix: the web UI could not create or edit anything. MLflow 3.x blocks requests whose `Origin` header isn't allowed, and the old start command never allowed the Railway domain. The start script now passes `--cors-allowed-origins https://<railway domain>`.
- Idle RAM down from about 4.9 GB to about 0.7 GB: 2 workers instead of 4, and MLflow's background job runners off by default (`MLFLOW_SERVER_ENABLE_JOB_EXECUTION=true` turns them back on).
- Allowed hosts are derived from the Railway domains; `MLFLOW_ALLOWED_HOSTS` is no longer used. Add custom domains with `MLFLOW_EXTRA_ALLOWED_HOSTS` and `MLFLOW_EXTRA_CORS_ORIGINS`.
