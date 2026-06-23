local TicTacToeLogic = require("../src/shared/TicTacToeLogic")

local tests = {}

local function test(name, callback)
	table.insert(tests, {
		name = name,
		callback = callback,
	})
end

local function assertEqual(actual, expected, message)
	if actual ~= expected then
		error(
			("%s: expected %s, got %s"):format(message or "assertEqual failed", tostring(expected), tostring(actual)),
			2
		)
	end
end

local function assertTruthy(value, message)
	if not value then
		error(message or "expected value to be truthy", 2)
	end
end

local function boardFromString(value)
	local board = TicTacToeLogic.createBoard()

	for index = 1, 9 do
		local mark = string.sub(value, index, index)

		if mark == "X" or mark == "O" then
			board[index] = mark
		end
	end

	return board
end

test("creates an empty board", function()
	local board = TicTacToeLogic.createBoard()

	assertEqual(#board, 9, "board length")

	for index = 1, 9 do
		assertEqual(board[index], TicTacToeLogic.empty, ("square %d"):format(index))
	end
end)

test("applies legal moves and rejects invalid moves", function()
	local board = TicTacToeLogic.createBoard()

	assertTruthy(TicTacToeLogic.applyMove(board, 5, "X"), "center should apply")
	assertEqual(board[5], "X", "center mark")
	assertEqual(TicTacToeLogic.applyMove(board, 5, "O"), false, "occupied square should reject")
	assertEqual(TicTacToeLogic.applyMove(board, 0, "O"), false, "low index should reject")
	assertEqual(TicTacToeLogic.applyMove(board, 10, "O"), false, "high index should reject")
end)

test("detects row column and diagonal wins", function()
	assertEqual(TicTacToeLogic.checkWinner(boardFromString("XXX......")), "X", "row winner")
	assertEqual(TicTacToeLogic.checkWinner(boardFromString("O..O..O..")), "O", "column winner")
	assertEqual(TicTacToeLogic.checkWinner(boardFromString("X...X...X")), "X", "diagonal winner")
end)

test("detects tie", function()
	assertEqual(TicTacToeLogic.checkWinner(boardFromString("XOXOXXOXO")), "Tie", "tie winner")
end)

test("strategist AI wins immediately", function()
	local board = boardFromString("OO.X.X...")

	assertEqual(TicTacToeLogic.chooseComputerMove(board, "Strategist"), 3, "winning move")
end)

test("strategist AI blocks immediately", function()
	local board = boardFromString("XX..O....")

	assertEqual(TicTacToeLogic.chooseComputerMove(board, "Strategist"), 3, "block move")
end)

test("strategist AI chooses center then corners", function()
	assertEqual(TicTacToeLogic.chooseComputerMove(TicTacToeLogic.createBoard(), "Strategist"), 5, "opening center")
	assertEqual(TicTacToeLogic.chooseComputerMove(boardFromString("....X...."), "Strategist"), 1, "corner fallback")
end)

test("does not choose a move on full board", function()
	assertEqual(TicTacToeLogic.chooseComputerMove(boardFromString("XOXOXXOXO"), "Strategist"), nil, "no move")
end)

local passed = 0
local failed = 0

for _, entry in ipairs(tests) do
	local ok, err = pcall(entry.callback)

	if ok then
		passed += 1
		print(("PASS %s"):format(entry.name))
	else
		failed += 1
		print(("FAIL %s\n%s"):format(entry.name, err))
	end
end

if failed > 0 then
	error(("%d TicTacToe logic tests failed."):format(failed))
end

print(("All %d TicTacToe logic tests passed."):format(passed))
