-- OVERRIDE THEM!
local vec = Vector
local P_Team = GetPlayerTeam

-- disables StudioFrameAdvance from weapon think for network performance.
local dsfa_module_load, _ = pcall(require, "disablewepanimtime")
if dsfa_module_load then
	MsgN("[DSFA]: Module loaded!!!")
end

if GMUTIL_TraceLine and GMUTIL_TraceHull then -- check if its available then do somthing!
	MsgN("[GMUTIL]: Module loaded!!!")

	-------------------------------------------------------------------
	-- SETUP MODULE FOR OVERRIDE SOME FUNCTIONS
	-------------------------------------------------------------------

	local TEMP_CTraceLine = GMUTIL_TraceLine
	local TEMP_CTraceHull = GMUTIL_TraceHull
	local bit_band = bit.band

	local function EmptyTraceFilter(ent)
		return true
	end

	ZS_HITBOXSCALE = 1
	-- Higher players on the server can cause lag compensation slow so trace size can help with it. Also, this is helpful on low tickrate.
	local function ResizeTraceThickness()
		local count = player.GetCount()

		ZS_HITBOXSCALE = (count >= 0 and count < 65) and 1.8 or (count > 65 and count < 90) and 2 or 2.5
	end
	timer.Create("ResizeTT", 10, 0, ResizeTraceThickness)

	local MASK_SOLID = MASK_SOLID

	GetEntityWorld = GetEntityWorld or nil

	local shotgun_scale = 4
	function UTIL_TraceLineStruct(trace_struct)
		local attacker_team = ((GAMEMODE.HitEveryone and 0) or trace_struct.IgnoreTeamID or 0)
		local hitboxscale = trace_struct.hitboxscale or 0
		local bullet_index = trace_struct.LoopIndex or 0

		if bullet_index and bullet_index > 1 and ((bullet_index % 2) == 1) then
			hitboxscale = hitboxscale > shotgun_scale and hitboxscale or shotgun_scale -- HL2 classic shotgun hit-registration.
		else -- To skip cliptrace, you have set the number to 1 or less than 1.
			hitboxscale = hitboxscale > ZS_HITBOXSCALE and hitboxscale or ZS_HITBOXSCALE
		end

		local result = TEMP_CTraceLine(
			trace_struct.start,
			trace_struct.endpos,
			trace_struct.mask or MASK_SOLID,
			trace_struct.ignoreworld or false,
			trace_struct.ShouldLagCompensation or false,
			trace_struct.Attacker or NULL,
			attacker_team or 0,
			hitboxscale,
			trace_struct.filter or EmptyTraceFilter,
			trace_struct
		)

		if not GetEntityWorld then
			GetEntityWorld = Entity(0)
		end

		-- table exist! use this method instead.
		if trace_struct.output then
			-- Add trace startpos/endpos because C++ doesnt have to push lua for endpos/startpos.
			trace_struct.output.StartPos = trace_struct.start
			trace_struct.output.EndPos = trace_struct.endpos
			-- Add extra trace
			local ent = trace_struct.output.Entity

			trace_struct.output.Hit = trace_struct.output.Fraction < 1
			trace_struct.output.HitSky = bit_band(trace_struct.output.SurfaceFlags, SURF_SKY) == SURF_SKY
			trace_struct.output.HitWorld = ent == GetEntityWorld
			trace_struct.output.HitNonWorld = ent ~= GetEntityWorld
			trace_struct.output.Entity = ent == -1 and NULL or ent -- Test NULL

			return trace_struct.output
		end

		-- Add trace startpos/endpos because C++ doesnt have to push lua for endpos/startpos.
		result.StartPos = trace_struct.start
		result.EndPos = trace_struct.endpos
		-- Add extra trace
		local ent = result.Entity

		result.Hit = result.Fraction < 1
		result.HitSky = bit_band(result.SurfaceFlags, SURF_SKY) == SURF_SKY
		result.HitWorld = ent == GetEntityWorld
		result.HitNonWorld = ent ~= GetEntityWorld
		result.Entity = ent == -1 and NULL or ent -- Test NULL

		return result
	end

	local tr_world = {}
	function UTIL_TestTraceCollideWithWorld(start, endpos, mask)
		local contents, startsolid, fraction, entity = GMUTIL_TraceTestHitWorld(start, endpos, mask or MASK_SOLID)

		if not GetEntityWorld then
			GetEntityWorld = Entity(0)
		end

		tr_world.Contents = contents
		tr_world.StartSolid = startsolid
		tr_world.Fraction = fraction
		tr_world.HitWorld = entity == GetEntityWorld
		tr_world.HitNonWorld = entity ~= GetEntityWorld
		tr_world.Entity = entity == -1 and NULL or entity
		-- Extra...
		tr_world.StartPos = start
		tr_world.EndPos = endpos

		return tr_world
	end

	function UTIL_TLPenetration(trace_struct)
		local hitboxscale = trace_struct.hitboxscale or 0
		local bullet_index = trace_struct.LoopIndex or 0

		if bullet_index and bullet_index > 0 and ((bullet_index % 2) == 1) then
			hitboxscale = hitboxscale > shotgun_scale and hitboxscale or shotgun_scale -- HL2 classic shotgun hit-registration.
		else -- To skip cliptrace, you have set the number to 1 or less than 1.
			hitboxscale = hitboxscale > ZS_HITBOXSCALE and hitboxscale or ZS_HITBOXSCALE
		end

		local result = GMUTIL_TLPenetration(
			trace_struct.start,
			trace_struct.endpos,
			trace_struct.mask or MASK_SOLID,
			trace_struct.ignoreworld or false,
			trace_struct.ShouldLagCompensation or false,
			trace_struct.Attacker or NULL,
			(GAMEMODE.HitEveryone and 0) or trace_struct.IgnoreTeamID or 0,
			hitboxscale,
			trace_struct.MaxPenetration or 6,
			trace_struct.filter or EmptyTraceFilter,
			trace_struct.ShouldTraceResultTable,
			trace_struct.trace_output_list,
			trace_struct.hull_size and true or false,
			trace_struct.mins or vector_origin,
			trace_struct.maxs or vector_origin
		)

		return result
	end

	function UTIL_TraceHullStruct(trace_struct)
		local result = TEMP_CTraceHull(
			trace_struct.start,
			trace_struct.endpos,
			trace_struct.mask or MASK_SOLID,
			trace_struct.ignoreworld or false,
			trace_struct.ShouldLagCompensation or false,
			trace_struct.Attacker or NULL,
			(GAMEMODE.HitEveryone and 0) or trace_struct.IgnoreTeamID or 0,
			trace_struct.mins or vector_origin,
			trace_struct.maxs or vector_origin,
			trace_struct.filter or EmptyTraceFilter,
			trace_struct
		)

		if not GetEntityWorld then
			GetEntityWorld = Entity(0)
		end

		-- table exist! use this method instead.
		if trace_struct.output then
			-- Add trace startpos/endpos because C++ doesnt have to push lua for endpos/startpos.
			trace_struct.output.StartPos = trace_struct.start
			trace_struct.output.EndPos = trace_struct.endpos
			-- Add extra trace
			local ent = trace_struct.output.Entity

			trace_struct.output.Hit = trace_struct.output.Fraction < 1
			trace_struct.output.HitSky = bit_band(trace_struct.output.SurfaceFlags, SURF_SKY) == SURF_SKY
			trace_struct.output.HitWorld = ent == GetEntityWorld
			trace_struct.output.HitNonWorld = ent ~= GetEntityWorld
			trace_struct.output.Entity = ent == -1 and NULL or ent -- Test NULL

			return trace_struct.output
		end

		-- Add trace startpos/endpos because C++ doesnt have to push lua for endpos/startpos.
		result.StartPos = trace_struct.start
		result.EndPos = trace_struct.endpos
		-- Add extra trace
		local ent = result.Entity

		result.Hit = result.Fraction < 1
		result.HitSky = bit_band(result.SurfaceFlags, SURF_SKY) == SURF_SKY
		result.HitWorld = ent == GetEntityWorld
		result.HitNonWorld = ent ~= GetEntityWorld
		result.Entity = ent == -1 and NULL or ent -- Test NULL

		return result
	end

	function SV_TraceHit(posa, posb, mask, attacker, filter)
		local ignore_team = attacker and attacker:IsValid() and EntityIsPlayer(attacker) and P_Team(attacker) or 0

		return GMUTIL_TraceHit(posa, posb, mask, false, attacker, ignore_team, filter)
	end

	-- This is tracetype for useful filter only for SV_TraceHitWithPartitionFilter function.
	-- Extreme fastest and useful for Aoe or whatever, this is because skipping the filter call example; (LUA > C > LUA)...
	-- All these defined with this module only.

	if GMUTIL_TraceHitWithPartitionFilter then
		TRACE_EVERYTHING = 0							-- Trace everything...
		TRACE_WORLD_ONLY = 1							-- This does *not* test static props!!!
		TRACE_ENTITIES_ONLY = 2							-- This version will *not* test static props
		TRACE_EVERYTHING_FILTER_PROPS = 3				-- This version will pass the IHandleEntity for props through the filter, unlike all other filters
		TRACE_PLAYERS_ONLY = 4					 		-- This does check all players only!!!
		TRACE_PLAYERS_TEAM_HUMAN = 5					-- This does check all players with human only!!!
		TRACE_PLAYERS_TEAM_UNDEAD = 6					-- This does check all players with zombie only!!!
		TRACE_PLAYERS_TEAM_HUMAN_WITH_EVERYTHING = 7	-- Trace everything with human only.
		TRACE_PLAYERS_TEAM_UNDEAD_WITH_EVERYTHING = 8	-- Trace everything with zombie only.
		TRACE_PLAYERS_NO_PLAYERS = 9 					-- Trace everything but WITHOUT PLAYERS
		TRACE_PROP_STATIC_AND_WORLD_ONLY = 10			-- Trace everything that PROP STATIC and WORLD only

		function SV_TraceHitWithPartitionFilter(posa, posb, mask, tracetype, filter)
			return GMUTIL_TraceHitWithPartitionFilter(posa, posb, mask, tracetype, filter)
		end
	end

	local math_max = math.max
	function UTIL_FindInBox(pos, radius, playeronly, ignoreteam, entonly, func_result, num, shouldsort)
		num = num or 24
		shouldsort = shouldsort or false

		GMUTIL_TraceBox(pos, math_max(radius, 1), playeronly, ignoreteam, entonly, func_result, num, shouldsort)
	end

	if GMUTIL_SetHullScaleLagCompensation then
		local default_hullscale_mul = Vector(2, 2, 1.75)

		hook.Add("PlayerSpawn", "PlayerSpawn.SetHullScaleLagCompensation", function(pl)
			GMUTIL_SetHullScaleLagCompensation(pl, default_hullscale_mul, 1)

			GMUTIL_SetSoundVolume(pl:EntIndex(), 1) -- default
		end)
	end

	--[[if GMUTIL_IsFromWeapon and GMUTIL_SetSoundVolume then
		local wep_meta = FindMetaTable("Weapon")
		if wep_meta then
			local ent_meta = FindMetaTable("Entity")
			wep_meta.OldEmitSound = wep_meta.OldEmitSound or ent_meta.EmitSound -- Save this
			local OldEmitSound = wep_meta.OldEmitSound
			function wep_meta:EmitSound(name, soundlvl, pitch, volume, channel, soundflag, dsp)
				GMUTIL_IsFromWeapon(true) -- OVERRIDE because gmod emitsound always 0 entindex!
				OldEmitSound(self, name, soundlvl, pitch, volume, channel, soundflag, dsp)
				GMUTIL_IsFromWeapon(false)
			end
		end

		local function RefreshPlayerWeaponVolumeOption()
			if not GMUTIL_SetSoundVolume then return end

			for _, client in ipairs(player.GetAll()) do
				if client then
					local client_index = client:EntIndex()
					local client_get_sound_volume = tonumber(client:GetInfo("zs_server_weapon_sound_volume"))
					if client_get_sound_volume then
						GMUTIL_SetSoundVolume(client_index, math.Clamp(client_get_sound_volume, 0, 1))
					end
				end
			end
		end
		timer.Create("RefreshPlayerWeaponVolumeOptionTimer", 1, 0, RefreshPlayerWeaponVolumeOption)
	end]]

	return -- C++ loaded.
