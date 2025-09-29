AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName             = "Mac 10"

    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 70

    SWEP.WeaponSelectIconLetter = "a"

    SWEP.Soundscripts = {
        [ACT_VM_RELOAD] = {
            {time = 0.3, snd = "weapons/zm/mac10/magout.ogg"},
            {time = 0.8, snd = "weapons/zm/mac10/magin.ogg", pitch = 110},
        },

        [ACT_VM_RELOAD_EMPTY] = {
            {time = 0.3, snd = "weapons/zm/mac10/magout.ogg"},
            {time = 0.8, snd = "weapons/zm/mac10/magin.ogg", pitch = 110},
            {time = 1.3, snd = "weapons/zm/mac10/boltback.ogg"},
            {time = 1.5, snd = "weapons/zm/mac10/boltforward.ogg"},
        },

        [ACT_VM_DRAW] = {
            {time = 0, snd = "<weapons/zm/mac10/deploy.ogg"},
            {time = 0.3, snd = "<weapons/zm/mac10/unfold.ogg"},
        },

        [ACT_VM_FIDGET] = {
            {time = 0.1, snd = "<weapons/foley/medium2.ogg", pitch = 105},
            {time = 1.4, snd = "<weapons/foley/light1.ogg", pitch = 100},
            {time = 2.6, snd = "<weapons/foley/light2.ogg", pitch = 100},
        },

    }
end

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 3
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/newzm/c_mac_zm.mdl"
SWEP.WorldModel                = Model( "models/weapons/smg_zm_3rd.mdl" )
SWEP.UseHands                  = true

--SWEP.Primary.Sound           = "weapons/zm/mac10/fire.ogg"
SWEP.Primary.Sound             = Sound("Weapon_SMG_ZM.Single")
SWEP.EmptySound                = "weapons/zm/mac10/empty.ogg"

SWEP.HoldType                  = "pistol"

SWEP.Primary.ClipSize          = 30
SWEP.Primary.DefaultClip       = 30
SWEP.Primary.Damage            = 17
SWEP.Primary.NumShots          = 1
SWEP.Primary.Delay             = 0.09
SWEP.Primary.Cone              = VECTOR_CONE_4DEGREES

SWEP.Primary.Automatic         = true
SWEP.Primary.Ammo              = "smg1"

SWEP.Secondary.Delay           = 0.3
SWEP.Secondary.ClipSize        = 1
SWEP.Secondary.DefaultClip     = 1
SWEP.Secondary.Automatic       = false
SWEP.Secondary.Ammo            = "dummy"

SWEP.EasyDampen                = 0.5
SWEP.VerticalKick              = 0.5
SWEP.SlideLimit                = 2

function SWEP:AddViewKick(bSecondaryAttack)
    self:DoMachineGunKick(self.EasyDampen, self.VerticalKick, self.m_fFireDuration, self.SlideLimit)
end