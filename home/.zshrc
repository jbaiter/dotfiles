# Initialize homeshick and its completions
. ~/.homesick/repos/homeshick/homeshick.sh
fpath=(~/.homesick/repos/homeshick/completions $fpath)

# Check for dotfiles updates
homeshick --quiet refresh

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Aliases
alias dquilt="quilt --quiltrc=${HOME}/.quiltrc-dpkg"
alias c='pygmentize -g'
alias mplayer="mpv"
alias feh="feh -Fx"
alias tmux='TERM=screen-256color tmux -2'
alias tmuxinator='TERM=screen-256color tmuxinator'
alias mux='TERM=screen-256color mux'
alias hdevtools='stack exec --no-ghc-package-path hdevtools --'
alias vim="nvim"

# Environment variables
if [[ $(hostname) == 'workstation' ]]; then
    export XORG_DPI=93
elif [[ $(hostname) == 'thinkpad' ]]; then
    export XORG_DPI=131
fi
export EDITOR="nvim"
export VISUAL="nvim"
export PATH="~/.bin:~/.local/bin:~/.cargo/bin:$PATH"
export CFLAGS="-O2 -pipe -march=native"
export CXXFLAGS="${CFLAGS}"
export LANG=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LESS="-R"
export WORKON_HOME=~/.envs
export MOZ_PLUGIN_PATH='/usr/lib/mozilla/plugins'
export TERM="screen-256color"
export NVM_DIR="~/.nvm"
export PANEL_FIFO="/tmp/panel-fifo"

# Automatically start X when logging in on TTY1
if [[ -z $DISPLAY && $(tty) = /dev/tty1 ]]; then
    exec startx -- -dpi $XORG_DPI -nolisten tcp -novtswitch || echo "oops"
fi

# Load node version manager
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Load virtualenvwrapper
. /usr/share/virtualenvwrapper/virtualenvwrapper_lazy.sh

if [[ $(hostname) == 'workstation' ]]; then
    # Activate torch
    . /home/jojo/.torch/install/bin/torch-activate
fi
