local Lighting = game:GetService("Lighting")
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CommunityAssets = require(ReplicatedStorage.Shared.CommunityAssets)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Palette = require(ReplicatedStorage.Shared.Palette)
local TicTacToeLogic = require(ReplicatedStorage.Shared.TicTacToeLogic)

print(("[Fortress TicTacToe] Server running for %s"):format(GameConfig.gameName))

for _, oldName in ipairs({
	GameConfig.arenaName,
	GameConfig.gameplayFolderName,
	"TicTacToeArena",
	"CoinDashMap",
	"DeskTicTacToeMap",
	"FortressTitlePanel",
	"PromptPanel",
	"FortressWarTable",
	"PlayerCommanderSeat",
	"AICommanderSeat",
	"SeatedAICommander",
	"SideStrategyTable",
}) do
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
arena.Name = GameConfig.gameplayFolderName
arena.Parent = workspace

local sessions = {}
local boardCells = {}
local boardLabels = {}

Lighting.Ambient = Color3.fromRGB(178, 210, 255)
Lighting.Brightness = 3.45
Lighting.ClockTime = 13.5
Lighting.ColorShift_Top = Color3.fromRGB(205, 228, 255)
Lighting.ColorShift_Bottom = Color3.fromRGB(124, 171, 224)
Lighting.EnvironmentDiffuseScale = 0.82
Lighting.EnvironmentSpecularScale = 0.85
Lighting.GlobalShadows = true
Lighting.OutdoorAmbient = Color3.fromRGB(142, 185, 235)

local existingSky = Lighting:FindFirstChild("BrightBlueGameSky")
if not existingSky then
	existingSky = Instance.new("Sky")
	existingSky.Name = "BrightBlueGameSky"
	existingSky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"
	existingSky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
	existingSky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"
	existingSky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
	existingSky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"
	existingSky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
	existingSky.Parent = Lighting
end

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

