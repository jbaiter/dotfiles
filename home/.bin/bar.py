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

# TODO: Temperature widget
# TODO: CPU usage widget
# TODO: GPU usage widget
# TODO: Memory usage widget

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
                elif desktop.is_occupied:
                    out.append(self.icons['free'])
                else:
                    out.append(fg(color['muted'], self.icons['free']))
                out.append("%{A}")
        return "".join(out)


class CpuLoad(Widget):
    CpuTimes = namedtuple("CpuTimes", ["user", "nice", "system", "idle"])

    def __init__(self, *args, **kwargs):
        self.last_times = []
        self.load = []

    def _read_times(self):
        times = []
        with open("/proc/stat") as fp:
            for line in fp:
                if not line.startswith("cpu") or line[3] == ' ':
                    continue
                times.append(
                    self.CpuTimes(*(int(n) for n in line.split(" ")[1:5])))
        return times

    @staticmethod
    def calculate(t1, t2):
        t1_all = sum(t1)
        t1_busy = t1_all - t1.idle
        t2_all = sum(t2)
        t2_busy = t2_all - t2.idle
        busy_delta = t2_busy - t1_busy
        all_delta = t2_all - t1_all
        if all_delta == 0:
            return 0
        busy_perc = (busy_delta / all_delta) * 100
        return busy_perc

    def render(self):
        def format(avg):
            if avg > 90:
                col = color['bad']
            elif avg < 20:
                col = color['muted']
            else:
                col = ''
            return fg(col, "{:2}".format(avg))
        if not self.last_times:
            self.last_times = self._read_times()
            return ''
        else:
            cur_times = self._read_times()
            load = [abs(int(self.calculate(t1, t2)))
                    for t1, t2 in zip(cur_times, self.last_times)]
            self.last_times = cur_times
        return '\ue026 ' + ' '.join(format(avg) for avg in load)


class Memory(Widget):
    pat = re.compile(r'^([\w\d]+):\s+(\d+)\s*(?:kB)?$')

    def __init__(self, *args, **kwargs):
        self.meminfo = None

    @staticmethod
    def sizeof_fmt(num, suffix='B'):
        for unit in ['K','M','G','T','P','E','Z']:
            if abs(num) < 1024.0:
                return "%3.1f%s%s" % (num, unit, suffix)
            num /= 1024.0
        return "%.1f%s%s" % (num, 'Yi', suffix)

    def render(self):
        with open("/proc/meminfo") as fp:
            self.meminfo = {}
            for l in fp:
                match = self.pat.match(l)
                if match:
                    key, val = match.groups()
                    self.meminfo[key] = int(val)

        mem_occupied =  self.meminfo['MemTotal'] - self.meminfo['MemAvailable']
        return '\ue021 ' + self.sizeof_fmt(mem_occupied, suffix='')


class WindowTitle(Widget):
    def __init__(self, pipe, hooks):
        self.client = subprocess.Popen(
            ['xtitle', '-f', 'window_title|%s', '-s', '-i', '-t', '100'],
            stdout=pipe)
        atexit.register(self.client.kill)
        hooks['window_title|'] = self
        self.title = ''

    def update(self, line):
        if line is None:
            return ''
        self.title = line.strip().replace('window_title|', '')

    def render(self):
        return self.title


class Battery(Widget):
    icons = [chr(c) for c in chain([0xe242], range(0xe24c, 0xe255))]
    icon_charging = '\ue239'
    icon_unknown = '\ue23a'
    icon_rate = '\ue215'
    pat = re.compile(
        r'\s*?(state|energy-rate|percentage):\s*?([0-9.]+|\w+)\s*[W%]?')

    @staticmethod
    def available():
        return file_contents('/sys/class/power_supply/BAT0/present') == '1'

    def __init__(self, pipe, hooks):
        self.client = subprocess.Popen(
            ['upower', '-i', '/org/freedesktop/UPower/devices/battery_BAT0',
             '--monitor-detail'], stdout=pipe)
        hooks[self.pat] = self
        self.rate = None
        self.charge = None
        self.discharging = True

    def update(self, line):
        if not line:
            return
        field, value = self.pat.match(line).groups()
        if field == 'energy-rate':
            self.rate = float(value)
        elif field == 'percentage':
            self.charge = int(value)
        elif field == 'state':
            self.discharging = (value == 'discharging')
            if value == 'fully-charged':
                self.charge = 100

    def render(self):
        c = color['bad'] if not self.charge or self.charge < 30 else color['good']
        if self.charge is None:
            icon = '%%{T2}%s%%{T1} ' % self.icon_unknown
        elif not self.discharging:
            icon = '%%{T2}%s%%{T1} ' % self.icon_charging
        else:
            icon = '%%{T2}%s%%{T1} ' % self.icons[
                round(self.charge / 100 * (len(self.icons) - 1))]
        return "{}{} {}{}".format(
            fg(c, icon), self.charge or '?',
            fg(color['bad' if self.discharging else 'good'], self.icon_rate),
            '?' if self.rate is None else int(self.rate))


