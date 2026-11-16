# MLflow tracking server for Railway, from the official image.
# Bump the tag and digest together; see CHANGELOG.md.
FROM ghcr.io/mlflow/mlflow:v3.18.0-full@sha256:a8459ca08b1e8a0dc287b4e226d4f2338f56052d7e2d333a4aa5891be0670919

COPY start.sh /usr/local/bin/railway-mlflow-start
RUN chmod 0755 /usr/local/bin/railway-mlflow-start

EXPOSE 5000
ENTRYPOINT []
CMD ["/usr/local/bin/railway-mlflow-start"]
