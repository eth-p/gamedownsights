#!/usr/bin/env false
# Homepage: https://github.com/eth-p/gamedownsights

#shellcheck shell=bash
#shellcheck disable=SC2034

case "${SteamAppId:-}" in

# Baldurs Gate 3
# Tested: 2025-07-29
1086940)
	ENABLE_GAMEMODE=false  # causes crash
	;;

# Ori and the Will of the Wisps
# Tested: 2025-07-30
1057090)
	ENABLE_GAMEMODE=false  # causes crash before Xbox Studios screen
	;;

esac
