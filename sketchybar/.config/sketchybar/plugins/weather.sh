#!/usr/bin/env bash

status=$(https 'wttr.in?format=%C+|+%t' | tail -n 1)
condition=$(echo $status | awk -F '|' '{print $1}' | tr '[:upper:]' '[:lower:]')
condition="${condition// /}"
temp=$(echo $status | awk -F '|' '{print $2}')
temp="${temp//\+/}"
temp="${temp// /}"

# add more conditions here as appropriate
case "${condition}" in
  "sunny")
    icon="􀆮"
    ;;
  "partlycloudy")
    icon="􀇕"
    ;;
  "cloudy")
    icon="􀇃"
    ;;
  "overcast")
    icon="􀇣"
    ;;
  "rainy")
    icon="􀇇"
    ;;
  "clear")
    icon="􀇁"
    ;;
  "lightrain")
    icon="􀇅"
    ;;
  "patchyrainnearby")
    icon="􀇅"
    ;;
  "showerinvicinity")
    icon="􀇗"
  ;;
  "rainshower")
    icon="􀇉"
    ;;
  *)
    icon="Weath Error"
    ;;
esac

sketchybar --set $NAME icon="$icon" label="$temp"
