#!/usr/bin/env bash
# =============================================================================
#  dotfiles/setup.sh  —  Anirudh's one-shot machine bootstrapper
#
#  Sets up a fresh macOS or Linux box (with or without sudo) the way I like it:
#  core CLI tools, neovim + LSPs/treesitter, claude/gh/uv, ghostty, herdr, and
#  my shell + configs (symlinked from ~/dotfiles, stow-style).
#
#  Usage:
#     git clone https://github.com/AnirudhG07/my_configs ~/dotfiles
#     bash ~/dotfiles/setup.sh                 # interactive
#     bash ~/dotfiles/setup.sh --all           # install everything, no prompts
#     bash ~/dotfiles/setup.sh --only core,nvim,shell
#     bash ~/dotfiles/setup.sh --dry-run       # show what would happen
#
#  Or straight from the internet:
#     curl -fsSL https://raw.githubusercontent.com/AnirudhG07/my_configs/stow/setup.sh | bash
#
#  Safe to re-run: every step is idempotent.
# =============================================================================

set -uo pipefail

# ------------------------------------------------------------------ constants
REPO_URL="https://github.com/AnirudhG07/my_configs"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
LOCAL_PREFIX="$HOME/.local"
LOCAL_BIN="$LOCAL_PREFIX/bin"
MAC_BRANCH="stow"      # macOS + zsh configs live here (also the default trunk)
LINUX_BRANCH="ugcl"    # linux bash config lives here

DRY_RUN=0
ASSUME_ALL=0
ONLY_MODULES=""

# ---------------------------------------------------------------------- colors
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RST=$'\033[0m'; C_B=$'\033[1m'; C_DIM=$'\033[2m'
  C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'
  C_BLU=$'\033[34m'; C_MAG=$'\033[35m'; C_CYN=$'\033[36m'
else
  C_RST=; C_B=; C_DIM=; C_RED=; C_GRN=; C_YEL=; C_BLU=; C_MAG=; C_CYN=
fi

step()  { printf '\n%s\n' "${C_B}${C_MAG}==>${C_RST} ${C_B}$*${C_RST}"; }
info()  { printf '%s %s\n' "${C_BLU}·${C_RST}" "$*"; }
ok()    { printf '%s %s\n' "${C_GRN}✓${C_RST}" "$*"; }
warn()  { printf '%s %s\n' "${C_YEL}!${C_RST}" "$*" >&2; }
err()   { printf '%s %s\n' "${C_RED}✗${C_RST}" "$*" >&2; }
die()   { err "$*"; exit 1; }

has()   { command -v "$1" >/dev/null 2>&1; }

# run a command, honoring --dry-run
run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '%s %s\n' "${C_DIM}[dry-run]${C_RST}" "$*"
    return 0
  fi
  "$@"
}

confirm() {
  # confirm "question" [default_yes]  -> returns 0 for yes
  local q="$1" def="${2:-y}" ans
  [ "$ASSUME_ALL" = 1 ] && return 0
  if [ ! -t 0 ]; then return 0; fi   # non-interactive: assume yes
  if [ "$def" = y ]; then q="$q [Y/n] "; else q="$q [y/N] "; fi
  printf '%s' "${C_CYN}?${C_RST} $q" >&2
  read -r ans || true
  ans="${ans:-$def}"
  case "$ans" in [Yy]*) return 0;; *) return 1;; esac
}

# ============================================================================
#  Environment detection
# ============================================================================
OS=""; ARCH=""; DISTRO=""; PKG=""; PKG_UPDATE=""; HAVE_SUDO=0; SUDO=""
BREW=""; SHELL_TARGET=""

detect_env() {
  step "Detecting environment"

  case "$(uname -s)" in
    Darwin) OS=mac ;;
    Linux)  OS=linux ;;
    *) die "Unsupported OS: $(uname -s)";;
  esac

  case "$(uname -m)" in
    x86_64|amd64) ARCH=x86_64 ;;
    arm64|aarch64) ARCH=arm64 ;;
    *) ARCH="$(uname -m)" ;;
  esac

  # sudo?
  if [ "$(id -u)" = 0 ]; then
    HAVE_SUDO=1; SUDO=""
  elif has sudo && sudo -n true 2>/dev/null; then
    HAVE_SUDO=1; SUDO="sudo"
  elif has sudo && [ -t 0 ] && [ "$ASSUME_ALL" != 1 ]; then
    # sudo exists but needs a password — ask once whether we may use it
    if confirm "sudo is available. Use it for system package installs?" y; then
      if sudo -v 2>/dev/null; then HAVE_SUDO=1; SUDO="sudo"; fi
    fi
  fi

  # linux distro / package manager
  if [ "$OS" = linux ]; then
    [ -r /etc/os-release ] && . /etc/os-release && DISTRO="${ID:-linux}"
    if   has apt-get; then PKG=apt;    PKG_UPDATE="$SUDO apt-get update -y"
    elif has dnf;     then PKG=dnf;    PKG_UPDATE=":"
    elif has pacman;  then PKG=pacman; PKG_UPDATE="$SUDO pacman -Sy"
    elif has zypper;  then PKG=zypper; PKG_UPDATE="$SUDO zypper refresh"
    elif has apk;     then PKG=apk;    PKG_UPDATE="$SUDO apk update"
    fi
  fi

  # brew?
  if has brew; then BREW="$(command -v brew)"
  elif [ -x /opt/homebrew/bin/brew ]; then BREW=/opt/homebrew/bin/brew
  elif [ -x /usr/local/bin/brew ]; then BREW=/usr/local/bin/brew
  elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then BREW=/home/linuxbrew/.linuxbrew/bin/brew
  elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then BREW="$HOME/.linuxbrew/bin/brew"
  fi
  [ -n "$BREW" ] && eval "$("$BREW" shellenv)" 2>/dev/null || true

  # which shell do we want as the login shell?
  #   mac            -> zsh
  #   linux + sudo   -> zsh
  #   linux, no sudo -> bash
  if [ "$OS" = mac ] || [ "$HAVE_SUDO" = 1 ]; then
    SHELL_TARGET=zsh
  else
    SHELL_TARGET=bash
  fi

  mkdir -p "$LOCAL_BIN"
  case ":$PATH:" in *":$LOCAL_BIN:"*) ;; *) export PATH="$LOCAL_BIN:$PATH";; esac

  ok "OS=$OS  arch=$ARCH  distro=${DISTRO:-n/a}  pkg=${PKG:-n/a}  sudo=$([ $HAVE_SUDO = 1 ] && echo yes || echo no)  brew=$([ -n "$BREW" ] && echo yes || echo no)  shell=$SHELL_TARGET"
}

