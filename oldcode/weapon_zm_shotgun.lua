AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_shotgunbase")

if CLIENT then
    SWEP.PrintName             = "Shotgun"
    SWEP.ViewModelFlip         = false
    
    SWEP.WeaponSelectIconLetter = "b"
    
    SWEP.VMPos                 = Vector(0, 0, -1.5)
    SWEP.VMAng                 = Vector(0, 0, 0)
end

sound.Add({
	name = 			"TFA_INS2_M1897.Boltback",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/tfa_ins2/m1897/m1897_pumpback.wav"	
})

sound.Add({
	name = 			"TFA_INS2_M1897.Boltrelease",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         ")weapons/tfa_ins2/m1897/m1897_pumpforward.wav"	
})

sound.Add({
	name = 			"TFA_INS2_M1897.ShellInsert",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         {")weapons/tfa_ins2/m1897/m1897_shell_insert_1.wav", ")weapons/tfa_ins2/m1897/m1897_shell_insert_2.wav", ")weapons/tfa_ins2/m1897/m1897_shell_insert_3.wav"}	
})

sound.Add({
	name = 			"TFA_INS2_M1897.ShellInsertSingle",			
	channel = 		CHAN_AUTO,
	volume = 		1.0,
	sound =         {")weapons/tfa_ins2/m1897/nova_single_shell_insert_1.wav", ")weapons/tfa_ins2/m1897/nova_single_shell_insert_2.wav", ")weapons/tfa_ins2/m1897/nova_single_shell_insert_3.wav"}	
})

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 3
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/tfa_ins2/c_zm_m1897.mdl"
SWEP.WorldModel                = Model("models/weapons/tfa_ins2/w_zm_m1897.mdl")
SWEP.UseHands                  = true

SWEP.WMPos                     = Vector(0.164, 4.796, -3.6)
SWEP.WMAng                     = Angle(-10.844, 0, 180)

SWEP.HoldType                  = "shotgun"

SWEP.Primary.Sound             = Sound(")weapons/tfa_ins2/m1897/m1897_fp_c2.wav")
SWEP.Primary.ClipSize          = 8
SWEP.Primary.DefaultClip       = 8
SWEP.Primary.Damage            = 16
SWEP.Primary.NumShots          = 7
SWEP.Primary.Delay             = 1.1
SWEP.Primary.ViewPunchMin      = Angle(-9, -3.5, 0)
SWEP.Primary.ViewPunchMax      = Angle(-5, 3.5, 0)

SWEP.ReloadDelay               = 0.3

SWEP.ReloadSound               = ""
SWEP.PumpSound                 = ""

SWEP.UseCustomMuzzleFlash      = true
SWEP.MuzzleAttachment          = "muzzle"

SWEP.ReloadTimeMultiplier      = 0.675
SWEP.EndReloadPump             = ACT_SHOTGUN_RELOAD_FINISH
SWEP.bUseSequenceDurationForReload = true
SWEP.BeginReloadEmpty          = ACT_VM_RELOAD_EMPTY
SWEP.BeginReloadEmptyLoadsFirstShell = true
SWEP.DelayFirstLoadEmpty       = 1.802

function SWEP:GetBulletSpread(cone)
    return VECTOR_CONE_10DEGREES
end