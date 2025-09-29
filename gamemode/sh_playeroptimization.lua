if IS_LOADED_PLAYEROPTIMIZATION then return end -- To avoid refresh lua...
IS_LOADED_PLAYEROPTIMIZATION = true

local ipairs = ipairs
local IsValid = IsValid
local LocalPlayer = LocalPlayer

local AllPlayers = {}
local AllBots = {}
local AllHumans = {}
local PlayerCount = 0

function player.GetCount()
    return PlayerCount
end

function player.GetAll()
	local copy = {}
	for i, v in ipairs(AllPlayers) do
        copy[i] = v
	end
	return copy
end

function player.GetBots()
	local copy = {}
	for i, v in ipairs(AllBots) do
        copy[i] = v
	end
	return copy
end

function player.GetHumans()
	local copy = {}
	for i, v in ipairs(AllHumans) do
        copy[i] = v
	end
	return copy
end

function player.GetAllNoCopy()
    return AllPlayers
end

function player.GetBotsNoCopy()
    return AllBots
end

function player.GetHumansNoCopy()
    return AllHumans
end

if CLIENT then
    hook.Add("InitPostEntity", "InitPostEntity.Players", function()
		local lp = LocalPlayer()
        if table.HasValue(AllPlayers, lp) then return end

		AllPlayers[#AllPlayers+1] = lp
		AllHumans[#AllHumans+1] = lp

        PlayerCount = #AllPlayers
    end)

    hook.Add("NetworkEntityCreated", "NetworkEntityCreated.Players", function(ent)
        if ent:IsPlayer() then
            if table.HasValue(AllPlayers, ent) then return end

			AllPlayers[#AllPlayers+1] = ent
			if ent:IsBot() then
				AllBots[#AllBots+1] = ent
			else
				AllHumans[#AllHumans+1] = ent
			end

            PlayerCount = #AllPlayers
        end
    end, HOOK_MONITOR_HIGH)
else
    hook.Add("PlayerInitialSpawn", "PlayerInitialSpawn.Players", function(pl)
        if table.HasValue(AllPlayers, pl) then return end

		AllPlayers[#AllPlayers+1] = pl
		if pl:IsBot() then
			AllBots[#AllBots+1] = pl
		else
			AllHumans[#AllHumans+1] = pl
		end

        PlayerCount = #AllPlayers
    end, HOOK_MONITOR_HIGH)
end

hook.Add("PlayerDisconnected", "PlayerDisconnected.Players", function(pl)
	table.RemoveByValue(AllPlayers, pl)
	table.RemoveByValue(pl:IsBot() and AllBots or AllHumans, pl)

	PlayerCount = #AllPlayers
end, HOOK_MONITOR_HIGH)
