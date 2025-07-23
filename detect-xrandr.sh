#!/usr/bin/env false
# Homepage: https://github.com/eth-p/gamedownsights

#shellcheck shell=bash
#shellcheck disable=SC2016 # yq query variables trigger false positive
if [ "${#BASH_SOURCE[@]}" -eq 1 ]; then
    echo "error: do not run detect-xrandr.sh" 1>&2
    exit 1
fi

# Read display configuration using `xrandr`.
# This cannot detect HDR or VRR configuration.

detect_display_configuration_impls+=(detect_display_configuration:xrandr)
detect_display_configuration:xrandr() {
    # Get the primary display.
    conf=$(
        LC_ALL=C xrandr | awk '
            BEGIN { output=0 }
            output && /^  / && /\*\+$/ { print $0 }
            output && !/^  / { exit }
            /^([^ ]+) connected primary/ { print $0; output=1 }
        '
    )
    
    {
        # Input example:
        # ```
        # DP-4 connected primary 2560x1440+0+0 (normal left inverted right x axis y axis) 603mm x 347mm
        #    2560x1440    239.88*+
        # ```
        read -r port _
        read -r xrandr_resolution xrandr_refresh_rate
        IFS='x' read -r width height <<<"$xrandr_resolution"

        #shellcheck disable=SC2001
        refresh_rate="$(sed 's/\*+$//' <<<"$xrandr_refresh_rate" | ceil)"
    
        set_var DISPLAY_PORT "$port"
        set_var DISPLAY_WIDTH "$width"
        set_var DISPLAY_HEIGHT "$height"
        set_var DISPLAY_REFRESH_RATE "$refresh_rate"
    } <<<"$conf"

    warn "Cannot detect VRR or HDR status using xrandr!"
}
