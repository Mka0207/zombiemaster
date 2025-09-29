AddCSLuaFile()
DEFINE_BASECLASS("player_basezm")

local PLAYER = {}

PLAYER.WalkSpeed             = 170
PLAYER.RunSpeed              = 170
PLAYER.CrouchedWalkSpeed     = 0.45
PLAYER.JumpPower			 = 160

PLAYER.AvoidPlayers          = false
PLAYER.TeammateNoCollide     = false
PLAYER.OverTheShoulder       = false

function PLAYER:Spawn()
    BaseClass.Spawn(self)
    
    self.Player:SetSlowWalkSpeed(110)
    self.Player:SetFlashlightBattery(100, true)
    self.Player:SetOxygenLevel(100, true)
    
    self.Player:CrosshairEnable()
    self.Player:StripWeapons()
    
    if GetConVar("zm_disableplayercollision"):GetBool() then
        self.Player:SetNoCollideWithTeammates(true)
        self.Player:SetCustomCollisionCheck(true)
        self.Player:SetAvoidPlayers(false)
        self.Player:CollisionRulesChanged()
    end
	
    self.Player:SendLua([[
        hook.Call("RemoveZMPanels", GAMEMODE)
        
        local ply = MySelf
        if not IsValid(ply.QuickInfo) then
            timer.Create("CreateQuickInfo", 0, 0, function()
                ply.QuickInfo = vgui.Create("CHudQuickInfo")
                if IsValid(ply.QuickInfo) then
                    ply.QuickInfo:Center()
                    timer.Remove("CreateQuickInfo")
                end
            end)
        end

        if cvars.Bool("zm_cl_enablehints") and IsValid(GAMEMODE.ZM_Center_Hints) then
            GAMEMODE.ZM_Center_Hints:SetHint(translate.Get("zm_hint_intro_s"))
            GAMEMODE.ZM_Center_Hints:SetActive(true, 2)
            
            timer.Simple(8, function()
                if not IsValid(GAMEMODE.ZM_Center_Hints) then return end
                
                GAMEMODE.ZM_Center_Hints:SetHint(translate.Get("zm_hint_weapons"))
                GAMEMODE.ZM_Center_Hints:SetActive(true, 2)
                
                timer.Simple(8, function()
                    if not IsValid(GAMEMODE.ZM_Center_Hints) then return end
                    
                    GAMEMODE.ZM_Center_Hints:SetHint(translate.Format("zm_hint_dropping", input.GetKeyName(cvars.Number("zm_dropweaponkey", 0)), input.GetKeyName(cvars.Number("zm_dropammokey", 0))))
                    GAMEMODE.ZM_Center_Hints:SetActive(true, 2)   
                end)                
            end)
        end
        
        if not IsValid(GAMEMODE.FlashlightHUD) then
            GAMEMODE.FlashlightHUD = vgui.Create("CHudFlashlight")
        end
        
        if not IsValid(GAMEMODE.OxygenHUD) then
            GAMEMODE.OxygenHUD = vgui.Create("CHudOxygen")
        end
        
        if not IsValid(GAMEMODE.ReloadHUD) then
            GAMEMODE.ReloadHUD = vgui.Create("CHudReloadTime")
        end
    ]])
end

function PLAYER:Loadout()
    self.Player:Give("weapon_zm_fists")
    //self.Player:Give("weapon_zm_carry")
end

