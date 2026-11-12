#!/usr/bin/env bash
# =============================================================================
#  dotfiles/setup.sh  —  Anirudh's one-shot machine bootstrapper
#
#  Sets up a fresh macOS or Linux box (with or without sudo) the way I like it:
#  core CLI tools, neovim (>= 0.12) + LSPs/treesitter, claude/gh/uv, ghostty, herdr-core
#  (hc) + the Herdr desktop app (only if you say yes), and my shell + configs (symlinked from
#  ~/dotfiles, stow-style).
#
#  Usage (straight from the internet — it clones the repo for you):
#     curl -fsSL https://anirudhg07.github.io/dotfiles/setup.sh -o setup.sh
#     bash setup.sh                            # interactive
#     bash setup.sh --all                      # install everything, no prompts
#     bash setup.sh --only core,nvim,shell
#     bash setup.sh --dry-run                  # show what would happen
#
#  or, from a clone:
#     git clone https://github.com/AnirudhG07/dotfiles ~/dotfiles
#     bash ~/dotfiles/setup.sh
#
#  or in one go:
#     curl -fsSL https://anirudhg07.github.io/dotfiles/setup.sh | bash
#
#  Safe to re-run: every step is idempotent.
# =============================================================================

set -uo pipefail

# ------------------------------------------------------------------ constants
REPO_URL="https://github.com/AnirudhG07/dotfiles"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
LOCAL_PREFIX="$HOME/.local"
LOCAL_BIN="$LOCAL_PREFIX/bin"

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
  local_bin_first

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
  # If this script already lives inside a clone of this repo, use that. A setup.sh fetched with curl lands
  # wherever it was run (maybe inside some unrelated git repo), so insist on this repo's own layout.
  local self_dir top=""
  self_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)" 2>/dev/null || self_dir=""
  [ -n "$self_dir" ] && top="$(git -C "$self_dir" rev-parse --show-toplevel 2>/dev/null)" || true
  if [ -n "$top" ] && [ -f "$top/setup.sh" ] && [ -d "$top/zsh" ] && [ -d "$top/nvim" ]; then
    DOTFILES_DIR="$top"
    ok "Using existing clone at $DOTFILES_DIR"
  elif [ -d "$DOTFILES_DIR/.git" ]; then
    ok "Found $DOTFILES_DIR"
    run git -C "$DOTFILES_DIR" pull --ff-only 2>/dev/null || warn "pull skipped"
  else
    info "Cloning $REPO_URL -> $DOTFILES_DIR"
    run git clone "$REPO_URL" "$DOTFILES_DIR" || die "clone failed"
  fi

  # Everything (mac zsh + linux bash) lives on one trunk now. Older clones sit on the retired 'ugcl' branch
  # or on 'stow' (the trunk's former name): move them to the remote's default branch when that's safe.
  local cur def
  cur="$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  case "$cur" in ugcl|stow)
    def="$(git -C "$DOTFILES_DIR" ls-remote --symref origin HEAD 2>/dev/null | sed -n 's#^ref: refs/heads/\([^[:space:]]*\)[[:space:]]*HEAD$#\1#p')"
    if [ -n "$def" ] && [ "$def" != "$cur" ] \
       && git -C "$DOTFILES_DIR" diff --quiet && git -C "$DOTFILES_DIR" diff --cached --quiet; then
      info "Moving this clone from '$cur' to '$def'"
      run git -C "$DOTFILES_DIR" fetch --quiet origin "$def" 2>/dev/null || true
      run git -C "$DOTFILES_DIR" checkout -q "$def" 2>/dev/null && run git -C "$DOTFILES_DIR" pull --ff-only -q 2>/dev/null \
        || warn "couldn't switch to '$def' — run: git -C $DOTFILES_DIR checkout $def"
    fi ;;
  esac
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
  claude_settings_merge
}

