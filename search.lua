local Ludwig = _G['Ludwig']
local Search = Ludwig:NewModule('Search')

local ItemDB = Ludwig('ItemDB')

function Search:GetItems()
	return ItemDB:GetItems(
		self.name,
		self.quality,
		self.type,
		self.subType,
		self.equipLoc,
		self.minLevel,
		self.maxLevel
	)
end

function Search:Reset()
	self.name = ''
	self.quality = nil
	self.type = nil
	self.subType = nil
	self.equipLoc = nil
	self.minLevel = nil
	self.maxLevel = nil
end