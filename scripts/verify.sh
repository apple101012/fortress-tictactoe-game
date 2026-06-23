#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

stylua --check src tests
selene src tests
lune run tests/TicTacToeLogic.test.luau
lune run tests/GameConfig.test.luau
rojo build -o /tmp/fortress-tictactoe-game-verify.rbxlx
