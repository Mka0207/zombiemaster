local meta = FindMetaTable("Weapon")
if not meta then return end

function meta:ShouldNotCollide(ent)
    return ent:IsWeapon() or ent.bIsAmmo
end

function meta:ValidPrimaryAmmo()
    local ammotype = self:GetPrimaryAmmoTypeString()
    if ammotype and ammotype ~= "none" then
        return ammotype
    end
end

function meta:ValidSecondaryAmmo()
    local ammotype = self:GetSecondaryAmmoTypeString()
    if ammotype and ammotype ~= "none" then
        return ammotype
    end
end

local TranslatedAmmo = {}
TranslatedAmmo[-1] = "none"
TranslatedAmmo[0] = "none"
TranslatedAmmo[1] = "ar2"
TranslatedAmmo[2] = "alyxgun"
TranslatedAmmo[3] = "pistol"
TranslatedAmmo[4] = "smg1"
TranslatedAmmo[5] = "357"
TranslatedAmmo[6] = "xbowbolt"
TranslatedAmmo[7] = "buckshot"
TranslatedAmmo[8] = "rpg_round"
TranslatedAmmo[9] = "smg1_grenade"
TranslatedAmmo[10] = "sniperround"
TranslatedAmmo[11] = "sniperpenetratedround"
TranslatedAmmo[12] = "grenade"
TranslatedAmmo[13] = "thumper"
TranslatedAmmo[14] = "gravity"
TranslatedAmmo[14] = "battery"
TranslatedAmmo[15] = "gaussenergy"
TranslatedAmmo[16] = "combinecannon"
TranslatedAmmo[17] = "airboatgun"
TranslatedAmmo[18] = "striderminigun"
TranslatedAmmo[19] = "helicoptergun"
TranslatedAmmo[20] = "ar2altfire"
TranslatedAmmo[21] = "slam"

function meta:GetPrimaryAmmoTypeString()
    if self.Primary and self.Primary.Ammo then return string.lower(self.Primary.Ammo) end
    return TranslatedAmmo[self:GetPrimaryAmmoType()] or "none"
end

function meta:GetSecondaryAmmoTypeString()
    if self.Secondary and self.Secondary.Ammo then return string.lower(self.Secondary.Ammo) end
    return TranslatedAmmo[self:GetSecondaryAmmoType()] or "none"
end

function meta:GetReloadSpeed(owner)
    return (self.ReloadTimeMultiplier or 1) * (self.ReloadAnimTotal or 1) * (1-(owner.WeaponReloadRate or 0))
end

local ReloadAnims = {
    [ACT_VM_RELOAD] = true,
    [ACT_VM_RELOAD_SILENCED] = true,
    [ACT_VM_RELOAD_DEPLOYED] = true,
    [ACT_VM_RELOAD_IDLE] = true,
    [ACT_VM_RELOAD_EMPTY] = true,
    [ACT_VM_RELOADEMPTY] = true,
    [ACT_VM_RELOAD_M203] = true,
    [ACT_VM_RELOAD_INSERT] = true,
    [ACT_VM_RELOAD_INSERT_PULL] = true,
    [ACT_VM_RELOAD_END] = true,
    [ACT_VM_RELOAD_END_EMPTY] = true,
    [ACT_VM_RELOAD_INSERT_EMPTY] = true,
    [ACT_VM_RELOAD2] = true
}

meta.OldSendWeaponAnim = meta.OldSendWeaponAnim or meta.SendWeaponAnim
function meta:SendWeaponAnim(anim)
	self:OldSendWeaponAnim(anim)

	local owner = self:GetOwner()
	if IsValid(owner) then
		local vm = owner:GetViewModel()
		if IsValid(vm) then
            local rate = vm:GetPlaybackRate()
			if (anim == ACT_VM_DRAW or anim == ACT_VM_DRAW_SILENCED) and self.DeployAnimRate then
				rate = self.DeployAnimRate
			elseif (anim == ACT_VM_PRIMARYATTACK or anim == ACT_VM_PRIMARYATTACK_SILENCED) and self.Primary and self.Primary.Delay then
				rate = rate * (self.AttackAnimRate or 1)
			elseif ReloadAnims[anim] then
				rate = rate / self:GetReloadSpeed(owner)
            elseif (self.PumpAction and anim == self.PumpAction) or (self.EndReloadPump and anim == self.EndReloadPump) then
                rate = rate * (self.PumpAnimRate or 1)
			end
            
            self:HandleSoundScript(anim, rate)
            vm:SetPlaybackRate(rate)
		end
	end
