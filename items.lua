--[[
	API for searching in the item database

	Usage:
		:GetItems(name, category, quality, minLevel, maxLevel)
		
		:GetItem(data, index)
		:GetItemLink(id, name, quality)
			
		:IterateCategories(subs, level)
		:HasSubCategories(subs, level)
--]]

local Markers, Matchers, Iterators, Cache = {'¤', '¢', '€', '£', '฿'}, {}, {}, {}
local ItemDB = Ludwig:NewModule('ItemDB')

for i = 1, 4 do
	Matchers[i] = '([^'.. Markers[i] ..']*)'
end

for i = 1, 3 do
	Iterators[i] = Markers[i] .. '([%-%a%s&]+)' .. Matchers[i]
end

local GetItemInfo, tinsert, tonumber = GetItemInfo, tinsert, tonumber
local LEVEL_MATCH = '(.)' .. Markers[4] .. Matchers[4]
local QUALITY_MATCH = '(.)' .. Markers[5] .. '$'
local ITEM_MATCH = '(.-)_(...)([^_^]+)'

local function newCache()
	local t = {}
	for i = 0, #ITEM_QUALITY_COLORS do
		t[strchar(i)] = {}
	end
	return t
end

local function improveCache(table)
	for i, v in pairs(table) do
		table[strbyte(i)] = v
	end
	return table
end

local function strint(s)
	local v, d = 0
	for i = 1, #s do
		d = strbyte(s, i)
		if d > 90 then
			d = d - 5
		end

		v = v + d * 122 ^ (#s - i)
	end
	return v
end


--[[ Searches ]]--

function ItemDB:GetItems(name, category, minLevel, maxLevel, quality)
	local quality = quality and strchar(quality)
	local search = name and {strsplit(' ', name:lower())}
	local ids, names, limits = newCache(), newCache(), {}
	local data, list, numResults = Ludwig_Items, {}, 0
	
	-- Category
	if category then
		local match = ''
		for i, value in ipairs(category) do
			match = match .. '.-' .. strchar(value) .. Markers[i]
		end
		
		data = data:match(match .. Matchers[#category])
	end

	-- Level
	if minLevel or maxLevel then
		local minLevel = strchar(minLevel or 0)
		local maxLevel = strchar(maxLevel or 126)
		local results = ''
		
		for level, items in data:gmatch(LEVEL_MATCH) do
			if level >= min and level <= max then
				tinsert(list, items)
			end
		end
	else
		tinsert(list, data)
	end
	
	-- Name/Quality
	for _, items in ipairs(list) do
		for extra, id, name in items:gmatch(ITEM_MATCH) do
			local q = extra:match(QUALITY_MATCH)
			if q then
				if not quality or q == quality then
					qualityNames = names[q]
					qualityIDs = ids[q]
				else
					qualityIDs = nil
				end
			end
			
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

	return strint(bestID), bestName, strbyte(bestQuality)
end


--[[ Items ]]--

function ItemDB:GetItem(data, index)
	local ids, names, limits = unpack(data)
	for q = 0, #ITEM_QUALITY_COLORS do
		if limits[q] >= index then
			index = index - (limits[q - 1] or 0)
			return strint(ids[q][index]), names[q][index], q
		end
	end
end

function ItemDB:GetItemLink(id, name, quality)
	return ('%s|Hitem:%d:0:0:0:0:0:0:0:0:0:0|h[%s]|h|r'):format(ITEM_QUALITY_COLORS[quality].hex, id, name)
end


--[[ Categories ]]--

function ItemDB:IterateCategories(subs, level)
	return (subs or Ludwig_Classes):gmatch(Iterators[level])
end

function ItemDB:HasSubCategories(subs, level)
	return subs:sub(1, 1) == Markers[level + 1]
end