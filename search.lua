local Ludwig = _G['Ludwig']
local Search = Ludwig:NewModule('Search')
local ItemDB = Ludwig('ItemDB')

local currentSearch = nil
local needsUpdate = true
local filter = {
	name = '',
	quality = nil,
	type = nil,
	subType = nil,
	equipLoc = nil,
	minLevel = nil,
	maxLevel = nil,
}

function Search:GetItems()
	if needsUpdate then
		currentSearch = itemDB:GetItems(
			filter.name,
			filter.quality,
			filter.type,
			filter.subType,
			filter.equipLoc,
			filter.minLevel,
			filter.maxLevel
		)
		needsUpdate = false
	end
	return currentSearch
end

function Search:SetFilter(index, value)
	if filter[index] ~= value then
		filter[index] = value
		needsUpdate = true
	end
	return needsUpdate
end

function Search:GetFilter(index)
	return filter[index]
end

function Search:Reset()
	filter.name = ''
	filter.quality = nil
	filter.type = nil
	filter.subType = nil
	filter.equipLoc = nil
	filter.minLevel = nil
	filter.maxLevel = nil
	needsUpdate = true
end