GM.Name = "Zombie Master"
GM.Author = "Forrest Mark X"
GM.Email = "forrestmarkx@outlook.com"
GM.Website = "http://steamcommunity.com/id/ForrestMarkX/"
GM.TeamBased = true

include("sh_playeroptimization.lua")
include("nixthelag.lua")
include("sh_translate.lua")
include("sh_sounds.lua")
include("sh_zm_globals.lua")
include("sh_utility.lua")
include("sh_zerolag.lua")

include("sh_zm_options.lua")

include("sh_string.lua")
include("sh_math.lua")
include("sh_vector.lua")
include("sh_weapons.lua")
include("sh_players.lua")
include("sh_entites.lua")
include("sh_zombies.lua")
include("sh_npc.lua")
include("sh_animations.lua")

include("player_class/player_basezm.lua")
include("player_class/player_survivor.lua")
include("player_class/player_zombiemaster.lua")
include("player_class/player_spectator.lua")

GM.NetworkVarCallbacks = {}
GM.iZombieList = {}
GM.ObjectiveObjects = {}

function GM:Initialize()
    hook.Call("SetupCustomItems", self)

    for _, mdl in pairs(file.Find("models/zombie/*.mdl", "GAME")) do
        util.PrecacheModel(mdl)
    end

    game.AddAmmoType({ name = "pistol", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_pistol"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_pistol"):GetInt(), maxcarry = GetConVar("zm_maxammo_pistol"):GetInt(), force = 2400 })
    game.AddAmmoType({ name = "smg1", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_smg1"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_smg1"):GetInt(), maxcarry = GetConVar("zm_maxammo_smg1"):GetInt(), force = 2200 })
    game.AddAmmoType({ name = "357", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_357"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_357"):GetInt(), maxcarry = GetConVar("zm_maxammo_357"):GetInt(), force = 3800 })
    game.AddAmmoType({ name = "buckshot", dmgtype = bit.bor(DMG_BULLET, DMG_BUCKSHOT), tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_buckshot"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_buckshot"):GetInt(), maxcarry = GetConVar("zm_maxammo_buckshot"):GetInt(), force = 1300 })
    game.AddAmmoType({ name = "revolver", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = 0, npcdmg = 0, maxcarry = GetConVar("zm_maxammo_revolver"):GetInt(), force = 3200 })
    game.AddAmmoType({ name = "molotov", dmgtype = DMG_BURN, tracer = TRACER_NONE, plydmg = 0, npcdmg = 0, maxcarry = GetConVar("zm_maxammo_molotov"):GetInt(), force = 0 })

    hook.Call("BuildZombieDataTable", self)
    hook.Call("SetupNetworkingCallbacks", self)

    if CLIENT then
        language.Add("revolver_ammo", "Revolver Ammo")
        language.Add("item_revolver_ammo", "Revolver Ammo")
        language.Add("molotov_ammo", "Molotov Ammo")

        self:SetupFonts()
    else
        self.bReplaceZombiesWithNextBots = file.Exists("maps/"..game.GetMap()..".nav", "GAME")

        if not self.bReplaceZombiesWithNextBots and GetConVar("zm_force_nextbots"):GetBool() then
            self.bReplaceZombiesWithNextBots = true
        end

        if self.bReplaceZombiesWithNextBots and system.IsLinux() then
            local succ, _ = pcall(require, "killsethintgroup")
            if not succ then
                --self.bReplaceZombiesWithNextBots = false
                print("[FIX NEXTBOT CRASH]: Module cannot be load!")
            end
        end

        self:ApplyZombieClasses()
    end
end

function GM:SetupCustomItems()
    self:AddCustomWeapon("weapon_zm_shotgun", "weapon_zm_olympia", 0.5)
    --self:AddCustomWeapon("weapon_zm_mac10", "weapon_zm_mp7", 0.5)
    --self:AddCustomWeapon("weapon_zm_revolver", "weapon_zm_deagle", 0.5)
end

function GM:CreateTeams()
    team.SetUp(TEAM_SURVIVOR, Either(CLIENT, translate.Get("team_survivor_l"), "Survivors"), Color(255, 64, 64, 255))
    team.SetSpawnPoint(TEAM_SURVIVOR, "info_player_deathmatch")

    team.SetUp(TEAM_ZOMBIEMASTER, Either(CLIENT, translate.Get("team_zombiemaster_l"), "Zombie Master"), Color(153, 255, 153, 255))
    team.SetSpawnPoint(TEAM_ZOMBIEMASTER, "info_player_zombiemaster")

    team.SetUp(TEAM_SPECTATOR, Either(CLIENT, translate.Get("team_spectators_l"), "Spectators"), Color(120, 120, 120, 255))
    team.SetSpawnPoint(TEAM_SPECTATOR, "info_player_zombiemaster")
