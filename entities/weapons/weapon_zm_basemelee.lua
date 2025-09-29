AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

SWEP.ViewModel                 = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel                = "models/weapons/w_crowbar.mdl"

SWEP.Primary.ClipSize          = -1
SWEP.Primary.DefaultClip       = -1
SWEP.Primary.Automatic         = true
SWEP.Primary.Ammo              = "none"
SWEP.Primary.DamageType        = DMG_CLUB

SWEP.Secondary.ClipSize        = -1
SWEP.Secondary.DefaultClip     = -1
SWEP.Secondary.Automatic       = false
SWEP.Secondary.Ammo            = "none"

SWEP.Slot                      = 0
SWEP.SlotPos                   = 4

SWEP.DrawAmmo                  = false
SWEP.DrawCrosshair             = true
SWEP.DrawQuickInfo             = false

SWEP.IsMelee                   = true
SWEP.HoldType                  = "melee"

function SWEP:GetHitAct()
    return ACT_VM_HITCENTER
end

function SWEP:GetMissAct()
    return ACT_VM_MISSCENTER
end

function SWEP:CanPrimaryAttack()
	local owner = self:GetOwner()
	if owner:IsHolding() then return false end

    return self:GetNextPrimaryFire() <= CurTime()
end

local ClientsideFBInfos = {}
function SWEP:ClearCLFireBullet()
    ClientsideFBInfos = {}
end

function SWEP:FirebulletSendCL()
    if not CLIENT then return end

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
    if tr.Entity and IsValid(tr.Entity) then
		ClientsideFBInfos[#ClientsideFBInfos + 1] = {[1] = tr.Entity:EntIndex(), [2] = tr.Entity:GetHitBoxBone(tr.HitBox, 0) or -1}
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

SWEP.Bullet = {Tracer = 0, Spread = Vector(0, 0, 0), Num = 1}
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local owner = self.Owner
    owner:DoAttackEvent()

    if not IsFirstTimePredicted() then return end

    if CLIENT then
        self:ClearCLFireBullet()
    end

    local damage = Either(self.Primary.Damage ~= nil, self.Primary.Damage, math.random(self.Primary.MinDamage or 0, self.Primary.MaxDamage or 0))

    owner:LagCompensation(true)
    local trace = util.TraceLine( {
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + (self.Owner:GetAimVector() * self.Primary.Reach),
        filter = GetConVar("zm_disableplayercollision"):GetBool() and player.GetAll() or owner
    } )
    owner:LagCompensation(false)

    if trace.Hit then
        self:SendWeaponAnim(self:GetHitAct())

        self.Bullet.Src    = owner:GetShootPos()
        self.Bullet.Dir    = owner:GetAimVector()
        self.Bullet.Distance = self.Primary.Reach
        self.Bullet.Force  = damage
        self.Bullet.Damage = damage
        self.Bullet.HullSize = self.Primary.Hull or 1

        local this = self
        self.Bullet.Callback = function(attacker, trace, dmginfo)
            this:DefaultCallBack(attacker, trace, dmginfo)

            if CLIENT and this.ClientBulletInfos then
                this:ClientBulletInfos(attacker, trace, dmginfo)
            end
        end

        owner:FireBullets(self.Bullet)

        if trace.MatType == MAT_GRATE or bit.band(trace.Contents, CONTENTS_GRATE) ~= 0 then
            local ent = trace.Entity
            if IsValid(ent) and ent.TakeDamage then
                ent:TakeDamage(damage, owner, self)
            end
        end

        if trace.MatType == MAT_FLESH then
            self:EmitSound(self.Primary.HitFleshSound)
        else
            self:EmitSound(self.Primary.HitSound)
        end

        self:SentWeaponInfos(owner, self.Bullet)
    else
        self:SendWeaponAnim(ACT_VM_HITCENTER)
        self:EmitSound(self.Primary.MissSound)
    end

    self:SetNextIdle(CurTime() + self:SequenceDuration())
    self:FirebulletSendCL()
end

--[[
function SWEP:DefaultCallBack(attacker, tr, dmginfo)
    BaseClass.DefaultCallBack(self, attacker, tr, dmginfo)
    dmginfo:SetDamageType(DMG_CLUB)
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local owner = self.Owner
    owner:DoAttackEvent()

    local damage = Either(self.Primary.Damage ~= nil, self.Primary.Damage, math.random(self.Primary.MinDamage or 0, self.Primary.MaxDamage or 0))
    local trace = util.TraceLine( {
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + (self.Owner:GetAimVector() * self.Primary.Reach),
        filter = team.GetPlayers(owner:Team())
    } )
    if trace.Hit then
        self:SendWeaponAnim(ACT_VM_HITCENTER)
        self:DoMeleeTrace(damage)

        if trace.MatType == MAT_FLESH then
            self:EmitSound(self.Primary.HitFleshSound)
        else
            self:EmitSound(self.Primary.HitSound)
        end
    else
        self:SendWeaponAnim(ACT_VM_HITCENTER)
        self:EmitSound(self.Primary.MissSound)
    end

    self:SetNextIdle(CurTime() + self:SequenceDuration())
end

function SWEP:DoMeleeTrace(damage)
    local owner = self:GetOwner()
    local this = self
    local BulletCallback = function(attacker, trace, dmginfo)
        this:DefaultCallBack(attacker, trace, dmginfo)
        return {tracer = false}
    end

    DO_BULLET_LAG_COMP = true
    owner:MeleeBullet(owner:GetShootPos(), owner:GetAimVector(), damage, owner, self.Primary.Force, BulletCallback, self.Primary.Hull, self.Primary.Reach, self)
    DO_BULLET_LAG_COMP = false
end--]]

if not CLIENT then return end

function SWEP:DrawHUD()
    self:DrawCrosshair()
end

function SWEP:DrawCrosshair()
	if GetConVarNumber("crosshair") ~= 1 then return end
	self:DrawCrosshairDot()
end