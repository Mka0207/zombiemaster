-- How is this faster than the one Marco did? - FMX
-- Animations are heavily optimized.

local ACT_MP_STAND_IDLE = ACT_MP_STAND_IDLE
local ACT_MP_RUN = ACT_MP_RUN
local ACT_MP_WALK = ACT_MP_WALK
local ACT_MP_JUMP = ACT_MP_JUMP
local ACT_MP_CROUCHWALK = ACT_MP_CROUCHWALK
local ACT_MP_CROUCH_IDLE = ACT_MP_CROUCH_IDLE
local GESTURE_SLOT_JUMP = GESTURE_SLOT_JUMP
local ACT_LAND = ACT_LAND
local MOVETYPE_NOCLIP = MOVETYPE_NOCLIP
local math_min = math.min
local math_max = math.max
local math_Approach = math.Approach
local GESTURE_SLOT_VCD = GESTURE_SLOT_VCD
local ACT_GMOD_IN_CHAT = ACT_GMOD_IN_CHAT
local CLIENT = CLIENT
local PLAYERANIMEVENT_FLINCH_HEAD = PLAYERANIMEVENT_FLINCH_HEAD
local PLAYERANIMEVENT_ATTACK_PRIMARY = PLAYERANIMEVENT_ATTACK_PRIMARY
local FL_ANIMDUCKING = FL_ANIMDUCKING
local GESTURE_SLOT_ATTACK_AND_RELOAD = GESTURE_SLOT_ATTACK_AND_RELOAD
local ACT_MP_ATTACK_CROUCH_PRIMARYFIRE = ACT_MP_ATTACK_CROUCH_PRIMARYFIRE
local ACT_MP_ATTACK_STAND_PRIMARYFIRE = ACT_MP_ATTACK_STAND_PRIMARYFIRE
local ACT_VM_PRIMARYATTACK = ACT_VM_PRIMARYATTACK
local PLAYERANIMEVENT_ATTACK_SECONDARY = PLAYERANIMEVENT_ATTACK_SECONDARY
local ACT_VM_SECONDARYATTACK = ACT_VM_SECONDARYATTACK
local PLAYERANIMEVENT_RELOAD = PLAYERANIMEVENT_RELOAD
local ACT_MP_RELOAD_CROUCH = ACT_MP_RELOAD_CROUCH
local ACT_MP_RELOAD_STAND = ACT_MP_RELOAD_STAND
local PLAYERANIMEVENT_JUMP = PLAYERANIMEVENT_JUMP
local ACT_INVALID = ACT_INVALID
local CurTime = CurTime
local IsValid = IsValid
local FrameTime = FrameTime

local M_Player = FindMetaTable("Player")
local M_Entity = FindMetaTable("Entity")
local P_Team = GetPlayerTeam
local P_AnimRestartGesture = M_Player.AnimRestartGesture
local P_AnimRestartMainSequence = M_Player.AnimRestartMainSequence
local P_Crouching = M_Player.Crouching
local P_Alive = M_Player.Alive
local P_TranslateWeaponActivity = M_Player.TranslateWeaponActivity
local P_AnimRestartMainSequence = M_Player.AnimRestartMainSequence 
local P_AnimResetGestureSlot = M_Player.AnimResetGestureSlot
local P_IsPlayingTaunt = M_Player.IsPlayingTaunt
local P_IsTyping = M_Player.IsTyping
local P_IsTalking = M_Player.IsTalking
local P_AnimSetGestureWeight  = M_Player.AnimSetGestureWeight
local E_IsFlagSet = M_Entity.IsFlagSet
local E_OnGround = M_Entity.OnGround
local E_GetTable = M_Entity.GetTable
local E_WaterLevel = M_Entity.WaterLevel
local E_SetPlaybackRate = M_Entity.SetPlaybackRate
local E_GetAbsVelocity = M_Entity.GetAbsVelocity
local E_IsValid = M_Entity.IsValid
local E_GetLocalAngularVelocity = M_Entity.GetLocalAngularVelocity
local E_GetClass = M_Entity.GetClass
-- These don't get destroyed by __index like player and entity but why not have them here.
local M_Vector = FindMetaTable("Vector")
local V_Length2D = M_Vector.Length2D
local V_Length2DSqr = M_Vector.Length2DSqr
local V_LengthSqr = M_Vector.LengthSqr
local P_IsCarrying

local function ApplyLocalFunctions()
    P_IsCarrying = M_Player.IsCarrying
end
hook.Add( "Initialize", "Animations.Initialize", ApplyLocalFunctions )
hook.Add( "OnReloaded", "Animations.OnReloaded", ApplyLocalFunctions )

local CS_GroundEnts

