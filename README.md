# gamedownsights

A [gamescope](https://github.com/ValveSoftware/gamescope) wrapper that
automatically sets the gamescope arguments and environment variables based
on for your display settings.

## Supported Desktop Environments

 * KDE Plasma 6 (Resolution / Refresh Rate / VRR / HDR)

## Installation

### With Nix

```
nix profile install github:eth-p/gamedownsights
```

## Usage

To use `gamedownsights`, add it to the launch options for the Steam game(s)
you want to use it with:

```
gamedownsights %command%
```

**Show detected display configuration:**

```
gamedownsights-config print
```

**Show generated gamescope command:**

```
gamedownsights-config print-launchcmd
```

## Configuration

If you want to override any settings globally or on a per-game basis,
you can create a `~/.config/gamedownsights/override.sh` bash script.

The following variables can be overidden:

```
DISPLAY_PORT=''
DISPLAY_WIDTH=1920
DISPLAY_HEIGHT=1080
DISPLAY_REFRESH_RATE=60
DISPLAY_USE_VRR=false
DISPLAY_USE_HDR=false
DISPLAY_ITM_NITS=300          # set to 0 to disable
DISPLAYSERVER_PROTOCOL=x11    # currently does not have any effect
GAMESCOPE_EXTRA_ARGS=()
ENABLE_GAMEMODE=false
```
