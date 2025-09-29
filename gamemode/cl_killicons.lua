killicon.OldAddFont = killicon.AddFont
killicon.OldAddAlias = killicon.AddAlias
killicon.OldAdd = killicon.Add
killicon.OldDraw = killicon.Draw

local surface_SetTextPos = surface.SetTextPos
local surface_SetFont = surface.SetFont
local surface_SetTextColor = surface.SetTextColor
local surface_DrawText = surface.DrawText
local surface_SetMaterial = surface.SetMaterial
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawTexturedRect = surface.DrawTexturedRect

local storedfonts = {}
local storedicons = {}
local storedsizes = {}
local storedmaterials = {}

function killicon.Exists(name)
	return killicon.Get(name) ~= nil
end

function killicon.AddFont(sClass, sFont, sLetter, cColor)
    storedfonts[sClass] = {sFont, sLetter, cColor}
end

function killicon.Add(sClass, sTexture, cColor)
    storedicons[sClass] = {sTexture, cColor}
end

function killicon.AddAlias(sClass, sBaseClass)
    if storedfonts[sClass] then
        killicon.AddFont(sBaseClass, storedfonts[sClass][1], storedfonts[sClass][2], storedfonts[sClass][3])
    elseif storedicons[sClass] then
        killicon.Add(sBaseClass, storedicons[sClass][1], storedicons[sClass][2])
    end
end

function killicon.Get(sClass)
    return killicon.GetFont(sClass) or killicon.GetIcon(sClass)
end

function killicon.GetFont(sClass)
    return storedfonts[sClass]
end

function killicon.GetIcon(sClass)
    return storedicons[sClass]
end

function killicon.GetSize(name)
    local t = killicon.Get(name)
    if not t then
        t = killicon.Get("default")
    end
	
	if storedsizes[name] then
		return storedsizes[name].w, storedsizes[name].h
	end
	
	local w, h = 0
	if #t == 3 then
		surface.SetFont(t[1])
		w, h = surface.GetTextSize(t[2])
    else
		surface.SetFont("HL2MPTypeDeath")
		w, h = surface.GetTextSize("0")
		
		h = h * 0.75
		
        local mat
        if istable(t[1]) then
            mat = Material(t[1][1])
        else
            mat = Material(t[1])
        end
        
		local tw, th = mat:Width(), mat:Height()
		w = tw * (h / th)
	end
	
	storedsizes[name] = {}
	storedsizes[name].w = w or 32
	storedsizes[name].h = h or 32
	
	return w, h
end

