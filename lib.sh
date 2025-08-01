#!/usr/bin/env false
# Homepage: https://github.com/eth-p/gamedownsights

#shellcheck shell=bash
if [ "${#BASH_SOURCE[@]}" -eq 1 ]; then
    echo "error: do not run lib.sh" 1>&2
    exit 1
fi

# awk runs the GNU version of awk.
if command -v gawk &>/dev/null; then
    awk() { gawk "$@" || return $?; }
fi

# ceil rounds up a floating-point number to the nearest integer above it.
# shellcheck disable=SC2120 # indirect call
ceil() {
    if [[ "$#" -gt 0 ]]; then
        exec <<<"$(printf "%s\n" "$@")"
    fi

    awk '{ print int($0 + 0.5) }'
}

# warn is an alias for printf that prints to stderr instead of stdout.
warn() {
    if [[ "$#" -gt 1 ]]; then
        # shellcheck disable=SC2059
        printf "WARN: $1\n" "${@:2}" 1>&2
    else
        # shellcheck disable=SC2059
        printf "WARN: $1\n" 1>&2
    fi
}

# join uses the first argument as a delimiter to join the remaining arguments.
join() {
    local delim="$1"
    shift

    if [[ "$#" -gt 0 ]]; then
        printf "%s" "$1"
        shift
    fi

    if [[ "$#" -gt 0 ]]; then
        printf "${delim}%s" "$@"
    fi
}

# default_display_configuration sets the detected display configuration
# parameters to their default values.
#
#shellcheck disable=SC2034 # used externally
default_display_configuration() {
    DISPLAY_PORT=''
    DISPLAY_WIDTH=1920
    DISPLAY_HEIGHT=1080
    DISPLAY_REFRESH_RATE=60
    DISPLAY_USE_VRR=false
    DISPLAY_USE_HDR=false
    DISPLAY_ITM_NITS=300
    DISPLAYSERVER_PROTOCOL=x11
    GAMESCOPE_EXTRA_ARGS=()
    __DISPLAY_CONFIGURATION_VARS=(
        DISPLAY_PORT
        DISPLAY_WIDTH
        DISPLAY_HEIGHT
        DISPLAY_REFRESH_RATE
        DISPLAY_USE_VRR
        DISPLAY_USE_HDR
        DISPLAY_ITM_NITS
        DISPLAYSERVER_PROTOCOL
    )

    ENABLE_STEAM_LDPRELOAD_WORKAROUND=true
    ENABLE_GAMESCOPE=true
    ENABLE_MANGOHUD=false
    ENABLE_GAMEMODE=false
    if command -v gamemoderun &>/dev/null; then
        ENABLE_GAMEMODE=true
    fi
}

# default_display_configuration sets the detected display configuration
# parameters to their default values.
detect_display_configuration_impls=()
detect_display_configuration() {
    default_display_configuration
    DISPLAY_DETECTED_USING=()

    #shellcheck disable=SC2317 # indirect call
    set_var() {
        printf "%s\x01%s\x02" "$1" "$2" >&3
    }

    # Detect wayland.
    if [[ "${XDG_SESSION_TYPE:-}" = "wayland" ]]; then
        #shellcheck disable=SC2034 # used externally
        DISPLAYSERVER_PROTOCOL=wayland
    fi

    # Run each of the possible implementations in a subshell.
    # It has to be done this way to prevent `set -e` from being suppressed.
    local impl_fn
    for impl_fn in "${detect_display_configuration_impls[@]}"; do
        # Reset the pending display configuration variables.
        for v in "${__DISPLAY_CONFIGURATION_VARS[@]}"; do
            eval "pend_${v}=\"\$${v}\""
        done

        # Run the display configuration function in a subshell
        # and have it write back to FD 3.
        exec 3< <({
            "$impl_fn"
            set_var __RESULT 0
        } 3>&1 1>&2)

        # Read the variables it sends back.
        while IFS=$'\x01' read -u 3 -d $'\x02' -r var value; do
            if [[ "$var" = "__RESULT" && "$value" -eq 0 ]]; then
                # Display configuration detection worked.
                DISPLAY_DETECTED_USING+=("$impl_fn")

                # Commit the variables.
                for v in "${__DISPLAY_CONFIGURATION_VARS[@]}"; do
                    eval "${v}=\"\$pend_${v}\""
                done

                load_display_configuration_overrides
                return 0
            fi

            #shellcheck disable=SC2034 # used in eval
            case "$var" in
            DISPLAY_PORT) pend_DISPLAY_PORT="$value" ;;
            DISPLAY_WIDTH) pend_DISPLAY_WIDTH="$value" ;;
            DISPLAY_HEIGHT) pend_DISPLAY_HEIGHT="$value" ;;
            DISPLAY_REFRESH_RATE) pend_DISPLAY_REFRESH_RATE="$value" ;;
            DISPLAY_USE_VRR) pend_DISPLAY_USE_VRR="$value" ;;
            DISPLAY_USE_HDR) pend_DISPLAY_USE_HDR="$value" ;;
            DISPLAY_ITM_NITS) pend_DISPLAY_ITM_NITS="$value" ;;
            DISPLAYSERVER_PROTOCOL) pend_DISPLAYSERVER_PROTOCOL="$value" ;;
            *) warn "Function tried to set variable '%s', but is not allowed." "$var" ;;
            esac
        done

        # Display configuration detection did not work.
        # It would have returned early if it had.
        warn "Error using '%s'" "$impl_fn"
    done

    warn "Could not detect display configuration. Using defaults!"
    load_display_configuration_overrides
    return 1
}

