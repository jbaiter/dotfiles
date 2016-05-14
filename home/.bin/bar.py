#!/usr/bin/env python3.5
import atexit
import datetime
import os
import re
import select
import subprocess
import sys
from collections import namedtuple
from itertools import chain

color = {
    "foreground": "#ffffff",
    "background": "#282f3a",
    "lightbackground": "#414a59",
    "primary": "#5294e2",
    "good": "#91cc57",
    "bad": "#cc575d",
    "muted": "#999999",
}


def fg(color, text):
    if not color:
        return text
    return '%{{F{color}}}{text}%{{F-}}'.format(color=color, text=text)


def bg(color, text):
    if not color:
        return text
    return '%{{B{color}}}{text}%{{B-}}'.format(color=color, text=text)


def file_contents(f):
    try:
        with open(f, 'r') as fp:
            return fp.read().strip()
    except:
        return None


def output_of(cmd):
    try:
        return (subprocess.run(cmd, stdout=subprocess.PIPE)
                          .stdout.decode('utf-8').strip())
    except:
        return None


class Widget(object):
    @staticmethod
    def available():
        """Determines if widget is available/makes sense on this system."""
        return True

    def __init__(self, pipe, hooks):
        """Initialize widget. The widget may spawn a subprocess and feed its
        stdout into pipe. The main loop runs through all lines received on all
        widget pipes and calls hooks based on the first word in a line. If

        hooks["my_trigger"] = self

        is set, this widget's update function will be called if the main loop
        sees a line starting with 'my_trigger'."""
        pass

    def update(self, line):
        """Update widget's internal state based on data received via the main
           loop."""
        pass

    def render(self):
        """Render the widget."""
        return ''


class Text(Widget):
    def __init__(self, text):
        super(Widget, self)
        self.text = text

    def render(self):
        return self.text


Monitor = namedtuple('Monitor', ('name', 'is_focused', 'desktops', 'layout',
                                 'focused_flags', 'focused_state'))
Desktop = namedtuple('Desktop', ('name', 'is_occupied', 'is_focused',
                                 'is_urgent'))
MONITOR_PAT = re.compile(r'([mM])(.*?):(.*?):?(?=[mM]|$)')


class Bspwm(Widget):
    icons = {'free': '\ue1bc',
             'occupied': '\ue1c2',
             'urgent': '\ue0b3',
             'monitor': '\ue09f'}
    colors = {'unfocused': '',
              'focused': ''}

    def __init__(self, pipe, hooks):
        self.client = subprocess.Popen(
            ['bspc', 'subscribe', 'report'], stdout=pipe)
        atexit.register(self.client.kill)
        hooks['W'] = self

    def update(self, line):
        self.monitors = []
        if line is None:
            return ''
        line = line[1:].strip()
        for mon_stat, mon_name, data in MONITOR_PAT.findall(line):
            mon_is_focused = mon_stat.isupper()
            focused_state = None
            focused_flags = tuple()
            layout = None
            desktops = []
            for d in data.split(':'):
                if d[0] == 'L':
                    layout = d[1:]
                elif d[0] == 'T':
                    focused_state = d[1:]
                elif d[0] == 'G':
                    focused_flags = tuple(d[1:])
                else:
                    desktops.append(Desktop(
                        name=d[1:],
                        is_occupied=d[0].lower() == 'o',
                        is_focused=d[0].isupper(),
                        is_urgent=d[0].lower() == 'u'))
            self.monitors.append(Monitor(
                name=mon_name, is_focused=mon_is_focused,
                desktops=desktops, layout=layout,
                focused_flags=focused_flags,
                focused_state=focused_state))

    def render(self):
        out = []
        for mon_idx, monitor in enumerate(self.monitors):
            out.append("%{{A:bspc monitor -f {}:}}".format(monitor.name))
            icon_color = self.colors[
                'focused' if monitor.is_focused else 'unfocused']
            out.append(fg(icon_color, self.icons['monitor']))
            out.append("%{A}")
            for desktop in monitor.desktops:
                out.append("%{{A:bspc desktop -f {}:}}".format(desktop.name))
                if desktop.is_focused or desktop.is_urgent:
                    icon_color = self.colors[
                        'focused' if desktop.is_focused else 'unfocused']
                    icon = self.icons[
                        'urgent' if desktop.is_urgent else 'occupied']
                    out.append(fg(icon_color, icon))
                else:
                    out.append(self.icons['free'])
                out.append("%{A}")
        return "".join(out)


class WindowTitle(Widget):
    def __init__(self, pipe, hooks):
        self.client = subprocess.Popen(
            ['xtitle', '-f', 'window_title: %s', '-s', '-i', '-t', '100'],
            stdout=pipe)
        atexit.register(self.client.kill)
        hooks['window_title: '] = self
        self.title = ''

    def update(self, line):
        if line is None:
            return ''
        self.title = line.strip().replace('window_title: ', '')

    def render(self):
        return self.title


