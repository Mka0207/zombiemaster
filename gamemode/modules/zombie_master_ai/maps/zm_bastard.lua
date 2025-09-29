-- Table layout
-------------------------------------
-- trapName, what's the trap
-- creationID, map creationID of the trap
-- usageChance, chance the trap is used, nil means bot choses
-- usageRadius, the radius of the trap, nil means bot choses
-- positions, position for the trap (One vector), trigger box (Two vectors), nil means default position
-- lineOfSight, if player needs to be in view of the trap
-------------------------------------

local mapTrapSettings = {
    {
        trapName    = "Ceiling Trap 12",
        creationID  = 1282,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(192, 1984, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Ceiling Trap 10",
        creationID  = 1283,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(192, 1728, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Ceiling Trap 11",
        creationID  = 1284,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(192, 1856, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Ceiling Trap 9",
        creationID  = 1285,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(64, 1984, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Ceiling Trap 8",
        creationID  = 1286,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(64, 1856, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Ceiling Trap 7",
        creationID  = 1287,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(64, 1728, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Ceiling Trap 4",
        creationID  = 1288,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(-64, 1728, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Ceiling Trap 5",
        creationID  = 1289,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(-64, 1856, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Ceiling Trap 6",
        creationID  = 1290,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(-64, 1984, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Ceiling Trap 3",
        creationID  = 1291,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(-192, 1984, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Ceiling Trap 2",
        creationID  = 1292,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(-192, 1856, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Ceiling Trap 1",
        creationID  = 1293,
        usageChance = nil,
        usageRadius = 2048,
        positions   = {Vector(-192, 1728, -192)},
        lineOfSight = true
    },
    {
        trapName    = "Drop Platform",
        creationID  = 1402,
        usageChance = nil,
        usageRadius = 256,
        positions   = {Vector(0, 4000, -2336)},
        lineOfSight = true
    },
    {
        trapName    = "Crusher 1",
        creationID  = 1404,
        usageChance = nil,
        usageRadius = nil,
        positions   = {Vector(0, 4000, -2336)},
        lineOfSight = true
    },
    {
        trapName    = "Crusher 2",
        creationID  = 1401,
        usageChance = nil,
        usageRadius = nil,
        positions   = {Vector(-1920, 5120, -2432)},
        lineOfSight = true
    },
    {
        trapName    = "Crusher 3",
        creationID  = 1399,
        usageChance = nil,
        usageRadius = nil,
        positions   = {Vector(-1600, 5280, -2432)},
        lineOfSight = true
    },
    {
        trapName    = "Massive Ball",
        creationID  = 1403,
        usageChance = nil,
        usageRadius = 512,
        positions   = {Vector(-1056, 6544, -2400)},
        lineOfSight = true
    },
    {
        trapName    = "Berkin",
        creationID  = 1610,
        usageChance = nil,
        usageRadius = 512,
        positions   = {Vector(2432, 7168, -2664)},
        lineOfSight = false
    },
    {
        trapName    = "Smallify",
        creationID  = 2619,
        usageChance = nil,
        usageRadius = 256,
        positions   = {Vector(6016, 5248, -3840)},
        lineOfSight = true
    },
    {
        trapName    = "Banshee Spawner",
        creationID  = 2650,
        usageChance = nil,
        usageRadius = 512,
        positions   = {Vector(4480, 7168, -3016)},
        lineOfSight = false
    }
}

return nil, mapTrapSettings, nil