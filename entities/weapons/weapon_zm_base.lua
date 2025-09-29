local IS_CLIENT_RUNNING = false
local IS_SERVER_RUNNING = false
if SERVER then
	IS_SERVER_RUNNING = true
end

if CLIENT then
	IS_CLIENT_RUNNING = true
end

local meta = FindMetaTable("Entity")
local E_GetTable = meta.GetTable
local E_IsValid = meta.IsValid

SWEP.Category                     = "Zombie Master SWEPs"

SWEP.AutoSwitchTo                 = false
SWEP.AutoSwitchFrom               = false
SWEP.WeaponSelectIconLetter       = "c"
SWEP.DrawAmmo                     = false
SWEP.DrawWeaponInfoBox            = false
SWEP.BounceWeaponIcon             = false
SWEP.SwayScale                    = 1.0
SWEP.BobScale                     = 1.0
SWEP.ViewModelFOV                 = 75
SWEP.ViewModelFlip                = false
SWEP.CSMuzzleFlashes              = false
SWEP.UseHands                     = true
SWEP.DrawCrosshair                = false
SWEP.DrawQuickInfo                = true
SWEP.ViewModelMovementScale       = 0.5

SWEP.Author                       = "???"
SWEP.Contact                      = ""
SWEP.Purpose                      = ""
SWEP.Instructions                 = ""

SWEP.Spawnable                    = false
SWEP.AdminSpawnable               = false

SWEP.UseCustomMuzzleFlash         = false
SWEP.MuzzleEffect                 = "CS_MuzzleFlash"
SWEP.MuzzleAttachment             = "1"

SWEP.ShakeWeaponSelectIcon        = false

SWEP.TracerType                   = "Tracer"

SWEP.InfiniteAmmo                 = false
SWEP.DeploySpeed                  = 1

SWEP.Primary.Sound                = ""
SWEP.Primary.NumShots             = 1
SWEP.Primary.Recoil               = 0

SWEP.IsMelee                      = false

SWEP.Primary.ClipSize             = -1
SWEP.Primary.DefaultClip          = -1
SWEP.Primary.Ammo                 = "none"
SWEP.Primary.RandomPitch          = false
SWEP.Primary.MinPitch             = 100
SWEP.Primary.MaxPitch             = 100
SWEP.Primary.DamageType           = DMG_BULLET
SWEP.Primary.ViewPunchMin         = Angle()
SWEP.Primary.ViewPunchMax         = Angle()

SWEP.Secondary.ClipSize           = -1
SWEP.Secondary.DefaultClip        = -1
SWEP.Secondary.Automatic          = false
SWEP.Secondary.Ammo               = "none"
SWEP.Secondary.ViewPunchMin       = Angle()
SWEP.Secondary.ViewPunchMax       = Angle()

SWEP.PenetrationDamageMultiplier  = 1
SWEP.MaxPenetrations              = 0

SWEP.EasyDampen                   = 0
SWEP.VerticalKick                 = 0
SWEP.SlideLimit                   = 0

SWEP.bCanBeSetAsLast              = true

SWEP.ReloadAnim                   = ACT_VM_RELOAD
SWEP.ReloadSpeed                  = 1

AccessorFuncDT(SWEP, "NextIdle", "Float", 0)
AccessorFuncDT(SWEP, "NextReload", "Float", 1)
AccessorFuncDT(SWEP, "ReloadStart", "Float", 2)
AccessorFuncDT(SWEP, "ReloadFinish", "Float", 3)
AccessorFuncDT(SWEP, "InspectTime", "Float", 4)
AccessorFuncDT(SWEP, "ReloadStartTime", "Float", 5)
AccessorFuncDT(SWEP, "Reloading", "Bool", 0)

function SWEP:PlayInspect()
	local stbl = E_GetTable(self)
	local ct = CurTime()

    local owner = self:GetOwner()
	if not IsValid(owner) or self:GetInspectTime() > ct then return end

	local vm = owner:GetViewModel()
	local fidget = vm:SelectWeightedSequence(ACT_VM_FIDGET)
	if fidget ~= -1 then
		stbl.IdleAnimation = nil
		self:SendWeaponAnim(ACT_VM_FIDGET)
		self:SetInspectTime(ct + self:GetSequenceDurationVM())
		stbl.IdleAnimation = self:GetInspectTime() + 0.5
		return
	end

	if not stbl.FidgetAnims then return end

	local seqname = table.Random(stbl.FidgetAnims)
	local seq = vm:LookupSequence(seqname)
	if seq then
		stbl.IdleAnimation = nil
		self:SendWeaponAnim(self:SelectWeightedSequence(ACT_VM_IDLE_EMPTY) ~= -1 and self:Clip1() == 0 and ACT_VM_IDLE_EMPTY or ACT_VM_IDLE)
		vm:SendViewModelMatchingSequence(seq)
		self:SetInspectTime(ct + vm:SequenceDuration(seq))
		stbl.IdleAnimation = self:GetInspectTime() + 0.5
	end

	if stbl.InspectAnimThirdperson then
		self:PlayThirdpersonTaunt(stbl.InspectAnimThirdperson)
	end
