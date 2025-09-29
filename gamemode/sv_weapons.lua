-- This is optimisation because of performance.
if META_GLOBAL_WEP_TBL then return end
META_GLOBAL_WEP_TBL = true

local meta = FindMetaTable("Weapon")
if not meta then return end

WEP_META_NEXTRELOAD = WEP_META_NEXTRELOAD or {}
WEP_META_RELOADSTART = WEP_META_RELOADSTART or {}
WEP_META_RELOADEND = WEP_META_RELOADEND or {}

local E_META = FindMetaTable("Entity")
local E_GetTable = E_META.GetTable
local E_GetVelocity = E_META.GetVelocity

local WEP_META_PRIMARY_CLIP = {}
local WEP_META_SECONDARY_CLIP = {}

-- WEAPON CLIP
meta.Clip1Old = meta.Clip1Old or meta.Clip1
meta.Clip2Old = meta.Clip2Old or meta.Clip2
meta.SetClip1Old = meta.SetClip1Old or meta.SetClip1
meta.SetClip2Old = meta.SetClip2Old or meta.SetClip2

function meta:Clip1()
	return rawget(WEP_META_PRIMARY_CLIP, self) or self:Clip1Old()
end

function meta:Clip2()
	return rawget(WEP_META_SECONDARY_CLIP, self) or self:Clip2Old()
end

function meta:SetClip1(amount)
	rawset(WEP_META_PRIMARY_CLIP, self, time)

	return self:SetClip1Old(amount)
end

function meta:SetClip2(amount)
	rawset(WEP_META_SECONDARY_CLIP, self, time)

	return self:SetClip2Old(amount)
end

local W_GetNextPrimaryFire = meta.GetNextPrimaryFire
local W_GetNextSecondaryFire = meta.GetNextSecondaryFire

local PLAYER_HasNotAutoWeapon_P = {}
local PLAYER_HasNotAutoWeapon_S = {}

local p_meta = FindMetaTable("Player")
--local P_GetActiveWeapon = p_meta.GetActiveWeapon

p_meta.StripWeaponOld = p_meta.StripWeaponOld or p_meta.StripWeapon
p_meta.StripWeaponsOld = p_meta.StripWeaponsOld or p_meta.StripWeapons

local c_meta = FindMetaTable("CMoveData")
--local C_KeyDown = c_meta.KeyDown
local C_GetButtons = c_meta.GetButtons

-- local bit_band = bit.band
-- how the fuck is this faster than bit.band? is it because skipping CheckType or some shit?
local math_floor = math.floor
local function fast_bit_band(a, b)
	local result = 0
	local bitval = 1

	while (a > 0 and b > 0) do
		if (a % 2 == 1 and b % 2 == 1) then
			result = result + bitval
		end

		bitval = bitval * 2

		a = math_floor(a * 0.5)
		b = math_floor(b * 0.5)
	end

	return result
end

-- CWeaponSWEP::ItemPostFrame has been detoured so let go use with LUA!
local gamemode_Call = gamemode.Call
local ply_index, wep, wep_tab, wep_act, current_act, wep_think, wep_reload, wep_primaryatk, wep_secondaryatk, wep_translateactivity, IN_RELOAD_PRESSED, IN_ATTACK_PRESSED, IN_ATTACK2_PRESSED

function GM:ItemPostFrame(pl, wep, buttons, velocity)
	wep_tab = wep and E_GetTable(wep)

	ply_index = pl:EntIndex()
	if ply_index > 0 then
		-- caching calcmainactivity
		current_act = ACT_MP_STAND_IDLE

		if GMUTIL_UpdateCalcMainActivity then
			current_act, act_override = gamemode_Call("CalcMainActivity", pl, velocity)

			GMUTIL_UpdateCalcMainActivity(ply_index, current_act or 0, act_override or 0)
		end

		-- caching translate activity from wep act.
		if GMUTIL_UpdateTranslateActivity then
			if wep_tab then -- lua valid!
				wep_translateactivity = wep_tab.TranslateActivity
				if wep_translateactivity then -- careful, some wep class doesnt exist.
					wep_act = wep_translateactivity(wep, current_act)
					if wep_act ~= -1 then
						current_act = wep_act
					end
				end
			else -- outside of weapon such as like HL2...
				wep_act = pl:TranslateWeaponActivity(current_act)
				if wep_act ~= -1 then
					current_act = wep_act
				end
			end

			GMUTIL_UpdateTranslateActivity(ply_index, current_act or 0)
		end
	end

	if not wep_tab then return end -- REQUIRE WEP VALID

	wep_think = wep_tab.Think
	if wep_think then
		wep_think(wep)
	end

	-- checking is player press anything down?

	IN_RELOAD_PRESSED = fast_bit_band(buttons, IN_RELOAD) == IN_RELOAD
	IN_ATTACK_PRESSED = fast_bit_band(buttons, IN_ATTACK) == IN_ATTACK
	IN_ATTACK2_PRESSED = fast_bit_band(buttons, IN_ATTACK2) == IN_ATTACK2

	wep_reload = wep_tab.Reload
	if IN_RELOAD_PRESSED and wep_reload then
		wep_reload(wep)
	end

	wep_primaryatk = wep_tab.PrimaryAttack
	if IN_ATTACK_PRESSED and wep_primaryatk and W_GetNextPrimaryFire(wep) <= CurTime() then
		if wep_tab.Primary.Automatic then
			wep_primaryatk(wep)
		elseif not PLAYER_HasNotAutoWeapon_P[pl] then
			PLAYER_HasNotAutoWeapon_P[pl] = true

			wep_primaryatk(wep)
		end
	else
		PLAYER_HasNotAutoWeapon_P[pl] = IN_ATTACK_PRESSED
	end

	wep_secondaryatk = wep_tab.SecondaryAttack
	if IN_ATTACK2_PRESSED and wep_secondaryatk and W_GetNextSecondaryFire(wep) <= CurTime() then
		if wep_tab.Secondary.Automatic then
			wep_secondaryatk(wep)
		elseif not PLAYER_HasNotAutoWeapon_S[pl] then
			PLAYER_HasNotAutoWeapon_S[pl] = true

			wep_secondaryatk(wep)
		end
	else
		PLAYER_HasNotAutoWeapon_S[pl] = IN_ATTACK2_PRESSED
	end
end
