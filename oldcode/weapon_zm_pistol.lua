AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName             = "Pistol"

    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 60

    SWEP.WeaponSelectIconLetter = "d"
end

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 1
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/newzm/c_pistol_zm.mdl"
SWEP.WorldModel                = Model( "models/weapons/pistol3rd_zm.mdl" )
SWEP.UseHands                  = true

SWEP.ReloadSound               = Sound("Weapon_pistol_zm.Reload")
SWEP.Primary.Sound             = Sound("Weapon_pistol_zm.Single")
SWEP.EmptySound                = Sound("Weapon_pistol_zm.Empty")

SWEP.HoldType                  = "revolver"

SWEP.Primary.ClipSize          = 20
SWEP.Primary.DefaultClip       = 20
SWEP.Primary.MinDamage         = 11
SWEP.Primary.MaxDamage         = 16
SWEP.Primary.NumShots          = 1
SWEP.Primary.Delay             = 0.255
SWEP.Primary.Automatic         = true
SWEP.Primary.Ammo              = "pistol"
SWEP.Primary.ViewPunchMin      = Angle(0.25, -0.6, 0)
SWEP.Primary.ViewPunchMax      = Angle(0.5, 0.6, 0)

SWEP.Secondary.Delay           = 0.3
SWEP.Secondary.ClipSize        = 1
SWEP.Secondary.DefaultClip     = 1
SWEP.Secondary.Automatic       = false
SWEP.Secondary.Ammo            = "dummy"

local PISTOL_ACCURACY_SHOT_PENALTY_TIME     = 0.2
local PISTOL_ACCURACY_MAXIMUM_PENALTY_TIME  = 1.5

function SWEP:Initialize()
    BaseClass.Initialize(self)
    self.flAccuracyPenalty = 0
end

function SWEP:Think()
    BaseClass.Think(self)

    local owner = self:GetOwner()
    if IsValid(owner) and owner:KeyDown(IN_ATTACK) and self:GetNextPrimaryFire() < CurTime() then
        self.flAccuracyPenalty = self.flAccuracyPenalty - FrameTime()
        self.flAccuracyPenalty = math.Clamp(self.flAccuracyPenalty, 0.0, PISTOL_ACCURACY_MAXIMUM_PENALTY_TIME)
    end
end

function SWEP:StartReloading(owner)
    self.flAccuracyPenalty = 0
    self.bClickedOnce = false
end

function SWEP:ShootBullet(dmg, numbul, cone)
    BaseClass.ShootBullet(self, dmg, numbul, cone)
    self.flAccuracyPenalty = self.flAccuracyPenalty + PISTOL_ACCURACY_SHOT_PENALTY_TIME
end

function SWEP:GetBulletSpread(cone)
    local ramp = math.Remap(self.flAccuracyPenalty, 0.0, PISTOL_ACCURACY_MAXIMUM_PENALTY_TIME, 0.0, 1.0)
    return LerpVector(ramp, Vector(0, 0, 0), VECTOR_CONE_2DEGREES)
end