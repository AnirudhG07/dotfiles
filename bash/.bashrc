# Enable the subsequent settings only in interactive sessions
case $- in
  *i*) ;;
    *) return;;
esac

[[ $- == *i* ]] &&
  source "$HOME/.local/share/blesh/ble.sh" --attach=none
# Path to your oh-my-bash installation.
export OSH='/home/anirudhgupta/.oh-my-bash'

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-bash is loaded.
#OSH_THEME="font"
eval "$(starship init bash)"

# If you set OSH_THEME to "random", you can ignore themes you don't like.
# OMB_THEME_RANDOM_IGNORED=("powerbash10k" "wanelo")

# Uncomment the following line to use case-sensitive completion.
# OMB_CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# OMB_HYPHEN_SENSITIVE="false"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_OSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you don't want the repository to be considered dirty
# if there are untracked files.
# SCM_GIT_DISABLE_UNTRACKED_DIRTY="true"

# Uncomment the following line if you want to completely ignore the presence
# of untracked files in the repository.
# SCM_GIT_IGNORE_UNTRACKED="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.  One of the following values can
# be used to specify the timestamp format.
# * 'mm/dd/yyyy'     # mm/dd/yyyy + time
# * 'dd.mm.yyyy'     # dd.mm.yyyy + time
# * 'yyyy-mm-dd'     # yyyy-mm-dd + time
# * '[mm/dd/yyyy]'   # [mm/dd/yyyy] + [time] with colors
# * '[dd.mm.yyyy]'   # [dd.mm.yyyy] + [time] with colors
# * '[yyyy-mm-dd]'   # [yyyy-mm-dd] + [time] with colors
# If not set, the default value is 'yyyy-mm-dd'.
HIST_STAMPS='dd-mm-yyyy'

# Uncomment the following line if you do not want OMB to overwrite the existing
# aliases by the default OMB aliases defined in lib/*.sh
# OMB_DEFAULT_ALIASES="check"

# Would you like to use another custom folder than $OSH/custom?
# OSH_CUSTOM=/path/to/new-custom-folder

# To disable the uses of "sudo" by oh-my-bash, please set "false" to
# this variable.  The default behavior for the empty value is "true".
OMB_USE_SUDO=false

# To enable/disable display of Python virtualenv and condaenv
# OMB_PROMPT_SHOW_PYTHON_VENV=true  # enable
# OMB_PROMPT_SHOW_PYTHON_VENV=false # disable

# Which completions would you like to load? (completions can be found in ~/.oh-my-bash/completions/*)
# Custom completions may be added to ~/.oh-my-bash/custom/completions/
# Example format: completions=(ssh git bundler gem pip pip3)
# Add wisely, as too many completions slow down shell startup.
completions=(
  git
  composer
  ssh
)

# Which aliases would you like to load? (aliases can be found in ~/.oh-my-bash/aliases/*)
# Custom aliases may be added to ~/.oh-my-bash/custom/aliases/
# Example format: aliases=(vagrant composer git-avh)
# Add wisely, as too many aliases slow down shell startup.
aliases=(
  general
)

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  bashmarks
  zoxide
 # tmux-autoattach
)

# Which plugins would you like to conditionally load? (plugins can be found in ~/.oh-my-bash/plugins/*)
# Custom plugins may be added to ~/.oh-my-bash/custom/plugins/
# Example format:
#  if [ "$DISPLAY" ] || [ "$SSH" ]; then
#      plugins+=(tmux-autoattach)
#  fi

source "$OSH"/oh-my-bash.sh

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

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-bash libs,
# plugins, and themes. Aliases can be placed here, though oh-my-bash
# users are encouraged to define aliases within the OSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias bashconfig="mate ~/.bashrc"
# alias ohmybash="mate ~/.oh-my-bash"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"


alias cd="z"

# USEFUL ALIASES
alias tmux_in='tmux -u a -t'
alias tmux_kill='tmux -u kill-session -t'
alias config="nvim ~/.config"
alias e="exit"
alias ls='eza --color=always --git --no-filesize --no-user --no-permissions --tree --level=1'
alias omzsh='nvim ~/.zshrc'
alias szsh='source ~/.zshrc'
alias pipi='pip install'
alias brewin='brew install'
alias ncdu='ncdu --color dark'
alias btop='btop'
alias df='duf'
alias cmds='tldr --list | fzf --preview "tldr {1} --color" --preview-window=right,70% | xargs tldr'
alias wget="aria2c"
alias lg='lazygit'
alias c='clear'
alias ppt='presenterm'
alias v='nvim'
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	bash -ic "/home/anirudhgupta/yazi/target/release/yazi $@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
alias yazi='bash -ic "/home/anirudhgupta/yazi/target/release/yazi $@"'
alias q="exit"
alias tmux='tmux -u -u'
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
alias edex-ui='open -a edex-ui'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/anirudhgupta/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/anirudhgupta/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/anirudhgupta/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/anirudhgupta/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
[[ ${BLE_VERSION-} ]] && ble-attach
. "$HOME/.cargo/env"
