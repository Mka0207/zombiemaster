resource.AddWorkshop("2330687046")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_credits.lua")
AddCSLuaFile("cl_deathnotice.lua")
AddCSLuaFile("cl_killicons.lua")
AddCSLuaFile("cl_utility.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_dermaskin.lua")
AddCSLuaFile("cl_halo.lua")
AddCSLuaFile("cl_sck.lua")

AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_zombie.lua")
AddCSLuaFile("cl_powers.lua")

AddCSLuaFile("nixthelag.lua")
AddCSLuaFile("buffthefps.lua")
AddCSLuaFile("sh_string.lua")
AddCSLuaFile("sh_math.lua")
AddCSLuaFile("sh_vector.lua")
AddCSLuaFile("sh_weapons.lua")
AddCSLuaFile("sh_players.lua")
AddCSLuaFile("sh_entites.lua")
AddCSLuaFile("sh_zombies.lua")
AddCSLuaFile("sh_npc.lua")
AddCSLuaFile("sh_animations.lua")

AddCSLuaFile("sh_sounds.lua")
AddCSLuaFile("sh_zm_globals.lua")
AddCSLuaFile("sh_utility.lua")
AddCSLuaFile("sh_zm_options.lua")

AddCSLuaFile("sh_playeroptimization.lua")

AddCSLuaFile("cl_zm_options.lua")
AddCSLuaFile("cl_targetid.lua")
AddCSLuaFile("cl_entites.lua")
AddCSLuaFile("cl_team.lua")
AddCSLuaFile("cl_collision.lua")

AddCSLuaFile("vgui/dmainhud.lua")
AddCSLuaFile("vgui/dteamheading.lua")
AddCSLuaFile("vgui/dzombiepanel.lua")
AddCSLuaFile("vgui/dpowerpanel.lua")
AddCSLuaFile("vgui/dmodelselector.lua")
AddCSLuaFile("vgui/dclickableavatar.lua")
AddCSLuaFile("vgui/dcrosshairinfo.lua")
AddCSLuaFile("vgui/dhintpanel.lua")
AddCSLuaFile("vgui/dlobby.lua")
AddCSLuaFile("vgui/dhealthhud.lua")
AddCSLuaFile("vgui/dexnotificationslist.lua")
AddCSLuaFile("vgui/dflashlighthud.lua")
AddCSLuaFile("vgui/doxygenhud.lua")
AddCSLuaFile("vgui/dreloadhud.lua")

--include("sv_math_counter.lua")
include("sv_team.lua")
include("sv_zm_options.lua")
include("sh_players.lua")
include("sv_players.lua")
include("sv_entites.lua")
include("sv_npc.lua")
include("sv_weapons.lua")
include("sv_vault.lua")
include("sv_collision.lua")
include("sv_modulewrapper.lua")
--include("sv_playerdamage.lua")
include("shared.lua")

include("modules/zombie_master_ai/sv_bot.lua")
include("modules/navmesh_check/sv_navmesh_check.lua")

include("sv_clientside_reg.lua")

DEFINE_BASECLASS("gamemode_base")

GM.DeadPlayers = {}
GM.ZombieMasterPriorities = {}

GM.Income_Time = 0

local ZEPLUGINS, _ = pcall(require, "zeplugins")
if ZEPLUGINS then
	MsgN("[ZE PLUGINS]: Loaded")
	-- FIX FilterTeam crash the server due to NULL pointer.
	-- FIX GameUI jittery movements due to lag compensation.
	-- ADD NoShake to disable env_shake.
	-- Access C++ Math counter
	-- Correct time in every Think
	-- CSViewOffset [Moved to zsutil]
	-- ResetCrouch, this is force reset crouch after unduck jump... thanks you valve bruh moment...
	-- Manual calling general Phys Simulate such as like controller for all bosses and props... not sure about players.
	-- without this module phys simulate on controller doesnt work if there is m_forcetime > 0 because one frame was behind.

	if ZEPLUGIN_DetourPhysicsHook then
		ZEPLUGIN_DetourPhysicsHook(false) -- we dont want to use lua physframe.
	end
end

local OldTriggerOutput
local OldStoreOutput
local PlayerReadyList = {}

if file.Exists(GM.FolderName.."/gamemode/maps/"..game.GetMap()..".lua", "LUA") then
    include("maps/"..game.GetMap()..".lua")
end

function BroadcastLua(str)
    net.Start("zm_sendlua")
        net.WriteString(str)
    net.Broadcast()
end

-- Many maps expect the outputs to start from 0 to the end, Garrys Mod seems to do the opposite of that
local function FireSingleOutput(output, this, activator, data, entitiesToFire)
	if output.times == 0 then return false end

	for _, ent in ipairs(entitiesToFire) do
        if output.delay == 0 then
            if IsValid(ent) then
                ent:Input(output.input, activator, this, data or output.param)
            end
        else
            timer.Simple(output.delay, function()
                if ent:IsValid() and ent:GetClass() == "physics_cannister" and output.input == "Explode" then
                    ent:Remove()
                    return
                end

                if IsValid(ent) then
                    ent:Input(output.input, activator, this, data or output.param)
                end
            end)
        end
	end

	if output.times ~= -1 then
		output.times = output.times - 1
	end

	return output.times > 0 or output.times == -1
end
local EntFireCount = {}
local function OutputQueue(name, idx, output, this, activator, data)
    if not (this and this:IsValid()) or not output or (EntFireCount[this] and EntFireCount[this] > 2) then
        EntFireCount[this] = nil
        return
    end

    local entitiesToFire = {}
    if output.entities == "!activator" then
        entitiesToFire = { activator }
    elseif output.entities == "!self" then
        entitiesToFire = { this }
    elseif output.entities == "!player" then
        entitiesToFire = player.GetAllNoCopy()
    else
        entitiesToFire = ents.FindByName( output.entities )
        if #entitiesToFire == 0 and output.entities ~= "" then
            -- Prevent infinite loops!
            EntFireCount[this] = (EntFireCount[this] or 0) + 1

            timer.Simple(0, function() OutputQueue(name, idx, output, this, activator, data) end)
            return
        end
    end

    EntFireCount[this] = nil

    if not FireSingleOutput(output, this.Entity, activator, data, entitiesToFire) then
        this.m_tOutputs[ name ][ idx ] = nil
    end
end
function TriggerOutputOverride(ent, name, activator, data)
    if string.len(data) == 0 then
        data = nil
    end

    if GAMEMODE.bUseOriginalTriggerOutput then
        OldTriggerOutput(ent, name, activator, data)
        return
    end

	if not ent.m_tOutputs then return end
	if not ent.m_tOutputs[name] then return end

	local OutputList = ent.m_tOutputs[ name ]
	for idx, output in ipairs(OutputList) do
        OutputQueue(name, idx, output, ent, activator, data)
	end
end

function GM:PreGamemodeLoaded()
    OldTriggerOutput = scripted_ents.Get("base_entity").TriggerOutput
    OldStoreOutput = scripted_ents.Get("base_entity").StoreOutput
end