if CLIENT then
	CS_GroundEnts = {}

    hook.Add("SetupNetworkingCallbacks", "SetupNetworkingCallbacks.GE", function()
        GAMEMODE:AddNetworkingCallbacks("GroundEntity",function(e,x)
            if e~=MySelf then
                rawset(CS_GroundEnts,e,x)
            end
        end)
    end)
	
	hook.Add("PlayerDisconnected", "PlayerDisconnected.CleanupGE", function(pl)
		rawset(CS_GroundEnts,pl,nil)
	end)
end

local onground, tab, len2d, waterlevel, ideal, override, pt

local m_bWasOnGround = {}
local m_bJumping = {}
local m_bFirstJumpFrame = {}
local m_flJumpStartTime = {}
local m_fGroundTime = {}
function GM:CalcMainActivity(pl, velocity)
	if CLIENT and pl~=MySelf then
		local e = rawget(CS_GroundEnts,pl)
		if e and E_IsValid(e) then
            local ev
            if E_GetClass(e) == "func_rotating" then
                ev = Vector(E_GetLocalAngularVelocity(e):Unpack())
            else
                ev = E_GetAbsVelocity(e)
            end
            
			local ne = V_LengthSqr(ev)
			if ne>1 then
				local nw = velocity-ev
				if V_Length2DSqr(nw)<(ne*0.5) then
					velocity:Zero()
				else
					velocity = nw
				end
			end
		end
	end
    
	-- Handle landing
	onground = E_OnGround(pl)
	if onground and not m_bWasOnGround[pl] then
		P_AnimRestartGesture(pl, GESTURE_SLOT_JUMP, ACT_LAND, true)
		m_bWasOnGround[pl] = true
	end
	--

	-- Handle jumping
	-- airwalk more like hl2mp, we airwalk until we have 0 velocity, then it's the jump animation
	-- underwater we're alright we airwalking
	waterlevel = E_WaterLevel(pl)
    if m_bJumping[pl] then
		if m_bFirstJumpFrame[pl] then
			m_bFirstJumpFrame[pl] = false
			P_AnimRestartMainSequence(pl)
		end

		if waterlevel >= 2 or CurTime() - m_flJumpStartTime[pl] > 0.2 and onground then
			m_bJumping[pl] = false
			m_fGroundTime[pl] = nil
			P_AnimRestartMainSequence(pl)
		else
			return ACT_MP_JUMP, -1
		end
	elseif not onground and waterlevel <= 0 then
		if not m_fGroundTime[pl] then
			m_fGroundTime[pl] = CurTime()
		elseif CurTime() > m_fGroundTime[pl] and V_Length2D(velocity) < 0.5 then
			m_bJumping[pl] = true
			m_bFirstJumpFrame[pl] = false
			m_flJumpStartTime[pl] = 0
		end
	end
	--

	-- Handle ducking
	if P_Crouching(pl) then
		if V_Length2DSqr(velocity) >= 1 then
			return ACT_MP_CROUCHWALK, -1
		end

		return ACT_MP_CROUCH_IDLE, -1
	end
	--

	-- Handle swimming
	if not onground and waterlevel >= 2 then
		return ACT_MP_SWIM, -1
	end
	--

	len2d = V_Length2DSqr(velocity)
	if len2d >= 22500 then -- 150^2
		return ACT_MP_RUN, -1
	end

	if len2d >= 1 then
		return ACT_MP_WALK, -1
	end

	return ACT_MP_STAND_IDLE, -1
end

--local wep
local len
local rate
local ChatGestureWeight = {}
function GM:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	if CLIENT and pl~=MySelf then
		local e = rawget(CS_GroundEnts,pl)
		if e and E_IsValid(e) then
            local ev
            if E_GetClass(e) == "func_rotating" then
                ev = Vector(E_GetLocalAngularVelocity(e):Unpack())
            else
                ev = E_GetAbsVelocity(e)
            end
            
			local ne = V_LengthSqr(ev)
			if ne>1 then
				local nw = velocity-ev
				if V_Length2DSqr(nw)<(ne*0.5) then
					velocity:Zero()
				else
					velocity = nw
				end
			end
		end
	end

	len = V_LengthSqr(velocity)

	if len > 1 then
		rate = math_min(len / maxseqgroundspeed ^ 2, 2)
	else
		rate = 1
	end

	-- if we're under water we want to constantly be swimming..
	if E_WaterLevel(pl) >= 2 then
		rate = math_max(rate, 0.5)
	end

	E_SetPlaybackRate(pl, rate)

	if CLIENT then
        ChatGestureWeight[pl] = ChatGestureWeight[pl] or 0

        if P_IsPlayingTaunt(pl) then return end

        if P_IsTyping(pl) or P_IsTalking(pl) then
            ChatGestureWeight[pl] = math_Approach(ChatGestureWeight[pl], 1, FrameTime() * 5.0)
        else
            ChatGestureWeight[pl] = math_Approach(ChatGestureWeight[pl], 0, FrameTime() * 5.0)
        end

        if ChatGestureWeight[pl] > 0 then
            P_AnimRestartGesture(pl, GESTURE_SLOT_VCD, ACT_GMOD_IN_CHAT, true)
            P_AnimSetGestureWeight(pl, GESTURE_SLOT_VCD, ChatGestureWeight[pl])
        end
	end