function PLAYER:Think()
    BaseClass.Think(self)
    
    local pl = self.Player
    if pl:FlashlightIsOn() and pl:GetFlashlightBattery() > 0 then
        pl:SetFlashlightBattery(pl:GetFlashlightBattery() - (FrameTime() * GetConVar("zm_sv_flashlightdrainrate"):GetFloat()))
    elseif not pl:FlashlightIsOn() and pl:GetFlashlightBattery() ~= 100 then
        pl:SetFlashlightBattery(pl:GetFlashlightBattery() + (FrameTime() * GetConVar("zm_sv_flashlightrechargerate"):GetFloat()))
    end

    if self.Player:WaterLevel() == 3 then
        if pl:GetOxygenLevel() > 0 then
            pl:SetOxygenLevel(pl:GetOxygenLevel() - (FrameTime() * GetConVar("zm_sv_oxygendrainrate"):GetFloat()))
        end
        
        if SERVER then
            if self.Player:IsOnFire() then
                self.Player:Extinguish()
            end

            if pl:GetOxygenLevel() == 0 then
                if (self.Player.Drowning or 0) < CurTime() then
                    local dmginfo = DamageInfo()
                    dmginfo:SetDamage(15)
                    dmginfo:SetDamageType(DMG_DROWN)
                    dmginfo:SetAttacker(game.GetWorld())

                    self.Player:TakeDamageInfo(dmginfo)

                    self.Player.Drowning = CurTime() + 1
                end
            end
        end
    else
        if pl:GetOxygenLevel() ~= 100 then
            pl:SetOxygenLevel(pl:GetOxygenLevel() + (FrameTime() * GetConVar("zm_sv_oxygengainrate"):GetFloat()))
        end
            
        if SERVER then
            if self.Player.DrownDamage then
                local timername = "zm_playerdrown_regen."..self.Player:EntIndex()
                if timer.Exists(timername) then return end
                
                timer.Create(timername, 2, 0, function()
                    if not IsValid(self.Player) or self.Player:Health() == self.Player:GetMaxHealth() then 
                        self.Player.DrownDamage = nil
                        timer.Remove(timername) 
                        return 
                    end
                    
                    local d = DamageInfo()
                    d:SetAttacker(self.Player)
                    d:SetInflictor(self.Player)
                    d:SetDamageType(DMG_DROWNRECOVER)
                    self.Player:TakeDamageInfo(d)
                    
                    self.Player:SetHealth(self.Player:Health() + 5)
                    self.Player.DrownDamage = self.Player.DrownDamage - 5
                    
                    if self.Player.DrownDamage <= 0 then
                        self.Player.DrownDamage = nil
                        timer.Remove(timername)
                    end
                end)
            end
            
            self.Player.Drowning = nil
        end
    end
    
    if CLIENT then
        if cvars.Number("zm_hudtype", 0) == HUD_ZMR and not IsValid(GAMEMODE.HumanHealthHUD) then
            GAMEMODE.HumanHealthHUD = vgui.Create("CHudHealthInfo")
        end
    end
end

function PLAYER:AllowPickup(ent)
    if not ent:IsValid() or ent:IsPlayerHolding() or not self.Player:Alive() then return false end
    
    local phys = ent:GetPhysicsObject()
    local objectMass = 0
    if IsValid(phys) then
        objectMass = phys:GetMass()
        if phys:HasGameFlag(FVPHYSICS_NO_PLAYER_PICKUP) or not phys:IsMotionEnabled() then
            return false
        end
    else
        return false
    end
    
    if ent.AllowPickup and not ent:AllowPickup(self.Player) then 
        return false 
    end
    
    if CARRY_MASS > 0 and objectMass > CARRY_MASS then
        return false
    end

    local size = ent:OBBMaxs() - ent:OBBMins()
    if size.x > CARRY_VOLUME or size.y > CARRY_VOLUME or size.z > CARRY_VOLUME then
        return false
    end
    
    return true
end

function PLAYER:CanPickupWeapon(ent)
    if SERVER and self.Player.DelayPickup and self.Player.DelayPickup > CurTime() then 
        self.Player.DelayPickup = 0
        return false 
    end
    
    if self.Player:Alive() then
        if ent.ThrowTime and ent.ThrowTime > CurTime() then return false end

        if self.Player:HasWeapon(ent:GetClass()) then 
            if ent.WeaponIsAmmo then
                return hook.Call("PlayerCanPickupItem", GAMEMODE, self.Player, ent)
            end
            
            return false 
        end
        
        local weps = self.Player:GetWeapons()
        for index, wep in ipairs(weps) do
            local slot = wep:GetSlot()
            if slot == 0 then continue end
            
            if slot == ent:GetSlot() then
                return false
            end
        end
        
        return true
    end
    
    self.Player.DelayPickup = CurTime() + 0.1
    
    return false
end