# ============================================================================
#  Backend installers
# ============================================================================

ensure_brew() {
  [ -n "$BREW" ] && return 0
  step "Installing Homebrew"
  if [ "$OS" = mac ]; then
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null || return 1
  else
    # Linuxbrew. Official installer wants /home/linuxbrew (needs sudo). If we
    # can't sudo, fall back to a home-dir git checkout — still fully usable.
    if [ "$HAVE_SUDO" = 1 ]; then
      run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null || return 1
    else
      warn "No sudo: installing Homebrew into ~/.linuxbrew (no root needed)"
      run git clone --depth=1 https://github.com/Homebrew/brew "$HOME/.linuxbrew" || return 1
    fi
  fi
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew \
           /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    [ -x "$b" ] && BREW="$b" && break
  done
  [ -n "$BREW" ] || { has brew && BREW="$(command -v brew)"; }
  [ -n "$BREW" ] && eval "$("$BREW" shellenv)" && ok "Homebrew ready" || { err "Homebrew install failed"; return 1; }
}

ensure_uv() {
  has uv && return 0
  step "Installing uv"
  run sh -c "curl -LsSf https://astral.sh/uv/install.sh | sh" || return 1
  export PATH="$HOME/.local/bin:$PATH"
  has uv && ok "uv ready"
}

# eget prompts when several release assets match. Build --asset filters so
# exactly one remains: drop installer packages, and pick glibc vs musl by distro.
EGET_FILTERS=()
_build_eget_filters() {
  EGET_FILTERS=(--asset ^.deb --asset ^.rpm --asset ^.msi --asset ^.apk)
  if [ "$OS" = linux ]; then
    if [ "${DISTRO:-}" = alpine ] || [ "$PKG" = apk ]; then
      EGET_FILTERS+=(--asset musl)      # musl libc systems (Alpine)
    else
      EGET_FILTERS+=(--asset ^musl)     # glibc systems (Ubuntu/Debian/Fedora/Arch)
    fi
  fi
}

ensure_eget() {
  has eget && return 0
  # eget grabs binaries straight from GitHub releases — our best no-sudo path
  if ensure_uv && run uv tool install eget-py >/dev/null 2>&1 && has eget; then
    ok "eget ready (via uv)"; return 0
  fi
  step "Installing eget"
  run sh -c "curl -fsSL https://zyedidia.github.io/eget.sh | sh" && run mv -f ./eget "$LOCAL_BIN/" 2>/dev/null
  has eget && ok "eget ready"
}

