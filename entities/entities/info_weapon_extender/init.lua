AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    local owner = self:GetOwner()
    if not owner:IsValid() then self:Remove() return end
    
    self:SetModel(owner:GetWeaponWorldModel())
    self:SetMoveType(MOVETYPE_NONE)
    self:SetNotSolid(true)
    self:SetUseType(SIMPLE_USE)
    
    local this = self
    timer.Simple(1, function()
        if not IsValid(this) then return end
        
        this:UseTriggerBounds(true, 36)
        this:SetTrigger(true)
    end)
end

function ENT:IsValidToPickup(owner, activator)
    return hook.Call("PlayerCanPickupWeapon", GAMEMODE, activator, owner)
end

function ENT:PickupWeapon(activator)
    local owner = self:GetOwner()
    if not self:IsValidToPickup(owner, activator) then return false end
    
    local class = owner:GetClass()
    local wep = activator:Give(class)
    if wep:IsValid() then
        if not wep.IsMelee then
            wep:SetClip1(self.m_Clip1)
            wep:SetClip2(self.m_Clip2)
        end
        
        self:Remove()
        owner:Remove()
    end
end

function ENT:TryPickup(ent)
    local owner = self:GetOwner()
    if not owner:IsValid() or not IsValid(ent) or not IsValid(self) or not ent:IsPlayer() then return end
    self:PickupWeapon(ent)
end

function ENT:StartTouch(ent)
    self:TryPickup(ent)
end

function ENT:Touch(ent)
    if (ent.PickupCooldown or 0) > CurTime() then return end
    ent.PickupCooldown = CurTime() + 0.1
    
    self:TryPickup(ent)
end

function ENT:EndTouch(ent)
    self:TryPickup(ent)
end

function ENT:Use(activator)
    local owner = self:GetOwner()
    if not owner:IsValid() then
        self:Remove()
        return
    end
    
    if not activator:IsValid() or not activator:IsPlayer() then return end
    
    if self:IsValidToPickup(owner, activator) then
        self:PickupWeapon(ent)
    else
        activator:PickupObject(owner)
    end
end

function ENT:Think()
    if not self:GetOwner():IsValid() then self:Remove() end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_NEVER
end