end

function GM:FindZM()
    if SERVER then return self.pZombieMaster end
    return GetGlobalEntity("zm_zombiemaster_player")
end

function GM:FindZMs()
    return team.GetPlayers( TEAM_ZOMBIEMASTER )
end

function GM:PlayerShouldTakeDamage(pl, attacker)
    return player_manager.RunClass(pl, "ShouldTakeDamage", attacker)
end

function GM:IsSpecialPerson(pl, image)
    local img, tooltip
    local steamid = pl:SteamID()

    if steamid == "STEAM_0:0:18807892" then
        img = "icon16/page_white_cplusplus.png"
        tooltip = "ForrestMarkX\nDeveloper!"
    elseif pl:IsAdmin() then
        img = "icon16/shield.png"
        tooltip = "Admin"
    else
        local contributor = self.ContributorList[steamid]
        if contributor then
            img = "icon16/heart.png"
            tooltip = contributor.."\nContributor!"
        end
    end

    if img then
        if CLIENT then
            image:SetImage(img)
            image:SetTooltip(tooltip)
        end

        return true
    end

    return false
end

function GM:GetRoundActive()
    return GetGlobalBool("zm_round_active", false)
end

function GM:GetPreRoundEnd()
    return GetGlobalBool("zm_preround_ended", false)
end

function GM:GetRoundEnd()
    return GetGlobalBool("zm_round_ended", false)
end

function GM:GetRoundsPlayed()
    return GetGlobalInt("zm_rounds_played", 0)
end

function GM:GetReadyCount()
    return GetGlobalInt("zm_ready_counter", -1)
end

function GM:GetGameStarting()
    return GetGlobalBool("zm_game_ready", false)
end

function GM:SetupMove(ply, mv, cmd)
    player_manager.RunClass(ply, "SetupMove", mv, cmd)
end

function GM:AddNetworkingCallbacks(name, func)
    if self.NetworkVarCallbacks[name] then return end
    self.NetworkVarCallbacks[name] = func
end

Old_DTVar_ReceiveProxyGL = Old_DTVar_ReceiveProxyGL or DTVar_ReceiveProxyGL
function DTVar_ReceiveProxyGL(ent, name, id, val)
	GAMEMODE:EntityNetworkedVarChanged(ent, name, id, val)
	Old_DTVar_ReceiveProxyGL(ent, name, id, val)
end

function GM:EntityNetworkedVarChanged(ent, name, oldval, newval)
    if self.NetworkVarCallbacks[name] ~= nil then self.NetworkVarCallbacks[name](ent, newval) end

    if CLIENT and ent.PostNetReceive then
        ent:PostNetReceive(name, oldval, newval)
    end
end

function GM:GravGunPickupAllowed(ply, ent)
    return player_manager.RunClass(ply, "AllowPickup", ent)
end

function GM:PlayerButtonDown(ply, button)
    player_manager.RunClass(ply, "ButtonDown", button)
end

function GM:PlayerButtonUp(ply, button)
    player_manager.RunClass(ply, "ButtonUp", button)
end

function GM:PlayerCanPickupWeapon(pl, ent)
    return player_manager.RunClass(pl, "CanPickupWeapon", ent)
end

function GM:PlayerCanPickupItem(pl, item)
    return player_manager.RunClass(pl, "CanPickupItem", item)
end

function GM:KeyPress(pl, key)
    return player_manager.RunClass(pl, "KeyPress", key)
end

function GM:KeyRelease(pl, key)
    return player_manager.RunClass(pl, "KeyRelease", key)
end

function GM:PlayerPostThink(pl)
    player_manager.RunClass(pl, "PostThink")
end