ensure_cargo() {
  has cargo && return 0
  if [ -n "$BREW" ] && run "$BREW" install rustup-init 2>/dev/null; then :; fi
  has rustup && ! has cargo && run rustup default stable
  has cargo && return 0
  step "Installing Rust toolchain (rustup)"
  run sh -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path" || return 1
  [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
  has cargo && ok "cargo ready"
}

# node manager: nvm (as requested), with brew/apt/fnm as fallback
ensure_nvm() {
  export NVM_DIR="$HOME/.nvm"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    step "Installing nvm"
    # PROFILE=/dev/null so nvm's installer doesn't append to our (symlinked) rc
    run env PROFILE=/dev/null sh -c \
      'curl -fsSL -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash' </dev/null \
      || warn "nvm install failed"
  fi
  # shellcheck disable=SC1090
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" 2>/dev/null || true
  if command -v nvm >/dev/null 2>&1; then
    ok "nvm ready"
    if ! has node; then
      info "nvm install --lts"
      run nvm install --lts >/dev/null 2>&1 && run nvm alias default 'lts/*' >/dev/null 2>&1
    fi
  fi
  has node || _ensure_node_fallback
  has node && ok "node $(node -v 2>/dev/null) / npm $(npm -v 2>/dev/null)" \
           || warn "node unavailable (some LSPs may not work)"
}

_ensure_node_fallback() {
  has node && return 0
  if [ -n "$BREW" ]; then run "$BREW" install node && has node && return 0; fi
  if [ "$PKG" = apt ] && [ "$HAVE_SUDO" = 1 ]; then
    run $SUDO apt-get install -y nodejs npm && has node && return 0
  fi
  info "Installing Node via fnm (fallback)"
  ensure_eget && run eget Schniz/fnm --to "$LOCAL_BIN" 2>/dev/null
  if has fnm; then
    eval "$(fnm env 2>/dev/null)" || true
    run fnm install --lts && run fnm default lts-latest
    eval "$(fnm env 2>/dev/null)" || true
  fi
}

ensure_node() { has node && has npm && return 0; ensure_nvm; }

ensure_python() {
  if has python3; then ok "python present ($(python3 -V 2>&1))"; return 0; fi
  if [ -n "$BREW" ] && run "$BREW" install python && has python3; then ok "python (brew)"; return 0; fi
  if [ -n "$PKG" ] && [ "$HAVE_SUDO" = 1 ]; then
    case "$PKG" in
      apt) pkg_install python3 && pkg_install python3-pip && pkg_install python3-venv ;;
      *)   pkg_install python3 ;;
    esac
    has python3 && { ok "python3 ($PKG)"; return 0; }
  fi
  # no-sudo: uv-managed standalone CPython, with python/python3 shims on PATH
  if ensure_uv; then
    run uv python install --default 2>/dev/null || run uv python install
    has python3 && { ok "python via uv"; return 0; }
  fi
  warn "Could not install python"
}

# MesloLGS Nerd Font — glyphs powerlevel10k / yazi / ghostty expect. Installed
# on both OSes: cask on mac, user font dir + fc-cache on linux.
install_nerd_font() {
  step "MesloLGS Nerd Font"
  if fc-list 2>/dev/null | grep -qiE "MesloLGS|Meslo.*Nerd"; then ok "Meslo Nerd Font already present"; return 0; fi
  if [ "$OS" = mac ]; then
    ensure_brew && run "$BREW" install --cask font-meslo-lg-nerd-font && ok "Meslo Nerd Font (brew cask)" \
      || warn "font install failed"
    return 0
  fi
  local fdir="$HOME/.local/share/fonts"
  run mkdir -p "$fdir"
  if run sh -c "curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip -o /tmp/Meslo.zip"; then
    if has unzip; then
      run sh -c "unzip -o /tmp/Meslo.zip -d '$fdir' >/dev/null"
    elif has python3; then
      run python3 -m zipfile -e /tmp/Meslo.zip "$fdir"
    else
      warn "no unzip/python3 to extract font"; return 1
    fi
    has fc-cache && run fc-cache -f "$fdir" >/dev/null 2>&1
    ok "Meslo Nerd Font installed to $fdir"
  else
    warn "Meslo font download failed"
  fi
}

# Run the target shell once, non-interactively, so its first-run setup completes
# now instead of on the user's first prompt: zinit clones plugins + builds
# powerlevel10k (zsh); oh-my-bash is already in place (bash).
warm_shell() {
  [ "$DRY_RUN" = 1 ] && { info "(dry-run) would warm up $SHELL_TARGET"; return 0; }
  if [ "$SHELL_TARGET" = zsh ] && has zsh; then
    info "Warming up zsh (zinit fetches plugins + powerlevel10k)…"
    zsh -i -c 'exit' >/dev/null 2>&1 || true
    ok "zsh ready"
  elif [ "$SHELL_TARGET" = bash ] && has bash; then
    info "Warming up bash (oh-my-bash)…"
    bash -i -c 'exit' >/dev/null 2>&1 || true
    ok "bash ready"
  fi
}

# Final step: drop the user into their fully configured shell (interactive only).
maybe_exec_shell() {
  [ "$DRY_RUN" = 1 ] && return 0
  [ -t 1 ] && [ -t 0 ] || return 0
  has "$SHELL_TARGET" || return 0
  printf '\n%s Launching %s — everything is set. (type %sexit%s to leave)\n' \
    "${C_GRN}▶${C_RST}" "${C_B}$SHELL_TARGET${C_RST}" "$C_B" "$C_RST"
  exec "$SHELL_TARGET" -i
}

# native package install (needs sudo)
pkg_install() {
  [ -z "$PKG" ] && return 1
  local p="$1"
  case "$PKG" in
    apt)    run $SUDO apt-get install -y "$p" ;;
    dnf)    run $SUDO dnf install -y "$p" ;;
    pacman) run $SUDO pacman -S --noconfirm --needed "$p" ;;
    zypper) run $SUDO zypper install -y "$p" ;;
    apk)    run $SUDO apk add "$p" ;;
    *) return 1 ;;
  esac
}

