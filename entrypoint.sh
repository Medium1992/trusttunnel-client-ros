#!/bin/sh
set -eu

CONFIG_DIR="/tt-config"
ENDPOINT_CONFIG="$CONFIG_DIR/endpoint_config.toml"
CLIENT_CONFIG="/trusttunnel_client.toml"

LOGLEVEL="${LOGLEVEL:-info}"
HAS_IPV6="${HAS_IPV6:-false}"

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

patch_array() {
  key="$1"
  val="$2"
  file="$3"

  formatted=$(printf '%s' "$val" | sed 's/,/", "/g')
  sed -i "s|^$key *=.*|$key = [\"$formatted\"]|" "$file"
}

toml_array() {
  printf '%s' "$1" | sed 's/,/", "/g; s/^/["/; s/$/"]/'
}

remove_listener() {
  sed -i '/^\[listener\]/,/^\[[^l]/ {/^\[[^l]/!d}' "$CLIENT_CONFIG"
}

configure_listener() {
  TYPE="${LISTENER_TYPE:-tun}"

  case "$TYPE" in
    tun)
      cat >> "$CLIENT_CONFIG" <<EOF

[listener]
[listener.tun]
bound_if = "${TUN_BOUND_IF:-}"
included_routes = $(toml_array "${TUN_INCLUDED_ROUTES:-0.0.0.0/0}")
excluded_routes = $(toml_array "${TUN_EXCLUDED_ROUTES:-0.0.0.0/8,10.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.168.0.0/16,224.0.0.0/3}")
mtu_size = ${TUN_MTU_SIZE:-1500}
change_system_dns = ${TUN_CHANGE_SYSTEM_DNS:-true}
EOF
      ;;
    socks)
      cat >> "$CLIENT_CONFIG" <<EOF

[listener]
[listener.socks]
address = "${SOCKS_ADDRESS:-0.0.0.0:1080}"
username = "${SOCKS_USERNAME:-}"
password = "${SOCKS_PASSWORD:-}"
EOF
      ;;
    *)
      echo "ERROR: LISTENER_TYPE must be 'tun' or 'socks'"
      exit 1
      ;;
  esac
}


mkdir -p "$CONFIG_DIR"

case "$LOGLEVEL" in
  info|debug|trace) ;;
  *)
    echo "ERROR: invalid LOGLEVEL=$LOGLEVEL (allowed: info, debug, trace)"
    exit 1
    ;;
esac

patch_string "loglevel" "$LOGLEVEL" "$CLIENT_CONFIG"

if [ -f "$ENDPOINT_CONFIG" ]; then
  echo "endpoint_config.toml found, forcing client config regeneration"
  rm -f "$CLIENT_CONFIG"
fi

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

if [ -n "${HAS_IPV6+x}" ]; then
  patch_bool "has_ipv6" "$HAS_IPV6" "$CLIENT_CONFIG"
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

if [ -n "${UPSTREAM_PROTOCOL+x}" ]; then
  patch_string "upstream_protocol" "$UPSTREAM_PROTOCOL" "$CLIENT_CONFIG"
fi

if [ -n "${UPSTREAM_FALLBACK_PROTOCOL+x}" ]; then
  patch_string "upstream_fallback_protocol" "$UPSTREAM_FALLBACK_PROTOCOL" "$CLIENT_CONFIG"
fi

if [ -n "${DNS_UPSTREAMS+x}" ]; then
  patch_array "dns_upstreams" "$DNS_UPSTREAMS" "$CLIENT_CONFIG"
fi

remove_listener
configure_listener

echo "Starting trusttunnel_client..."
exec /trusttunnel_client -c "$CLIENT_CONFIG"