# No attribution lines in Claude Code's commits/PRs. Merged into ~/.claude/settings.json:
# the file is read, only attribution.{commit,pr,sessionUrl} are set, every other setting
# (and any other attribution key) is kept, and it's written back atomically. A file that
# isn't valid JSON is left untouched.
claude_settings_merge() {
  local f="$HOME/.claude/settings.json"
  if [ "$DRY_RUN" = 1 ]; then info "${C_DIM}[dry-run]${C_RST} would set attribution (no commit/PR lines) in $f"; return 0; fi
  has python3 || { warn "python3 missing: add \"attribution\": {\"commit\": \"\", \"pr\": \"\", \"sessionUrl\": false} to $f yourself"; return 0; }
  mkdir -p "$(dirname "$f")"
  python3 - "$f" <<'PY'
import json, os, sys, tempfile
path = sys.argv[1]
want = {"commit": "", "pr": "", "sessionUrl": False}
try:
    with open(path) as fh:
        text = fh.read()
except FileNotFoundError:
    text = ""
try:
    data = json.loads(text) if text.strip() else {}
except json.JSONDecodeError as e:
    print(f"! {path} isn't valid JSON ({e}); left it alone", file=sys.stderr)
    sys.exit(0)
if not isinstance(data, dict):
    print(f"! {path} isn't a JSON object; left it alone", file=sys.stderr)
    sys.exit(0)
attr = data.get("attribution")
attr = dict(attr) if isinstance(attr, dict) else {}
if all(attr.get(k) == v for k, v in want.items()):
    print(f"\u2713 claude settings: attribution already off ({path})")
    sys.exit(0)
attr.update(want)
data["attribution"] = attr
d = os.path.dirname(path)
fd, tmp = tempfile.mkstemp(dir=d, prefix=".settings.", suffix=".json")
with os.fdopen(fd, "w") as out:
    json.dump(data, out, indent=2, ensure_ascii=False)
    out.write("\n")
if os.path.exists(path):
    os.chmod(tmp, os.stat(path).st_mode & 0o777)
os.replace(tmp, path)
print(f"\u2713 claude settings: attribution off ({path})")
PY
}

# ---------------------------------------------------------------- neovim
# The config's treesitter (nvim-treesitter `main`) needs Neovim 0.12+ and tree-sitter CLI 0.26.1+.
NVIM_MIN="0.12.0"
TS_MIN="0.26.1"

# ver_ge A B: dotted version A >= B
ver_ge() {
  awk -v a="$1" -v b="$2" 'BEGIN { split(a, x, "."); split(b, y, ".")
    for (i = 1; i <= 3; i++) { if (x[i] + 0 > y[i] + 0) exit 0; if (x[i] + 0 < y[i] + 0) exit 1 } exit 0 }'
}
nvim_version() { "$1" --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9][0-9.]*\).*/\1/p'; }
ts_version()   { "$1" --version 2>/dev/null | sed -n '1s/^tree-sitter \([0-9][0-9.]*\).*/\1/p'; }

# put ~/.local/bin first for the rest of this run, even if it's already on PATH after /usr/bin
# (else apt's old /usr/bin/nvim keeps winning over the one we just installed)
local_bin_first() {
  PATH=":$PATH:"; PATH="${PATH//:$LOCAL_BIN:/:}"; PATH="${PATH#:}"; PATH="$LOCAL_BIN:${PATH%:}"; export PATH
  hash -r 2>/dev/null || true
}

