local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Palette = require(ReplicatedStorage.Shared.Palette)
local TicTacToeLogic = require(ReplicatedStorage.Shared.TicTacToeLogic)

print(("[Fortress TicTacToe] Server running for %s"):format(GameConfig.gameName))

for _, oldName in ipairs({ GameConfig.arenaName, "TicTacToeArena", "CoinDashMap", "DeskTicTacToeMap" }) do
	local oldMap = workspace:FindFirstChild(oldName)

	if oldMap then
		oldMap:Destroy()
	end
end

local gameFunction = ReplicatedStorage:FindFirstChild(GameConfig.remoteName)

if not gameFunction then
	gameFunction = Instance.new("RemoteFunction")
	gameFunction.Name = GameConfig.remoteName
	gameFunction.Parent = ReplicatedStorage
end

local arena = Instance.new("Folder")
arena.Name = GameConfig.arenaName
arena.Parent = workspace

local sessions = {}
local boardCells = {}
local boardLabels = {}

Lighting.Ambient = Color3.fromRGB(76, 24, 22)
Lighting.Brightness = 1.8
Lighting.ColorShift_Top = Palette.ember
Lighting.ColorShift_Bottom = Palette.bloodstone
Lighting.EnvironmentDiffuseScale = 0.35
Lighting.EnvironmentSpecularScale = 0.6
Lighting.GlobalShadows = true
Lighting.OutdoorAmbient = Palette.obsidian

