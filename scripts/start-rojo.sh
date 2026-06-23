#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

PORT="${ROJO_PORT:-34873}"
PID_FILE=".rojo-server.pid"
LOG_FILE="rojo-serve.log"
PROJECT_DIR="$(pwd)"
TMUX_SESSION="fortress-tictactoe-game-rojo"
ROJO_BIN="$(command -v rojo)"

write_pid_file() {
	if command -v lsof >/dev/null 2>&1; then
		PID="$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null | head -n 1 || true)"
		if [ -n "$PID" ]; then
			echo "$PID" >"$PID_FILE"
			return
		fi
	fi

	if command -v pgrep >/dev/null 2>&1; then
		PID="$(pgrep -f "$ROJO_BIN serve --port $PORT" | head -n 1 || true)"
		if [ -n "$PID" ]; then
			echo "$PID" >"$PID_FILE"
		fi
	fi
}

if [ -f "$PID_FILE" ]; then
	PID="$(cat "$PID_FILE")"
	if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
		echo "Rojo is already running on port $PORT with pid $PID."
		exit 0
	fi
fi

if command -v lsof >/dev/null 2>&1; then
	EXISTING="$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)"
	if [ -n "$EXISTING" ]; then
		echo "Port $PORT is already in use by pid(s): $EXISTING"
		exit 1
	fi
fi

if command -v tmux >/dev/null 2>&1; then
	if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
		echo "Rojo tmux session '$TMUX_SESSION' is already running."
		exit 0
	fi

	tmux new-session -d -s "$TMUX_SESSION" "cd \"$PROJECT_DIR\" && exec \"$ROJO_BIN\" serve --port \"$PORT\" >>\"$PROJECT_DIR/$LOG_FILE\" 2>&1"
	sleep 1
	write_pid_file
else
	nohup sh -c 'exec "$1" serve --port "$2" </dev/null' sh "$ROJO_BIN" "$PORT" >>"$LOG_FILE" 2>&1 &
	echo "$!" >"$PID_FILE"
fi

if [ -f "$PID_FILE" ]; then
	echo "Rojo started in the background on port $PORT with pid $(cat "$PID_FILE")."
else
	echo "Rojo start requested on port $PORT."
fi

echo "Log: $LOG_FILE"
