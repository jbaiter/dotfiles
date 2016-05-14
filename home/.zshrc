# Initialize homeshick and its completions
. $HOME/.homesick/repos/homeshick/homeshick.sh
fpath=($HOME/.homesick/repos/homeshick/completions $fpath)

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

# Load node version manager
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Load virtualenvwrapper
. /usr/share/virtualenvwrapper/virtualenvwrapper_lazy.sh

if [ $(hostname) = 'workstation' ]; then
    # Activate torch
    . /home/jojo/.torch/install/bin/torch-activate
fi

# Automatically start X when logging in on TTY1
if [[ -z $DISPLAY && $(tty) = /dev/tty1 ]]; then
    exec startx -- -dpi $XORG_DPI -nolisten tcp -novtswitch 2>! $HOME/.startx.log || echo "oops"
fi
