local Ludwig = _G['Ludwig']
local Search = Ludwig:NewModule('Search')
local ItemDB = Ludwig('ItemDB')

local needsUpdate = true

local filter = {
	name = nil,
	quality = nil,
	class = nil,
	subClass = nil,
	slot = nil,
	minLevel = nil,
	maxLevel = nil,
}

function Search:GetItems()
	return ItemDB:GetItems(
		filter.name,
		filter.quality,
		filter.class,
		filter.subClass,
		filter.slot,
		filter.minLevel,
		filter.maxLevel
	)
end

function Search:SetFilter(index, value)
	if filter[index] ~= value then
		filter[index] = value
		return true
	end
	return false
end

function Search:GetFilter(index)
	return filter[index]
end

function Search:Reset()
	filter.name = ''
	filter.quality = nil
	filter.class = nil
	filter.subClass = nil
	filter.slot = nil
	filter.minLevel = nil
	filter.maxLevel = nil
end