function GM:InitPostEntity()
    RunConsoleCommand("mapcyclefile", "mapcycle_zombiemaster.txt")
    hook.Call("InitPostEntityMap", self)

    local ammotbl = hook.Call("GetCustomAmmo", self)
    if table.Count(ammotbl) > 0 then
        for _, ammo in pairs(ammotbl) do
            CreateConVar("zm_maxammo_"..ammo.Type, ammo.MaxCarry, FCVAR_REPLICATED, "Max "..ammo.Type.." ammo that players can hold.")
            game.AddAmmoType({name = ammo.Type, dmgtype = ammo.DmgType, tracer = ammo.TracerType, plydmg = 0, npcdmg = 0, force = 2000, maxcarry = ammo.MaxCarry})
        end
    end

    local Settings = physenv.GetPerformanceSettings()
    Settings.MaxCollisionsPerObjectPerTimestep = 10
    Settings.MaxCollisionChecksPerTimestep = 200
    Settings.MaxVelocity = 2000
    Settings.MaxAngularVelocity = 360 * 10
    Settings.LookAheadTimeObjectsVsWorld = 1
    Settings.LookAheadTimeObjectsVsObject = 0.5
    Settings.MinFrictionMass = 10
    Settings.MaxFrictionMass = 2500

    physenv.SetPerformanceSettings(Settings)
end

function GM:InitPostEntityMap()
    self:SetupAmmo()

    for _, ent in ipairs(ents.FindByClass("weapon_*")) do
        if string.sub(ent:GetClass(), 1, 9) == "weapon_zm" then
            local owner = ent:GetOwner()
            if IsValid(owner) and owner:IsPlayer() then continue end

            hook.Call("ReplaceItemWithCrate", self, ent)

            if IsValid(ent) then
                hook.Call("CreateCustomWeapons", self, ent)
            end
        elseif string.sub(ent:GetClass(), 1, 7) == "weapon_" then
            local owner = ent:GetOwner()
            if IsValid(owner) and owner:IsPlayer() then continue end

            self:ConvertWeapon(ent)
        end
    end

    for _, ent in ipairs(ents.FindByClass("item_*")) do
        if string.sub(ent:GetClass(), 1, 10) == "item_ammo_" or string.sub(ent:GetClass(), 1, 9) == "item_box_" then
            self:ConvertAmmo(ent)
        end
    end

    self.bMapWasInitilized = true
end

function GM:OnPlayerHitGround(ply, inWater, onFloater, speed)
    local groundent = ply:GetGroundEntity()
    if IsValid(groundent) then
        groundent:SetPhysicsAttacker(ply)
    end
end

function GM:AcceptInput(ent, input, activator, caller, value)
    if input == "ForceDrop" then
        DropEntityIfHeld(ent)
    end
end

function GM:EntityKeyValue(ent, key, value)
    key = string.lower(key)
    if key == "targetname" then
        ent:SetName(value)
    end

    if ent:GetClass() == "game_text" and key == "y" and value == "-1" then
        return "0.85"
    end

    if key == "crabcount" then
        return "0"
    end

    if ent:IsNPC() and key == "spawnflags" then
        local tab = self:GetZombieData(ent:GetClass())
        if tab and tab.SpawnFlags then
            return tostring(bit.bor(tonumber(value), tab.SpawnFlags))
        end
    end
end

function GM:SetupAmmo()
    local ammotbl = ents.FindByClass("item_ammo_*")
    table.Add(ammotbl, ents.FindByClass("item_box_*"))

    for _, ammo in ipairs(ammotbl) do
        if ammo:GetClass() == "item_ammo_revolver" then
            ammo:SetClassName(ammo:GetClass())
            continue
        end

        local ammotype = self.AmmoClass[ammo:GetClass()]
        if ammotype then
            local ent = ents.Create("item_zm_ammo")
            if IsValid(ent) then
                ent:SetPos(ammo:GetPos())
                ent:SetAngles(ammo:GetAngles())

                ent:SetClassName(ammo:GetClass())
                ent.Model = ammo:GetModel()
                ent.AmmoAmount = self.AmmoCache[ammotype]
                ent.AmmoType = ammotype
                ent:SetKeyValue("spawnflags", ammo:GetSpawnFlags())
                ent:Spawn()

                if not self.AmmoModels[ammo:GetClass()] then
                    self.AmmoModels[ammo:GetClass()] = ammo:GetModel()
                end

                ammo:Remove()
            end
        end
    end
end

function GM:ConvertAmmo(ammo)
    if not IsValid(ammo) then return end
    if ammo:GetClass() == "item_ammo_revolver" then return end

    local ammotype = self.AmmoClass[ammo:GetClass()]
    if ammotype then
        local ent = ents.Create("item_zm_ammo")
        if IsValid(ent) then
            hook.Call("ReplaceItemWithCrate", self, ammo, ammo:GetClass())
            if not IsValid(ammo) then ent:Remove() return end

            if IsValid(ent) then
                ent = hook.Call("CreateCustomAmmo", self, ent)
            else return end

            ent:SetPos(ammo:GetPos())
            ent:SetAngles(ammo:GetAngles())

            ent:SetClassName(ammo:GetClass())
            ent.Model = self.AmmoModels[ammo:GetClass()]
            ent.AmmoAmount = self.AmmoCache[ammotype]
            ent.AmmoType = ammotype
            ent:Spawn()

            ammo:Remove()
        end
    end
end

local WepsToConvert = {
    ["weapon_357"] = "weapon_zm_revolver",
    ["weapon_pistol"] = "weapon_zm_pistol",
    ["weapon_shotgun"] = "weapon_zm_shotgun",
    ["weapon_smg1"] = "weapon_zm_mac10",
    ["weapon_crossbow"] = "weapon_zm_rifle",
    ["weapon_grenade"] = "weapon_zm_molotov",
    ["weapon_ar2"] = "weapon_zm_mac10",
    ["weapon_rpg"] = "weapon_zm_rifle",
    ["weapon_crowbar"] = "weapon_zm_improvised",
    ["weapon_bugbait"] = "weapon_zm_molotov"
}
function GM:ConvertWeapon(wep)
    if not IsValid(wep) then return end
    if not WepsToConvert[wep:GetClass()] then return end

    local ent = ents.Create(WepsToConvert[wep:GetClass()])
    if IsValid(ent) then
        ent:SetPos(wep:GetPos())
        ent:SetAngles(wep:GetAngles())
        ent:Spawn()

        wep:Remove()
    end
end

function GM:CreateCustomWeapons(ent, bNoSpawn)
    local weptbl = hook.Call("GetCustomWeapons", self)
    if table.Count(weptbl) > 0 then
        local weptab = weptbl[ent:GetClass()]
        if weptab and math.random() < weptab.Chance then
            local wep = ents.Create(weptab.Class)
            if IsValid(wep) then
                wep:SetPos(ent:GetPos())
                wep:SetAngles(ent:GetAngles())
                if not bNoSpawn then wep:Spawn() end

                ent:Remove()

                return wep
            end
        end
    end

    return ent
end

function GM:CreateCustomAmmo(ent, bNoSpawn)
    local ammotbl = hook.Call("GetCustomAmmo", self)
    if table.Count(ammotbl) > 0 then
        local ammotab = ammotbl[ent.AmmoType]
        if ammotab and math.random() > ammotab.Chance then
            local ammoent = ents.Create(ammotab.Class)
            if IsValid(ammoent) then
                ammoent:SetPos(ent:GetPos())
                ammoent:SetAngles(ent:GetAngles())
                if not bNoSpawn then ammoent:Spawn() end

                ent:Remove()

                return ammoent
            end
        end
    end

    return ent