end

function meta:GetSequenceDurationVM(activity)
	local vm = self:GetOwner():GetViewModel()
	if not IsValid(vm) then return 0 end

	local requested_duration = activity and vm:SelectWeightedSequence(activity)
	return vm:SequenceDuration(requested_duration)
end

-- by magicswap
function meta:PlayThirdpersonTaunt(seq)
	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	if SERVER then
		local pvs = RecipientFilter()
		pvs:AddPVS(owner:WorldSpaceCenter())

		net.Start("zs_playtaunt")
			net.WriteUInt(GESTURE_SLOT_ATTACK_AND_RELOAD, 4)
			net.WriteString(seq)
			net.WriteEntity(owner)
		net.Send(pvs)
	end
end

--Support for soundscripts with reload animations

--[[
FORMAT:
["name"] = {
	{time = num, snd = "path/to/sound.snd", pitch = 100 (optional, can be table for range), lvl = 75 (soundlevel, optional)}
}
--]]

function meta:HandleSoundScript(anim, rate)
	if CLIENT and IsFirstTimePredicted() then
		self:KillSoundScript()

		if self.Soundscripts and self.Soundscripts[anim] then
			self:PlaySoundScript(anim, rate or 1)
		end
	end
end

function meta:PlaySoundScript(name, speed, cycle)
    if not self.Soundscripts then return end

	local t = self.Soundscripts[name]
	if not t then return end

	cycle = cycle or 0

	local total = self:SequenceDuration()
	local time = CurTime() + cycle * total
	self.CurSoundTable = t
	self.CurSoundEntry = 1
	self.CurSoundSpeed = speed
	self.CurSoundTime = time

	self:ProcessCurrentSoundScript()
end

function meta:KillSoundScript()
	self.CurSoundTable = nil
	self.CurSoundEntry = nil
	self.CurSoundTime = nil
	self.CurSoundSpeed = nil
end

function meta:ProcessCurrentSoundScript()
	if not self.CurSoundTable then return end

	local t = self.CurSoundTable[self.CurSoundEntry]
	if not t then self:KillSoundScript() return end

	local flCT = CurTime()
	if flCT >= self.CurSoundTime + (t.time / self.CurSoundSpeed) then
		local pitch = istable(t.pitch) and math.random(t.pitch[1], t.pitch[2]) or t.pitch
		self:EmitSound(t.snd, t.lvl or 75, pitch or 100, t.vol or 1, CHAN_AUTO)

		if self.CurSoundTable[self.CurSoundEntry+1] then
			self.CurSoundEntry = self.CurSoundEntry + 1
		else
			self:KillSoundScript()
		end
	end
end

local M_Entity = FindMetaTable("Entity")
local E_GetTable = M_Entity.GetTable
local E_GetOwner = M_Entity.GetOwner

local val
local wt
function meta:__index(key)
	val = meta[key]
	if val ~= nil then return val end

	val = M_Entity[key]
	if val ~= nil then return val end

	-- Deprecated, don't use
	if key == "Owner" then return E_GetOwner(self) end

	wt = E_GetTable(self)
	if wt then
		return wt[key]
	end
end

if not CLIENT then return end

local E_Meta = FindMetaTable("Entity")
local E_WorldSpaceCenter = E_Meta.WorldSpaceCenter
local E_GetPos = E_Meta.GetPos
local E_GetTable = E_Meta.GetTable

local V_Meta = FindMetaTable("Vector")
local V_Dot = V_Meta.Dot
local V_DistToSqr = V_Meta.DistToSqr

local EyeVector = EyeVector
local EyePos = EyePos
local CurTime = CurTime
local LocalPlayer = LocalPlayer

local hook_Call = hook.Call

function meta:ShouldDrawOutline()
    if not GAMEMODE.bUseItemHalos then return false end

    local ct = CurTime()
    local tb = E_GetTable(self)
	if (tb.NextUpdateOutline or 0)<ct then
        tb.NextUpdateOutline = ct+0.25
        if IsValid(self:GetOwner()) then
            tb.PickupCache = false
        else
            local DotDist = V_Dot(EyeVector(), E_WorldSpaceCenter(self)-EyePos())
            if DotDist<1 or DotDist>20000 then
                tb.PickupCache = false
            else
                tb.PickupCache = V_DistToSqr(E_GetPos(self), E_GetPos(MySelf)) < 42000 and hook_Call("PlayerCanPickupWeapon", GAMEMODE, MySelf, self)
            end
        end
	end

    return tb.PickupCache
end