# Linux: the official tarball (glibc 2.34+, Ubuntu 22.04+), else neovim-releases' build for
# older glibc (Ubuntu 20.04, RHEL 8, ...). Installed to ~/.local/nvim, linked into ~/.local/bin.
install_nvim_release() {
  local asset tmp url v dest="$LOCAL_PREFIX/nvim"
  if [ "$ARCH" = arm64 ]; then asset=nvim-linux-arm64; else asset=nvim-linux-x86_64; fi
  if [ "$DRY_RUN" = 1 ]; then info "${C_DIM}[dry-run]${C_RST} would install the latest $asset into $dest"; return 0; fi
  for url in "https://github.com/neovim/neovim/releases/latest/download/$asset.tar.gz" \
             "https://github.com/neovim/neovim-releases/releases/latest/download/$asset.tar.gz"; do
    tmp="$(mktemp -d)"
    if curl -fsSL "$url" -o "$tmp/nvim.tgz" && mkdir -p "$tmp/nvim" \
       && tar -xzf "$tmp/nvim.tgz" -C "$tmp/nvim" --strip-components=1; then
      v="$(nvim_version "$tmp/nvim/bin/nvim")"
      if [ -n "$v" ] && ver_ge "$v" "$NVIM_MIN"; then
        mkdir -p "$LOCAL_BIN" && rm -rf "$dest" && mv "$tmp/nvim" "$dest" && ln -sfn "$dest/bin/nvim" "$LOCAL_BIN/nvim"
        rm -rf "$tmp"; ok "neovim $v -> $dest  ${C_DIM}(${url#https://github.com/})${C_RST}"; return 0
      fi
      info "${url#https://github.com/} doesn't run here (glibc too old?) — trying the next build"
    fi
    rm -rf "$tmp"
  done
  warn "couldn't install a Neovim >= $NVIM_MIN"; return 1
}

ensure_nvim() {
  local cur v
  cur="$(command -v nvim || true)"
  v="$([ -n "$cur" ] && nvim_version "$cur")"
  if [ -n "$v" ] && ver_ge "$v" "$NVIM_MIN"; then ok "neovim $v ($cur)"; return 0; fi
  [ -n "$cur" ] && info "neovim ${v:-?} at $cur is too old (need >= $NVIM_MIN) — installing a newer one"
  if [ "$OS" = mac ]; then
    ensure_brew && { has_brew_pkg neovim && run "$BREW" upgrade neovim || run "$BREW" install neovim; }
  else
    install_nvim_release && local_bin_first
  fi
  cur="$(command -v nvim || true)"; v="$([ -n "$cur" ] && nvim_version "$cur")"
  if [ "$DRY_RUN" = 1 ]; then return 0
  elif [ -n "$v" ] && ver_ge "$v" "$NVIM_MIN"; then ok "using neovim $v ($cur)"
  else warn "nvim on PATH is still ${v:-missing} ($cur); the config needs >= $NVIM_MIN"; fi
}
has_brew_pkg() { "$BREW" list --formula "$1" >/dev/null 2>&1; }

# tree-sitter CLI, which nvim-treesitter uses to build parsers. In order:
#   1. one already on PATH that is >= 0.26.1 and really runs;
#   2. the official binary from GitHub releases, if it runs here (it needs glibc 2.39 on Linux,
#      i.e. Ubuntu 24.04+; mason's and npm's copies are the same binary);
#   3. tree-sitter-cc (bin/.local/bin): a stand-in that builds parsers with just cc. Every core
#      parser builds with it; only "generated" ones (latex, perl, swift) need the real CLI.
ensure_tree_sitter() {
  local cur v os a tmp
  cur="$(command -v tree-sitter || true)"
  v="$([ -n "$cur" ] && ts_version "$cur")"
  if [ -n "$v" ] && ver_ge "$v" "$TS_MIN" && ! "$cur" --version 2>/dev/null | grep -q tree-sitter-cc; then
    ok "tree-sitter CLI $v ($cur)"; return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then info "${C_DIM}[dry-run]${C_RST} would fetch the tree-sitter CLI from GitHub, or link tree-sitter-cc"; return 0; fi
  case "$OS" in mac) os=macos ;; *) os=linux ;; esac
  case "$ARCH" in arm64) a=arm64 ;; *) a=x64 ;; esac
  tmp="$(mktemp -d)"; mkdir -p "$LOCAL_BIN"
  if curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-$os-$a.gz" -o "$tmp/ts.gz" \
     && gunzip -f "$tmp/ts.gz" && chmod +x "$tmp/ts" \
     && v="$(ts_version "$tmp/ts")" && [ -n "$v" ] && ver_ge "$v" "$TS_MIN"; then
    rm -f "$LOCAL_BIN/tree-sitter" && mv "$tmp/ts" "$LOCAL_BIN/tree-sitter" && ok "tree-sitter CLI $v (GitHub release) -> $LOCAL_BIN/tree-sitter"
  else
    ln -sfn "$DOTFILES_DIR/bin/.local/bin/tree-sitter-cc" "$LOCAL_BIN/tree-sitter"
    ok "tree-sitter-cc -> $LOCAL_BIN/tree-sitter  ${C_DIM}(the official CLI doesn't run here; parsers build with cc)${C_RST}"
  fi
  rm -rf "$tmp"
  local_bin_first
  # mason's tree-sitter-cli is that same GitHub binary; inside nvim it would shadow ours
  local m="$HOME/.local/share/nvim/mason"
  if [ -e "$m/bin/tree-sitter" ] && ! "$m/bin/tree-sitter" --version >/dev/null 2>&1; then
    rm -rf "$m/packages/tree-sitter-cli" "$m/bin/tree-sitter" && info "removed mason's tree-sitter-cli (it can't run here)"
  fi
}

