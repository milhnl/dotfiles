export MOZ_ENABLE_WAYLAND=1
sleep 5 #No clue why, but sway refuses to start otherwise
[ "$(tty)" != /dev/tty1 ] || sway