local function makePart(name, size, cframe, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Size = size
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Parent = arena

	return part
end

local function addLight(parent, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Brightness = brightness
	light.Color = color
	light.Range = range
	light.Shadows = true
	light.Parent = parent

	return light
end

local function addSurfaceText(part, face, text, color, font)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = face
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 42
	surfaceGui.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.GothamBlack
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Parent = surfaceGui

	return label
end

local function addPromptToPart(part)
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("ProximityPrompt") and child.Name == GameConfig.promptName then
			child:Destroy()
		end
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = GameConfig.promptName
	prompt.ActionText = "Challenge"
	prompt.ObjectText = "Fortress War Table"
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = GameConfig.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
end

local function buildFortressShell()
	local halfSize = GameConfig.arenaHalfSize
	makePart("ObsidianStoneFloor", Vector3.new(halfSize * 2, 2, halfSize * 2), CFrame.new(0, -1, 0), Palette.obsidian)

	for _, data in ipairs({
		{ "NorthWall", Vector3.new(halfSize * 2, 28, 5), CFrame.new(0, 13, -halfSize), 0 },
		{ "SouthWall", Vector3.new(halfSize * 2, 24, 5), CFrame.new(0, 11, halfSize), 0 },
		{ "EastWall", Vector3.new(5, 26, halfSize * 2), CFrame.new(halfSize, 12, 0), 0 },
		{ "WestWall", Vector3.new(5, 26, halfSize * 2), CFrame.new(-halfSize, 12, 0), 0 },
	}) do
		makePart(data[1], data[2], data[3], Palette.bloodstone, Enum.Material.Slate)
	end

	for _, x in ipairs({ -66, -22, 22, 66 }) do
		makePart(
			("NorthBattlement%d"):format(x),
			Vector3.new(12, 7, 6),
			CFrame.new(x, 29, -82),
			Palette.deepCrimson,
			Enum.Material.Slate
		)
		makePart(
			("SouthBattlement%d"):format(x),
			Vector3.new(12, 7, 6),
			CFrame.new(x, 25, 82),
			Palette.deepCrimson,
			Enum.Material.Slate
		)
	end

	for _, point in ipairs({
		Vector3.new(-72, 11, -72),
		Vector3.new(72, 11, -72),
		Vector3.new(-72, 11, 72),
		Vector3.new(72, 11, 72),
	}) do
		makePart(
			("FortressTower%d%d"):format(point.X, point.Z),
			Vector3.new(15, 24, 15),
			CFrame.new(point),
			Palette.deepCrimson,
			Enum.Material.Brick
		)
		local crown = makePart(
			("FortressTowerCrown%d%d"):format(point.X, point.Z),
			Vector3.new(18, 5, 18),
			CFrame.new(point + Vector3.new(0, 14.5, 0)),
			Palette.crimson,
			Enum.Material.Slate
		)
		addLight(crown, Palette.ember, 0.5, 22)
	end
end

local function buildDecor()
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = GameConfig.spawnName
	spawn.Anchored = true
	spawn.Size = Vector3.new(13, 1, 13)
	spawn.Position = GameConfig.spawnPosition
	spawn.Color = Palette.crimson
	spawn.Material = Enum.Material.Neon
	spawn.Parent = arena
	addLight(spawn, Palette.ember, 1.6, 26)

	for index = 1, 8 do
		local z = 14 - index * 7
		local runner = makePart(
			("CrimsonRunway%d"):format(index),
			Vector3.new(10, 0.22, 4.4),
			CFrame.new(0, 0.25, z),
			index % 2 == 0 and Palette.bloodstone or Palette.charcoal,
			Enum.Material.SmoothPlastic
		)
		local trim = makePart(
			("GoldRunwayTrim%d"):format(index),
			Vector3.new(0.5, 0.28, 4.6),
			CFrame.new(0, 0.5, z),
			Palette.gold,
			Enum.Material.Neon
		)
		addLight(trim, Palette.gold, 0.25, 9)
		runner.Transparency = 0.02
	end

	local titlePanel =
		makePart("FortressTitlePanel", Vector3.new(44, 9, 1), CFrame.new(0, 12, -78), Palette.deepCrimson)
	addSurfaceText(titlePanel, Enum.NormalId.Front, "FORTRESS TIC TAC TOE", Palette.bone, Enum.Font.GothamBlack)

	local promptPanel = makePart("PromptPanel", Vector3.new(36, 6, 1), CFrame.new(0, 7, -8), Palette.bloodstone)
	addSurfaceText(
		promptPanel,
		Enum.NormalId.Front,
		"WALK TO THE WAR TABLE  |  PRESS E",
		Palette.gold,
		Enum.Font.GothamBold
	)

	for index, x in ipairs({ -48, -32, 32, 48 }) do
		local brazier = makePart(
			("BrazierBase%d"):format(index),
			Vector3.new(4.5, 2.8, 4.5),
			CFrame.new(x, 1.4, -22),
			Palette.iron,
			Enum.Material.Metal
		)
		local flame = makePart(
			("EmberFlame%d"):format(index),
			Vector3.new(3.2, 4.2, 3.2),
			CFrame.new(x, 5, -22),
			index % 2 == 0 and Palette.ember or Palette.gold,
			Enum.Material.Neon
		)
		flame.Shape = Enum.PartType.Ball
		addLight(flame, Palette.ember, 1.8, 32)
		brazier.Transparency = 0
	end

	for _, x in ipairs({ -24, -12, 12, 24 }) do
		local banner = makePart("HangingBanner", Vector3.new(7, 13, 0.5), CFrame.new(x, 15, -80), Palette.crimson)
		addSurfaceText(banner, Enum.NormalId.Front, "X  O", Palette.gold, Enum.Font.GothamBlack)
	end
end

local function createSeat(name, position, rotationY, color)
	local seat = Instance.new("Seat")
	seat.Name = name
	seat.Anchored = true
	seat.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotationY), 0)
	seat.Color = color
	seat.Material = Enum.Material.SmoothPlastic
	seat.Size = Vector3.new(5, 1, 5)
	seat.Parent = arena

	local backOffset = rotationY == 180 and Vector3.new(0, 3.1, 3.1) or Vector3.new(0, 3.1, -3.1)
	local back = makePart(
		("%sBack"):format(name),
		Vector3.new(5.4, 6, 0.75),
		CFrame.new(position + backOffset) * CFrame.Angles(0, math.rad(rotationY), 0),
		color:Lerp(Palette.obsidian, 0.22)
	)

	return seat, back
end