# ----------------------------------------------------------------------------
# install_tool BIN  key=val ...
#   keys: brew=<formula> apt=<pkg> dnf=<pkg> pacman=<pkg> zypper=<pkg>
#         uv=<pypkg> eget=<owner/repo> cargo=<crate> npm=<pkg>
# Tries backends in an OS/sudo-appropriate order, stops at first success.
# ----------------------------------------------------------------------------
_recipe_get() { # _recipe_get key "key=val" ...
  local want="$1"; shift
  local kv
  for kv in "$@"; do
    case "$kv" in "$want="*) printf '%s' "${kv#*=}"; return 0;; esac
  done
  return 1
}

install_tool() {
  local bin="$1"; shift
  if has "$bin"; then ok "$bin already installed"; return 0; fi

  local order arg
  if [ "$OS" = mac ]; then
    order="brew uv eget cargo npm"
  elif [ "$HAVE_SUDO" = 1 ]; then
    order="native brew uv eget cargo npm"
  else
    order="brew uv eget cargo npm native"
  fi

  local b
  for b in $order; do
    case "$b" in
      brew)
        [ -n "$BREW" ] || continue
        arg="$(_recipe_get brew "$@")" || continue
        info "brew install $arg"
        run "$BREW" install $arg && has "$bin" && { ok "$bin (brew)"; return 0; }
        ;;
      native)
        [ -n "$PKG" ] && [ "$HAVE_SUDO" = 1 ] || continue
        arg="$(_recipe_get "$PKG" "$@")" || continue
        info "$PKG install $arg"
        pkg_install "$arg" && has "$bin" && { ok "$bin ($PKG)"; return 0; }
        ;;
      uv)
        arg="$(_recipe_get uv "$@")" || continue
        ensure_uv || continue
        info "uv tool install $arg"
        run uv tool install "$arg" && has "$bin" && { ok "$bin (uv)"; return 0; }
        ;;
      eget)
        arg="$(_recipe_get eget "$@")" || continue
        ensure_eget || continue
        # recipe may be "owner/repo" or "owner/repo|filter1|filter2" (extra --asset hints)
        local repo="${arg%%|*}" extra=""
        case "$arg" in *"|"*) extra="${arg#*|}"; extra="${extra//|/ }";; esac
        _build_eget_filters
        info "eget $repo ${EGET_FILTERS[*]} $extra"
        # shellcheck disable=SC2086
        run eget "$repo" "${EGET_FILTERS[@]}" $extra --to "$LOCAL_BIN" && has "$bin" && { ok "$bin (eget)"; return 0; }
        ;;
      cargo)
        arg="$(_recipe_get cargo "$@")" || continue
        ensure_cargo || continue
        info "cargo install $arg"
        run cargo install "$arg" && has "$bin" && { ok "$bin (cargo)"; return 0; }
        ;;
      npm)
        arg="$(_recipe_get npm "$@")" || continue
        ensure_node || continue
        info "npm install -g $arg"
        run npm install -g "$arg" && has "$bin" && { ok "$bin (npm)"; return 0; }
        ;;
    esac
  done
  warn "Could not install '$bin' with available backends"
  return 1
}

# some distros name the binary differently; expose the canonical name
link_alias() { # link_alias real wanted
  local real="$1" want="$2"
  has "$want" && return 0
  if has "$real"; then
    run ln -sfn "$(command -v "$real")" "$LOCAL_BIN/$want" && ok "linked $want -> $real"
  fi
}

# ============================================================================
#  Dotfiles repo
# ============================================================================
setup_dotfiles_repo() {
  step "Dotfiles repository"
  # If this script already lives inside a clone, use that.
  local self_dir
  self_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)" 2>/dev/null || self_dir=""
  if [ -n "$self_dir" ] && git -C "$self_dir" rev-parse --show-toplevel >/dev/null 2>&1; then
    DOTFILES_DIR="$(git -C "$self_dir" rev-parse --show-toplevel)"
    ok "Using existing clone at $DOTFILES_DIR"
  elif [ -d "$DOTFILES_DIR/.git" ]; then
    ok "Found $DOTFILES_DIR"
    run git -C "$DOTFILES_DIR" pull --ff-only 2>/dev/null || warn "pull skipped"
  else
    info "Cloning $REPO_URL -> $DOTFILES_DIR"
    run git clone "$REPO_URL" "$DOTFILES_DIR" || die "clone failed"
  fi

  # make sure both branches' trees are available for cross-branch file grabs
  run git -C "$DOTFILES_DIR" fetch --quiet origin "$MAC_BRANCH" "$LINUX_BRANCH" 2>/dev/null || true
}

# ============================================================================
#  stow / symlink deployment
# ============================================================================

# manually symlink one package dir (stow fallback), file-by-file
manual_stow() {
  local pkg="$1" src="$DOTFILES_DIR/$1"
  [ -d "$src" ] || { warn "package '$pkg' not found, skipping"; return 0; }
  ( cd "$src" && find . \( -type f -o -type l \) -print ) | while IFS= read -r rel; do
    rel="${rel#./}"
    local dest="$HOME/$rel"
    run mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      run cp -n "$dest" "$dest.pre-dotfiles.bak" 2>/dev/null || true
    fi
    run ln -sfn "$src/$rel" "$dest"
  done
  ok "linked $pkg"
}

