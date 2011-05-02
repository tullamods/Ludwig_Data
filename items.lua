--[[
	API for searching in the item database

	Usage:
		:GetItems(name, category, quality, minLevel, maxLevel)
		:GetItemLink(id, name, color)
		:GetQualityColor(quality)
			
		:IterateClasses()
		:IterateSubclasses(subclasses)
		:IterateSlots(slots)
--]]

local Markers, Matchers, Iterators = {'{', '}', '$', '€', '£'}, {}, {}
local ItemDB = Ludwig:NewModule('ItemDB')

for i, marker in ipairs(Markers) do
	Matchers[i] = '([^'..marker..']+)'
end

for i = 1, 3 do
	Iterators[i] = '([%-%a%s]+)' .. Markers[i] .. Matchers[i] .. ';'
end

local GetItemInfo, tinsert, tonumber = GetItemInfo, tinsert, tonumber
local LEVEL_MATCH = '(%d+)' .. Markers[4] .. Matchers[4]
local QUALITY_MATCH = '(%d)' .. Markers[5] .. '$'
local ITEM_MATCH = '(.-)(%d+);([^;]+)'

local function buildNumber(string)
	if string then
		return #string == 2 and string or ('0' .. string)
	end
end

local function buildTable()
	local t = {}
	for i = 0, Ludwig.MaxQualities do
		t[tostring(i)] = {}
	end
	return t
end

local function improveTable(table)
	for i, v in pairs(table) do
		table[tonumber(i)] = v
	end
	return table
end


--[[ Search API ]]--

function ItemDB:GetItems(name, category, minLevel, maxLevel, quality)
	local search = name and {strsplit(' ', name:lower())}
	local ids, names = buildTable(), buildTable()
	local data = Ludwig_Items
	
	if category then
		local match = ''
		for i, value in ipairs(category) do
			match = match .. '.*' .. value .. Marker[1]
		end
		
		data = data:match(match .. Matchers[#category])
	end

	if minLevel or maxLevel then
		local min = buildNumber(minLevel) or '00'
		local max = buildNumber(maxLevel) or '99'
		local results = ''
		
		for level, items in data:gmatch(LEVEL_MATCH) do
			if #level == 1 then
				level = '0' .. level
			end
		
			if level > min and level < max then
				results = results .. ';' .. items
			end
		end
		
		data = results
	end
	
	for extra, id, name in data:gmatch(ITEM_MATCH) do
		local qual = extra:match(QUALITY_MATCH)
		if qual then
			if not quality or qual == quality then
				qualityNames = names[qual]
				qualityIDs = ids[qual]
			else
				qualityIDs = nil
			end
		end
		
		if qualityIDs then
			tinsert(qualityIDs, id)
			tinsert(qualityNames, name)
		end
	end

	return improveTable(ids), improveTable(names)
end


--[[ Categories API ]]--

function ItemDB:IterateClasses()
	return Ludwig_Classes:gmatch(Iterators[1])
end

function ItemDB:IterateSubClasses(subs)
	return subs:gmatch(Iterators[2])
end

function ItemDB:IterateSlots(slots)
	return slots:gmatch(Iterators[3])
end


--[[ Item API ]]--

function ItemDB:GetItemLink(id, name, hex)
	return ('%s\124Hitem:%s:0:0:0:0:0:0:0:%d:0\124h[%s]\124h\124r'):format(hex, id, UnitLevel('player'), name)
end

function ItemDB:GetQualityColor(quality)
	return select(4, GetItemQualityColor(tonumber(quality)))
end