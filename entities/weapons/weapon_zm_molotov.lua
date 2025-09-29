AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName             = "Molotovs"

    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 55
    
    SWEP.WeaponSelectIconLetter = "k"
    
    SWEP.ViewModelBoneMods = {
        ["ValveBiped.Bip01_R_Finger01"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 0, 180) },
        ["ValveBiped.Bip01_R_Finger02"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 0, 180) },
        ["ValveBiped.Bip01_R_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 0, 180) },
        ["ValveBiped.Bip01_L_Finger01"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 0, 180) },
        ["ValveBiped.Bip01_L_Finger02"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 0, 180) },
        ["ValveBiped.Bip01_L_Finger0"] = { scale = Vector(1, 1, 1), pos = Vector(0, 0, 0), angle = Angle(0, 0, 180) }
    }
end

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 4
SWEP.SlotPos                   = 0

SWEP.ViewModel				   = "models/wick/weapons/l4d1/c_molotov.mdl"
SWEP.WorldModel                = Model( "models/weapons/molotov3rd_zm.mdl" )
SWEP.UseHands                  = true
SWEP.WeaponIsAmmo              = true

SWEP.HoldType                  = "grenade"
SWEP.DontDrawSpare             = true

SWEP.Primary.Recoil            = 0
SWEP.Primary.Delay             = 0
SWEP.Primary.Damage            = 40
SWEP.Primary.Radius            = 128
SWEP.Primary.ClipSize          = -1
SWEP.Primary.DefaultClip       = -1
SWEP.Primary.Reload            = 0
SWEP.Primary.Automatic         = false
SWEP.Primary.Ammo              = "molotov"
SWEP.Primary.Projectile        = "projectile_molotov"

SWEP.Secondary.Delay           = 0.3
SWEP.Secondary.ClipSize        = -1
SWEP.Secondary.DefaultClip     = -1
SWEP.Secondary.Automatic       = false
SWEP.Secondary.Ammo            = "dummy"

SWEP.Undroppable               = true
SWEP.CantThrowAmmo             = true
SWEP.bCanBeSetAsLast           = false

AccessorFuncDT(SWEP, "NextIdle", "Float", 0)
AccessorFuncDT(SWEP, "FireTimer", "Float", 1)
AccessorFuncDT(SWEP, "Firing", "Bool", 0)

function SWEP:Initialize()
    BaseClass.Initialize(self)
    
    self.m_bLighterFlame = false
    self.m_bClothFlame = false
    
    self:SetNextIdle(0)
    self:SetFireTimer(0)
    self:SetFiring(false)
end

function SWEP:CreateFireAttachment()
    if SERVER then return end

    local owner = self:GetOwner()
    if not owner:IsValid() then return end
    
    local vm = owner:GetViewModel()
    if not vm:IsValid() then return end
    
    if IsValid(self.m_FireAttachment) then
        self.m_FireAttachment:StopEmissionAndDestroyImmediately()
    end
    
    self.m_FireAttachment = CreateParticleSystem(vm, "weapon_molotov_fp", PATTACH_POINT_FOLLOW, 1)
    self.m_FireAttachment:StartEmission()
end

function SWEP:DestroyFireAttachment()
    if SERVER then return end
    if IsValid(self.m_FireAttachment) then self.m_FireAttachment:StopEmissionAndDestroyImmediately() end
end

function SWEP:Deploy()
    timer.Simple(0, function()
        if not IsValid(self) or SERVER then return end
        self:CreateFireAttachment()
    end)

    self:SetNextIdle(CurTime() + self:SequenceDuration())
    if self.DrawSound then
        self:EmitSound(self.DrawSound)
    end
    
    self:SendWeaponAnim(ACT_VM_DRAW)
    
    return true
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    
    self:SendWeaponAnim(ACT_VM_PULLPIN)
    self:SetNextPrimaryFire(CurTime() + self:SequenceDuration())
    self:SetFiring(true)
    self:SetFireTimer(CurTime() + self:SequenceDuration())
end

function SWEP:CanPrimaryAttack()
	local owner = self:GetOwner()
	if not owner:IsValid() or owner:IsHolding() then return false end
    
    if owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
        return false
    end

    return self:GetNextPrimaryFire() <= CurTime()
end

function SWEP:Reload()
    return false
end

