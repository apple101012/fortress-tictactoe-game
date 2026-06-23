local function vector3(x, y, z)
	if Vector3 then
		return Vector3.new(x, y, z)
	end

	return {
		x = x,
		y = y,
		z = z,
	}
end

return {
	gameName = "Fortress TicTacToe",
	arenaName = "FortressTicTacToeArena",
	promptName = "OpenFortressTicTacToePrompt",
	remoteName = "FortressTicTacToeFunction",
	spawnName = "FortressSpawn",
	arenaHalfSize = 82,
	tablePosition = vector3(0, 4.2, -42),
	spawnPosition = vector3(0, 1.2, 18),
	promptDistance = 18,
}