# this machine's nvim extras (gitignored lua/anirudh/machine.lua): start one from the template
seed_nvim_machine_file() {
  local d="$DOTFILES_DIR/nvim/.config/nvim/lua/anirudh"
  [ -e "$d/machine.lua" ] && return 0
  [ "$DRY_RUN" = 1 ] && { info "${C_DIM}[dry-run]${C_RST} would create $d/machine.lua"; return 0; }
  cp "$d/machine.example.lua" "$d/machine.lua" \
    && info "nvim: core only on this machine (pyright, ruff, clangd). Extras go in ${C_B}~/.config/nvim/lua/anirudh/machine.lua${C_RST}"
}

module_nvim() {
  step "Neovim (>= $NVIM_MIN) + treesitter + Python & C/C++ LSPs"
  local_bin_first

  # 1) Neovim itself: apt's is usually too old (Ubuntu 24.04 ships 0.9.5)
  ensure_nvim

  # 2) What parsers and LSP servers need: a C compiler, the tree-sitter CLI, node (pyright)
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
  has cc || has gcc || has clang || warn "no C compiler: treesitter parsers can't be built (ask an admin for gcc / build-essential)"
  ensure_tree_sitter
  ensure_node

  # 3) System-wide toolchains (mason installs pyright, and ruff/clangd when these are missing)
  step "LSP toolchains (python, C/C++, lean)"
  ensure_uv && run uv tool install ruff >/dev/null 2>&1 && ok "ruff (uv)" || true
  install_tool clangd brew=llvm apt=clangd dnf=clang-tools-extra pacman=clang eget=clangd/clangd || true
  # lean: elan toolchain manager (installs lean/lake; lean.nvim uses its LSP)
  if has lean || has elan; then ok "lean/elan present"
  elif [ -n "$BREW" ] && run "$BREW" install elan-init 2>/dev/null && has elan; then ok "elan (brew)"
  else
    info "Installing elan (Lean toolchain)"
    run sh -c "curl -fsSL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y --default-toolchain stable" </dev/null \
      && ok "elan ready" || warn "elan install failed"
  fi
  [ -f "$HOME/.elan/env" ] && . "$HOME/.elan/env" 2>/dev/null || true

  seed_nvim_machine_file

  # 4) First launch, headless: plugins, then parsers + mason tools from lua/anirudh/core/tools.lua
  #    (core + this machine's extras), waiting for each to finish.
  if has nvim && [ "$DRY_RUN" != 1 ]; then
    step "Bootstrapping Neovim (plugins, parsers, LSP servers) — headless"
    info "This compiles treesitter parsers; give it a minute..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "Lazy sync had issues (open nvim to finish)"
    nvim --headless "+lua require('nvim-treesitter').install(require('anirudh.core.tools').treesitter()):wait(900000)" +qa 2>/dev/null \
      || warn "some parsers didn't build (open nvim, :checkhealth nvim-treesitter)"
    nvim --headless "+MasonToolsInstallSync" +qa 2>/dev/null || true
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

# ============================================================================
#  Herdr app: herdr-core (hc) + the desktop app + my layout/mods/keys
# ============================================================================
HERDR_RELEASES="https://releases.herdr.dev"

is_nixos()      { [ "$OS" = linux ] && [ -e /etc/NIXOS ]; }

herdr_app_installed() {
  has herdr-app || [ -d /Applications/Herdr.app ] || [ -d "$HOME/Applications/Herdr.app" ]
}

# herdr-core runs the terminals (and gives you `hc`); the app and the CLI both sit on it. Every machine gets it.
install_herdr_core() {
  if has herdr-core || [ -x "$LOCAL_BIN/herdr-core" ]; then ok "herdr-core (hc) already installed"; return 0; fi
  if is_nixos; then
    warn "NixOS: herdr-core's prebuilt binary can't run here and nixpkgs has no package for it yet — skipping"
    return 0
  fi
  info "Installing herdr-core (hc)"
  run sh -c "curl -fsSL $HERDR_RELEASES/core/install.sh | sh" </dev/null || { warn "herdr-core install failed"; return 1; }
  if [ "$DRY_RUN" = 1 ] || has herdr-core || [ -x "$LOCAL_BIN/herdr-core" ]; then ok "herdr-core (hc)"; fi
}

# The desktop app is installed only when asked for and answered yes: --all and
# non-interactive runs never install it, and Enter means no.
want_herdr_app() {
  [ "$ASSUME_ALL" = 1 ] && return 1
  [ -t 0 ] || return 1
  local ans
  printf '%s Install the Herdr desktop app too? %s[y/N] ' "${C_CYN}?${C_RST}" "${C_DIM}(herdr-core is installed either way)${C_RST} " >&2
  read -r ans || return 1
  case "$ans" in [Yy]*) return 0;; *) return 1;; esac
}