deploy_packages() {
  local pkgs="$*"
  if has stow; then
    step "Deploying configs with stow: $pkgs"
    # --adopt would move existing files into the repo; we instead back up + link.
    for p in $pkgs; do
      [ -d "$DOTFILES_DIR/$p" ] || { warn "no package '$p'"; continue; }
      if ! run stow -d "$DOTFILES_DIR" -t "$HOME" --restow "$p" 2>/dev/null; then
        warn "stow failed for '$p', using manual symlink"
        manual_stow "$p"
      fi
    done
  else
    step "Deploying configs (manual symlink — stow not available): $pkgs"
    for p in $pkgs; do manual_stow "$p"; done
  fi
}

# ============================================================================
#  MODULES
# ============================================================================

module_core() {
  step "Core CLI tools"
  [ -n "$PKG_UPDATE" ] && [ "$HAVE_SUDO" = 1 ] && run sh -c "$PKG_UPDATE" 2>/dev/null || true

  install_tool fzf      brew=fzf      apt=fzf      dnf=fzf      pacman=fzf      zypper=fzf      uv=fzf-bin        eget=junegunn/fzf
  install_tool rg       brew=ripgrep  apt=ripgrep  dnf=ripgrep  pacman=ripgrep  zypper=ripgrep  uv=ripgrep-bin    eget=BurntSushi/ripgrep    cargo=ripgrep
  install_tool jq       brew=jq       apt=jq       dnf=jq       pacman=jq       zypper=jq       eget=jqlang/jq
  install_tool lazygit  brew=lazygit  pacman=lazygit                                            uv=lazygit-py     eget=jesseduffield/lazygit
  install_tool yazi     brew=yazi     pacman=yazi                                               uv=yazi-bin       eget=sxyazi/yazi
  install_tool zoxide   brew=zoxide   apt=zoxide   dnf=zoxide   pacman=zoxide                   eget=ajeetdsouza/zoxide  cargo=zoxide
  install_tool delta    brew=git-delta pacman=git-delta                                         eget=dandavison/delta    cargo=git-delta
  install_tool bat      brew=bat      apt=bat      dnf=bat      pacman=bat      zypper=bat      eget=sharkdp/bat  cargo=bat
  install_tool fd       brew=fd       apt=fd-find  dnf=fd-find  pacman=fd       zypper=fd       eget=sharkdp/fd   cargo=fd-find
  install_tool eza      brew=eza      pacman=eza                                                eget=eza-community/eza   cargo=eza
  install_tool tldr     brew=tealdeer pacman=tealdeer                                           'eget=tldr-pages/tlrc|--file|tldr'  cargo=tealdeer

  # binary-name fixups for distro packages
  link_alias fdfind fd
  link_alias batcat bat

  # GNU stow (needs perl; nice-to-have — manual symlink covers us otherwise)
  install_tool stow brew=stow apt=stow dnf=stow pacman=stow zypper=stow || \
    warn "stow unavailable — will symlink manually"
}

module_dev() {
  step "Dev tooling: uv, python, node/nvm, gh, claude"
  ensure_uv
  ensure_python
  ensure_nvm

  install_tool gh brew=gh apt=gh dnf=gh pacman=github-cli eget=cli/cli

  # Claude Code — official installer, npm fallback
  if has claude; then ok "claude already installed"
  else
    run sh -c "curl -fsSL https://claude.ai/install.sh | bash" </dev/null || {
      ensure_node && run npm install -g @anthropic-ai/claude-code
    }
    has claude && ok "claude ready (alias: cr = claude -r)" || warn "claude install failed"
  fi
}

