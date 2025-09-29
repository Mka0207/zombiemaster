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
DEFINE_BASECLASS("weapon_zm_base")

SWEP.Base             = "weapon_zm_base"
SWEP.HoldType         = "shotgun"

SWEP.Primary.Delay    = 0.8
SWEP.ReloadDelay      = 1
SWEP.ReloadSpeed      = 1.0

SWEP.ReloadSound      = Sound("Weapon_Shotgun_ZM.Reload")
SWEP.Primary.Sound    = Sound("Weapon_Shotgun_ZM.Single")
SWEP.PumpSound        = Sound("Weapon_Shotgun_ZM.Special1")
SWEP.EmptySound       = Sound("Weapon_Shotgun_ZM.Empty")

SWEP.bUsePumpSoundOnReloadEnd = true

SWEP.Primary.Ammo     = "buckshot"
SWEP.Primary.DamageType = bit.bor(DMG_BULLET, DMG_BUCKSHOT)

SWEP.CurReload        = ACT_VM_RELOAD
SWEP.CurReloadEmpty   = ACT_VM_RELOAD_EMPTY
SWEP.EndReloadPump    = ACT_SHOTGUN_PUMP
SWEP.BeginReload      = ACT_SHOTGUN_RELOAD_START
SWEP.PumpAct          = ACT_SHOTGUN_PUMP

AccessorFuncDT(SWEP, "ShotgunPump", "Float", 1)
AccessorFuncDT(SWEP, "PumpEnd", "Float", 2)
AccessorFuncDT(SWEP, "Pumping", "Bool", 1)

function SWEP:Reload()
	local stbl = E_GetTable(self)
    if stbl.bEmptyReloadSpeedLoader and self:SelectWeightedSequence(stbl.CurReloadEmpty) ~= -1 and self:Clip1() == 0 then
        BaseClass.Reload(self)
        return
    end

	if not self:IsReloading() then
		if self:CanReload() then
			self:StartReloading()
		elseif stbl.EndReloadTime == 0 then
			self:PlayInspect()
		end
	end
end

function SWEP:Think()
	local stbl = E_GetTable(self)
	local ct = CurTime()
    if stbl.bEmptyReloadSpeedLoader and self:GetReloadFinish() > 0 and self:SelectWeightedSequence(stbl.CurReloadEmpty) ~= -1 and self:Clip1() == 0 then
        BaseClass.Think(self)
        return
    end

    if IS_CLIENT_RUNNING then
        self:ProcessCurrentSoundScript()
    end

	if self:ShouldDoReload() then
		self:DoReloadThink()
	end

    if stbl.FirstShellDelay and stbl.FirstShellDelay ~= 0 and stbl.FirstShellDelay < ct then
        stbl.FirstShellDelay = 0
        self:DoReloadThink(true)
    end

    if self:GetShotgunPump() ~= 0 and self:GetShotgunPump() < ct then
        self:SendWeaponAnim(self:GetPumpActivity())
		if self.PumpSound then
			self:EmitSound(stbl.PumpSound)
		end
        self:SetShotgunPump(0)
        self:SetPumpEnd(ct + self:SequenceDuration())
    end

	if (stbl.EndReloadTime or 0) < ct then
		stbl.EndReloadTime = 0
	end

    local pumpend = self:GetPumpEnd()
    if pumpend ~= 0 and pumpend < ct then
        self:SetPumping(false)
        self:SetPumpEnd(0)
    end

	self:NextThink(CurTime())
	return true
end

function SWEP:StartReloading()
	local stbl = E_GetTable(self)
	local ct = CurTime()
	local owner = self:GetOwner()

    local bEmpty = stbl.BeginReloadEmpty and self:SelectWeightedSequence(stbl.BeginReloadEmpty) ~= -1 and self:Clip1() <= 0
	if stbl.BeginReload or bEmpty then
		self:SendWeaponAnim(bEmpty and stbl.BeginReloadEmpty or stbl.BeginReload)
	end

    if bEmpty and stbl.BeginReloadEmptyLoadsFirstShell then
        local reloadspeed = self:GetReloadSpeed(owner)
        stbl.FirstShellDelay = ct + (stbl.DelayFirstLoadEmpty * reloadspeed)
        self:SetDTFloat(3, ct + (self:SequenceDuration() * reloadspeed))
    else
        local delay = self:GetReloadDelay()
        self:SetDTFloat(3, ct + delay)
    end

	self:SetDTFloat(31, ct)
	if stbl.HoldForReload then
		self:SetDTBool(2, true)
	end
	self:SetNextPrimaryFire(ct + math.max(stbl.Primary.Delay, self:GetDTFloat(3)))

	owner:DoReloadEvent()

    stbl.bClipWasEmpty = self:Clip1() == 0
