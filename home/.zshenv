if [ $(hostname) = 'workstation' ]; then
    export XORG_DPI=93
    export MAIN_SCREEN="DVI-I-1"
    export PA_DEFAULT_SINK=1
elif [ $(hostname) = 'thinkpad' ]; then
    export XORG_DPI=131
    export MAIN_SCREEN="LVDS1"
    export PA_DEFAULT_SINK=0
fi
export EDITOR="nvim"
export VISUAL="nvim"
export PATH="$HOME/.bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export CFLAGS="-O2 -pipe -march=native"
export CXXFLAGS="${CFLAGS}"
export LANG=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LESS="-R"
export WORKON_HOME=$HOME/.envs
export MOZ_PLUGIN_PATH='/usr/lib/mozilla/plugins'
#export TERM="screen-256color"
export NVM_DIR="$HOME/.nvm"

export PANEL_HEIGHT=16

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi
