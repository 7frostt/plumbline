--!strict
local Config = require(script.Config)
local Types = require(script.Types)
local Pool = require(script.Internal.Pool)

local Plumbline = {}
Plumbline.Enabled = Config.Enabled

local function handleLifetime(item: Types.VisualItem, duration: number?)
	local life = duration or Config.DefaultDuration
	if life > 0 then
		task.delay(life, function()
			Pool.Release(item)
		end)
	else
		task.defer(function()
			Pool.Release(item)
		end)
	end
end

-- 3D Marker Point
function Plumbline.Point(position: Vector3, radius: number?, color: Color3?, duration: number?)
	if not Plumbline.Enabled then
		return
	end

	local item = Pool.Acquire("Sphere")
	local sphere = item.Adornment :: SphereHandleAdornment
	sphere.CFrame = CFrame.new(position)
	sphere.Radius = radius or Config.Raycast.HitPointSize
	sphere.Color3 = color or Config.DefaultColor
	sphere.Transparency = Config.DefaultTransparency

	handleLifetime(item, duration)
end

-- Line between two points
function Plumbline.Line(from: Vector3, to: Vector3, color: Color3?, duration: number?, thickness: number?)
	if not Plumbline.Enabled then
		return
	end

	local distance = (to - from).Magnitude
	if distance < 0.001 then
		return
	end

	local item = Pool.Acquire("Cylinder")
	local cylinder = item.Adornment :: CylinderHandleAdornment
	cylinder.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -distance / 2)
	cylinder.Height = distance
	cylinder.Radius = thickness or Config.WireframeThickness
	cylinder.Color3 = color or Config.DefaultColor
	cylinder.Transparency = Config.DefaultTransparency

	handleLifetime(item, duration)
end

-- Orientable Bounding Box
function Plumbline.Box(cframe: CFrame, size: Vector3, color: Color3?, duration: number?)
	if not Plumbline.Enabled then
		return
	end

	local item = Pool.Acquire("Box")
	local box = item.Adornment :: BoxHandleAdornment
	box.CFrame = cframe
	box.Size = size
	box.Color3 = color or Config.DefaultColor
	box.Transparency = Config.DefaultTransparency

	handleLifetime(item, duration)
end

-- Sphere volume / radius
function Plumbline.Sphere(center: Vector3, radius: number, color: Color3?, duration: number?)
	if not Plumbline.Enabled then
		return
	end

	local item = Pool.Acquire("Sphere")
	local sphere = item.Adornment :: SphereHandleAdornment
	sphere.CFrame = CFrame.new(center)
	sphere.Radius = radius
	sphere.Color3 = color or Config.DefaultColor
	sphere.Transparency = Config.DefaultTransparency

	handleLifetime(item, duration)
end

-- Directional Arrow (Ray / Vector / Velocity)
function Plumbline.Arrow(origin: Vector3, vector: Vector3, color: Color3?, duration: number?)
	if not Plumbline.Enabled then
		return
	end

	local length = vector.Magnitude
	if length < 0.001 then
		return
	end

	local tip = origin + vector
	local arrowColor = color or Config.DefaultColor

	-- Draw shaft
	Plumbline.Line(origin, tip, arrowColor, duration)

	-- Draw arrowhead
	local headItem = Pool.Acquire("Sphere")
	local head = headItem.Adornment :: SphereHandleAdornment
	head.CFrame = CFrame.new(tip)
	head.Radius = Config.Raycast.HitPointSize * 1.2
	head.Color3 = arrowColor
	head.Transparency = 0.1

	handleLifetime(headItem, duration)
end

-- Smart Raycast Visualizer
function Plumbline.Ray(
	origin: Vector3,
	direction: Vector3,
	result: RaycastResult?,
	duration: number?,
	options: Types.RayOptions?
)
	if not Plumbline.Enabled then
		return
	end

	local hitColor = Config.Raycast.HitColor
	local missColor = Config.Raycast.MissColor
	local life = duration or Config.DefaultDuration
	local hitPointSize = Config.Raycast.HitPointSize
	local showNormal = true
	local normalLen = Config.Raycast.NormalLength
	local normalColor = Config.Raycast.NormalColor

	if options then
		if options.HitColor then
			hitColor = options.HitColor
		end
		if options.MissColor then
			missColor = options.MissColor
		end
		if options.Duration then
			life = options.Duration
		end
		if options.HitPointSize then
			hitPointSize = options.HitPointSize
		end
		if options.ShowNormal ~= nil then
			showNormal = options.ShowNormal
		end
		if options.NormalLength then
			normalLen = options.NormalLength
		end
		if options.NormalColor then
			normalColor = options.NormalColor
		end
	end

	if result then
		-- Clamped to hit position
		local hitPos = result.Position
		Plumbline.Line(origin, hitPos, hitColor, life)

		-- Impact dot
		Plumbline.Point(hitPos, hitPointSize, hitColor, life)

		-- Surface normal indicator
		if showNormal then
			Plumbline.Arrow(hitPos, result.Normal * normalLen, normalColor, life)
		end
	else
		-- Ray missed: show full trace in red
		local endPos = origin + direction
		Plumbline.Line(origin, endPos, missColor, life)
	end