module_nvim() {
  step "Neovim + treesitter + LSPs"

  # 1) Neovim itself — apt ships ancient versions, so grab the official build.
  if has nvim; then ok "neovim already installed"
  elif [ "$OS" = mac ] && { ensure_brew && run "$BREW" install neovim; }; then ok "neovim (brew)"
  else
    info "Fetching official Neovim build"
    local nv_asset
    if [ "$ARCH" = arm64 ]; then nv_asset="nvim-linux-arm64"; else nv_asset="nvim-linux-x86_64"; fi
    local url="https://github.com/neovim/neovim/releases/latest/download/${nv_asset}.tar.gz"
    run sh -c "curl -fsSL '$url' -o /tmp/nvim.tar.gz && rm -rf '$LOCAL_PREFIX/nvim' && mkdir -p '$LOCAL_PREFIX/nvim' && tar -xzf /tmp/nvim.tar.gz -C '$LOCAL_PREFIX/nvim' --strip-components=1" \
      && run ln -sfn "$LOCAL_PREFIX/nvim/bin/nvim" "$LOCAL_BIN/nvim" \
      && ok "neovim ($LOCAL_PREFIX/nvim)" || warn "neovim install failed"
  fi

  # 2) Build prerequisites the config's treesitter `main` branch needs:
  #    a C compiler + tree-sitter CLI, plus node for many LSP servers.
  step "Neovim build deps (C compiler, tree-sitter CLI, node)"
  if ! has cc && ! has gcc && ! has clang; then
    if [ "$OS" = mac ]; then
      xcode-select -p >/dev/null 2>&1 || run xcode-select --install || true
    elif [ "$HAVE_SUDO" = 1 ]; then
      case "$PKG" in
        apt)    pkg_install build-essential ;;
        dnf)    run $SUDO dnf groupinstall -y "Development Tools" || pkg_install gcc ;;
        pacman) pkg_install base-devel ;;
        *)      pkg_install gcc ;;
      esac
    elif [ -n "$BREW" ]; then run "$BREW" install gcc; fi
  fi
  install_tool tree-sitter brew=tree-sitter pacman=tree-sitter-cli npm=tree-sitter-cli cargo=tree-sitter-cli 'eget=tree-sitter/tree-sitter|--asset|.gz'
  ensure_node

  # 3) LSP toolchains that must exist system-wide (mason installs the rest):
  #    python, lean, C/C++, lua, markdown.
  step "LSP toolchains (python, lean, C/C++, lua, markdown)"

  # python: ruff + pyright (mason also manages ruff/ty; we make sure ruff+node exist)
  ensure_uv && run uv tool install ruff >/dev/null 2>&1 && ok "ruff (uv)" || true

  # lean: elan toolchain manager (installs lean/lake; lean.nvim uses its LSP)
  if has lean || has elan; then ok "lean/elan present"
  elif [ -n "$BREW" ] && run "$BREW" install elan-init 2>/dev/null && has elan; then ok "elan (brew)"
  else
    info "Installing elan (Lean toolchain)"
    run sh -c "curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y --default-toolchain stable" </dev/null \
      && ok "elan ready" || warn "elan install failed"
  fi
  [ -f "$HOME/.elan/env" ] && . "$HOME/.elan/env" 2>/dev/null || true

  # C/C++: clangd
  install_tool clangd brew=llvm apt=clangd dnf=clang-tools-extra pacman=clang eget=clangd/clangd || true

  # lua_ls & marksman are installed by mason on first launch (see below).

  # 4) First-launch sync: lazy.nvim plugins, treesitter parsers, mason tools.
  if has nvim && [ "$DRY_RUN" != 1 ]; then
    step "Bootstrapping Neovim (plugins, parsers, LSP servers) — headless"
    info "This compiles treesitter parsers; give it a minute..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Lazy sync had issues (open nvim to finish)"
    nvim --headless "+TSUpdateSync" +qa 2>/dev/null || true
    nvim --headless "+MasonToolsInstallSync" +qa 2>/dev/null || true
    nvim --headless "+MasonInstall lua-language-server marksman" +qa 2>/dev/null || true
    ok "Neovim bootstrapped"
  else
    info "Open nvim once to let lazy.nvim + mason finish installing."
  fi
}

module_ghostty() {
  step "Ghostty (config + terminfo)"
  # On a remote server we usually only need Ghostty's terminfo so keys/colors
  # work; the GUI app itself we install only on macOS.
  if [ "$OS" = mac ]; then
    if [ -d "/Applications/Ghostty.app" ] || has ghostty; then ok "Ghostty app present"
    elif confirm "Install Ghostty.app (cask)?" y; then
      ensure_brew && run "$BREW" install --cask ghostty || true
    fi
  else
    # ensure xterm-ghostty terminfo exists so SSH sessions render correctly
    if infocmp xterm-ghostty >/dev/null 2>&1; then
      ok "ghostty terminfo present"
    else
      info "Installing xterm-ghostty terminfo"
      run sh -c 'curl -fsSL https://raw.githubusercontent.com/ghostty-org/ghostty/main/src/terminfo/ghostty.terminfo -o /tmp/ghostty.terminfo && tic -x -o "$HOME/.terminfo" /tmp/ghostty.terminfo' \
        && ok "ghostty terminfo installed" || warn "terminfo install failed (set TERM=xterm-256color as a fallback)"
    fi
  fi
  deploy_packages ghostty
}

module_herdr() {
  step "Herdr (agent/pane multiplexer)  — alias: h"
  if has herdr; then ok "herdr already installed"
  elif [ -n "$BREW" ] && run "$BREW" install herdr && has herdr; then ok "herdr (brew)"
  elif { ensure_cargo && run cargo install herdr; } && has herdr; then ok "herdr (cargo)"
  else
    run sh -c "curl -fsSL https://herdr.dev/install.sh | sh" </dev/null
    has herdr && ok "herdr ready" || warn "herdr install failed"
  fi
  deploy_packages herdr
}

# write a small machine-local file the rc sources: brew env, PATH, portable aliases
write_shell_local() {
  local target="$1"   # $HOME/.zshrc.local or $HOME/.bashrc.local
  local shname="$2"   # zsh | bash
  [ "$DRY_RUN" = 1 ] && { info "[dry-run] would write $target"; return 0; }
  local brew_line=""
  [ -n "$BREW" ] && brew_line="eval \"\$($BREW shellenv)\""
  cat > "$target" <<EOF
# ---- managed by dotfiles/setup.sh : machine-local shell setup ----
$brew_line
# prepend user bin dirs, but only if not already present (no duplicates on nested shells)
for d in "\$HOME/.local/bin" "\$HOME/go/bin"; do
  case ":\$PATH:" in *":\$d:"*) ;; *) [ -d "\$d" ] && PATH="\$d:\$PATH";; esac
