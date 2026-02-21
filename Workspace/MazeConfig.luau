-- Maze Configuration Module
-- Configure your maze layout using these matrices

local MazeConfig = {}

-- Fill Matrix (9x9)
-- 1 = add full cube filling the space between pillars
-- 0 = empty space (just the pillars)
-- This matrix represents the spaces between the 9x9 pillar grid
MazeConfig.FillMatrix = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

-- Wall Matrix (8x8)
-- Each cell represents the intersection between 4 pillars
-- Each cell is an object with properties: top, left, right, bottom
-- Set to true to create a wall in that direction
-- Example: {top=true, left=false, right=false, bottom=true}
MazeConfig.WallMatrix = {
    {{},{},{},{},{},{},{},{}},
    {{},{},{},{},{},{},{},{}},
    {{},{},{},{},{},{},{},{}},
    {{},{},{},{},{},{},{},{}},
    {{},{},{},{},{},{},{},{}},
    {{},{},{},{},{},{},{},{}},
    {{},{},{},{},{},{},{},{}},
    {{},{},{},{},{},{},{},{}},
}


-- ============================================
-- EXAMPLE CONFIGURATIONS (uncomment to use)
-- ============================================

-- Example 1: Add a fill cube between pillars (0,0) and (1,1)
-- MazeConfig.FillMatrix[1][1] = 1

-- Example 2: Create a dead end at corner (0,0) with walls on top and left
-- MazeConfig.WallMatrix[1][1] = {top=true, left=true, right=false, bottom=false}

-- Example 3: Create a wall on the right side of intersection (2,2)
-- MazeConfig.WallMatrix[3][3] = {top=false, left=false, right=true, bottom=false}

-- Example 4: Create a full enclosure at intersection (4,4)
-- MazeConfig.WallMatrix[5][5] = {top=true, left=true, right=true, bottom=true}

-- Example 5: Add multiple fill cubes to create a solid area
-- MazeConfig.FillMatrix[1][1] = 1
-- MazeConfig.FillMatrix[2][1] = 1
-- MazeConfig.FillMatrix[1][2] = 1
-- MazeConfig.FillMatrix[2][2] = 1

return MazeConfig
