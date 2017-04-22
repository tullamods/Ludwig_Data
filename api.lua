--[[
	API for searching the item database

	Usage:
		:GetItems(name, category, quality, minLevel, maxLevel)
		:GetItem(data, index)
		:GetClosestItem(search)
		:GetItemLink(id, name, quality)
--]]

local ItemDB = Ludwig:NewModule('ItemDB')

local MARKERS = {'$', '^', '*', '<', '´'}
local LEVEL_MATCH = '(%d+)%' .. MARKERS[4] .. '([^%' .. MARKERS[4] .. ']+)'
local QUALITY_MATCH = '(%d+)%' .. MARKERS[5]
local ITEM_MATCH = '(.-)(%w%w%w%w)([^_]+)'

local function newCache()
	local t = {}
	for i = 0, #ITEM_QUALITY_COLORS do
		t[tostring(i)] = {}
	end
	return t
end

local function improveCache(table)
	for i, v in pairs(table) do
		table[tonumber(i)] = v
	end
	return table
end


--[[ Searches ]]--

function ItemDB:GetItems(name, class, minLevel, maxLevel, quality)
	local quality = quality and tostring(quality)
	local search = name and {strsplit(' ', name:lower())}
	local ids, names, limits = newCache(), newCache(), {}
	local data, list, numResults = Ludwig_Items, {}, 0

	-- Class
	if class then
		local match = ''
		for i, value in ipairs(class) do
			match = match .. tostring(value) .. '%' .. MARKERS[i] .. '.-'
		end

		match = match:sub(1, -3) .. '([^%' .. MARKERS[#class] .. ']+)'
		data = data:match(match)
	end

	-- Level
	if minLevel or maxLevel then
		minLevel = tonumber(minLevel or 0)
		maxLevel =  tonumber(maxLevel or 1000)
		local results = ''

		for level, items in data:gmatch(LEVEL_MATCH) do
			level = tonumber(level)
			if level >= minLevel and level <= maxLevel then
				tinsert(list, items)
			end
		end
	else
		tinsert(list, data)
	end

	for _, items in ipairs(list) do
		for extra, id, name in items:gmatch(ITEM_MATCH) do
			-- Quality
			local q = extra:match(QUALITY_MATCH)
			if q then
				if not quality or q == quality then
					qualityNames = names[q]
					qualityIDs = ids[q]
				else
					qualityIDs = nil
				end
			end

			-- Name
			if qualityIDs then
				local match = true

				if search then
					local name = name:lower()

					for i, word in ipairs(search) do
						if not name:match(word) then
							match = nil
							break
						end
					end
				end

				if match then
					tinsert(qualityIDs, id)
					tinsert(qualityNames, name)
				end
			end
		end
	end

	-- Calculations
	improveCache(ids)
	improveCache(names)

	for i = 0, #ITEM_QUALITY_COLORS do
		numResults = numResults + #ids[i]
		limits[i] = numResults
	end

	return {ids, names, limits}, numResults
end

function ItemDB:GetClosestItem(search)
	local size = #search
	local search = '^' .. search
	local distance = math.huge
	local bestID, bestName, bestQuality

	for extra, id, name in Ludwig_Items:gmatch(ITEM_MATCH) do
		quality = extra:match(QUALITY_MATCH) or quality

		if name:match(search) then
			local off = #name - size
			if off >= 0 and off < distance then
				bestID, bestName, bestQuality = id, name, quality
				distance = off
			end
		end
	end

	if bestID then
		return tonumber(bestID, 36), bestName, tonumber(bestQuality)
	end
end


--[[ Items ]]--

function ItemDB:GetItem(data, index)
	local ids, names, limits = unpack(data)
	for q = 0, #ITEM_QUALITY_COLORS do
		if limits[q] >= index then
			index = index - (limits[q - 1] or 0)
			return tonumber(ids[q][index], 36), names[q][index], q
		end
	end
end

function ItemDB:GetItemLink(id, name, quality)
	return ('%s|Hitem:%d:::::::::::::::|h[%s]|h|r'):format(ITEM_QUALITY_COLORS[quality].hex, id, name)
end
