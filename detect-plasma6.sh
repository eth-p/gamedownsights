#!/usr/bin/env false
# Homepage: https://github.com/eth-p/gamedownsights

#shellcheck shell=bash
#shellcheck disable=SC2016 # yq query variables trigger false positive
if [ "${#BASH_SOURCE[@]}" -eq 1 ]; then
    echo "error: do not run detect-plasma6.sh" 1>&2
    exit 1
fi

# Read display configuration for KDE Plasma using `kscreen-doctor`.

detect_display_configuration_impls+=(detect_display_configuration:plasma6)
detect_display_configuration:plasma6() {
    # Get the primary display.
    conf=$(
        kscreen-doctor -j | yq --input-format=json '
            .outputs[] | select(.priority == 1)
        '
    )

    set_var DISPLAY_PORT "$(yq -r '.name' <<<"$conf")"
    set_var DISPLAY_WIDTH "$(yq -r '.size.width' <<<"$conf")"
    set_var DISPLAY_HEIGHT "$(yq -r '.size.height' <<<"$conf")"
    set_var DISPLAY_USE_VRR "$(yq -r '.size.height' <<<"$conf")"
    set_var DISPLAY_USE_HDR "$(yq -r '.hdr' <<<"$conf")"
    set_var DISPLAY_ITM_NITS "$(yq -r '."sdr-brightness"' <<<"$conf")"
    set_var DISPLAY_REFRESH_RATE "$({
        yq -r '
            .currentModeId as $mode 
                | .modes[]
                | select(.id == $mode)
                | .refreshRate
        ' <<<"$conf" | ceil
    })"
}
