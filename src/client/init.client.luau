local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Palette = require(ReplicatedStorage.Shared.Palette)
local TicTacToeLogic = require(ReplicatedStorage.Shared.TicTacToeLogic)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local leaderstats = player:WaitForChild("leaderstats")
local gameFunction = ReplicatedStorage:WaitForChild(GameConfig.remoteName)

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local wins = leaderstats:WaitForChild("Wins")
local streak = leaderstats:WaitForChild("Streak")
local bestStreak = leaderstats:WaitForChild("BestStreak")
local losses = leaderstats:WaitForChild("Losses")
local ties = leaderstats:WaitForChild("Ties")

local buttons = {}
local buttonStrokes = {}
local currentDifficulty = "Strategist"
local requestBusy = false
local celebrationToken = 0
local randomGenerator = Random.new()

local celebrationColors = {
	Palette.gold,
	Palette.ember,
	Palette.bone,
	Palette.winGreen,
	Color3.fromRGB(255, 210, 92),
	Color3.fromRGB(255, 99, 71),
}

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent

	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = parent

	return stroke
end

local function makeLabel(parent, text, position, size, font, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = font
	label.Position = position
	label.Size = size
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent

	return label
end

local function makeButton(parent, text, position, size, color)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Position = position
	button.Size = size
	button.Text = text
	button.TextColor3 = Palette.bone
	button.TextScaled = true
	button.Parent = parent
	addCorner(button, 7)

	return button
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FortressTicTacToeGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local hintBar = Instance.new("Frame")
hintBar.AnchorPoint = Vector2.new(0.5, 0)
hintBar.BackgroundColor3 = Palette.obsidian
hintBar.BackgroundTransparency = 0.06
hintBar.BorderSizePixel = 0
hintBar.Position = UDim2.fromScale(0.5, 0.03)
hintBar.Size = UDim2.fromOffset(500, 46)
hintBar.Parent = screenGui
addCorner(hintBar, 8)
addStroke(hintBar, Palette.gold, 1, 0.18)

local hintLabel = makeLabel(
	hintBar,
	"Walk to the fortress war table and press E.",
	UDim2.fromOffset(16, 6),
	UDim2.new(1, -32, 1, -12),
	Enum.Font.GothamBold,
	Palette.bone
)
hintLabel.TextXAlignment = Enum.TextXAlignment.Center

local background = Instance.new("Frame")
background.BackgroundColor3 = Palette.obsidian
background.BackgroundTransparency = 0.04
background.BorderSizePixel = 0
background.Size = UDim2.fromScale(1, 1)
background.Visible = false
background.Parent = screenGui

local backgroundGradient = Instance.new("UIGradient")
backgroundGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Palette.obsidian),
	ColorSequenceKeypoint.new(0.45, Palette.bloodstone),
	ColorSequenceKeypoint.new(1, Palette.charcoal),
})
backgroundGradient.Rotation = 25
backgroundGradient.Parent = background

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.BackgroundColor3 = Palette.bloodstone
panel.BorderSizePixel = 0
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(500, 570)
panel.Parent = background
addCorner(panel, 8)
addStroke(panel, Palette.gold, 2, 0.08)

local panelScale = Instance.new("UIScale")
panelScale.Parent = panel

local panelGradient = Instance.new("UIGradient")
panelGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Palette.deepCrimson),
	ColorSequenceKeypoint.new(1, Palette.obsidian),
})
panelGradient.Rotation = 90
panelGradient.Parent = panel

makeLabel(
	panel,
	GameConfig.gameName,
	UDim2.fromOffset(24, 16),
	UDim2.new(1, -92, 0, 40),
	Enum.Font.GothamBlack,
	Palette.bone
)

local closeButton = makeButton(panel, "X", UDim2.new(1, -58, 0, 20), UDim2.fromOffset(34, 34), Palette.crimson)

makeLabel(
	panel,
	"Defeat the seated commander.",
	UDim2.fromOffset(26, 58),
	UDim2.new(1, -52, 0, 24),
	Enum.Font.GothamMedium,
	Palette.gold
)

local statsLabel =
	makeLabel(panel, "", UDim2.fromOffset(26, 90), UDim2.new(1, -52, 0, 28), Enum.Font.GothamBold, Palette.bone)