end

-- Swept Box Visualizer (Blockcast)
function Plumbline.Blockcast(
	cframe: CFrame,
	size: Vector3,
	direction: Vector3,
	result: RaycastResult?,
	duration: number?,
	options: Types.RayOptions?
)
	if not Plumbline.Enabled then
		return
	end

	local life = duration or Config.DefaultDuration
	local hitColor = Config.Raycast.HitColor
	local missColor = Config.Raycast.MissColor

	if options then
		if options.HitColor then
			hitColor = options.HitColor
		end
		if options.MissColor then
			missColor = options.MissColor
		end
		if options.Duration then
			life = options.Duration
		end
	end

	-- 1. Initial box where the cast started
	Plumbline.Box(cframe, size, Color3.fromRGB(180, 180, 180), life)

	if result then
		-- Travel distance clamped by hit
		local distance = (result.Position - cframe.Position).Magnitude
		local sweepDir = direction.Unit * distance
		local endCFrame = cframe + sweepDir

		-- Center trajectory line
		Plumbline.Line(cframe.Position, endCFrame.Position, hitColor, life)

		-- Terminal box where the cast collided
		Plumbline.Box(endCFrame, size, hitColor, life)

		-- Impact marker & surface normal
		Plumbline.Point(result.Position, 0.2, hitColor, life)
		Plumbline.Arrow(result.Position, result.Normal * 1.5, Config.Raycast.NormalColor, life)
	else
		-- Swept all the way to max distance without hitting anything
		local endCFrame = cframe + direction
		Plumbline.Line(cframe.Position, endCFrame.Position, missColor, life)
		Plumbline.Box(endCFrame, size, missColor, life)
	end
end

-- Swept Sphere Visualizer (Spherecast)
function Plumbline.Spherecast(
	origin: Vector3,
	radius: number,
	direction: Vector3,
	result: RaycastResult?,
	duration: number?,
	options: Types.RayOptions?
)
	if not Plumbline.Enabled then
		return
	end

	local life = duration or Config.DefaultDuration
	local hitColor = Config.Raycast.HitColor
	local missColor = Config.Raycast.MissColor

	if options then
		if options.HitColor then
			hitColor = options.HitColor
		end
		if options.MissColor then
			missColor = options.MissColor
		end
		if options.Duration then
			life = options.Duration
		end
	end

	-- 1. Starting sphere
	Plumbline.Sphere(origin, radius, Color3.fromRGB(180, 180, 180), life)

	if result then
		local distance = (result.Position - origin).Magnitude
		local sweepDir = direction.Unit * distance
		local endPos = origin + sweepDir

		-- Center travel line
		Plumbline.Line(origin, endPos, hitColor, life)

		-- Terminal collided sphere
		Plumbline.Sphere(endPos, radius, hitColor, life)

		-- Impact marker & surface normal
		Plumbline.Point(result.Position, 0.2, hitColor, life)
		Plumbline.Arrow(result.Position, result.Normal * 1.5, Config.Raycast.NormalColor, life)
	else
		-- Full miss
		local endPos = origin + direction
		Plumbline.Line(origin, endPos, missColor, life)
		Plumbline.Sphere(endPos, radius, missColor, life)
	end
end

