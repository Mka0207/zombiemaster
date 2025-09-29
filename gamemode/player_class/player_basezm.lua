AddCSLuaFile()
DEFINE_BASECLASS( "player_default" )

if CLIENT then
    CreateConVar( "cl_playercolor", "0.24 0.34 0.41", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
    CreateConVar( "cl_weaponcolor", "0.30 1.80 2.10", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
    CreateConVar( "cl_playerskin", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The skin to use, if the model has any" )
    CreateConVar( "cl_playerbodygroups", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The bodygroups to use, if the model has any" )
end

local spark_packs = false

if VoicePacks then
	VoiceSetTranslate = ModelIDTable
	spark_packs = true
	MsgN("SPARKWERK VOICE PACKS LOADED")
end

local PLAYER = {}

PLAYER.TauntCam = TauntCamera()

function PLAYER:Spawn()
    BaseClass.Spawn(self)

    local col = self.Player:GetInfo("cl_playercolor")
    self.Player:SetPlayerColor(Vector(col))

    local col = Vector(self.Player:GetInfo("cl_weaponcolor"))
    if col:Length() == 0 then
        col = Vector(0.001, 0.001, 0.001)
    end
    self.Player:SetWeaponColor(col)
    self.Player:Flashlight(false)
    self.Player.m_flLastActivity = CurTime()
    self.Player.OldEyeAngles = Angle(0, 0, 0)
end

local VoiceSetTranslate = {}
VoiceSetTranslate["models/player/alyx.mdl"] = "alyx"
VoiceSetTranslate["models/player/barney.mdl"] = "barney"
VoiceSetTranslate["models/player/breen.mdl"] = "male"
VoiceSetTranslate["models/player/combine_soldier.mdl"] = "combine"
VoiceSetTranslate["models/player/combine_soldier_prisonguard.mdl"] = "combine"
VoiceSetTranslate["models/player/combine_super_soldier.mdl"] = "combine"
VoiceSetTranslate["models/player/eli.mdl"] = "male"
VoiceSetTranslate["models/player/gman_high.mdl"] = "male"
VoiceSetTranslate["models/player/kleiner.mdl"] = "male"
VoiceSetTranslate["models/player/monk.mdl"] = "monk"
VoiceSetTranslate["models/player/mossman.mdl"] = "female"
VoiceSetTranslate["models/player/odessa.mdl"] = "male"
VoiceSetTranslate["models/player/police.mdl"] = "combine"

local PlayerSkinReplacment = {}
PlayerSkinReplacment["models/player/group01/male_01.mdl"] = "models/Humans/Male/Group02/MaleSurvivor1"
PlayerSkinReplacment["models/player/group01/male_02.mdl"] = "models/Humans/Male/Group02/MaleSurvivor2"
PlayerSkinReplacment["models/player/group01/male_03.mdl"] = "models/Humans/Male/Group02/MaleSurvivor3"
PlayerSkinReplacment["models/player/group01/male_04.mdl"] = "models/Humans/Male/Group02/MaleSurvivor4"
PlayerSkinReplacment["models/player/group01/male_05.mdl"] = "models/Humans/Male/Group02/MaleSurvivor5"
PlayerSkinReplacment["models/player/group01/male_06.mdl"] = "models/Humans/Male/Group02/MaleSurvivor6"
PlayerSkinReplacment["models/player/group01/male_07.mdl"] = "models/Humans/Male/Group02/MaleSurvivor7"
PlayerSkinReplacment["models/player/group01/male_08.mdl"] = "models/Humans/Male/Group02/MaleSurvivor8"
PlayerSkinReplacment["models/player/group01/male_09.mdl"] = "models/Humans/Male/Group02/MaleSurvivor9"
PlayerSkinReplacment["models/player/group01/female_01.mdl"] = "models/Humans/Female/Group02/Fem_Survivor1"
PlayerSkinReplacment["models/player/group01/female_02.mdl"] = "models/Humans/Female/Group02/Fem_Survivor2"
PlayerSkinReplacment["models/player/group01/female_03.mdl"] = "models/Humans/Female/Group02/Fem_Survivor3"
PlayerSkinReplacment["models/player/group01/female_04.mdl"] = "models/Humans/Female/Group02/Fem_Survivor4"
PlayerSkinReplacment["models/player/group01/female_05.mdl"] = "models/Humans/Female/Group02/Fem_Survivor5"
PlayerSkinReplacment["models/player/group01/female_06.mdl"] = "models/Humans/Female/Group02/Fem_Survivor6"
function PLAYER:GetReplacmentSkin(model)
    return PlayerSkinReplacment[model]
end

function PLAYER:SetModel()
    local cl_playermodel = self.Player:GetInfo("cl_playermodel")
    local modelname = string.lower(player_manager.TranslatePlayerModel(cl_playermodel))
    if #cl_playermodel == 0 then
        modelname = "models/player/kleiner.mdl"
    end

    util.PrecacheModel(modelname)
    self.Player:SetModel(modelname)

    local skin = self.Player:GetInfoNum("cl_playerskin", 0)
    self.Player:SetSkin(skin)

    local groups = self.Player:GetInfo("cl_playerbodygroups")
    if groups == nil then groups = "" end
    local groups = string.Explode(" ", groups)
    for k = 0, self.Player:GetNumBodyGroups() - 1 do
        self.Player:SetBodygroup(k, tonumber(groups[ k + 1 ]) or 0)
    end

    if string.find(modelname, "male", 1, true) then
        self.Player:SetSkin(skin)
    end

	self.Player:SetupHands()
	local hands = self.Player:GetHands()
	
	local replace_hands = hands and hands:IsValid() and hands:GetModel() == modelname
	
    if PlayerSkinReplacment[modelname] then
        for i, mat in pairs(self.Player:GetMaterials()) do
            if string.find(mat, "players_sheet") then
                self.Player:SetSubMaterial(i - 1, PlayerSkinReplacment[modelname])
                self.Player:SetSkinReplacmentIndex(i - 1)
                self.Player:SetSkinReplacmentMat(PlayerSkinReplacment[modelname])
                break
            end
        end
		if replace_hands then
			for i, mat in pairs(hands:GetMaterials()) do
				if string.find(mat, "players_sheet") then
					hands:SetSubMaterial(i - 1, PlayerSkinReplacment[modelname])
					hands:SetSkinReplacmentIndex(i - 1)
					hands:SetSkinReplacmentMat(PlayerSkinReplacment[modelname])
					break
				end
			end
		end
    end

    if not GetConVar("zm_disable_playersnds"):GetBool() then
        if spark_packs then
            local mid = getModelID(self.Player)
            self.Player.VoiceSet = mid and mid or "None"
        elseif VoiceSetTranslate[modelname] then
            self.Player.VoiceSet = VoiceSetTranslate[modelname]
        elseif string.find(modelname, "female", 1, true) then
            self.Player.VoiceSet = "female"
        else
            self.Player.VoiceSet = "male"
        end
    else
        self.Player.VoiceSet = "None"
    end
end

function PLAYER:ShouldDrawLocal()
    if self.TauntCam:ShouldDrawLocalPlayer(self.Player, self.Player:IsPlayingTaunt()) then return true end
end

function PLAYER:SetupMove(mv, cmd)
end

function PLAYER:CreateMove( cmd )
    if self.TauntCam:CreateMove(cmd, self.Player, self.Player:IsPlayingTaunt()) then return true end
end

function PLAYER:CalcView( view )
    if self.TauntCam:CalcView(view, self.Player, self.Player:IsPlayingTaunt()) then return true end
end

function PLAYER:GetHandsModel()
    local cl_playermodel = self.Player:GetInfo( "cl_playermodel" )
    return player_manager.TranslatePlayerHands( cl_playermodel )
end

function PLAYER:GetNextViewablePlayer(dir)
	local AllPlayers = team.GetPlayers(TEAM_SURVIVOR)
	local PlayerCount = #AllPlayers
	local CurrentIndex = -1
	local RealViewTarget = self.Player:GetObserverTarget()
	if IsValid(RealViewTarget) then
		for i, pl in pairs(AllPlayers) do
			if RealViewTarget == pl then
				CurrentIndex = i
				break
			end
		end
	end

	local Index = CurrentIndex+dir
	if Index > PlayerCount then
		CurrentIndex = 0
	elseif Index < 0 then
		CurrentIndex = PlayerCount-dir
	end

	for NewIndex=CurrentIndex+dir,PlayerCount do
		local ply = AllPlayers[NewIndex]
		if IsValid(ply) and ply:Alive() then
			return ply
		end
	end

	return NULL
end

function PLAYER:OnTakeDamage(attacker, dmginfo)
end

function PLAYER:PostOnTakeDamage(attacker, dmginfo, took)
end

function PLAYER:PreDeath(inflictor, attacker)
    self.Player.NextSpawnTime = CurTime() + 2
    self.Player.DeathTime = CurTime()

    if IsValid(attacker) and attacker:GetClass() == "trigger_hurt" then attacker = self.Player end

    if IsValid(attacker) and attacker:IsVehicle() and IsValid(attacker:GetDriver()) then
        attacker = attacker:GetDriver()
    end

    if not IsValid(inflictor) and IsValid(attacker) then
        inflictor = attacker
    end

    if IsValid(inflictor) and inflictor == attacker and inflictor:IsPlayer() then
        inflictor = inflictor:GetActiveWeapon()
        if not IsValid(inflictor) then inflictor = attacker end
    end

    if attacker == self.Player then
        net.Start("PlayerKilledSelf")
            net.WriteEntity(self.Player)
        net.Broadcast()
    return end

    if attacker:IsPlayer() then
        net.Start("PlayerKilledByPlayer")
            net.WriteEntity(self.Player)
            net.WriteString(inflictor:IsValid() and inflictor:GetClass() or attacker:GetClass())
            net.WriteEntity(attacker)
        net.Broadcast()
    return end

    if attacker:IsNPC() or inflictor:IsNPC() or attacker:IsNextBot() or inflictor:IsNextBot() then
        /*local pZM = GAMEMODE:FindZM()
        if IsValid(pZM) then
            pZM:AddFrags(1)
        end*/
		
		for k, v in pairs (GAMEMODE:FindZMs()) do
			if IsValid(v) then
				v:AddFrags(1)
			end
		end

        net.Start("PlayerKilledByNPC")
            net.WriteEntity(self.Player)
            net.WriteEntity(attacker)
            net.WriteString(inflictor:IsValid() and inflictor:GetClass() or attacker:GetClass())
        net.Broadcast()
    return end

    net.Start("PlayerKilled")
        net.WriteEntity(self.Player)
        net.WriteString(inflictor:IsValid() and inflictor:GetClass() or attacker:GetClass())
        net.WriteString(attacker:GetClass())
    net.Broadcast()
end

function PLAYER:OnDeath(attacker, dmginfo)
end

function PLAYER:PostOnDeath(inflictor, attacker)
end

function PLAYER:OnHurt(attacker, healthremaining, damage)
end

function PLAYER:Think()
    if SERVER and GAMEMODE:GetRoundActive() and not self.bIgnoreAFK then
        if self.Player:GetInternalVariable("m_afButtonLast") ~= self.Player:GetInternalVariable("m_nButtons") or self.Player:EyeAngles() ~= self.Player.OldEyeAngles then
            self.Player.m_flLastActivity = CurTime()
            self.Player.OldEyeAngles = self.Player:EyeAngles()
        end

        if self.Player:IsCloseToAFK() and hook.Call("CanInactivityPunish", GAMEMODE, self.Player) then
            if self.Player:IsAFK() then
                hook.Call("PunishInactivity", GAMEMODE, self.Player)
            elseif ((self.Player.m_flLastActivityWarning or 0) + 1) < CurTime() then
                self.Player:PrintMessage(HUD_PRINTCENTER, "You are about to get punished for being AFK!")
                self.Player.m_flLastActivityWarning = CurTime()
            end
        end
    end
end

function PLAYER:PostThink()
end

function PLAYER:DeathThink()
    return true
end

function PLAYER:AllowPickup(ent)
    return false
end

function PLAYER:CanPickupWeapon(ent)
    return false
end

function PLAYER:CanPickupItem(item)
    return false
end

function PLAYER:PreDraw()
    return true
end

function PLAYER:PostDraw()
end

function PLAYER:PreDrawOther(ply)
    hook.Run("PlayerAlphaChanged", ply, 1)
    ply.ShadowMan = false
    return true
end

function PLAYER:PostDrawOther(ply)
end

function PLAYER:ShouldTaunt(act)
    return true
end

function PLAYER:CanSuicide()
    return not GAMEMODE:GetRoundEnd()
end

function PLAYER:BindPress(bind, pressed)
end

function PLAYER:ButtonDown(button)
end

function PLAYER:ButtonUp(button)
end

function PLAYER:KeyPress(key)
end

function PLAYER:KeyRelease(key)
end

function PLAYER:MousePressed(code, vector)
end

function PLAYER:MouseReleased(code, vector)
end

function PLAYER:MouseDoublePressed(code, vector)
end

function PLAYER:ShouldTakeDamage(attacker)
    return false
end

function PLAYER:DrawHUD()
end

function PLAYER:CreateVGUI()
end

function PLAYER:InputMouseApply(cmd, x, y, ang)
end

function PLAYER:RenderScreenspaceEffects()
end

player_manager.RegisterClass("player_basezm", PLAYER, "player_default")