local statusLabel = makeLabel(
	panel,
	"Press New Match to begin.",
	UDim2.fromOffset(26, 124),
	UDim2.new(1, -52, 0, 30),
	Enum.Font.GothamBold,
	Palette.bone
)

local recklessButton =
	makeButton(panel, "Reckless", UDim2.fromOffset(26, 164), UDim2.fromOffset(116, 36), Palette.crimson)
local strategistButton =
	makeButton(panel, "Strategist", UDim2.fromOffset(152, 164), UDim2.fromOffset(126, 36), Palette.deepCrimson)
local newRoundButton =
	makeButton(panel, "New Match", UDim2.new(1, -154, 0, 164), UDim2.fromOffset(128, 36), Palette.darkGold)

local boardFrame = Instance.new("Frame")
boardFrame.BackgroundColor3 = Palette.gold
boardFrame.BorderSizePixel = 0
boardFrame.Position = UDim2.fromOffset(82, 218)
boardFrame.Size = UDim2.fromOffset(336, 336)
boardFrame.Parent = panel
addCorner(boardFrame, 8)
addStroke(boardFrame, Palette.bone, 2, 0.1)

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellPadding = UDim2.fromOffset(6, 6)
gridLayout.CellSize = UDim2.fromOffset(108, 108)
gridLayout.FillDirectionMaxCells = 3
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = boardFrame

local celebrationLabel =
	makeLabel(background, "", UDim2.fromScale(0, 0.08), UDim2.fromScale(1, 0.1), Enum.Font.GothamBlack, Palette.gold)
celebrationLabel.TextXAlignment = Enum.TextXAlignment.Center
celebrationLabel.Visible = false

local function updateScale()
	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	local viewport = camera.ViewportSize
	local scale = math.min(viewport.X / 560, viewport.Y / 650, 1)
	panelScale.Scale = math.max(scale, 0.72)
end

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	updateScale()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateScale)

local function updateStats()
	statsLabel.Text = ("Wins %d  Losses %d  Ties %d  Streak %d  Best %d"):format(
		wins.Value,
		losses.Value,
		ties.Value,
		streak.Value,
		bestStreak.Value
	)
end

local function updateDifficultyButtons()
	if currentDifficulty == "Strategist" then
		strategistButton.BackgroundColor3 = Palette.ember
		recklessButton.BackgroundColor3 = Palette.crimson
	else
		recklessButton.BackgroundColor3 = Palette.ember
		strategistButton.BackgroundColor3 = Palette.deepCrimson
	end
end

local function clearGlow()
	celebrationToken += 1
	celebrationLabel.Visible = false

	for _, stroke in ipairs(buttonStrokes) do
		stroke.Transparency = 1
	end

	for _, button in ipairs(buttons) do
		button.BackgroundColor3 = Palette.bloodstone
	end
end

