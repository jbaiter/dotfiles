#!/bin/sh

exec xautolock -detectsleep \
  -time 5 -locker "$HOME/.bin/lock.py" \
  -notify 35 \
  -notifier "notify-send -u critical -t 10000 -- 'LOCKING screen in 30 seconds'"
