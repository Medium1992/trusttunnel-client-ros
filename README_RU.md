[English](/README.md) | [Русский](/README_RU.md)

[Telegram группа](https://t.me/+96HVPF3Ww6o3YTNi)

# 🇷🇺 Описание на русском

**trusttunnel-client-ros** — это Docker-контейнер на базе [**TrustTunnelClient**](https://github.com/TrustTunnel/TrustTunnelClient) для Mikrotik RouterOS.
На сервере необходимо поднять [TrustTunnel](https://github.com/TrustTunnel/TrustTunnel) и сформировать [конфиг](https://github.com/TrustTunnel/TrustTunnel?tab=readme-ov-file#export-client-configuration) файл для клиента с именем `endpoint_config.toml`.

## Описание ENVs

**Обязательно монтировать `endpoint_config.toml` в папку `/tt-config/`, из него создается клиентский конфиг** 
> При наличии смонтированного `endpoint_config.toml` конфигурация клиента всегда пересоздаётся.  
> Конфигурация listener’а полностью управляется через ENV.

Контейнер конфигурируется через переменные окружения.

Все переменные являются необязательными, если не указано иное.

| Переменная | По умолчанию | Описание |
|-----------|--------------|----------|
| `LOGLEVEL` | `info` | Уровень логирования клиента. Возможные значения: `info`, `debug`, `trace`. |
| `LISTENER_TYPE` | `tun` | Тип listener’а. `tun` — виртуальный TUN интерфейс, `socks` — SOCKS5 прокси. |
| `TUN_BOUND_IF` | — | Имя сетевого интерфейса, к которому будет привязан TUN. Если не задано — определяется автоматически. |
| `TUN_INCLUDED_ROUTES` | `0.0.0.0/0` | CIDR-подсети, которые маршрутизируются через VPN (TUN). Задаются списком через запятую. |
| `TUN_EXCLUDED_ROUTES` | `0.0.0.0/8,10.0.0.0/8,169.254.0.0/16, 172.16.0.0/12,192.168.0.0/16,224.0.0.0/3` | CIDR-подсети, которые исключаются из маршрутизации через VPN. Задаются списком через запятую. |
| `TUN_MTU_SIZE` | `1500` | Размер MTU виртуального TUN интерфейса. |
| `TUN_CHANGE_SYSTEM_DNS` | `true` | Разрешить изменение системных DNS серверов при использовании TUN. |
| `SOCKS_ADDRESS` | `0.0.0.0:1080` | Адрес, на котором будет запущен SOCKS5 сервер (используется при `LISTENER_TYPE=socks`). |
| `SOCKS_USERNAME` | — | Имя пользователя для аутентификации SOCKS5. Если не задано — аутентификация отключена. |
| `SOCKS_PASSWORD` | — | Пароль для аутентификации SOCKS5. Используется совместно с `SOCKS_USERNAME`. |
| `HAS_IPV6` | `false` | Разрешить маршрутизацию IPv6 трафика через VPN endpoint. |
| `KILLSWITCH_ENABLED` | `true` | Включение kill-switch. При потере соединения с endpoint трафик не будет выпускаться напрямую. |
| `POST_QUANTUM_GROUP_ENABLED` | `false` | Использование post-quantum алгоритмов при TLS handshake. |
| `ANTI_DPI` | `false` | Включение anti-DPI механизмов. |
| `UPSTREAM_PROTOCOL` | `http2` | Основной протокол соединения с VPN endpoint. Возможные значения: `http2`, `http3`. |
| `UPSTREAM_FALLBACK_PROTOCOL` | — | Резервный протокол соединения с endpoint, используется если основной недоступен. |
| `DNS_UPSTREAMS` | — | DNS серверы, которые будут использоваться клиентом. Задаются списком через запятую. Поддерживаются `udp`, `tcp`, `tls`, `https`, `quic`. |

## Пример установки на RouterOS Mikrotik.

Предварительно убедитесь что у вас установлен пакет `container`, а также разрешены нужные функции device-mode.
```bash
/system/device-mode/print
```
Разрешите device-mode если необходимо.
Следуйте указаниям после выполнения команды ниже, даётся 5 минут на перезагрузку электропитанием или кратковременно нажать на любую кнопку на устройстве, я рекомендую использовать любую кнопку)
```bash
/system/device-mode/update mode=advanced container=yes
```

Установка без роутинга с синтаксисом для версии RouterOS 7.21, при установке на другую версию синтаксис некоторых команд может отличаться.
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

## 💖 Поддержка проекта

Если вам полезен этот проект, вы можете поддержать его донатом:  
**USDT(TRC20): TWDDYD1nk5JnG6FxvEu2fyFqMCY9PcdEsJ**

**https://boosty.to/petersolomon/donate**

<img width="150" height="150" alt="petersolomon-donate" src="https://github.com/user-attachments/assets/fcf40baa-a09e-4188-a036-7ad3a77f06ea" />
