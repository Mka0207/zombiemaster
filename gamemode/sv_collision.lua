-- if CollisionLuaLoaded then return end
-- -- To Avoid lua refresh as well...

if not CollisionLuaLoaded then
	List_CollisionGroups = {}
	List_CollisionFlags = {}

	CollisionLuaLoaded = true
end

local meta = FindMetaTable("Entity")
if not meta then return end

local bit_band = bit.band
local bit_bor = bit.bor
local bit_bnot = bit.bnot

function meta:GetCustomCollisionGroup()
	return List_CollisionGroups[self] or 0
end

function meta:GetCollisionFlags()
	return List_CollisionFlags[self] or 0
end

-- Whatever if you want swap the collision flag for player movement. Its used for proj or etc... look at zs new code soon.
local function SWAPCollision_MOVEMENT(self, flags)
	return flags
end

function meta:SetCustomCollisionGroup(NewGroup, bSimulated)
	if List_CollisionGroups[self] == NewGroup then return end

	self:SetDTInt(DT_PLAYER_AND_ENTITY_INT_COLLISION_GROUP, NewGroup)

	if ShouldCollide_SetGroup then
		ShouldCollide_SetGroup(self:EntIndex(), NewGroup)

		if ShouldCollide_SetGroup_gm then
			ShouldCollide_SetGroup_gm(self:EntIndex(), NewGroup)
		end
	end

	List_CollisionGroups[self] = NewGroup

	self:CollisionRulesChanged()
end

function meta:SetCollisionFlags(NewFlags)
	if List_CollisionFlags[self] == NewFlags then return end

	local swapflags = SWAPCollision_MOVEMENT(self, NewFlags)
	self:SetDTInt(DT_PLAYER_AND_ENTITY_INT_COLLISION_FLAG, swapflags)

	if ShouldCollide_SetFlag then
		ShouldCollide_SetFlag(self:EntIndex(), NewFlags)

		if ShouldCollide_SetFlag_gm then
			ShouldCollide_SetFlag_gm(self:EntIndex(), swapflags)
		end
	end

	List_CollisionFlags[self] = NewFlags

	self:CollisionRulesChanged()
end

function meta:SetCustomGroupAndFlags(group, flags)
	if List_CollisionGroups[self] == group and List_CollisionFlags[self] == flags then return end

	local swapflags = SWAPCollision_MOVEMENT(self, flags)

	self:SetDTInt(DT_PLAYER_AND_ENTITY_INT_COLLISION_FLAG, swapflags)
	self:SetDTInt(DT_PLAYER_AND_ENTITY_INT_COLLISION_GROUP, group)

	if ShouldCollide_SetGroupAndFlag then
		ShouldCollide_SetGroupAndFlag(self:EntIndex(), flags, group)

		if ShouldCollide_SetGroupAndFlag_gm then
			ShouldCollide_SetGroupAndFlag_gm(self:EntIndex(), swapflags, group)
		end
	end

	List_CollisionGroups[self] = group
	List_CollisionFlags[self] = flags

	self:CollisionRulesChanged()
end

function meta:AddCollisionFlag(Flag)
	local CurrentFlags = List_CollisionFlags[self] or 0
	if bit_band(CurrentFlags, Flag) == Flag then return end

	self:SetCollisionFlags(bit_bor(CurrentFlags, Flag))
end

function meta:RemoveCollisionFlag(Flag)
	local CurrentFlags = List_CollisionFlags[self] or 0
	if bit_band(CurrentFlags, Flag) == 0 then return end

	self:SetCollisionFlags(bit_band(CurrentFlags, bit_bnot(Flag)))
end

local ShouldCleanTables = false
hook.Add("EntityRemoved", "EntityRemoved.CollisionMode", function(ent)
	if not ShouldCleanTables and (List_CollisionGroups[ent] or List_CollisionFlags[ent]) then
		List_CollisionFlags[ent] = nil
		List_CollisionGroups[ent] = nil

		if ShouldCollide_SetGroupAndFlag then
			ShouldCollide_SetGroupAndFlag(ent:EntIndex(), 0, 0)

			if ShouldCollide_SetGroupAndFlag_gm then
				ShouldCollide_SetGroupAndFlag_gm(ent:EntIndex(), 0, 0) -- gamemovement
			end
		end
	end
end, HOOK_MONITOR_HIGH)

-- Wipe entire tables to save RAM Memory!
local function CleanMemory()
	if true then return end -- bug ill work soon

	ShouldCleanTables = true

	List_CollisionFlags = {}
	List_CollisionGroups = {}

	if ShouldCollide_EraseTable then
		ShouldCollide_EraseTable()
	end

	ShouldCleanTables = false
end

hook.Add("ShutDown", "ShutDown.CollisionMode", CleanMemory, HOOK_MONITOR_HIGH)
hook.Add("PreCleanupMap", "PreCleanupMap.CollisionMode", CleanMemory, HOOK_MONITOR_HIGH)

function GM:ShouldCollide(enta, entb)
	local ga, gb, fa, fb = rawget(List_CollisionGroups, enta), rawget(List_CollisionGroups, entb), rawget(List_CollisionFlags, enta), rawget(List_CollisionFlags, entb)
    return not ga or not gb or not fa or not fb or bit_band(ga, fb) ~= 0 or bit_band(gb, fa) ~= 0
end

hook.Add("OnEntityCreated", "OnEntityCreated.CollisionMode", function(ent)
	if ent:IsValid() and ent:IsAPhysicsProp() then
		ent:SetCustomGroupAndFlags(ZS_COLLISIONGROUP_PROP, ZS_COLLISIONFLAGS_PROP, true)
	end
end)

local function TryToCollides(e, g, f)
	local ga, fa = rawget(List_CollisionGroups, e), rawget(List_CollisionFlags, e)
	return not ga or not fa or bit_band(ga, f) ~= 0 or bit_band(g, fa) ~= 0
end

function GM:TryCollides(e, g, f)
	return TryToCollides(e, g, f)
end