end

function SWEP:CanPrimaryAttack()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsHolding() or self:GetReloadFinish() > 0 then return false end

    if self:Clip1() <= 0 then
        if self:SelectWeightedSequence(ACT_VM_DRYFIRE) ~= -1 then
            self:SendWeaponAnim(ACT_VM_DRYFIRE)
        end
        if IS_CLIENT_RUNNING and IsFirstTimePredicted() then self:EmitSound(self.EmptySound or "Weapon_Pistol.Empty") end
        self:SetNextPrimaryFire(CurTime() + 1)
        self:Reload()
        return false
    end

    return self:GetNextPrimaryFire() <= CurTime()
end

SWEP.NeedsToPlayDrawSound = false
function SWEP:Deploy()
	local stbl = E_GetTable(self)
    self:SetNextIdle(CurTime() + self:SequenceDuration())
    if stbl.DrawSound then
        self:EmitSound(stbl.DrawSound)
    end

    local selanim = (self:Clip1() == 0 and self:SelectWeightedSequence(ACT_VM_DRAW_EMPTY) ~= -1) and ACT_VM_DRAW_EMPTY or ACT_VM_DRAW
    self:SendWeaponAnim(selanim)

    if IS_CLIENT_RUNNING then
        self:PlaySoundScript(selanim, 1)
    end

    return true
end

function SWEP:Holster()
    local owner = self:GetOwner()
    self:SendWeaponAnim((self:Clip1() == 0 and self:SelectWeightedSequence(ACT_VM_HOLSTER_EMPTY) ~= -1) and ACT_VM_HOLSTER_EMPTY or ACT_VM_HOLSTER)

    if owner and IsValid(owner) and owner.IsHolding and owner:IsHolding() then
        return false
    end

    if IS_CLIENT_RUNNING then
        self:SCKHolster()
    end

    if self.bCanBeSetAsLast then
        owner.m_LastWeapon = self
    end

    return true
end

function SWEP:Initialize()
	local stbl = E_GetTable(self)
    if IS_SERVER_RUNNING then
        self:SetNPCMinBurst(30)
        self:SetNPCMaxBurst(30)
        self:SetNPCFireRate(0.01)

        self:SetTrigger(false)
        self:UseTriggerBounds(false, 0)
    else
        self:SCKInit()
    end

    if cvars.Bool("zm_infiniteammo") then
        stbl.InfiniteAmmo = true
    end

    self:SetWeaponHoldType(stbl.HoldType)

    self:SetNextIdle(0)
    self:SetDeploySpeed(stbl.DeploySpeed)

    self:SpawnWeaponExtender()

    stbl.m_CurrentPenetrations = 0
end

function SWEP:SpawnWeaponExtender()
    if IS_CLIENT_RUNNING then return end
	local stbl = E_GetTable(self)
    if stbl.WeaponExtender and IsValid(stbl.WeaponExtender) then
        stbl.WeaponExtender:Remove()
    end

    local extender = ents.Create("info_weapon_extender")
    extender:SetOwner(self)
    extender:SetParent(self)
    extender:SetPos(self:GetPos())
    extender:SetAngles(self:GetAngles())
    extender.m_Clip1 = self:Clip1()
    extender.m_Clip2 = self:Clip2()
    extender:Spawn()

    stbl.WeaponExtender = extender
end

function SWEP:RemoveWeaponExtender()
    if IS_CLIENT_RUNNING then return end
	local stbl = E_GetTable(self)
    if stbl.WeaponExtender and IsValid(stbl.WeaponExtender) then
        stbl.WeaponExtender:Remove()
    end
end

function SWEP:PlayPrimaryFireSound()
	local stbl = E_GetTable(self)
    self:EmitSound(stbl.Primary.Sound, 75, Either(stbl.Primary.RandomPitch, math.random(stbl.Primary.MinPitch, stbl.Primary.MaxPitch), 100))
end

function SWEP:PlayReloadSound()
	local stbl = E_GetTable(self)
    if stbl.ReloadSound and stbl.ReloadSound ~= "" then
        self:EmitSound(stbl.ReloadSound)
    end
end

function SWEP:SendReloadAnimation()
    local reload_anim = self.ReloadAnim
    if self:SelectWeightedSequence(ACT_VM_RELOAD_EMPTY) ~= -1 and self:Clip1() == 0 then
        reload_anim = ACT_VM_RELOAD_EMPTY
    end

    self:SendWeaponAnim(reload_anim)
end

