# hnrobert-omz-installer

Automated installer for Zsh + Oh My Zsh + zsh-autosuggestions + zsh-syntax-highlighting + Powerlevel10k using the included `.p10k.zsh` theme.

## What it does

- Installs dependencies (zsh, git, curl, wget, fonts, locales)
- Installs Oh My Zsh (unattended) **with auto-update disabled**
- Installs plugins: zsh-autosuggestions, zsh-syntax-highlighting
- Installs Powerlevel10k theme and copies the provided `.p10k.zsh` to your home
- Updates `~/.zshrc` to use the theme and plugins (also sets `DISABLE_AUTO_UPDATE` and `DISABLE_UPDATE_PROMPT`)
- Switches your default login shell to `zsh`
- Prompts to reboot (skipped automatically inside containers)

## Usage on a host (Ubuntu/Debian) - One command install

> Make sure you are connected to the internet where `raw.githubusercontent.com` is reachable.

```bash
# Copy this and paste in your bash, and run it, and the installation will run automatically
curl -fsSL https://raw.githubusercontent.com/hnrobert/hnrobert-omz-installer/main/install.sh | bash
```

The script installs needed dependencies (git, curl, etc.) if they are missing. You can also run `exec zsh` or open a new terminal session.

You do not need to clone the repo, it will fetch the required `.p10k.zsh` automatically.

## Test inside a container (Ubuntu 22.04)

The compose file uses upstream `ubuntu:22.04`, creates non-root user `dev`, installs `sudo`, and runs the installer as `dev`. The container then idles.

Start and view logs:

```bash
docker-compose up -d && docker-compose logs -f
```

When the instruction `[SUCCESS] All done.` appears and the container idles, you may attach to zsh as `dev` and start trying it out:

```bash
docker-compose exec --user dev hnrobert-omz-installer-test zsh
```

To stop and clean up:

```bash
docker-compose down
```
