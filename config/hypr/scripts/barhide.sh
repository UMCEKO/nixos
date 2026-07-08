#!/usr/bin/env bash
# Auto-hide HyprPanel: shows on cursor near top edge, hides otherwise

THRESHOLD_SHOW=5
THRESHOLD_HIDE=60
POLL=0.1
VISIBLE=true

# Wait for hyprpanel to start
while ! pgrep -f hyprpanel > /dev/null; do
    sleep 1
done
sleep 2

# Hide on start
hyprpanel -t bar-0 2>/dev/null
VISIBLE=false

while true; do
    y=$(hyprctl cursorpos | awk -F', ' '{print $2}')

    if [ "$VISIBLE" = false ] && [ "$y" -le "$THRESHOLD_SHOW" ]; then
        hyprpanel -t bar-0 2>/dev/null
        VISIBLE=true
    elif [ "$VISIBLE" = true ] && [ "$y" -gt "$THRESHOLD_HIDE" ]; then
        hyprpanel -t bar-0 2>/dev/null
        VISIBLE=false
    fi

    sleep $POLL
done
