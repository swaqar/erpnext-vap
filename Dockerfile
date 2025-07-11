FROM ubuntu:22.04

LABEL maintainer="swaqar <your-email@example.com>"
LABEL description="Minimal ERPNext image for production use with Virtuozzo VAP"
LABEL org.opencontainers.image.os="linux"
LABEL org.opencontainers.image.architecture="amd64"
LABEL org.opencontainers.image.vendor="Virtuozzo VAP"
LABEL org.opencontainers.image.title="ERPNext Hardened"
LABEL org.opencontainers.image.description="Production-ready ERPNext for Virtuozzo Application Platform"
LABEL org.opencontainers.image.version="1.0.1"
LABEL org.opencontainers.image.created="2024-01-01T00:00:00Z"
LABEL org.opencontainers.image.revision="v1.0.1"
LABEL org.opencontainers.image.source="https://github.com/sydwaq/erpnext-vap-git"
LABEL com.virtuozzo.vap.os="ubuntu"
LABEL com.virtuozzo.vap.os.version="22.04"
LABEL com.virtuozzo.vap.arch="amd64"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/home/frappe/.local/bin:$PATH

# Install Python 3.10 and minimal runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.10 \
        python3.10-dev \
        python3.10-venv \
        python3-pip \
        curl \
        wget \
        gnupg \
        git \
        build-essential \
        mariadb-client \
        redis-server \
        redis-tools \
        ca-certificates \
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

# Create symlink for python3.10
RUN ln -sf /usr/bin/python3.10 /usr/bin/python3 && \
    ln -sf /usr/bin/python3.10 /usr/bin/python

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