-- Advanced 3D Gizmo Axes (Includes planar glass for XYZ planes)
function Plumbline.Axes(cframe: CFrame, size: number?, duration: number?)
	if not Plumbline.Enabled then
		return
	end

	local length = size or 2
	local life = duration or Config.DefaultDuration
	local pos = cframe.Position

	-- Draw directional arrows
	Plumbline.Arrow(pos, cframe.RightVector * length, Color3.fromRGB(255, 60, 60), life)
	Plumbline.Arrow(pos, cframe.UpVector * length, Color3.fromRGB(60, 240, 80), life)
	Plumbline.Arrow(pos, cframe.LookVector * length, Color3.fromRGB(60, 140, 255), life)

	-- Draw translucent planes (XY, XZ, YZ)
	local planeSize = length * 0.4
	local planeOffset = planeSize / 2

	-- XY Plane (Front/Back) - Blue tint
	Plumbline.Box(
		cframe * CFrame.new(planeOffset, planeOffset, 0),
		Vector3.new(planeSize, planeSize, 0.05),
		Color3.fromRGB(60, 140, 255),
		life
	)
	-- XZ Plane (Floor) - Green tint
	Plumbline.Box(
		cframe * CFrame.new(planeOffset, 0, -planeOffset),
		Vector3.new(planeSize, 0.05, planeSize),
		Color3.fromRGB(60, 240, 80),
		life
	)
	-- YZ Plane (Side) - Red tint
	Plumbline.Box(
		cframe * CFrame.new(0, planeOffset, -planeOffset),
		Vector3.new(0.05, planeSize, planeSize),
		Color3.fromRGB(255, 60, 60),
		life
	)
end

-- Advanced Multi-Bounce Trajectory / Prediction
function Plumbline.Trajectory(
	origin: Vector3,
	velocity: Vector3,
	gravity: Vector3?,
	duration: number?,
	segments: number?,
	raycastParams: RaycastParams?
)
	if not Plumbline.Enabled then
		return
	end

	local grav = gravity or Vector3.new(0, -workspace.Gravity, 0)
	local life = duration or Config.DefaultDuration
	local color = Color3.fromRGB(255, 200, 50)
	local timeStep = 0.05
	local maxBounces = 3
	local bounciness = 0.65

	local currentPos = origin
	local currentVel = velocity
	local bounces = 0

	for _ = 1, (segments or 50) do
		local nextPos = currentPos + (currentVel * timeStep) + (0.5 * grav * (timeStep * timeStep))
		local delta = nextPos - currentPos

		if raycastParams then
			local hit = workspace:Raycast(currentPos, delta, raycastParams)
			if hit then
				-- Draw line to impact
				Plumbline.Line(currentPos, hit.Position, color, life)
				Plumbline.Point(hit.Position, 0.25, Color3.fromRGB(255, 100, 100), life)

				bounces += 1
				if bounces > maxBounces then
					break
				end

				-- Calculate bounce velocity
				local normal = hit.Normal
				currentVel = (currentVel - 2 * currentVel:Dot(normal) * normal) * bounciness
				currentPos = hit.Position + (normal * 0.1)
				continue
			end
		end

		Plumbline.Line(currentPos, nextPos, color, life)
		currentPos = nextPos
		currentVel += grav * timeStep
	end
end

-- Advanced Radar Vision Cone (Depth rings + solid base)
function Plumbline.Cone(
	origin: Vector3,
	direction: Vector3,
	angleDeg: number,
	range: number,
	duration: number?,
	color: Color3?
)
	if not Plumbline.Enabled then
		return
	end

	local coneColor = color or Config.DefaultColor
	local life = duration or Config.DefaultDuration
	local dirUnit = direction.Unit
	local halfRad = math.rad(angleDeg / 2)

	local forward = dirUnit
	local up = if math.abs(forward.Y) > 0.99 then Vector3.new(0, 0, 1) else Vector3.new(0, 1, 0)
	local right = forward:Cross(up).Unit
	local trueUp = right:Cross(forward).Unit

	local edgeCount = 12

	-- Draw concentric rings at 50% and 100% distance to show volume depth
	for _, distanceScale in ipairs({ 0.5, 1.0 }) do
		local currentDist = range * distanceScale
		local coneHeight = currentDist * math.cos(halfRad)
		local baseRadius = currentDist * math.sin(halfRad)
		local baseCenter = origin + (forward * coneHeight)

		local prevPoint = nil
		local firstPoint = nil

		for i = 1, edgeCount do
			local theta = (i - 1) * (2 * math.pi / edgeCount)
			local radialOffset = (right * math.cos(theta) + trueUp * math.sin(theta)) * baseRadius
			local rimPoint = baseCenter + radialOffset

			if prevPoint then
				Plumbline.Line(prevPoint, rimPoint, coneColor, life, 0.03)
			else
				firstPoint = rimPoint
			end
			prevPoint = rimPoint

			-- Only draw corner spokes out to the max range
			if distanceScale == 1.0 and i % 3 == 0 then
				Plumbline.Line(origin, rimPoint, coneColor, life, 0.05)
			end
		end
		-- Close the ring
		if prevPoint and firstPoint then
			Plumbline.Line(prevPoint, firstPoint, coneColor, life, 0.03)
		end
	end

	-- Center spine
	Plumbline.Line(origin, origin + (forward * range), Color3.fromRGB(255, 255, 255), life)
end

return Plumbline
