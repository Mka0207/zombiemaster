AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_basemelee")

if CLIENT then
    SWEP.PrintName             = "Sledge"
    SWEP.ViewModelFOV          = 65

    SWEP.WeaponSelectIconLetter = "i"
end

SWEP.ViewModel                 = "models/weapons/c_sledgehammer_zm.mdl"
SWEP.WorldModel                = "models/weapons/sledgehammer3rd_zm.mdl"
SWEP.UseHands                  = true

SWEP.Slot                      = 2
SWEP.HoldType                  = "melee2"

SWEP.Primary.MinDamage         = 55
SWEP.Primary.MaxDamage         = 60
SWEP.Primary.Force             = SWEP.Primary.Damage
SWEP.Primary.Reach             = 85
SWEP.Primary.HitSound          = Sound("physics/metal/metal_canister_impact_hard1.wav")
SWEP.Primary.HitFleshSound     = Sound("physics/body/body_medium_break2.wav")
SWEP.Primary.MissSound         = Sound("weapons/iceaxe/iceaxe_swing1.wav")
SWEP.Primary.Delay             = 2.8

SWEP.Secondary.MinDamage       = 15
SWEP.Secondary.MaxDamage       = 25
SWEP.Secondary.HitSound        = "Weapon_Crowbar.Melee_Hit"
SWEP.Secondary.HitFleshSound   = "Weapon_Crowbar.Melee_Hit"
SWEP.Secondary.MissSound       = "Weapon_Crowbar.Single"

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 1, "AttackTime")
    self:NetworkVar("Bool", 1, "IsSecondary")
end

function SWEP:Initialize()
    BaseClass.Initialize(self)
    self:SetAttackTime(0)
    self:SetIsSecondary(false)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

    self:SetHoldType("melee")
    self:SendWeaponAnim(ACT_VM_HITCENTER2)
    self:SetAttackTime(CurTime() + 1.75)

    self:SetIsSecondary(false)

    self:SetNextIdle(CurTime() + self:SequenceDuration())
end

function SWEP:SecondaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

    self:SetHoldType("melee")
    self:SendWeaponAnim(ACT_VM_HITCENTER)
    self:SetAttackTime(CurTime() + 1.5)

    self:SetIsSecondary(true)

    self:SetNextIdle(CurTime() + self:SequenceDuration())
end

function SWEP:CanSecondaryAttack()
    return self:GetNextSecondaryFire() <= CurTime()
end

SWEP.Bullet = {Tracer = 0, Spread = Vector(0, 0, 0), Num = 1}
function SWEP:Swing(alt)
    self:SetHoldType("melee2")

    local owner = self.Owner
    owner:SetAnimation(PLAYER_ATTACK1)

    local hitsound = Either(alt, self.Secondary.HitSound, self.Primary.HitSound)
    local hitfleshsound = Either(alt, self.Secondary.HitFleshSound, self.Primary.HitFleshSound)
    local misssound = Either(alt, self.Secondary.MissSound, self.Primary.MissSound)
    local mindamage, maxdamage = Either(alt, self.Secondary.MinDamage or 0, self.Primary.MinDamage or 0), Either(alt, self.Secondary.MaxDamage or 0, self.Primary.MaxDamage or 0)
    local damage = Either(self.Primary.Damage ~= nil, self.Primary.Damage, math.random(mindamage, maxdamage))

    owner:LagCompensation(true)
    local trace = util.TraceLine( {
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + (self.Owner:GetAimVector() * self.Primary.Reach),
        filter = owner
    } )
    owner:LagCompensation(false)

    if trace.Hit and IsFirstTimePredicted() then
        if CLIENT then
            self:ClearCLFireBullet()
        end

        self.Bullet.Src    = owner:GetShootPos()
        self.Bullet.Dir    = owner:GetAimVector()
        self.Bullet.Distance = self.Primary.Reach
        self.Bullet.Force  = damage
        self.Bullet.Damage = damage
        self.Bullet.HullSize = self.Primary.Hull or 1

        local this = self
        self.Bullet.Callback = function(attacker, trace, dmginfo)
            this:DefaultCallBack(attacker, trace, dmginfo)
            if CLIENT and this.ClientBulletInfos then
                this:ClientBulletInfos(attacker, trace, dmginfo)
            end
        end

        owner:FireBullets(self.Bullet)

        if trace.MatType == MAT_GRATE or bit.band(trace.Contents, CONTENTS_GRATE) ~= 0 then
            local ent = trace.Entity
            if IsValid(ent) and ent.TakeDamage then
                ent:TakeDamage(self.Bullet.Damage, owner, self)
            end
        end

        if trace.MatType == MAT_FLESH then
            self:EmitSound(hitfleshsound)
        else
            self:EmitSound(hitsound)
        end

        self:SentWeaponInfos(owner, self.Bullet)
        self:FirebulletSendCL()
    else
        self:EmitSound(misssound, 75, math.random(35, 45))
    end
