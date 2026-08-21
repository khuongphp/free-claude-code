# Free Claude Code - Dockerfile
# Alpine-based multi-stage build for minimal image

# ============================================
# Stage 1: Build stage
# ============================================
FROM python:3.14-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache gcc musl-dev libffi-dev openssl-dev

# Copy files required for Hatchling wheel (metadata, lockfile, package sources)
COPY pyproject.toml uv.lock README.md .env.example ./
COPY src ./src

# Install uv and dependencies
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
RUN uv pip install --system --no-cache .

# ============================================
# Stage 2: Runtime stage (minimal)
# ============================================
FROM python:3.14-alpine

WORKDIR /app

# Copy installed packages and console scripts from builder
COPY --from=builder /usr/local/lib/python3.14/site-packages /usr/local/lib/python3.14/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

RUN mkdir -p /app/agent_workspace

# Expose the default port
EXPOSE 8082

# Health check (local-only endpoint)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8082/health')" || exit 1

# Run the server
CMD ["fcc-server"]