local function removeOldGeneratedParts()
	local oldPrefixes = {
		"BrazierBase",
		"Castle Wall Medieval Fortress Defense Tower Left",
		"Castle Wall Medieval Fortress Defense Tower Right",
		"CrimsonRunway",
		"EmberFlame",
		"FortressTower",
		"GoldRunwayTrim",
		"HangingBanner",
		"IronTableLeg",
		"NorthBattlement",
		"NorthWall",
		"SouthBattlement",
		"SouthWall",
	}

	local oldNames = {
		BackWallTitlePanel = true,
		BlueArenaFloor = true,
		EastWall = true,
		FortressTitlePanel = true,
		FortressWarTable = true,
		ObsidianStoneFloor = true,
		PhysicalBoardBase = true,
		PlayerCommanderSeat = true,
		PromptPanel = true,
		SeatedAICommander = true,
		SideStrategyTable = true,
		TablePresentationPlatform = true,
		WarTablePlatform = true,
		WestWall = true,
	}

	for _, child in ipairs(workspace:GetChildren()) do
		if oldNames[child.Name] then
			child:Destroy()
		else
			for _, prefix in ipairs(oldPrefixes) do
				if string.sub(child.Name, 1, #prefix) == prefix then
					child:Destroy()
					break
				end
			end
		end
	end
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

local function getCommunityGroup()
	local group = workspace:FindFirstChild("CommunityFortressModels")

	if not group then
		group = Instance.new("Folder")
		group.Name = "CommunityFortressModels"
		group.Parent = workspace
	end

	return group
end

local function sanitizeCommunityModel(model)
	local removedScripts = 0

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BaseScript") then
			descendant:Destroy()
			removedScripts += 1
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end

	model:SetAttribute("CommunityScriptsRemoved", removedScripts)
	model:SetAttribute("CommunityAssetSanitized", true)
end

local function normalizeCommunityContainer(container, desiredName, group)
	if not container then
		return nil
	end

	if container:IsA("Model") then
		container.Name = desiredName
		container.Parent = group
		return container
	end

	local wrapper = Instance.new("Model")
	wrapper.Name = desiredName
	wrapper.Parent = group

	for _, child in ipairs(container:GetChildren()) do
		child.Parent = wrapper
	end

	container:Destroy()
	return wrapper
end

local function loadCommunityAssets()
	local group = getCommunityGroup()

	for _, asset in ipairs(CommunityAssets) do
		if not group:FindFirstChild(asset.name) then
			local ok, inserted = pcall(function()
				return InsertService:LoadAsset(asset.assetId)
			end)

			if ok and inserted then
				local model = normalizeCommunityContainer(inserted, asset.name, group)

				if model then
					model:SetAttribute("CreatorStoreAssetId", asset.assetId)
					model:SetAttribute("CreatorStoreRole", asset.role)
					sanitizeCommunityModel(model)
				end
			else
				warn(("[Fortress TicTacToe] Could not load community asset %s (%s)"):format(asset.name, asset.assetId))
			end
		end
	end

	return group
end

local function getCommunityModel(group, name)
	local existing = group:FindFirstChild(name)

	if not existing then
		return nil
	end

	return normalizeCommunityContainer(existing, name, group)
end

local function placeModel(model, pivot, scale)
	if not model or not model:IsA("Model") then
		return nil
	end

	sanitizeCommunityModel(model)

	if scale and model.ScaleTo then
		model:ScaleTo(scale)
	end

	model:PivotTo(pivot)

	return model
end

local function placeModelTopAt(model, pivot, scale, topY)
	if not placeModel(model, pivot, scale) then
		return nil
	end

	local boundsCFrame, boundsSize = model:GetBoundingBox()
	local currentTopY = boundsCFrame.Position.Y + boundsSize.Y / 2
	model:PivotTo(model:GetPivot() + Vector3.new(0, topY - currentTopY, 0))

	return model
end

local function cloneCommunityModel(group, sourceName, cloneName, pivot, scale)
	local existing = group:FindFirstChild(cloneName)

	if existing and existing:IsA("Model") then
		return placeModel(existing, pivot, scale)
	end

	local source = getCommunityModel(group, sourceName)

	if not source or not source:IsA("Model") then
		return nil
	end

	local clone = source:Clone()
	clone.Name = cloneName
	clone.Parent = group

	return placeModel(clone, pivot, scale)
end

local function buildFortressShell()
	local halfSize = GameConfig.arenaHalfSize
	local floor = makePart(
		"ObsidianCourtyardFloor",
		Vector3.new(halfSize * 2.35, 2, halfSize * 2.35),
		CFrame.new(0, -1, -22),
		Color3.fromRGB(64, 54, 53)
	)
	floor.Material = Enum.Material.Cobblestone

	local runway = makePart(
		"CrimsonRunway",
		Vector3.new(18, 0.16, 66),
		CFrame.new(0, 0.08, -5),
		Palette.deepCrimson,
		Enum.Material.Fabric
	)
	runway.CanCollide = false

	for _, x in ipairs({ -9.6, 9.6 }) do
		local trim = makePart(
			"GoldRunwayTrim",
			Vector3.new(0.55, 0.2, 66),
			CFrame.new(x, 0.15, -5),
			Palette.gold,
			Enum.Material.Metal
		)
		trim.CanCollide = false
	end

	for index, z in ipairs({ 18, 6, -6, -18, -30 }) do
		for _, x in ipairs({ -12.5, 12.5 }) do
			local marker = makePart(
				("RunwayEmberLight%d"):format(index),
				Vector3.new(1.8, 0.25, 1.8),
				CFrame.new(x, 0.3, z),
				Palette.ember,
				Enum.Material.Neon
			)
			marker.CanCollide = false
			addLight(marker, Palette.ember, 1.25, 18)
		end
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
end

local function arrangeCommunityModels()
	local group = loadCommunityAssets()

	placeModel(
		getCommunityModel(group, "Medieval Village Set - Castle Town Buildings"),
		CFrame.new(0, 13, -72) * CFrame.Angles(0, math.rad(180), 0),
		0.36
	)
	placeModel(
		getCommunityModel(group, "Medieval Castle Village Fortress Fantasy Building"),
		CFrame.new(-48, 5, -26) * CFrame.Angles(0, math.rad(28), 0),
		0.92
	)
	placeModel(
		getCommunityModel(group, "Synty Dungeon Pack Cave Castle Medieval Interior"),
		CFrame.new(76, 9, -6) * CFrame.Angles(0, math.rad(-90), 0),
		0.17
	)
	placeModel(getCommunityModel(group, "Castle Wall Medieval Fortress Defense Tower"), CFrame.new(0, 14, -42), 1.25)
	placeModel(
		getCommunityModel(group, "Portcullis Castle Gate Door Medieval Fortress"),
		CFrame.new(0, 11.5, -32) * CFrame.Angles(0, math.rad(180), 0),
		1.25
	)
	cloneCommunityModel(
		group,
		"Castle Wall Medieval Fortress Defense Tower",
		"Castle Wall Medieval Fortress Defense Tower Left",
		CFrame.new(-42, 14, 0) * CFrame.Angles(0, math.rad(90), 0),
		0.95
	)
	cloneCommunityModel(
		group,
		"Castle Wall Medieval Fortress Defense Tower",
		"Castle Wall Medieval Fortress Defense Tower Right",
		CFrame.new(42, 14, 0) * CFrame.Angles(0, math.rad(-90), 0),
		0.95
	)
	local ornateTable = getCommunityModel(group, "Ornate War Council Table")
	if ornateTable then
		placeModelTopAt(ornateTable, CFrame.new(GameConfig.tablePosition), 1.25, GameConfig.tablePosition.Y + 0.35)
		placeModel(getCommunityModel(group, "WAR MAP TABLE"), CFrame.new(0, -80, 0), 1)
	else
		placeModelTopAt(
			getCommunityModel(group, "WAR MAP TABLE"),
			CFrame.new(GameConfig.tablePosition),
			2.05,
			GameConfig.tablePosition.Y + 0.15
		)
	end
	placeModelTopAt(
		getCommunityModel(group, "Dungeon Table Medieval Castle Fantasy Decor"),
		CFrame.new(-20, GameConfig.tablePosition.Y, 5) * CFrame.Angles(0, math.rad(22), 0),
		1.45,
		GameConfig.tablePosition.Y - 0.2
	)
	placeModel(
		getCommunityModel(group, "Medieval Chair Throne Castle Roleplay RP"),
		CFrame.new(0, 2.4, -17) * CFrame.Angles(0, math.rad(180), 0),
		1.4
	)
	placeModel(
		getCommunityModel(group, "Medieval Furniture Pack Castle Kingdom Vibe RP"),
		CFrame.new(-23, 2.4, -1) * CFrame.Angles(0, math.rad(35), 0),
		1.7
	)
	placeModelTopAt(
		getCommunityModel(group, "Medieval Furniture Set Table Chair Decor"),
		CFrame.new(22, GameConfig.tablePosition.Y, 4) * CFrame.Angles(0, math.rad(-28), 0),
		0.55,
		GameConfig.tablePosition.Y + 0.15
	)
	placeModelTopAt(
		getCommunityModel(group, "Wooden Table Medieval Furniture Dining Feast"),
		CFrame.new(GameConfig.tablePosition) * CFrame.Angles(0, math.rad(180), 0),
		1.35,
		GameConfig.tablePosition.Y + 0.1
	)
	placeModelTopAt(
		getCommunityModel(group, "Large Dinning Set"),
		CFrame.new(25, GameConfig.tablePosition.Y, 1) * CFrame.Angles(0, math.rad(-28), 0),
		0.82,
		GameConfig.tablePosition.Y
	)
	placeModel(
		getCommunityModel(group, "King's Throne Royal Regal Castle Throne Room"),
		CFrame.new(0, 2.8, -21) * CFrame.Angles(0, math.rad(180), 0),
		1.25
	)
	placeModel(
		getCommunityModel(group, "Statue Sword Knight Armor Medieval Guard"),
		CFrame.new(-19, 14.5, -16) * CFrame.Angles(0, math.rad(22), 0),
		0.82
	)
	placeModel(
		getCommunityModel(group, "Knight NPC Armor Swords Shield Medieval RPG"),
		CFrame.new(11, 3.1, -13) * CFrame.Angles(0, math.rad(-18), 0),
		1.35
	)
	placeModel(
		getCommunityModel(group, "Wall Torch Flame Light Medieval Castle Prop"),
		CFrame.new(-18, 7.5, -27) * CFrame.Angles(0, math.rad(180), 0),
		1.4
	)
	placeModel(getCommunityModel(group, "Brazier"), CFrame.new(-13, 2.2, 12), 1.35)

	cloneCommunityModel(
		group,
		"Statue Sword Knight Armor Medieval Guard",
		"Statue Sword Knight Armor Medieval Guard Right",
		CFrame.new(19, 14.5, -16) * CFrame.Angles(0, math.rad(-22), 0),
		0.82
	)
	cloneCommunityModel(
		group,
		"Wall Torch Flame Light Medieval Castle Prop",
		"Wall Torch Flame Light Medieval Castle Prop Right",
		CFrame.new(18, 7.5, -27) * CFrame.Angles(0, math.rad(180), 0),
		1.4
	)
	cloneCommunityModel(
		group,
		"Wall Torch Flame Light Medieval Castle Prop",
		"Wall Torch Flame Light Medieval Castle Prop Left Mid",
		CFrame.new(-34, 7.5, 12) * CFrame.Angles(0, math.rad(90), 0),
		1.2
	)
	cloneCommunityModel(
		group,
		"Wall Torch Flame Light Medieval Castle Prop",
		"Wall Torch Flame Light Medieval Castle Prop Right Mid",
		CFrame.new(34, 7.5, 12) * CFrame.Angles(0, math.rad(-90), 0),
		1.2
	)
	cloneCommunityModel(group, "Brazier", "Brazier Right", CFrame.new(13, 2.2, 12), 1.35)
	cloneCommunityModel(group, "Brazier", "Brazier Left Rear", CFrame.new(-28, 2.2, -16), 1.2)
	cloneCommunityModel(group, "Brazier", "Brazier Right Rear", CFrame.new(28, 2.2, -16), 1.2)
	cloneCommunityModel(
		group,
		"Medieval Chair Throne Castle Roleplay RP",
		"Player Throne Chair",
		CFrame.new(0, 2.4, 13),
		1.15
	)
	placeModelTopAt(
		getCommunityModel(group, "Old Wooden Chair Classic Rustic Furniture Farmhou"),
		CFrame.new(0, GameConfig.tablePosition.Y, 12.8),
		1.55,
		GameConfig.tablePosition.Y - 0.35
	)
	cloneCommunityModel(
		group,
		"Old Wooden Chair Classic Rustic Furniture Farmhou",
		"Creator Store AI Chair",
		CFrame.new(0, GameConfig.tablePosition.Y, -12.8) * CFrame.Angles(0, math.rad(180), 0),
		1.55
	)
	cloneCommunityModel(
		group,
		"Medieval Furniture Pack Castle Kingdom Vibe RP",
		"Medieval Furniture Pack Right Decor",
		CFrame.new(23, 2.4, -1) * CFrame.Angles(0, math.rad(-35), 0),
		1.7
	)
	cloneCommunityModel(
		group,
		"Medieval Castle Village Fortress Fantasy Building",
		"Medieval Castle Village Fortress Fantasy Building Right",
		CFrame.new(48, 5, -26) * CFrame.Angles(0, math.rad(-28), 0),
		0.92
	)

	group:SetAttribute("Source", "Creator Store free community models")
	group:SetAttribute("Safety", "Embedded scripts removed at runtime")

	return group
end

local function buildWarTable()
	local center = GameConfig.tablePosition
	local communityModels = workspace:FindFirstChild("CommunityFortressModels")
	local communityTable = communityModels
		and (
			communityModels:FindFirstChild("Ornate War Council Table")
			or communityModels:FindFirstChild("WAR MAP TABLE")
			or communityModels:FindFirstChild("Dungeon Table Medieval Castle Fantasy Decor")
		)
	local promptPart

	if communityTable and communityTable:IsA("Model") then
		for _, descendant in ipairs(communityTable:GetDescendants()) do
			if descendant:IsA("BaseScript") then
				descendant:Destroy()
			elseif descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end

		if communityTable.ScaleTo then
			local tableScale = if communityTable.Name == "Ornate War Council Table"
				then 1.25
				elseif communityTable.Name == "WAR MAP TABLE" then 2.05
				else 2.5
			communityTable:ScaleTo(tableScale)
		end

		communityTable:PivotTo(CFrame.new(center.X, center.Y, center.Z))

		local boundsCFrame, boundsSize = communityTable:GetBoundingBox()
		local tableTopOffset = if communityTable.Name == "Ornate War Council Table" then 0.35 else 0.15
		local desiredTopY = center.Y + tableTopOffset
		local currentTopY = boundsCFrame.Position.Y + boundsSize.Y / 2
		communityTable:PivotTo(communityTable:GetPivot() + Vector3.new(0, desiredTopY - currentTopY, 0))

		promptPart = makePart(
			"WarTablePromptHitbox",
			Vector3.new(18, 5, 15),
			CFrame.new(center + Vector3.new(0, 1.2, 0)),
			Palette.ember,
			Enum.Material.Neon
		)
		promptPart.CanCollide = false
		promptPart.Transparency = 1
		addLight(promptPart, Palette.ember, 1.2, 22)
	else
		local tableTop = makePart("FortressWarTable", Vector3.new(28, 1.4, 19), CFrame.new(center), Palette.bloodstone)
		tableTop.Material = Enum.Material.WoodPlanks
		addSurfaceText(tableTop, Enum.NormalId.Top, "COMMAND TABLE", Palette.gold, Enum.Font.GothamBlack)
		addLight(tableTop, Palette.ember, 1.2, 22)
		promptPart = tableTop

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
	end

	addPromptToPart(promptPart)

	local tableTop = makePart(
		"PlayableWarTableTop",
		Vector3.new(21, 0.7, 15),
		CFrame.new(center + Vector3.new(0, 0, 0)),
		Color3.fromRGB(138, 76, 42),
		Enum.Material.WoodPlanks
	)
	addLight(tableTop, Palette.ember, 1.35, 24)

	local tableCloth = makePart(
		"CrimsonTableCloth",
		Vector3.new(19, 0.18, 13),
		CFrame.new(center + Vector3.new(0, 0.45, 0)),
		Color3.fromRGB(156, 24, 31),
		Enum.Material.Fabric
	)
	tableCloth.CanCollide = false

	for _, offset in ipairs({
		Vector3.new(-8.5, -1.9, -5.8),
		Vector3.new(8.5, -1.9, -5.8),
		Vector3.new(-8.5, -1.9, 5.8),
		Vector3.new(8.5, -1.9, 5.8),
	}) do
		makePart(
			"PlayableWarTableLeg",
			Vector3.new(1.4, 3.6, 1.4),
			CFrame.new(center + offset),
			Palette.iron,
			Enum.Material.Metal
		)
	end

	local frontApron = makePart(
		"PlayableWarTableFrontApron",
		Vector3.new(21, 2.2, 0.65),
		CFrame.new(center + Vector3.new(0, -1.15, 7.85)),
		Color3.fromRGB(118, 35, 29),
		Enum.Material.WoodPlanks
	)
	addSurfaceText(frontApron, Enum.NormalId.Front, "TIC TAC TOE", Palette.gold, Enum.Font.GothamBlack)

	for _, offset in ipairs({
		Vector3.new(0, 0.78, 7.75),
		Vector3.new(0, 0.78, -7.75),
		Vector3.new(-10.7, 0.78, 0),
		Vector3.new(10.7, 0.78, 0),
	}) do
		local trimSize = if math.abs(offset.X) > 0 then Vector3.new(0.55, 0.28, 15.5) else Vector3.new(21.5, 0.28, 0.55)
		local trim = makePart(
			"PlayableWarTableGoldTrim",
			trimSize,
			CFrame.new(center + offset),
			Palette.gold,
			Enum.Material.Metal
		)
		trim.CanCollide = false
	end

	local playerSeat = makePart(
		"PlayerTableChair",
		Vector3.new(5, 0.7, 4.2),
		CFrame.new(center + Vector3.new(0, -0.85, 12.5)),
		Color3.fromRGB(80, 35, 29),
		Enum.Material.WoodPlanks
	)
	local playerBack = makePart(
		"PlayerTableChairBack",
		Vector3.new(5, 4.2, 0.65),
		CFrame.new(center + Vector3.new(0, 1.0, 14.35)),
		Palette.bloodstone,
		Enum.Material.WoodPlanks
	)
	addLight(playerSeat, Palette.ember, 0.45, 12)
	addLight(playerBack, Palette.ember, 0.35, 10)

	local aiSeat = makePart(
		"AITableChair",
		Vector3.new(5, 0.7, 4.2),
		CFrame.new(center + Vector3.new(0, -0.85, -12.5)),
		Color3.fromRGB(80, 35, 29),
		Enum.Material.WoodPlanks
	)
	local aiBack = makePart(
		"AITableChairBack",
		Vector3.new(5, 4.2, 0.65),
		CFrame.new(center + Vector3.new(0, 1.0, -14.35)),
		Palette.bloodstone,
		Enum.Material.WoodPlanks
	)
	addLight(aiSeat, Palette.ember, 0.45, 12)
	addLight(aiBack, Palette.ember, 0.35, 10)

	local tableSpotlight = makePart(
		"WarTableSpotlight",
		Vector3.new(1, 1, 1),
		CFrame.new(center + Vector3.new(0, 7.5, 0)),
		Palette.gold,
		Enum.Material.Neon
	)
	tableSpotlight.Transparency = 1
	tableSpotlight.CanCollide = false
	addLight(tableSpotlight, Palette.gold, 2.1, 34)

	local boardBase = makePart(
		"PhysicalBoardBase",
		Vector3.new(GameConfig.boardSize, 0.55, GameConfig.boardSize),
		CFrame.new(center + GameConfig.boardCenterOffset),
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
				CFrame.new(
					center
						+ Vector3.new(
							startX + (column - 1) * spacing,
							GameConfig.boardCellOffsetY,
							startZ + (row - 1) * spacing
						)
				),
				Palette.deepCrimson,
				Enum.Material.Neon
			)
			boardCells[index] = cell
			boardLabels[index] = addSurfaceText(cell, Enum.NormalId.Top, "", Palette.bone, Enum.Font.GothamBlack)
		end
	end

	local beacon = makePart(
		"WarTableBeacon",
		Vector3.new(0.75, 5.5, 0.75),
		CFrame.new(center + Vector3.new(0, 5.5, 0)),
		Palette.ember,
		Enum.Material.Neon
	)
	beacon.Shape = Enum.PartType.Cylinder
	beacon.Transparency = 0.42
	beacon.CanCollide = false
	addLight(beacon, Palette.ember, 1.4, 20)

	return promptPart
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

removeOldGeneratedParts()
buildFortressShell()
buildDecor()
arrangeCommunityModels()
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
