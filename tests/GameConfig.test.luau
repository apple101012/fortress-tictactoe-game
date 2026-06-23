local GameConfig = require("../src/shared/GameConfig")
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
	assertTruthy(GameConfig.promptName ~= "", "prompt name")
	assertTruthy(GameConfig.remoteName ~= "", "remote name")
	assertTruthy(GameConfig.spawnName ~= "", "spawn name")
	assertTruthy(GameConfig.arenaName ~= GameConfig.remoteName, "runtime names should not collide")
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