class Battery(Widget):
    icons = [chr(c) for c in chain([0xe242], range(0xe24c, 0xe255))]
    icon_charging = '\ue239'

    @staticmethod
    def available():
        return file_contents('/sys/class/power_supply/BAT0/present') == '1'

    def render(self):
        try:
            charge = int(file_contents(
                '/sys/class/power_supply/BAT0/capacity'))
        except:
            charge = 0
        c = color['bad'] if charge < 30 else color['good']
        bat_status = file_contents('/sys/class/power_supply/BAT0/status')
        if bat_status != 'Discharging':
            icon = ' %%{T2}%s%%{T1} ' % self.icon_charging
        else:
            icon = ' %%{T2}%s%%{T1} ' % self.icons[
                round(charge / 100 * (len(self.icons) - 1))]
        return fg(c, icon) + str(charge)


class PulseAudio(Widget):
    icon_loud = ' \ue05d '
    icon_mute = ' \ue04f '

    @staticmethod
    def available():
        try:
            subprocess.run(
                ['pactl', 'info'], check=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            return True
        except:
            return False

    def __init__(self, pipe, hooks):
        client = subprocess.Popen(['pactl', 'subscribe'], stdout=pipe)
        atexit.register(client.kill)
        self.volume = 0
        self.mute = False
        hooks["Event 'change' on sink"] = self

    def update(self, line):
        painfo = output_of(['pactl', 'info']).splitlines()
        look_for = None
        for l in painfo:
            if l.startswith('Default Sink:'):
                look_for = l.split(':')[1].strip()
                break
        in_sink = False
        look_for = 'Name: ' + look_for
        sink_list = output_of(['pactl', 'list', 'sinks']).splitlines()
        for l in sink_list:
            if not in_sink:
                if look_for in l:
                    in_sink = True
            else:
                if 'Mute:' in l:
                    if l.split(':')[1].strip() == 'yes':
                        self.mute = True
                    else:
                        self.mute = False
                elif 'Volume:' in l:
                    self.volume = int(l.split('/', 2)[1].strip()[:-1])
                    return

    def render(self):
        if self.mute:
            return fg(color['bad'], self.icon_mute) + '--'
        else:
            return fg(color['good'], self.icon_loud) + str(self.volume)


class Clock(Widget):
    def render(self):
        return datetime.datetime.now().strftime('  %a %b %d  %H:%M  ')


class Wifi(Widget):
    icon = ' \ue048 '

    @staticmethod
    def available():
        try:
            return len(output_of(['iw', 'dev'])) > 0
        except:
            return False

    def render(self):
        strength = 0.0
        iw = output_of(['iwgetid']).split()
        profile = ''
        if len(iw) == 0:
            profile = fg(color['muted'], 'disconnected')
        elif len(iw) < 2 or 'ESSID' not in iw[1]:
            profile = fg(color['muted'], 'connecting')
        else:
            profile = iw[1][7:-1]
            if profile == '':
                profile = fg(color['muted'], 'disconnected')
            else:
                lines = file_contents('/proc/net/wireless').splitlines()[2:]
                for line in lines:
                    cols = line.split()
                    if cols[0][:-1] == iw[0]:
                        strength = float(cols[2])
                        break
        c = color['good'] if strength > 40 else color['bad']
        profile = fg(c, self.icon) + profile
        if strength > 0:
            profile += ' ' + fg(color['muted'], str(int(strength)))
        return profile


class MPD(Widget):
    icon_paused = ' \ue059 '
    icon_playing = ' \ue05c '
    audio_files = ['mp3', 'ogg', 'flac', 'mp4', 'm4a']

    @staticmethod
    def available():
        try:
            subprocess.run(['mpc'], check=True, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
            return True
        except:
            return False

    def __init__(self, pipe, hooks):
        client = subprocess.Popen(['mpc', 'idleloop', 'player'], stdout=pipe)
        atexit.register(client.kill)
        self.song = ''
        self.status = 'stopped'
        hooks['player'] = self

    def update(self, line):
        status = output_of('mpc').splitlines()
        if len(status) < 3:
            self.song = ''
            self.status = 'stopped'
        else:
            self.song = status[0]
            has_song = (
                '.' in self.song[-5:] and
                self.song.rsplit('.', 1)[1].lower() in self.audio_files)
            if has_song:
                self.song = self.song.rsplit('/', 1)[1]
            self.status = status[1].split(None, 1)[0][1:-1]

    def render(self):
        if self.status == 'playing':
            return self.icon_playing + fg(color['muted'], self.song)
        elif self.status == 'paused':
            return self.icon_paused + fg(color['muted'], self.song)
        return ''


widgets = ['%{l}', Bspwm, '%{c}', WindowTitle, '%{r}', Wifi, Battery,
           PulseAudio, Clock]

if __name__ == '__main__':
    sread, swrite = os.pipe()
    hooks = {}

    ws = []
    for wc in widgets:
        if type(wc) is str:
            w = Text(wc)
            ws.append(w)
        elif wc.available():
            w = wc(swrite, hooks)
            w.update(None)
            ws.append(w)

    print(''.join(w.render() for w in ws))
    sys.stdout.flush()

    while True:
        ready, _, _ = select.select([sread], [], [], 5)
        # poll / update widgets (rerender only on updates that match hooks,
        # or on regular timeouts)
        updated = False
        if len(ready) > 0:
            for p in ready:
                lines = os.read(p, 4096).decode('utf-8').splitlines()
                for line in lines:
                    for first, hook in hooks.items():
                        if line.startswith(first):
                            updated = True
                            hook.update(line)
        else:
            updated = True
        # render
        if updated:
            print(''.join(w.render() for w in ws))
            sys.stdout.flush()