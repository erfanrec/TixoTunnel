# TixoTunnel

Branded Bash installation and management panel for the TixoTunnel core.

- Telegram: `@TixoCloud`
- Website: `TixoCloud.com`

## Repository preparation

Replace `YOUR_GITHUB_USERNAME/TixoTunnel` in both `install.sh` and `TixoTunnel.sh` with the real GitHub repository path.

Upload these files to the repository root:

- `TixoTunnel.sh`
- `install.sh`

Upload `tixotunnel-core` as an asset named exactly `tixotunnel-core` in a GitHub Release. Avoid committing the binary directly when possible.

## One-line installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/TixoTunnel/main/install.sh)
```

The installer automatically:

1. Creates `/root/tixotunnel-core`.
2. Downloads the panel and core.
3. Applies permission `0755`.
4. Installs the `tixotunnel` command.
5. Opens the panel.

## Notes

Renaming the executable does not modify branding strings compiled inside the binary. Full binary rebranding requires its source code and permission to rebuild/distribute it.
