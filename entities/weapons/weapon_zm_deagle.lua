AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName             = "Desert Eagle"

    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 70
    
    SWEP.WeaponSelectIconLetter = "e"
    
    SWEP.VMPos                 = Vector(-0.25, -0.15, -0.75)
    SWEP.VMAng                 = Vector(0, 0, 0)
end

sound.Add({
	name = 			"TFA_INS2.DEAGLE.1",			
	channel = 		CHAN_WEAPON,
	volume = 		1.0,
	sound = 		")weapons/tfa_ins2/deagle/de_single.wav"	
})

sound.Add({
	name = 			"TFA_INS2.DEAGLE.Boltback",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		")weapons/tfa_ins2/deagle/handling/deagle_boltback.wav"	
})

sound.Add({
	name = 			"TFA_INS2.DEAGLE.Boltrelease",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		")weapons/tfa_ins2/deagle/handling/deagle_boltrelease.wav"	
})

sound.Add({
	name = 			"TFA_INS2.DEAGLE.Boltslap",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		")weapons/tfa_ins2/deagle/handling/deagle_boltslap.wav"	
})

sound.Add({
	name = 			"TFA_INS2.DEAGLE.Boltbackslap",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		")weapons/tfa_ins2/deagle/handling/deagle_boltbackslap.wav"	
})

sound.Add({
	name = 			"TFA_INS2.DEAGLE.Empty",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		")weapons/tfa_ins2/deagle/handling/deagle_empty.wav"	
})

sound.Add({
	name = 			"TFA_INS2.DEAGLE.Magrelease",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		")weapons/tfa_ins2/deagle/handling/deagle_magrelease.wav"	
})

sound.Add({
	name = 			"TFA_INS2.DEAGLE.Magout",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		")weapons/tfa_ins2/deagle/handling/deagle_magout.wav"	
})

sound.Add({
	name = 			"TFA_INS2.DEAGLE.Magin",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		")weapons/tfa_ins2/deagle/handling/deagle_magin.wav"	
})


sound.Add({
	name = 			"TFA_INS2.DEAGLE.MagHit",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound = 		")weapons/tfa_ins2/deagle/handling/deagle_maghit.wav"	
})

SWEP.Author                    = "Forrest Mark X"

SWEP.Slot                      = 1
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/tfa_ins2/c_zm_deagle.mdl"
SWEP.WorldModel                = Model("models/weapons/w_pist_deagle.mdl")
SWEP.UseHands                  = true

SWEP.Primary.Sound             = Sound("TFA_INS2.DEAGLE.1")
SWEP.EmptySound                = Sound("TFA_INS2.DEAGLE.Empty")

SWEP.HoldType                  = "revolver"

SWEP.Primary.ClipSize           = 7
SWEP.Primary.DefaultClip        = 7
SWEP.Primary.Damage             = 42
SWEP.Primary.NumShots           = 1
SWEP.Primary.Delay              = 0.2
SWEP.Primary.Automatic          = true
SWEP.Primary.Ammo               = "revolver"
SWEP.Primary.ViewPunchMin       = Angle(-3, -2, 0)
SWEP.Primary.ViewPunchMax       = Angle(-5, 2, 0)
SWEP.Primary.Cone               = VECTOR_CONE_1DEGREES