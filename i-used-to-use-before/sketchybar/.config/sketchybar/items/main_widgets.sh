#!/usr/bin/env sh

sketchybar --add       alias              MeetingBar right                              \
           --set       MeetingBar         background.padding_right=-8                   \
                                          background.padding_left=-6                    \
                                          update_freq=60                                \
                                                                                        \
           --add       item               widget.time right                           \
           --set       widget.time      update_freq=2                                 \
                                          icon.drawing=on                               \
                                          script="$PLUGIN_DIR/time.sh"                  \
                                                                                        \
           --clone     widget.date      label_template                                \
           --set       widget.date      update_freq=60                                \
                                          position=right                                \
                                          label=cal                                     \
                                          drawing=on                                    \
                                          background.padding_right=0                    \
                                          script="$PLUGIN_DIR/date.sh"                  \
                                                                                        \                                                                                        \
           --add       item               widget.battery right                        \
           --set       widget.battery     update_freq=1                                \
                                          icon.drawing=on                               \
                                          script="$PLUGIN_DIR/battery.sh"               \
                                                                                        \
           --add       item               widget.weather right                        \
           --set       widget.weather   update_freq=15                                \
                                          icon.drawing=on                               \
                                          script="$PLUGIN_DIR/weather.sh"               \
           --add       bracket            widget                                      \
                                          MeetingBar                                    \
                                          widget.time                                 \
                                          widget.date                                 \
                                          widget.battery                              \
                                          widget.weather                              \
                                          widget.volume \
           --set       widget           background.drawing=on

sketchybar --add item volume right \
           --set volume script="$PLUGIN_DIR/volume.sh" \
           --subscribe volume volume_change 

 #--add       item               mailIndicator right                           \
           #--set       mailIndicator      update_freq=30                                \
           #                               script="$PLUGIN_DIR/mailIndicator.sh"         \
           #                               icon.font="$FONT:Bold:16.0"                   \
           #                               icon=􀍜                                        \
           #                               label.padding_right=8                         \
           #                               background.padding_right=0                    \
           #                               label=!                                       \
           #                                                                             \
                             # -add bracket             mailIndicator                                 \
