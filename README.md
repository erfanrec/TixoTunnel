# TixoTunnel

TixoTunnel is a single-file installer and management panel maintained by TixoCloud.

## Install

Run as root:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/erfanrec/TixoTunnel/main/TixoTunnel.sh)
```

The script automatically:

- Creates `/root/tixotunnel-core`
- Downloads `tixotunnel-core` from the latest GitHub Release
- Installs the panel as `/root/TixoTunnel.sh`
- Creates the global `tixotunnel` command
- Applies executable permissions
- Opens the management panel

## Run again

```bash
tixotunnel
```

## GitHub Release asset

Each published release must contain an executable asset with this exact name:

```text
tixotunnel-core
```

## Brand

- Telegram: `@TixoCloud`
- Website: `TixoCloud.com`