local function createAICommander(position)
	local model = Instance.new("Model")
	model.Name = "SeatedAICommander"
	model.Parent = arena

	local function figurePart(name, size, offset, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.Color = color
		part.Material = material or Enum.Material.SmoothPlastic
		part.Position = position + offset
		part.Size = size
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = model

		return part
	end

	figurePart("TorsoArmor", Vector3.new(3.2, 4, 1.5), Vector3.new(0, 3.8, 0), Palette.iron, Enum.Material.Metal)
	figurePart("Helmet", Vector3.new(2.4, 2.1, 2.4), Vector3.new(0, 6.9, 0), Palette.darkGold, Enum.Material.Metal)
	figurePart("LeftArm", Vector3.new(0.9, 3.2, 0.9), Vector3.new(-2.2, 4, -0.2), Palette.crimson)
	figurePart("RightArm", Vector3.new(0.9, 3.2, 0.9), Vector3.new(2.2, 4, -0.2), Palette.crimson)
	figurePart("LeftLeg", Vector3.new(1, 2.7, 1), Vector3.new(-0.8, 1.5, -1), Palette.iron, Enum.Material.Metal)
	figurePart("RightLeg", Vector3.new(1, 2.7, 1), Vector3.new(0.8, 1.5, -1), Palette.iron, Enum.Material.Metal)

	local crownGlow = figurePart(
		"CommanderCrownGlow",
		Vector3.new(2.8, 0.35, 2.8),
		Vector3.new(0, 8.2, 0),
		Palette.gold,
		Enum.Material.Neon
	)
	addLight(crownGlow, Palette.gold, 0.8, 14)

	return model
end

local function buildWarTable()
	local center = GameConfig.tablePosition
	local platform = makePart(
		"WarTablePlatform",
		Vector3.new(34, 0.6, 25),
		CFrame.new(center + Vector3.new(0, -3.3, 0)),
		Palette.charcoal
	)
	local tableTop = makePart("FortressWarTable", Vector3.new(28, 1.4, 19), CFrame.new(center), Palette.bloodstone)
	tableTop.Material = Enum.Material.WoodPlanks
	addSurfaceText(tableTop, Enum.NormalId.Top, "COMMAND TABLE", Palette.gold, Enum.Font.GothamBlack)
	addPromptToPart(tableTop)
	addLight(tableTop, Palette.ember, 1.2, 22)

	for _, offset in ipairs({
		Vector3.new(-12, -2.8, -8),
		Vector3.new(12, -2.8, -8),
		Vector3.new(-12, -2.8, 8),
		Vector3.new(12, -2.8, 8),
	}) do
		makePart(
			"IronTableLeg",
			Vector3.new(2.4, 5.5, 2.4),
			CFrame.new(center + offset),
			Palette.iron,
			Enum.Material.Metal
		)
	end

	local boardBase = makePart(
		"PhysicalBoardBase",
		Vector3.new(13.5, 0.55, 13.5),
		CFrame.new(center + Vector3.new(0, 1, 0)),
		Palette.obsidian
	)
	boardBase.Material = Enum.Material.SmoothPlastic

	local startX = -3.8
	local startZ = -3.8
	local spacing = 3.8

	for row = 1, 3 do
		for column = 1, 3 do
			local index = (row - 1) * 3 + column
			local cell = makePart(
				("BoardCell%d"):format(index),
				Vector3.new(3.35, 0.25, 3.35),
				CFrame.new(center + Vector3.new(startX + (column - 1) * spacing, 1.42, startZ + (row - 1) * spacing)),
				Palette.deepCrimson,
				Enum.Material.Neon
			)
			boardCells[index] = cell
			boardLabels[index] = addSurfaceText(cell, Enum.NormalId.Top, "", Palette.bone, Enum.Font.GothamBlack)
		end
	end

	createSeat("PlayerCommanderSeat", center + Vector3.new(0, -3, 13), 180, Palette.crimson)
	local aiSeat = createSeat("AICommanderSeat", center + Vector3.new(0, -3, -13), 0, Palette.iron)
	aiSeat.Disabled = true
	createAICommander(aiSeat.Position + Vector3.new(0, 0.2, 1.2))

	for _, x in ipairs({ -18, 18 }) do
		local sideTable = makePart(
			"SideStrategyTable",
			Vector3.new(9, 0.8, 7),
			CFrame.new(center + Vector3.new(x, -1.4, 4)),
			Palette.deepCrimson
		)
		addSurfaceText(sideTable, Enum.NormalId.Top, "RANKED\nSOON", Palette.bone, Enum.Font.GothamBold)
	end

	platform.Transparency = 0.02
	return tableTop
end

local function updatePhysicalBoard(board, line, winner)
	local winningSquares = {}

	if line then
		for _, index in ipairs(line) do
			winningSquares[index] = true
		end
	end

	for index, label in ipairs(boardLabels) do
		local mark = board[index]
		local cell = boardCells[index]
		label.Text = mark

		if mark == TicTacToeLogic.playerMark then
			label.TextColor3 = Palette.gold
		elseif mark == TicTacToeLogic.computerMark then
			label.TextColor3 = Palette.ember
		else
			label.TextColor3 = Palette.bone
		end

		if winningSquares[index] then
			cell.Color = winner == TicTacToeLogic.playerMark and Palette.winGreen or Palette.ember
		else
			cell.Color = Palette.deepCrimson
		end
	end
end

buildFortressShell()
buildDecor()
buildWarTable()

local function getOrCreateStat(parent, name)
	local stat = parent:FindFirstChild(name)

	if not stat then
		stat = Instance.new("IntValue")
		stat.Name = name
		stat.Value = 0
		stat.Parent = parent
	end

	return stat
end

local function ensureLeaderboard(player)
	local leaderstats = player:FindFirstChild("leaderstats")

	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	getOrCreateStat(leaderstats, "Wins")
	getOrCreateStat(leaderstats, "Streak")
	getOrCreateStat(leaderstats, "BestStreak")
	getOrCreateStat(leaderstats, "Losses")
	getOrCreateStat(leaderstats, "Ties")

	return leaderstats
end

local function resetSession(session)
	session.board = TicTacToeLogic.createBoard()
	session.gameOver = false
	session.scored = false
end

local function ensureSession(player)
	local session = sessions[player]

	if not session then
		session = {
			board = TicTacToeLogic.createBoard(),
			difficulty = "Strategist",
			gameOver = false,
			randomGenerator = Random.new(),
			scored = false,
		}

		sessions[player] = session
	end

	return session
end

local function buildState(session, status, winner, line)
	updatePhysicalBoard(session.board, line, winner)

	return {
		board = TicTacToeLogic.cloneBoard(session.board),
		difficulty = session.difficulty,
		gameOver = session.gameOver,
		line = line,
		status = status,
		winner = winner,
	}
end

local function recordResult(player, session, winner)
	if session.scored or not winner then
		return
	end

	local leaderstats = ensureLeaderboard(player)
	local wins = leaderstats:FindFirstChild("Wins")
	local streak = leaderstats:FindFirstChild("Streak")
	local bestStreak = leaderstats:FindFirstChild("BestStreak")
	local losses = leaderstats:FindFirstChild("Losses")
	local ties = leaderstats:FindFirstChild("Ties")

	session.scored = true

	if winner == TicTacToeLogic.playerMark then
		wins.Value += 1
		streak.Value += 1

		if streak.Value > bestStreak.Value then
			bestStreak.Value = streak.Value
		end
	elseif winner == TicTacToeLogic.computerMark then
		losses.Value += 1
		streak.Value = 0
	elseif winner == "Tie" then
		ties.Value += 1
	end
end

local function finishIfNeeded(player, session)
	local winner, line = TicTacToeLogic.checkWinner(session.board)

	if not winner then
		return nil, nil, nil
	end

	session.gameOver = true
	recordResult(player, session, winner)

	if winner == TicTacToeLogic.playerMark then
		return winner, line, "Victory. The fortress salutes you."
	elseif winner == TicTacToeLogic.computerMark then
		return winner, line, "The commander wins. Demand a rematch."
	end

	return winner, line, "Stalemate. Reset the board."
end

Players.PlayerAdded:Connect(function(player)
	ensureLeaderboard(player)
	ensureSession(player)
end)

Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
end)

