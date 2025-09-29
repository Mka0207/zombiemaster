local meta = FindMetaTable("Player")
if not meta then return end

local getmetatable = getmetatable
local P_Team = meta.Team

local spark_packs = VoicePacks and true or false

function meta:GetMouseTrace()
    if SERVER then return end
    
    local framenum = FrameNumber()
    if self.LastMouseTrace == framenum then
        return self.MouseTrace
    end

    self.LastMouseTrace = framenum

	local tr = util.TraceLine(util.GetPlayerTrace(self, gui.ScreenToVector(gui.MousePos())))
	self.MouseTrace = tr

	return tr
end

function meta:IsZM()
    return P_Team(self) == TEAM_ZOMBIEMASTER
end

function meta:IsSurvivor()
    return P_Team(self) == TEAM_SURVIVOR
end

function meta:IsSpectator()
    return P_Team(self) == TEAM_SPECTATOR
end

meta.OldSpectate = meta.OldSpectate or meta.Spectate
function meta:Spectate(obsmode)
    if CLIENT then return end
    
    self:SetNoTarget(true)
    self:SetMoveType(MOVETYPE_NOCLIP)
    self:OldSpectate(obsmode)
end

meta.OldUnSpectate = meta.OldUnSpectate or meta.UnSpectate
function meta:UnSpectate()
    self:SetNoTarget(false)
    self:OldUnSpectate()
end

function meta:CanAfford(cost)
    return self:GetZMPoints() > cost
end

function meta:GetZMPoints()
    return self:GetDTInt(1)
end

function meta:GetZMPointIncome()
    return self:GetDTInt(2)
end

meta.OldAlive = meta.OldAlive or meta.Alive
function meta:Alive()
    if self:IsZM() then
        return true
    end

    return self:OldAlive()
end

function meta:SyncAngles()
	local ang = self:EyeAngles()
	ang.pitch = 0
	ang.roll = 0
	return ang
end

local VoiceSets = {}

VoiceSets["male"] = {
    ["PainSoundsLight"] = {
        Sound("vo/npc/male01/ow01.wav"),
        Sound("vo/npc/male01/ow02.wav"),
        Sound("vo/npc/male01/pain01.wav"),
        Sound("vo/npc/male01/pain02.wav"),
        Sound("vo/npc/male01/pain03.wav")
    },
    ["PainSoundsMed"] = {
        Sound("vo/npc/male01/pain04.wav"),
        Sound("vo/npc/male01/pain05.wav"),
        Sound("vo/npc/male01/pain06.wav")
    },
    ["PainSoundsHeavy"] = {
        Sound("vo/npc/male01/pain07.wav"),
        Sound("vo/npc/male01/pain08.wav"),
        Sound("vo/npc/male01/pain09.wav")
    },
    ["DeathSounds"] = {
        Sound("vo/npc/male01/no02.wav"),
        Sound("ambient/voices/citizen_beaten1.wav"),
        Sound("ambient/voices/citizen_beaten3.wav"),
        Sound("ambient/voices/citizen_beaten4.wav"),
        Sound("ambient/voices/citizen_beaten5.wav"),
        Sound("vo/npc/male01/pain07.wav"),
        Sound("vo/npc/male01/pain08.wav")
    }
}

VoiceSets["barney"] = {
    ["PainSoundsLight"] = {
        Sound("vo/npc/Barney/ba_pain02.wav"),
        Sound("vo/npc/Barney/ba_pain07.wav"),
        Sound("vo/npc/Barney/ba_pain04.wav")
    },
    ["PainSoundsMed"] = {
        Sound("vo/npc/Barney/ba_pain01.wav"),
        Sound("vo/npc/Barney/ba_pain08.wav"),
        Sound("vo/npc/Barney/ba_pain10.wav")
    },
    ["PainSoundsHeavy"] = {
        Sound("vo/npc/Barney/ba_pain05.wav"),
        Sound("vo/npc/Barney/ba_pain06.wav"),
        Sound("vo/npc/Barney/ba_pain09.wav")
    },
    ["DeathSounds"] = {
        Sound("vo/npc/Barney/ba_ohshit03.wav"),
        Sound("vo/npc/Barney/ba_no01.wav"),
        Sound("vo/npc/Barney/ba_no02.wav"),
        Sound("vo/npc/Barney/ba_pain03.wav")
    }
}

