# gamedownsights

A Steam launch options wrapper that automatically launches and configures
wrappers such as [gamescope](https://github.com/ValveSoftware/gamescope).

## Features

### Gamescope

https://github.com/ValveSoftware/gamescope

 - Enables HDR based on display settings.
 - Enables VRR based on display settings.
 - Enables inverse tone mapping for non-HDR games.
 - Sets refresh rate.
 - Sets screen resolution.

> [!tip]
> Gamescope is enabled by default.  
> You can disable it by adding `ENABLE_GAMEMODE=false` to your overrides.

### GameMode

https://github.com/FeralInteractive/gamemode

> [!tip]
> GameMode is enabled by default if it's installed.  
> You can disable it by adding `ENABLE_GAMEMODE=false` to your overrides.

### MangoHud

https://github.com/flightlessmango/MangoHud

> [!tip]
> MangoHud is disabled by default.  
> You can enable it by adding `ENABLE_MANGOHUD=true` to your overrides.

## Display Detection Support

In order to determine the settings to pass to gamescope, gamedownsights reads them
from your desktop environment configuration. The following desktop environments
are currently supported:

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

While `gamedownsights` is meant to work out-of-the-box, you might want to
tweak or override some of the settings.

This can be done by creating `~/.config/gamedownsights/override.sh`.
When `gamedownsights` is invoked, it will source that script to replace
or update any settings variables.

### Per-Game Configuration

If you know the AppID of the Steam game, you can override settings on a per-game basis.

```bash
# ... the rest of your override.sh config

# Per-Game Settings:
case "${SteamAppId:-}" in
1086940) # Baldur's Gate 3
	ENABLE_GAMESCOPE=false
	;;
esac
```

### Settings List


```bash
# The connector of the primary display. (e.g. DP-1)
# Applies to: gamescope
DISPLAY_PORT=''
```

```bash
# The width and height of the primary display.
# Applies to: gamescope
DISPLAY_WIDTH=1920
DISPLAY_HEIGHT=1080
```

```bash
# The configured refresh rate of the primary display.
# Applies to: gamescope
DISPLAY_REFRESH_RATE=60
```

```bash
# Enable variable refresh rate.
# Applies to: gamescope
DISPLAY_USE_VRR=false
```

```bash
# Enable HDR.
# Applies to: gamescope (or with gamescope disabled)
DISPLAY_USE_HDR=false
```

```bash
# Enable HDR inverse tone mapping.
# Applies to: gamescope
DISPLAY_ITM_NITS=300          # set to 0 to disable
```

```bash
# Gamescope-specific settings.
# Applies to: gamescope
DISPLAYSERVER_PROTOCOL=x11    # currently does not have any effect
GAMESCOPE_EXTRA_ARGS=()
```

```bash
# Enable gamemode. (default is true)
ENABLE_GAMEMODE=true

# Enable gamescope. (default is true)
ENABLE_GAMESCOPE=true

# Enable mangohud. (default is false)
ENABLE_MANGOHUD=false
```
