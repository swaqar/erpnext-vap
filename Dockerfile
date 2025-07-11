FROM python:3.10-slim-bullseye

LABEL maintainer="swaqar <your-email@example.com>"
LABEL description="Minimal ERPNext image for production use with Virtuozzo VAP"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/home/frappe/.local/bin:$PATH

# Install minimal runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        gnupg \
        git \
        build-essential \
        mariadb-client \
        redis-server \
        redis-tools \
        curl \
        ca-certificates \
        gnupg \
        lsb-release \
        cron \
        supervisor \
        nginx \
        libffi-dev \
        libssl-dev \
        libjpeg-dev \
        zlib1g-dev \
        libmariadb-dev \
        libpq-dev \
        libwebp-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 18+ (required for Frappe framework)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Create user and set permissions
RUN useradd -ms /bin/bash frappe && \
    mkdir -p /home/frappe && \
    chown -R frappe:frappe /home/frappe

USER frappe
WORKDIR /home/frappe

# Copy entrypoint script
COPY --chown=frappe:frappe entrypoint.sh /home/frappe/entrypoint.sh

# Install bench CLI
RUN pip install --no-cache-dir --user frappe-bench

# Setup bench directory
RUN bench init --frappe-path https://github.com/frappe/frappe --frappe-branch version-15 frappe-bench

WORKDIR /home/frappe/frappe-bench

# Install ERPNext App (source, or custom fork if needed)
RUN bench get-app --branch version-15 erpnext https://github.com/frappe/erpnext

# Expose ports for web + socketio
EXPOSE 8000 9000

# Entrypoint for dynamic site + production setup
ENTRYPOINT ["bash", "/home/frappe/entrypoint.sh"]
