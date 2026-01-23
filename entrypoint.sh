#!/bin/sh
set -eu

CONFIG_DIR="/tt-config"
ENDPOINT_CONFIG="$CONFIG_DIR/endpoint_config.toml"
CLIENT_CONFIG="/trusttunnel_client.toml"

patch_bool() {
  key="$1"
  val="$2"
  file="$3"

  sed -i "s|^$key *=.*|$key = $val|" "$file"
}

patch_string() {
  key="$1"
  val="$2"
  file="$3"

  sed -i "s|^$key *=.*|$key = \"$val\"|" "$file"
}

mkdir -p "$CONFIG_DIR"

if [ ! -f "$CLIENT_CONFIG" ]; then
  if [ ! -f "$ENDPOINT_CONFIG" ]; then
    echo "ERROR: $ENDPOINT_CONFIG not found"
    echo "You must mount endpoint_config.toml into $CONFIG_DIR"
    exit 1
  fi

  echo "Generating trusttunnel_client.toml using setup_wizard..."

  /setup_wizard \
    --mode non-interactive \
    --endpoint_config "$ENDPOINT_CONFIG" \
    --settings "$CLIENT_CONFIG"
else
  echo "Using existing trusttunnel_client.toml"
fi

if [ -n "${KILLSWITCH_ENABLED+x}" ]; then
  patch_bool "killswitch_enabled" "$KILLSWITCH_ENABLED" "$CLIENT_CONFIG"
fi

if [ -n "${POST_QUANTUM_GROUP_ENABLED+x}" ]; then
  patch_bool "post_quantum_group_enabled" "$POST_QUANTUM_GROUP_ENABLED" "$CLIENT_CONFIG"
fi

if [ -n "${ANTI_DPI+x}" ]; then
  patch_bool "anti_dpi" "$ANTI_DPI" "$CLIENT_CONFIG"
fi

if [ -n "${UPSTREAM_FALLBACK_PROTOCOL+x}" ]; then
  patch_string "upstream_fallback_protocol" "$UPSTREAM_FALLBACK_PROTOCOL" "$CLIENT_CONFIG"
fi

echo "Starting trusttunnel_client..."
exec /trusttunnel_client -c "$CLIENT_CONFIG"