# Herdr's own installer: Herdr.app into ~/Applications (Apple silicon) or the app into
# ~/.local/share/herdr-app with a launcher entry (Linux), `herdr-app` in ~/.local/bin.
# No Homebrew or nix involved; the app keeps itself and herdr-core updated afterwards.
install_herdr_app_desktop() {
  info "Installing the Herdr desktop app"
  run sh -c "curl -fsSL $HERDR_RELEASES/app/install.sh | sh" </dev/null || { warn "Herdr app install failed"; return 1; }
  if [ "$DRY_RUN" = 1 ] || herdr_app_installed; then ok "Herdr desktop app"; fi
}

# my layout (preview-plus Files panel, popup terminals, idle-reaper), keys, theme and mods
deploy_herdr_app_config() {
  local h="$HOME/.config/herdr-app"
  # make the dirs first so stow links individual mods/files instead of folding the whole folder
  # (the app writes plenty of state of its own in there)
  run mkdir -p "$h/mods" "$h/layouts" "$h/themes"
  deploy_packages herdr-app
  # first start: open on my layout (afterwards the app keeps this file itself)
  if [ "$DRY_RUN" != 1 ] && [ ! -e "$h/shared.json" ]; then
    printf '{"layout":"anirudh","workspace.panels":["files","changes"]}\n' > "$h/shared.json"
  fi
  # a running window switches over live
  if [ "$DRY_RUN" != 1 ] && has herdr-app; then herdr-app do layout.switch '{"name":"anirudh"}' >/dev/null 2>&1 || true; fi
  has python3 || warn "python3 is missing — the claude-manager mod needs it"
}

