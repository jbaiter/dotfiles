#!/bin/sh

# Host-specific actions
if [[ $(hostname) == 'workstation' ]]; then
    xrandr --output DVI-I-1 --pos 1080x490 \
           --output DVI-D-0 --rotate left --left-of DVI-I-1 \
           --output HDMI-0 --off
elif [[ $(hostname) == 'thinkpad' ]]; then
    # Disable tapping on touchpad while typing
    syndaemon -t -k -i 1 -d &
fi

# Disable  bell
xset -b

# Set mouse cursor
xsetroot -cursor_name left_ptr

# Use eurkey keyboard mapping
setxkbmap eurkey

# Load X settings
xrdb ~/.Xresources
echo "Xft.dpi: $XORG_DPI" |xrdb -merge

# Load machine-specific keymappings
if [[ -f ~/.Xmodmap ]]
    xmodmap ~/.Xmodmap
fi

# Set wallpaper
feh --bg-fill ~/.wallpapers/sorpasso-beach.jpg

# Adapt the colors to the daytime
redshift -l 48.367842:10.892248 -t 5500:4000 &

# Hide mouse cursor after 2.5 seconds of inactivity
unclutter -idle 2.5 &

sxhkd &
urxvt &
exec bspwm