local function spawnConfetti()
	for index = 1, 36 do
		local piece = Instance.new("Frame")
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.BackgroundColor3 = celebrationColors[((index - 1) % #celebrationColors) + 1]
		piece.BorderSizePixel = 0
		piece.Position = UDim2.fromScale(randomGenerator:NextNumber(0.07, 0.93), -0.05)
		piece.Rotation = randomGenerator:NextInteger(0, 180)
		piece.Size = UDim2.fromOffset(randomGenerator:NextInteger(8, 18), randomGenerator:NextInteger(14, 26))
		piece.Parent = background
		addCorner(piece, 3)

		local tween = TweenService:Create(
			piece,
			TweenInfo.new(randomGenerator:NextNumber(1.1, 2), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(
					randomGenerator:NextNumber(0.04, 0.96),
					randomGenerator:NextNumber(0.78, 1.08)
				),
				Rotation = piece.Rotation + randomGenerator:NextInteger(150, 520),
			}
		)

		tween:Play()
		tween.Completed:Connect(function()
			piece:Destroy()
		end)
	end
end

local function startVictoryGlow(line)
	celebrationToken += 1
	local token = celebrationToken

	celebrationLabel.Text = "FORTRESS VICTORY"
	celebrationLabel.TextTransparency = 0
	celebrationLabel.Visible = true
	spawnConfetti()

	for _, stroke in ipairs(buttonStrokes) do
		stroke.Transparency = 0.04
		stroke.Thickness = 4
	end

	if line then
		for _, index in ipairs(line) do
			buttons[index].BackgroundColor3 = Palette.winGreen
		end
	end

	task.spawn(function()
		local colorIndex = 1

		while celebrationToken == token do
			local color = celebrationColors[colorIndex]

			for _, stroke in ipairs(buttonStrokes) do
				TweenService:Create(stroke, TweenInfo.new(0.18), { Color = color }):Play()
			end

			for _, button in ipairs(buttons) do
				TweenService
					:Create(button, TweenInfo.new(0.18), { BackgroundColor3 = color:Lerp(Palette.obsidian, 0.35) })
					:Play()
			end

			colorIndex = (colorIndex % #celebrationColors) + 1
			task.wait(0.2)
		end
	end)
end

local function showLossGlow(line)
	if line then
		for _, index in ipairs(line) do
			buttons[index].BackgroundColor3 = Palette.crimson
			buttonStrokes[index].Color = Palette.ember
			buttonStrokes[index].Transparency = 0.05
		end
	end
end

local function applyState(state)
	if not state then
		statusLabel.Text = "The fortress did not answer."
		return
	end

	clearGlow()
	currentDifficulty = state.difficulty or currentDifficulty
	statusLabel.Text = state.status or "Your move."
	updateDifficultyButtons()

	for index, button in ipairs(buttons) do
		local value = state.board and state.board[index] or TicTacToeLogic.empty
		button.Text = value

		if value == TicTacToeLogic.playerMark then
			button.TextColor3 = Palette.gold
		elseif value == TicTacToeLogic.computerMark then
			button.TextColor3 = Palette.ember
		else
			button.TextColor3 = Palette.bone
		end
	end

	if state.winner == TicTacToeLogic.playerMark then
		startVictoryGlow(state.line)
	elseif state.winner == TicTacToeLogic.computerMark then
		showLossGlow(state.line)
	elseif state.winner == "Tie" then
		for _, stroke in ipairs(buttonStrokes) do
			stroke.Color = Palette.gold
			stroke.Transparency = 0.12
		end
	end
end

local function requestState(action, payload)
	if requestBusy then
		return
	end

	requestBusy = true
	statusLabel.Text = action == "Move" and "The commander is thinking..." or "Preparing the board..."

	local ok, state = pcall(function()
		return gameFunction:InvokeServer(action, payload)
	end)

	requestBusy = false

	if ok then
		applyState(state)
	else
		statusLabel.Text = "Server request failed."
		warn(state)
	end
end

local function openGame()
	background.Visible = true
	hintBar.Visible = false
	requestState("NewRound")
end

for index = 1, 9 do
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = Palette.bloodstone
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.LayoutOrder = index
	button.Text = ""
	button.TextScaled = true
	button.Parent = boardFrame
	addCorner(button, 6)

	local stroke = addStroke(button, Palette.gold, 3, 1)

	button.MouseButton1Click:Connect(function()
		requestState("Move", index)
	end)

	buttons[index] = button
	buttonStrokes[index] = stroke
end

wins:GetPropertyChangedSignal("Value"):Connect(updateStats)
losses:GetPropertyChangedSignal("Value"):Connect(updateStats)
ties:GetPropertyChangedSignal("Value"):Connect(updateStats)
streak:GetPropertyChangedSignal("Value"):Connect(updateStats)
bestStreak:GetPropertyChangedSignal("Value"):Connect(updateStats)

recklessButton.MouseButton1Click:Connect(function()
	requestState("SetDifficulty", "Reckless")
end)

strategistButton.MouseButton1Click:Connect(function()
	requestState("SetDifficulty", "Strategist")
end)

newRoundButton.MouseButton1Click:Connect(function()
	requestState("NewRound")
end)

closeButton.MouseButton1Click:Connect(function()
	background.Visible = false
	hintBar.Visible = true
	clearGlow()
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == GameConfig.promptName then
		openGame()
	end
end)

updateStats()
updateDifficultyButtons()
applyState({
	board = TicTacToeLogic.createBoard(),
	difficulty = currentDifficulty,
	status = "Walk to the fortress war table and press E.",
})
