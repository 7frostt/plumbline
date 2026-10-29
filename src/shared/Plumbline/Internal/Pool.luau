--!strict
local Types = require(script.Parent.Parent.Types)
local Config = require(script.Parent.Parent.Config)

local Pool = {}
Pool.__index = Pool

local container: Folder? = nil

local function getContainer(): Folder
	if not container or not container.Parent then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "Plumbline_Pool"

		local parentTarget: Instance = workspace.CurrentCamera or workspace
		newFolder.Parent = parentTarget

		container = newFolder
	end

	return container :: Folder
end

local pools: { [Types.AdornmentType]: { Types.VisualItem } } = {
	Box = {},
	Sphere = {},
	Cylinder = {},
	Line = {},
}

local function createAdornment(adornType: Types.AdornmentType): HandleAdornment
	local adorn: HandleAdornment
	if adornType == "Box" then
		adorn = Instance.new("BoxHandleAdornment")
	elseif adornType == "Sphere" then
		adorn = Instance.new("SphereHandleAdornment")
	elseif adornType == "Cylinder" then
		adorn = Instance.new("CylinderHandleAdornment")
	elseif adornType == "Line" then
		adorn = Instance.new("LineHandleAdornment")
	else
		error("[Plumbline] Unknown adornment type: " .. tostring(adornType))
	end

	adorn.Adornee = workspace.Terrain
	adorn.AlwaysOnTop = Config.AlwaysOnTop
	adorn.ZIndex = 1
	adorn.Visible = false
	adorn.Parent = getContainer()
	return adorn
end

function Pool.Acquire(adornType: Types.AdornmentType): Types.VisualItem
	local poolList = pools[adornType]

	for _, item in poolList do
		if not item.InUse then
			item.InUse = true
			item.Adornment.Visible = true
			return item
		end
	end

	local newAdorn = createAdornment(adornType)
	local newItem: Types.VisualItem = {
		Adornment = newAdorn,
		Type = adornType,
		ExpiresAt = 0,
		InUse = true,
	}
	table.insert(poolList, newItem)
	newAdorn.Visible = true
	return newItem
end

function Pool.Release(item: Types.VisualItem)
	item.InUse = false
	item.ExpiresAt = 0
	item.Adornment.Visible = false
end

return Pool