end

function GM:OnEntityCreated(ent)
    local this = ent
    if this:GetClass() == "npc_headcrab_poison" then
        this:Remove()
        return
    end

    timer.Simple(0, function()
        if not IsValid(this) then return end

        if IsValid(ent) and ent:GetModel() == "models/cat/cat_woodencrate_grey.mdl" then
            ent:SetModel("models/props_junk/wood_crate001a.mdl")
            ent:SetMaterial("CAT/cat_woodencrate_grey")
        end

        if this:GetMaxHealth() > 1 and this:Health() <= 0 and not this:IsPlayer() and not this:IsNPC() and not this:IsNextBot() and string.sub(this:GetClass(), 0, 5) == "func_" then
            ent:AddFlags(FL_OBJECT)
        end
    end)

    -- Prevent massive lag from vphysics objects colliding with the physics shadow of a func_brush
    if this:GetClass() == "func_brush" then
        timer.Simple(0, function()
            if not IsValid(this) then return end

            local WasNotSolid = not this:IsSolid()

            this:PhysicsInit(SOLID_VPHYSICS)
            this:MakePhysicsObjectAShadow(false, false)
            this:SetMoveType(MOVETYPE_PUSH)
            this:SetNotSolid(WasNotSolid)

            local phys = this:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableCollisions(not WasNotSolid)
                phys:EnableMotion(false)
            end
        end)
    end

    -- ZMRCHANGE: Make sure we do not create bone followers if the value isn't defined in the map data.
    -- This little fix can save hundreds of edict slots... thanks prop_dynamic ragdolls...
    if this:GetClass() == "prop_dynamic" then
        timer.Simple(0, function()
            if not IsValid(this) then return end
            this:SetSaveValue("m_bDisableBoneFollowers", true)
        end)
    end

    if (string.sub(this:GetClass(), 1, 9) == "item_ammo" or string.sub(this:GetClass(), 1, 8) == "item_box") and self.bMapWasInitilized then
        timer.Simple(0, function() self:ConvertAmmo(this) end)
    end

    if this:GetClass() == "raggib" then
        this:Extinguish()
        this:SetNoDraw(true)
        SafeRemoveEntityDelayed(this, 0)
    end

    if this:IsNPC() or this:IsNextBot() then
        local entclass = this:GetClass()
        if self:GetZombieData(entclass) ~= nil then
            self.iZombieList[this:EntIndex()] = this
        end

        timer.Simple(0, function()
            if not IsValid(this) then return end

            if not this.SpawnedFromNode then
                this:SetEngineNPC(not this:IsScripted())

                self:CallZombieFunction(this, "OnSpawned")
                self:CallZombieFunction(this, "SetupModel")
                self:CallZombieFunction(this, "SetupCapabilities")
            end

            if this.GetNumBodyGroups and this.SetBodyGroup then
                for k = 0, this:GetNumBodyGroups() - 1 do
                    this:SetBodyGroup(k, 0)
                end
            end

            this:SetShouldServerRagdoll(false)
        end)

        for index, npc in pairs(self.iZombieList) do
            hook.Call("AddNPCFriends", self, npc, this)
        end
    end
end

function GM:EntityRemoved(ent)
    if ent:IsNPC() or ent:IsNextBot() then
        table.RemoveByValue(self.iZombieList, ent)
    end
end

function GM:ReplaceItemWithCrate(ent, class)
    local playercount = player.GetCount()
    if playercount <= 16 or self.bDisableItemCrateReplacment then return end

    local chance = math.min(playercount / (playercount * 10), 1)
    if math.random() <= chance then
        for _, box in ipairs(ents.FindInSphere(ent:WorldSpaceCenter(), 32)) do
            if box and box:IsValid() and (box:GetClass() == "item_item_crate" or box:IsPlayer() or box:GetClass() == "info_player_deathmatch") then return end
        end

        local itemcount = math.ceil(playercount * (ent:IsWeapon() and 0.15 or 0.25))
        if itemcount > 1 then
            local crate = ents.Create("item_item_crate")
            if IsValid(crate) then
                crate:SetPos(ent:GetPos())
                crate:SetAngles(ent:GetAngles())
                crate:SetKeyValue("itemclass", class and tostring(class) or ent:GetClass())
                crate:SetKeyValue("itemcount", tostring(itemcount))
                crate:Spawn()

                ent:Remove()
            end
        end
    end
end

function GM:AddNPCFriends(npc, ent)
    if not (npc and npc:IsValid()) then return end

    local zombie = self:GetZombieData(npc:GetClass())
    if not zombie or not zombie.Friends then return end

    local zombiefriends = {}
    for _, fri in pairs(zombie.Friends) do
        if fri ~= npc:GetClass() then
            local fritab = ents.FindByClass(fri)
            if fritab then
                table.Merge(zombiefriends, fritab)
            end
        end
    end

    for _, zom in pairs(zombiefriends) do
        npc:AddEntityRelationship(zom, D_LI, 99)
    end
end

function GM:PostGamemodeLoaded()
    self:SetRoundStartTime(5)
    self:SetRoundActive(false)

    util.AddNetworkString("PlayerKilledByNPC")

    util.AddNetworkString("zm_trigger")
    util.AddNetworkString("zm_infostrings")
    util.AddNetworkString("zm_queue")
    util.AddNetworkString("zm_remove_queue")
    util.AddNetworkString("zm_sendcurrentgroups")
    util.AddNetworkString("zm_sendselectedgroup")
    util.AddNetworkString("zm_spawnclientragdoll")
    util.AddNetworkString("zm_forcecustomragdoll")
    util.AddNetworkString("zm_coloredprintmessage")
    util.AddNetworkString("zm_place_physexplode")
    util.AddNetworkString("zm_net_power_killzombies")
    util.AddNetworkString("zm_place_zombiespot")
    util.AddNetworkString("zm_net_dropammo")
    util.AddNetworkString("zm_net_dropweapon")
    util.AddNetworkString("zm_boxselect")
    util.AddNetworkString("zm_selectnpc")
    util.AddNetworkString("zm_command_npcgo")
    util.AddNetworkString("zm_npc_target_object")
    util.AddNetworkString("zm_net_deselect")
    util.AddNetworkString("zm_clicktrap")
    util.AddNetworkString("zm_selectall_zombies")
    util.AddNetworkString("zm_placetrigger")
    util.AddNetworkString("zm_spawnzombie")
    util.AddNetworkString("zm_rqueue")
    util.AddNetworkString("zm_placerally")
    util.AddNetworkString("zm_creategroup")
    util.AddNetworkString("zm_setselectedgroup")
    util.AddNetworkString("zm_selectgroup")
    util.AddNetworkString("zm_switch_to_defense")
    util.AddNetworkString("zm_switch_to_offense")
    util.AddNetworkString("zm_player_ready")
    util.AddNetworkString("zm_create_ambush_point")
    util.AddNetworkString("zm_cling_ceiling")
    util.AddNetworkString("zm_sendlua")
    util.AddNetworkString("zm_playeready")
    util.AddNetworkString("zm_updateclientreadytable")
    util.AddNetworkString("zm_updateragdollpos")
    util.AddNetworkString("zm_servertravel")
    util.AddNetworkString("zm_navloaded")
    util.AddNetworkString("zm_mousemove")

    util.AddNetworkString("zs_playtaunt")

    game.ConsoleCommand("fire_dmgscale 1\nmp_falldamage 1\nsv_gravity 600\n")

    local mapinfo = "maps/"..game.GetMap()..".txt"
    if file.Exists(mapinfo, "GAME") then
        self.MapInfo = file.Read(mapinfo, "GAME")
    else
        self.MapInfo = "No objectives found!"
    end

    if not file.Exists("zm_info", "DATA") then
        file.CreateDir("zm_info")
    end

    if file.Exists("zm_info/help_menu.html", "DATA") then
        self.HelpInfo = file.Read("zm_info/help_menu.html", "DATA")
    else
        self.HelpInfo = "No Info"
    end
