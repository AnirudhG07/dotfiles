# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
task
echo -e "\e[1;30mType '#' in beginning for AI command suggestions\e[0m"
# Q pre block. Keep at the top of this file.
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"


export VISUAL=nvim 
export EDITOR=nvim

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"
#

## GO PATH and config
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Color variables
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
# Clear the color after that
clear='\033[0m'
alias colorpalet='echo "red, green, yellow, blue, magenta, cyan"
echo "Use colour as '

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Put these in your .zshrc (No need to install a plugin)
cc() python3 -c "from math import *; print($*);"
alias calc='noglob cc'
# You can use `cc` just like `=` from above. All functions from the math module of Python are available for use. 

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="dd.mm.yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search zsh-bat you-should-use)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"
#
eval "$(fzf --zsh)"
# -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}
source ~/fzf-git.sh/fzf-git.sh

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

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
# ----- Bat (better cat) -----

export BAT_THEME=tokyonight_night

eval $(thefuck --alias)
eval $(thefuck --alias shit)
# Postgress@16 path 
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"

alias cd="z"

# USEFUL ALIASES
alias tmux_in='tmux a -t'
alias tmux_kill='tmux kill-session -t'
alias config="nvim ~/.config"
alias e="exit"
alias ls='eza --color=always --git --no-filesize --no-user --no-permissions --tree --level=1'
alias iisc='cd /Volumes/Anirudh/IISc'
alias home='cd /Volumes/Anirudh'
alias omzsh='nvim ~/.zshrc'
alias szsh='source ~/.zshrc'
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
alias y='yazi'
alias v='nvim'
####################################################################

# USELESS ALIASES
alias ilu='echo "I love you too!"'
alias games='echo "We have games like snake, pong, doctor, gomoku, tetris...
Just type in emacs-> ESC x-> Type in game name as mentioned.
OR
ninvaders, moon_buggy, nethacks
ENJOY Your GAME TIME!!!"'
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
alias amuse_me='echo "WELL WELL WELL SOMEONE LOOKS BORED!
Help yourself by playing games, but typing 'games' in terminal
OR
You can do sl, cowsay, espeak, cmatrix, rig, fortune, figlet, rev, asciiquarium, llama...
Just Enjoy yourself Mate!"'
alias moo='fortune | cowsay | lolcat'
alias fishing='asciiquarium'
alias good='echo "Ab itni bhi tareef mat karo!"'
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
alias joke='echo "Type one of [moo, tux, dino] to get a joke ft. animal. Use lolcat for colour.
For example:"
moo'
alias cool='echo "I know right!"'
alias gm='echo "GOOD MORNING ANIRUDH! HAVE A GREAT DAY TODAY!"
say "GOOD MORNING ANIRUDH! HAVE A GREAT DAY TODAY"'
alias terminal-robot='bash terminal-robot.sh'
export NEKOPATH="/opt/homebrew/lib/neko"
alias edex-ui='open -a edex-ui'
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Q post block. Keep at the bottom of this file.
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