module_herdr_app() {
  step "Herdr  — herdr-core (hc) + my layout, mods and keys (desktop app only if you say yes)"
  case ":$PATH:" in *":$LOCAL_BIN:"*) ;; *) PATH="$LOCAL_BIN:$PATH"; export PATH ;; esac
  install_herdr_core
  if herdr_app_installed; then ok "Herdr desktop app already installed"
  elif want_herdr_app; then install_herdr_app_desktop
  else info "Skipping the desktop app (herdr-core is in). Add it later: bash setup.sh --only herdr-app"; fi
  deploy_herdr_app_config
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
# user bin dirs go first, ahead of /usr/bin (so ~/.local/bin/nvim beats an old apt nvim);
# an entry already on PATH is moved to the front, never duplicated on nested shells
for d in "\$HOME/.local/bin" "\$HOME/go/bin"; do
  [ -d "\$d" ] || continue
  PATH=":\$PATH:"; PATH="\${PATH//:\$d:/:}"; PATH="\${PATH#:}"; PATH="\$d:\${PATH%:}"
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
alias h='hc'
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
    # linux, no sudo -> bash. The config is this repo's bash/ package.
    info "Deploying bash config (bash/.bashrc)"
    if [ "$DRY_RUN" != 1 ]; then
      if [ -f "$DOTFILES_DIR/bash/.bashrc" ]; then
        [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ] && cp -n "$HOME/.bashrc" "$HOME/.bashrc.pre-dotfiles.bak" 2>/dev/null || true
        cp "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc" && ok "deployed ~/.bashrc"
        # guard fragile unconditional sources so a fresh box still gets a clean shell, and make the
        # oh-my-bash path follow $HOME instead of one machine's /home/<user>
        sed -i.bak -E \
          -e 's#^([[:space:]]*)source "\$HOME/.local/share/blesh/ble.sh"#\1[ -f "$HOME/.local/share/blesh/ble.sh" ] \&\& source "$HOME/.local/share/blesh/ble.sh"#' \
          -e 's#^\. "\$HOME/.cargo/env"#[ -f "$HOME/.cargo/env" ] \&\& . "$HOME/.cargo/env"#' \
          -e 's#^export OSH=.*#export OSH="$HOME/.oh-my-bash"#' \
          "$HOME/.bashrc" 2>/dev/null && rm -f "$HOME/.bashrc.bak"
        # oh-my-bash is a hard dependency of that bashrc
        if [ ! -d "$HOME/.oh-my-bash" ]; then
          info "Installing oh-my-bash"
          run sh -c 'export OSH="$HOME/.oh-my-bash"; curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh | bash -s -- --unattended' </dev/null || warn "oh-my-bash install failed"
        fi
      else
        warn "$DOTFILES_DIR/bash/.bashrc is missing; keeping existing ~/.bashrc"
      fi
    fi
    write_shell_local "$HOME/.bashrc.local" bash
  fi

  # shared user-level configs, regardless of shell
  # 'bin' stows ~/.local/bin scripts (mathlib, ...) — already on PATH.
  deploy_packages nvim yazi bin

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

ALL_MODULES="core dev nvim ghostty herdr-app shell"

run_module() { case "$1" in
  core)    module_core ;;
  dev)     module_dev ;;
  nvim)    module_nvim ;;
  ghostty) module_ghostty ;;
  herdr-app) module_herdr_app ;;
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
  ${C_GRN}3${C_RST}) nvim     — neovim >= 0.12 + treesitter + python & C/C++ LSPs (extras per machine)
  ${C_GRN}4${C_RST}) ghostty  — config + terminfo
  ${C_GRN}5${C_RST}) herdr-app — herdr-core (hc) + my layout, mods, keys; asks before the desktop app
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
    4) out="$out ghostty";; 5) out="$out herdr-app";; 6) out="$out shell";;
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
    • ${C_B}h${C_RST}     — hc (herdr-core): pick a terminal and attach, no desktop needed; ${C_B}herdr-app${C_RST} — the desktop app, if installed  ${C_DIM}(⌘/ shell, ⌘G lazygit, ⌘Y yazi popups)${C_RST}
    • ${C_B}cr${C_RST}    — claude -r
    • Fonts: install a Nerd Font (MesloLGS NF) on your *local* machine's terminal.

  Configs are symlinked from ${C_B}$DOTFILES_DIR${C_RST}. Re-run this script anytime.
EOF

  maybe_exec_shell
}

main "$@"
