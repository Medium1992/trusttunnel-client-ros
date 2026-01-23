FROM --platform=$BUILDPLATFORM alpine:latest AS package
ARG TARGETARCH
RUN apk add --no-cache curl jq tar
COPY entrypoint.sh /final/
RUN set -eux; \
    case "$TARGETARCH" in \
      amd64)  ARCH="x86_64" ;; \
      arm64)  ARCH="aarch64" ;; \
      arm)    ARCH="armv7" ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac; \
    \
    URL=$(curl -s https://api.github.com/repos/TrustTunnel/TrustTunnelClient/releases/latest | \
        jq -r '.assets[].browser_download_url' | \
        grep "linux-$ARCH\.tar\.gz$"); \
    \
    curl -L "$URL" -o trusttunnel.tar.gz; \
    tar -xzf trusttunnel.tar.gz; \
    \
    mkdir -p /final; \
    cp setup_wizard trusttunnel_client /final/; \
    chmod +x /final/setup_wizard /final/trusttunnel_client /final/entrypoint.sh

FROM alpine:latest 
FROM ${TARGETOS}-${TARGETARCH}${TARGETVARIANT}
COPY --from=package /final /
ENTRYPOINT ["/entrypoint.sh"]
