AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName             = "Revolver"

    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 55
    
    SWEP.WeaponSelectIconLetter = "e"
end

sound.Add({
	name = 			"MMOD_Weapon_357.CloseLoader",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		"<weapons/mmod/357/357_reload4.wav"	
})

sound.Add({
	name = 			"MMOD_Weapon_357.Fidget_Spinner",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		"<weapons/mmod/357/357_spin2.wav"	
})

sound.Add({
	name = 			"MMOD_Weapon_357.Hammer_Pull",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		"<weapons/mmod/357/357_hammerpull.wav"	
})

sound.Add({
	name = 			"MMOD_Weapon_357.Hammer_Release",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		"<weapons/mmod/357/357_hammerrelease.wav"	
})

sound.Add({
	name = 			"MMOD_Weapon_357.OpenLoader",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		"<weapons/mmod/357/357_reload1.wav"	
})

sound.Add({
	name = 			"MMOD_Weapon_357.RemoveLoader",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		"<weapons/mmod/357/357_reload2.wav"	
})

sound.Add({
	name = 			"MMOD_Weapon_357.ReplaceLoader",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		"<weapons/mmod/357/357_reload3.wav"	
})

sound.Add({
	name = 			"MMOD_Weapon_357.Spin",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		"<weapons/mmod/357/357_spin1.wav"	
})

sound.Add({
	name = 			"MMOD_Weapon_357.Single",			
	channel = 		CHAN_WEAPON,
	volume = 		0.93,
	level = 		SNDLVL_GUNFIRE,
	pitch = 		{ 88, 93 },
	sound = 		{"<weapons/mmod/357/357_fire1.wav", "<weapons/mmod/357/357_fire2.wav", "<weapons/mmod/357/357_fire3.wav"}	
})

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 1
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/mmod/c_357.mdl"
SWEP.WorldModel                = Model("models/weapons/w_357.mdl")
SWEP.UseHands                  = true

SWEP.Primary.Sound             = Sound("MMOD_Weapon_357.Single")
SWEP.EmptySound                = Sound("Weapon_Pistol_ZM.Empty")

SWEP.DrawSound                 = "<weapons/mmod/357/357_deploy.wav"
SWEP.HoldType                  = "revolver"

SWEP.Primary.ClipSize           = 6
SWEP.Primary.DefaultClip        = 6
SWEP.Primary.Damage             = 45
SWEP.Primary.NumShots           = 1
SWEP.Primary.Delay              = 0.7
SWEP.Primary.Automatic          = true
SWEP.Primary.Ammo               = "revolver"
SWEP.Primary.ViewPunchMin       = Angle(-8, -1, 0)
SWEP.Primary.ViewPunchMax       = Angle(-8, 1, 0)

SWEP.UseCustomMuzzleFlash       = true
SWEP.MuzzleEffect               = "CS_MuzzleFlash"
SWEP.MuzzleAttachment           = "muzzle"

function SWEP:GetBulletSpread(cone)
    return VECTOR_CONE_1DEGREES
end