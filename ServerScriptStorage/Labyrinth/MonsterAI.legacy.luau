local monster = workspace:WaitForChild("Monster")
local humanoid = monster:WaitForChild("Humanoid")
local hrp = monster:WaitForChild("HumanoidRootPart")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local WANDER_SPEED = 8
local CHASE_SPEED = 16
local SIGHT_RANGE = 50
local SIGHT_ANGLE = 70 -- degrees of field of view
local WANDER_CHANGE_INTERVAL = 3 -- seconds between direction changes
local RAYCAST_IGNORE = {monster}

-- State
local isChasing = false
local currentTarget = nil
local lastWanderChange = 0
local wanderDirection = Vector3.new(1, 0, 0)

-- Raycast parameters
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = RAYCAST_IGNORE

-- Check if a player is visible to the monster
local function canSeePlayer(player)
	local character = player.Character
	if not character then return false end
	
	local playerHrp = character:FindFirstChild("HumanoidRootPart")
	if not playerHrp then return false end
	
	-- Check distance
	local distance = (playerHrp.Position - hrp.Position).Magnitude
	if distance > SIGHT_RANGE then return false end
	
	-- Check if player is in front of monster (field of view)
	local toPlayer = (playerHrp.Position - hrp.Position).Unit
	local monsterForward = hrp.CFrame.LookVector
	local dotProduct = monsterForward:Dot(toPlayer)
	local angleThreshold = math.cos(math.rad(SIGHT_ANGLE / 2))
	
	if dotProduct < angleThreshold then return false end
	
	-- Check line of sight with raycast
	local rayDirection = playerHrp.Position - hrp.Position
	local rayResult = workspace:Raycast(hrp.Position, rayDirection, raycastParams)
	
	-- If ray hit nothing or hit the player, they're visible
	if not rayResult then return true end
	if rayResult.Instance:IsDescendantOf(character) then return true end
	
	return false
end

-- Find the closest visible player
local function findVisibleTarget()
	local closestPlayer = nil
	local closestDistance = SIGHT_RANGE
	
	for _, player in Players:GetPlayers() do
		if canSeePlayer(player) then
			local character = player.Character
			if character then
				local playerHrp = character:FindFirstChild("HumanoidRootPart")
				if playerHrp then
					local distance = (playerHrp.Position - hrp.Position).Magnitude
					if distance < closestDistance then
						closestDistance = distance
						closestPlayer = player
					end
				end
			end
		end
	end
	
	return closestPlayer
end

-- Pick a random wander direction
local function pickRandomDirection()
	local angle = math.random() * math.pi * 2
	return Vector3.new(math.cos(angle), 0, math.sin(angle))
end

-- Main update loop
local lastTime = tick()

while true do
	local currentTime = tick()
	local deltaTime = currentTime - lastTime
	lastTime = currentTime
	
	-- Look for visible players
	local target = findVisibleTarget()
	
	if target then
		-- Chase mode
		isChasing = true
		currentTarget = target
		humanoid.WalkSpeed = CHASE_SPEED
		
		local character = target.Character
		if character then
			local playerHrp = character:FindFirstChild("HumanoidRootPart")
			if playerHrp then
				humanoid:MoveTo(playerHrp.Position)
			end
		end
	else
		-- Wander mode
		isChasing = false
		currentTarget = nil
		humanoid.WalkSpeed = WANDER_SPEED
		
		-- Change direction periodically
		if currentTime - lastWanderChange > WANDER_CHANGE_INTERVAL then
			wanderDirection = pickRandomDirection()
			lastWanderChange = currentTime
		end
		
		-- Move in wander direction
		local targetPosition = hrp.Position + wanderDirection * 20
		humanoid:MoveTo(targetPosition)
	end
	
	task.wait(0.1)
end