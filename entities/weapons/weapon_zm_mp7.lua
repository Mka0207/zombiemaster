AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName             = "MP7"

    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 62
    
    SWEP.WeaponSelectIconLetter = "a"
end

sound.Add({
	name = 			"TFA_INS2.MP7.1",			
	channel = 		CHAN_WEAPON,
	volume = 		1.0,
	sound =         ")weapons/tfa_ins2/mp7/fp.wav"
})

sound.Add({
	name = 			"TFA_INS2.MP7.2",			
	channel = 		CHAN_WEAPON,
	volume = 		1.0,
	sound =         ")weapons/tfa_ins2/mp7/fp_suppressed.wav"
})

sound.Add({
	name = 			"TFA_INS2.MP7.Empty",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/tfa_ins2/mp7/empty.wav"
})

sound.Add({
	name = 			"TFA_INS2.MP7.Boltback",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/tfa_ins2/mp7/boltback.wav"
})

sound.Add({
	name = 			"TFA_INS2.MP7.Boltrelease",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/tfa_ins2/mp7/boltrelease.wav"
})

sound.Add({
	name = 			"TFA_INS2.MP7.Magrelease",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/tfa_ins2/mp7/magrelease.wav"
})

sound.Add({
	name = 			"TFA_INS2.MP7.Magout",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/tfa_ins2/mp7/magout.wav"
})

sound.Add({
	name = 			"TFA_INS2.MP7.Magin",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/tfa_ins2/mp7/magin.wav"
})

sound.Add({
	name = 			"TFA_INS2.MP7.ROF",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/tfa_ins2/mp7/fireselect.wav"
})

sound.Add({
	name = 			"TFA_INS2.BipodSwivel",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         { "weapons/tfa_ins2/uni/uni_bipod_swivel_01.wav", "weapons/tfa_ins2/uni/uni_bipod_swivel_02.wav", "weapons/tfa_ins2/uni/uni_bipod_swivel_03.wav", "weapons/tfa_ins2/uni/uni_bipod_swivel_04.wav", "weapons/tfa_ins2/uni/uni_bipod_swivel_05.wav" }
})

SWEP.Author                    = "Forrest Mark X"

SWEP.Slot                      = 3
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/tfa_ins2/c_zm_mp7.mdl"
SWEP.WorldModel                = Model("models/weapons/tfa_ins2/w_mp7.mdl")
SWEP.UseHands                  = true

SWEP.WMPos                     = Vector(0.75, 3.796, -1.6)
SWEP.WMAng                     = Angle(-10.844, 0, 192)

SWEP.Primary.Sound             = Sound("TFA_INS2.MP7.1")
SWEP.EmptySound                = Sound("TFA_INS2.MP7.Empty")

SWEP.HoldType                  = "smg"

SWEP.Primary.ClipSize          = 40
SWEP.Primary.DefaultClip       = 40
SWEP.Primary.MinDamage         = 7
SWEP.Primary.MaxDamage         = 11
SWEP.Primary.NumShots          = 1
SWEP.Primary.Delay             = 0.05
SWEP.Primary.Cone              = VECTOR_CONE_5DEGREES

SWEP.Primary.Automatic         = true
SWEP.Primary.Ammo              = "smg1"

SWEP.EasyDampen                = 0.1
SWEP.VerticalKick              = 0.75
SWEP.SlideLimit                = 1.5

function SWEP:AddViewKick(bSecondaryAttack)
    self:DoMachineGunKick(self.EasyDampen, self.VerticalKick, self.m_fFireDuration, self.SlideLimit)
end