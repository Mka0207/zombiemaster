AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_shotgunbase")

if CLIENT then
    SWEP.PrintName             = "Rifle"

    SWEP.ViewModelFlip         = true
    SWEP.ViewModelFOV          = 55
    
    SWEP.WeaponSelectIconLetter = "f"
end

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 3
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/m9k_tfa/c_zm_winchester1873.mdl"
SWEP.WorldModel                = Model( "models/weapons/rifle_zm_3rd.mdl" )
SWEP.UseHands                  = true

SWEP.EmptySound                = Sound("Weapon_Rifle_ZM.Empty")
SWEP.PumpSound                 = Sound("Weapon_Rifle_ZM.Special1")

SWEP.HoldType                  = "ar2"

SWEP.Primary.Sound             = Sound("Weapon_Rifle_ZM.Single")
SWEP.Primary.ClipSize          = 11
SWEP.Primary.DefaultClip       = 11
SWEP.Primary.MinDamage         = 55
SWEP.Primary.MaxDamage         = 65
SWEP.Primary.NumShots          = 1
SWEP.Primary.Delay             = 0.9
SWEP.Primary.Cone              = 0
SWEP.Primary.DamageType        = DMG_BULLET
SWEP.Primary.Automatic         = true
SWEP.Primary.Ammo              = "357"
SWEP.Primary.ViewPunchMin      = Angle(-10, -2, 0)
SWEP.Primary.ViewPunchMax      = Angle(-6, 2, 0)

SWEP.ReloadDelay               = 0.8

SWEP.Secondary.Delay           = 0.25
SWEP.PumpAct                   = {ACT_VM_PULLBACK_LOW, ACT_VM_PULLBACK_HIGH}
SWEP.EndReloadPump             = ACT_SHOTGUN_RELOAD_FINISH

SWEP.UseCustomMuzzleFlash      = true
SWEP.MuzzleEffect              = "CS_MuzzleFlash"
SWEP.MuzzleAttachment          = "muzzle"

SWEP.Soundscripts = {
    [ACT_VM_PULLBACK_LOW] = {
		{time = 5 / 30, snd = Sound("Weapon_Rifle_ZM.Special1")}
    },    
    [ACT_VM_PULLBACK_HIGH] = {
		{time = 3 / 30, snd = Sound("Weapon_Rifle_ZM.Special1")}
    },
    [ACT_VM_RELOAD] = {
		{time = 7 / 30, snd = Sound("Weapon_Rifle_ZM.Reload")}
    },   
    [ACT_SHOTGUN_RELOAD_FINISH] = {
		{time = 6 / 30, snd = Sound("Weapon_Rifle_ZM.Special1")}
    }
}

function SWEP:SetupDataTables()
    BaseClass.SetupDataTables(self)
    self:NetworkVar( "Bool", 2, "Zoomed" )
end

function SWEP:Initialize()
    BaseClass.Initialize(self)
    self:SetZoomed(false)
end

function SWEP:SecondaryAttack()
    if not self:CanSecondaryAttack() then return end
     
    local owner = self.Owner

    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

    local zoomed = self:GetZoomed()
    self:SetZoomed(not zoomed)

    owner:SetFOV(owner:GetInfo("fov_desired") * (zoomed and 1 or 0.25), zoomed and 0.35 or 0.5)
end

function SWEP:CanSecondaryAttack()
	local owner = self:GetOwner()
	if owner:IsHolding() then return end
    
    return self:GetNextSecondaryFire() <= CurTime()
end

function SWEP:Holster()
    if self:GetZoomed() then
        local owner = self.Owner
        owner:SetFOV(owner:GetInfo("fov_desired"), 0.5)
        self:EmitSound("weapons/sniper/sniper_zoomout.wav", 50, 100)
        self:SetZoomed(false)
    end

    return true
end

function SWEP:OnRemove()
    local owner = self.Owner
    if owner:IsValid() and self:GetZoomed() then
        owner:SetFOV(owner:GetInfo("fov_desired"), 0.5)
    end
end

function SWEP:AdjustMouseSensitivity()
    return self:GetZoomed() and 0.5 or 1.0
end

if not CLIENT then return end

function SWEP:PreDrawViewModel(vm, wep, ply)
    if self.ShowViewModel == false or self:GetZoomed() then render.SetBlend(0) end
end