end

MsgN("[ZSUTIL]: Module not loaded!")

-- Lets strip this function because you dont have that module.
MODULE_FinishMove = function(pl, mv) end

local isplayer = true
local ignoreteam_ = 0
local entityonly_ = true

local table_sort = table.sort
local aoe_epiccenter = vector_origin

local temp_tbl = {}
local function BoxSort(a, b)
	return a:GetPos():DistToSqr(aoe_epiccenter) < b:GetPos():DistToSqr(aoe_epiccenter)
end

local function TraceBoxFilter(ent)
	if isplayer and EntityIsPlayer(ent) or (ignoreteam_ > 0 and EntityIsPlayer(ent) and P_Team(ent) ~= ignoreteam_) or entityonly_ and not EntityIsPlayer(ent) then
		temp_tbl[#temp_tbl + 1] = ent
	end

	return false
end

-- 100% same as c++ but this is about between 70-100x slower because lua is shit since its C push to Lua with shitty tables.
local trace_exp = {ignoreworld = true, mask = CONTENTS_EMPTY, filter = TraceBoxFilter, output = {}}
function UTIL_FindInBox(pos, size, isply, ignoreteam, entityonly, func, entitylimit, shouldsort)
	ignoreteam_ = ignoreteam or 0
	isplayer = isply
	entityonly_ = entityonly
	entitylimit = entitylimit or 24

	temp_tbl = {}

	local vec_radius = vec(size, size, size)

	trace_exp.start = pos
	trace_exp.endpos = pos
	trace_exp.mins = -vec_radius
	trace_exp.maxs = vec_radius

	util.TraceHull(trace_exp)

	if shouldsort then
		aoe_epiccenter = pos
		table_sort(temp_tbl, BoxSort)
	end

	local entitypassed = 0
	if func and #temp_tbl > 0 then
		for i = 0, #temp_tbl do
			local ent = temp_tbl[i]
			if not ent then continue end

			func(ent)

			entitypassed = entitypassed + 1
			if entitypassed >= entitylimit then break end
		end
	end
end

-- gmod traceline is expensive, this is same shit for Tracehull.
local hullsize = Vector(2.5, 2.5, 2.5)
function UTIL_TraceLineStruct(trace_tbl)
	if trace_tbl.LoopIndex and trace_tbl.LoopIndex > 0 and ((trace_tbl.LoopIndex % 2) == 1) then
		trace_tbl.mins = -hullsize
		trace_tbl.maxs = hullsize

		return util.TraceHull(trace_tbl)
	end

	return util.TraceLine(trace_tbl)
end

function UTIL_TraceHullStruct(trace_tbl)
	return util.TraceHull(trace_tbl)
end

local tr_tbl = {}
function SV_TraceHit(posa, posb, mask, attacker, filter)
	tr_tbl.start = posa
	tr_tbl.endpos = posb
	tr_tbl.mask = mask
	tr_tbl.filter = filter

	return util.TraceLine(tr_tbl).Hit
end

local tr_tbl = {}
function SV_TraceHitWithPartitionFilter(posa, posb, mask, tracetype, filter)
	tr_tbl.start = posa
	tr_tbl.endpos = posb
	tr_tbl.mask = mask
	tr_tbl.filter = filter

	return util.TraceLine(tr_tbl).Hit
end