function PLAYER:CanPickupItem(item)
    if self.Player.DelayItemPickup and self.Player.DelayItemPickup > CurTime() then 
        self.Player.DelayItemPickup = 0
        return false
    end
    
    if self.Player:Alive() and item:GetClassName() ~= nil then
        if item.ThrowTime and item.ThrowTime > CurTime() then return false end
        
        local ammotype = GAMEMODE.AmmoClass[item:GetClassName()] or ""
        for _, wep in ipairs(self.Player:GetWeapons()) do
            local primaryammo = wep.Primary and wep.Primary.Ammo or ""
            local secondaryammo = wep.Secondary and wep.Secondary.Ammo or ""
            
            if string.lower(primaryammo) == string.lower(ammotype) or string.lower(secondaryammo) == string.lower(ammotype) then
                local ammovar = GetConVar("zm_maxammo_"..primaryammo or secondaryammo)
                
                if ammovar == nil then return end
                
                local clipdif = wep:GetMaxClip1() - wep:Clip1()
                if (self.Player:GetAmmoCount(ammotype) - clipdif) < ammovar:GetInt() then
                    if item:IsWeapon() then
                        self.Player:GiveAmmo(GAMEMODE.AmmoCache[ammotype], ammotype, false)
                        item:Remove()
                        return false
                    end
                    
                    return true
                end
            end
        end
        
        return false
    end
    
    self.Player.DelayItemPickup = CurTime() + 0.1
    
    return false
end

function PLAYER:SetupMove(mv, cmd)
    if self.Player:IsHolding() then
        local ent = self.Player.CarryProp
        if ent:IsPlayerHolding() then 
            self.Player.player_pickup:SetupMove(self.Player, ent, mv, cmd)
            return true
        end
    end
end

function PLAYER:ButtonDown(button)
    if SERVER then return end
    
    if button == cvars.Number("zm_dropweaponkey", 0) then
        RunConsoleCommand("zm_dropweapon")
    elseif button == cvars.Number("zm_dropammokey", 0) then
        RunConsoleCommand("zm_dropammo")
    end
end