load_display_configuration_overrides() {
    # Load built-in overrides.
    # shellcheck source=./game-overrides.sh
    source "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")/game-overrides.sh"

    # Load user-specified overrides.
    local configdir="${XDG_CONFIG_HOME:-$HOME/.config}/gamedownsights"

    if [[ -f "${configdir}/override.sh" ]]; then
        printf "Loading configuration overrides from: %s\n" "${configdir}/override.sh"

        # shellcheck source=/dev/null
        source "${configdir}/override.sh"
    fi
}

generate_gamescope_command() {
    local env_vars env_ldpreload gamescope_args

    env_vars=()
    env_ldpreload=()
    gamescope_args=(
        --fullscreen
        -w "$DISPLAY_WIDTH" -W "$DISPLAY_WIDTH"
        -h "$DISPLAY_HEIGHT" -H "$DISPLAY_HEIGHT"
        --nested-refresh "$DISPLAY_REFRESH_RATE"
        --prefer-output "$DISPLAY_PORT"
        --scaler integer
    )

    # Read LD_PRELOAD items.
    local item
    while read -r -d':' item; do
        if [[ -n "$item" ]]; then
            env_ldpreload+=("$item")
        fi
    done <<< "${LD_PRELOAD:-}:"

    # Enable HDR.
    if [[ "$DISPLAY_USE_HDR" = "true" ]]; then
        gamescope_args+=(--hdr-enabled)
        env_vars+=(
            DXVK_HDR=1
        )

        if [[ "$ENABLE_GAMESCOPE" = "true" ]]; then
            env_vars+=(
                ENABLE_GAMESCOPE_WSI=1
            )
        else
            env_vars+=(
                ENABLE_HDR_WSI=1
                PROTON_ENABLE_WAYLAND=1
                PROTON_ENABLE_HDR=1
            ) 
        fi

        # Enable inverse tone mapping.
        if [[ "$DISPLAY_ITM_NITS" != "0" ]]; then
            gamescope_args+=(
                --hdr-itm-enabled
                --hdr-sdr-content-nits "$DISPLAY_ITM_NITS"
            )
        fi
    fi

    if [[ "$DISPLAY_USE_VRR" = "true" ]]; then
        gamescope_args+=(--adaptive-sync)
    fi

    if [[ "$DISPLAYSERVER_PROTOCOL" = "wayland" ]]; then
        :
        # DISABLED -- This breaks gamescope.
        # gamescope_args+=(--expose-wayland)
    fi

    local arg
    for arg in "${GAMESCOPE_EXTRA_ARGS[@]}"; do
        gamescope_args+=("$arg")
    done

    # Reset LD_PRELOAD.
    # https://github.com/ValveSoftware/gamescope/issues/163
    if [[ "$ENABLE_STEAM_LDPRELOAD_WORKAROUND" = "true" && "$ENABLE_GAMESCOPE" = "true" ]]; then
        printf "env LD_PRELOAD='' "
    fi

    # GameMode.
    if [[ "$ENABLE_GAMEMODE" = true ]]; then
        printf "gamemoderun "
        env_ldpreload+=("libgamemodeauto.so.0")
    fi

    # MangoHud.
    if [[ "$ENABLE_MANGOHUD" = true ]]; then
        if [[ "$ENABLE_GAMESCOPE" = true ]]; then
            gamescope_args+=(--mangoapp)
        else
            printf "%q " mangohud
        fi
    fi

    # Gamescope.
    if [[ "$ENABLE_GAMESCOPE" = true ]]; then
        printf "%q " gamescope "${gamescope_args[@]}" --
    fi

    # Environment variables.
    if [[ "${#env_ldpreload[@]}" -gt 0 ]]; then
        env_vars+=("LD_PRELOAD=$(join ":" "${env_ldpreload[@]}")")
    fi

    if [[ "${#env_vars[@]}" -gt 0 ]]; then
        printf "env "
        printf "%q " "${env_vars[@]}"
    fi

    # Launch command.
    if [[ "$#" -gt 0 ]]; then
        printf "%q " "$@"
    fi

    printf "\n"
}

# ----------------------------------------------------------------------------
# Load detect_display_configuration implementations:
# ----------------------------------------------------------------------------

# Plasma 6
if [[ 
    "${XDG_CURRENT_DESKTOP:-}" = "KDE" &&
    "${KDE_SESSION_VERSION:-}" = "6" ]]; then
    source "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")/detect-plasma6.sh"
# Hyprland
elif [[
      "${XDG_CURRENT_DESKTOP:-}" = "Hyprland" ]]; then
      source "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")/detect-hyprland.sh"
else
    # Fallback: xrandr
    # Does not detect VRR, HDR.
    source "$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")/detect-xrandr.sh"
fi
