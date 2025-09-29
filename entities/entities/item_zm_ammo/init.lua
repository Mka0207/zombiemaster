AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel(self.Model)
    
    self:SetCustomGroupAndFlags(ZS_COLLISIONGROUP_AMMO, ZS_COLLISIONFLAGS_AMMO, true)
    self:SetCustomCollisionCheck(true)
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    
    self:AddEFlags(EFL_NO_ROTORWASH_PUSH)
    self:UseTriggerBounds(true, 24)
    self:SetTrigger(true)
    self:SetUseType(SIMPLE_USE)
    
    if not self:OnGround() then
        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            phys:EnableMotion(true)
            phys:Wake()
        end
    end
end

function ENT:TryPickup(ent)
    if not IsValid(ent) or not IsValid(self) or not ent:IsPlayer() or not hook.Call("PlayerCanPickupItem", GAMEMODE, ent, self) then return end

    local amount = self.AmmoAmount
    local ammocount = ent:GetAmmoCount(self.AmmoType)
    local wep = ent:GetActiveWeapon()
    if wep and wep:IsValid() then
        local primary = wep:ValidPrimaryAmmo()
        local secondary = wep:ValidSecondaryAmmo()
        
        if (primary and self.AmmoType == primary) or (secondary and self.AmmoType == secondary) then
            ammocount = ammocount - (wep:GetMaxClip1() - wep:Clip1())
        end
    end
    local ammovar = GetConVar("zm_maxammo_"..self.AmmoType)
    if ammovar == nil then return end
    
    local maxammo = ammovar:GetInt()
    
    if (ammocount + amount) > maxammo then
        amount = maxammo - ammocount
    end
    
    ent:GiveAmmo(amount, self.AmmoType)
    
    self.AmmoAmount = self.AmmoAmount - amount
    
    if self.AmmoAmount <= 0 then
        self:Remove()
    end
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

function ENT:OnTakeDamage(dmginfo)
    self:TakePhysicsDamage(dmginfo)
end

function ENT:Use(activator)
    if not IsValid(activator) or not IsValid(self) or not activator:IsPlayer() or (self.UseCooldown or 0) > CurTime() then return end

    if self:IsPlayerHolding() then
        DropEntityIfHeld(self)
        return
    end
    
    if activator:IsHolding() then
        activator:DropObject()
    end
    
    self.UseCooldown = CurTime() + 0.25
    if hook.Call("AllowPlayerPickup", GAMEMODE, activator, self) then
        activator:PickupObject(self)
    end
end

function ENT:AllowPickup(ply)
    return false
end