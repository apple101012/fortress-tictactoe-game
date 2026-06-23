#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

PID_FILE=".rojo-server.pid"
TMUX_SESSION="fortress-tictactoe-game-rojo"

if command -v tmux >/dev/null 2>&1 && tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
	tmux kill-session -t "$TMUX_SESSION"
	echo "Stopped Rojo tmux session '$TMUX_SESSION'."
fi

if [ ! -f "$PID_FILE" ]; then
	echo "No Rojo pid file found."
	exit 0
fi

PID="$(cat "$PID_FILE")"

if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
	kill "$PID"
	echo "Stopped Rojo pid $PID."
else
	echo "Rojo pid $PID is not running."
fi

rm -f "$PID_FILE"
