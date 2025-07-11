FROM python:3.10-slim-bullseye

# Set environment
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH="/home/frappe/.local/bin:$PATH"

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        build-essential \
        mariadb-client \
        redis-tools \
        libffi-dev \
        libssl-dev \
        libmysqlclient-dev \
        wkhtmltopdf \
        sudo \
        nodejs \
        npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -ms /bin/bash frappe && \
    adduser frappe sudo && \
    echo 'frappe ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER frappe
WORKDIR /home/frappe

# Install Frappe Bench CLI
RUN pip install --user frappe-bench

# Initialize Bench
RUN bench init frappe-bench --frappe-branch version-15 && \
    cd frappe-bench && \
    bench get-app erpnext --branch version-15

WORKDIR /home/frappe/frappe-bench
COPY entrypoint.sh /home/frappe/entrypoint.sh
RUN chmod +x /home/frappe/entrypoint.sh

EXPOSE 8000 9000

ENTRYPOINT ["/home/frappe/entrypoint.sh"]