end

function GM:OnReloaded()
    if team.NumPlayers(TEAM_ZOMBIEMASTER) > 0 then
        timer.Simple(0.25, function()
            self.Income_Time = 1
            self:SetRoundActive(true)
            BroadcastLua([[
                if IsValid(GAMEMODE.PlayerLobby) then
                    GAMEMODE.PlayerLobby:Close()
                end
            ]])
        end)
    end

    hook.Call("BuildZombieDataTable", self)
    hook.Call("SetupNetworkingCallbacks", self)
    hook.Call("SetupCustomItems", self)
end

function GM:PlayerSpawnAsSpectator(pl)
    pl:StripWeapons()
    pl:SetClass("player_spectator")
    pl:ChangeTeam(TEAM_SPECTATOR)
    pl:SendLua("hook.Call('RemoveZMPanels', GAMEMODE)")

    player_manager.RunClass(pl, "Spawn")
end

function GM:PlayerDeathThink(pl)
    if player_manager.RunClass(pl, "DeathThink") then return false end
end

function GM:PlayerShouldTaunt(ply, act)
    return player_manager.RunClass(ply, "ShouldTaunt", act)
end

function GM:CanPlayerSuicide(ply)
    return player_manager.RunClass(ply, "CanSuicide")
end

function GM:PlayerDeathSound()
    return true
end

function GM:PlayerInitialSpawn(pl)
    pl.FreshSpawn = true
    pl:ChangeTeam(TEAM_SPECTATOR)
    pl:AddEFlags(EFL_IN_SKYBOX)
    pl:KillSilent()
    pl:Spectate(OBS_MODE_ROAMING)
    pl:CrosshairDisable()
    pl:SetFlashlightBattery(100)
    pl.AllowKeyPress = true
    self:LoadVault(pl)

    if (self:GetRoundActive() and team.NumPlayers(TEAM_SURVIVOR) == 0 and team.NumPlayers(TEAM_ZOMBIEMASTER) >= 1) and not NotifiedRestart then
        PrintTranslatedMessage(HUD_PRINTTALK, "round_restarting")
        timer.Simple(4, function() hook.Call("EndRound", self) end)
        NotifiedRestart = true
    end

    if pl:IsBot() then
        hook.Call("InitClient", self, pl)
    end

    pl.NextPainSound = 0

    if not zm_start_round and not self:GetRoundActive() then
        zm_start_round = true
    end

    net.Start("zm_infostrings")
        net.WriteString(self.MapInfo)
        net.WriteString(self.HelpInfo)
    net.Send(pl)

    net.Start("zm_navloaded")
        net.WriteBool(self.bReplaceZombiesWithNextBots)
    net.Send(pl)

    if not GetConVar("zm_debug_nolobby"):GetBool() and not self:GetRoundActive() then
        net.Start("zm_updateclientreadytable")
            net.WriteBool(true)
            net.WriteTable(PlayerReadyList)
        net.Send(pl)
    end
end

function GM:PlayerNoClip(ply, desiredState)
    return ply:IsAdmin() and ply:Team() ~= TEAM_ZOMBIEMASTER
end

function GM:OnNPCKilled(ent, attacker, inflictor)
    self:CallZombieFunction(ent, "OnKilled", attacker, inflictor)
end

function GM:ScaleNPCDamage(npc, hitgroup, dmginfo)
    self:CallZombieFunction(npc, "OnScaledDamage", hitgroup, dmginfo)
end

function GM:PlayerDeath(ply, inflictor, attacker)
    player_manager.RunClass(ply, "PreDeath", inflictor, attacker)
end

function GM:DoPlayerDeath(ply, attacker, dmginfo)
    player_manager.RunClass(ply, "OnDeath", attacker, dmginfo)
end

function GM:PostPlayerDeath(ply)
    player_manager.RunClass(ply, "PostOnDeath")
end

function GM:PlayerHurt(victim, attacker, healthremaining, damage)
    player_manager.RunClass(victim, "OnHurt", attacker, healthremaining, damage)
end

function GM:PostCleanupMap()
    hook.Call("InitPostEntityMap", self)
end

function GM:PlayerSay(sender, text, teamChat)
    if string.lower(text) == "!roundsleft" then
        local roundsleft = (GetConVar("zm_roundlimit"):GetInt() - self:GetRoundsPlayed()) + 1
        local roundtext = Either(roundsleft == 1, "round", "rounds")
        PrintMessage(HUD_PRINTTALK, "There is currently "..roundsleft.." "..roundtext.." left.")
    end

    return BaseClass.PlayerSay(self, sender, text, teamChat)
end

function GM:OnPlayerClassChanged(pl, class)
end
function GM:OnPlayerChangedTeam() end -- disable message Bot01 joined Spectators

function GM:PlayerChangedTeam(ply, oldTeam, newTeam)
    if newTeam == TEAM_ZOMBIEMASTER then
        self.pZombieMaster = ply
        SetGlobalEntity("zm_zombiemaster_player", ply)
        timer.Simple(0.1, function() ply:SendLua("GAMEMODE:CreateVGUI()") end)
    elseif newTeam == TEAM_SURVIVOR then
        ply:SetCustomGroupAndFlags(ZS_COLLISIONGROUP_HUMAN, ZS_COLLISIONFLAGS_HUMAN)
    end

    ply:Flashlight(false)
    ply:SendLua("if MySelf.ClientSetFlashlight then MySelf:ClientSetFlashlight(false) end")

    if oldTeam == TEAM_SURVIVOR then
        self:ApplyZombieScaling()
    end
end

-- You can override or hook and return false in case you have your own map change system.
local function RealMap(map)
    return string.match(map, "(.+)%.bsp")
end
function GM:LoadNextMap()
    -- Just in case.
    timer.Simple(5, game.LoadNextMap)
    timer.Simple(10, function() RunConsoleCommand("changelevel", game.GetMap()) end)

    if file.Exists(GetConVarString("mapcyclefile"), "GAME") then
        game.LoadNextMap()
    else
        local maps = file.Find("maps/zm_*.bsp", "GAME")
        table.sort(maps)
        if #maps > 0 then
            local currentmap = game.GetMap()
            for i, map in ipairs(maps) do
                local lowermap = string.lower(map)
                local realmap = RealMap(lowermap)
                if realmap == currentmap then
                    if maps[i + 1] then
                        local nextmap = RealMap(maps[i + 1])
                        if nextmap then
                            RunConsoleCommand("changelevel", nextmap)
                        end
                    else
                        local nextmap = RealMap(maps[1])
                        if nextmap then
                            RunConsoleCommand("changelevel", nextmap)
                        end
                    end

                    break
                end
            end
        end
    end
end

