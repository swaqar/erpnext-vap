#!/bin/bash

set -e

SITE_NAME=${SITE_NAME:-mysite.local}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin}
DB_HOST=${DB_HOST:-mariadb}
DB_PORT=${DB_PORT:-3306}
DB_USER=${DB_USER:-root}
DB_PASSWORD=${DB_PASSWORD:-root}
REDIS_HOST=${REDIS_HOST}
REDIS_PORT=${REDIS_PORT:-6379}
FRAPPE_USER=${FRAPPE_USER:-frappe}

cd /home/frappe/frappe-bench

if [ -n "$REDIS_HOST" ]; then
  echo "📡 Configuring Redis..."
  export REDIS_CACHE="redis://${REDIS_HOST}:${REDIS_PORT}"
  export REDIS_QUEUE="redis://${REDIS_HOST}:${REDIS_PORT}"
  export REDIS_SOCKETIO="redis://${REDIS_HOST}:${REDIS_PORT}"
fi

if [ ! -d "sites/$SITE_NAME" ]; then
  echo "⚙️  Creating site: $SITE_NAME"
  bench new-site "$SITE_NAME" \
    --admin-password "$ADMIN_PASSWORD" \
    --mariadb-root-password "$DB_PASSWORD" \
    --db-host "$DB_HOST" \
    --db-port "$DB_PORT" \
    --db-name "$SITE_NAME"

  echo "📦 Installing ERPNext on $SITE_NAME"
  bench --site "$SITE_NAME" install-app erpnext
fi

echo "✅ Setting default site to $SITE_NAME"
bench use "$SITE_NAME"

echo "🚀 Enabling production mode..."
sudo bench setup production "$FRAPPE_USER"

echo "📌 Reloading Supervisor..."
sudo supervisorctl reload

echo "🎉 ERPNext is now set up and running in production mode!"