function SWEP:Think()
    local owner = self:GetOwner()
    if not owner:IsValid() then return end
        
    if self:GetFiring() and self:GetFireTimer() < CurTime() then
        if SERVER then
            if owner:GetAmmoCount(self.Primary.Ammo) > 0 then
                self:ThrowMolotov()
            end
        end
        self:SendWeaponAnim(ACT_VM_THROW)
        self:SetNextIdle(CurTime() + self:SequenceDuration())
        
        self:SetFireTimer(0)
        self:SetFiring(false)
        
        if not self.InfiniteAmmo then
            self:TakePrimaryAmmo(1)
        end
        owner:DoAttackEvent()
        
        if owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
            local time = self:SequenceDuration() * 0.5
            if SERVER then
                SafeRemoveEntityDelayed(self, time)
            else
                timer.Simple(time, function()
                    if not IsValid(self) or not owner:IsValid() or not IsValid(owner.m_LastWeapon) then return end
                    input.SelectWeapon(owner.m_LastWeapon)
                end)
            end
        end
    end
    
    if self:GetNextIdle() ~= 0 and self:GetNextIdle() < CurTime() then
        self:SendWeaponAnim(ACT_VM_IDLE)
        self:SetNextIdle(0)
    end
    
    if CLIENT and IsValid(self.m_FireAttachment) then
        if self.m_FireAttachment:IsFinished() then
            self.m_FireAttachment:Restart()
        end
        
        if owner:ShouldDrawLocalPlayer() then
            self.m_FireAttachment:SetShouldDraw(false)
        else
            self.m_FireAttachment:SetShouldDraw(true)
        end
    end
end

function SWEP:CheckThrowPosition( pPlayer, vecEye, vecSrc )
	local tr = {}
	tr.start = vecEye
	tr.endpos = vecSrc
	tr.mins = -Vector(6,6,6)
	tr.maxs = Vector(6,6,6)
	tr.mask = MASK_PLAYERSOLID
	tr.filter = pPlayer
	tr.collision = pPlayer:GetCollisionGroup()
    
	local trace = util.TraceHull(tr)
	if trace.Hit then
		vecSrc = tr.endpos
	end

	return vecSrc
end

function SWEP:ThrowMolotov()
    local pPlayer = self:GetOwner()
    if not pPlayer:IsValid() then return end
    
	local vecEye = pPlayer:EyePos()
	local vecShoot = pPlayer:GetShootPos()
    local vecEyeAngles = pPlayer:EyeAngles()
	local vForward, vRight = vecEyeAngles:Forward(), vecEyeAngles:Right()
	local vecSrc = self:CheckThrowPosition(pPlayer, vecEye, vecEye + vForward * 18.0 + vRight * 8.0)
	local vecThrow = pPlayer:GetVelocity() + vForward * 1200
    
	local pGrenade = ents.Create(self.Primary.Projectile)
    if pGrenade and pGrenade:IsValid() then
        pGrenade:SetPos(vecSrc)
        pGrenade:SetAngles(Angle(0,0,0))
        pGrenade:SetOwner(pPlayer)
        pGrenade:Spawn()

        if pPlayer and not pPlayer:Alive() then
            vecThrow = pPlayer:GetVelocity()
            local pPhysicsObject = pGrenade:GetPhysicsObject()
            if pPhysicsObject then
                vecThrow = pPhysicsObject:SetVelocity()
            end
        end
        
        local phys = pGrenade:GetPhysicsObject()
        if phys:IsValid() then
            phys:SetVelocity(vecThrow)
            phys:AddAngleVelocity(Vector(600,math.random(-1200,1200),0))
        end

        pGrenade.m_flDamage = self.Primary.Damage
        pGrenade.m_DmgRadius = self.Primary.Radius
    end
end

function SWEP:Equip(NewOwner)
    BaseClass.Equip(self, NewOwner)
    self:CreateFireAttachment()
    NewOwner:GiveAmmo(1, self.Primary.Ammo, true)
end

function SWEP:OnDrop()
    BaseClass.OnDrop(self)
    self:DestroyFireAttachment()
end

function SWEP:OnRemove()
    BaseClass.OnRemove(self)
    self:DestroyFireAttachment()
end

function SWEP:FireAnimationEvent(pos, ang, event, name)
    if event == 48 then
        self:CallOnClient("SpawnLighterFlame", "true")
    elseif event == 3900 then
        self:CallOnClient("SpawnClothFlame", "true")
    end
end

game.AddParticles("particles/wick_l4d_particles_groundfire.pcf")
PrecacheParticleSystem("molotov_explosion")
PrecacheParticleSystem("molotov_explosion_child_burst")
PrecacheParticleSystem("molotov_explosion_child_streams")
PrecacheParticleSystem("molotov_groundfire")
PrecacheParticleSystem("molotov_groundfire_child_base")
PrecacheParticleSystem("molotov_groundfire_child_tips")
PrecacheParticleSystem("molotov_groundfire_low")
PrecacheParticleSystem("molotov_groundfire_primary")

