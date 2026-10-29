--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Plumbline = require(ReplicatedStorage.Shared.Plumbline)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local arena = workspace:WaitForChild("Plumbline_DemoArena")
local turretBase = arena:WaitForChild("TurretBase") :: Part

print("--- [Plumbline Spatial Debugger] ---")
print("Left Click : Shotgun spread with wall ricochets (Rays + Normals)")
print("Press [E]  : Active Melee Hitbox query (Box volume)")
print("Press [F]  : Swept Box Projection (Blockcast)")
print("Press [G]  : Multi-Bounce Trajectory Arc (Grenade toss physics)")
print("Press [V]  : Smart Vision Cone (Detects dummy in stealth range)")
print("Press [X]  : 3D Professional Axes Gizmo")

-- 1. CONTINUOUS SCANNER TURRET (Runs every frame)

local clock = 0
RunService.RenderStepped:Connect(function(dt: number)
	clock += dt * 1.5

	local turretHeadPos = turretBase.Position + Vector3.new(0, 2.5, 0)
	local angle = math.sin(clock) * 0.75
	local sweepDir = (CFrame.Angles(0, angle, 0) * Vector3.new(0, -0.05, -1)).Unit * 80

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character, turretBase }

	-- Primary beam
	local res1 = workspace:Raycast(turretHeadPos, sweepDir, params)
	Plumbline.Ray(turretHeadPos, sweepDir, res1, 0, {
		HitColor = Color3.fromRGB(0, 255, 180),
		MissColor = Color3.fromRGB(100, 100, 100),
		NormalLength = 1.2,
		NormalColor = Color3.fromRGB(255, 230, 80),
	})

	-- Surface ricochet off obstacles
	if res1 then
		local incoming = (res1.Position - turretHeadPos).Unit
		local bounceDir = (incoming - 2 * incoming:Dot(res1.Normal) * res1.Normal).Unit * 50
		local res2 = workspace:Raycast(res1.Position, bounceDir, params)

		Plumbline.Ray(res1.Position, bounceDir, res2, 0, {
			HitColor = Color3.fromRGB(255, 170, 0),
			MissColor = Color3.fromRGB(180, 120, 40),
			NormalLength = 0.8,
			NormalColor = Color3.fromRGB(255, 255, 255),
		})
	end
end)

-- 2. SHOTGUN SPREAD WITH RICOCHETS

local function fireShotgun()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local origin = camera.CFrame.Position
	local target = mouse.Hit.Position
	local baseDir = (target - origin).Unit

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }

	for _ = 1, 5 do
		local spread =
			Vector3.new((math.random() - 0.5) * 0.15, (math.random() - 0.5) * 0.15, (math.random() - 0.5) * 0.15)
		local dir = (baseDir + spread).Unit * 120
		local result = workspace:Raycast(origin, dir, params)

		Plumbline.Ray(origin, dir, result, 2.0)

		if result then
			local incoming = (result.Position - origin).Unit
			local reflectDir = (incoming - 2 * incoming:Dot(result.Normal) * result.Normal).Unit * 30
			local bounceResult = workspace:Raycast(result.Position, reflectDir, params)

			Plumbline.Ray(result.Position, reflectDir, bounceResult, 2.0, {
				HitColor = Color3.fromRGB(255, 170, 0),
				MissColor = Color3.fromRGB(255, 200, 80),
				NormalLength = 0.5,
			})
		end
	end
end

-- 3. INTERACTIVE INPUT HANDLERS

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	local char = player.Character
	if not char or not char.PrimaryPart then
		return
	end
	local root = char.PrimaryPart

	-- Left-Click: Shotgun
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		fireShotgun()

	-- [E] Melee Attack Sweep
	elseif input.KeyCode == Enum.KeyCode.E then
		local hitboxCFrame = root.CFrame * CFrame.new(0, 0, -3.5)
		local hitboxSize = Vector3.new(4, 4, 4)

		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		overlapParams.FilterDescendantsInstances = { char, turretBase }

		local hits = workspace:GetPartBoundsInBox(hitboxCFrame, hitboxSize, overlapParams)

		if #hits > 0 then
			Plumbline.Box(hitboxCFrame, hitboxSize, Color3.fromRGB(60, 240, 100), 1.0)
		else
			Plumbline.Box(hitboxCFrame, hitboxSize, Color3.fromRGB(240, 70, 70), 0.5)
		end

	-- [F] Swept Dash / Blockcast
	elseif input.KeyCode == Enum.KeyCode.F then
		local castCFrame = root.CFrame
		local boxSize = Vector3.new(2.5, 4, 2.5)
		local direction = root.CFrame.LookVector * 30
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }

		local result = workspace:Blockcast(castCFrame, boxSize, direction, params)
		Plumbline.Blockcast(castCFrame, boxSize, direction, result, 2.5)

	-- [G] Multi-Bounce Grenade Trajectory
	elseif input.KeyCode == Enum.KeyCode.G then
		local origin = root.Position + Vector3.new(0, 2, 0)
		local tossVelocity = (root.CFrame.LookVector * 45) + Vector3.new(0, 20, 0)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }

		Plumbline.Trajectory(origin, tossVelocity, nil, 4.0, 150, params)

	-- [V] Smart NPC Vision Cone (Stealth Detection)
	elseif input.KeyCode == Enum.KeyCode.V then
		local origin = root.Position + Vector3.new(0, 1, 0)
		local direction = root.CFrame.LookVector
		local fovAngles = 60
		local viewRange = 25

		local dummyHead = arena:FindFirstChild("DummyHead")
		local detected = false

		if dummyHead then
			local vectorToDummy = dummyHead.Position - origin
			local distance = vectorToDummy.Magnitude

			if distance <= viewRange then
				local angleToDummy = math.deg(math.acos(direction:Dot(vectorToDummy.Unit)))
				if angleToDummy <= (fovAngles / 2) then
					detected = true
				end
			end
		end

		if detected then
			Plumbline.Cone(origin, direction, fovAngles, viewRange, 3.0, Color3.fromRGB(255, 40, 40))
			print("🚨 [ALERT] TARGET SPOTTED IN VISION CONE!")
		else
			Plumbline.Cone(origin, direction, fovAngles, viewRange, 1.5, Color3.fromRGB(80, 200, 255))
		end

	-- [X] Professional 3D Gizmo
	elseif input.KeyCode == Enum.KeyCode.X then
		local camera = workspace.CurrentCamera
		if camera then
			Plumbline.Axes(camera.CFrame * CFrame.new(0, 0, -6), 3.0, 5.0)
		end
	end
end)
