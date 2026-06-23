local GameConfig = require("../src/shared/GameConfig")
local CommunityAssets = require("../src/shared/CommunityAssets")
local Palette = require("../src/shared/Palette")

local tests = {}

local function test(name, callback)
	table.insert(tests, {
		name = name,
		callback = callback,
	})
end

local function assertTruthy(value, message)
	if not value then
		error(message or "expected value to be truthy", 2)
	end
end

local function distance(a, b)
	if a.Magnitude then
		return (a - b).Magnitude
	end

	local dx = a.x - b.x
	local dy = a.y - b.y
	local dz = a.z - b.z

	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

test("places spawn within prompt range of fortress table approach", function()
	local spawnToTable = distance(GameConfig.spawnPosition, GameConfig.tablePosition)

	assertTruthy(spawnToTable < 70, ("spawn should face the table approach, got %.2f studs"):format(spawnToTable))
	assertTruthy(GameConfig.promptDistance >= 16, "prompt distance should be forgiving")
end)

test("uses unique runtime names", function()
	assertTruthy(GameConfig.arenaName ~= "", "arena name")
	assertTruthy(GameConfig.gameplayFolderName ~= "", "gameplay folder name")
	assertTruthy(GameConfig.promptName ~= "", "prompt name")
	assertTruthy(GameConfig.remoteName ~= "", "remote name")
	assertTruthy(GameConfig.spawnName ~= "", "spawn name")
	assertTruthy(GameConfig.arenaName ~= GameConfig.remoteName, "runtime names should not collide")
	assertTruthy(GameConfig.arenaName ~= GameConfig.gameplayFolderName, "visual and gameplay folders should differ")
end)

test("positions gameplay board above the community table", function()
	assertTruthy(GameConfig.boardSize >= 12, "board should be large enough to read")
	assertTruthy(GameConfig.boardCenterOffset.y > 0, "board should sit above the table center")
	assertTruthy(GameConfig.boardCellOffsetY > GameConfig.boardCenterOffset.y, "cells should sit above board base")
end)

test("declares a broad dark red palette", function()
	local required = {
		"obsidian",
		"bloodstone",
		"crimson",
		"ember",
		"gold",
		"bone",
		"smoke",
	}

	for _, key in ipairs(required) do
		assertTruthy(Palette[key] ~= nil, ("missing palette color %s"):format(key))
	end
end)

test("declares curated creator store community models", function()
	assertTruthy(#CommunityAssets >= 10, "should include a full community model set")

	local roles = {}

	for _, asset in ipairs(CommunityAssets) do
		assertTruthy(type(asset.assetId) == "number", "asset id should be numeric")
		assertTruthy(asset.assetId > 0, "asset id should be positive")
		assertTruthy(asset.name and asset.name ~= "", "asset needs display name")
		assertTruthy(asset.role and asset.role ~= "", "asset needs role")
		roles[asset.role] = true
	end

	assertTruthy(roles.gate, "community set should include a gate")
	assertTruthy(roles.village_buildings, "community set should include large buildings")
	assertTruthy(roles.fortress_building, "community set should include fortress buildings")
	assertTruthy(roles.castle_interior_pack, "community set should include interior/castle pack dressing")
	assertTruthy(roles.furniture_pack, "community set should include furniture pack dressing")
	assertTruthy(roles.banquet_furniture, "community set should include banquet furniture")
	assertTruthy(roles.creator_store_table, "community set should include a Creator Store table")
	assertTruthy(roles.creator_store_chair, "community set should include a Creator Store chair")
	assertTruthy(roles.ai_commander, "community set should include an AI commander model")
	assertTruthy(roles.table, "community set should include a table")
	assertTruthy(roles.throne, "community set should include throne/chair dressing")
	assertTruthy(roles.throne_room, "community set should include a throne room prop")
	assertTruthy(roles.torch or roles.brazier, "community set should include lighting props")
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
	error(("%d game config tests failed."):format(failed))
end

print(("All %d game config tests passed."):format(passed))
