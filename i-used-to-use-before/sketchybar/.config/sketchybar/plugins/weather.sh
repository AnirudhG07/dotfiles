#!/usr/bin/env bash

status=$(timeout 5 https 'wttr.in?format=%C+|+%t' | tail -n 1)

if [ -z "$status" ]; then
  status=$(curl -s 'wttr.in?format=%C+|+%t' | tail -n 1)
fi
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
  "lightdrizzle")
    icon="􀇗"
  ;;
  "rainshower")
    icon="􀇉"
    ;;
  *)
    icon="􀇃 ?" 
    ;;
esac

sketchybar --set $NAME icon="$icon" label="$temp"