end

local eact
function GM:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_FLINCH_HEAD then
		return P_DoFlinchAnim(pl, data)
	end

	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		if E_IsFlagSet(pl, FL_ANIMDUCKING) then
			P_AnimRestartGesture(pl, GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_MP_ATTACK_CROUCH_PRIMARYFIRE, true)
		else
			P_AnimRestartGesture(pl, GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_MP_ATTACK_STAND_PRIMARYFIRE, true)
		end

		return ACT_VM_PRIMARYATTACK
	elseif event == PLAYERANIMEVENT_ATTACK_SECONDARY then
		return ACT_VM_SECONDARYATTACK
	elseif event == PLAYERANIMEVENT_RELOAD then
		if E_IsFlagSet(pl, FL_ANIMDUCKING) then
			P_AnimRestartGesture(pl, GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_MP_RELOAD_CROUCH, true)
		else
			P_AnimRestartGesture(pl, GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_MP_RELOAD_STAND, true)
		end

		return ACT_INVALID
	elseif event == PLAYERANIMEVENT_JUMP then
		m_bJumping[pl] = true
		m_bFirstJumpFrame[pl] = true
		m_flJumpStartTime[pl] = CurTime()

		P_AnimRestartMainSequence(pl)

		return ACT_INVALID
	elseif event == PLAYERANIMEVENT_CANCEL_RELOAD then
		P_AnimResetGestureSlot(pl, GESTURE_SLOT_ATTACK_AND_RELOAD)
		return ACT_INVALID
	end
end

local CarryingActivityTranslate = {}
CarryingActivityTranslate[ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_SLAM
CarryingActivityTranslate[ACT_MP_WALK] = ACT_HL2MP_IDLE_SLAM + 1
CarryingActivityTranslate[ACT_MP_RUN] = ACT_HL2MP_IDLE_SLAM + 2
CarryingActivityTranslate[ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_SLAM + 3
CarryingActivityTranslate[ACT_MP_CROUCHWALK] = ACT_HL2MP_IDLE_SLAM + 4
CarryingActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE] = ACT_HL2MP_IDLE_SLAM + 5
CarryingActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = ACT_HL2MP_IDLE_SLAM + 5
CarryingActivityTranslate[ACT_MP_RELOAD_STAND] = ACT_HL2MP_IDLE_SLAM + 6
CarryingActivityTranslate[ACT_MP_RELOAD_CROUCH] = ACT_HL2MP_IDLE_SLAM + 6
CarryingActivityTranslate[ACT_MP_JUMP] = ACT_HL2MP_JUMP_SLAM
CarryingActivityTranslate[ACT_MP_SWIM] = ACT_HL2MP_IDLE_SLAM + 9
CarryingActivityTranslate[ACT_LAND] = ACT_LAND

local IdleActivity = ACT_HL2MP_IDLE
local IdleActivityTranslate = {}
IdleActivityTranslate[ACT_MP_STAND_IDLE] = IdleActivity
IdleActivityTranslate[ACT_MP_WALK] = IdleActivity + 1
IdleActivityTranslate[ACT_MP_RUN] = IdleActivity + 2
IdleActivityTranslate[ACT_MP_CROUCH_IDLE] = IdleActivity + 3
IdleActivityTranslate[ACT_MP_CROUCHWALK] = IdleActivity + 4
IdleActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE] = IdleActivity + 5
IdleActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = IdleActivity + 5
IdleActivityTranslate[ACT_MP_RELOAD_STAND] = IdleActivity + 6
IdleActivityTranslate[ACT_MP_RELOAD_CROUCH] = IdleActivity + 6
IdleActivityTranslate[ACT_MP_JUMP] = ACT_HL2MP_JUMP_SLAM
IdleActivityTranslate[ACT_MP_SWIM] = IdleActivity + 9
IdleActivityTranslate[ACT_LAND] = ACT_LAND

local newact
function GM:TranslateActivity(pl, act)
	if P_IsCarrying(pl) then
		return CarryingActivityTranslate[act] or act
	end

	newact = P_TranslateWeaponActivity(pl, act)
	if act == newact then
		return IdleActivityTranslate[act]
	end

	return newact
end