end

function SWEP:StopReloading()
	local stbl = E_GetTable(self)
	local ct = CurTime()

	self:SetDTFloat(3, 0)
    self:SetDTFloat(31, 0)
	if stbl.HoldForReload then
		self:SetDTBool(2, false)
	end
	self:SetNextPrimaryFire(ct + stbl.Primary.Delay)

	if self:Clip1() > 0 then
		if stbl.PumpSound and stbl.bUsePumpSoundOnReloadEnd then
			self:EmitSound(stbl.PumpSound)
		end

        if stbl.EndReloadPumpEmpty and self:SelectWeightedSequence(stbl.EndReloadPumpEmpty) ~= -1 and stbl.bClipWasEmpty then
            self:SendWeaponAnim(stbl.EndReloadPumpEmpty)
            self.EndReloadTime = CurTime() + self:SequenceDuration()
        elseif stbl.EndReloadPump then
            self:SendWeaponAnim(stbl.EndReloadPump)
            self.EndReloadTime = CurTime() + self:SequenceDuration()
        end
    end
end

function SWEP:GetReloadDelay()
	return (self.bUseSequenceDurationForReload and self:SequenceDuration() or self.ReloadDelay) * self:GetReloadSpeed(self:GetOwner())
end

function SWEP:ShouldDoReload()
	return self:GetDTFloat(3) > 0 and CurTime() >= self:GetDTFloat(3)
end

function SWEP:IsReloading()
	return self:GetDTFloat(3) > 0
end

function SWEP:CanReload()
	return self:Clip1() < self.Primary.ClipSize and self:Ammo1() > 0 and not self:GetPumping()
end

function SWEP:SecondaryAttack()
end

function SWEP:CanStopReload()
    local owner = self:GetOwner()
	if not self:CanReload() or owner:KeyDown(IN_ATTACK) or (self.HoldForReload and not self:GetDTBool(2) and not owner:KeyDown(IN_RELOAD)) then
		return true
	end

    return false
end

function SWEP:DoReloadThink(bOnlyAmmo)
    local owner = self:GetOwner()
	local stbl = E_GetTable(self)
	local primary = stbl.Primary

	if not bOnlyAmmo and self:CanStopReload() then
        self:StopReloading()
        return
    end

    if not bOnlyAmmo then
        if stbl.CurReloadEmpty and self:SelectWeightedSequence(self.CurReloadEmpty) ~= -1 and self:Clip1() == 0 then
            self:SendWeaponAnim(stbl.CurReloadEmpty)
        elseif stbl.CurReload then
            self:SendWeaponAnim(stbl.CurReload)
        end

        if stbl.ReloadSound then
            self:EmitSound(stbl.ReloadSound)
        end
    end

	local max1 = self:GetPrimaryClipSize()
	local spare = owner:GetAmmoCount(primary.Ammo)
	local current = self:Clip1()
	local needed = math.min(max1 - current, primary.ReloadAmount or 1)

	needed = math.min(spare, needed)

	owner:RemoveAmmo(needed, primary.Ammo, false)
	self:SetClip1(current + needed)

	if bOnlyAmmo then
        if self:CanStopReload() then
            self:StopReloading()
        end

        return
    end
	local ct = CurTime()
    local delay = self:GetReloadDelay()
	if stbl.HoldForReload then
		self:SetDTBool(2, false)
	end
	self:SetDTFloat(3, ct + delay)
    self:SetDTFloat(31, ct)

	self:SetNextPrimaryFire(ct + math.max(primary.Delay, delay))
end

function SWEP:CanPrimaryAttack()
    return BaseClass.CanPrimaryAttack(self) and not self:GetPumping()
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	BaseClass.PrimaryAttack(self)

    self:AddViewKick(false)

	if self:SelectWeightedSequence(self:GetPumpActivity()) ~= -1 then
		self:SetShotgunPump(CurTime() + self:SequenceDuration())
		self:SetPumping(true)
	end
end

function SWEP:GetPumpActivity()
    local pumpact = self.PumpAct
    if istable(pumpact) then
        pumpact = pumpact[math.Round(util.SharedRandom("PumpAct_"..tostring(self), 1, #pumpact))]
    end

    return pumpact
end

if not IS_CLIENT_RUNNING then return end

function SWEP:ShouldDrawReloadTime()
    return self:IsReloading()
end

function SWEP:GetReloadHUDStart()
    return self:GetDTFloat(3)
end

function SWEP:GetReloadHUDFinish()
    return self:GetDTFloat(31)
end

function SWEP:GetReloadTimeHUD()
    local time = self:GetDTFloat(3) - CurTime()
    if time < 0 then
        return 0 .. " s"
    end

    return math.Round(time, 1).." s"
end