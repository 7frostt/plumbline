--!strict
local Config = {
	Enabled = true,
	AlwaysOnTop = true,
	DefaultDuration = 0,
	DefaultColor = Color3.fromRGB(80, 160, 255),
	DefaultTransparency = 0.4,
	WireframeThickness = 0.05,

	Raycast = {
		HitColor = Color3.fromRGB(60, 220, 100),
		MissColor = Color3.fromRGB(240, 70, 70),
		HitPointSize = 0.15,
		NormalColor = Color3.fromRGB(255, 215, 0),
		NormalLength = 1.0,
	},

	Pool = {
		InitialCapacityPerType = 16,
		MaxCapacityPerType = 256,
	},
}

return Config