function killicon.Draw(x, y, name, alpha)
    local ki = killicon.Get(name)
    local w, h = 0, 0
    if not ki then
        ki = killicon.Get("default")
        w, h = killicon.GetSize("default")
    else
        w, h = killicon.GetSize(name)
    end
    
    x = x - w * 0.5

    local cols = ki and ki[#ki] or ""
    if #ki == 3 then
        y = y - h * 0.1
        
        surface_SetTextPos(x, y)
        surface_SetFont(ki[1])
        surface_SetTextColor(cols.r, cols.g, cols.b, alpha)
        surface_DrawText(ki[2])
    else
        y = y - h * 0.3
        
        local mat
        if storedmaterials[name] then
            mat = storedmaterials[name]
        else
            if istable(ki[1]) then
                mat = Material(ki[1][1])
            else
                mat = Material(ki[1])
            end
            
            storedmaterials[name] = mat
        end

        surface_SetMaterial(mat)
        surface_SetDrawColor(cols.r, cols.g, cols.b, alpha)
        surface_DrawTexturedRect(x, y, w, h)
    end
end

local DefaultKillIconColor = Color(255, 80, 0, 255)

language.Add("env_laser", "Laser")
language.Add("env_explosion", "Explosion")
language.Add("func_door", "Door")
language.Add("func_door_rotating", "Door")
language.Add("trigger_hurt", "Hazard")
language.Add("func_rotating", "Hazard")
language.Add("fell", "Gravity")
language.Add("worldspawn", "Something")
language.Add("prop_physics", "Prop")
language.Add("prop_physics_respawnable", "Prop")
language.Add("prop_physics_multiplayer", "Prop")
language.Add("entityflame", "Fire")

killicon.Add("default", "HUD/killicons/default", DefaultKillIconColor)
killicon.AddAlias("suicide", "default")
killicon.AddAlias("player", "default")
killicon.AddAlias("worldspawn", "default")
killicon.AddAlias("func_move_linear", "default")
killicon.AddAlias("func_rotating", "default")
killicon.AddAlias("trigger_hurt", "default")

killicon.AddFont("prop_physics", "ZMDeathNotice", "9", DefaultKillIconColor)
killicon.AddAlias("prop_physics_respawnable", "prop_physics")
killicon.AddAlias("prop_physics_multiplayer", "prop_physics")
killicon.AddAlias("func_physbox", "prop_physics")

killicon.AddFont("weapon_smg1", "ZMDeathNotice", "/", DefaultKillIconColor)
killicon.AddFont("weapon_357", "ZMDeathNotice", ".", DefaultKillIconColor)
killicon.AddFont("weapon_ar2", "ZMDeathNotice", "2", DefaultKillIconColor)
killicon.AddFont("crossbow_bolt", "ZMDeathNotice", "1", DefaultKillIconColor)
killicon.AddFont("weapon_shotgun", "ZMDeathNotice", "0", DefaultKillIconColor)
killicon.AddFont("rpg_missile", "ZMDeathNotice", "3", DefaultKillIconColor)
killicon.AddFont("npc_grenade_frag", "ZMDeathNotice", "4", DefaultKillIconColor)
killicon.AddFont("weapon_pistol", "ZMDeathNotice", "-", DefaultKillIconColor)
killicon.AddFont("prop_combine_ball", "ZMDeathNotice", "8", DefaultKillIconColor)
killicon.AddFont("grenade_ar2", "ZMDeathNotice", "7", DefaultKillIconColor)
killicon.AddFont("weapon_stunstick", "ZMDeathNotice", "!", DefaultKillIconColor)
killicon.AddFont("weapon_slam", "ZMDeathNotice", "*", DefaultKillIconColor)
killicon.AddFont("weapon_crowbar", "ZMDeathNotice", "6", DefaultKillIconColor)

killicon.AddFont("weapon_zm_fists", "ZMDeathFonts", "c", DefaultKillIconColor)
killicon.AddFont("weapon_zm_mac10", "ZMDeathFonts", "a", DefaultKillIconColor)
killicon.AddFont("weapon_zm_molotov", "ZMDeathFonts", "k", DefaultKillIconColor)
killicon.AddFont("weapon_zm_pistol", "ZMDeathFonts", "d", DefaultKillIconColor)
killicon.AddFont("weapon_zm_revolver", "ZMDeathFonts", "e", DefaultKillIconColor)
killicon.AddFont("weapon_zm_rifle", "ZMDeathFonts", "f", DefaultKillIconColor)
killicon.AddFont("weapon_zm_shotgun", "ZMDeathFonts", "b", DefaultKillIconColor)
killicon.AddFont("weapon_zm_sledge", "ZMDeathFonts", "i", DefaultKillIconColor)
killicon.AddFont("weapon_zm_improvised", "ZMDeathFonts", "h", DefaultKillIconColor)

killicon.AddFont("ammo_pistol", "ZMDeathFonts", "p", color_white)
killicon.AddFont("ammo_smg1", "ZMDeathFonts", "r", color_white)
killicon.AddFont("ammo_357", "ZMDeathFonts", "q", color_white)
killicon.AddFont("ammo_revolver", "ZMDeathFonts", "q", color_white)
killicon.AddFont("ammo_buckshot", "ZMDeathFonts", "s", color_white)
killicon.AddFont("ammo_molotov", "ZMDeathFonts", "k", color_white)