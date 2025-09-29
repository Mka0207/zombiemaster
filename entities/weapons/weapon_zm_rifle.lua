AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_shotgunbase")

if CLIENT then
    SWEP.PrintName             = "Rifle"

    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 68

    SWEP.WeaponSelectIconLetter = "f"

    SWEP.Soundscripts = {
        [ACT_VM_PRIMARYATTACK] = {
            {time = 0.6, snd = "<weapons/zm/rifle/open.ogg"},
            {time = 0.8, snd = "<weapons/zm/rifle/close.ogg"},
        },

        [ACT_SHOTGUN_PUMP] = {
            {time = 0.65, snd = "Weapon_Rifle_ZM.Special1"},

        },

        [ACT_VM_RELOAD] = {
           {time = 0, snd = "<weapons/zm/rifle/insert.ogg"},
        },

        [ACT_VM_RELOAD_EMPTY] = {
            {time = 0.4, snd = "<weapons/zm/rifle/raise_speedloader.ogg", pitch = 90},
            {time = 0.9, snd = "<weapons/zm/rifle/push_speedloader.ogg", pitch = 125},
            {time = 1.3, snd = "weapons/zm/rifle/bulletrack_speedloader.ogg"},
            {time = 2, snd = "<weapons/zm/rifle/handle.ogg"},
            {time = 2.5, snd = "<weapons/zm/rifle/push_speedloader.ogg", pitch = 125},
            {time = 2.85, snd = "<weapons/zm/rifle/handle.ogg", pitch = 85},
            {time = 3.3, snd = "weapons/zm/rifle/bulletrack_speedloader.ogg", pitch = 95},
            {time = 4, snd = "<weapons/zm/rifle/open.ogg"},
            {time = 4.2, snd = "<weapons/zm/rifle/close.ogg"},
         },

        [ACT_VM_FIDGET] = {
            {time = 0.1, snd = "<weapons/zm/rifle/handle5.ogg", pitch = 105},
            {time = 1.8, snd = "<weapons/zm/rifle/handle.ogg", pitch = 100},
        },

        [ACT_VM_DRAW] = {
            {time = 0, snd = "<weapons/zm/rifle/handle5.ogg", pitch = 100},

        },
    }
end

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 3
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/newzm/c_rifle_zm.mdl"
SWEP.WorldModel                = Model( "models/weapons/rifle_zm_3rd.mdl" )
SWEP.UseHands                  = true

SWEP.ReloadSound               = ""
SWEP.EmptySound                = Sound("Weapon_Rifle_ZM.Empty")
SWEP.PumpSound                 = ""

SWEP.HoldType                  = "ar2"

SWEP.Primary.Sound             = Sound("<weapons/zm/rifle/fire.ogg")
SWEP.Primary.ClipSize          = 11
SWEP.Primary.DefaultClip       = 11
SWEP.Primary.Damage            = 90
SWEP.Primary.NumShots          = 1
SWEP.Primary.Delay             = 1.225
SWEP.Primary.Cone              = VECTOR_CONE_0DEGREES
SWEP.Primary.DamageType        = DMG_BULLET
SWEP.Primary.Automatic         = true
SWEP.Primary.Ammo              = "357"
SWEP.Primary.ViewPunchMin      = Angle(-10, -2, 0)
SWEP.Primary.ViewPunchMax      = Angle(-6, 2, 0)
SWEP.MaxPenetrations           = 4
SWEP.PenetrationDamageMultiplier = 0.75
SWEP.AttackAnimRate            = 1.25

SWEP.ReloadDelay               = 0.8
SWEP.bEmptyReloadSpeedLoader   = true
SWEP.EndReloadPump             = ACT_SHOTGUN_RELOAD_FINISH

SWEP.Secondary.Delay           = 0.25

AccessorFuncDT(SWEP, "Zoomed", "Bool", 2)

function SWEP:Initialize()
    BaseClass.Initialize(self)
    self:SetZoomed(false)
end

function SWEP:SecondaryAttack()
    if not self:CanSecondaryAttack() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

    local zoomed = self:GetZoomed()
    self:SetZoomed(not zoomed)

    owner:SetFOV(owner:GetInfo("fov_desired") * (zoomed and 1 or 0.25), zoomed and 0.35 or 0.5)
end

function SWEP:CanSecondaryAttack()
	local owner = self:GetOwner()
	if not IsValid(owner) or owner:IsHolding() then return end

    return self:GetNextSecondaryFire() <= CurTime()
end

function SWEP:Holster()
    if self:GetZoomed() then
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        owner:SetFOV(owner:GetInfo("fov_desired"), 0.5)
        self:EmitSound("weapons/sniper/sniper_zoomout.wav", 50, 100)
        self:SetZoomed(false)
    end

    return true
end

function SWEP:OnRemove()
    local owner = self:GetOwner()
    if owner:IsValid() and self:GetZoomed() then
        owner:SetFOV(owner:GetInfo("fov_desired"), 0.5)
    end
end

function SWEP:AdjustMouseSensitivity()
    return self:GetZoomed() and 0.5 or 1.0
end

function SWEP:SendReloadAnimation()
    if self.bEmptyReloadSpeedLoader then
        self:SendWeaponAnim(ACT_VM_RELOAD_EMPTY)
        return
    end
    self:SendWeaponAnim(self.ReloadAnim)
end