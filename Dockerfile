# =============================================================================
# SokoPrice - production container image (multi-stage build)
#
#   Stage 1 "builder": installs Python dependencies into a virtual environment.
#   Stage 2 "runtime": copies ONLY the virtual environment and the app code, so
#                      the final image is small and has no build tooling.
#
# Build:  docker build -t sokoprice .
# Run:    docker run -p 5000:5000 sokoprice
# =============================================================================

# Pin the Python version AND the Debian release so builds are reproducible.
# (Never use a bare "python" or "latest" tag.)
ARG PYTHON_VERSION=3.12

# -----------------------------------------------------------------------------
# Stage 1: builder - resolve and install dependencies
# -----------------------------------------------------------------------------
FROM python:${PYTHON_VERSION}-slim-bookworm AS builder

# Do not keep pip's download cache and do not nag about pip upgrades.
ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1

# A virtual environment is easy to copy into the runtime stage as one folder.
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /build

# LAYER CACHING: copy only the requirements file first. This layer (and the slow
# pip install below) is rebuilt ONLY when requirements.txt changes, not every
# time application code changes.
COPY requirements.txt .
RUN pip install -r requirements.txt

# -----------------------------------------------------------------------------
# Stage 2: runtime - the image that actually runs
# -----------------------------------------------------------------------------
FROM python:${PYTHON_VERSION}-slim-bookworm AS runtime

LABEL org.opencontainers.image.title="SokoPrice" \
      org.opencontainers.image.description="Crop price tracker for African farmers (USSD + REST API)" \
      org.opencontainers.image.source="https://github.com/jessewalu/sokoprice-formative1" \
      org.opencontainers.image.licenses="MIT"

# PYTHONUNBUFFERED: send logs straight to `docker logs` without buffering.
# PORT: the port gunicorn listens on (can be overridden at run time).
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

# SECURITY: create an unprivileged system user with a fixed UID/GID, no home
# directory and no login shell. The app never runs as root.
RUN groupadd --system --gid 10001 appgroup \
    && useradd --system --uid 10001 --gid appgroup \
       --no-create-home --shell /usr/sbin/nologin appuser

WORKDIR /srv

# Bring in the installed dependencies from the builder stage.
COPY --from=builder /opt/venv /opt/venv

# Copy application code last: it changes most often, so it sits in the top
# layers and keeps earlier layers cached. --chown gives the app user ownership.
COPY --chown=appuser:appgroup app ./app
COPY --chown=appuser:appgroup data ./data
COPY --chown=appuser:appgroup scripts ./scripts
COPY --chown=appuser:appgroup run.py .

# Drop privileges: everything below (and the running container) is non-root.
USER 10001:10001

# Documentation only: the port the app listens on.
EXPOSE 5000

# HEALTH CHECK: Docker / Compose mark the container "healthy" only when
# /health answers 200. The probe uses Python because slim images have no curl.
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD ["python", "scripts/healthcheck.py"]

# Start the production WSGI server (not the Flask dev server).
# "exec" makes gunicorn PID 1 so it receives SIGTERM for clean shutdowns.
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT} --workers 2 --access-logfile - run:app"]
