local meta = FindMetaTable("Entity")
if not meta then return end

local IS_SERVER_RUNNING = SERVER and true or false
local IS_CLIENT_RUNNING = CLIENT and true or false

function meta:SetModelDelayed(delay, mdl)
	timer.Simple(delay, function() if IsValid(self) then self:SetModel(mdl) end end)
end

function meta:IsPointInBounds(vecWorldPt)
	local vecLocalSpace = self:WorldToLocal(vecWorldPt)
	local m_vecMins = self:OBBMins()
	local m_vecMaxs = self:OBBMaxs()

	return (vecLocalSpace.x >= m_vecMins.x and vecLocalSpace.x <= m_vecMaxs.x) and
			(vecLocalSpace.y >= m_vecMins.y and vecLocalSpace.y <= m_vecMaxs.y) and
			(vecLocalSpace.z >= m_vecMins.z and vecLocalSpace.z <= m_vecMaxs.z)
end

function meta:RandomPointInBounds(vecNormalizedMins, vecNormalizedMaxs)
	local vecNormalizedSpace = Vector(math.Rand(vecNormalizedMins.x, vecNormalizedMaxs.x), math.Rand(vecNormalizedMins.y, vecNormalizedMaxs.y), math.Rand(vecNormalizedMins.z, vecNormalizedMaxs.z))
	return self:LocalToWorld(vecNormalizedSpace)
end

function meta:SetClassName(name)
	self:SetDTString(0, name)
end

function meta:GetClassName()
	return self:GetDTString(0)
end

function meta:GetBonePositionMatrixed(index)
	local matrix = self:GetBoneMatrix(index)
	if matrix then
		return matrix:GetTranslation(), matrix:GetAngles()
	end

	return self:GetPos(), self:GetAngles()
end

function meta:NearestBone(pos)
	local count = self:GetBoneCount()
	if count == 0 then return end

	local nearest
	local nearestdist

	for boneid = 1, count - 1 do
		local bonepos, boneang = self:GetBonePositionMatrixed(boneid)
		local dist = bonepos:Distance(pos)

		if not nearest or dist < nearestdist then
			nearest = boneid
			nearestdist = dist
		end
	end

	return nearest
end

local string_sub = string.sub
function meta:IsAPhysicsProp()
	if not IsValid(self) then return false end

	if not self.CheckedIsPhysProp then
		self.CheckedIsPhysProp = (string_sub(self:GetClass(), 1, 12) == "prop_physics" or string_sub(self:GetClass(), 1, 12) == "func_physbox") and 1 or 0
	end
	return self.CheckedIsPhysProp == 1
end

local util_TraceHull = util.TraceHull
local util_TraceLine = util.TraceLine

local CS_MASK_SHOOT = bit.bor(MASK_SOLID, CONTENTS_DEBRIS, CONTENTS_HITBOX)

local M_Player = FindMetaTable("Player")
local P_LagCompensation = M_Player.LagCompensation
local P_Team = GetPlayerTeam

local E_IsValid = meta.IsValid
local E_GetTable = meta.GetTable

local E_GetParent = meta.GetParent
local E_GetOwner = meta.GetOwner

local bit_band = bit.band
local math_Rand = math.Rand
local math_Clamp = math.Clamp
local util_Effect = util.Effect
local util_PointContents = util.PointContents

local EF_M = FindMetaTable("CEffectData")
local EF_SetOrigin = EF_M.SetOrigin
local EF_SetEntity = EF_M.SetEntity
local EF_SetHitBox = EF_M.SetHitBox
local EF_SetAttachment = EF_M.SetAttachment
local EF_SetStart = EF_M.SetStart
local EF_SetScale = EF_M.SetScale
local EF_SetSurfaceProp = EF_M.SetSurfaceProp
local EF_SetDamageType = EF_M.SetDamageType
local EF_SetNormal = EF_M.SetNormal
local EF_SetFlags = EF_M.SetFlags

local A_Meta = FindMetaTable("Angle")
local A_Up = A_Meta.Up
local A_Set = A_Meta.Set
local A_Forward = A_Meta.Forward
local A_RotateAroundAxis = A_Meta.RotateAroundAxis
local A_Right = A_Meta.Right

local V_Meta = FindMetaTable("Vector")
local V_Angle = V_Meta.Angle

local temp_angle = Angle(0, 0, 0)
local temp_ignore_team
local temp_has_spread
local spread_multi_min = 0.01 * 50 -- For RNG. When you reduce the number of that value and it make more accurate.
local spread_multi_max = 0.02 * 50 -- Thats seem equal to (/ 50) and fast than divide.
local temp_shooter = NULL
local temp_attacker = NULL
local attacker_player
local temp_pen_ents = {}
local temp_multishot_ignore_ents = {}

local function BaseBulletFilter(ent)
	if ent == temp_shooter
		or ent == temp_attacker
		or EntityIsPlayer(ent) and P_Team(ent) == temp_ignore_team
		or temp_multishot_ignore_ents[ent]
		or temp_pen_ents[ent] then
			return false
	end

	local e_tb = E_GetTable(ent)

	if e_tb.OnlyOwner then
		return E_GetOwner(ent) == temp_shooter
	end

	if e_tb.NeverAlive or e_tb.IgnoreBullets and (not e_tb.IgnoreBulletsBypassable or not BYPASS_BULLET_IGNORE) or e_tb.RealProjectile then
		return false
	end

	return true
