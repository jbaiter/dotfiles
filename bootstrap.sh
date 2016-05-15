#!/bin/bash
set -e

install_basics() {
    sudo apt-get install git apt
}

install_dotfiles() {
    tmpfilename="/tmp/${0##*/}.XXXXX"

    if type mktemp >/dev/null; then
    tmpfile=$(mktemp $tmpfilename)
    else
    tmpfile=$(echo $tmpfilename | sed "s/XX*/$RANDOM/")
    fi

    trap 'rm -f "$tmpfile"' EXIT

    cat <<'EOF' > $tmpfile
# Which Homeshick castles do you want to install?
#
# Each line is passed as the argument(s) to `homeshick clone`.
# Lines starting with '#' will be ignored.
#
# If you remove or comment a line that castle will NOT be installed.
# However, if you remove or comment everything, the script will be aborted.

jbaiter/dotfiles
jojo@jbaiter.de:~/repos/secrets.git
EOF

    ${VISUAL:-vi} $tmpfile

    code=$?

    if [[ $code -ne 0 ]]; then
    echo "Editor returned ${code}." 1>&2
    exit 1
    fi

    castles=()

    while read line; do
    castle=$(echo "$line" | sed '/^[ \t]*#/d;s/^[ \t]*\(.*\)[ \t]*$/\1/')
    if [[ -n $castle ]]; then
        castles+=("$castle")
    fi
    done <$tmpfile

    if [[ ${#castles[@]} -eq 0 ]]; then
    echo "No castles to install. Aborting."
    exit 0
    fi

    if [[ ! -f $HOME/.homesick/repos/homeshick/homeshick.sh ]]; then
    git clone git://github.com/andsens/homeshick.git $HOME/.homesick/repos/homeshick
    fi

    source $HOME/.homesick/repos/homeshick/homeshick.sh

    for castle in "${castles[@]}"; do
    homeshick clone "$castle"
    done
}

install_nvim() {
    mkdir -p ~/.build
    unset LUA_PATH
    unset LUA_CPATH
    sudo apt install libtool libtool-bin autoconf automake cmake g++ \
                     pkg-config unzip
    git clone https://github.com/neovim/neovim ~/.build/neovim
    cd ~/.build/neovim
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
}

install_bspwm() {
    mkdir -p ~/.build
    sudo apt install git gcc make xcb libxcb-util0-dev libxcb-ewmh-dev \
                     libxcb-randr0-dev libxcb-icccm4-dev libxcb-keysyms1-dev \
                     libxcb-xinerama0-dev libasound2-dev libxcb-xtest0-dev \
                     python3.5
    git clone https://github.com/baskerville/bspwm.git ~/.build/bspwm
    git clone https://github.com/baskerville/sxhkd.git ~/.build/sxhkd
    git clone https://github.com/LemonBoy/bar.git ~/.build/lemonbar
    git clone https://github.com/baskerville/xtitle.git ~/.build/xtitle
    git clone https://github.com/baskerville/xdo.git ~/.build/xdo

    for proj in bspwm sxhkd lemonbar xtitle xdo; do
        cd ~/.build/$proj
        make
        sudo make install
    done

    git clone https://github.com/baskverville/sutils.git ~/.build/sutils
    cd ~/.build/sutils
    make
    make BINPREFIX=~/.bin/ install
}

install_compton() {
    mkdir -p ~/.build
    sudo apt install libconfig-dev libx11-dev libxcomposite-dev libxdamage-dev \
                     libxfixes-dev libxext-dev libxrender-dev libxrandr-dev \
                     libxinerama-dev pkg-config make x11proto-core-dev \
                     x11-utils libpcre3-dev libdrm-dev libgl1-mesa-dev \
                     libdbus-1-dev asciidoc
    git clone https://github.com/chjj/compton.git ~/.build/compton
    cd ~/.build/compton
    make
    make docs
    sudo make install
}

install_basics
nvim -v &> /dev/null || install_nvim
install_bspwm
install_compton
install_dotfiles