function SWEP:EmitReloadFinishSound()
	local stbl = E_GetTable(self)
    if stbl.ReloadFinishSound and IsFirstTimePredicted() then
        self:EmitSound(stbl.ReloadFinishSound, 75, 100, 0.7, CHAN_ITEM)
    end
end

function SWEP:FinishReload()
    self:SendWeaponAnim(ACT_VM_IDLE)
    self:SetNextReload(0)
    self:SetReloadStart(0)
    self:SetReloadFinish(0)
    self:EmitReloadFinishSound()
    self:SetReloading(false)

    local owner = self:GetOwner()
    if not E_IsValid(owner) then return end

    local max1 = self:GetPrimaryClipSize()
    local max2 = self:GetMaxClip2()

    if max1 > 0 then
        local ammotype = self:GetPrimaryAmmoType()
        local spare = owner:GetAmmoCount(ammotype)
        local current = self:Clip1()
        local needed = max1 - current

        needed = math.min(spare / (self.ReloadConsumption or 1), needed)

        self:SetClip1(current + needed)
        if IS_SERVER_RUNNING then
            owner:RemoveAmmo(needed, ammotype)
        end
    end

    if max2 > 0 then
        local ammotype = self:GetSecondaryAmmoType()
        local spare = owner:GetAmmoCount(ammotype)
        local current = self:Clip2()
        local needed = max2 - current

        needed = math.min(spare, needed)

        self:SetClip2(current + needed)
        if IS_SERVER_RUNNING then
            owner:RemoveAmmo(needed, ammotype)
        end
    end
end

function SWEP:CanReload()
	local clip1 = self:Clip1()
	local owner = self:GetOwner()
	local max_clip2 = self:GetMaxClip2()
    return self:GetNextReload() <= CurTime() and self:GetReloadFinish() == 0 and
        (
            self:GetMaxClip1() > 0 and clip1 < self:GetPrimaryClipSize() and self:ValidPrimaryAmmo() and owner:GetAmmoCount(self:GetPrimaryAmmoType()) > 0
            or max_clip2 > 0 and clip1 < max_clip2 and self:ValidSecondaryAmmo() and owner:GetAmmoCount(self:GetSecondaryAmmoType()) > 0
        )
end

SWEP.RequiredClip = 1
function SWEP:GetPrimaryClipSize()
	local stbl = E_GetTable(self)
    local owner = self:GetOwner()
    local mag_mul      = owner.MagSizeEightMul or 1
    local mag_mul_four  = owner.MagSizeFourEightMul or 1

    local ratio = stbl.Primary.ClipSize / stbl.RequiredClip
    local multi = ratio >= 8 and mag_mul or
                  ratio >= 4 and ratio <= 7 and mag_mul_four
                  or 1

    return math.floor(stbl.Primary.ClipSize * multi)
end

SWEP.SubtractReloadSpeed = 1
function SWEP:ProcessReloadEndTime(seq, owner)
    local reloadspeed = (self.ReloadSpeed or 1)

    self:SetReloadFinish(seq / (reloadspeed * self.SubtractReloadSpeed))
    self:SetReloadStartTime(CurTime())
    if not self.DontScaleReloadSpeed then
        owner:GetViewModel():SetPlaybackRate(reloadspeed)
    end
end

function SWEP:Reload()
    local owner = self:GetOwner()
    if owner:IsHolding() then return end

    if self:CanReload() then
        self:SendReloadAnimation()
        self:PlayReloadSound()

        local seq = CurTime() + self:GetSequenceDurationVM() --self:SequenceDuration()
        self:SetNextIdle(seq)
        self:SetNextReload(seq)
        self:SetReloadStart(CurTime())
        self:SetReloading(true)

        owner:DoReloadEvent()

        if self.ReloadSound then
            self:EmitSound(self.ReloadSound)
        end

        self:ProcessReloadEndTime(seq, owner)
	elseif not self:GetReloading() then
        self:PlayInspect()
    end
end

function SWEP:DoMachineGunKick(DampEasy, MaxVerticleKickAngle, FireDurationTime, SlideLimitTime)
    if IS_CLIENT_RUNNING and not IsFirstTimePredicted() then return end

    local pPlayer = self:GetOwner()
    if not IsValid(pPlayer) then return end

    local KICK_MIN_X = 0.2
    local KICK_MIN_Y = 0.2
    local KICK_MIN_Z = 0.1

    local duration = ( FireDurationTime > SlideLimitTime ) and SlideLimitTime or FireDurationTime
    local kickPerc = duration / SlideLimitTime

    pPlayer:ViewPunchReset(10)

    local vecScratch = Angle()
    vecScratch.x = -( KICK_MIN_X + ( MaxVerticleKickAngle * kickPerc ) )
    vecScratch.y = -( KICK_MIN_Y + ( MaxVerticleKickAngle * kickPerc ) ) / 3
    vecScratch.z = KICK_MIN_Z + ( MaxVerticleKickAngle * kickPerc ) / 8

    if util.SharedRandom("mac10_1", -1, 1) >= 0 then
	    vecScratch.y = vecScratch.y * -1
    end

    if util.SharedRandom("mac10_2", -1, 1) >= 0 then
	    vecScratch.z = vecScratch.z * -1
    end

    util.ClipPunchAngleOffset(vecScratch, pPlayer:GetViewPunchAngles(), Angle(24, 3, 1))

    pPlayer:ViewPunch(vecScratch * 0.5)
