-- A module for updating navmesh areas. More or less based on how it is done in Zombie Master Reborn.

-- do not set this to more than one
local TransientAreasUpdateRate = 0.666 -- for reference: UpdateBlocked internal timer resets them after 5 seconds or so
local AvoidanceUpdateRate = 0.2

local TransientAreas = TransientAreas or {}
local TransientNoFloor = TransientNoFloor or {}
local NumTransientAreas = NumTransientAreas or 0

local function InsertTBL(tbl, stuff)
	tbl[#tbl + 1] = stuff
end

local util_TraceHull = util.TraceHull
local util_TraceLine = util.TraceLine

-- ZMR navmesh compatibility
local NAV_MESH_NOFLOOR = 0x00040000

local next_transient_update = CurTime()
local float_max = 3.402823e+38
local function GetAreaBounds( area )

	local temp = vector_origin

	local mins = Vector( float_max, float_max, float_max )
	local maxs = Vector( -float_max, -float_max, -float_max )

	for i = 0, 3 do
		temp = area:GetCorner( i )

		if temp.x < mins.x then
			mins.x = temp.x
		end
		if temp.y < mins.y then
			mins.y = temp.y
		end
		if temp.z < mins.z then
			 mins.z = temp.z
		end
		if temp.x > maxs.x then
			 maxs.x = temp.x
		end
		if temp.y > maxs.y then
			maxs.y = temp.y
		end
		if temp.z > maxs.z then
			 maxs.z = temp.z
		end
	end

	return mins, maxs
end

local halfHumanHeight = 35.5
local halfHumanWidth = 16

local updateblocked_trace = { mins = Vector( -1, -1, 0 ), maxs = Vector( 1, 1, 36 - halfHumanHeight ), collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT, mask = MASK_NPCSOLID_BRUSHONLY, output = {} }

local function UpdateBlockedArea( area, force )

	local origin = area:GetCenter()
	origin.z = origin.z + halfHumanHeight

	local sizeX = math.max( 1, math.min ( area:GetSizeX() / 2 - 5, halfHumanWidth ) )
	local sizeY = math.max( 1, math.min ( area:GetSizeY() / 2 - 5, halfHumanWidth ) )

	updateblocked_trace.start = origin
	updateblocked_trace.endpos = origin

	updateblocked_trace.mins.x = -sizeX
	updateblocked_trace.mins.y = -sizeY

	updateblocked_trace.maxs.x = sizeX
	updateblocked_trace.maxs.y = sizeY

	local tr = util_TraceHull( updateblocked_trace )

	if !tr.StartSolid then
		area:MarkAsUnblocked()
	elseif force then
		area:MarkAsBlocked()
	end

end

-- Update transient areas
local transient_trace = { collisiongroup = COLLISION_GROUP_NONE, mask = bit.bor( CONTENTS_SOLID, CONTENTS_GRATE, CONTENTS_WINDOW, CONTENTS_MOVEABLE ), ignoreworld = true, output = {} }

local function UpdateTransientAreas()

	if next_transient_update > CurTime() then return end
	next_transient_update = CurTime() + TransientAreasUpdateRate

	local area, mins, maxs, center
	local offset = 17


	for i=1, NumTransientAreas do
		area = TransientAreas[i]

		local no_floor = TransientNoFloor[ area:GetID() ]

		if no_floor then

			mins, maxs = GetAreaBounds( area )

			maxs.z = mins.z
			mins.z = mins.z - offset

			center = mins + ( maxs - mins ) * 0.5

			mins = mins - center
			maxs = maxs - center

			transient_trace.start = center
			transient_trace.endpos = center
			transient_trace.mins = mins
			transient_trace.maxs = maxs

			local tr = util_TraceHull( transient_trace )

			local blocked = !IsValid( tr.Entity )

			if blocked then
				area:MarkAsBlocked()
			else
				UpdateBlockedArea( area, true )
			end

		else

			if area:IsBlocked() then continue end

			mins, maxs = GetAreaBounds( area )

			mins.z = maxs.z + offset
			maxs.z = mins.z + 18

			center = mins + ( maxs - mins ) * 0.5

			mins = mins - center
			maxs = maxs - center

			transient_trace.start = center
			transient_trace.endpos = center
			transient_trace.mins = mins
			transient_trace.maxs = maxs

			local tr = util_TraceHull( transient_trace )

			local blocked = tr.Fraction ~= 1 or tr.StartSolid or IsValid( tr.Entity )

			if blocked then
				--UpdateBlockedArea( area, true )
				area:MarkAsBlocked()
			end

		end

	end

end
hook.Add( "Think", "UpdateTransientAreas", UpdateTransientAreas )

-- Build our transient area tables. This s only done once at the start of the map.
local function SweepAreas()

	timer.Simple( 1, function()

		local areas = navmesh.GetAllNavAreas()

		for k, area in ipairs( areas ) do
			if area:HasAttributes( NAV_MESH_TRANSIENT ) then
				InsertTBL( TransientAreas, area )
				if area:HasAttributes( NAV_MESH_NOFLOOR ) then
					TransientNoFloor[ area:GetID() ] = true
				end
			end
		end

		NumTransientAreas = #TransientAreas

		PrintTable( TransientAreas )

	end )

end
hook.Add( "InitPostEntity", "GatherNavAreasInfo", SweepAreas )


-- Lua remake of obstacle avoidance, but cooler and with ground check
local avoid_trace = { mask = MASK_NPCSOLID, output = {} }
local ground_trace = { collisiongroup = COLLISION_GROUP_DEBRIS, output = {} }
local debug_angles = Angle( 0, 0, 0 )
local vector_up = vector_up

function NEXTBOT_CustomAvoidOverride( bot, path )

	local goalpos

	bot.NextAvoid = bot.NextAvoid or 0
	if bot.NextAvoid > CurTime() then return end

	bot.NextAvoid = CurTime() + AvoidanceUpdateRate

	local loco = bot.loco

	if loco:IsClimbingOrJumping() or !loco:IsOnGround() then return end

	local next_pos = path:FirstSegment() and path:FirstSegment().pos

	if !next_pos then return end

	local forward = path:FirstSegment().forward

	local bounds_min, bounds_max = bot:GetCollisionBounds()

	local size = bounds_max.x / 2.5
	local offset = size + 2

	local range = 30 * bot:GetModelScale()

	local m_hullMin = Vector( -size, -size, loco:GetStepHeight() + 0.1 )
	local m_hullMax = Vector( size, size, bounds_max.y * 2 )

	local nextStepHullMin = Vector( -size, -size, 2.0 * loco:GetStepHeight() + 0.1 )

	local m_leftFrom = bot:GetPos() + offset * bot:GetRight() * -1
	local m_leftTo = m_leftFrom + range * forward

	local m_leftToCenter = m_leftTo - range * forward * 0.5 + ( loco:GetStepHeight() + 0.1 ) * vector_up

	local m_isLeftClear = true
	local m_isLeftGroundClear = true
	local leftAvoid = 0

	avoid_trace.start = m_leftFrom
	avoid_trace.endpos = m_leftTo
	avoid_trace.mins = m_hullMin
	avoid_trace.maxs = m_hullMax

	avoid_trace.filter = bot

	local result = util_TraceHull( avoid_trace )

	if result.Fraction < 1 or result.StartSolid then

		if result.StartSolid then
			result.Fraction = 0
		end

		leftAvoid = math.Clamp( 1 - result.Fraction, 0, 1 )

		m_isLeftClear = false

	end

	-- left ground check
	if m_isLeftClear then

		local ground_pos = m_leftToCenter * 1
		ground_pos.z = bot:GetPos().z
		ground_pos.z = ground_pos.z - 30

		ground_trace.start = m_leftToCenter
		ground_trace.endpos = ground_pos

		local ground_result = util_TraceLine( ground_trace )

		if !ground_result.Hit then
			m_isLeftClear = false
			m_isLeftGroundClear = false
			debugoverlay.Line( m_leftToCenter, ground_pos, 0.2, Color( 255, 0, 0 ) )
		else
			debugoverlay.Line( m_leftToCenter, ground_pos, 0.2, Color( 0, 255, 0 ) )
		end

	end

	local m_rightFrom = bot:GetPos() + offset * bot:GetRight()
	local m_rightTo = m_rightFrom + range * forward

	local m_rightToCenter = m_rightTo - range * forward * 0.5 + ( loco:GetStepHeight() + 0.1 ) * vector_up

	local m_isRightClear = true
	local m_isRightGroundClear = true
	local rightAvoid = 0

	avoid_trace.start = m_rightFrom
	avoid_trace.endpos = m_rightTo

	result = util_TraceHull( avoid_trace )

	if result.Fraction < 1 or result.StartSolid then

		if result.StartSolid then
			result.Fraction = 0
		end

		rightAvoid = math.Clamp( 1 - result.Fraction, 0, 1 )

		m_isRightClear = false

	end

	-- right ground check
	if m_isRightClear then

		local ground_pos = m_rightToCenter * 1
		ground_pos.z = bot:GetPos().z
		ground_pos.z = ground_pos.z - 30

		ground_trace.start = m_rightToCenter
		ground_trace.endpos = ground_pos

		local ground_result = util_TraceLine( ground_trace )

		if !ground_result.Hit then
			m_isRightClear = false
			m_isRightGroundClear = false
			debugoverlay.Line( m_rightToCenter, ground_pos, 0.2, Color( 255, 0, 0 ) )
		else
			debugoverlay.Line( m_rightToCenter, ground_pos, 0.2, Color( 0, 255, 0 ) )
		end

	end

	local adjustedGoal = next_pos

	if !m_isLeftClear or !m_isRightClear then

		local avoidResult = 0

		if m_isLeftClear then
			avoidResult = -rightAvoid
		elseif m_isRightClear then
			avoidResult = leftAvoid
		else
			local equalTolerance = 0.01
			if ( math.abs( rightAvoid - leftAvoid ) < equalTolerance ) then
				return
			elseif ( rightAvoid > leftAvoid ) then
				avoidResult = -rightAvoid
			else
				avoidResult = leftAvoid
			end
		end


		if m_isLeftClear then
			debugoverlay.SweptBox( m_leftFrom, m_leftTo, m_hullMin, m_hullMax, debug_angles, 0.2, Color( 0, 255, 0 ) )
		else
			debugoverlay.SweptBox( m_leftFrom, m_leftTo, m_hullMin, m_hullMax, debug_angles, 0.2, Color( 255, 0, 0 ) )
		end

		if m_isRightClear then
			debugoverlay.SweptBox( m_rightFrom, m_rightTo, m_hullMin, m_hullMax, debug_angles, 0.2, Color( 0, 255, 0 ) )
		else
			debugoverlay.SweptBox( m_rightFrom, m_rightTo, m_hullMin, m_hullMax, debug_angles, 0.2, Color( 255, 0, 0 ) )
		end

		-- prioritise strafing
		local avoidDir = 0.25 * forward + bot:GetRight() * 4 * avoidResult
		avoidDir:Normalize()

		adjustedGoal = bot:GetPos() + 100 * avoidDir
		goalpos = adjustedGoal

	end

	local side_check = 20

	-- worst case scenario
	if !m_isLeftClear and !m_isRightClear then

		local ground_pos = m_leftToCenter * 1 - bot:GetRight() * side_check
		ground_pos.z = bot:GetPos().z
		ground_pos.z = ground_pos.z - 30

		ground_trace.start = m_leftToCenter - bot:GetRight() * side_check
		ground_trace.endpos = ground_pos

		local ground_result = util_TraceLine( ground_trace )

		if !ground_result.Hit then
			m_isLeftGroundClear = false
			debugoverlay.Line( ground_trace.start, ground_pos, 0.2, Color( 255, 0, 0 ) )
		else
			debugoverlay.Line( ground_trace.start, ground_pos, 0.2, Color( 0, 255, 0 ) )
		end


		ground_pos = m_rightToCenter * 1 + bot:GetRight() * side_check
		ground_pos.z = bot:GetPos().z
		ground_pos.z = ground_pos.z - 30

		ground_trace.start = m_rightToCenter + bot:GetRight() * side_check
		ground_trace.endpos = ground_pos

		ground_result = util_TraceLine( ground_trace )

		if !ground_result.Hit then
			m_isRightGroundClear = false
			debugoverlay.Line( ground_trace.start, ground_pos, 0.2, Color( 255, 0, 0 ) )
		else
			debugoverlay.Line( ground_trace.start, ground_pos, 0.2, Color( 0, 255, 0 ) )
		end

		if m_isLeftGroundClear then
			local avoidDir = 0.5 * forward + bot:GetRight() * -1
			avoidDir:Normalize()

			adjustedGoal = bot:GetPos() + 100 * avoidDir
			goalpos = adjustedGoal
		end

		if m_isRightGroundClear then
			local avoidDir = 0.5 * forward + bot:GetRight()
			avoidDir:Normalize()

			adjustedGoal = bot:GetPos() + 100 * avoidDir
			goalpos = adjustedGoal
		end

	end

	return goalpos
end