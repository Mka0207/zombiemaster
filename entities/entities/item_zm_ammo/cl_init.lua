include("shared.lua")

local E_Meta = FindMetaTable("Entity")
local E_WorldSpaceCenter = E_Meta.WorldSpaceCenter
local E_GetPos = E_Meta.GetPos
local E_GetTable = E_Meta.GetTable

local V_Meta = FindMetaTable("Vector")
local V_Dot = V_Meta.Dot
local V_DistToSqr = V_Meta.DistToSqr

local hook_Call = hook.Call

local EyeVector = EyeVector
local EyePos = EyePos
local CurTime = CurTime
local LocalPlayer = LocalPlayer

ENT.PickupCache = false
ENT.NextUpdateOutline = 0

function ENT:Initialize()
    self:SetCustomGroupAndFlags(ZS_COLLISIONGROUP_AMMO, ZS_COLLISIONFLAGS_AMMO, true)
end

function ENT:ShouldDrawOutline()
    if not GAMEMODE.bUseItemHalos then return false end
    
    local ct = CurTime()
    local tb = E_GetTable(self)
	if (tb.NextUpdateOutline or 0)<ct then
        tb.NextUpdateOutline = ct+0.25
        if IsValid(self:GetOwner()) then 
            tb.PickupCache = false 
        else
            local DotDist = V_Dot(EyeVector(), E_WorldSpaceCenter(self)-EyePos())
            if DotDist<1 or DotDist>20000 then
                tb.PickupCache = false 
            else
                tb.PickupCache = V_DistToSqr(E_GetPos(self), E_GetPos(MySelf)) < 42000 and hook_Call("PlayerCanPickupItem", GAMEMODE, MySelf, self)
            end
        end
	end
    
    return tb.PickupCache
end