done
export PATH
[ -f "\$HOME/.cargo/env" ] && . "\$HOME/.cargo/env"
[ -f "\$HOME/.elan/env" ]  && . "\$HOME/.elan/env"
# node via nvm (fnm as fallback)
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && . "\$NVM_DIR/bash_completion"
command -v fnm >/dev/null 2>&1 && eval "\$(fnm env 2>/dev/null)"
# portable aliases (work on every machine)
alias cr='claude -r'
alias h='herdr'
alias lg='lazygit'
alias v='nvim'
alias y='yazi'
EOF
  # bash gets fzf's Ctrl-R (fuzzy history) / Ctrl-T here; zsh has it in .zshrc.
  if [ "$shname" = bash ]; then
    cat >> "$target" <<'EOF'
# fzf integration — Ctrl-R fuzzy history, Ctrl-T files (guarded across versions)
if command -v fzf >/dev/null 2>&1 && fzf --bash >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd bash)"
EOF
  fi
  ok "wrote $target"
  # ensure the rc sources it
  local rc="$HOME/.${shname}rc"
  if [ -f "$rc" ] && ! grep -q '\.'"${shname}"'rc\.local' "$rc" 2>/dev/null; then
    printf '\n[ -f "$HOME/.%src.local" ] && source "$HOME/.%src.local"\n' "$shname" "$shname" >> "$rc"
  fi
}

module_shell() {
  step "Shell setup: $SHELL_TARGET"

  if [ "$SHELL_TARGET" = zsh ]; then
    has zsh || install_tool zsh brew=zsh apt=zsh dnf=zsh pacman=zsh zypper=zsh apk=zsh
    # zinit + powerlevel10k bootstrap themselves from the .zshrc on first start;
    # p10k.zsh carries the prompt config.
    deploy_packages zsh p10k.zsh
    write_shell_local "$HOME/.zshrc.local" zsh
    # make zsh the login shell if we can
    if [ "$(basename "${SHELL:-}")" != zsh ] && has zsh; then
      if [ "$HAVE_SUDO" = 1 ] || [ "$OS" = mac ]; then
        if confirm "Set zsh as your login shell (chsh)?" y; then
          local zpath; zpath="$(command -v zsh)"
          grep -q "$zpath" /etc/shells 2>/dev/null || echo "$zpath" | run $SUDO tee -a /etc/shells >/dev/null 2>&1 || true
          run chsh -s "$zpath" 2>/dev/null || warn "chsh failed — run it manually: chsh -s $zpath"
        fi
      else
        info "No sudo: exec zsh from your bashrc, or ask an admin to chsh."
      fi
    fi
  else
    # linux, no sudo -> bash. The good bash config lives on the ugcl branch.
    has zsh || true
    info "Deploying bash config from '$LINUX_BRANCH' branch"
    if [ "$DRY_RUN" != 1 ]; then
      if git -C "$DOTFILES_DIR" cat-file -e "origin/$LINUX_BRANCH:bash/.bashrc" 2>/dev/null; then
        [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ] && cp -n "$HOME/.bashrc" "$HOME/.bashrc.pre-dotfiles.bak" 2>/dev/null || true
        git -C "$DOTFILES_DIR" show "origin/$LINUX_BRANCH:bash/.bashrc" > "$HOME/.bashrc" && ok "deployed ~/.bashrc"
        # guard fragile unconditional sources so a fresh box still gets a clean shell
        sed -i.bak -E \
          -e 's#^([[:space:]]*)source "\$HOME/.local/share/blesh/ble.sh"#\1[ -f "$HOME/.local/share/blesh/ble.sh" ] \&\& source "$HOME/.local/share/blesh/ble.sh"#' \
          -e 's#^\. "\$HOME/.cargo/env"#[ -f "$HOME/.cargo/env" ] \&\& . "$HOME/.cargo/env"#' \
          "$HOME/.bashrc" 2>/dev/null && rm -f "$HOME/.bashrc.bak"
        # oh-my-bash is a hard dependency of that bashrc
        if [ ! -d "$HOME/.oh-my-bash" ]; then
          info "Installing oh-my-bash"
          run sh -c 'export OSH="$HOME/.oh-my-bash"; curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh | bash -s -- --unattended' </dev/null || warn "oh-my-bash install failed"
        fi
      else
        warn "Could not read bash/.bashrc from $LINUX_BRANCH; keeping existing ~/.bashrc"
      fi
    fi
    write_shell_local "$HOME/.bashrc.local" bash
  fi

  # shared user-level configs, regardless of shell
  deploy_packages nvim yazi

  install_nerd_font

  # run the shell once so plugins/prompt finish installing now, not on first prompt
  warm_shell
}

# ============================================================================
#  Orchestration
# ============================================================================
# always-interactive yes/no (ignores --all), default No — for launching things
# that take over the terminal, where auto-yes would be wrong.
_ask() {
  local ans
  [ -t 0 ] || return 1
  printf '%s %s [y/N] ' "${C_CYN}?${C_RST}" "$1" >&2
  read -r ans || return 1
  case "$ans" in [Yy]*) return 0;; *) return 1;; esac
}