class PulseAudio(Widget):
    icon_loud = '\ue05d '
    icon_mute = '\ue04f '

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
        return datetime.datetime.now().strftime(
            '\ue1cd %a %b %d  \ue017 %H:%M')


class Wifi(Widget):
    ethernet_icon = '\ue19c'
    icons = ('\ue047', '\ue048')

    @staticmethod
    def available():
        try:
            return len(output_of(['sudo', '-n', 'iw', 'dev'])) > 0
        except:
            return False

    def render(self):
        strength = 0.0
        iw = output_of(['sudo', 'iwgetid']).split()
        profile = ''
        if len(iw) == 0:
            eth = output_of(['ip', 'addr', 'show', 'eth0'])
            if 'inet' in eth:
                profile = ''
                strength = 'ethernet'
            else:
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
        if strength == 'ethernet':
            c = color['good']
            icon = self.ethernet_icon
        elif strength > 40:
            c = color['good']
            icon = self.icons[1]
        else:
            c = color['bad']
            icon = self.icons[0]
        profile = fg(c, icon) + ' ' + profile
        return profile


class Ping(Widget):
    latency_icons = ('\ue191', '\ue192', '\ue193', '\ue194', '\ue195', '\ue196')
    missed_icon = '\ue140'
    hook_pat = re.compile(r'^(64 bytes from|no answer yet).*?')
    pat = re.compile(r'^.*time=([0-9.]+) ms$')

    def __init__(self, pipe, hooks):
        client = subprocess.Popen(['ping', '-W', '5', '-i', '10', '8.8.8.8'],
                                  stdout=pipe)
        atexit.register(client.kill)
        self.latency = 1
        self.packet_lost = False
        hooks[self.hook_pat] = self

    def update(self, line):
        if not line:
            return
        elif line.startswith('no answer'):
            self.packet_lost = True
            return
        self.packet_lost = False
        latency = self.pat.match(line).group(1)
        latency = float(latency)
        self.latency = latency

    def render(self):
        c = color['good' if self.latency < 500 else 'bad']
        icon_idx = min((int(self.latency)//100), 5)
        return "{}{}".format(
            fg(c, self.latency_icons[icon_idx]),
            fg(colors['bad'], self.missed_icon) if self.packet_lost else '')


class MPD(Widget):
    icon_paused = '\ue059 '
    icon_playing = '\ue05c '
    audio_files = ['mp3', 'ogg', 'flac', 'mp4', 'm4a']

    @staticmethod
    def available():
        try:
            subprocess.run(['mpc'], check=True, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE)
            return True
        except:
            return False

    def render(self):
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
        if self.status == 'playing':
            return self.icon_playing + fg(color['muted'], self.song)
        elif self.status == 'paused':
            return self.icon_paused + fg(color['muted'], self.song)
        return ''


widgets = ['%{l}', Bspwm, '%{c}', '  ', CpuLoad, '  ',  Memory, '%{r}',
           Wifi, ' ', Ping, '  ', Battery, '  ', PulseAudio, '  ', Clock]

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
                        if isinstance(first, str):
                            matches = line.startswith(first)
                        else:
                            matches = first.match(line)
                        if matches:
                            updated = True
                            hook.update(line)
        else:
            updated = True
        # render
        if updated:
            print(''.join(w.render() for w in ws))
            sys.stdout.flush()
