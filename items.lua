--[[
	API for searching in the item database

	Usage:
		:GetItems(name, quality, class, subClass, slot, minLevel, maxLevel)
			returns an ordered list of the item IDs that match the provided terms
	
		:GetItemNamedLike(name)
			returns the id and name of the closest match (for linkerator support)
	
		:IterateItems(string)
			iterates all items in the database or the given string, returning id and name
	
		:IterateClasses()
			iterates all classes and the strings containing their subclasses
	
		:IterateSubclasses(subclasses)
			iterates all subclasses and the strings containing their slots in the given "subclasses string" (from :IterateClasses)
	
		:IterateSlots(slots)
			iterates all slots in the given "slots string" (from :IterateSubclasses)
	
		:GetItemName(id)
			returns name, colorHex
	
		:GetItemLink(id)
--]]

local Ludwig = _G['Ludwig']
local ItemDB = Ludwig:NewModule('ItemDB')
local Ludwig_Data = Ludwig_Data

local Markers, Matchers, Iterators = {'{', '}', '$', '€', '£'}, {}, {}
local ItemMatch = '(%d+);([^;]+)'
local Caches, Values = {}, {}

for i, marker in ipairs(Markers) do
	Matchers[i] = marker..'[^'..marker..']+'
end

for i = 1, 3 do
	Iterators[i] = '([%-%a%s]+)' .. '(' .. Matchers[i] .. ';)'
end

local GetItemInfo, tinsert, tonumber = GetItemInfo, tinsert, tonumber
local adaptString(string)
	if string then
		return #string == 2 and string or ('0' .. string)
	end
end


--[[ Search API ]]--

function ItemDB:GetItems(search, quality, class, subClass, slot, minLevel, maxLevel)
	local search = search and {strsplit(' ', search:lower())}
	local filters = {class, subClass, slot, quality}
	local prevMin, prevMax = Values[5], Values[6]

	local results = Ludwig_Data
	local list, match = {}
	local level = 5


	-- Check Caches
	for i = 1, 4 do
		if filters[i] == Values[i] then
			results = Caches[i] or Ludwig_Data
		else
			level = i
			break
		end
	end
	Values = filters


	-- Apply Filters
	for i = level, 4 do
		local term = filters[i]
		if term then
			local match = term .. Matchers[i]

			-- Categories
			if i < 4 then
				results = results:match(match)

			-- Quality
			elseif i == 4 then
				local items = ''
				for section in results:gmatch(match) do
					items = items .. section
				end
				results = items
			end

--			Caches[i] = results
		end
	end


	-- Search Level
	if level == 5 and prevMin == minLevel and prevMax == maxLevel then
		results = Caches[5] or Ludwig_Data

	elseif minLevel or maxLevel then
		local items = ''
		local min = adaptString(minLevel) or '00'
		local max = adaptString(maxLevel) or '99'

		for section in (results or Ludwig_Data):gmatch('%d+' .. Matchers[5]) do
			local level = section:match('^(%d+)')
			if level > min and level < max then
				items = items .. section
			end
		end

		Values[5] = minLevel
		Values[6] = maxLevel
--		Caches[5] = items

		results = items
	end


	-- Search Name
	for id, name in self:IterateItems(results) do
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
			tinsert(list, id)
		end
	end

	return list
end

function ItemDB:GetItemNamedLike(search)
	local search = '^' .. search:lower()
	for id, name in self:IterateItems() do
		if name:lower():match(search) then
			return id, name
		end
	end
end

function ItemDB:IterateItems(section)
	return (section or Ludwig_Data):gmatch(ItemMatch)
end


--[[ Categories API ]]--

function ItemDB:IterateClasses()
	return Ludwig_Data:gmatch(Iterators[1])
end

function ItemDB:IterateSubClasses(subs)
	return subs:gmatch(Iterators[2])
end

function ItemDB:IterateSlots(slots)
	return slots:gmatch(Iterators[3])
end


--[[ Item API ]]--

function ItemDB:GetItemName(id)
	if id then
		local name, link, quality = GetItemInfo(id)
		if not (name and quality) then
			quality, name = Ludwig_Data:match(('(%%d+)€%s;([^;]+)'):format(id))
			if not name then
				quality, name = Ludwig_Data:match(('(%%d+)€[^€]*[^%%d]%s;([^;]+)'):format(id))
			end
		end

		if name then
			return name, select(4, GetItemQualityColor(tonumber(quality)))
		else
			return ('Error: Item %s Not Found'):format(id), ''
		end
	end
end

function ItemDB:GetItemLink(id)
	local name, hex = self:GetItemName(id)
	return ('%s\124Hitem:%s:0:0:0:0:0:0:0:%d:0\124h[%s]\124h\124r'):format(hex, id, UnitLevel('player'), name)
end