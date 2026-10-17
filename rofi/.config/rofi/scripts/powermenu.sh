#!/usr/bin/env bash

if [ -z "$@" ]; then
    echo " Lock"
    echo " Logout"
    echo " Suspend"
    echo " Reboot"
    echo " Shutdown"
else
    case "$1" in
        *Lock)      loginctl lock-session ;;
        *Logout)    loginctl terminate-session self ;;
        *Suspend)   systemctl suspend ;;
        *Reboot)    systemctl reboot ;;
        *Shutdown)  systemctl poweroff ;;
    esac
fi