end

-- Trace struct
local bullet_trace = {mask = MASK_SHOT, output = {}, filter = BaseBulletFilter}

-- Water stuff
local bullet_water_tr = {}
local CONTENTS_LIQUID = bit.bor(CONTENTS_WATER, CONTENTS_SLIME)
local MASK_SHOT_HIT_WATER = bit.bor(MASK_SHOT, CONTENTS_LIQUID)

local function HandleShotImpactingWater(damage)
	-- Trace again with water enabled
	bullet_trace.mask = MASK_SHOT_HIT_WATER
	bullet_trace.output = bullet_water_tr
	local tr = util_TraceLine(bullet_trace)
	bullet_trace.output = tr
	bullet_trace.mask = MASK_SHOT

	if bullet_water_tr.AllSolid then return false end

	local contents = util_PointContents(bullet_water_tr.HitPos - bullet_water_tr.HitNormal * 0.1)
	if bit_band(contents, CONTENTS_LIQUID) == 0 then return false end

	if IsFirstTimePredicted() then
		local effectdata = EffectData()
		EF_SetOrigin(effectdata, bullet_water_tr.HitPos)
		EF_SetNormal(effectdata, bullet_water_tr.HitNormal)
		EF_SetScale(effectdata, math_Clamp(damage * 0.25, 5, 30))
		EF_SetFlags(effectdata, bit_band(contents, CONTENTS_SLIME) ~= 0 and 1 or 0)
		util_Effect("gunshotsplash", effectdata)
	end

	return true
end

local wspawn = Entity(0)
local function CheckFHB(tr)
	local ent = tr.Entity
	if not ent or ent == wspawn then return end

	if E_IsValid(ent) and E_GetTable(ent).FHB then
		tr.Entity = E_GetParent(ent)
	end
end

local DM = FindMetaTable("CTakeDamageInfo")
local DMG_SetDamage = DM.SetDamage
local DMG_GetDamage = DM.GetDamage
local DMG_SetDamagePosition = DM.SetDamagePosition
local DMG_SetDamageForce = DM.SetDamageForce
local DMG_SetAttacker = DM.SetAttacker
local DMG_SetInflictor = DM.SetInflictor
local DMG_SetDamageType = DM.SetDamageType

local has_hit_world = false
local head_hitbox = false
local math_randomseed = math.randomseed

local function do_special_tracers(ent, tr, tracerlist)
	local eff = EffectData()
	eff:SetOrigin(tr.HitPos)
	eff:SetEntity(ent)

	for k, v in ipairs(tracerlist) do
		eff:SetFlags(v)
		util.Effect("tracer_bullet_rounds", eff)
	end
end

local function EffectClientBullets(self, hitwater, rag_impact, use_impact, use_tracer, src, attacker, ent, tr, tracer, ath_ent, ath_id, tracer_rounds_list, noattachtowep)
	if IS_SERVER_RUNNING and not FORCE_B_EFFECT then
		return -- Keep it clientside.
	end

	local effectdata = EffectData()
	EF_SetOrigin(effectdata, tr.HitPos)
	EF_SetStart(effectdata, src)
	EF_SetNormal(effectdata, tr.HitNormal)

	if hitwater then
		-- We may not impact, but we DO need to affect ragdolls on the client
		if rag_impact then
			util_Effect("RagdollImpact", effectdata, true, false)
		end
	elseif use_impact and not tr.HitSky and tr.Fraction < 1 then
		EF_SetSurfaceProp(effectdata, tr.SurfaceProps)
		EF_SetDamageType(effectdata, DMG_BULLET)
		EF_SetHitBox(effectdata, tr.HitBox)
		EF_SetEntity(effectdata, ent)
		util_Effect("Impact", effectdata)
	end

	if use_tracer then
		if not noattachtowep and EntityIsPlayer(self) then
			local wep = self:GetActiveWeapon()
			if E_IsValid(wep) then
				EF_SetFlags(effectdata, 0x0003) --TRACER_FLAG_USEATTACHMENT + TRACER_FLAG_WHIZ
				EF_SetEntity(effectdata, ath_ent or wep)
				EF_SetAttachment(effectdata, ath_id or 1)
			end
		else
			EF_SetEntity(effectdata, self)
			EF_SetFlags(effectdata, 0x0001) -- TRACER_FLAG_WHIZ
		end
		EF_SetScale(effectdata, 5000) -- Tracer travel speed

		if IS_SERVER_RUNNING and not FORCE_B_EFFECT then
			SuppressHostEvents(self)
		end
		util_Effect(tracer or "Tracer", effectdata, true, false)
		if IS_SERVER_RUNNING and not FORCE_B_EFFECT then
			SuppressHostEvents(NULL)
		end
	end

	if IS_CLIENT_RUNNING and tracer_rounds_list then
		local wep
		if EntityIsPlayer(self) then
			wep = self:GetActiveWeapon()
		else
			wep = self
		end

		do_special_tracers(wep, tr, tracer_rounds_list)
	end