VoiceSets["female"] = {
    ["PainSoundsLight"] = {
        Sound("vo/npc/female01/pain01.wav"),
        Sound("vo/npc/female01/pain02.wav"),
        Sound("vo/npc/female01/pain03.wav")
    },
    ["PainSoundsMed"] = {
        Sound("vo/npc/female01/pain04.wav"),
        Sound("vo/npc/female01/pain05.wav"),
        Sound("vo/npc/female01/pain06.wav")
    },
    ["PainSoundsHeavy"] = {
        Sound("vo/npc/female01/pain07.wav"),
        Sound("vo/npc/female01/pain08.wav"),
        Sound("vo/npc/female01/pain09.wav")
    },
    ["DeathSounds"] = {
        Sound("vo/npc/female01/no01.wav"),
        Sound("vo/npc/female01/ow01.wav"),
        Sound("vo/npc/female01/ow02.wav"),
        Sound("vo/npc/female01/goodgod.wav"),
        Sound("ambient/voices/citizen_beaten2.wav")
    }
}

VoiceSets["alyx"] = {
    ["PainSoundsLight"] = {
        Sound("vo/npc/Alyx/gasp03.wav"),
        Sound("vo/npc/Alyx/hurt08.wav")
    },
    ["PainSoundsMed"] = {
        Sound("vo/npc/Alyx/hurt04.wav"),
        Sound("vo/npc/Alyx/hurt06.wav"),
        Sound("vo/Citadel/al_struggle07.wav"),
        Sound("vo/Citadel/al_struggle08.wav")
    },
    ["PainSoundsHeavy"] = {
        Sound("vo/npc/Alyx/hurt05.wav"),
        Sound("vo/npc/Alyx/hurt06.wav")
    },
    ["DeathSounds"] = {
        Sound("vo/npc/Alyx/no01.wav"),
        Sound("vo/npc/Alyx/no02.wav"),
        Sound("vo/npc/Alyx/no03.wav"),
        Sound("vo/Citadel/al_dadgordonno_c.wav"),
        Sound("vo/Streetwar/Alyx_gate/al_no.wav")
    }
}

VoiceSets["combine"] = {
    ["PainSoundsLight"] = {
        Sound("npc/combine_soldier/pain1.wav"),
        Sound("npc/combine_soldier/pain2.wav"),
        Sound("npc/combine_soldier/pain3.wav")
    },
    ["PainSoundsMed"] = {
        Sound("npc/metropolice/pain1.wav"),
        Sound("npc/metropolice/pain2.wav")
    },
    ["PainSoundsHeavy"] = {
        Sound("npc/metropolice/pain3.wav"),
        Sound("npc/metropolice/pain4.wav")
    },
    ["DeathSounds"] = {
        Sound("npc/combine_soldier/die1.wav"),
        Sound("npc/combine_soldier/die2.wav"),
        Sound("npc/combine_soldier/die3.wav")
    }
}

VoiceSets["monk"] = {
    ["PainSoundsLight"] = {
        Sound("vo/ravenholm/monk_pain01.wav"),
        Sound("vo/ravenholm/monk_pain02.wav"),
        Sound("vo/ravenholm/monk_pain03.wav"),
        Sound("vo/ravenholm/monk_pain05.wav")
    },
    ["PainSoundsMed"] = {
        Sound("vo/ravenholm/monk_pain04.wav"),
        Sound("vo/ravenholm/monk_pain06.wav"),
        Sound("vo/ravenholm/monk_pain07.wav"),
        Sound("vo/ravenholm/monk_pain08.wav")
    },
    ["PainSoundsHeavy"] = {
        Sound("vo/ravenholm/monk_pain09.wav"),
        Sound("vo/ravenholm/monk_pain10.wav"),
        Sound("vo/ravenholm/monk_pain12.wav")
    },
    ["DeathSounds"] = {
        Sound("vo/ravenholm/monk_death07.wav")
    }
}
function meta:GetSRVoiceLines(line_type)
    return VoicePacks[self.VoiceSet][line_type]
end

