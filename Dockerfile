ARG PY_BASE=python:3.12-slim@sha256:9c1d9ed7593f2552a4ea47362ec0d2ddf5923458a53d0c8e30edf8b398c94a31
# ---- Builder ----
FROM ${PY_BASE} AS builder
ENV PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app

# System deps required for building wheels (adjust if needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential gcc curl && \
    rm -rf /var/lib/apt/lists/*

# Copy only resolver files first for better caching
COPY requirements.txt ./
RUN python -m venv /opt/venv && /opt/venv/bin/pip install -r requirements.txt

# ---- Runtime ----
FROM ${PY_BASE} AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN useradd --create-home --uid 10001 appuser
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy only what you need (after .dockerignore is set)
COPY app/ app/
COPY wsgi.py .

USER appuser:appuser

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD python -c "import urllib.request as u; u.urlopen('http://127.0.0.1:5000/health').read()"

# Gunicorn (prod server), bind to 5000 to match compose
ENV GUNICORN_CMD_ARGS="--bind 0.0.0.0:5000 --workers 3 --threads 2 --timeout 60"
EXPOSE 5000
ENTRYPOINT ["gunicorn", "wsgi:app"]
