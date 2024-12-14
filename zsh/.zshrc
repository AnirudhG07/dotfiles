# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias vim='nvim'
alias c='clear'

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

DISABLE_AUTO_TITLE="true"


export VISUAL=nvim 
export EDITOR=nvim
## GO PATH and config
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin


HIST_STAMPS="dd.mm.yyyy"

_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}
source ~/fzf-git.sh/fzf-git.sh

# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#
BAT_THEME="Catppuccin Mocha"

# PREVIEW SETTINGS
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
  esac
}

export YAZI_CONFIG_HOME=~/dotfiles/yazi/.config/yazi
# ----- Bat (better cat) -----

export BAT_THEME=tokyonight_night

# Postgress@16 path 
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export PATH="/Applications/Ghostty.app/Contents/MacOS:$PATH"

function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}


########## NIX ################
alias hms="home-manager switch"
alias nix-cg="nix-collect-garbage"
alias nix-drb="darwin-rebuild switch --flake ~/dotfiles/nix/.config/nix-darwin"
eval "$(direnv hook zsh)"

# USEFUL ALIASES
alias tmux_in='tmux a -t'
alias tmux_kill='tmux kill-session -t'
alias config="nvim ~/.config"
alias e="exit"
alias ls='eza --color=always --git --no-filesize --no-user --no-permissions --tree --level=1'
alias iisc='cd /Volumes/Anirudh/IISc'
alias home='cd /Volumes/Anirudh'
alias pipi='pip install'
alias pylib='cd /opt/homebrew/lib'
alias brewin='brew install'
alias basic_compiler='echo "This is link of compiler given by CTF. It may or maynot work. 
If it doesnt work, delete this alias."
socat file:`tty`,rawer tcp:basic-01.2023-bq.ctfcompetition.com:1337'
alias ncdu='ncdu --color dark'
alias btop='btop'
alias df='duf'
alias ctf='cd /Volumes/Anirudh/Coding/ctf'
alias cmds='tldr --list | fzf --preview "tldr {1} --color" --preview-window=right,70% | xargs tldr'

alias ghidra='/Applications/ghidra_11.0.3_PUBLIC/ghidraRun'
alias jadx='/Applications/jadx/bin/jadx-gui'
alias barpsuite='open /Applications/Burp\ Suite\ Community\ Edition.app'
alias wget="aria2c"
alias lg='lazygit'
alias vm='ssh -i /Applications/awsvm1.pem  ec2-user@ec2-13-200-254-231.ap-south-1.compute.amazonaws.com'
alias c='clear'
alias ppt='presenterm'
alias packmol='cd /Volumes/Anirudh/IISc/igem/packmol-20.14.4-docs1
./packmol'
alias v='nvim'
alias y='yazi'
alias yy='yy'
alias :q="exit"
alias python="python3"
alias mathworks='ssh anirudhgupta@10.134.13.103'
alias fuweather="https 'wttr.in?format=%C+|+%t' | tail -n 1; sketchybar --reload"
####################################################################

# USELESS ALIASES
alias ilu='echo "I love you too!"'
alias llama='echo "
        1          _________________________
       11         |                         |
   111111         |   ALWAYS BE YOURSELF    |
 11_O-111         |   UNLESS YOU CAN BE A   | 
1111111111        |   |  |   /\ |\/| /\     |
 11__11111      --|   |__|__/--\|  |/--\    |
 1___1111    --/  |_________________________|
 1___1111  -/
 1__1111 
 1__1111 
 1_11111       11111 
 1_1111       1111111 
 1_111111    111111111 
 1__11111111111111111111 
  1_111111111111111111111 
   11111111111111111111111 
     111111111111111111111 
      1111111111111111111 
      111111     1111111
       1111       111111 
       111         11111 
       111          111_1 
       111          111_1 
       111          11_1 
       111          1111 
      11           111
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
"'

alias moo='fortune | cowsay | lolcat'
alias fishing='asciiquarium'
alias weather='https wttr.in'

alias eww='echo "
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡾⠟⠋⢩⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⠟⠁⠀⠀⠀⠸⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⠟⠁⠀⠀⠀⠀⠀⠀⠙⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⠃⠀⠀⠀⠀⠀⠐⠷⠤⠤⠤⠤⣿⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⢿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⡾⠟⠛⢦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⢰⡿⠉⠀⠀⠀⠀⠈⠓⠦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⣀⡤⠤⠤⢄⡀⠀⠈⠙⠒⠦⣤⣀⣠⠖⠋⠉⠓⠦⣀⣸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⣿⣧⡞⠁⢀⣀⡀⠀⠙⣆⠀⠀⠀⠀⠀⡼⠁⠀⣠⣤⡀⠀⠙⡟⠿⢶⣤⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣠⡾⠟⠁⡼⠀⢠⣿⣿⣿⣦⠀⠘⡆⠀⠀⠀⢰⠇⠀⣼⣿⣿⣿⡄⠀⢹⠀⠀⠙⢿⣄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣼⡟⠀⠀⠀⡇⠀⢸⣿⣿⣿⣿⠆⠀⡧⠀⠀⠀⠸⡆⠀⣿⣿⣿⣿⡇⠀⢸⠇⠀⠀⠈⣿⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣿⠀⠀⠀⠀⢻⡀⠘⣿⣿⣿⡿⠀⢀⠟⠦⢤⣀⡀⢳⠀⠘⢿⣿⠟⠀⠀⡼⠀⠀⠀⠀⣿⠇⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢿⡆⠀⠀⠀⠀⢳⡀⠈⠉⠉⠀⢀⡞⠀⠀⠀⠈⠉⠙⠳⣄⠀⠀⠀⣠⣾⣁⣀⣀⣀⣠⣿⣤⣀⠀⠀⠀⠀
⠀⠀⠀⣀⣼⣿⡄⠀⠀⠀⠀⠙⠲⠤⠤⠒⠉⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⡉⡉⠁⠀⠀⠀⠀⠀⠀⠀⠉⠛⢷⣦⠀⠀
⠀⣠⣾⠟⠉⠀⠙⢦⡀⠀⠀⠀⠀⣴⠒⠒⠲⠤⠤⠤⠴⠖⠒⠒⠒⠊⠉⢉⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣷⠀
⢰⡟⠁⠀⠀⠀⠀⠀⠉⠳⢤⣀⠀⠈⠳⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⡇
⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠲⢤⣀⡙⠲⠤⠤⣤⣤⠤⠴⠚⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⡇
⢻⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠓⠲⠤⢤⣄⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡿⠀
⠀⠙⢷⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣠⣭⣽⣿⠶⠶⠶⣶⣤⣤⣤⣤⣤⣤⣤⣶⠿⠛⠀⠀
⠀⠀⠀⢉⣙⡛⠿⠷⠶⢶⣶⣶⣶⡶⠶⠶⠾⠿⠟⠛⠛⠋⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠁⠀⠀⠀⠀⠀
"'
alias gn='echo "GOOD NIGHT ANIRUDH!!! SLEEP WELL!" 
say "GOOD NIGHT ANIRUDH SLEEP WELL"
exit'
alias dino='fortune | cowsay -f stegosaurus'
alias tux='fortune | cowsay -f tux'
alias cool='echo "I know right!"'
alias gm='echo "GOOD MORNING ANIRUDH! HAVE A GREAT DAY TODAY!"
say "GOOD MORNING ANIRUDH! HAVE A GREAT DAY TODAY"'
alias edex-ui='open -a edex-ui'

# Q post block. Keep at the bottom of this file.
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"

. "$HOME/.cargo/env"
eval "$(gh copilot alias -- zsh)"
