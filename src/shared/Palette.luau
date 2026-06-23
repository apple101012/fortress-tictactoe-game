local function rgb(red, green, blue)
	if Color3 then
		return Color3.fromRGB(red, green, blue)
	end

	return {
		b = blue,
		g = green,
		r = red,
	}
end

local Palette = {
	obsidian = rgb(16, 9, 11),
	bloodstone = rgb(58, 13, 18),
	crimson = rgb(139, 30, 36),
	deepCrimson = rgb(92, 14, 22),
	ember = rgb(232, 80, 46),
	gold = rgb(214, 166, 79),
	darkGold = rgb(129, 89, 39),
	bone = rgb(242, 222, 189),
	smoke = rgb(107, 90, 88),
	iron = rgb(48, 43, 43),
	charcoal = rgb(28, 24, 25),
	winGreen = rgb(77, 209, 122),
}

return Palette