local healthBG = Material("zmr_effects/hud_bg_hp")
function PLAYER:DrawHUD()
    if cvars.Number("zm_hudtype", 0) == HUD_ZMR then return end
    
    local wid, hei = ScreenScale(75), ScreenScale(24)
    local x, y = ScrW() * 0.035, ScrH() * 0.9
    
    draw.RoundedBox(10, x + 2, y + 2, wid, hei, Color(60, 0, 0, 200))
    
    local health = self.Player:Health()
    if self.Player.CurrentHP ~= health then
        self.Player.CurrentHP = health
        
        self.Player.LastHurtTime = CurTime()
        self.Player.HurtTimer = CurTime() + 5
    end
    
    local healthCol = health <= 10 and Color(185, 0, 0, 255) or health <= 30 and Color(150, 50, 0) or health <= 60 and Color(255, 200, 0) or color_white
    if health <= 10 then
        local sinScale = math.floor(math.abs(math.sin(CurTime() * 8)) * 128)
        healthCol.a = math.Clamp(sinScale, 90, 230)
    end
    
    draw.SimpleTextBlurry(health, "zm_hud_font_big", x + wid * 0.72, y + hei * 0.5, healthCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, self.Player.LastHurtTime, self.Player.HurtTimer)
    draw.SimpleTextBlurry(language.GetPhrase("Valve_Hud_HEALTH"), "zm_hud_font_small", x + wid * 0.25, y + hei * 0.7, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function PLAYER:PreDeath(inflictor, attacker)
    BaseClass.PreDeath(self, inflictor, attacker)
    
    self.Player:SendLua([[
        if IsValid(MySelf.QuickInfo) then
            MySelf.QuickInfo:Remove()
        end        
        
        if IsValid(GAMEMODE.HumanHealthHUD) then
            GAMEMODE.HumanHealthHUD:Remove()
        end        
        
        if IsValid(GAMEMODE.FlashlightHUD) then
            GAMEMODE.FlashlightHUD:Remove()
        end
    ]])
    
    for _, wep in ipairs(self.Player:GetWeapons()) do
        if IsValid(wep) and not wep.Undroppable then
            self.Player:DropWeapon(wep)
        end
    end
end

function PLAYER:OnDeath(attacker, dmginfo)
    self.Player:Freeze(false)
    self.Player:DropAllAmmo()
    
    GAMEMODE.DeadPlayers[self.Player:SteamID()] = true
    
    if IsValid(attacker) and attacker:IsPlayer() then
        if attacker == self.Player then
            attacker:AddFrags(-1)
        else
            attacker:AddFrags(1)
        end
    end
    
    if self.Player:Health() <= -70 and not dmginfo:IsDamageType(DMG_DISSOLVE) then
        if attacker:IsValid() and attacker:IsAPhysicsProp() then
            self.Player:CreateRagdoll()
        else
            self.Player:Gib(dmginfo)
        end
    else
        self.Player:CreateRagdoll()
    end
    
    local hands = self.Player:GetHands()
    if IsValid(hands) then
        hands:Remove()
    end
    
    self.Player:PlayDeathSound()
    
    /*local pZM = GAMEMODE:FindZM()
    if IsValid(pZM) then
        pZM:AddFrags(10)
        pZM:AddZMPoints(GetConVar("zm_kill_reward"):GetInt())
    end*/
	
	for k, v in pairs (GAMEMODE:FindZMs()) do
		if IsValid(v) then
			v:AddFrags(10)
			v:AddZMPoints(GetConVar("zm_kill_reward"):GetInt())
		end
	end
    
    if self.Player:FlashlightIsOn() then
        self.Player:Flashlight(false)
        self.Player:SendLua("MySelf:ClientSetFlashlight(false)")
    end
    
    self.Player:SendLua("MySelf.m_flEnd = CurTime() + 6")
    timer.Simple(0.1, function() 
        if not IsValid(self.Player) then
            for _, pl in ipairs(team.GetPlayers(TEAM_SURVIVOR)) do
                if not pl:Alive() then
                    hook.Call("PlayerSpawnAsSpectator", GAMEMODE, pl)
                end
            end
            return 
        end
        hook.Call("PlayerSpawnAsSpectator", GAMEMODE, self.Player) 
    end)
end

function PLAYER:PostOnDeath(inflictor, attacker)
    self.Player.AllowKeyPress = false
    timer.Simple(3.15, function()
        if not IsValid(self.Player) or self.Player:Team() ~= TEAM_SPECTATOR then return end
        self.Player.AllowKeyPress = true
    end)
    
    if player.GetCount() == 1 then return end
    
    timer.Simple(0.15, function()
        if team.NumPlayers(TEAM_SURVIVOR) == 0 then
            hook.Call("TeamVictorious", GAMEMODE, false, "undead_has_won")
        end
    end)
end

function PLAYER:OnTakeDamage(attacker, dmginfo)
    local inflictor = dmginfo:GetInflictor()
    if IsValid(attacker) and attacker:GetClass() == "projectile_molotov" then
        return true
    end
    
    if IsValid(inflictor) and inflictor:GetClass() == "projectile_molotov" then
        return true
    end
    
    if attacker:GetClass() == "env_fire" and attacker:GetOwner() == self.Player then
        dmginfo:ScaleDamage(0.25)
    end
    
    if bit.band(dmginfo:GetDamageType(), DMG_DROWN) ~= 0 and dmginfo:GetDamage() > 0 then
        self.Player.DrownDamage = (self.Player.DrownDamage or 0) + dmginfo:GetDamage()
    end
    
    if dmginfo:GetDamage() > 0 and self.Player:Health() > 0 and bit.band(dmginfo:GetDamageType(), DMG_DROWN) == 0 and self:ShouldTakeDamage(attacker) and not self.Player:HasGodMode() then
        self.Player:PlayPainSound()
    end
end

function PLAYER:ShouldTakeDamage(attacker)
    if attacker.PBAttacker and attacker.PBAttacker:IsValid() and CurTime() < attacker.NPBAttacker then -- Protection against prop_physbox team killing. physboxes don't respond to SetPhysicsAttacker()
        attacker = attacker.PBAttacker
    end
    
    local attackerclass = attacker:GetClass()
    local entteam = attacker.OwnerTeam
    if attackerclass == "env_fire" and entteam == self.Player:Team() and attacker:GetOwner() ~= self.Player then
        return false
    elseif attackerclass == "env_delayed_physexplosion" then
        return false
    end
    
    if (attacker:IsPlayer() and attacker ~= self.Player and not attacker:IsZM()) or string.sub(attackerclass, 1, 5) == "item_" then
        return false
    end
    
    local parent = attacker:GetParent()
    if attacker:GetClass() == "entityflame" and parent:IsValid() and (parent:IsPlayer() and parent ~= self.Player and not parent:IsZM()) then
        return false
    end
    
    return true
end

local oldGEnts,StandOnNewGround

if SERVER then
	oldGEnts = {}
	local MoverEnts = {["func_train"]=true,["func_tracktrain"]=true,["func_movelinear"]=true,["func_rotating"]=true}

	function StandOnNewGround( pl, ent )
		rawset(oldGEnts,pl,ent)
		
		if IsValid(ent) and MoverEnts[ent:GetClass()] then
			pl:SetNW2Entity("GroundEntity",ent)
		else
			pl:SetNW2Entity("GroundEntity",nil)
		end
	end
end

local entmeta = FindMetaTable("Entity")
local pl_GetGroundEntity = entmeta.GetGroundEntity
function PLAYER:Move(mv) 
    if SERVER then
        local ent = pl_GetGroundEntity(self.Player)
        if rawget(oldGEnts,self.Player)~=ent then
            StandOnNewGround(self.Player,ent)
        end
    end
end

local EyePos = EyePos
local math_max = math.max
local hook_Run = hook.Run

local M_Vector = FindMetaTable("Vector")
local V_DistToSqr = M_Vector.DistToSqr

local M_Entity = FindMetaTable("Entity")
local E_NearestPoint = M_Entity.NearestPoint
local E_GetTable = M_Entity.GetTable

local undomodelblend = false
local matWhite = Material("models/debug/debugwhite")
function PLAYER:PreDrawOther(ply)
    local ptbl = E_GetTable(ply)
    local shadowman = false
    local radius = GAMEMODE.TransparencyRadius
    if radius > 0 then
        local eyepos = EyePos()
        local dist = V_DistToSqr(E_NearestPoint(ply, eyepos), eyepos)
        if self.Player:Team() == ply:Team() and dist < radius then
            local blend = math_max((dist / radius) ^ 1.4, 0.04)
            if ptbl.Transparency ~= blend then
                hook_Run("PlayerAlphaChanged", ply, blend)
            end
            ptbl.Transparency = blend
            
			if blend == 0 then
				ptbl.ShadowMan = true
				return true
			end
            
            render.SetBlend(blend)
            if blend < 0.4 then
                render.ModelMaterialOverride(matWhite)
                render.SetColorModulation(0.2, 0.2, 0.2)
                shadowman = true
            end
            undomodelblend = true
        end
    end
    
    ptbl.ShadowMan = shadowman
    
    return true
end

function PLAYER:PostDrawOther(ply)
    if undomodelblend then
        render.SetBlend(1)
        render.ModelMaterialOverride()
        render.SetColorModulation(1, 1, 1)
        undomodelblend = false
    end	
end

function PLAYER:UseOverTheShoulder()
	return self.OverTheShoulder and not engine.IsPlayingDemo()
end

function PLAYER:ShouldDrawLocal()
    return self:UseOverTheShoulder()
end

local otscameraangles = Angle()
local otsdesiredright = 0
local staggerdir = VectorRand():GetNormalized()

function PLAYER:UseOverTheShoulder()
	return self.OverTheShoulder and not engine.IsPlayingDemo()
end

function PLAYER:ToggleOTSCamera()
	if self.OverTheShoulder then
		self.OverTheShoulder = false
	else
		self.OverTheShoulder = true
		otsdesiredright = 1
		otscameraangles = MySelf:EyeAngles()
	end
end

function PLAYER:InputMouseApplyOTS(cmd, x, y, ang)
	otscameraangles.pitch = math.Clamp(math.NormalizeAngle(otscameraangles.pitch + y / 50), -89, 89)
	otscameraangles.yaw = math.NormalizeAngle(otscameraangles.yaw - x / 50)
	otscameraangles.roll = ang.roll
end

function PLAYER:CreateMoveOTS(cmd)
	local offsetyaw = otscameraangles.yaw - cmd:GetViewAngles().yaw --ply:EyeAngles( ).y

	local corrected = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), 0)
	local sign = cmd:GetForwardMove() < 0
	local length = corrected:Length()

	corrected = Angle(0, corrected:Angle().y - offsetyaw, 0):Forward()

	-- Not possible to get a perfect solution, but this is better.
	cmd:SetForwardMove(math.Clamp(corrected.x * length, sign and -length or 0, length))
	cmd:SetSideMove(corrected.y * length)