end

local pen_condition_met = true
local math_max = math.max
local math_min = math.min
local math_cos = math.cos
local math_sin = math.sin
local hullvec = Vector(1, 1, 1)

if CLIENT then
	-- Tracer effect
	local client_trace_t = {mask = MASK_SHOT, filter = BaseBulletFilter, output = {}}
	hook.Add("DoAnimationEvent", "DoAnimationEvent.FireBulletEffects", function(pl, event, data)
		if GAMEMODE.IgnorePlayersFireBulletEffect then return end

		if event == PLAYERANIMEVENT_ATTACK_PRIMARY and pl ~= MySelf then
			local wep = pl:GetActiveWeapon()
			if wep and E_IsValid(wep) and not wep.IsMelee and wep.Primary and wep.GetCone and wep.ShootBullets and not wep.IsAProjectile then
				local src = pl:GetShootPos()
				local dir = pl:GetAimVector()
				local spread = (wep.ConeMax or 2) * 0.5 -- estimate
				local base_ang = V_Angle(dir)
				local pattern = wep.SpreadPattern

				temp_shooter = pl
				temp_attacker = pl
				temp_ignore_team = P_Team(pl)

				for i = 0, wep.Primary.NumShots - 1 do
					-- SPREAD
					if pattern and pattern[i + 1] then
						local pattern_x, pattern_y = pattern[i + 1][1], pattern[i + 1][2]

						A_Set(temp_angle, base_ang)
						A_RotateAroundAxis(temp_angle, A_Forward(temp_angle), pattern_x)
						A_RotateAroundAxis(temp_angle, A_Up(temp_angle), pattern_y * spread)

						dir = A_Forward(temp_angle)
					elseif spread > 0 then
						local classic_spread = spread * math_Rand(0, math_Rand(spread_multi_min, spread_multi_max))
						local spread_360_rng = math_Rand(-360, 360) -- :the: 360 RNG spread
						local make_circle_x = math_cos(spread_360_rng) * classic_spread
						local make_circle_y = math_sin(spread_360_rng) * classic_spread

						dir = A_Forward(base_ang) + make_circle_x * A_Right(base_ang) + make_circle_y * A_Up(base_ang)
					end

					client_trace_t.start = src
					client_trace_t.endpos = src + dir * 10000

					local cl_tr = util.TraceLine(client_trace_t)
					if cl_tr then
						local effectdata = EffectData()
							EF_SetOrigin(effectdata, cl_tr.HitPos)
							EF_SetStart(effectdata, src)
							EF_SetNormal(effectdata, cl_tr.HitNormal)
							EF_SetFlags(effectdata, 0x0003)
							EF_SetEntity(effectdata, wep)
							EF_SetAttachment(effectdata, 1)
							EF_SetScale(effectdata, 5000) -- Tracer travel speed
						util_Effect(wep.TracerName or "Tracer", effectdata, true, false)
					end
				end
			end
		end
	end)
end

local is_player_lagcompensating = false
local function WantLagCompensationOnEntity(start_lag, hit_own_team, distance)
	if is_player_lagcompensating and start_lag then return end -- because of bullet callback

	if not DO_BULLET_LAG_COMP then return end -- was it set?
	if not attacker_player then return end -- attacker is not player..

	if IS_SERVER_RUNNING and GMUTIL_AttackerLagCompensationInfos then
		if not start_lag then -- FINISH LAG COMPENSATION
			GMUTIL_AttackerLagCompensationInfos(temp_attacker:EntIndex(), false, 0)
		else -- START LAG COMPENSATION
			GMUTIL_AttackerLagCompensationInfos(temp_attacker:EntIndex(), hit_own_team, distance * 1.5)
		end
	end

	is_player_lagcompensating = start_lag
	P_LagCompensation(temp_attacker, start_lag)
end

local damage_list, has_damage_to_do = {}, false
local function EntityDamageLogic(tr, bulletinfo, damageinfo, use_damage, damage_multiplier)
	local ent = tr.Entity
	if E_IsValid(ent) and use_damage then
		if EntityIsPlayer(ent) then
			if IS_SERVER_RUNNING then
				ent:SetLastHitGroup(tr.HitGroup)
			end
		elseif temp_attacker:IsValidPlayer() then
			local phys = ent:GetPhysicsObject()
			if ent:GetMoveType() == MOVETYPE_VPHYSICS and phys:IsValid() and phys:IsMoveable() then
				ent:SetPhysicsAttacker(temp_attacker)
			end
		end

		if IS_SERVER_RUNNING then
			has_damage_to_do = true

			local cur_damage = damage_list[ent]
			local ent_player = EntityIsPlayer(ent)
			local ent_npc = ent:IsNPC()
			local ent_nextbot = ent:IsNextBot()

			if ent_player then
				gamemode.Call("ScalePlayerDamage", ent, tr.HitGroup, damageinfo)
			elseif ent_npc then
				gamemode.Call("NPCTraceAttack", ent, damageinfo, bulletinfo.dir, tr)
			end

			if not cur_damage then
				cur_damage = {
					Info = damageinfo,
					Pos = tr.HitPos,
					Trace = tr,
					Damage = DMG_GetDamage(damageinfo) * (damage_multiplier or 1),
					Hits = 1
				}

				damage_list[ent] = cur_damage
			else
				cur_damage.Damage = cur_damage.Damage + DMG_GetDamage(damageinfo)
				cur_damage.Hits = cur_damage.Hits + 1

				if (ent_player or ent_npc or ent_nextbot) and cur_damage.Damage > ent:Health() * 1.5 then
					temp_multishot_ignore_ents[ent] = true
				end
			end
		end
	end
