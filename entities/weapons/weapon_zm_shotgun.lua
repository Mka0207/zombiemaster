AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_shotgunbase")

if CLIENT then
    SWEP.PrintName             = "Shotgun"
    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 65

    SWEP.WeaponSelectIconLetter = "b"

    SWEP.Soundscripts = {
        [ACT_VM_FIDGET] = {
            {time = 0.1, snd = "<weapons/zm/rifle/handle5.ogg", pitch = 105},
            {time = 1.8, snd = "weapons/foley/light2.ogg", pitch = 100},
			{time = 2, snd = "weapons/foley/light3.ogg", pitch = 100},
			{time = 2.65, snd = "<weapons/zm/rifle/handle.ogg", pitch = 105},
        },

		[ACT_VM_PRIMARYATTACK] = {
			{time = 0.25, snd =  "weapons/zm/shotgun/pumpback.ogg"},
			{time = 0.5, snd =  "weapons/zm/shotgun/pumpforward.ogg"},
		},

		[ACT_VM_RELOAD_END_EMPTY] = {
			{time = 0.2, snd =  "weapons/zm/shotgun/pumpback.ogg"},
			{time = 0.35, snd =  "weapons/zm/shotgun/pumpforward.ogg"},
		},

		[ACT_VM_DRAW] = {
            {time = 0.2, snd = "<weapons/zm/rifle/handle.ogg", pitch = 100},
        },
    }
end

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 3
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/newzm/c_shotgun_zm.mdl"
SWEP.WorldModel                = Model( "models/weapons/w_shotgun_zm.mdl" )
SWEP.UseHands                  = true

SWEP.ReloadSound      = Sound("Weapon_Shotgun_ZM.Reload")
--SWEP.Primary.Sound    = "weapons/zm/shotgun/fire.ogg"
SWEP.PumpSound        = ""
SWEP.EmptySound       = "weapons/zm/shotgun/empty.ogg"

SWEP.HoldType                  = "shotgun"

SWEP.Primary.ClipSize          = 8
SWEP.Primary.DefaultClip       = 8
SWEP.Primary.Damage            = 9
SWEP.Primary.NumShots          = 7
SWEP.Primary.Delay             = 1.1
SWEP.Primary.ViewPunchMin      = Angle(-9, -3.5, 0)
SWEP.Primary.ViewPunchMax      = Angle(-5, 3.5, 0)
SWEP.Primary.Cone              = VECTOR_CONE_7DEGREES

SWEP.bUsePumpSoundOnReloadEnd  = false

SWEP.EndReloadPump             = ACT_SHOTGUN_RELOAD_FINISH
SWEP.EndReloadPumpEmpty        = ACT_VM_RELOAD_END_EMPTY

SWEP.ReloadDelay               = 0.3
SWEP.InspectAnimThirdperson    = "taunt_rancher"
function SWEP:GetPumpActivity()
    return 0
end