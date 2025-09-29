local meta = FindMetaTable("Entity")
if not meta then return end

local E_IsValid = meta.IsValid
local bit_band = bit.band
local bit_bor = bit.bor
local bit_bnot = bit.bnot
local rawget = rawget

hook.Add("NetworkEntityCreated", "NetworkEntityCreated.Collision", function(ent)
	if ent:IsValid() and ent:IsAPhysicsProp() then
		ent:SetCustomGroupAndFlags(ZS_COLLISIONGROUP_DYNAMICPROP, ZS_COLLISIONFLAGS_PROP, true)
	end
end)

List_CollisionGroups = List_CollisionGroups or {}
List_CollisionFlags = List_CollisionFlags or {}

function meta:GetCustomCollisionGroup()
	return List_CollisionGroups[self] or 0
end

function meta:GetCollisionFlags()
	return List_CollisionFlags[self] or 0
end

function meta:SetCustomCollisionGroup(NewGroup)
	if List_CollisionGroups[self] == NewGroup then return end

	self._CFG = NewGroup
	List_CollisionGroups[self] = NewGroup
	self:CollisionRulesChanged()
end

function meta:SetCollisionFlags(NewFlags)
	if List_CollisionFlags[self] == NewFlags then return end

	self._CFF = NewFlags
	List_CollisionFlags[self] = NewFlags
	self:CollisionRulesChanged()
end

function meta:SetCustomGroupAndFlags(group, flags)
	if List_CollisionGroups[self] == group and List_CollisionFlags[self] == flags then return end

	self._CFG = group
	self._CFF = flags
	List_CollisionGroups[self] = group
	List_CollisionFlags[self] = flags

	self:CollisionRulesChanged()
end

function meta:AddCollisionFlag(Flag)
	local CurrentFlags = List_CollisionFlags[self] or 0
	if bit_band(CurrentFlags,Flag) == Flag then return end

	self:SetCollisionFlags(bit_bor(CurrentFlags, Flag))
end

function meta:RemoveCollisionFlag(Flag)
	local CurrentFlags = List_CollisionFlags[self] or 0
	if bit_band(CurrentFlags,Flag) == 0 then return end

	self:SetCollisionFlags(bit_band(CurrentFlags,bit_bnot(Flag)))
end

function GM.TryCollides( ent, cg, cf )
	ga,fa = rawget(List_CollisionGroups,ent), rawget(List_CollisionFlags,ent)
	return not ga or not fa or bit_band(ga,cf) ~= 0 or bit_band(cg,fa) ~= 0
end

function GM:ShouldCollide(enta, entb)
	ga,gb,fa,fb = List_CollisionGroups[enta],List_CollisionGroups[entb],List_CollisionFlags[enta],List_CollisionFlags[entb]
	return not ga or not gb or not fa or not fb or bit_band(ga,fb) ~= 0 or bit_band(gb,fa) ~= 0
end

local DTVarFunc = {
	["Int" .. DT_PLAYER_AND_ENTITY_INT_COLLISION_FLAG] = function(e,x) e:SetCustomCollisionCheck(true) rawset(List_CollisionFlags, e, x) e:CollisionRulesChanged() end,
	["Int" .. DT_PLAYER_AND_ENTITY_INT_COLLISION_GROUP] = function(e,x) e:SetCustomCollisionCheck(true) rawset(List_CollisionGroups, e, x) e:CollisionRulesChanged() end
}

-- SetNW2 isnt worth for collision and animation...
Old_DTVar_ReceiveProxyGL = Old_DTVar_ReceiveProxyGL or DTVar_ReceiveProxyGL
function DTVar_ReceiveProxyGL(ent, name, id, val)
	local f = DTVarFunc[name .. id]
	if f then
		f(ent, val)
	end

	Old_DTVar_ReceiveProxyGL(ent, name, id, val)
end