end

function SWEP:Think()
    BaseClass.Think(self)

    if self:GetAttackTime() ~= 0 and self:GetAttackTime() <= CurTime() then
        self:SetAttackTime(0)
        self:Swing(self:GetIsSecondary())
    end
end

--[[AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_basemelee")

if CLIENT then
    SWEP.PrintName             = "Sledge"
    SWEP.ViewModelFOV          = 75

    SWEP.WeaponSelectIconLetter = "i"
end

SWEP.ViewModel                 = "models/weapons/c_sledgehammer/c_sledgehammer.mdl"
SWEP.WorldModel                = "models/weapons/c_sledgehammer/w_sledgehammer.mdl"
SWEP.UseHands                  = true

SWEP.Slot                      = 2
SWEP.HoldType                  = "melee2"

SWEP.Primary.Damage            = 55
SWEP.Primary.Force             = SWEP.Primary.Damage
SWEP.Primary.Reach             = 90
SWEP.Primary.HitSound          = Sound("physics/metal/metal_canister_impact_hard1.wav")
SWEP.Primary.HitFleshSound     = Sound("physics/body/body_medium_break2.wav")
SWEP.Primary.MissSound         = Sound("Weapon_Sledge_ZM.Primary")
SWEP.Primary.Delay             = 1.2
SWEP.Primary.Hull              = 6

SWEP.SwingRotation = Angle(20, 0, -30)
SWEP.SwingOffset = Vector(0, -30, -10)
SWEP.SwingTime = 0.85
SWEP.SwingHoldType = "melee"

AccessorFuncDT(SWEP, "AttackTime", "Float", 1)
AccessorFuncDT(SWEP, "IsSwinging", "Bool", 1)

function SWEP:Initialize()
    BaseClass.Initialize(self)
    self:SetAttackTime(0)
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    local owner = self:GetOwner()
    if not owner:IsValid() then return end

    local vm = owner:GetViewModel()
    if not vm:IsValid() then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)

    self:SetAttackTime(CurTime() + self.SwingTime)
    self:SetIsSwinging(true)

    self:SetNextIdle(CurTime() + self.SwingTime)
end

function SWEP:Swing()
    self:SetIsSwinging(false)

    local owner = self.Owner
    local trace = util.TraceLine( {
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + (self.Owner:GetAimVector() * self.Primary.Reach),
        filter = team.GetPlayers(owner:Team())
    } )
    if trace.Hit then
        self:SendWeaponAnim(ACT_VM_HITCENTER)
        self:DoMeleeTrace(self.Primary.Damage)

        if trace.MatType == MAT_FLESH then
            self:EmitSound(self.Primary.HitFleshSound)
        else
            self:EmitSound(self.Primary.HitSound)
        end
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
        self:EmitSound(self.Primary.MissSound)
    end
end

function SWEP:Think()
    BaseClass.Think(self)

    if self:GetAttackTime() ~= 0 and self:GetAttackTime() < CurTime() then
        self:SetAttackTime(0)
        self:Swing()
    end
end

function SWEP:GetViewModelPosition(pos, ang)
	local owner = self:GetOwner()

	if self:GetIsSwinging() then
		local rot = self.SwingRotation
		local offset = self.SwingOffset

		ang = Angle(ang.pitch, ang.yaw, ang.roll) -- Copy

		local swingend = self:GetAttackTime()
		local delta = self.SwingTime - math.Clamp(swingend - CurTime(), 0, self.SwingTime)
		local power = CosineInterpolation(0, 1, delta / self.SwingTime)

		if power >= 0.9 then
			power = (1 - power) ^ 0.4 * 2
		end

		pos = pos + offset.x * power * ang:Right() + offset.y * power * ang:Forward() + offset.z * power * ang:Up()

		ang:RotateAroundAxis(ang:Right(), rot.pitch * power)
		ang:RotateAroundAxis(ang:Up(), rot.yaw * power)
		ang:RotateAroundAxis(ang:Forward(), rot.roll * power)
	end

	return pos, ang
end
--]]