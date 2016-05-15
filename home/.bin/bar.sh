#!/bin/sh

# configurables
if [ $(hostname) = 'workstation' ]; then
    width=1920
    pos_x=1080
fi
font="-*-profont-medium-*-*-*-12-*-*-*-*-*-*-*"
icon_font="-wuncon-siji-medium-r-normal-*-*-*-*-*-*-*-*-*"""
wm_name=bspwm_panel
color_foreground="#ffffff"
color_background="#282f3a"

set -f

bar.py \
    | lemonbar -a 32 -n $wm_name -f $font -f $icon_font \
               -g "${width}x${PANEL_HEIGHT}+${x_pos}+${y_pos}" \
               -F $color_foreground -B $color_background \
    | sh