function GM:FinishingRound(won, rounds)
    if self:GetRoundsPlayed() > rounds then
        PrintTranslatedMessage(HUD_PRINTTALK, "map_changing")
    else
        PrintTranslatedMessage(HUD_PRINTTALK, "round_restarting")
    end
end

function GM:CreateGibs(pos, headoffset)
    headoffset = headoffset or 0

    local headpos = Vector(pos.x, pos.y, pos.z + headoffset)
    for i = 1, 2 do
        local ent = ents.Create("prop_playergib")
        if ent:IsValid() then
            ent:SetPos(headpos + VectorRand() * 5)
            ent:SetAngles(VectorRand():Angle())
            ent:SetGibType(i)
            ent:Spawn()
        end
    end

    for i=1, 4 do
        local ent = ents.Create("prop_playergib")
        if ent:IsValid() then
            ent:SetPos(pos + VectorRand() * 12)
            ent:SetAngles(VectorRand():Angle())
            ent:SetGibType(math.random(3, #self.HumanGibs))
            ent:Spawn()
        end
    end
end

function GM:TeamVictorious(won, message, submit)
    if self:GetPreRoundEnd() then return end

    self:SetPreRoundEnd(true)

    local winscore = Either(won, HUMAN_WIN_SCORE, HUMAN_LOSS_SCORE)
    local winningteam = Either(won, TEAM_SURVIVOR, TEAM_ZOMBIEMASTER)
    for _, ply in pairs(team.GetPlayers(winningteam)) do
        ply:AddFrags(winscore)
    end

    hook.Call("IncrementRoundCount", self)

    local rounds = GetConVar("zm_roundlimit"):GetInt()
    if self:GetRoundsPlayed() > rounds then
        timer.Simple(3, function() hook.Call("LoadNextMap", self) end)
    else
        timer.Simple(4, function() hook.Call("EndRound", self) end)
    end

    for _, ply in ipairs(player.GetAllNoCopy()) do
        if translate.ClientGet(ply, message) ~= "@"..message.."@" then
            ply:PrintTranslatedMessage(HUD_PRINTTALK, message)
        else
            ply:PrintMessage(HUD_PRINTTALK, message)
        end
    end

    hook.Call("FinishingRound", self, won, rounds)
end

function GM:EndRound()
    if player.GetCount() == 0 and GetConVar("zm_debug_nozombiemaster"):GetBool() then return end
    if self:GetRoundsPlayed() > GetConVar("zm_roundlimit"):GetInt() or self:GetRoundEnd() then return end

    for _, pl in ipairs(player.GetAllNoCopy()) do
        pl.m_TriggerCount = 0
        pl.m_SpawnCount = 0
        pl:StripWeapons()
        pl:StripAmmo()
        pl:Spectate(OBS_MODE_ROAMING)
        pl:SetZMPoints(0)
        pl:Flashlight(false)

        hook.Call("PlayerSpawnAsSpectator", self, pl)
    end

    BroadcastLua("hook.Call('RestartRound', GAMEMODE)")

    table.Empty(self.groups)
    table.Empty(self.DeadPlayers)
    table.Empty(self.iZombieList)

    self.GameStartTime = nil
    self.currentmaxgroup = 0
    self.selectedgroup = 0
    self.Income_Time = 0
    self.pZombieMaster = nil
    self:SetCurZombiePop(0)
    NotifiedRestart = false

    self:SetRoundActive(false)
    self:SetRoundEnd(true)
    self:SaveAllVaults()

    timer.Simple(1, function()
        self.bZombieMasterSelected = false

        self:SetPreRoundEnd(false)
        self:SetRoundEnd(false)

        hook.Call("SetupZombieMasterVolunteers", self)
        for _, ent in pairs(ents.FindByClass("info_loadout")) do
            ent:Distribute()
        end
    end)
end

function GM:IncrementRoundCount()
    self:SetRoundsPlayed(self:GetRoundsPlayed() + 1)
end

function GM:SetupPlayer(ply)
    ply:Freeze(false)
    ply:SendLua([[
        gui.EnableScreenClicker(false, true)
        if IsValid(GAMEMODE.PreferredMenu) then
            GAMEMODE.PreferredMenu:Close()
        end
        MySelf:ScreenFade(SCREENFADE.IN, Color( 255, 255, 255, 255 ), 1.25, 0)
        MySelf:EmitSound("ambient/energy/whiteflash.wav", 75, math.random(105, 110))
    ]])

    if ply:GetInfoNum("zm_preference", 0) == 2 or ply:Team() == TEAM_ZOMBIEMASTER then return end

    if ply.FreshSpawn and self.MapInfo ~= "No objectives found!" then
        self:ShowHelp(ply)
    end
    ply.FreshSpawn = false

    ply:ChangeTeam(TEAM_SURVIVOR)
    ply:SetClass("player_survivor")

    ply:UnSpectate()
    ply:Spawn()

    ply:SprintDisable()
    if ply:KeyDown(IN_WALK) then
        ply:ConCommand("-walk")
    end

    ply:ResetHull()
    ply:SetCanWalk(false)
    ply:SetCanZoom(false)
end

function GM:InitClient(pl)
    if not pl:IsValid() then return end

    if not self:GetRoundActive() then
        pl:Freeze(true)
    end

    if self:GetReadyCount() == -1 and (player.GetCount() > 1 or GetConVar("zm_debug_nolobby"):GetBool()) then
        self:SetReadyCount(CurTime() + (GetConVar("zm_debug_nolobby"):GetBool() and 5 or GetConVar("zm_readytimerlength"):GetInt()))
    end

    if pl:GetInfoNum("zm_nopreferredmenu", 0) <= 0 then
        pl:SendLua("GAMEMODE:MakePreferredMenu()")
    end

    if self.RoundStarted and self.RoundStarted ~= 0 and self:GetRoundActive() then
        if pl.FreshSpawn and self.RoundStarted + GetConVar("zm_postroundstarttimer"):GetInt() >= CurTime() and not self.DeadPlayers[pl:SteamID()] then
            hook.Call("SetupPlayer", self, pl)

            local randply
            local maxs, mins
            local pos, plpos
            local plang
            local allhumans = team.GetPlayers(TEAM_SURVIVOR)
            local maxcount = #allhumans
            local count = 0
            repeat
                if count >= maxcount then break end
                count = count + 1

                repeat
                    randply = allhumans[math.random(#allhumans)]
                until IsValid(randply)

                if GetConVar("zm_disableplayercollision"):GetBool() then
                    pos = randply:GetPos()
                else
                    mins, maxs = randply:GetHull()

                    plpos = randply:WorldSpaceCenter()
                    plang = randply:GetAngles()

                    for i=0, 3 do
                        local tr = util.TraceHull( {
                            start = plpos,
                            endpos = plpos + (i == 0 and plang:Forward() or i == 1 and -plang:Forward() or i == 2 and plang:Right() or -plang:Right()),
                            filter = randply,
                            mins = bottom,
                            maxs = top
                        } )

                        if tr.Fraction < 1 then continue end

                        pos = tr.HitPos
                        break
                    end
                end
            until util.IsInWorld(pos)

            if pos == nil then
                local spawnpoint = hook.Call("PlayerSelectSpawn", self, pl)
                if IsValid(spawnpoint) then
                    pos = spawnpoint:GetPos()
                end
            end

            pl:SetPos(pos)

            --[[local pZM = self:FindZM()
            if IsValid(pZM) then
                hook.Call("IncreaseResources", self, pZM, true)
            end--]]
        end
    else
        PlayerReadyList[pl] = pl:IsBot()

        if not GetConVar("zm_debug_nolobby"):GetBool() then
            net.Start("zm_updateclientreadytable")
                net.WriteBool(false)
                net.WriteEntity(pl)
                net.WriteBool(PlayerReadyList[pl])
            net.Broadcast()

            self:CheckPlayersReady()
        end
    end

    hook.Call("InitPostClient", self, pl)
end

function GM:InitPostClient(pl)
end

function GM:CheckPlayersReady()
    if player.GetCount() > 1 then
        local bNotReady = false
        for pl, b in pairs(PlayerReadyList) do
            if not b then bNotReady = true break end
        end

        if not bNotReady then
            if (self:GetReadyCount() - CurTime()) > 5 then
                self:SetReadyCount(CurTime() + 5)
            end
            self:SetGameStarting(true)
        end
    end
end

function GM:EntityTakeDamage(ent, dmginfo)
    local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
    local damage = dmginfo:GetDamage()

    if ent:IsPlayerHolding() then
        dmginfo:SetDamageForce(vector_origin)
    end

    if (ent:GetInternalVariable("m_explodeDamage") or 0) > 0 or (ent:GetInternalVariable("m_explodeRadius") or 0) > 0 then
        if attacker and attacker:IsPlayer() and ent:IsPlayerHolding() then
            dmginfo:SetDamage(0)
            dmginfo:ScaleDamage(0)
            return true
        end

        if ent:IsOnFire() then
            dmginfo:ScaleDamage(2.0)
        end
    end

    if attacker:IsNPC() or attacker:IsNextBot() then
        self:CallZombieFunction(attacker, "OnDamagedEnt", ent, dmginfo)
    elseif inflictor:IsNPC() or inflictor:IsNextBot() then
        self:CallZombieFunction(inflictor, "OnDamagedEnt", ent, dmginfo)
    end

    if ent:IsNPC() or ent:IsNextBot() then
        if self:CallZombieFunction(ent, "OnTakeDamage", attacker, inflictor, dmginfo) then return true end
    end

    if ent:IsPlayer() then
        if player_manager.RunClass(ent, "OnTakeDamage", attacker, dmginfo) then return true end
    end

    local is_prop = string.sub(ent:GetClass(), 1, 12) == "prop_physics"
    if (attacker:IsNPC() or attacker:IsNextBot()) and is_prop then
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            if phys:IsMotionEnabled() then
                ent:SetPhysicsAttacker(attacker)
            end
        end
    end

    -- We need to stop explosive chains team killing.
    if inflictor:IsValid() then
        local dmgtype = dmginfo:GetDamageType()
        if dmgtype == DMG_BLAST or dmgtype == DMG_BURN or dmgtype == DMG_SLOWBURN then
            if ent:IsPlayer() then
                if inflictor.LastExplosionTeam == ent:Team() and inflictor.LastExplosionAttacker ~= ent and inflictor.LastExplosionTime and CurTime() < inflictor.LastExplosionTime + 10 then -- Player damaged by physics object explosion / fire.
                    dmginfo:SetDamage(0)
                    dmginfo:ScaleDamage(0)
                    return true
                end
            elseif inflictor ~= ent and is_prop and string.sub(inflictor:GetClass(), 1, 12) == "prop_physics" then -- Physics object damaged by physics object explosion / fire.
                ent.LastExplosionAttacker = inflictor.LastExplosionAttacker
                ent.LastExplosionTeam = inflictor.LastExplosionTeam
                ent.LastExplosionTime = CurTime()

                ent:SetPhysicsAttacker(ent.LastExplosionAttacker)
            end
        elseif inflictor:IsPlayer() and is_prop then -- Physics object damaged by player.
            ent.LastExplosionAttacker = inflictor
            ent.LastExplosionTeam = inflictor:Team()
            ent.LastExplosionTime = CurTime()

            ent:SetPhysicsAttacker(inflictor)
        end
    end

	if ent:GetMaxHealth() > 1 and ent:Health() <= 0 and not ent:IsPlayer() and not ent:IsNPC() and not ent:IsNextBot() then
        ent:Fire("break")
        SafeRemoveEntityDelayed(ent, 0)
    end
end

function GM:PostEntityTakeDamage(ent, dmginfo, took)
    local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()

    if ent:IsNPC() or ent:IsNextBot() then
        if self:CallZombieFunction(ent, "PostOnTakeDamage", attacker, inflictor, dmginfo, took) then return true end
    end

    if ent:IsPlayer() then
        if player_manager.RunClass(ent, "PostOnTakeDamage", attacker, dmginfo, took) then return true end
    end
end

function GM:SetRoundStartTime(time)
    self.RoundStartTime = time
end

function GM:GetRoundStartTime()
    return self.RoundStartTime or 2
end

function GM:Tick()
    for index, npc in pairs(self.iZombieList) do
        self:CallZombieFunction(npc, "Think")
    end
end

function GM:CanInactivityPunish(pPlayer)
    if pPlayer:IsBot() then
        return false
    end

    if pPlayer:IsZM() and GetConVar("zm_sv_antiafk_replacezm"):GetBool() then
        return true
    end

    local punish = GetConVar("zm_sv_antiafk_punish"):GetInt()
    if punish == AFK_PUNISH_SPECTATE then
        if pPlayer:IsSpectator() then
            return false
        end
    elseif punish == AFK_PUNISH_NOTHING then
        return false
    end

    return true
end

function GM:PunishInactivity(pPlayer)
    if team.NumPlayers(TEAM_SURVIVOR) <= 1 and team.NumPlayers(TEAM_SPECTATOR) == 0 then
        self:SetRoundActive(false)
        hook.Call("TeamVictorious", self, true, "zombiemaster_afk", true)
        return
    end

    if GetConVar("zm_sv_antiafk_replacezm"):GetBool() and pPlayer:IsZM() and not self:GetRoundEnd() and team.NumPlayers(TEAM_ZOMBIEMASTER) <= 1 then
        hook.Call("ReplaceZM", self, pPlayer)
    end

    local punish = GetConVar("zm_sv_antiafk_punish"):GetInt()
    if punish == AFK_PUNISH_SPECTATE then
        if not pPlayer:IsSpectator() then
            pPlayer:KillSilent()
            hook.Call("PlayerSpawnAsSpectator", self, pPlayer)
        end
    elseif punish == AFK_PUNISH_KICK then
        pPlayer:Kick("AFK")
    end
end

function GM:ReplaceZM(pZM)
    local pChoice = NULL

    local vFirstChoice = {}
    local vOther = {}

    for _, pPlayer in ipairs(player.GetAllNoCopy()) do
        if pPlayer == pZM or pPlayer:IsZM() then continue end
        if pPlayer:GetInfoNum("zm_preference", 0) == 2 then continue end

        if pPlayer:IsSpectator() or not pPlayer:Alive() then
            table.insert(vFirstChoice, pPlayer)
        end

        table.insert(vOther, pPlayer)
    end

    if #vFirstChoice > 0 then
        pChoice = vFirstChoice[math.random(#vFirstChoice)]
    elseif #vOther > 0 then
        pChoice = vOther[math.random(#vFirstChoice)]
    end

    if pChoice:IsValid() then
        hook.Call("SetPlayerToZombieMaster", self, pChoice, true)
    end

    pZM:KillSilent()
    hook.Call("PlayerSpawnAsSpectator", self, pZM)

    return pChoice:IsValid()
end

local NextTick = 0
function GM:Think()
    local time = CurTime()

    local players = player.GetAllNoCopy()
    for i= 1, #players do
        local ply = players[i]
        player_manager.RunClass(ply, "Think")
    end

    if NextTick <= time then
        NextTick = time + 1

        if not GetConVar("zm_disableplayercollision"):GetBool() then
            local playercount = player.GetCount()
            if playercount > 16 then
                for i= 1, #players do
                    local ply = players[i]
                    if ply:GetNoCollideWithTeammates() or not ply:IsSurvivor() then continue end

                    ply:SetNoCollideWithTeammates(true)
                    ply:SetCustomCollisionCheck(true)
                    ply:SetAvoidPlayers(false)
                    ply:CollisionRulesChanged()
                end

                if not self.SetNoCollidePlayers then self.SetNoCollidePlayers = true end
            elseif self.SetNoCollidePlayers then
                for i= 1, #players do
                    local ply = players[i]
                    if not ply:GetNoCollideWithTeammates() or not ply:IsSurvivor() then continue end

                    ply:SetNoCollideWithTeammates(false)
                    ply:SetCustomCollisionCheck(false)
                    ply:SetAvoidPlayers(true)
                end

                if self.SetNoCollidePlayers then self.SetNoCollidePlayers = false end
            end
        end

        if self:GetReadyCount() ~= -1 and CurTime() >= self:GetReadyCount() and not self:GetRoundActive() then
            hook.Call("SetupZombieMasterVolunteers", self)
            for _, ent in pairs(ents.FindByClass("info_loadout")) do
                ent:Distribute()
            end
        end
    end
end

function GM:ShowHelp(pl)
    pl:SendLua("GAMEMODE:ShowHelp()")
end

function GM:ShowTeam(pl)
    pl:SendLua("GAMEMODE:ShowOptions()")
end

function GM:ShowSpare1(pl)
    pl:SendLua("MakepOptions()")
end

function GM:PlayerDisconnected(ply)
    if self:GetRoundActive() then
        if ply:IsZM() and #team.GetPlayers(TEAM_ZOMBIEMASTER) <= 0 then
            self:SetRoundActive(false)
            hook.Call("TeamVictorious", self, true, "zombiemaster_left", true)
        elseif ply:IsSurvivor() and team.NumPlayers(TEAM_SURVIVOR) <= 0 then
            self:SetRoundActive(false)
            hook.Call("TeamVictorious", self, false, "all_humans_left", true)
        end
    end
    self:SaveVault(ply)

    self.DeadPlayers[ply:SteamID()] = true
end

function GM:IsSpawnpointSuitable(pl, spawnpointent, bMakeSuitable)
    local Pos = spawnpointent:GetPos()
    local Ents = ents.FindInBox(Pos + Vector(-16, -16, 0), Pos + Vector(16, 16, 64))

    if pl:Team() == TEAM_SPECTATOR then return true end

    local Blockers = 0
    for k, v in pairs( Ents ) do
        if IsValid(v) and v ~= pl and v:GetClass() == "player" and v:Alive() then
            Blockers = Blockers + 1
        end
    end

    if bMakeSuitable then return true end
    if Blockers > 0 then return false end

    return true
end

function GM:SetupZombieMasterVolunteers(bSkipToSelection)
    if (self:GetRoundsPlayed() > GetConVar("zm_roundlimit"):GetInt()) or self:GetRoundEnd() then return end

    if team.NumPlayers(TEAM_ZOMBIEMASTER) == 0 then
        if not GetConVar("zm_debug_nozombiemaster"):GetBool() then

			local extra_zm_count = math.floor( #player.GetAll() / math.max( GetConVar("zm_multiple_zms_per_players"):GetInt(), 1 ) )

			if self.ForceSingleZM then
				extra_zm_count = 0
			end
			
			print( "Extra Zombie Masters needed: "..extra_zm_count )

			hook.Call("SetPlayerToZombieMaster", self, hook.Call("GetZombieMasterVolunteer", self))

			for i=1, extra_zm_count do
				hook.Call("SetPlayerToZombieMaster", self, hook.Call("GetZombieMasterVolunteer", self, true), true)
			end

            timer.Simple(1, function()
                if self:GetRoundActive() then
                    hook.Call("SetupZombieMasterVolunteers", self, true)
                end
            end)
        else
            self:SetRoundActive(true)
            BroadcastLua([[
                if IsValid(GAMEMODE.PlayerLobby) then
                    GAMEMODE.PlayerLobby:Close()
                end
            ]])
        end
    end

    if not bSkipToSelection then
        self.RoundStarted = CurTime()

        game.CleanUpMap(true, self.CleanupFilterServer)
        BroadcastLua("game.CleanUpMap(false, GAMEMODE.CleanupFilterClient)")

        for _, ply in ipairs(team.GetPlayers(TEAM_SPECTATOR)) do
            hook.Call("SetupPlayer", self, ply)
        end
    end
end

function GM:SetPlayerToZombieMaster(pl, bForce)
    if team.NumPlayers(TEAM_ZOMBIEMASTER) >= 1 and not bForce then return end

    if not IsValid(pl) then
        --hook.Call("SetupZombieMasterVolunteers", self, true) FIX ME: infinite loop
        return
    end

    pl:KillSilent()
    pl:SetFrags(0)
    pl:SetDeaths(0)
    pl:Freeze(false)
    pl:ChangeTeam(TEAM_ZOMBIEMASTER)
    pl:SetClass("player_zombiemaster")
    pl:Spawn()

    for _, pPlayer in ipairs(player.GetAllNoCopy()) do
        if pPlayer ~= pl then
            self.ZombieMasterPriorities[pPlayer] = (self.ZombieMasterPriorities[pPlayer] or 0) + 10
        end
    end

    self.ZombieMasterPriorities[pl] = 0

    PrintTranslatedMessage(HUD_PRINTTALK, "x_has_become_the_zombiemaster", pl:Name())

    pl:SetZMPoints(GetConVar("zm_initial_resources"):GetInt())
    --hook.Call("IncreaseResources", self, pl)

    self.Income_Time = CurTime() + GetConVar("zm_incometime"):GetInt()

    self:SetRoundActive(true)
    BroadcastLua([[
        if IsValid(GAMEMODE.PlayerLobby) then
            GAMEMODE.PlayerLobby:Close()
        end
    ]])

    if not self.GameStartTime then
        self.GameStartTime = CurTime()
    end
end

function GM:GetZombieMasterVolunteer( bForce )
    if IsValid(self:FindZM()) and not bForce then return self:FindZM() end

    local iHighest = -1
    for _, pl in ipairs(player.GetAllNoCopy()) do
        if pl:GetInfoNum("zm_preference", 0) == 2 then continue end

        local iPriority = self.ZombieMasterPriorities[pl]
        if iPriority and iPriority > iHighest and pl:GetInfoNum("zm_preference", 0) == 1 then
            iHighest = iPriority
        end
    end

    local ZMList = {}
    for _, pl in ipairs(player.GetAllNoCopy()) do
        if pl:GetInfoNum("zm_preference", 0) == 2 then continue end

        local iPriority = self.ZombieMasterPriorities[pl]
        if iPriority and iPriority == iHighest and pl:GetInfoNum("zm_preference", 0) == 1 then
            ZMList[#ZMList + 1] = pl
        end
    end

    local pl = nil
    if #ZMList > 0 then
        pl = ZMList[math.random(#ZMList)]
        if not (pl and pl:IsValid()) then
            local players = player.GetAllNoCopy()
            pl = players[math.random(#players)]
        end
    else
        local players = player.GetAllNoCopy()
        pl = players[math.random(#players)]
    end

    if not IsValid(pl) then
        pl = player.GetAll()[math.random(player.GetCount())]
    end

    return pl
end

function GM:AllowPlayerPickup(pl, ent)
    if ent:GetClass() == "item_zm_ammo" then
        if hook.Call("PlayerCanPickupItem", self, pl, ent) then
            ent:Touch(pl)
        else
            pl:PickupObject(ent)
        end

        return false
    end

    if ent:IsPlayerHolding() and pl == ent.bHeldBy then
        pl:DropObject()
        return false
    end

    if player_manager.RunClass(pl, "AllowPickup", ent) then
        pl:PickupObject(ent)
        return false
    end

    return false
end

function GM:PlayerCanHearPlayersVoice(listener, talker)
    return true, false
end

function GM:PlayerUse(pl, ent)
    if not pl:Alive() or pl:IsZM() or pl:IsSpectator() then return false end

    local entclass = ent:GetClass()
    if entclass == "prop_door_rotating" then
        if CurTime() < (ent.m_AntiDoorSpam or 0) then
            return false
        end
        ent.m_AntiDoorSpam = CurTime() + 0.85
    end

    return true
end

function GM:PlayerSwitchFlashlight(pl, newstate)
	if pl:IsSurvivor() and pl:Alive() and (pl.LastFlashLightToggle or 0) < RealTime() then
		pl.LastFlashLightToggle = RealTime() + 0.25
		pl:ToggleFlashlight()
	end

	return false
end

function GM:SetCurZombiePop(amount)
    if amount < 0 then amount = 0 end
    SetGlobalInt("m_iZombiePopCount", amount)
end

function GM:SetRoundActive(active)
    SetGlobalBool("zm_round_active", active)
end

function GM:SetPreRoundEnd(active)
    SetGlobalBool("zm_preround_ended", active)
end

function GM:SetRoundEnd(active)
    SetGlobalBool("zm_round_ended", active)
end

function GM:SetRoundsPlayed(rounds)
    SetGlobalInt("zm_rounds_played", rounds)
end

function GM:SetReadyCount(time)
    SetGlobalInt("zm_ready_counter", time)
end

function GM:SetGameStarting(b)
    SetGlobalBool("zm_game_ready", b)
end

function GM:AddCurZombiePop(amount)
    self:SetCurZombiePop(self:GetCurZombiePop() + amount)
end

function GM:TakeCurZombiePop(amount)
    self:SetCurZombiePop(self:GetCurZombiePop() - amount)
end

function GM:SpawnZombie(pZM, entname, origin, angles, cost, bHidden)
    local tab = self:GetZombieData(entname)
    if not tab then return NULL end

    local popcost = tab.PopCost
    if IsValid(pZM) and (self:GetCurZombiePop() + popcost) > self:GetMaxZombiePop() then
        pZM:PrintTranslatedMessage(HUD_PRINTCENTER, "population_limit_reached")
        return NULL
    end

    local pZombie = ents.Create(entname)

    if IsValid(pZombie) then
        local PosInWorld, pos = pZombie:FloorPoint(origin + Vector(0, 0, 0.1), MASK_NPCSOLID, 0, -2048)

        if not PosInWorld then
            print( string.format("NPC %s stuck in wall--level design error at (%.2f %.2f %.2f)\n", pZombie:GetClass(), pZombie:GetPos().x, pZombie:GetPos().y, pZombie:GetPos().z) )
        end

        pZombie:SetPos(pos)
        pZombie:SetOwner(pZM)
        pZombie:SetCollisionGroup(COLLISION_GROUP_NPC)

        angles.x = 0.0
        angles.z = 0.0
        pZombie:SetAngles(angles)

        if pZombie.SetEngineNPC then
            pZombie:SetEngineNPC(not pZombie:IsScripted())
        end

        pZombie.SpawnedFromNode = true
        pZombie:Spawn()
        pZombie:Activate()
        pZombie:AddEFlags(EFL_IN_SKYBOX)

        self:CallZombieFunction(pZombie, "SetupModel")
        self:CallZombieFunction(pZombie, "OnSpawned")

        if pZM and pZM:IsValid() then
            pZM:TakeZMPoints(cost)
        end

        self:AddCurZombiePop(popcost)

        --annoying bug
        if tab.Class == "npc_headcrab" then
            timer.Simple(0.2, function()
                if pZombie and IsValid(pZombie) then
                    pZombie:SetPos(pos)
                end
            end)
        end
        return pZombie
    end

    return NULL
end

function GM:ServerTravel( nextURL )
	if self.PendingURL then
		if not nextURL then -- Abort mapchange.
			timer.Remove("ServerTravelURL")
			self.PendingURL = nil
			print("Pending mapchange aborted!")

			net.Start("zm_servertravel")
				net.WriteBool(false)
			net.Broadcast()
		end
		return
	elseif not nextURL then
		return
	end

	net.Start("zm_servertravel")
		net.WriteBool(true)
		net.WriteString(nextURL)
	net.Broadcast()

	self.PendingURL = nextURL
	print("Pending mapchange to "..nextURL)
	timer.Create("ServerTravelURL", 6, 1, function()
		RunConsoleCommand( "changelevel", nextURL )
		timer.Simple(10, function() RunConsoleCommand( "changelevel", game.GetMap()) end ) -- Just incase the server hangs itself.
	end)
end

function GM:PropBreak(attacker, prop)
    SafeRemoveEntityDelayed(prop, 0)
end

function GM:SetupNetworkingCallbacks()
end

function GM:NPCTraceAttack(npc, dmginfo, dir, trace)
	npc.HitGroupWindow = npc.HitGroupWindow or 0

	if npc.HitGroupWindow < CurTime() then
		npc.HitGroupWindow = CurTime() + 0.01
		npc.LastHitGroup = trace.HitGroup
		npc.LastHitBox = trace.HitBox
	else
		if trace.HitGroup ~= 0 then
			npc.LastHitGroup = trace.HitGroup
			npc.LastHitBox = trace.HitBox
		end
	end

    npc:SetNWInt("LastHitBox", npc.LastHitBox)
end

net.Receive("zm_playeready", function(len, pl)
    local bReady = net.ReadBool()
    PlayerReadyList[pl] = bReady

    net.Start("zm_updateclientreadytable")
        net.WriteBool(false)
        net.WriteEntity(pl)
        net.WriteBool(bReady)
    net.Broadcast()

    GAMEMODE:CheckPlayersReady()
end)

net.Receive("zm_updateragdollpos", function(len, pl)
    local pos = net.ReadVector()
    if pl:Alive() or pl:Team() ~= TEAM_SPECTATOR then return end
    pl:SetPos(pos)
end)

net.Receive("zm_mousemove", function(len, pl)
    pl.m_flLastActivity = CurTime()
end)