end

-- Make TraceEngine...
local function TracePenetration(tracestruct, ishull, function_output)
	if not tracestruct then return end
	if not function_output then return end

	if IS_SERVER_RUNNING and UTIL_TLPenetration then
		if tracestruct.ShouldTraceResultTable then
			local trtbl = UTIL_TLPenetration(tracestruct)
			if trtbl then
				for i = 0, #trtbl do
					local tr = trtbl[i]
					if not tr then continue end

					local trent = tr.Entity
					if E_IsValid(trent) then
						temp_pen_ents[trent] = true -- filter the entity in last trace
					end

					function_output(i, tr.Contents, tr.StartSolid, tr.Fraction, tr.FractionLeftSolid, tr.AllSolid, tr.HitNormal, tr.HitPos, tr.Normal, tr.HitBox, tr.HitGroup, tr.SurfaceFlags, tr.SurfaceProps, tr.PhysicsBone, trent)
				end
			end
		else -- This one is fastest because of tables...
			tracestruct.trace_output_list = function_output
			UTIL_TLPenetration(tracestruct)

			return
		end
	end

	for i = 0, (tracestruct.MaxPenetration or 6) do
		local tr = ishull and util_TraceHull(tracestruct) or util_TraceLine(tracestruct)
		local trent = tr.Entity

		if E_IsValid(trent) then
			temp_pen_ents[trent] = true -- filter the entity in last trace
		end

		function_output(i, tr.Contents, tr.StartSolid, tr.Fraction, tr.FractionLeftSolid, tr.AllSolid, tr.HitNormal, tr.HitPos, tr.Normal, tr.HitBox, tr.HitGroup, tr.SurfaceFlags, tr.SurfaceProps, tr.PhysicsBone, trent)
	end
end

-- In FireBullet stuff...
local bulletinfo_t = nil
local damageinfo = nil
local bore_pens = 0
local bore_val = nil
local inflictortbl = nil

-- TraceResult Penetration...
local tr_pens = {}
local firebullet_has_to_stop = false

-- TraceExitResult Penetration...
local trace_exit_pens = 0
local tr_pens_exit = {}
local ExitToEnterWorldDistance = 1

-- FireBullet Effect
local use_tracer = true
local use_impact = true
local use_ragdoll_impact = true
local use_damage = true
local do_effects = true
local hitwater = false

