local TicTacToeLogic = {}

TicTacToeLogic.empty = ""
TicTacToeLogic.playerMark = "X"
TicTacToeLogic.computerMark = "O"

local winningLines = {
	{ 1, 2, 3 },
	{ 4, 5, 6 },
	{ 7, 8, 9 },
	{ 1, 4, 7 },
	{ 2, 5, 8 },
	{ 3, 6, 9 },
	{ 1, 5, 9 },
	{ 3, 5, 7 },
}

function TicTacToeLogic.createBoard()
	local board = {}

	for index = 1, 9 do
		board[index] = TicTacToeLogic.empty
	end

	return board
end

function TicTacToeLogic.cloneBoard(board)
	local clone = {}

	for index = 1, 9 do
		clone[index] = board[index]
	end

	return clone
end

function TicTacToeLogic.applyMove(board, index, mark)
	if typeof(index) ~= "number" or index < 1 or index > 9 or index % 1 ~= 0 then
		return false
	end

	if board[index] ~= TicTacToeLogic.empty then
		return false
	end

	board[index] = mark
	return true
end

function TicTacToeLogic.checkWinner(board)
	for _, line in ipairs(winningLines) do
		local a, b, c = line[1], line[2], line[3]
		local mark = board[a]

		if mark ~= TicTacToeLogic.empty and mark == board[b] and mark == board[c] then
			return mark, line
		end
	end

	for index = 1, 9 do
		if board[index] == TicTacToeLogic.empty then
			return nil, nil
		end
	end

	return "Tie", nil
end

local function findWinningMove(board, mark)
	for index = 1, 9 do
		if board[index] == TicTacToeLogic.empty then
			local candidate = TicTacToeLogic.cloneBoard(board)
			candidate[index] = mark

			if TicTacToeLogic.checkWinner(candidate) == mark then
				return index
			end
		end
	end

	return nil
end

local function chooseRandomMove(board, randomGenerator)
	local openSquares = {}

	for index = 1, 9 do
		if board[index] == TicTacToeLogic.empty then
			table.insert(openSquares, index)
		end
	end

	if #openSquares == 0 then
		return nil
	end

	local generator = randomGenerator or Random.new()
	return openSquares[generator:NextInteger(1, #openSquares)]
end

function TicTacToeLogic.chooseComputerMove(board, difficulty, randomGenerator)
	if difficulty == "Reckless" then
		return chooseRandomMove(board, randomGenerator)
	end

	local winningMove = findWinningMove(board, TicTacToeLogic.computerMark)

	if winningMove then
		return winningMove
	end

	local blockMove = findWinningMove(board, TicTacToeLogic.playerMark)

	if blockMove then
		return blockMove
	end

	if board[5] == TicTacToeLogic.empty then
		return 5
	end

	for _, index in ipairs({ 1, 3, 7, 9 }) do
		if board[index] == TicTacToeLogic.empty then
			return index
		end
	end

	return chooseRandomMove(board, randomGenerator)
end

return TicTacToeLogic
