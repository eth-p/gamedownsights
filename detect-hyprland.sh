#!/usr/bin/env false
# Homepage: https://github.com/eth-p/gamedownsights

#shellcheck shell=bash
#shellcheck disable=SC2016 # yq query variables trigger false positive
if [ "${#BASH_SOURCE[@]}" -eq 1 ]; then
    echo "error: do not run detect-hyprland.sh" 1>&2
    exit 1
fi

# Read display configuration for Hyprland using `hyprctl`.

detect_display_configuration_impls+=(detect_display_configuration:hyprland)
detect_display_configuration:hyprland() {
    # Get the primary display.
    conf=$(
        hyprctl monitors -j | yq --input-format=json '
            .[] | select(.id == 0)
        '
    )

    set_var DISPLAY_PORT "$(yq -r '.name' <<<"$conf")"
    set_var DISPLAY_WIDTH "$(yq -r '.width' <<<"$conf")"
    set_var DISPLAY_HEIGHT "$(yq -r '.height' <<<"$conf")"
    set_var DISPLAY_USE_VRR "$(yq -r '.vrr' <<<"$conf")"
    # set_var DISPLAY_USE_HDR "$(yq -r '.hdr' <<<"$conf")" # NOT IMPLEMENTED
    # set_var DISPLAY_ITM_NITS "$(yq -r '."sdr-brightness"' <<<"$conf")" # NOT IMPLEMENTED
    set_var DISPLAY_REFRESH_RATE "$(yq -r '.refreshRate' <<<"$conf" | ceil)"
}
