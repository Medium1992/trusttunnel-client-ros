[English](/README.md) | [Russian](/README_RU.md)

[Telegram group](https://t.me/+96HVPF3Ww6o3YTNi)

# 🇬🇧 Description in English

**trusttunnel-client-ros** is a Docker container based on [**TrustTunnelClient**](https://github.com/TrustTunnel/TrustTunnelClient) for Mikrotik RouterOS.

On the server, you need to launch [TrustTunnel](https://github.com/TrustTunnel/TrustTunnel) and generate a [config](https://github.com/TrustTunnel/TrustTunnel?tab=readme-ov-file#export-client-configuration) file for the client named `endpoint_config.toml`.

## ENVs description

**Be sure to mount `endpoint_config.toml` to the `/tt-config/` folder, from which the client config is created**
> If `endpoint_config.toml` is mounted, the client configuration is always recreated.
> The listener configuration is fully managed through ENV.

The container is configured through environment variables.

All variables are optional unless otherwise specified.

| Variable | Default | Description |
|-----------|--------------|----------|
| `LOGLEVEL` | `info` | Client logging level. Possible values: `info`, `debug`, `trace`. |
| `LISTENER_TYPE` | `tun` | Listener type. `tun` — virtual TUN interface, `socks` — SOCKS5 proxy. |
| `TUN_BOUND_IF` | — | Name of the network interface to which TUN will be bound. If not specified, it is determined automatically. |
| `TUN_INCLUDED_ROUTES` | `0.0.0.0/0` | CIDR subnets that are routed through VPN (TUN). Specified as a comma-separated list. |
| `TUN_EXCLUDED_ROUTES` | `0.0.0.0/8,10.0.0.0/8,169.254.0.0/16, 172.16.0.0/12,192.168.0.0/16,224.0.0.0/3` | CIDR subnets that are excluded from routing through VPN. Specified as a comma-separated list. |
| `TUN_MTU_SIZE` | `1500` | MTU size of the virtual TUN interface. |
| `TUN_CHANGE_SYSTEM_DNS` | `true` | Allow changing system DNS servers when using TUN. |
| `SOCKS_ADDRESS` | `0.0.0.0:1080` | Address at which the SOCKS5 server will be launched (used when `LISTENER_TYPE=socks`). |
| `SOCKS_USERNAME` | — | Username for SOCKS5 authentication. If not specified, authentication is disabled. |
| `SOCKS_PASSWORD` | — | Password for SOCKS5 authentication. Used in conjunction with `SOCKS_USERNAME`. |
| `HAS_IPV6` | `false` | Allow IPv6 traffic to be routed through the VPN endpoint. |
| `KILLSWITCH_ENABLED` | `true` | Enable kill switch. If the connection to the endpoint is lost, traffic will not be released directly. |
| `POST_QUANTUM_GROUP_ENABLED` | `false` | Use post-quantum algorithms during TLS handshake. |
| `ANTI_DPI` | `false` | Enable anti-DPI mechanisms. |
| `UPSTREAM_PROTOCOL` | `http2` | Primary connection protocol with the VPN endpoint. Possible values: `http2`, `http3`. |
| `UPSTREAM_FALLBACK_PROTOCOL` | — | Backup connection protocol to the endpoint, used if the main one is unavailable. |
| `DNS_UPSTREAMS` | — | DNS servers that will be used by the client. Specified as a comma-separated list. Supported protocols: `udp`, `tcp`, `tls`, `https`, `quic`. |

## Example installation on Mikrotik RouterOS.

First, make sure you have the `container` package installed and that the necessary device-mode functions are enabled.
```bash
/system/device-mode/print
```

Enable device mode if necessary.
Follow the instructions after executing the command below. You have 5 minutes to reboot the power supply or briefly press any button on the device (I recommend using any button).
```bash
/system/device-mode/update mode=advanced container=yes
```

Installation without routing with syntax for RouterOS version 7.21. When installing on a different version, the syntax of some commands may differ.
```bash
/interface/veth/add name=TrustTunnelClient address=192.168.255.18/30 gateway=192.168.255.17
/ip/address/add address=192.168.255.17/30 interface=TrustTunnelClient
/routing/table/add name=TrustTunnelClient fib comment="TrustTunnelClient"
/ip/route/add dst-address=0.0.0.0/0 gateway=192.168.255.18 routing-table=TrustTunnelClient comment="TrustTunnelClient"
/container/envs/add key=LOGLEVEL list=TrustTunnelClient value="info"
/container/envs/add key=LISTENER_TYPE list=TrustTunnelClient value="tun"
/container/envs/add key=TUN_BOUND_IF list=TrustTunnelClient value=""
/container/envs/add key=TUN_INCLUDED_ROUTES list=TrustTunnelClient value="0.0.0.0/0"
/container/envs/add key=TUN_EXCLUDED_ROUTES list=TrustTunnelClient value="0.0.0.0/8,10.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.168.0.0/16,224.0.0.0/3"
/container/envs/add key=TUN_MTU_SIZE list=TrustTunnelClient value="1500"
/container/envs/add key=TUN_CHANGE_SYSTEM_DNS list=TrustTunnelClient value="true"
/container/envs/add key=SOCKS_ADDRESS list=TrustTunnelClient value="0.0.0.0:1080"
/container/envs/add key=SOCKS_USERNAME list=TrustTunnelClient value=""
/container/envs/add key=SOCKS_PASSWORD list=TrustTunnelClient value=""
/container/envs/add key=HAS_IPV6 list=TrustTunnelClient value="false"
/container/envs/add key=KILLSWITCH_ENABLED list=TrustTunnelClient value="true"
/container/envs/add key=POST_QUANTUM_GROUP_ENABLED list=TrustTunnelClient value="false"
/container/envs/add key=ANTI_DPI list=TrustTunnelClient value="false"
/container/envs/add key=UPSTREAM_PROTOCOL list=TrustTunnelClient value="http2"
/container/envs/add key=UPSTREAM_FALLBACK_PROTOCOL list=TrustTunnelClient value=""
/container/envs/add key=DNS_UPSTREAMS list=TrustTunnelClient value=""
/file/add name=tt-config type=directory
/container/mounts/add src=/tt-config/ dst=/tt-config/ list=tt-config comment="TrustTunnelClient"
/container/add remote-image="ghcr.io/medium1992/trusttunnel-client-ros" envlists=TrustTunnelClient mountlists=tt-config interface=TrustTunnelClient root-dir=/Containers/TrustTunnelClient start-on-boot=yes comment="TrustTunnelClient"
```
## 💖 Support the project

If you find this project useful, you can support it with a donation:  
**USDT(TRC20): TWDDYD1nk5JnG6FxvEu2fyFqMCY9PcdEsJ**

**https://boosty.to/petersolomon/donate**

<img width="150" height="150" alt="petersolomon-donate" src="https://github.com/user-attachments/assets/fcf40baa-a09e-4188-a036-7ad3a77f06ea" />
