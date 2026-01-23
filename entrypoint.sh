#!/bin/sh
set -eu

CONFIG_DIR="/tt-config"
ENDPOINT_CONFIG="$CONFIG_DIR/endpoint_config.toml"
CLIENT_CONFIG="/trusttunnel_client.toml"

mkdir -p "$CONFIG_DIR"

if [ ! -f "$ENDPOINT_CONFIG" ]; then
  echo "ERROR: $ENDPOINT_CONFIG not found"
  echo "You must mount endpoint_config.toml into $CONFIG_DIR"
  exit 1
fi

if [ ! -f "$CLIENT_CONFIG" ]; then
  echo "Generating trusttunnel_client.toml using setup_wizard..."

  /setup_wizard \
    --mode non-interactive \
    --endpoint_config "$ENDPOINT_CONFIG" \
    --settings "$CLIENT_CONFIG"
else
  echo "Using existing trusttunnel_client.toml"
fi

# TODO: ENV → toml patching goes here later

echo "Starting trusttunnel_client..."
exec /trusttunnel_client -c "$CLIENT_CONFIG"