end

function SWEP:AddViewKick(bSecondaryAttack)
    local pPlayer = self:GetOwner()
    if not IsValid(pPlayer) then return end
	local stbl = E_GetTable(self)
	local primary = stbl.Primary

    local min, max
    if not bSecondaryAttack then
        min = primary.ViewPunchMin
        max = primary.ViewPunchMax
    else
        min = primary.ViewPunchMin
        max = primary.ViewPunchMax
    end

	local punch = Angle(util.SharedRandom("gunx", min.x, max.x), util.SharedRandom("guny", min.y, max.y), util.SharedRandom("gunz", min.z, max.z))
    pPlayer:ViewPunch(punch)
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
	local stbl = E_GetTable(self)
	local primary = stbl.Primary
	local ct = CurTime()

    self:SetNextSecondaryFire(ct + primary.Delay)
    self:SetNextPrimaryFire(ct + primary.Delay)

    self:PlayPrimaryFireSound()
    if self:Clip1() == 1 and self:SelectWeightedSequence(ACT_VM_PRIMARYATTACK_EMPTY) ~= -1 then
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK_EMPTY)
    else
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    end

    local damage = Either(primary.Damage ~= nil, primary.Damage, math.random(primary.MinDamage or 0, primary.MaxDamage or 0))
    self:ShootBullet(damage, primary.NumShots, primary.Cone)
    self:AddViewKick(false)

    if not stbl.InfiniteAmmo then
        self:TakePrimaryAmmo(1)
    end
end

--[[function SWEP:DefaultCallBack(attacker, tr, dmginfo)
    dmginfo:SetDamageType(self.Primary.DamageType)

    local ent = tr.Entity
    if IsValid(ent) and not ent:IsPlayer() then
        ent.LastDamageAmount = dmginfo:GetDamage()
        ent.LastDamageForce = dmginfo:GetDamageForce()
        ent.LastHitPos = tr.HitPos
        ent.LastDamageType = dmginfo:GetDamageType()

        local bone = ent:NearestBone(tr.HitPos)
        if bone then
            ent.LastHitPhysBone = ent:TranslateBoneToPhysBone(bone)
        end
    end
end--]]

function SWEP:DefaultCallBack(attacker, tr, dmginfo)
    dmginfo:SetDamageType(self.Primary.DamageType)

    local ent = tr.Entity
    if IsValid(ent) and not ent:IsPlayer() then
        local phys = ent:GetPhysicsObject()
        if ent:GetMoveType() == MOVETYPE_VPHYSICS and IsValid(phys) and phys:IsMoveable() then
            ent:SetPhysicsAttacker(attacker)
        end

        ent.LastDamageAmount = dmginfo:GetDamage()
        ent.LastDamageForce = dmginfo:GetDamageForce()
        ent.LastHitPos = tr.HitPos
        ent.LastDamageType = dmginfo:GetDamageType()

        local bone = ent:NearestBone(tr.HitPos)
        if bone then
            ent.LastHitPhysBone = ent:TranslateBoneToPhysBone(bone)
        end
    end
end

function SWEP:GetBulletSpread(cone)
    return Vector(cone, cone, 0)
end

function SWEP:GetBulletCone(spread)
    local owner = self:GetOwner()
    local cone = spread:Length()
    local conmax = cone * 1.5
	if not owner:OnGround() then return conmax end

	local basecone = cone
	local conedelta = conmax - basecone

	local multiplier = math.min(owner:GetVelocity():Length() / 225, 1) * 0.5
	if not owner:Crouching() then multiplier = multiplier + 0.5 end

	return basecone + conedelta * multiplier ^ 2
end

