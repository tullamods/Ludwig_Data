--[[
	API for searching the item database

	Usage:
		:FindItems(search, class, subclass, quality, minLevel, maxLevel)
		:FindClosestItem(search)
		:ItemClassExists(class, subclass)
		:GetItemLink(id, name, quality)
--]]

local Database = Ludwig:NewModule('Database')
local ITEM_MATCH = '(%w%w%w%w)([^_]+)'


--[[ Searches ]]--

function Database:FindItems(search, class, subclass, quality, minLevel, maxLevel)
	local ids, names = {}, {}

	search = search and search:lower()
	maxLevel = maxLevel or math.huge
	minLevel = minLevel or 0

	for category, subclasses in pairs(Ludwig_Items) do
		if not class or class == category then
			for subcat, qualities in pairs(subclasses) do
				if not subclass or subclass == subcat then
					for rarity, levels in pairs(qualities) do
						if not quality or quality == rarity then
							ids[rarity] = ids[rarity] or {}
							names[rarity] = names[rarity] or {}

							for level, items in pairs(levels) do
								if level >= minLevel and level <= maxLevel then
									for id, name in items:gmatch(ITEM_MATCH) do
										if not search or name:lower():find(search) then
											tinsert(ids[rarity], id)
											tinsert(names[rarity], name)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return ids, names
end

function Database:FindClosestItem(search)
	local size = #search
	local search = '^' .. search:lower()
	local distance = math.huge
	local bestID, bestName, bestQuality

	for class, subclasses in pairs(Ludwig_Items) do
		for subclass, qualities in pairs(subclasses) do
			for quality, levels in pairs(qualities) do
				for level, items in pairs(levels) do
					for id, name in items:gmatch(ITEM_MATCH) do
						if name:lower():match(search) then
							local off = #name - size
							if off >= 0 and off < distance then
								bestID, bestName, bestQuality = id, name, quality
								distance = off
							end
						end
					end
				end
			end
		end
	end

	if bestID then
		return tonumber(bestID, 36), bestName, bestQuality
	end
end

function Database:ItemClassExists(class, subclass)
	if subclass then
		return Ludwig_Items[class] and Ludwig_Items[class][subclass]
	end
	return Ludwig_Items[class]
end


--[[ Utilities ]]--

function Database:GetItemLink(id, name, quality)
	return ('%s|Hitem:%d:::::::::::::::|h[%s]|h|r'):format(ITEM_QUALITY_COLORS[quality].hex, id, name)
end
