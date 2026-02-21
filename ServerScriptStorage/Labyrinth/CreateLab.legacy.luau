-- CreateLab Script
-- Generates a maze with pillars and fill cubes using an 18x18 matrix configuration

local Workspace = game:GetService("Workspace")

-- Configuration
local GRID_SIZE = 17 -- 17x17 grid of cells
local CUBE_SIZE = 13 -- Size of each cube
local CUBE_HEIGHT = 22.5 -- 1.5x of previous 15
local WALL_HEIGHT = 22.5

local MazeConfig = require(script.Parent.MazeConfig)
local FillMatrix = MazeConfig.FillMatrix

-- Helper function to create a cube
local function createCube(name, position, size, color)
    local cube = Instance.new("Part")
    cube.Name = name
    cube.Size = size
    -- Offset Y so the bottom of the cube is at the provided position.Y
    cube.Position = position + Vector3.new(0, size.Y/2, 0)
    cube.Anchored = true
    cube.CanCollide = true
    if color then
        cube.Color = color
    end
    cube.Parent = Workspace.Labyrinth
    return cube
end

-- Get the spawnpoint position
local spawnPoint = Workspace.Labyrinth:FindFirstChild("SpawnPoint")
if not spawnPoint then
    warn("SpawnPoint not found in Workspace.Labyrinth")
    return
end

local centerPosition = spawnPoint.Position

-- Each cell is one cube size apart
local centerSpacing = CUBE_SIZE 

-- Calculate offset so the pillar at (9,9) is at the centerPosition
local offset = -(9 - 1) * centerSpacing

-- Unified Generation Loop
local totalCount = 0
local pillarCount = 0
local fillCount = 0

for x = 1, GRID_SIZE do
    for z = 1, GRID_SIZE do
        local xPos = centerPosition.X + offset + (x - 1) * centerSpacing
        local zPos = centerPosition.Z + offset + (z - 1) * centerSpacing
        
        local isPillarSlot = (x % 2 == 1 and z % 2 == 1)
        local isSpawnSlot = (x == 9 and z == 9)
        local isFillSlot = (FillMatrix[x] and FillMatrix[x][z] == 1)
        
        if isSpawnSlot then continue end
        
        if isPillarSlot then
            -- Create Pillar
            createCube(
                "Pillar_" .. x .. "_" .. z,
                Vector3.new(xPos, centerPosition.Y, zPos),
                Vector3.new(CUBE_SIZE, CUBE_HEIGHT, CUBE_SIZE),
                Color3.fromRGB(150, 150, 150)
            )
            pillarCount = pillarCount + 1
            totalCount = totalCount + 1
        elseif isFillSlot then
            -- Create Fill Cube
            createCube(
                "Fill_" .. x .. "_" .. z,
                Vector3.new(xPos, centerPosition.Y, zPos),
                Vector3.new(CUBE_SIZE, CUBE_HEIGHT, CUBE_SIZE),
                Color3.fromRGB(120, 120, 120)
            )
            fillCount = fillCount + 1
            totalCount = totalCount + 1
        end
    end
end

print("Created " .. pillarCount .. " pillars")
print("Created " .. fillCount .. " fill cubes")
print("Total: " .. totalCount .. " objects")
