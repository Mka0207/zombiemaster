AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName             = "Revolver"

    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 65

    SWEP.WeaponSelectIconLetter = "e"

    SWEP.Soundscripts = {
        [ACT_VM_RELOAD] = {
            {time = 0, snd = "weapons/foley/medium1.ogg"},
            {time = 0.6, snd = "weapons/zm/revolver/open.ogg"},
            {time = 1.2, snd = "weapons/zm/revolver/extractor.ogg"},
            {time = 1.3, snd = "weapons/zm/revolver/rounds_dump01.ogg"},
            {time = 1.5, snd = "weapons/zm/revolver/extractor.ogg"},
            {time = 1.8, snd = "weapons/zm/revolver/round_dump02.ogg"},
            {time = 2, snd = "weapons/foley/light3.ogg"},
            {time = 2.65, snd = "weapons/zm/revolver/speed_insert.ogg"},
            {time = 3.3, snd = "weapons/zm/revolver/close.ogg"},
            {time = 3.8, snd = "weapons/357/357_spin1.wav", pitch = 105},
        },

        [ACT_VM_DRAW] = {
            {time = 0, snd = "weapons/foley/medium2.ogg"},
        },

        [ACT_VM_FIDGET] = {
            {time = 0, snd = "weapons/foley/light1.ogg"},
            {time = 0.5, snd = "weapons/zm/revolver/twirl1.ogg"},
            {time = 1, snd = "weapons/foley/light3.ogg"},
            {time = 1.5, snd = "weapons/zm/revolver/twirl2.ogg"},
        },

        [ACT_VM_PRIMARYATTACK] = {
            {time = 0, snd = "weapons/zm/revolver/hammer.ogg"},
            {time = 0.25, snd = "weapons/zm/revolver/hammer_ready.ogg"},
        }

    }
end

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 1
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/newzm/c_revolver_zm.mdl"
SWEP.WorldModel                = Model( "models/weapons/w_357.mdl" )
SWEP.UseHands                  = true

SWEP.ReloadSound               = ""
--SWEP.Primary.Sound           = "weapons/zm/revolver/fire.ogg"
SWEP.Primary.Sound             = Sound("<weapons/revolver_zm/revolver_fire.wav")
SWEP.EmptySound                = "weapons/zm/revolver/empty.ogg"

SWEP.HoldType                  = "revolver"

SWEP.Primary.ClipSize           = 6
SWEP.Primary.DefaultClip        = 6
SWEP.Primary.Damage             = 48
SWEP.Primary.NumShots           = 1
SWEP.Primary.Delay              = 1.2
SWEP.Primary.ViewPunchMin       = Angle(-8, -1, 0)
SWEP.Primary.ViewPunchMax       = Angle(-8, 1, 0)
SWEP.Primary.Cone               = VECTOR_CONE_1DEGREES
SWEP.Primary.Ammo               = "revolver"

SWEP.Secondary.Delay            = 0.3
SWEP.Secondary.ClipSize         = 1
SWEP.Secondary.DefaultClip      = 1
SWEP.Secondary.Automatic        = false
SWEP.Secondary.Ammo             = "dummy"
SWEP.Secondary.ViewPunchMin     = Angle(-12, -6, 0)
SWEP.Secondary.ViewPunchMax     = Angle(6, 8, 0)
SWEP.Secondary.Cone             = VECTOR_CONE_2DEGREES

SWEP.MaxPenetrations            = 1

function SWEP:Think()
    BaseClass.Think(self)

    if self.firing and self.firetimer < CurTime() then
        self:PlayPrimaryFireSound()

        local damage = Either(self.Primary.Damage ~= nil, self.Primary.Damage, math.random(self.Primary.MinDamage or 0, self.Primary.MaxDamage or 0))
        self:ShootBullet(damage, self.Primary.NumShots, self.Primary.Cone)

        self:AddViewKick(false)

        if not self.InfiniteAmmo then
            self:TakePrimaryAmmo(1)
        end

        self.firing = false
        self.firetimer = 0
    end

    if self.IdleAnimation and self.IdleAnimation <= CurTime() then
        self.IdleAnimation = nil
        self:SendWeaponAnim(ACT_VM_IDLE)
    end
end

function SWEP:SecondaryAttack()
    if not self:CanPrimaryAttack() then return end

    self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)

    self:PlayPrimaryFireSound()
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)

    local damage = Either(self.Primary.Damage ~= nil, self.Primary.Damage, math.random(self.Primary.MinDamage or 0, self.Primary.MaxDamage or 0))
    self:ShootBullet(damage, self.Primary.NumShots, self.Secondary.Cone)

    self:AddViewKick(true)

    if not self.InfiniteAmmo then
        self:TakePrimaryAmmo(1)
    end

    self:SetNextIdle(CurTime() + self:GetSequenceDurationVM())
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self.firing = true
    self.firetimer = CurTime() + 0.38

    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:DoAttackEvent()

    self:SetNextIdle(CurTime() + self:GetSequenceDurationVM())
end

function SWEP:Reload()
    local owner = self:GetOwner()
    if owner:IsHolding() or self:GetNextReload() > CurTime() then return end

    if self:CanReload() then
        self:SendReloadAnimation()

        local seq = CurTime() + self:GetSequenceDurationVM()
        self:SetNextIdle(seq)
        self:SetNextReload(seq)
        self:SetReloadStart(CurTime())
        self:SetReloading(true)

        owner:DoReloadEvent()

        if self.ReloadSound then
            timer.Simple(1.5, function()
                if not IsValid(self) then return end
                self:EmitSound(self.ReloadSound)
            end)
        end

        self:ProcessReloadEndTime(seq, owner)
	elseif not self:GetReloading() then
        self:PlayInspect()
    end
end

function SWEP:SendReloadAnimation()
    self:SendWeaponAnim(self.ReloadAnim)
end