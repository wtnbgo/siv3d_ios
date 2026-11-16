#!/bin/bash
# iOS シミュレータの補助スクリプト (siv3d_ios)
#   sim.sh list | boot <name|udid> | log <bundle-id> | shot <file> | reset
set -euo pipefail

booted_udid() {
	xcrun simctl list devices booted | grep -oE '[0-9A-F]{8}-[0-9A-F-]{27}' | head -1
}

case "${1:-}" in
	list)
		xcrun simctl list devices available | grep -E -- '^--|iPhone|iPad'
		;;
	boot)
		target="${2:?usage: sim.sh boot <name|udid>}"
		xcrun simctl boot "$target" 2>/dev/null || true
		xcrun simctl bootstatus "$target" -b >/dev/null
		open -a Simulator
		;;
	log)
		bundle="${2:?usage: sim.sh log <bundle-id>}"
		udid="$(booted_udid)"
		[ -n "$udid" ] || { echo "no booted simulator" >&2; exit 1; }
		exec xcrun simctl launch --console-pty --terminate-running-process "$udid" "$bundle"
		;;
	shot)
		file="${2:?usage: sim.sh shot <file>}"
		xcrun simctl io booted screenshot "$file"
		;;
	reset)
		killall -9 com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true
		echo "CoreSimulatorService restarted (it starts again on the next simctl command)"
		;;
	*)
		echo "usage: sim.sh list | boot <name|udid> | log <bundle-id> | shot <file> | reset" >&2
		exit 1
		;;
esac
