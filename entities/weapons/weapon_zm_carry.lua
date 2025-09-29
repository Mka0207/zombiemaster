AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_basemelee")

if CLIENT then 
    SWEP.PrintName             = "Carry"
    SWEP.WeaponSelectIconLetter = "m"    
end

SWEP.Author                    = "Î¤yler Blu, ErrolLiamP"

SWEP.ViewModel                 = Model("models/weapons/invisible_vm.mdl")
SWEP.WorldModel                = ""
SWEP.UseHands                  = false

SWEP.Slot                      = 0
SWEP.SlotPos                   = 0

SWEP.HoldType                  = "normal"
    
SWEP.PuntForce                 = 3500
SWEP.PullForce                 = 3500
SWEP.MaxMass                   = 300
    
SWEP.Primary.ClipSize          = -1
SWEP.Primary.DefaultClip       = -1
SWEP.Primary.Automatic         = true
SWEP.Primary.Ammo              = ""
    
SWEP.Secondary.ClipSize        = -1
SWEP.Secondary.DefaultClip     = -1
SWEP.Secondary.Automatic       = true
SWEP.Secondary.Ammo            = ""

SWEP.Undroppable               = true

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
end

function SWEP:CanPrimaryAttack()
	if self:GetOwner():IsHolding() then return false end
    return self:GetNextPrimaryFire() <= CurTime()
end

function SWEP:CanSecondaryAttack()
	if self:GetOwner():IsHolding() then return false end
    return self:GetNextSecondaryFire() <= CurTime()
end
    
function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) or not self:CanPrimaryAttack() then return end

    local trace = util.TraceHull({
        start = owner:EyePos(),
        endpos = owner:EyePos() + owner:EyeAngles():Forward() * 64,
        mins = Vector(-8, -8, -8),
        maxs = Vector(8, 8, 8),    
        mask = bit.bor(MASK_SHOT, CONTENTS_GRATE),
        filter = function(ent)
            if not (ent:IsPlayer() or ent:IsWeapon() or ent:GetClass() == "item_zm_ammo") then return true end
        end
    })
    local tgt = trace.Entity
    
    self:SetNextPrimaryFire( CurTime() + 0.5 )
    self:SetNextSecondaryFire( CurTime() + 0.5 )
    
    if not IsValid(tgt) then return end
    if not hook.Call("GravGunPunt", GAMEMODE, owner, tgt) then return end
    if tgt:IsPlayerHolding() then return end
    
    if SERVER then
        local position = trace.HitPos
        local phys = tgt:GetPhysicsObject()
        if IsValid(phys) then
            local mass = phys:GetMass()
            if mass >= self.MaxMass then return end
            
            local ang = Angle(math.Rand(0.2, 1.0), math.Rand(-0.5, 0.5), 0)
            owner:ViewPunch(ang)
            
            phys:ApplyForceCenter(owner:GetAimVector() * self.PuntForce)
            phys:ApplyForceOffset(owner:GetAimVector() * 30 * 0.5, position)
            tgt:SetPhysicsAttacker(owner)
        end
    end
end

function SWEP:SecondaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) or not self:CanSecondaryAttack() then return end
    
    if self.TP then
        self:SendWeaponAnim( ACT_VM_SECONDARYATTACK )
        owner:SetAnimation( PLAYER_ATTACK1 )
        self:Drop()
        return
    end
    
    local trace = util.TraceHull({
        start = owner:EyePos(),
        endpos = owner:EyePos() + owner:EyeAngles():Forward() * 64,
        mins = Vector(-8, -8, -8),
        maxs = Vector(8, 8, 8),    
        mask = bit.bor(MASK_SHOT, CONTENTS_GRATE),
        filter = function(ent)
            if not (ent:IsPlayer() or ent:IsWeapon() or ent:GetClass() == "item_zm_ammo") then return true end
        end
    })
    local tgt = trace.Entity
    
    if not IsValid(tgt) then return end
    if tgt:IsPlayerHolding() then return end
    
    self:SetNextPrimaryFire( CurTime() + 0.5 )
    self:SetNextSecondaryFire( CurTime() + 0.5 )
    
    if SERVER then
        local position = trace.HitPos
        local phys = tgt:GetPhysicsObject()
        if IsValid(phys) then
            if phys:IsMoveable() and not constraint.HasConstraints(tgt) then
                local mass = phys:GetMass()
                if mass >= self.MaxMass then return end
                
                local ang = -Angle(math.Rand(0.2, 1.0), math.Rand(-0.5, 0.5), 0)
                owner:ViewPunch(ang)
                
                phys:ApplyForceCenter(-(owner:GetAimVector() * self.PuntForce))
                phys:ApplyForceOffset(-(owner:GetAimVector() * 30 * 0.5), position)
                tgt:SetPhysicsAttacker(owner)
            end
        end
    end
end

function SWEP:Deploy()
    self:SetNextSecondaryFire(CurTime() + 1)
end