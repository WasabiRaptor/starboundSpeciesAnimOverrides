
function addDirectives()
	local directives = self.directives:lower()
	local found1, found2 = directives:find("00ffa1=")
	if found1 then
		local colorStartIndex = found2+1
		local colorEndIndex = #directives
		local found4 = directives:find(";", colorStartIndex)
		if found4 then
			local found5 = directives:find("?", colorStartIndex)
			if found5 and found4 > found5 then
				colorEndIndex = found5 -1
			else
				colorEndIndex = found4 -1
			end
		end

		local multiplyAmount = 0.75
		local color = directives:sub(colorStartIndex, colorEndIndex)
		local R = tonumber(color:sub(1,2),16)
		local G = tonumber(color:sub(3,4),16)
		local B = tonumber(color:sub(5,6),16)
		local A = ""
		if #color == 8 then
			A = color:sub(7,8)
		end
		local newReplaceColors = "?replace;00c77d="..string.format("%02x", math.floor(R * multiplyAmount))..string.format("%02x", math.floor(G * multiplyAmount))..string.format("%02x", math.floor(B * multiplyAmount))..A
		self.directives = self.directives..newReplaceColors
		self.hairDirectives = self.hairDirectives..newReplaceColors
	end
end
