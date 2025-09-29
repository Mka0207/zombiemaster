-- Written by How Super Terrible/Marco.
-- Player Meta
local meta = FindMetaTable("Entity")
local E_Health = meta.Health
local E_IsValid = meta.IsValid
local E_SetHealth = meta.SetHealth

meta.OldTakeDamageInfo = meta.OldTakeDamageInfo or meta.TakeDamageInfo
local E_OldTakeDamageInfo = meta.OldTakeDamageInfo

local P_Meta = FindMetaTable("Player")
local P_Alive = P_Meta.Alive
local P_GodMode = P_Meta.HasGodMode
local P_Armor = P_Meta.Armor
local P_SetArmor = P_Meta.SetArmor

local math_floor = math.floor
local bit_band = bit.band
local math_ceil = math.ceil

local DI_Meta = FindMetaTable("CTakeDamageInfo")
local DI_GetDamage = DI_Meta.GetDamage
local DI_GetDamageType = DI_Meta.GetDamageType

local damage_carry_over = {}
local hook_call = hook.Call

local IGNORE_DAMAGETYPE = bit.bor(DMG_FALL,DMG_DROWN,DMG_POISON,DMG_RADIATION)
local IGNORE_DAMAGETYPE_NOPOISON = bit.bor(DMG_FALL,DMG_DROWN)

local taking_damage = false

util.AddNetworkString("zs_dmg")
util.AddNetworkString("zs_dmg_prop")
util.AddNetworkString("zs_dmg_headshot")
util.AddNetworkString("zs_dmg_armor")

local function EntityPlayer(ent, attacker, dmginfo)
	if taking_damage then
		local inflictor = dmginfo:GetInflictor()
		local inf_v = IsValid(inflictor)

		if inf_v then
			ErrorNoHalt("Doubled up damage event!" .. tostring(inflictor) .. " - " .. DI_GetDamage(dmginfo))
		end

		taking_damage = false

		return
	end

	taking_damage = true

	local entity_hp = E_Health(ent)
	if entity_hp >= 0 then
		local damage = DI_GetDamage(dmginfo)
		if damage > 0 then
            local realdamage = damage
            local armor = P_Armor(ent)
            
            if armor>0 and bit_band(DI_GetDamageType(dmginfo),ent.bHasHazmat and IGNORE_DAMAGETYPE_NOPOISON or IGNORE_DAMAGETYPE)==0 then
                local ratio = hook_call("PlayerArmorDamaged", GAMEMODE, ent, attacker, dmginfo)
                if ratio == nil then ratio = ARMOR_RATIO end
                
                if ratio ~= true and ratio > 0 then
                    local armreduct = math_ceil(damage*ratio)
                    if armor<armreduct then
                        armreduct = armor
                        P_SetArmor(ent,0)
                    else
                        P_SetArmor(ent,armor-armreduct)
                    end
                    
                    damage = damage-armreduct
                end
            end
            hook_call("PostPlayerHurt", GAMEMODE, ent, attacker, realdamage, dmginfo)
            
			if damage < entity_hp then
				local unfloored_damage	= damage + (damage_carry_over[ent] or 0)
				local damage_used 		= math_floor(unfloored_damage)
				damage_carry_over[ent] 	= unfloored_damage - damage_used

				hook_call("PlayerHurt", GAMEMODE, ent, attacker, entity_hp - damage_used, DI_GetDamage(dmginfo))
				E_SetHealth(ent, entity_hp - damage_used)

				if entity_hp - damage_used <= 0 then
					ent.PlayerIsKilled = true
					E_OldTakeDamageInfo(ent, dmginfo)
					ent.PlayerIsKilled = nil
				end
			else
				ent.PlayerIsKilled = true
				E_OldTakeDamageInfo(ent, dmginfo)
				ent.PlayerIsKilled = nil
			end
		end
	end

	taking_damage = false
end

hook.Add("PlayerSpawn", "PlayerSpawn.Damagefunc", function(pl)
	pl.PlayerIsKilled = false
end)

local function _PlayerDoDamageEvent(self, dmginfo, tr, dir)
	if E_IsValid(self) and dmginfo:GetDamage() > 0 and not P_GodMode(self) and (P_Alive(self) or self.NeverAlive) then
		local attacker = dmginfo:GetAttacker()

		if hook_call("PlayerShouldTakeDamage", GAMEMODE, self, attacker) and not hook_call("EntityTakeDamage", GAMEMODE, self, dmginfo) then
			if tr then hook_call("ScalePlayerDamage", GAMEMODE, self, tr.HitGroup, dmginfo) end -- Call for hitbox damage scale.

			EntityPlayer(self, attacker, dmginfo)
		end
	end
end

P_Meta.TakeDamageInfo = _PlayerDoDamageEvent
P_Meta.DispatchTraceAttack = _PlayerDoDamageEvent

function SV_DispatchTraceAttack(self, dmginfo, tr, dir)
	if EntityIsPlayer(self) then
		_PlayerDoDamageEvent(self, dmginfo, tr, dir)

		return
	end

	self:DispatchTraceAttack(dmginfo, tr, dir)
end