for _, player in Players:GetPlayers() do
	ensureLeaderboard(player)
	ensureSession(player)
end

gameFunction.OnServerInvoke = function(player, action, payload)
	ensureLeaderboard(player)
	local session = ensureSession(player)

	if action == "NewRound" then
		resetSession(session)
		return buildState(session, ("Your move. Mode: %s."):format(session.difficulty))
	end

	if action == "SetDifficulty" then
		session.difficulty = payload == "Reckless" and "Reckless" or "Strategist"
		resetSession(session)
		return buildState(session, ("Your move. Mode: %s."):format(session.difficulty))
	end

	if action ~= "Move" then
		return buildState(session, "Unknown command.")
	end

	local move = tonumber(payload)

	if session.gameOver then
		return buildState(session, "Round over. Start a new match.")
	end

	if not TicTacToeLogic.applyMove(session.board, move, TicTacToeLogic.playerMark) then
		return buildState(session, "Choose an empty square.")
	end

	local winner, line, status = finishIfNeeded(player, session)

	if winner then
		return buildState(session, status, winner, line)
	end

	local computerMove = TicTacToeLogic.chooseComputerMove(session.board, session.difficulty, session.randomGenerator)

	if computerMove then
		TicTacToeLogic.applyMove(session.board, computerMove, TicTacToeLogic.computerMark)
	end

	winner, line, status = finishIfNeeded(player, session)

	if winner then
		return buildState(session, status, winner, line)
	end

	return buildState(session, "Your move. You command X.")
end