function GM:CanHiddenZombieBeCreated(ply, pos, mousepos)
    if not IsValid(ply) then return end

    local tr = util.TraceLine({start = pos, endpos = pos + mousepos * (75 ^ 2), filter = player.GetAll(), mask = MASK_SOLID})
    local location = tr.HitPos

    local tr_floor = util.TraceHull({start = location + Vector(0, 0, 25), endpos = location - Vector(0, 0, 25), filter = player.GetAll(), mins = Vector(-13, -13, 0), maxs = Vector(13, 13, 72), mask = MASK_NPCSOLID})
    if tr_floor.Fraction < 0.5 then
        return false, "zombie_does_not_fit"
    end

    location = tr_floor.HitPos

    if not ply:CanAfford(GetConVar("zm_spotcreate_cost"):GetInt()) then
        return false, "not_enough_resources"
    end

    local vecHeadTarget = location
    vecHeadTarget.z = vecHeadTarget.z + 64

    for k, v in pairs(ents.FindByClass("trigger_blockspotcreate")) do
        if v.m_bActive then
            if v:IsPointInBounds(location) then
                return false, "zombie_cant_be_created"
            end
        end
    end

    for _, pl in ipairs(team.GetPlayers(TEAM_SURVIVOR)) do
        if not (pl and pl:IsValid()) then continue end

        local tr = util.TraceLine({
            start = location,
            endpos = pl:GetPos(),
            filter = pl,
            mask = MASK_OPAQUE
        })

        local visible = false
        if tr.Fraction == 1 then
            visible = true
        end

        local tr = util.TraceLine({
            start = vecHeadTarget,
            endpos = pl:EyePos(),
            filter = pl,
            mask = MASK_OPAQUE
        })
        if tr.Fraction == 1 then
            visible = true
        end

        if visible then
            return false, "human_can_see_location"
        end
    end

    return true, nil, tr
end

function GM:IsUseableEntity( ent )
	return ent and ent:IsValid() and bit.band(ent:ObjectCaps(), bit.bor(FCAP_IMPULSE_USE, FCAP_CONTINUOUS_USE, FCAP_ONOFF_USE, FCAP_DIRECTIONAL_USE)) > 0
end

local function IsBadEnt(ent)
    return not (ent:IsPlayer() or ent:IsWeapon() or ent:GetClass() == "item_zm_ammo")
end
function GM:FindUseEntity(ply, ent)
	if not ent:IsValid() then ent = ply:TraceLine(90, MASK_SOLID, IsBadEnt).Entity end

    if SERVER and ply:IsSurvivor() and ply:KeyPressed(IN_USE) then
        if gamemode.Call("IsUseableEntity", ent) then
            ply:SendLua("MySelf:EmitSound('HL2Player.Use')")
        else
            ply:SendLua("MySelf:EmitSound('HL2Player.UseDeny')")
        end
    end

	return ent
end

function DropEntityIfHeld(ent)
    if CLIENT then return end

    if ent.bHeldBy and ent.bHeldBy:IsValid() then
        ent.bHeldBy:DropObject()
    end
end

if not StartCommandTBL then
	PLAYER_RandomSeed = {}
    StartCommandTBL = true
end
function GM:StartCommand(ply, ucmd)
	rawset(PLAYER_RandomSeed, ply, ucmd:TickCount()) -- Used to sync bullets.
end

local TranslateNPC = {
    ["npc_zm_dragzombie"] = "npc_dragzombie",
    ["npc_zm_burnzombie"] = "npc_burnzombie"
}
local TranslateNextBot = {
    ["npc_zm_nextbot_zombie"] = "npc_zombie",
    ["npc_zm_nextbot_fastzombie"] = "npc_fastzombie",
    ["npc_zm_nextbot_poisonzombie"] = "npc_poisonzombie",
    ["npc_zm_nextbot_dragzombie"] = "npc_dragzombie",
    ["npc_zm_nextbot_burnzombie"] = "npc_burnzombie"
}
function GM:ApplyZombieClasses()
    local tab = self.bReplaceZombiesWithNextBots and TranslateNextBot or TranslateNPC
    for name, rep in pairs(tab) do
        local ent = scripted_ents.Get(name)
        scripted_ents.Register(ent, rep)
    end
end

local bScaledZombieCosts = false
function GM:ApplyZombieScaling()
    local numhumans = team.NumPlayers(TEAM_SURVIVOR) - 16
    if numhumans > 0 then
        for _, zombie in pairs(self:GetZombieTables()) do
            if zombie.DefaultCost == nil then
                zombie.DefaultCost = zombie.Cost
            end

            zombie.Cost = math.ceil(zombie.DefaultCost / (numhumans * 0.25))
        end

        self:RePopulateZombieMenus()

        bScaledZombieCosts = true
    elseif bScaledZombieCosts then
        for _, zombie in pairs(self:GetZombieTables()) do
            zombie.Cost = zombie.DefaultCost
        end

        self:RePopulateZombieMenus()
    end
end

function GM:RePopulateZombieMenus()
    if not CLIENT then return end

    local data = hook.Call("GetZombieMenus", self)
    for ent, menu in pairs(data) do
        menu.buttons:Clear(true)
        menu:Populate()
    end
end