function SWEP:SetupPenetration(attacker, tr, dmginfo)
    local owner = self:GetOwner()
    if not IsValid(owner) or tr.HitWorld or tr.HitSky then return end
	local stbl = E_GetTable(self)
    if stbl.MaxPenetrations == 0 or stbl.BulletTrace == nil then return end

    local ent = tr.Entity
    if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then
        local dmg = dmginfo:GetDamage() * stbl.PenetrationDamageMultiplier
        if dmg <= 0 or stbl.m_CurrentPenetrations >= stbl.MaxPenetrations or stbl.m_LastHitEnt == ent then
            stbl.m_CurrentPenetrations = 0
            stbl.m_LastHitEnt = NULL
            return
        end

        stbl.m_CurrentPenetrations = stbl.m_CurrentPenetrations + 1

        local bullet = stbl.BulletTrace
        bullet.Src = tr.HitPos
        bullet.Damage = dmg
        bullet.IgnoreEntity = ent
        bullet.Num = 1

        local this = self
        bullet.Callback = function(attacker, trace, dmginfo)
            if IS_CLIENT_RUNNING and this.ClientBulletInfos then
                this:ClientBulletInfos(attacker, trace, dmginfo)
            end
        end

        owner:FireBullets(bullet)

        self:SentWeaponInfos(attacker, bullet)

        stbl.m_LastHitEnt = ent
    end
end

local ClientsideFBInfos = {}
function SWEP:ClearCLFireBullet()
    ClientsideFBInfos = {}
end

function SWEP:FirebulletSendCL()
    if not IS_CLIENT_RUNNING then return end

	local infos = ""
	local count = #ClientsideFBInfos
	if count == 0 then return end

	for i = 1, count do
		local tbl = ClientsideFBInfos[i]
		if not tbl then continue end

		infos = infos .. tostring(tbl[1]) .. ":" .. tostring(tbl[2])

		if i ~= count then
			infos = infos .. "|"
		end
	end

	local compressed_info = util.Compress(infos)
	local bytes_amount = #compressed_info

	net.Start("zm_infos")
		net.WriteUInt(bytes_amount, 16)
		net.WriteData(compressed_info, bytes_amount)
	net.SendToServer()
end

