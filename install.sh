#!/usr/bin/env bash

# =============================================================================
# Oh My Zsh + Powerlevel10k installer
# Targets: Ubuntu/Debian
# Installs: zsh, oh-my-zsh, zsh-autosuggestions, zsh-syntax-highlighting, p10k
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
	echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1" >&2
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_USER="${USER:-$(id -un)}"
P10K_URL_DEFAULT="https://raw.githubusercontent.com/hnrobert/hnrobert-omz-installer/main/.p10k.zsh"
P10K_URL="${P10K_URL:-$P10K_URL_DEFAULT}"

check_root() {
	if [ "$EUID" -eq 0 ]; then
		log_warning "Running as root; sudo will be skipped."
		SUDO=""
		USER_HOME="/root"
	else
		SUDO="sudo"
		USER_HOME="$HOME"
	fi
}

install_dependencies() {
	log_info "Updating package index..."
	$SUDO apt-get update -y

	log_info "Installing dependencies (zsh, git, curl, wget, fonts)..."
	$SUDO apt-get install -y \
		zsh \
		git \
		curl \
		wget \
		fontconfig \
		locales

	$SUDO locale-gen en_US.UTF-8 || true
	log_success "Dependencies installed."
}

install_oh_my_zsh() {
	if [ -d "$USER_HOME/.oh-my-zsh" ]; then
		log_warning "Oh My Zsh already present; skipping."
		return
	fi

	log_info "Installing Oh My Zsh (unattended)..."
	RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	log_success "Oh My Zsh installed."
}

install_zsh_autosuggestions() {
	local plugin_dir="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
	if [ -d "$plugin_dir" ]; then
		log_warning "zsh-autosuggestions already present; skipping."
		return
	fi

	log_info "Installing zsh-autosuggestions..."
	git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"
	log_success "zsh-autosuggestions installed."
}

install_zsh_syntax_highlighting() {
	local plugin_dir="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
	if [ -d "$plugin_dir" ]; then
		log_warning "zsh-syntax-highlighting already present; skipping."
		return
	fi

	log_info "Installing zsh-syntax-highlighting..."
	git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugin_dir"
	log_success "zsh-syntax-highlighting installed."
}

install_powerlevel10k() {
	local theme_dir="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
	if [ -d "$theme_dir" ]; then
		log_warning "Powerlevel10k already present; skipping."
		return
	fi

	log_info "Installing Powerlevel10k theme..."
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
	log_success "Powerlevel10k installed."
}

configure_zshrc() {
	log_info "Configuring .zshrc..."
	local zshrc="$USER_HOME/.zshrc"

	if [ -f "$zshrc" ]; then
		cp "$zshrc" "$zshrc.backup.$(date +%Y%m%d%H%M%S)"
		log_info "Backed up existing .zshrc."
	fi

	# Ensure base file exists
	touch "$zshrc"

	# Disable Oh My Zsh auto-updates to avoid background prompts
	if grep -q "^DISABLE_AUTO_UPDATE=" "$zshrc"; then
		sed -i 's|^DISABLE_AUTO_UPDATE=.*|DISABLE_AUTO_UPDATE="true"|' "$zshrc"
	else
		echo 'DISABLE_AUTO_UPDATE="true"' >>"$zshrc"
	fi

	if grep -q "^DISABLE_UPDATE_PROMPT=" "$zshrc"; then
		sed -i 's|^DISABLE_UPDATE_PROMPT=.*|DISABLE_UPDATE_PROMPT="true"|' "$zshrc"
	else
		echo 'DISABLE_UPDATE_PROMPT="true"' >>"$zshrc"
	fi

	if grep -q "^ZSH_THEME=" "$zshrc"; then
		sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$zshrc"
	else
		echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >>"$zshrc"
	fi

	if grep -q "^plugins=" "$zshrc"; then
		sed -i 's|^plugins=.*|plugins=(git zsh-autosuggestions zsh-syntax-highlighting)|' "$zshrc"
	else
		echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >>"$zshrc"
	fi

	if ! grep -q "source .*\.p10k\.zsh" "$zshrc"; then
		cat >>"$zshrc" <<'EOF'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF
	fi

	log_success ".zshrc configured."
}

copy_p10k_config() {
	local source_config="$SCRIPT_DIR/.p10k.zsh"
	local target_config="$USER_HOME/.p10k.zsh"

	if [ -f "$source_config" ]; then
		log_info "Copying .p10k.zsh to home..."
		cp "$source_config" "$target_config"
		log_success "Copied to $target_config"
		return
	fi

	log_warning ".p10k.zsh not found locally; downloading..."
	if curl -fsSL "$P10K_URL" -o "$target_config"; then
		log_success "Downloaded .p10k.zsh to $target_config"
	else
		log_warning "Failed to download .p10k.zsh from $P10K_URL"
	fi
}

set_default_shell() {
	log_info "Setting zsh as default login shell..."
	local zsh_path
	zsh_path="$(command -v zsh || true)"

	if [ -z "$zsh_path" ]; then
		log_error "zsh not found in PATH; cannot switch shell."
		return
	fi

	local current_shell
	current_shell="$(getent passwd "$CURRENT_USER" | cut -d: -f7)"

	if [ "$current_shell" = "$zsh_path" ]; then
		log_warning "zsh is already the default shell."
		return
	fi

	if $SUDO -n chsh -s "$zsh_path" "$CURRENT_USER" 2>/dev/null; then
		log_success "Default shell updated to zsh."
	else
		log_warning "Failed to change default shell automatically. Run: sudo chsh -s $(which zsh) $CURRENT_USER"
	fi
}

font_reminder() {
	log_info "================ Font recommendation ================"
	log_info "For best glyphs, install a Nerd Font (e.g., MesloLGS NF)."
	log_info "See: https://github.com/romkatv/powerlevel10k#fonts"
	log_info "====================================================="
}

prompt_reboot() {
	if [ -f /.dockerenv ]; then
		log_info "Container detected; skipping reboot prompt."
		return
	fi

	echo ""
	read -r -p "Do you want to reboot now to apply the login shell change? [y/N] " reply
	case "$reply" in
	[yY][eE][sS] | [yY])
		log_info "Rebooting..."
		$SUDO reboot || log_warning "Reboot failed; please reboot manually."
		;;
	*)
		log_info "Skipping reboot. You can run 'exec zsh' or log out/in manually."
		;;
	esac
}

main() {
	echo ""
	echo "=============================================="
	echo "   Oh My Zsh + Powerlevel10k installer"
	echo "=============================================="
	echo ""

	check_root
	install_dependencies
	install_oh_my_zsh
	install_zsh_autosuggestions
	install_zsh_syntax_highlighting
	install_powerlevel10k
	configure_zshrc
	copy_p10k_config
	set_default_shell
	# font_reminder

	echo ""
	log_success "All done."
	log_info "Launch zsh with 'exec zsh' or open a new terminal."
	prompt_reboot
}

main "$@"