game.AddParticles("particles/wick_l4d_particles_molotov.pcf")
PrecacheParticleSystem("weapon_molotov_fp")
PrecacheParticleSystem("weapon_molotov_fp_fire")
PrecacheParticleSystem("weapon_molotov_fp_fire2")
PrecacheParticleSystem("weapon_molotov_fp_fire3")
PrecacheParticleSystem("weapon_molotov_fp_fire3b")
PrecacheParticleSystem("weapon_molotov_fp_fire3c")
PrecacheParticleSystem("weapon_molotov_fp_fire3d")
PrecacheParticleSystem("weapon_molotov_fp_fire_blue")
PrecacheParticleSystem("weapon_molotov_fp_glow")
PrecacheParticleSystem("weapon_molotov_fp_smoke")
PrecacheParticleSystem("weapon_molotov_fp_wick")
PrecacheParticleSystem("weapon_molotov_held")
PrecacheParticleSystem("weapon_molotov_thrown")
PrecacheParticleSystem("weapon_molotov_thrown_child1")
PrecacheParticleSystem("weapon_molotov_thrown_child3")

sound.Add( {
	name = "TFA_L4D1_MOLOTOV.LOOP",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 75,
	pitch = PITCH_NORM,
	sound = "wick/weapons/l4d1/molotov/fire_idle_loop_1.wav"
} )

sound.Add( {
	name = "TFA_L4D1_MOLOTOV.IGNITE",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 75,
	pitch = PITCH_NORM,
	sound = "wick/weapons/l4d1/molotov/fire_ignite_5.wav"
} )

sound.Add( {
	name = "TFA_L4D1_MOLOTOV.DETONATE",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 75,
	pitch = PITCH_NORM,
	sound = {"wick/weapons/l4d1/molotov/molotov_detonate_1.wav", "wick/weapons/l4d1/molotov/molotov_detonate_2.wav", "wick/weapons/l4d1/molotov/molotov_detonate_3.wav", "wick/weapons/l4d1/molotov/molotov_detonate_4.wav"}
} )

sound.Add( {
	name = "TFA_L4D1_MOLOTOV.FLY",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 75,
	pitch = PITCH_NORM,
	sound = "wick/weapons/l4d1/molotov/fire_loop_1.wav"
} )
sound.Add( {
	name = "TFA_L4D1_MOLOTOV.IGNITE",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 75,
	pitch = PITCH_NORM,
	sound = {"wick/weapons/l4d1/molotov/fire_ignite_1.wav", "wick/weapons/l4d1/molotov/fire_ignite_2.wav", "wick/weapons/l4d1/molotov/fire_ignite_2.wav", "wick/weapons/l4d1/molotov/fire_ignite_4.wav", "wick/weapons/l4d1/molotov/fire_ignite_5.wav"}
} )

sound.Add( {
	name = "TFA_L4D1_SNIPER.DRAW",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 60,
	pitch = PITCH_NORM,
	sound = "wick/weapons/l4d1/hunter/gunother/hunting_rifle_deploy_1.wav"
} )

if SERVER then return end

function SWEP:SpawnLighterFlame(b)
    b = tobool(b)
    
    if b then self:SetJiggerVars() end
    self.m_bLighterFlame = b
end

function SWEP:SpawnClothFlame(b)
    b = tobool(b)
    
    if b then self:SetJiggerVars() end
    self.m_bClothFlame = b
end

function SWEP:SetJiggerVars()
    self.m_fNextJiggerTime = CurTime()
    self.m_iLastJiggerX = 2
    self.m_iLastJiggerY = 4
end

local flamemat = Material("sprites/fire_vm_grey")
function SWEP:ViewModelDrawn(ViewModel)
    if self.m_bLighterFlame then
        local id = ViewModel:LookupBone("ValveBiped.LighterFlame")
        if id ~= 0 then
            local m = ViewModel:GetBoneMatrix(id)
            local pos, ang = m:GetTranslation(), m:GetAngles()
            
            render.SetMaterial(flamemat)
            self:DrawJiggeringSprite(pos + (ang:Forward() * 2))        
        end
    end
    
    if self.m_bClothFlame then
        local id = ViewModel:LookupBone("cloth5")
        if id ~= 0 then
            local m = ViewModel:GetBoneMatrix(id)
            local pos, ang = m:GetTranslation(), m:GetAngles()
            
            render.SetMaterial(flamemat)
            self:DrawJiggeringSprite(pos)            
        end
    end
end

function SWEP:DrawJiggeringSprite(vecAttach)
    local green = 165 - math.random(0, 64)
    local flamecolor = Color(255, green, 0)

    if CurTime() >= self.m_fNextJiggerTime then
        self.m_iLastJiggerX = math.Rand(1.0, 2.0)
        self.m_iLastJiggerY = math.Rand(3.8, 4.2)
        self.m_fNextJiggerTime = CurTime() + math.Rand(0.2, 1.0)
    end

    render.DrawSprite(vecAttach, self.m_iLastJiggerX, self.m_iLastJiggerY, flamecolor)
end

function SWEP:DrawHUD()
    if cvars.Number("zm_maxammo_molotov") > 1 then
        BaseClass.DrawHUD(self)
    end
end