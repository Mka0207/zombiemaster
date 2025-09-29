AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_basemelee")

if CLIENT then
    SWEP.PrintName             = "Fists"
    SWEP.ViewModelFOV          = 50
end

SWEP.ViewModel                 = "models/weapons/c_smodpunch.mdl"
SWEP.WorldModel                = ""
SWEP.UseHands                  = true

SWEP.Slot                      = 0
SWEP.SlotPos                   = 1
SWEP.HoldType                  = "fist"

SWEP.Primary.Damage            = 10
SWEP.Primary.Force             = SWEP.Primary.Damage
SWEP.Primary.Reach             = 60
SWEP.Primary.HitSound          = "Flesh.ImpactHard"
SWEP.Primary.HitFleshSound     = "Flesh.ImpactHard"
SWEP.Primary.MissSound         = "Weapon_Fists_ZM.Melee_Hit"
SWEP.Primary.Delay             = 0.8
SWEP.Primary.Hull              = 3

SWEP.Undroppable               = true

function SWEP:GetHitAct()
    return ACT_VM_PRIMARYATTACK
end

function SWEP:GetMissAct()
    return ACT_VM_PRIMARYATTACK
end

function SWEP:SecondaryAttack()
    if not self:CanPrimaryAttack() then return end
    
    self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay * 1.5))
    
    local owner = self.Owner
    owner:DoAttackEvent()
    
    local damage = self.Primary.Damage * 2
    local trace = util.TraceLine( {
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + (self.Owner:GetAimVector() * self.Primary.Reach),
        filter = function(ent)
            return hook.Call("ShouldCollide", GAMEMODE, owner, ent)
        end
    } )
    if trace.Hit then
        self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
        
        bullet        = {}
        bullet.Num    = 1
        bullet.Src    = owner:GetShootPos()
        bullet.Dir    = owner:GetAimVector()
        bullet.Distance = self.Primary.Reach
        bullet.Spread = Vector(0, 0, 0)
        bullet.Tracer = 0
        bullet.Force  = self.Primary.Force
        bullet.Damage = damage
        bullet.Callback = self.DefaultCallBack
        
        owner:FireBullets(bullet)
        
        if trace.MatType == MAT_GRATE then
            local ent = trace.Entity
            if IsValid(ent) and ent.TakeDamage then
                ent:TakeDamage(damage, owner, self)
            end
        end
        
        if trace.MatType == MAT_FLESH then
            self:EmitSound(self.Primary.HitFleshSound)
        else
            self:EmitSound(self.Primary.HitSound)
        end
    else
        self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
        self:EmitSound(self.Primary.MissSound)
    end
    
    self:SetNextIdle(CurTime() + self:SequenceDuration())
end

function SWEP:Equip(NewOwner)
    self:RemoveWeaponExtender()
    self.Dropped = false
end

function SWEP:EquipAmmo(ply)
end

function SWEP:ShouldDropOnDie()
    return false
end

function SWEP:PreDrawPlayerHands(vm, weapon, ply)
    render.SetBlend(1)
end

function SWEP:PostDrawPlayerHands(vm, weapon, ply)
    render.SetBlend(0)
end

function SWEP:PreDrawViewModel(vm, weapon, ply)
    render.SetBlend(0)
end

function SWEP:PostDrawViewModel(vm, weapon, ply)
    render.SetBlend(1)
end