function meta:PlayDeathSound()
    if VoiceSets == nil or self.VoiceSet == "None" or self.VoiceSet == nil then return end

    local snds = spark_packs and self:GetSRVoiceLines(VOICE_EVENT.DEATH) or (VoiceSets[self.VoiceSet] and VoiceSets[self.VoiceSet].DeathSounds)
    if snds then
        self:EmitSound(snds[math.random(1, #snds)], 75, 100, 1, CHAN_VOICE)
    end
end

function meta:PlayPainSound()
    if VoiceSets == nil or self.VoiceSet == "None" or self.VoiceSet == nil then return end
    if self.NextPainSound and CurTime() < self.NextPainSound then return end

    local snds
    local set = spark_packs and nil or VoiceSets[self.VoiceSet]
    
    if spark_packs or set then
        local health = self:Health()
        if 70 <= health then
            snds = spark_packs and self:GetSRVoiceLines(VOICE_EVENT.PAIN_LIGHT) or set.PainSoundsLight
        elseif 35 <= health then
            snds = spark_packs and self:GetSRVoiceLines(VOICE_EVENT.PAIN_MED) or set.PainSoundsMed
        else
            snds = spark_packs and self:GetSRVoiceLines(VOICE_EVENT.PAIN_HEAVY) or set.PainSoundsHeavy
        end
    end

    if snds then
        local snd = snds[math.random(#snds)]
        if snd then
            self:EmitSound(snd, 70, 100, 1, CHAN_VOICE)
            self.NextPainSound = CurTime() + SoundDuration(snd) - 0.1
        end
    end
end

function meta:TraceLine(distance, mask, filter, start)
	start = start or self:GetShootPos()
	return util.TraceLine({start = start, endpos = start + self:GetAimVector() * distance, filter = filter or self, mask = mask, output = {}})
end

function meta:IsHolding()
	return self.player_pickup and self.player_pickup:IsValid()
end
meta.IsCarrying = meta.IsHolding

function meta:SetupHands(ply)
	local oldhands = self:GetHands()
	if IsValid(oldhands) then
		oldhands:Remove()
	end

	local hands = ents.Create("zm_hands")
	if IsValid(hands) then
		hands:DoSetup(self, ply)
		hands:Spawn()
	end
end

function meta:ShouldNotCollide(ent)
	if getmetatable(ent) == meta and P_Team(self) == P_Team(ent) then
		return true
	end

	return ent.bIsHolding
end

function meta:FlashlightIsOn()
	return self.m_bIsFlashLightOn or false
end

local M_Entity = FindMetaTable("Entity")
local E_GetTable = M_Entity.GetTable

local val
local pt
function meta:__index(key)
	val = meta[key]
	if val ~= nil then return val end

	val = M_Entity[key]
	if val ~= nil then return val end

	pt = E_GetTable(self)
	if pt then
		return pt[key]
	end
end

function meta:ToggleFlashlight()
	self:Flashlight(not self.m_bIsFlashLightOn)
end

function meta:Flashlight(isOn)
	if not isOn then isOn = nil end

	if SERVER then
        self:SetNW2Bool("m_bIsFlashLightOn",isOn)
    else
        self:ClientSetFlashlight(isOn)
    end
    
	self.m_bIsFlashLightOn = isOn
end

function meta:GetLastActivity()
    return self.m_flLastActivity or 0
end

function meta:IsCloseToAFK()
    return GetConVar("zm_sv_antiafk"):GetFloat() > 0 and (CurTime() - self:GetLastActivity()) > (GetConVar("zm_sv_antiafk"):GetFloat() * 0.8)
end

function meta:IsAFK()
    return GetConVar("zm_sv_antiafk"):GetFloat() > 0 and (CurTime() - self:GetLastActivity()) > GetConVar("zm_sv_antiafk"):GetFloat()
end

function meta:SetFlashlightBattery(amount, bForceSimulate)
    local oldbattery = self.m_iFlashlightBattery
    self.m_iFlashlightBattery = math.Clamp(amount, 0, 100)
    
    if oldbattery == self.m_iFlashlightBattery then return end
    
    if SERVER then
        if self.m_iFlashlightBattery <= 0 then
            self:Flashlight(false)
        end
        
        if bForceSimulate then
            self:SendLua("MySelf:SetFlashlightBattery(" .. amount .. ")")
        end
    end
end

function meta:SetOxygenLevel(amount, bForceSimulate)
    local oldoxygen = self.m_iOxygenLevel
    self.m_iOxygenLevel = math.Clamp(amount, 0, 100)
    
    if oldoxygen == self.m_iOxygenLevel then return end
    
    if SERVER and bForceSimulate then
        self:SendLua("MySelf:SetOxygenLevel(" .. amount .. ")")
    end
end

function meta:SetSkinReplacmentIndex(Index)
    self.bSkinReplacmentIndex = Index
    if SERVER then
        self:SetNW2Int("bSkinReplacmentIndex", Index)
    end
end

function meta:SetSkinReplacmentMat(Mat)
    self.bSkinReplacmentMat = Mat
    if SERVER then
        self:SetNW2Int("bSkinReplacmentMat", Mat)
    end
end

function meta:GetFlashlightBattery()
    return self.m_iFlashlightBattery or 0
end

function meta:GetOxygenLevel()
    return self.m_iOxygenLevel or 0
end

if not CLIENT then return end

local P_GetViewModel = meta.GetViewModel
local P_ShouldDrawLocalPlayer = meta.ShouldDrawLocalPlayer

local E_Meta = FindMetaTable("Entity")
local E_IsValid = E_Meta.IsValid
local E_GetCollisionGroup = E_Meta.GetCollisionGroup
local E_IsPlayer = E_Meta.IsPlayer
local E_GetAbsVelocity = E_Meta.GetAbsVelocity
local E_GetMoveType = E_Meta.GetMoveType

local A_Meta = FindMetaTable("Angle")
local A_Forward = A_Meta.Forward

local PT_Meta = FindMetaTable("ProjectedTexture")
local PT_SetNearZ = PT_Meta.SetNearZ
local PT_SetPos = PT_Meta.SetPos
local PT_SetAngles = PT_Meta.SetAngles
local PT_Update = PT_Meta.Update
local PT_SetLinearAttenuation = PT_Meta.SetLinearAttenuation
local PT_SetHorizontalFOV = PT_Meta.SetHorizontalFOV
local PT_SetVerticalFOV = PT_Meta.SetVerticalFOV

local Angle = Angle
local Lerp = Lerp
local CurTime = CurTime

local COLLISION_GROUP_DEBRIS = COLLISION_GROUP_DEBRIS
local COLLISION_GROUP_INTERACTIVE_DEBRIS = COLLISION_GROUP_INTERACTIVE_DEBRIS
local MOVETYPE_LADDER = MOVETYPE_LADDER

local util_TraceHull = util.TraceHull
local math_AngleDifference = math.AngleDifference
local math_Clamp = math.Clamp
local math_cos = math.cos
local math_sin = math.sin

local m_bUpdateFlashlight = false
local flDistCutoff = 128
local flOffsetY = 0
local m_flDistMod = 1

local function F_LerpAngle(StartAng, EndAng, Time)
	YawDif = math_AngleDifference(EndAng.yaw,StartAng.yaw) * Time
	RollDif = math_AngleDifference(EndAng.roll,StartAng.roll) * Time
	PitchDif = math_AngleDifference(EndAng.pitch,StartAng.pitch) * Time
	return Angle(StartAng.pitch+PitchDif, StartAng.yaw+YawDif, StartAng.roll+RollDif)
end

local function FlashlightTrace(ent)
	return ent ~= P_GetViewModel(MySelf) and hook.Call("ShouldCollide", GAMEMODE, MySelf, ent)
end

local function CalcFlashlight(ply, pos, angles, fov)
	ply:UpdateFlashlight(P_ShouldDrawLocalPlayer(ply) and pos + A_Forward(angles) * 12 or pos, angles)
end

function meta:ToggleFlashlight()
	self:SetupFlashlight()
end

local mat_flashlight = "effects/flashlight001"
local InitLightTeam = -1

function meta:SetupFlashlight()
	local flashlight = self:GetFlashlightEnt()
	if flashlight:IsValid() then 
		self:RemoveFlashlight()
		return
	end
	
	local light = ProjectedTexture()
	if light:IsValid() then
        light:SetEnableShadows(GetConVar("r_flashlightdepthtexture"):GetBool())
		light:SetNearZ(4)
        light:SetColor(color_white)
        light:SetTexture(mat_flashlight)
        light:SetFOV(60)
        light:SetFarZ(750)
    
		self:SetFlashlightEnt(light)
		InitLightTeam = self:Team()
		self:UpdateFlashlight(EyePos(), EyeAngles(), true)

		hook.Add("CalcView", "CalcView.Flashlight", CalcFlashlight, HOOK_MONITOR_HIGH)
	end
end

local OldEA,OldEP,OldEAT,LagEA
local flashlightTracef = {filter = FlashlightTrace,mins = Vector(-4, -4, -4),maxs = Vector(4, 4, 4),mask = bit.band(bit.bor(MASK_OPAQUE_AND_NPCS, CONTENTS_WINDOW), bit.bnot(CONTENTS_HITBOX)),output = {}}

function meta:UpdateFlashlight(pos, ang, force)
	if InitLightTeam~=P_Team(self) then -- Make sure super bright flashlight doesn't stay.
		self:ClientSetFlashlight(false)
		return
	end
	
	if force then
		OldEA = false
		OldEP = false
		OldEAT = false
		LagEA = false
	end
	
	local flashlight = self:GetFlashlightEnt()
	
	pos = pos + E_GetAbsVelocity(self) * 0.01
	
	if OldEP~=pos or OldEA~=ang or OldEAT then
		local ctime = CurTime()

		flashlightTracef.start = pos
		flashlightTracef.endpos = pos + (A_Forward(ang) * 750)
		local tr = util_TraceHull(flashlightTracef)
		
		local flDist = #(tr.HitPos - pos)
		if flDist < flDistCutoff then
			local bPlayerOnLadder = E_GetMoveType(self) == MOVETYPE_LADDER
			local flPullBackDist = bPlayerOnLadder and 40 or (flDistCutoff - flDist)
			m_flDistMod = Lerp(0.2, m_flDistMod, flPullBackDist)
		
			if not bPlayerOnLadder then
				flashlightTracef.endpos = pos - (A_Forward(ang) * (flPullBackDist - 0.1))
				tr = util_TraceHull(flashlightTracef)
				
				if tr.Hit then
					local flMaxDist = #(tr.HitPos - pos) - 0.1
					if m_flDistMod > flMaxDist then
						m_flDistMod = flMaxDist
					end
				end
			end
		else
			m_flDistMod = Lerp(0.2, m_flDistMod, 0)
		end
		
		pos = pos - (A_Forward(ang) * m_flDistMod)
		
		PT_SetNearZ(flashlight, 4 + m_flDistMod)
		PT_SetPos(flashlight, pos)

		OldEP = pos
		
		if OldEA ~= ang then
			if not LagEA then
				LagEA = ang
				OldEAT = false
			else
				OldEAT = ctime + 0.5
				LagEA = F_LerpAngle(LagEA, ang, 0.5)
			end
			
			PT_SetAngles(flashlight, LagEA)
			OldEA = ang
		elseif OldEAT then
			if ctime > (OldEAT or 0) then
				OldEAT = false
				PT_SetAngles(flashlight, ang)
			else
				LagEA = F_LerpAngle(LagEA, ang, 1.0 - (OldEAT - ctime))
				PT_SetAngles(flashlight, LagEA)
			end
		end

		m_bUpdateFlashlight = true
	end
    
    local flBatteryPower = self:GetFlashlightBattery()
    if flBatteryPower <= 15 then
        local flScale = 0
        if flBatteryPower >= 0 then
            flScale = flBatteryPower <= 4.5 and math.SimpleSplineRemapVal(flBatteryPower, 4.5, 0, 1, 0) or 1
        else
            flScale = math.SimpleSplineRemapVal(flBatteryPower, 10, 4.8, 1, 0)
        end
        
        flScale = math.Clamp(flScale, 0, 1)

        if flScale < 0.55 then
            local flFlicker = math.cos(CurTime() * 6 ) * math.sin( CurTime() * 15)
            
            if flFlicker > 0.25 and flFlicker < 0.75 then
                PT_SetLinearAttenuation(flashlight, GAMEMODE.FlashlightLinear * flScale)
            else
                PT_SetLinearAttenuation(flashlight, 0)
            end
        else
            local flNoise = math.cos(CurTime() * 7) * math.sin(CurTime() * 25)
            PT_SetLinearAttenuation(flashlight, GAMEMODE.FlashlightLinear * flScale + 1.5 * flNoise)
        end

        PT_SetHorizontalFOV(flashlight, GAMEMODE.FlashlightFOV - (16 * (1-flScale)))
        PT_SetVerticalFOV(flashlight, GAMEMODE.FlashlightFOV - (16 * (1-flScale)))
        
        m_bUpdateFlashlight = true
    end
	
	if m_bUpdateFlashlight then
		m_bUpdateFlashlight = false
		PT_Update(flashlight)
	end
end

function meta:ClientSetFlashlight(bOn)
    if self:IsSurvivor() and self:Alive() then
        self:EmitSound(bOn and "HL2Player.FlashlightOn" or "HL2Player.FlashlightOff")
        
        if self==MySelf then
            if bOn then
                self:SetupFlashlight()
            else
                self:RemoveFlashlight()
            end
        end
    end
end

function meta:RemoveFlashlight()
	local flashlight = self:GetFlashlightEnt()
	if flashlight:IsValid() then
		hook.Remove("CalcView", "CalcView.Flashlight")
		flashlight:Remove() 
	end
end

function meta:GetFlashlightEnt()
	return self.m_flashlight or NULL
end

function meta:SetFlashlightEnt(ent)
	self.m_flashlight = ent
end