end

local trace_wall = {mask = MASK_SOLID_BRUSHONLY, mins = Vector(-3, -3, -3), maxs = Vector(3, 3, 3)}
local trace_crosshair = {mask = MASK_VISIBLE--[[, mins = Vector(-1, -1, -1), maxs = Vector(1, 1, 1)]]}
local maxdiff = 70

local myteam = 0
local function IgnoreTeam(ent)
	return not (ent:IsPlayer() and ent:Team() == myteam)
end
function PLAYER:CalcViewOTS(pl, origin, angles, fov, znear, zfar)
	local camPos = origin - otscameraangles:Forward() * 28 + otsdesiredright * 12 * otscameraangles:Right()
	local eyepos = pl:EyePos()

	trace_wall.start = eyepos
	trace_wall.endpos = camPos
	trace_wall.filter = pl
	camPos = util.TraceHull(trace_wall).HitPos

	myteam = GetPlayerTeam(pl)
	trace_crosshair.start = camPos
	trace_crosshair.endpos = camPos + otscameraangles:Forward() * 32768
	trace_crosshair.filter = IgnoreTeam
	local crosshair_tr = util.TraceLine(trace_crosshair)
	local crosshair_pos = crosshair_tr.HitPos
	local desired_angles = (crosshair_pos - eyepos):Angle()

	-- Don't face away more than a certain amount of degrees
	desired_angles.yaw = math.ApproachAngle(otscameraangles.yaw, desired_angles.yaw, maxdiff)

	pl:SetEyeAngles(desired_angles)

	origin:Set(camPos)
	angles:Set(otscameraangles)
