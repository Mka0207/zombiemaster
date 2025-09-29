AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName             = "Olympia"
    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 65
    
    SWEP.WeaponSelectIconLetter = "b"
    
    SWEP.VMPos = Vector(-0.36,-7.96,-1.68)
    SWEP.VMAng = Vector(0,0,0)
end

sound.Add({
	name = 			"weapon_bo3_olympia.latch",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/bo3/olympia/fly_olympia_latch_open.wav"	
})

sound.Add({
	name = 			"weapon_bo3_olympia.open",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/bo3/olympia/fly_olympia_barrel_open.wav"	
})

sound.Add({
	name = 			"weapon_bo3_olympia.shell_1",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/bo3/olympia/fly_olympia_shell_1.wav"
})

sound.Add({
	name = 			"weapon_bo3_olympia.shell_2",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/bo3/olympia/fly_olympia_shell_2.wav"	
})

sound.Add({
	name = 			"weapon_bo3_olympia.close",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/bo3/olympia/fly_olympia_barrel_close.wav"	
})

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 3
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/bo3/c_zm_bo3_olympia.mdl"
SWEP.WorldModel                = Model("models/weapons/bo3/w_bo3_olympia.mdl")
SWEP.UseHands                  = true

SWEP.WMPos                     = Vector(0.75, 2.796, -1.6)
SWEP.WMAng                     = Angle(-10.844, 90, 192)

SWEP.HoldType                  = "shotgun"

SWEP.Primary.Sound             = Sound("weapons/bo3/olympia/wpn_shotgun_olympia_fire_00.wav")
SWEP.Primary.ClipSize          = 2
SWEP.Primary.DefaultClip       = 2
SWEP.Primary.Damage            = 12
SWEP.Primary.Force             = 2
SWEP.Primary.NumShots          = 7
SWEP.Primary.Delay             = 0.45
SWEP.Primary.Ammo              = "buckshot"
SWEP.Primary.ViewPunchMin      = Angle(-8, -4, 0)
SWEP.Primary.ViewPunchMax      = Angle(-6, 4, 0)
SWEP.Primary.Cone              = VECTOR_CONE_8DEGREES

SWEP.MaxPenetrations            = 1