function SWEP:ClientBulletInfos(attacker, tr, dmginfo)
	local ent = tr.Entity
    if ent and IsValid(ent) then
		ClientsideFBInfos[#ClientsideFBInfos + 1] = {[1] = ent:EntIndex(), [2] = ent:GetHitBoxBone(tr.HitBox, 0) or -1}
	end
end

local wep_attacker = NULL
local function SE_FB_FILTER(ent)
    if ent == wep_attacker then return false end

    return GAMEMODE:ShouldCollide(ent, wep_attacker)
end
local trace_struct_sv = {filter = SE_FB_FILTER, mask = MASK_SOLID}

function SWEP:SentWeaponInfos(owner, bullet)
    if EntityIsPlayer(owner) and AddDataToRecordTrack then
        owner.LastTimeShoot = CurTime()

        wep_attacker = owner
        trace_struct_sv.start = bullet.Src
        trace_struct_sv.endpos = trace_struct_sv.start + bullet.Dir * 10000

        local tr_data = {}
        tr_data.force_mul = self.Primary.Force or 1
        tr_data.dir = bullet.Dir
        tr_data.tr = util.TraceLine(trace_struct_sv)
        tr_data.damage = bullet.Damage
        tr_data.attacker = owner
        tr_data.inflictor = self
        tr_data.ammo_id = game.GetAmmoID(self.Primary.Ammo)

        AddDataToRecordTrack(owner, tr_data)
    end
end

SWEP.Bullet = {Tracer = SWEP.TracerFreq, TracerName = SWEP.TracerType}
function SWEP:ShootBullet(dmg, numbul, cone)
    local owner = self:GetOwner()
	local stbl = E_GetTable(self)
	local primary = stbl.Primary
    if IS_CLIENT_RUNNING then
        self:ClearCLFireBullet()
    end

    if not IsValid(owner) or not owner.DoAttackEvent then return end

    numbul = numbul or 1
    cone = cone or 0.01

    if stbl.UseCustomMuzzleFlash and IS_CLIENT_RUNNING and IsFirstTimePredicted() then
        local vm = owner:GetViewModel()
        if IsValid(vm) then
            local data = EffectData()
                data:SetFlags(0)
                data:SetEntity(vm)
                data:SetAttachment(vm:LookupAttachment(stbl.MuzzleAttachment or "1"))
                data:SetScale(stbl.MuzzleScale or 1)
            util.Effect(stbl.MuzzleEffect, data)
        end
    end

    owner:DoAttackEvent()
    owner:MuzzleFlash()

    if not IsFirstTimePredicted() then return end

    local bullet       = stbl.Bullet
    bullet.Num         = numbul
    bullet.Src         = owner:GetShootPos()
    bullet.Dir         = (owner:GetAimVector():Angle() + owner:GetViewPunchAngles()):Forward()
    bullet.Spread      = self:GetBulletSpread(cone)
    bullet.Damage      = dmg
    bullet.AmmoType    = primary.Ammo
    bullet.IgnoreEntity = NULL

	if primary.Force then
		bullet.Force = primary.Force
	end

    stbl.BulletTrace = bullet

    local this = self
    bullet.Callback = function(attacker, trace, dmginfo)
        this:DefaultCallBack(attacker, trace, dmginfo)
        this:SetupPenetration(attacker, trace, dmginfo)

        if IS_CLIENT_RUNNING and this.ClientBulletInfos then
            this:ClientBulletInfos(attacker, trace, dmginfo)
        end
    end

    BULLET_CLIENTSIDE_HITREG_EDIT = true
    owner:FireBullets(bullet)
    BULLET_CLIENTSIDE_HITREG_EDIT = false

    self:SetNextIdle(CurTime() + self:SequenceDuration())
    self:SentWeaponInfos(owner, bullet)
    self:FirebulletSendCL()
end

function SWEP:Think()
    local owner = self:GetOwner()
    if IsValid(owner) then
        local bHoldingAttack = owner:KeyDown(IN_ATTACK)
        self.m_fFireDuration = bHoldingAttack and ((self.m_fFireDuration or 0) + FrameTime()) or 0
    end

    if self:GetNextIdle() ~= 0 and self:GetNextIdle() < CurTime() then
        self:SendWeaponAnim((self:Clip1() == 0 and self:SelectWeightedSequence(ACT_VM_IDLE_EMPTY) ~= -1) and ACT_VM_IDLE_EMPTY or ACT_VM_IDLE)
        self:SetNextIdle(0)
    end

    if self:GetReloadFinish() > 0 then
        if CurTime() >= self:GetReloadFinish() then
            self:FinishReload()
        end
    end
end

function SWEP:CanSecondaryAttack()
    return false
end

function SWEP:SecondaryAttack()
end

function SWEP:Equip(NewOwner)
    self.Dropped = false
    NewOwner:EmitSound("HL2Player.PickupWeapon")
    self:RemoveWeaponExtender()
end

function SWEP:EquipAmmo(ply)
    ply:EmitSound("HL2Player.PickupWeapon")
end

function SWEP:OnDrop()
    self:SpawnWeaponExtender()
    self.Dropped = true

    local phys = self:GetPhysicsObject()
    if IsValid(phys) and not phys:IsMotionEnabled() then
        phys:EnableMotion(true)
    end
end

function SWEP:Ammo1()
    local owner = self:GetOwner()
    if not IsValid(owner) then return 0 end

	return owner:GetAmmoCount( self:GetPrimaryAmmoType() )
end

function SWEP:Ammo2()
    local owner = self:GetOwner()
    if not IsValid(owner) then return 0 end

	return owner:GetAmmoCount( self:GetSecondaryAmmoType() )
end

local ActIndex = {
    [ "pistol" ]         = ACT_HL2MP_IDLE_PISTOL,
    [ "smg" ]            = ACT_HL2MP_IDLE_SMG1,
    [ "grenade" ]        = ACT_HL2MP_IDLE_GRENADE,
    [ "ar2" ]            = ACT_HL2MP_IDLE_AR2,
    [ "shotgun" ]        = ACT_HL2MP_IDLE_SHOTGUN,
    [ "rpg" ]            = ACT_HL2MP_IDLE_RPG,
    [ "physgun" ]        = ACT_HL2MP_IDLE_PHYSGUN,
    [ "crossbow" ]       = ACT_HL2MP_IDLE_CROSSBOW,
    [ "melee" ]          = ACT_HL2MP_IDLE_MELEE,
    [ "slam" ]           = ACT_HL2MP_IDLE_SLAM,
    [ "normal" ]         = ACT_HL2MP_IDLE,
    [ "fist" ]           = ACT_HL2MP_IDLE_FIST,
    [ "melee2" ]         = ACT_HL2MP_IDLE_MELEE2,
    [ "passive" ]        = ACT_HL2MP_IDLE_PASSIVE,
    [ "knife" ]          = ACT_HL2MP_IDLE_KNIFE,
    [ "duel" ]           = ACT_HL2MP_IDLE_DUEL,
    [ "revolver" ]       = ACT_HL2MP_IDLE_REVOLVER
}
function SWEP:SetWeaponHoldType(t)
    t = string.lower(t)
    local index = ActIndex[t]

    if index == nil then
        Msg( "SWEP:SetWeaponHoldType - ActIndex[ \""..t.."\" ] isn't set! (defaulting to normal)\n" )
        t = "normal"
        index = ActIndex[t]
    end

    self.ActivityTranslate = {}
    self.ActivityTranslate[ACT_MP_STAND_IDLE]                     = index
    self.ActivityTranslate[ACT_MP_WALK]                           = index+1
    self.ActivityTranslate[ACT_MP_RUN]                            = index+2
    self.ActivityTranslate[ACT_MP_CROUCH_IDLE]                    = index+3
    self.ActivityTranslate[ACT_MP_CROUCHWALK]                     = index+4
    self.ActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE]       = index+5
    self.ActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]      = index+5
    self.ActivityTranslate[ACT_MP_RELOAD_STAND]                   = index+6
    self.ActivityTranslate[ACT_MP_RELOAD_CROUCH]                  = index+6
    self.ActivityTranslate[ACT_MP_JUMP]                           = index+7
    self.ActivityTranslate[ACT_RANGE_ATTACK1]                     = index+8
    self.ActivityTranslate[ACT_MP_SWIM_IDLE]                      = index+8
    self.ActivityTranslate[ACT_MP_SWIM]                           = index+9

    if t == "normal" then
        self.ActivityTranslate [ ACT_MP_JUMP ] = ACT_HL2MP_JUMP_SLAM
    end

    if t == "knife" or t == "melee2" then
        self.ActivityTranslate [ ACT_MP_CROUCH_IDLE ] = nil
    end
