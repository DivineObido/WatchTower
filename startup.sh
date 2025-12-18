#!/bin/sh
set -e

# Create admin if it doesn't exist
npx payload users:create \
  --email $PAYLOAD_ADMIN_EMAIL \
  --password $PAYLOAD_ADMIN_PASSWORD \
  --role admin \
  --no-exit || true

# Pass control to CMD
exec "$@"
