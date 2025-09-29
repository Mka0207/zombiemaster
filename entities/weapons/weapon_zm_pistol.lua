AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName             = "Pistol"

    SWEP.ViewModelFlip         = false


    SWEP.WeaponSelectIconLetter = "d"

    SWEP.Soundscripts = {
        [ACT_VM_RELOAD] = {
           {time = 0.3, snd = "weapons/zm/pistol/magout.ogg"},
           {time = 0.8, snd = "weapons/zm/pistol/magin.ogg"},
        },

        [ACT_VM_RELOAD_EMPTY] = {
            {time = 0.3, snd = "weapons/zm/pistol/magout.ogg"},
            {time = 0.7, snd = "weapons/zm/pistol/magin.ogg"},
            {time = 1.25, snd = "weapons/zm/pistol/sliderelease.ogg", pitch = 95}
        },

        [ACT_VM_DRAW] = {
            {time = 0, snd = "<weapons/zm/rifle/handle.ogg", pitch = 100},
        },

        [ACT_VM_FIDGET] = {
            {time = 0.1, snd = "<weapons/zm/rifle/handle5.ogg", pitch = 105},
            {time = 1.6, snd = "<weapons/foley/light1.ogg", pitch = 100},
        },

    }

end
SWEP.ViewModelFOV          = 80


SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 1
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/newzm/c_pistol_zm.mdl"
SWEP.WorldModel                = Model( "models/weapons/pistol3rd_zm.mdl" )
SWEP.UseHands                  = true

SWEP.ReloadSound               = ""
SWEP.Primary.Sound             = Sound("Weapon_pistol_zm.Single")
--SWEP.Primary.Sound           = "weapons/zm/pistol/fire.ogg"
SWEP.EmptySound                = Sound("Weapon_pistol_zm.Empty")

SWEP.HoldType                  = "pistol"

SWEP.Primary.ClipSize          = 20
SWEP.Primary.DefaultClip       = 20
SWEP.Primary.Damage            = 16
SWEP.Primary.NumShots          = 1
SWEP.Primary.Delay             = 0.255
SWEP.Primary.Automatic         = true
SWEP.Primary.Ammo              = "pistol"
SWEP.Primary.ViewPunchMin      = Angle(0.25, -0.6, 0)
SWEP.Primary.ViewPunchMax      = Angle(0.5, 0.6, 0)
SWEP.Primary.Cone              = VECTOR_CONE_2DEGREES

SWEP.Secondary.Delay           = 0.3
SWEP.Secondary.ClipSize        = 1
SWEP.Secondary.DefaultClip     = 1
SWEP.Secondary.Automatic       = false
SWEP.Secondary.Ammo            = "dummy"