end

SWEP:SetWeaponHoldType("fist")

function SWEP:TranslateActivity(act)
    return self.ActivityTranslate and self.ActivityTranslate[act] or -1
end

if not IS_CLIENT_RUNNING then return end

local colBG     = Color(60, 0, 0, 200)
local colRed    = Color(220, 0, 0, 230)
local colYellow = Color(220, 220, 0, 230)
local colWhite  = Color(220, 220, 220, 230)
local colAmmo   = Color(255, 255, 255, 230)
local function GetAmmoColor(clip, maxclip)
    if clip == 0 then
        colAmmo.r = 255 colAmmo.g = 0 colAmmo.b = 0
    else
        local sat = clip / maxclip
        colAmmo.r = 255
        colAmmo.g = sat ^ 0.3 * 255
        colAmmo.b = sat * 255
    end
end

local ammoBG = Material("zmr_effects/hud_bg_ammo")
function SWEP:DrawHUD()
    local owner = self:GetOwner()
    if not E_IsValid(owner) then return end

    local stbl = E_GetTable(self)
    local primary = stbl.Primary
    local ct = CurTime()

    self:DrawCrosshair()

    local wid, hei = ScreenScale(60), ScreenScale(21)
    local x, y = ScrW() * 0.865, ScrH() * 0.91
    local clip = stbl.DontDrawSpare and owner:GetAmmoCount(self:GetPrimaryAmmoType()) or self:Clip1()
    local spare = owner:GetAmmoCount(self:GetPrimaryAmmoType())
    local maxclip = primary.ClipSize
    local bZMRHUD = cvars.Number("zm_hudtype", 0) == HUD_ZMR
    local font = bZMRHUD and "ZMHudNumbers" or "zm_hud_font_normal"
    local bigfont = bZMRHUD and "ZMHudNumbers" or "zm_hud_font_big"
    local smallfont = bZMRHUD and "ZMHudNumbersSmall" or "zm_hud_font_small"

    local reloadhud = GAMEMODE.ReloadHUD
    local bShouldDrawReload = self:ShouldDrawReloadTime()
    if IsValid(reloadhud) and reloadhud.bShouldDraw ~= bShouldDrawReload then
        reloadhud.bShouldDraw = bShouldDrawReload
    end

    if bZMRHUD then
        surface.SetDrawColor(70, 0, 0, 150)
        surface.SetMaterial(ammoBG)
        surface.DrawTexturedRect(x - (wid * 0.25), y - (hei * 0.25), wid * 1.5, hei * 1.5)
    else
        draw.RoundedBox(10, x + 2, y + 2, wid, hei, colBG)
    end

    if stbl.InfiniteAmmo then
        draw.SimpleTextBlurry("∞", "zm_hud_font_bigger", x + wid * 0.5, y + hei * 0.42, colAmmo, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    if stbl.CurrentSpare ~= spare then
        stbl.CurrentSpare = spare

        stbl.LastAmmoTaken = ct
        stbl.AmmoTimer = ct + 5
    end

    if stbl.CurrentClip1 ~= clip then
        stbl.CurrentClip1 = clip

        stbl.LastClipTaken = ct
        stbl.ClipTimer = ct + 5
    end

    local displayspare = maxclip > 0 and stbl.Primary.DefaultClip ~= 99999
    if displayspare or not stbl.DontDrawSpare then
        draw.SimpleTextBlurry(spare, bZMRHUD and smallfont or (spare >= 1000 and smallfont or font), x + wid * 0.75, y + hei * 0.5, spare == 0 and colRed or spare <= maxclip and colYellow or colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, stbl.LastAmmoTaken, stbl.AmmoTimer)
    end

    GetAmmoColor(clip, maxclip)
    draw.SimpleTextBlurry(clip, clip >= 100 and font or bigfont, x + wid * (displayspare and 0.25 or 0.5), y + hei * 0.5, colAmmo, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, self.LastClipTaken, self.ClipTimer)
end

function SWEP:DrawCrosshair()
	if GetConVarNumber("crosshair") ~= 1 then return end

	self:DrawCrosshairCross()
	self:DrawCrosshairDot()
end

local CrossHairScale = 1
local matGrad = Material("VGUI/gradient-r")
local function DrawLine(x, y, rot)
	rot = 270 - rot
	surface.SetMaterial(matGrad)
	surface.SetDrawColor(0, 0, 0, 220)
	surface.DrawTexturedRectRotated(x, y, 14, 4, rot)
	surface.SetDrawColor(color_white:Unpack())
	surface.DrawTexturedRectRotated(x, y, 12, 2, rot)
end
local baserot = 0
function SWEP:DrawCrosshairCross()
	local x = ScrW() * 0.5
	local y = ScrH() * 0.5

	local owner = self:GetOwner()
	local cone = self:GetBulletCone(self.Primary.Cone)

	cone = ScrH() / 76.8 * cone

	CrossHairScale = math.Approach(CrossHairScale, cone, FrameTime() * math.max(5, math.abs(CrossHairScale - cone) * 0.02))

 	local midarea = 40 * CrossHairScale
	local ang = Angle(0, 0, baserot)
	for i=0, 359, 360 / 4 do
		ang.roll = baserot + i
		local p = ang:Up() * midarea
		DrawLine(math.Round(x + p.y), math.Round(y + p.z), ang.roll)
	end
end

function SWEP:DrawCrosshairDot()
	local x = ScrW() * 0.5
	local y = ScrH() * 0.5

	surface.SetDrawColor(COLOR_RED:Unpack())
	surface.DrawRect(x - 2, y - 2, 4, 4)
	surface.SetDrawColor(0, 0, 0, 220)
	surface.DrawOutlinedRect(x - 2, y - 2, 4, 4)
end

function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
	local stbl = E_GetTable(self)
    draw.SimpleTextBlurry(stbl.WeaponSelectIconLetter, "ZMDeathFonts", x + wide / 2, y + tall * 0.2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
    if stbl.ShakeWeaponSelectIcon then
        draw.SimpleTextBlurry(stbl.WeaponSelectIconLetter, "ZMDeathFonts", x + wide / 2 + math.Rand(-4, 4), y + tall * 0.2 + math.Rand(-14, 14), Color(255, 255, 255, math.Rand(10, 120)), TEXT_ALIGN_CENTER)
        draw.SimpleTextBlurry(stbl.WeaponSelectIconLetter, "ZMDeathFonts", x + wide / 2 + math.Rand(-4, 4), y + tall * 0.2 + math.Rand(-9, 9), Color(255, 255, 255, math.Rand(10, 120)), TEXT_ALIGN_CENTER)
    end
end

local E_LookupBone = meta.LookupBone
local E_GetBoneMatrix = meta.GetBoneMatrix
local E_GetBonePosition = meta.GetBonePosition
local E_SetRenderOrigin = meta.SetRenderOrigin
local E_SetRenderAngles = meta.SetRenderAngles
local E_SetModelScale = meta.SetModelScale
local E_GetOwner = meta.GetOwner
local E_GetNoDraw = meta.GetNoDraw
local E_GetTable = meta.GetTable
local E_DrawModel = meta.DrawModel

local VM_Meta = FindMetaTable("VMatrix")
local VM_GetTranslation = VM_Meta.GetTranslation
local VM_GetAngles = VM_Meta.GetAngles

local Ang_Meta = FindMetaTable("Angle")
local A_Forward = Ang_Meta.Forward
local A_Right = Ang_Meta.Right
local A_Up = Ang_Meta.Up
local A_RotateAroundAxis = Ang_Meta.RotateAroundAxis

function SWEP:DrawWorldModel()
	local owner = E_GetOwner(self)
    if not E_IsValid(owner) then
        E_SetRenderOrigin(self, nil)
        E_SetRenderAngles(self, nil)
        E_DrawModel(self)
        return
    end

	if E_GetTable(owner).ShadowMan and MySelf:IsSurvivor() then return end

	self:SCKWorldModel()
end

function SWEP:OnRemove()
	self:SCKOnRemove()
end

function SWEP:ViewModelDrawn()
	self:SCKViewModel()

    self:ProcessCurrentSoundScript()
end

function SWEP:GetTracerOrigin()
    local owner = self:GetOwner()
    if E_IsValid(owner) then
        local vm = owner:GetViewModel()
        if E_IsValid(vm) then
            local attachment = vm:GetAttachment(1)
            if attachment then
                return attachment.Pos
            end
        end
    end

    return nil
end

function SWEP:ShouldDrawReloadTime()
    return self:GetReloadFinish() > 0
end

function SWEP:GetReloadHUDStart()
    return self:GetReloadStartTime()
end

function SWEP:GetReloadHUDFinish()
    return self:GetReloadFinish()
end

function SWEP:GetReloadTimeHUD()
    local time = self:GetReloadHUDFinish() - CurTime()
    if time < 0 then
        return 0 .. " s"
    end

    return math.Round(time, 1).." s"
end