end

function PLAYER:BindPress(bind, pressed)
    if bind == "+menu_context" then
        self:ToggleOTSCamera()
	end
end

function PLAYER:InputMouseApply(cmd, x, y, ang)
	if self:ShouldDrawLocal() then
		self:InputMouseApplyOTS(cmd, x, y, ang)
	end
end

function PLAYER:CreateMove(cmd)
    BaseClass.CreateMove(self, cmd)
    
    if self:ShouldDrawLocal() then
        self:CreateMoveOTS(cmd)
    end
end

local roll = 0
function PLAYER:CalcView( view )
    if self:ShouldDrawLocal() then
        self:CalcViewOTS(self.Player, view.origin, view.angles, view.fov, view.znear, view.zfar)
    end
    
	local targetroll = 0

	if self.Player:WaterLevel() >= 3 then
		targetroll = targetroll + math.sin(CurTime()) * 7
	end

	roll = math.Approach(roll, targetroll, math.max(0.25, math.sqrt(math.abs(roll))) * 30 * FrameTime())
	view.angles.roll = view.angles.roll + roll
    
    if self.TauntCam:CalcView(view, self.Player, self.Player:IsPlayingTaunt()) then return true end
end

local Normal_ColorMod = {
    ["$pp_colour_contrast"] = 0.95,
    ["$pp_colour_colour"] = 0.9,
    ["$pp_colour_addr"] = 0,
    ["$pp_colour_addg"] = 0,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = -0.025,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0,
    ["$pp_colour_mulb"] = 0
}
local matUnderwater = Material("effects/water_warp01")
function PLAYER:RenderScreenspaceEffects()
	if not matUnderwater:IsError() and MySelf:WaterLevel() >= 3 then
		render.UpdateScreenEffectTexture()
		render.SetMaterial(matUnderwater)
		render.DrawScreenQuad()
	end
    
    if not GAMEMODE.ColorModEnabled then return end
    
    local healthfract = math.Clamp(self.Player:Health(), 0, self.Player:GetMaxHealth()) / 100
    Normal_ColorMod["$pp_colour_addr"] = (1 - healthfract) * 0.075
    Normal_ColorMod["$pp_colour_mulr"] = (1 - healthfract) * 0.25
    Normal_ColorMod["$pp_colour_brightness"] = -((1 - healthfract) * 0.025) - 0.025
    DrawColorModify(Normal_ColorMod)
end

player_manager.RegisterClass("player_survivor", PLAYER, "player_basezm")