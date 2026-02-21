local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

-- Dependencies
local MazeConfig = require(script.Parent.MazeConfig)

-- Configuration
local WANDER_SPEED = 8
local CHASE_SPEED = 18
local SIGHT_RANGE = 60
local SIGHT_ANGLE = 90
local CHASE_COOLDOWN = 3
local REACHED_THRESHOLD = 5

-----------------------------------------------------------
-- PROGRAMMATIC MONSTER SETUP
-----------------------------------------------------------
local function getOrCreateMonster()
	local monster = workspace:FindFirstChild("Monster")
	
	-- If it's just a part named Monster or Cube, wrap it in a Model
	if monster and monster:IsA("BasePart") then
		local part = monster
		local model = Instance.new("Model")
		model.Name = "Monster"
		model.Parent = workspace
		part.Name = "HumanoidRootPart"
		part.Parent = model
		model.PrimaryPart = part
		monster = model
	elseif not monster then
		-- Try to find a part named "Cube" to turn into the monster
		local cube = workspace:FindFirstChild("Cube")
		if cube and cube:IsA("BasePart") then
			local model = Instance.new("Model")
			model.Name = "Monster"
			model.Parent = workspace
			cube.Name = "HumanoidRootPart"
			cube.Parent = model
			model.PrimaryPart = cube
			monster = model
		else
			-- Final fallback: Create a cube if nothing exists
			warn("Monster part not found. Creating a temporary one.")
			local model = Instance.new("Model")
			model.Name = "Monster"
			model.Parent = workspace
			local part = Instance.new("Part")
			part.Name = "HumanoidRootPart"
			part.Size = Vector3.new(12, 12, 12)
			part.Position = Vector3.new(0, 10, 0)
			part.Color = Color3.fromRGB(200, 50, 50)
			part.Parent = model
			model.PrimaryPart = part
			monster = model
		end
	end

	-- Ensure Humanoid exists
	local humanoid = monster:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = monster
	end
	
	-- Ensure monster is collisionable and doesn't fall through floor
	local hrp = monster:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CanCollide = true
		hrp.Anchored = false
		-- Set size smaller than corridors (13) to avoid getting stuck
		if hrp.Size.X >= 13 then
			hrp.Size = Vector3.new(11, 11, 11)
		end
	end

	return monster
end

local monster = getOrCreateMonster()
local humanoid = monster:FindFirstChildOfClass("Humanoid")
local hrp = monster.PrimaryPart

-- State variables
local state = "WANDERING"
local targetPlayer = nil
local lastSeenTime = 0

-- Pathfinding setup (Agent info)
local path = PathfindingService:CreatePath({
	AgentRadius = 5.5, -- Half of our monster size (11) plus a little buffer
	AgentHeight = 11,
	AgentCanJump = false,
})

-- Grid calculation (matching CreateLab logic)
local GRID_SIZE = 17
local CUBE_SIZE = 13
local centerSpacing = CUBE_SIZE
local offset = -(9 - 1) * centerSpacing

local function getLabyrinthCenter()
	local lab = workspace:FindFirstChild("Labyrinth")
	local spawn = lab and lab:FindFirstChild("SpawnPoint")
	return spawn and spawn.Position or Vector3.new(0, 5, 0)
end

local centerPosition = getLabyrinthCenter()

local function getPosFromGrid(x, z)
	local xPos = centerPosition.X + offset + (x - 1) * centerSpacing
	local zPos = centerPosition.Z + offset + (z - 1) * centerSpacing
	-- Use the monster's current Y or the labyrinth center's Y
	return Vector3.new(xPos, centerPosition.Y + 6, zPos)
end

-- Pre-calculate walkable cells from MazeConfig
local walkableCells = {}
for x = 1, GRID_SIZE do
	for z = 1, GRID_SIZE do
		local isPillarSlot = (x % 2 == 1 and z % 2 == 1)
		local isFillSlot = (MazeConfig.FillMatrix[x] and MazeConfig.FillMatrix[x][z] == 1)
		
		if not isPillarSlot and not isFillSlot then
			table.insert(walkableCells, {x = x, z = z})
		end
	end
end

-- Raycast vision check
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {monster}

local function canSeePlayer(player)
	local char = player.Character
	if not char then return false end
	local pHrp = char:FindFirstChild("HumanoidRootPart")
	if not pHrp then return false end

	local dist = (pHrp.Position - hrp.Position).Magnitude
	if dist > SIGHT_RANGE then return false end

	local toPlayer = (pHrp.Position - hrp.Position).Unit
	local dot = hrp.CFrame.LookVector:Dot(toPlayer)
	if dot < math.cos(math.rad(SIGHT_ANGLE / 2)) then return false end

	local rayDirection = pHrp.Position - hrp.Position
	local result = workspace:Raycast(hrp.Position, rayDirection, raycastParams)
	if not result or result.Instance:IsDescendantOf(char) then
		return true
	end
	return false
end

local function findVisibleTarget()
	local closest = nil
	local minDist = SIGHT_RANGE
	
	for _, player in Players:GetPlayers() do
		if canSeePlayer(player) then
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local dist = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
				if dist < minDist then
					minDist = dist
					closest = player
				end
			end
		end
	end
	return closest
end

-- Path following logic
local function followPathInternal(targetPos)
	local success, err = pcall(function()
		path:ComputeAsync(hrp.Position, targetPos)
	end)

	if not success or path.Status ~= Enum.PathStatus.Success then
		return "FAILED"
	end

	local waypoints = path:GetWaypoints()
	for i = 1, #waypoints do
		local spotted = findVisibleTarget()
		if spotted then return "SPOTTED", spotted end

		local waypoint = waypoints[i]
		humanoid:MoveTo(waypoint.Position)
		
		local timeout = 0
		while (hrp.Position - waypoint.Position).Magnitude > REACHED_THRESHOLD and timeout < 30 do
			task.wait(0.1)
			timeout = timeout + 1
			spotted = findVisibleTarget()
			if spotted then return "SPOTTED", spotted end
		end
	end
	
	return "REACHED"
end

-- Main AI Logic
task.spawn(function()
	while true do
		if state == "WANDERING" then
			humanoid.WalkSpeed = WANDER_SPEED
			
			if #walkableCells > 0 then
				local cell = walkableCells[math.random(1, #walkableCells)]
				local goalPos = getPosFromGrid(cell.x, cell.z)
				
				local result, spotted = followPathInternal(goalPos)
				if result == "SPOTTED" then
					state = "CHASING"
					targetPlayer = spotted
				end
			else
				task.wait(1)
			end
			
		elseif state == "CHASING" then
			humanoid.WalkSpeed = CHASE_SPEED
			
			if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local playerHrp = targetPlayer.Character.HumanoidRootPart
				
				if canSeePlayer(targetPlayer) then
					lastSeenTime = tick()
					humanoid:MoveTo(playerHrp.Position)
				else
					humanoid:MoveTo(playerHrp.Position)
					if tick() - lastSeenTime > CHASE_COOLDOWN then
						state = "WANDERING"
						targetPlayer = nil
					end
				end
			else
				state = "WANDERING"
				targetPlayer = nil
			end
			task.wait(0.2)
		end
		task.wait(0.1)
	end
end)

print("Monster AI Initialized - Setup complete, wandering started.")