local function TraceExitResult_Penetration(index, contents, startsolid, fraction, fractionleftsolid, allsolid, hitnormal, hitpos, normal, hitbox, hitgroup, surfaceflags, surfaceprops, physbone, entity)
	-- Setup trace so can sent to bullet callback etc...
	if IS_SERVER_RUNNING and GMUTIL_TLPenetration then
		tr_pens_exit.Contents = contents
		tr_pens_exit.StartSolid = startsolid
		tr_pens_exit.Fraction = fraction
		tr_pens_exit.FractionLeftSolid = fractionleftsolid
		tr_pens_exit.Hit = fraction < 1
		tr_pens_exit.AllSolid = allsolid
		tr_pens_exit.HitNormal = hitnormal
		tr_pens_exit.HitPos = hitpos
		tr_pens_exit.Normal = normal
		tr_pens_exit.HitBox = hitbox
		tr_pens_exit.HitGroup = hitgroup
		tr_pens_exit.SurfaceFlags = surfaceflags
		tr_pens_exit.SurfaceProps = surfaceprops
		tr_pens_exit.HitSky = bit.band(surfaceflags, SURF_SKY) == SURF_SKY
		tr_pens_exit.PhysicsBone = physbone
		tr_pens_exit.HitWorld = entity == Entity(0)
		tr_pens_exit.HitNonWorld = entity ~= Entity(0)
		tr_pens_exit.Entity = entity == -1 and NULL or entity -- good god
		-- Add extra...
		tr_pens_exit.StartPos = bullet_trace.start
		tr_pens_exit.EndPos = bullet_trace.endpos
	else
		tr_pens_exit = util_TraceLine(bullet_trace)
	end

	trace_exit_pens = index
	if trace_exit_pens > bullet_trace.MaxPenetration then return end
	-- Hit world?
	if trace_exit_pens > 0 and tr_pens_exit.HitWorld then return end -- STOP!

	local pen_damage = (1 / (math_max(1, ExitToEnterWorldDistance) * 0.3))
	if pen_damage >= 0.1 and pen_damage <= 1 then -- Damage multiplier check
		local pen_real_damage = bulletinfo_t.damage
		pen_real_damage = pen_real_damage * ((inflictortbl and inflictortbl.PenetrationDamageMultiplier or 0.5) ^ trace_exit_pens)

		if pen_real_damage < 1 then
			return -- stop, da saving performance reason!
		end

		DMG_SetDamage(damageinfo, pen_real_damage) -- SET AGAIN

		EntityDamageLogic(tr_pens_exit, bulletinfo_t, damageinfo, use_damage, pen_damage)
	end

	tr_pens_exit.WasTraceExit = true -- TraceExit
	tr_pens_exit.Penetrations = (tr_pens_exit.Penetrations or 0) + 1

	tr_lists[#tr_lists + 1] = tr_pens_exit

	if do_effects and (MySelf and IsFirstTimePredicted() or temp_shooter ~= MySelf) then
		EffectClientBullets(bulletinfo_t.inflictor, hitwater, use_ragdoll_impact, use_impact, use_tracer, tr_pens_exit.StartPos, temp_attacker, tr_pens_exit.Entity, tr_pens_exit, bulletinfo_t.tracer, bulletinfo_t.effect_entity, bulletinfo_t.effect_attachment_id, bulletinfo_t.tracer_rounds_list, true)
	end
end

-- Test when the trace exit from world.
local tr_struct_exit = {Filter = BaseBulletFilter}
local function TraceToExit(start, dir, trEnter, flStepSize, flMaxDistance)
	ExitToEnterWorldDistance = 1

	local endpos
	local flDistance = 0
	local trExit

	while (flDistance <= flMaxDistance) do
		flDistance = flDistance + (flStepSize or 4)
		ExitToEnterWorldDistance = flDistance

		endpos = start + dir * flDistance

		local vecTrEnd = endpos - dir * flStepSize

		if UTIL_TestTraceCollideWithWorld then -- C++
			trExit = UTIL_TestTraceCollideWithWorld(endpos, vecTrEnd, CS_MASK_SHOOT)
		else
			tr_struct_exit.start = endpos
			tr_struct_exit.endpos = vecTrEnd
			tr_struct_exit.mask = CS_MASK_SHOOT

			trExit = UTIL_TraceLineStruct and UTIL_TraceLineStruct(tr_struct_exit) or util.TraceLine(tr_struct_exit)
		end

		-- Still inside world?
		if trExit.StartSolid and trExit.HitWorld then
			continue
		end

		if ((trExit.Fraction < 1 or trExit.AllSolid) and not trExit.StartSolid ) then
			bullet_trace.start = endpos
			-- Update final trace
			TracePenetration(bullet_trace, false, TraceExitResult_Penetration)
			break -- Finished
		end
	end
end

-- This is same as pairs without using table...
local function TraceResult_Penetration(trace_pens_total, contents, startsolid, fraction, fractionleftsolid, allsolid, hitnormal, hitpos, normal, hitbox, hitgroup, surfaceflags, surfaceprops, physbone, entity)
	if firebullet_has_to_stop then return end -- STOP
	if trace_pens_total > bullet_trace.MaxPenetration then return end -- STOP
	if not pen_condition_met then return end

	-- Setup trace so can sent to bullet callback etc...
	tr_pens.Contents = contents
	tr_pens.StartSolid = startsolid
	tr_pens.Fraction = fraction
	tr_pens.FractionLeftSolid = fractionleftsolid
	tr_pens.Hit = fraction < 1
	tr_pens.AllSolid = allsolid
	tr_pens.HitNormal = hitnormal
	tr_pens.HitPos = hitpos
	tr_pens.Normal = normal
	tr_pens.HitBox = hitbox
	tr_pens.HitGroup = hitgroup
	tr_pens.SurfaceFlags = surfaceflags
	tr_pens.SurfaceProps = surfaceprops
	tr_pens.HitSky = bit.band(surfaceflags, SURF_SKY) == SURF_SKY
	tr_pens.PhysicsBone = physbone
	tr_pens.HitWorld = entity == Entity(0)
	tr_pens.HitNonWorld = entity ~= Entity(0)
	tr_pens.Entity = entity == -1 and NULL or entity -- good god
	-- Add extra...
	tr_pens.StartPos = bullet_trace.start
	tr_pens.EndPos = bullet_trace.endpos

	-- Penetration damage calculdate
	local real_damage = bulletinfo_t.damage
	if bore_pens == 1 then
		real_damage = bulletinfo_t.damage * 0.75

		if trace_pens_total == 1 then
			real_damage = bulletinfo_t.damage * bore_val
		end
	end

	if bullet_trace.MaxPenetration >= 1 and inflictortbl.MaxPenetrations and inflictortbl.MaxPenetrations >= 1 and (bore_pens ~= 1 or trace_pens_total ~= 1) then
		local stagger = bore_pens == 1 and trace_pens_total >= 1 and 1 or 0

		real_damage = real_damage * (inflictortbl.PenetrationDamageMultiplier ^ (trace_pens_total - stagger))
	end

	-- FHB...
	CheckFHB(tr_pens)

	hitwater = false
	if IS_CLIENT_RUNNING and tr_pens.HitPos and bit_band(util_PointContents(tr_pens.HitPos), CONTENTS_LIQUID) ~= 0 then
		hitwater = HandleShotImpactingWater(real_damage)
	end

	local hb = tr_pens.HitGroup
	head_hitbox = hb and hb == HITGROUP_HEAD

	has_hit_world = tr_pens.HitWorld or not tr_pens.Hit

	if bullet_trace.MaxPenetration >= 1 and inflictortbl.PenHeadOnly and not head_hitbox then
		pen_condition_met = false
	end

	DMG_SetDamageType(damageinfo, DMG_BULLET)
	DMG_SetDamage(damageinfo, real_damage)
	DMG_SetDamagePosition(damageinfo, tr_pens.HitPos)
	DMG_SetAttacker(damageinfo, temp_attacker)
	DMG_SetInflictor(damageinfo, bulletinfo_t.inflictor or temp_shooter)

	local vecForce = bulletinfo_t.dir:GetNormalized()
	vecForce = vecForce * GetConVar("phys_pushscale"):GetFloat()
	vecForce = vecForce * bulletinfo_t.force_mul
	vecForce = vecForce * game.GetAmmoForce(bulletinfo_t.ammo_id)
	DMG_SetDamageForce(damageinfo, vecForce)

	use_tracer = bulletinfo_t.tracer ~= "none"
	use_impact = true
	use_ragdoll_impact = true
	use_damage = true

	if bulletinfo_t.callback then
		local ret = bulletinfo_t.callback(temp_shooter, tr_pens, damageinfo, trace_pens_total)
		if ret then
			if ret.donothing then return end

			if ret.tracer ~= nil then use_tracer = ret.tracer end
			if ret.impact ~= nil then use_impact = ret.impact end
			if ret.ragdoll_impact ~= nil then use_ragdoll_impact = ret.ragdoll_impact end
			if ret.damage ~= nil then use_damage = ret.damage end
		end
	end

	-- Damage Event
	EntityDamageLogic(tr_pens, bulletinfo_t, damageinfo, use_damage, 1)

	-- Add it for final callback
	tr_pens.Penetrations = trace_pens_total
	tr_lists[#tr_lists + 1] = tr_pens

	do_effects = true
	if bullet_trace.MaxPenetration >= 1 then
		do_effects = trace_pens_total == bullet_trace.MaxPenetration or has_hit_world
	end

	if do_effects and (MySelf and IsFirstTimePredicted() or temp_shooter ~= MySelf) then
		EffectClientBullets(temp_shooter, hitwater, use_ragdoll_impact, use_impact, use_tracer, bulletinfo_t.src, temp_attacker, tr_pens.Entity, tr_pens, bulletinfo_t.tracer, bulletinfo_t.effect_entity, bulletinfo_t.effect_attachment_id, bulletinfo_t.tracer_rounds_list, false)
	end

	-- WALLBANG WALLBANG!!!
	if has_hit_world and bullet_trace.MaxPenetration > 0 then
		local hitNoDraw = bit_band(tr_pens.SurfaceFlags, SURF_NODRAW) == SURF_NODRAW
		local hitGrate = bit_band(tr_pens.Contents, CONTENTS_GRATE) == CONTENTS_GRATE
		local hitWindow = bit_band(tr_pens.Contents, CONTENTS_WINDOW) == CONTENTS_WINDOW

		-- check if bullet can penetrarte another entity
		-- If we hit a grate with iPenetration == 0, stop on the next thing we hit

		if (trace_pens_total == 0 and not hitGrate and hitNoDraw and not hitWindow) then
			return -- no, stop
		end

		local flt_pen_distance = math_min(60, math.max(1, real_damage * 0.4))
		if flt_pen_distance > 0 then
			TraceToExit(tr_pens.HitPos, bulletinfo_t.dir, tr_pens, 4, flt_pen_distance)
		end

		firebullet_has_to_stop = true
	elseif trace_pens_total >= 0 and tr_pens.Entity and tr_pens.Entity ~= NULL and not (EntityIsPlayer(tr_pens.Entity) or tr_pens.Entity:IsNPC() or tr_pens.Entity:IsNextBot()) then
		firebullet_has_to_stop = true -- STOP we don't want piece through no player entity... but deal damage to entity though.
	end
end

local melee_mask = bit.bor(MASK_SOLID, CONTENTS_GRATE, CONTENTS_HITBOX)
function meta:MeleeBullet(src, dir, damage, attacker, force_mul, callback, hull_size, max_distance, inflictor)
	bullet_trace.mask = melee_mask
	self:FireBulletsLua(src, dir, 0, 1, damage, attacker, force_mul, nil, callback, hull_size, false, max_distance, nil, inflictor)
	bullet_trace.mask = CS_MASK_SHOOT
end

-- This function is deprecated... you should be using the FireBulletsInfo instead.
local bulletinfo_var = {}
function meta:FireBulletsLua(src, dir, spread, num, damage, attacker, force_mul, tracer, callback, hull_size, hit_own_team, max_distance, filter, inflictor, effect_entity, effect_attachment_id, ammo_id, trace_result)
	bulletinfo_var.src = src
	bulletinfo_var.dir = dir
	bulletinfo_var.spread = spread
	bulletinfo_var.num = num
	bulletinfo_var.damage = damage
	bulletinfo_var.attacker = attacker
	bulletinfo_var.force_mul = force_mul
	bulletinfo_var.tracer = tracer
	bulletinfo_var.callback = callback
	bulletinfo_var.hull_size = hull_size
	bulletinfo_var.hit_own_team = hit_own_team
	bulletinfo_var.max_distance = max_distance
	bulletinfo_var.filter = filter
	bulletinfo_var.inflictor = inflictor
	bulletinfo_var.effect_entity = effect_entity
	bulletinfo_var.effect_attachment_id = effect_attachment_id
	bulletinfo_var.tracer_rounds_list = tracer_rounds_list
	bulletinfo_var.bulletsize = 1
	bulletinfo_var.ammo_id = ammo_id
	bulletinfo_var.FireBulletTraceResult = trace_result and trace_result or false

	return self:FireBulletsInfo(bulletinfo_var)
end

--[[ FireBullets Struct example
	bulletinfo.src,
	bulletinfo.dir,
	bulletinfo.spread,
	bulletinfo.num,
	bulletinfo.damage,
	bulletinfo.attacker,
	bulletinfo.force_mul,
	bulletinfo.tracer,
	bulletinfo.callback,
	bulletinfo.hull_size,
	bulletinfo.hit_own_team,
	bulletinfo.max_distance,
	bulletinfo.filter,
	bulletinfo.inflictor,
	bulletinfo.effect_entity,
	bulletinfo.effect_attachment_id
	bulletinfo.tracer_rounds_list
	bulletinfo.bulletsize
	bulletinfo_var.bulletsize
	bulletinfo_var.ammo_id
	bulletinfo_var.FireBulletTraceResult
]]

function meta:FireBulletsInfo(bulletinfo)
	bulletinfo.attacker = bulletinfo.attacker or self

	if not E_IsValid(bulletinfo.attacker) then bulletinfo.attacker = self end
	if not bulletinfo.force_mul then bulletinfo.force_mul = 1 end
	bulletinfo.ammo_id = bulletinfo.ammo_id or 1

	temp_shooter = self
	temp_attacker = bulletinfo.attacker
	attacker_player = EntityIsPlayer(bulletinfo.attacker)

	bullet_trace.start = bulletinfo.src
	if bulletinfo.filter then
		bullet_trace.filter = bulletinfo.filter
	else
		bullet_trace.filter = BaseBulletFilter
		if not bulletinfo.hit_own_team and attacker_player then
			temp_ignore_team = ((GAMEMODE.HitEveryone and 0) or P_Team(temp_attacker))
		else
			temp_ignore_team = nil
		end
	end
	-- custom
	bullet_trace.ShouldTraceResultTable = false
	bullet_trace.Attacker = temp_attacker
	bullet_trace.IgnoreTeamID = temp_ignore_team
	bullet_trace.ShouldLagCompensation = DO_BULLET_LAG_COMP and attacker_player and not temp_attacker:IsBot()
	-- hitboxscale bonus
	bullet_trace.hitboxscale = (bulletinfo.HitboxSize or 0) + (PLAYER_WeaponMeta and PLAYER_WeaponMeta[temp_attacker] and PLAYER_WeaponMeta[temp_attacker]["TraceHitBoxScale"] or 1)

	if bulletinfo.hull_size then
		bullet_trace.maxs = hullvec * bulletinfo.hull_size * 0.5
		bullet_trace.mins = bullet_trace.maxs * -1
	end

	local base_ang = IS_SERVER_RUNNING and GMUTIL_VTA and GMUTIL_VTA(bulletinfo.dir) or V_Angle(bulletinfo.dir)
	temp_has_spread = bulletinfo.spread > 0

	local calculate_dist_by_cone = math_max(1, math_min(10, bulletinfo.spread)) * 3 -- Oh well, that's performance... for example shotguns should have like 3500 distance
	bulletinfo.max_distance = bulletinfo.max_distance or temp_has_spread and 56756 / calculate_dist_by_cone or 56756

	bore_pens = 0
	bore_val = nil
	inflictortbl = nil
	tr_lists = {}

	bullet_trace.mask = CS_MASK_SHOOT

	if bulletinfo.inflictor and E_IsValid(bulletinfo.inflictor) then
		inflictortbl = E_GetTable(bulletinfo.inflictor)
	end

	-- Spread pattern
	local pattern = inflictortbl.SpreadPattern

	-- Penetration
	if attacker_player and (inflictortbl.Tier or 1) <= 4 then
		local bore = E_GetTable(bulletinfo.attacker).BulletModBore
		if bore and bore > 0 then
			bore_pens = 1
			bore_val = bore
		end
	end

	-- bullet penetrating
	local total_pens = (inflictortbl.MaxPenetrations or 0) + bore_pens

	-- Damage event
	damageinfo = DamageInfo()
	damage_list, has_damage_to_do = {}, false
	temp_multishot_ignore_ents = {}

	-- Start Lag compensation
	WantLagCompensationOnEntity(true, bulletinfo.hit_own_team, bulletinfo.max_distance)

	for i = 0, bulletinfo.num - 1 do
		temp_pen_ents = {}
		has_hit_world = false
		pen_condition_met = true
		firebullet_has_to_stop = false

		-- Init random seed to sync up server/client.
		if attacker_player and temp_attacker and IsFirstTimePredicted() then
			math_randomseed((rawget(PLAYER_RandomSeed, temp_attacker) or 0) + i)
		end

		-- SPREAD SPREADDDD
		if pattern and pattern[i + 1] then
			local pattern_x, pattern_y = pattern[i + 1][1], pattern[i + 1][2]

			A_Set(temp_angle, base_ang)
			A_RotateAroundAxis(temp_angle, IS_SERVER_RUNNING and GMUTIL_GF and GMUTIL_GF(temp_angle) or A_Forward(temp_angle), pattern_x)
			A_RotateAroundAxis(temp_angle, IS_SERVER_RUNNING and GMUTIL_GUP and GMUTIL_GUP(temp_angle) or A_Up(temp_angle), pattern_y * bulletinfo.spread)

			bulletinfo.dir = IS_SERVER_RUNNING and GMUTIL_GF and GMUTIL_GF(temp_angle) or A_Forward(temp_angle)
		elseif temp_has_spread then
			local classic_spread = bulletinfo.spread * math_Rand(0, math_Rand(spread_multi_min, spread_multi_max))
			local spread_360_rng = math_Rand(-360, 360) -- :the: 360 RNG spread
			local make_circle_x = math_cos(spread_360_rng) * classic_spread
			local make_circle_y = math_sin(spread_360_rng) * classic_spread

			bulletinfo.dir = IS_SERVER_RUNNING and GMUTIL_ApplySpread and GMUTIL_ApplySpread(base_ang, make_circle_x, make_circle_y)
				or A_Forward(base_ang) + make_circle_x * A_Right(base_ang) + make_circle_y * A_Up(base_ang)
		end

		-- Trace EndPos
		bullet_trace.endpos = bulletinfo.src + bulletinfo.dir * bulletinfo.max_distance

		-- Shotgun or multishot hit registration....
		if IS_SERVER_RUNNING then
			bullet_trace.LoopIndex = i
		end

		-- Trace penetration
		bullet_trace.MaxPenetration = total_pens -- lets count how many penetration need.
		-- Update this info
		bulletinfo_t = bulletinfo
		-- Lets Call Trace penetration
		TracePenetration(bullet_trace, bulletinfo.hull_size, TraceResult_Penetration)
	end

	-- Finish Lag compensation
	WantLagCompensationOnEntity(false, false, 0)

	-- Damage event for hit things
	if has_damage_to_do then
		for ent, dmg_data in pairs(damage_list) do
			local final_dmginfo = dmg_data.Info

			DMG_SetDamage(final_dmginfo, dmg_data.Damage)
			DMG_SetDamagePosition(final_dmginfo, dmg_data.Pos)

			ent:DispatchTraceAttack(final_dmginfo, dmg_data.Trace)
		end
	end

	-- Callback or Events...
	local final_firebullet_cb = bulletinfo.FireBulletTraceResult
	if final_firebullet_cb and tr_lists and #tr_lists > 0 then
		for i = 0, #tr_lists do
			local trace = tr_lists[i]
			if not trace then continue end

			if final_firebullet_cb then
				final_firebullet_cb(trace, temp_attacker, bulletinfo.inflictor or temp_shooter)
			end
		end
	end
end

function meta:IsValidPlayer()
	return E_IsValid(self) and EntityIsPlayer(self)
end

function meta:GetAlpha()
	return self:GetColor().a
end

function meta:SetAlpha(a)
	local col = self:GetColor()
	col.a = a
	self:SetColor(col)
end

function meta:SetSelected(b)
end

local MOVE_HEIGHT_EPSILON = 0.0625
function meta:FloorPoint(vecStart, collisionMask, flStartZ, flEndZ)
    local mins, maxs
    if self:IsNPC() or self:IsNextBot() then
        mins, maxs = GAMEMODE:CallZombieFunction(self, "GetHullSizes")
    else
        mins, maxs = self:OBBMins(), self:OBBMaxs()
    end
    maxs.z = mins.z

	local vecUp = Vector(vecStart.x, vecStart.y, vecStart.z + flStartZ + MOVE_HEIGHT_EPSILON)
	local vecDown = Vector(vecStart.x, vecStart.y, vecStart.z + flEndZ)

	local trace = util.TraceHull( {
        start = vecUp,
        endpos = vecDown,
        mins = mins,
        maxs = maxs,
        mask = collisionMask
    } )

	local fStartedInObject = false
	if trace.StartSolid then
		if trace.Entity and ( trace.Entity:GetMoveType() == MOVETYPE_VPHYSICS or trace.Entity:IsNPC() or trace.Entity:IsNextBot() ) and ( vecStart - self:GetPos() ):Length() < 0.1 then
			fStartedInObject = true
        end

		vecUp.z = vecStart.z + MOVE_HEIGHT_EPSILON;
        trace = util.TraceHull( {
            start = vecUp,
            endpos = vecDown,
            mins = mins,
            maxs = maxs,
            mask = collisionMask
        } )
	end

	if not trace.Hit or trace.AllSolid or ( fStartedInObject and trace.StartSolid ) then
		if fStartedInObject then
			return true, vecStart
        end
		return false, vecStart
	end

	return true, trace.HitPos
end

local val
local et
function meta:__index(key)
	val = meta[key]
	if val ~= nil then return val end

	et = E_GetTable(self)
	if et then
		return et[key]
	end
end