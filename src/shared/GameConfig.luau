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
	gameplayFolderName = "FortressGameplayRuntime",
	promptName = "OpenFortressTicTacToePrompt",
	remoteName = "FortressTicTacToeFunction",
	spawnName = "FortressSpawn",
	arenaHalfSize = 82,
	boardCenterOffset = vector3(0, 0.75, 0),
	boardCellOffsetY = 1.05,
	boardSize = 13.5,
	tablePosition = vector3(0, 2.55, 14),
	spawnPosition = vector3(0, 1.2, 28),
	promptDistance = 18,
}
