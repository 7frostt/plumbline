--!strict
export type AdornmentType = "Box" | "Sphere" | "Cylinder" | "Line"

export type VisualItem = {
	Adornment: HandleAdornment,
	Type: AdornmentType,
	ExpiresAt: number,
	InUse: boolean,
}

export type RayOptions = {
	Duration: number?,
	HitColor: Color3?,
	MissColor: Color3?,
	ShowNormal: boolean?,
	NormalColor: Color3?,
	NormalLength: number?,
	HitPointSize: number?,
}

export type PrimitiveOptions = {
	Color: Color3?,
	Transparency: number?,
	Duration: number?,
	AlwaysOnTop: boolean?,
}

return nil