# After everything is installed, offer to authenticate gh / claude. User picks
# whichever they want (or neither). Interactive TTY only.
interactive_account_setup() {
  [ "$DRY_RUN" = 1 ] && { info "(dry-run) would offer gh / claude account setup"; return 0; }
  [ -t 0 ] || return 0
  { has gh || has claude; } || return 0

  step "Account setup — set up whichever you want (or skip)"
  if has gh; then
    if gh auth status >/dev/null 2>&1; then
      ok "GitHub CLI already authenticated"
    elif _ask "Authenticate GitHub CLI now (runs 'gh auth login')?"; then
      gh auth login || warn "gh auth login didn't finish — run it again anytime"
    else
      info "Skipped gh — run 'gh auth login' later."
    fi
  fi
  if has claude; then
    if _ask "Set up / log in to Claude Code now (opens 'claude'; exit it to return)?"; then
      claude || true
    else
      info "Skipped claude — run 'claude' later to log in. (alias: cr = claude -r)"
    fi
  fi
}

ALL_MODULES="core dev nvim ghostty herdr shell"

run_module() { case "$1" in
  core)    module_core ;;
  dev)     module_dev ;;
  nvim)    module_nvim ;;
  ghostty) module_ghostty ;;
  herdr)   module_herdr ;;
  shell)   module_shell ;;
  *) warn "unknown module: $1" ;;
esac; }

choose_modules() {
  [ -n "$ONLY_MODULES" ] && { echo "${ONLY_MODULES//,/ }"; return; }
  [ "$ASSUME_ALL" = 1 ] && { echo "$ALL_MODULES"; return; }
  if [ ! -t 0 ]; then echo "$ALL_MODULES"; return; fi

  printf '\n%sWhat should I set up?%s\n' "$C_B" "$C_RST" >&2
  cat >&2 <<EOF
  ${C_GRN}1${C_RST}) core     — yazi lazygit fzf ripgrep fd bat eza zoxide delta jq tldr stow
  ${C_GRN}2${C_RST}) dev      — uv, python, node+nvm, gh, claude (cr = claude -r)
  ${C_GRN}3${C_RST}) nvim     — neovim + treesitter + LSPs (python/lean/C/C++/lua/markdown)
  ${C_GRN}4${C_RST}) ghostty  — config + terminfo
  ${C_GRN}5${C_RST}) herdr    — install + config (h = herdr)
  ${C_GRN}6${C_RST}) shell    — $SHELL_TARGET + powerlevel10k prompt + my aliases/configs, stow-deploy
  ${C_GRN}a${C_RST}) all of the above   ${C_DIM}(default)${C_RST}
EOF
  printf '%s' "${C_CYN}?${C_RST} Enter choices (e.g. '1 3 6' or 'a'): " >&2
  local ans; read -r ans || true
  ans="${ans:-a}"
  case "$ans" in *a*|"") echo "$ALL_MODULES"; return;; esac
  local out=""
  for n in $ans; do case "$n" in
    1) out="$out core";; 2) out="$out dev";; 3) out="$out nvim";;
    4) out="$out ghostty";; 5) out="$out herdr";; 6) out="$out shell";;
  esac; done
  echo "${out:-$ALL_MODULES}"
}

print_banner() {
  printf '%s' "$C_MAG$C_B"
  cat <<'EOF'
   ___      _   _____ _ _
  |   \ ___| |_|  ___(_) | ___ ___
  | |) / _ \  _| |_  | | |/ -_|_-<
  |___/\___/\__|_|   |_|_|\___/__/   setup.sh
EOF
  printf '%s' "$C_RST"
  printf '  %s\n' "${C_DIM}Anirudh's machine bootstrapper — macOS & Linux, sudo or not${C_RST}"
}

usage() {
  cat <<EOF
Usage: bash setup.sh [options]
  --all                install everything, no prompts
  --only m1,m2         only these modules ($ALL_MODULES)
  --dry-run            print actions without doing them
  -h, --help           this help
EOF
}

main() {
  while [ $# -gt 0 ]; do case "$1" in
    --all) ASSUME_ALL=1 ;;
    --only) ONLY_MODULES="$2"; shift ;;
    --only=*) ONLY_MODULES="${1#*=}" ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) warn "unknown arg: $1" ;;
  esac; shift; done

  print_banner
  detect_env

  # mac always wants brew present up front
  if [ "$OS" = mac ] && [ -z "$BREW" ]; then ensure_brew || die "Homebrew is required on macOS"; fi

  setup_dotfiles_repo

  local mods; mods="$(choose_modules)"
  step "Running modules:${C_B} $mods${C_RST}"
  for m in $mods; do run_module "$m"; done

  interactive_account_setup

  step "Done 🎉"
  cat <<EOF

  ${C_GRN}Next steps${C_RST}
    • Restart your terminal (or: ${C_B}exec $SHELL_TARGET${C_RST}) to load everything.
    • ${C_B}nvim${C_RST}  — first launch finishes any remaining plugin/parser installs.
    • ${C_B}h${C_RST}     — herdr    ${C_DIM}(prefix Ctrl+a, like your old tmux)${C_RST}
    • ${C_B}cr${C_RST}    — claude -r
    • Fonts: install a Nerd Font (MesloLGS NF) on your *local* machine's terminal.

  Configs are symlinked from ${C_B}$DOTFILES_DIR${C_RST}. Re-run this script anytime.
EOF

  maybe_exec_shell
}

main "$@"
