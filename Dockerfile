# syntax=docker/dockerfile:1
# check=error=true

# ================================================================================
# TRAMATE PLATFORM - PRODUCTION DOCKERFILE
# ================================================================================
# Optimized for deployment with security, performance, and monitoring features
# 
# Build commands:
#   docker build -t tramate:latest -t tramate:$(date +%Y%m%d) .
#   docker run -d -p 3000:3000 --name tramate-prod tramate:latest
#
# Environment variables required:
#   RAILS_MASTER_KEY - Rails credentials decryption key
#   DATABASE_URL - PostgreSQL connection string
#   REDIS_URL - Redis connection string (optional)
# ================================================================================

# Build arguments for flexibility
ARG RUBY_VERSION=3.2.3
ARG DEBIAN_VERSION=bookworm-slim
ARG APP_USER=rails
ARG APP_UID=1000
ARG APP_GID=1000

# Base image with security updates
FROM docker.io/library/ruby:$RUBY_VERSION-$DEBIAN_VERSION AS base

# Set working directory
WORKDIR /rails

# Install system dependencies with security updates
RUN apt-get update -qq && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
        # Essential packages
        curl \
        wget \
        ca-certificates \
        gnupg \
        # Performance and memory management
        libjemalloc2 \
        # Image processing
        libvips \
        # Database clients
        postgresql-client \
        # SSL/TLS support
        openssl \
        # Process monitoring
        htop \
        # Timezone data
        tzdata \
        # Clean up
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && apt-get clean

# Set timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set production environment variables
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_SERVE_STATIC_FILES="true" \
    RAILS_LOG_TO_STDOUT="true" \
    MALLOC_ARENA_MAX="2" \
    RUBY_YJIT_ENABLE="1"

# ================================================================================
# BUILD STAGE - Multi-stage build for smaller final image
# ================================================================================
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        # Build tools
        build-essential \
        git \
        # Database development headers
        libpq-dev \
        # YAML support
        libyaml-dev \
        # Package config
        pkg-config \
        # Node.js for asset compilation
        nodejs \
        npm \
        # Clean up
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && apt-get clean

# Create app user for build stage
ARG APP_USER
ARG APP_UID
ARG APP_GID
RUN groupadd --system --gid $APP_GID $APP_USER && \
    useradd $APP_USER --uid $APP_UID --gid $APP_GID --create-home --shell /bin/bash

# Copy dependency files with proper ownership
COPY --chown=$APP_USER:$APP_USER Gemfile Gemfile.lock ./

# Install Ruby gems with optimizations
RUN bundle config --global frozen 1 && \
    bundle config --global no-cache true && \
    bundle config --global deployment true && \
    bundle config --global without 'development test' && \
    bundle install --jobs=$(nproc) --retry=3 && \
    # Clean up gem cache and docs
    rm -rf ~/.bundle/ \
           "${BUNDLE_PATH}"/ruby/*/cache \
           "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git \
           "${BUNDLE_PATH}"/ruby/*/gems/*/test \
           "${BUNDLE_PATH}"/ruby/*/gems/*/spec \
           "${BUNDLE_PATH}"/ruby/*/gems/*/benchmark \
    && bundle exec bootsnap precompile --gemfile

# Copy application code
COPY --chown=$APP_USER:$APP_USER . .

# Create necessary directories with proper permissions
RUN mkdir -p log tmp/pids tmp/cache tmp/sockets storage && \
    chown -R $APP_USER:$APP_USER log tmp storage

# Switch to app user for build operations
USER $APP_USER

# Precompile bootsnap for faster boot times
RUN bundle exec bootsnap precompile app/ lib/ config/

# Precompile assets with optimizations
RUN SECRET_KEY_BASE_DUMMY=1 \
    RAILS_ENV=production \
    NODE_ENV=production \
    ./bin/rails assets:precompile && \
    # Remove source maps and other dev files
    find public/assets -name "*.map" -delete && \
    find public/assets -name "*.md" -delete

# ================================================================================
# PRODUCTION STAGE - Minimal runtime image
# ================================================================================
FROM base AS production

# Create app user and group
ARG APP_USER
ARG APP_UID  
ARG APP_GID
RUN groupadd --system --gid $APP_GID $APP_USER && \
    useradd $APP_USER --uid $APP_UID --gid $APP_GID --create-home --shell /bin/bash

# Copy built artifacts from build stage
COPY --from=build --chown=$APP_USER:$APP_USER "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build --chown=$APP_USER:$APP_USER /rails /rails

# Create and set permissions for runtime directories
RUN mkdir -p /rails/log /rails/tmp /rails/storage && \
    chown -R $APP_USER:$APP_USER /rails/db /rails/log /rails/storage /rails/tmp && \
    chmod -R 755 /rails/log /rails/tmp /rails/storage

# Add health check script
COPY --chown=$APP_USER:$APP_USER <<'EOF' /rails/bin/healthcheck
#!/bin/bash
set -e

# Health check with timeout and retry logic
HEALTH_URL="http://localhost:3000/health"
MAX_RETRIES=3
RETRY_DELAY=2

for i in $(seq 1 $MAX_RETRIES); do
    if curl -f -s --connect-timeout 5 --max-time 10 "$HEALTH_URL" >/dev/null 2>&1; then
        echo "Health check passed"
        exit 0
    else
        echo "Health check attempt $i failed"
        if [ $i -lt $MAX_RETRIES ]; then
            sleep $RETRY_DELAY
        fi
    fi
done

echo "Health check failed after $MAX_RETRIES attempts"
exit 1
EOF

RUN chmod +x /rails/bin/healthcheck

# Switch to non-root user for security
USER $APP_USER

# Health check configuration with proper startup grace period
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD ["/rails/bin/healthcheck"]

# Configure container metadata with build info
LABEL maintainer="Tramate Platform <support@tramate.com>" \
      description="Tramate - Advanced Discord-to-Binance Trading Platform" \
      version="1.0.0" \
      build.date="2024-12-19" \
      org.opencontainers.image.title="Tramate Platform" \
      org.opencontainers.image.description="Advanced Discord-to-Binance trading automation platform with 88.6% signal success rate" \
      org.opencontainers.image.vendor="Tramate" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.created="2024-12-19T00:00:00Z" \
      org.opencontainers.image.licenses="Proprietary" \
      org.opencontainers.image.documentation="https://github.com/tramate/platform/docs" \
      tramate.component="web-server" \
      tramate.environment="production"

# Create volume mount points for persistent data
VOLUME ["/rails/storage", "/rails/log"]

# Expose port 3000 (Rails standard)
EXPOSE 3000

# Set working directory
WORKDIR /rails

# Set entrypoint for container initialization
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Default command with optimized Rails server settings
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000", "--pid", "/rails/tmp/pids/server.pid"]
