local zombieData = {}
function GM:AddZombieType(name, data)
    if data.Disabled then return end
    zombieData[name] = data
end

function GM:GetZombieTable(bShowDefault)
    local zombietab = table.Copy(zombieData)
    if not bShowDefault then
        zombietab["class_default"] = nil
    end

    return zombietab
end

function GM:GetZombieData(class)
    for _, data in pairs(zombieData) do
        if data.Class == class then
            return data
        end
    end

    return zombieData["class_default"]
end

function GM:GetZombieTables()
    return zombieData
end

function GM:CallZombieFunction(npc, func, ...)
    if not (npc and npc:IsValid()) then return end

    local zombie = self:GetZombieData(npc:GetClass())
    if not zombie then return end

    local func_tocall = zombie[func]
    if func_tocall then
        return func_tocall(zombie, npc, ...)
    end
end

function GM:BuildZombieDataTable()
    for k, v in pairs(zombieData) do
        if k ~= "class_default" then
            if not v.Base then v.Base = "class_default" end
            local basetable = zombieData[v.Base]
            if basetable then
                table.Inherit(v, basetable)
            end
        end

        baseclass.Set(k, v)
    end
end

function GM:CanSpawnZombie(flag, iZombieFlags)
    return iZombieFlags <= 0 or bit.band(iZombieFlags, flag) ~= 0
end

function GM:GetCurZombiePop()
    return GetGlobalInt("m_iZombiePopCount", 0)
end

function GM:GetMaxZombiePop()
    local maxpopulation = GetConVar("zm_zombiemax"):GetInt()
    local count = player.GetCount() - 4
    if count > 0 then
        local dynpop = GetConVar("zm_dynamicpopulationincrease"):GetInt()
        if dynpop > 0 then
            maxpopulation = maxpopulation + (dynpop * count)
        end
    end

    return maxpopulation
end

local function AddZombieTypes(filename, directory, bWasFolderType)
    local fname = string.StripExtension(string.lower(filename))
    if bWasFolderType and (fname == "init" or fname == "shared" or fname == "cl_init") then
        if CLIENT and fname == "init" then return
        elseif SERVER and (fname == "shared" or fname == "cl_init") then AddCSLuaFile(directory) end

        include(directory)
    elseif not bWasFolderType then
        AddCSLuaFile(directory)
        include(directory)
    end
end

local zombiedir = "zombies"
local path = GM.FolderName.."/gamemode/"..zombiedir.."/"
local files, directories = file.Find(path.."*", "LUA")
for i, directory in ipairs(directories) do
    NPC = {}
    if file.Exists(path..directory.."/shared.lua", "LUA") then
        local shf = zombiedir.."/"..directory.."/shared.lua"
        AddCSLuaFile(shf)
        include(shf)
    end
    for i, filename in ipairs(file.Find(path..directory.."/*.lua", "LUA")) do
        if filename ~= "shared.lua" then
            AddZombieTypes(filename, zombiedir.."/"..directory.."/"..filename, true)
        end
    end
    GM:AddZombieType(directory, NPC)
    NPC = nil
end

for i, filename in ipairs(files) do
    if string.GetExtensionFromFilename(filename) == "lua" then
        NPC = {}
        AddZombieTypes(filename, zombiedir.."/"..filename)
        GM:AddZombieType(string.StripExtension(filename), NPC)
        NPC = nil
    end
end