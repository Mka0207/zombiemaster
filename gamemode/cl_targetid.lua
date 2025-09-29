local math_max = math.max
local math_Clamp = math.Clamp
local math_min = math.min
local math_ceil = math.ceil

local draw_RoundedBox = draw.RoundedBox
local draw_SimpleText = draw.SimpleText
local draw_SimpleTextOutlined = draw.SimpleTextOutlined
local draw_GetFontHeight = draw.GetFontHeight

local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize

local util_ColorCopy = util.ColorCopy
local util_TraceHull = util.TraceHull

local table_Copy = table.Copy

local string_StripExtension = string.StripExtension
local string_GetFileFromFilename = string.GetFileFromFilename

local GetPlayerTeam = GetPlayerTeam

local Lerp = Lerp
local tostring = tostring
local RealFrameTime = RealFrameTime
local EyePos = EyePos
local CurTime = CurTime
local EyeAngles = EyeAngles
local IsValid = IsValid
local pairs = pairs

local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER

local M_Entity = FindMetaTable("Entity")
local E_Health = M_Entity.Health
local E_GetMaxHealth = M_Entity.GetMaxHealth
local E_GetPos = M_Entity.GetPos
local E_IsValid = M_Entity.IsValid

local M_Player = FindMetaTable("Player")
local P_GetMaxZombieHealth = M_Player.GetMaxZombieHealth
local P_Nick = M_Player.Nick
local P_GetActiveWeapon = M_Player.GetActiveWeapon
local P_GetObserverTarget = M_Player.GetObserverTarget
local P_Name = M_Player.Name

local M_Vector = FindMetaTable("Vector")
local V_ToScreen = M_Vector.ToScreen

local M_Weapon = FindMetaTable("Weapon")
local W_GetPrintName = M_Weapon.GetPrintName

local M_Angle = FindMetaTable("Angle")
local A_Forward = M_Angle.Forward

local ScreenW, ScreenH = ScrW(), ScrH()
local GlobalScreenScale = BetterScreenScale()
hook.Add("OnScreenSizeChanged", "OnScreenSizeChanged.TargetID", function()
    ScreenH = ScrH()
    ScreenW = ScrW()
    
    GlobalScreenScale = BetterScreenScale()
end)

local localTeam = LocalPlayer():IsValid() and LocalPlayer():Team()
hook.Add("OnPlayerChangedTeam", "OnPlayerChangedTeam.TargetID", function(pl, old, new)
    if pl == MySelf then localTeam = new end
end)

local function OldDrawTargetID(ent, text, fraction, x, y, xalign, yalign)
    local green = fraction * 255
    local healthCol = Color(255 - green, green, 0)
    
    draw.SimpleTextOutlined(text, "DermaLarge", x, y, healthCol, xalign, yalign, 1, color_black)
end

local trace = {mask = MASK_SHOT, mins = Vector(-2, -2, -2), maxs = Vector(2, 2, 2), filter = {}}
local entitylist = {}

local colTargetIDW = Color(255, 255, 255, 255)
local colTarget = Color(0, 150, 0)
local colOutline = Color(0, 0, 0)
function GM:DrawTargetID(ent, fade, boverride)
	fade = fade or 1
    
    local a = (fade * 255)
	local ts = V_ToScreen(E_GetPos(ent))
	local x, y = ts.x, math_Clamp(ts.y, 0, ScreenH * 0.95)
    
    colOutline.a = a
    colTarget.a = a

	local name = P_Name(ent)
	draw_SimpleTextOutlined(name, "TargetID", x, y, colTarget, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, colOutline)
	surface_SetFont("TargetID")
	local texw, texh = surface_GetTextSize(name)
	y = y + texh + 4

	local healthfraction = math_max(E_Health(ent) / E_GetMaxHealth(ent), 0)
    local green = healthfraction * 255
    local healthCol = Color(255 - green, green, 0, a)
    
    local health = E_Health(ent)
    local healthtext = health < 20 and "Critical" or health < 50 and "Wounded" or health < 75 and "Injured" or "Healthy"
    draw_SimpleTextOutlined(healthtext, "TargetID", x, y, healthCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, colOutline)
    surface_SetFont("TargetID")
    local texw, texh = surface_GetTextSize(healthtext)
    y = y + texh + 4

	colTargetIDW.a = a

    if ent.CarryProp and E_IsValid(ent.CarryProp) then
        local prop_name = string_StripExtension(string_GetFileFromFilename(ent.CarryProp:GetModel())) or "Unknown"
        draw_SimpleTextOutlined("Holding ["..prop_name.."]", "TargetID", x, y, colTargetIDW, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, colOutline)
    else
        local wep = P_GetActiveWeapon(ent)
        if E_IsValid(wep) then
            draw_SimpleTextOutlined(W_GetPrintName(wep), "TargetID", x, y, colTargetIDW, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, colOutline)
        end
    end
end

local function FuncFilterPlayers(ent)
	return not EntityIsPlayer(ent)
end
function GM:HUDDrawTargetID(teamid)
    if localTeam == TEAM_ZOMBIEMASTER then 
        hook.Call("DrawZMTargetID", self) 
        return 
    elseif localTeam == TEAM_SPECTATOR and IsValid(MySelf:GetObserverTarget()) then
        hook.Call("DrawSpectatorTargetID", self)
        return
    end
    
    local currentTime = CurTime()
	local start = EyePos()
	trace.start = start
	trace.endpos = start + A_Forward(EyeAngles()) * 2048
    trace.filter = {}
	trace.filter[1] = MySelf
	trace.filter[2] = P_GetObserverTarget(MySelf)
    
    local entity = util_TraceHull(trace).Entity
    self.TraceTarget = entity

	if E_IsValid(entity) then
		entitylist[entity] = CurTime()
	end

	for ent, time in pairs(entitylist) do
		if E_IsValid(ent) and EntityIsPlayer(ent) and (GetPlayerTeam(ent) == teamid or teamid == TEAM_SPECTATOR or VisibleTarget == ent) and currentTime < time + 1.5 and not ent.bHidden then
			self:DrawTargetID(ent, 1 - math_Clamp((currentTime - time) / 1.5, 0, 1), VisibleTarget == ent)
		else
            if VisibleTarget == ent then
                VisibleTarget = NULL
            end
			entitylist[ent] = nil
		end
	end
end

function GM:DrawSpectatorTargetID()
    local ent = MySelf:GetObserverTarget()
    if ent:IsRagdoll() then return end
    
    local name = ""
    local maxhealth = 0
    local healthtext = ent:Health()
    if ent:IsPlayer() then
        name = ent:Name()
        maxhealth = ent:GetMaxHealth()
        
        if ent:IsZM() then
            healthtext = "Zombie Master"
        end 
    elseif ent:IsNPC() or ent:IsNextBot() then
        local tab = self:GetZombieData(ent:GetClass())
        if tab then
            name = tab.Name
            maxhealth = tab.Health
        end
    end
    
    local text = name .. " (" .. healthtext .. ")"
    OldDrawTargetID(ent, text, math.Clamp(ent:Health() / maxhealth, 0, 1), ScrW() * 0.5, ScrH() * 0.95, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end

function GM:DrawZMTargetID()
    local tr = vgui.CursorVisible() and MySelf:GetMouseTrace() or MySelf:GetEyeTrace()
    
    if not tr.Hit or not tr.HitNonWorld then
        if not self.DrawingPowerTooltip and IsValid(self.ToolPan_Center_Tip) and not self.ToolPan_Center_Tip.bFadeOut then 
            self.ToolPan_Center_Tip.bFadeOut = true
            self.ToolPan_Center_Tip.bFadeIn = false
            self.ToolPan_Center_Tip.m_AnimList = nil
            self.ToolPan_Center_Tip:AlphaTo(0, 0.2) 
        end
        
        return
    end
    
    local ent = tr.Entity
    if not IsValid(ent) then return end
    
    if not (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then
        if not self.DrawingPowerTooltip then
            if IsValid(self.ToolPan_Center_Tip) and not self.ToolPan_Center_Tip.bFadeOut then 
                self.ToolPan_Center_Tip.bFadeOut = true
                self.ToolPan_Center_Tip.bFadeIn = false
                self.ToolPan_Center_Tip.m_AnimList = nil
                self.ToolPan_Center_Tip:AlphaTo(0, 0.2) 
            end
        end
        
        return
    end
    
    if not IsValid(self.ToolLab_Center_Tip) or not IsValid(self.ToolPan_Center_Tip) then return end
    
    if not self.ToolPan_Center_Tip.bFadeIn then
        self.ToolPan_Center_Tip.bFadeOut = false
        self.ToolPan_Center_Tip.bFadeIn = true
        self.ToolPan_Center_Tip.m_AnimList = nil
        self.ToolPan_Center_Tip:AlphaTo(255, 0.2)
    end
    
    if ent:IsPlayer() then
        self.ToolLab_Center_Tip:SetText(translate.Format("targetid_tooltip_human", ent:Name()))
        self.ToolLab_Center_Tip:SizeToContents()
    elseif ent:IsNPC() or ent:IsNextBot() then
        local name = "ERROR"
        local datatable = self:GetZombieTable()
        for _, data in pairs(datatable) do
            if data.Class == ent:GetClass() then
                name = data.Name
                break
            end
        end
        
        self.ToolLab_Center_Tip:SetText(translate.Format("targetid_tooltip_"..string.lower(name), name))
        self.ToolLab_Center_Tip:SizeToContents()
    end
    
    self.ToolPan_Center_Tip:InvalidateLayout(true)
    self.ToolPan_Center_Tip:SizeToChildren(true, false)
    self.ToolPan_Center_Tip:SetSize(self.ToolPan_Center_Tip:GetWide() + 15, self.ToolPan_Center_Tip:GetTall())
    self.ToolLab_Center_Tip:Center()
    self.ToolPan_Center_Tip:Center()
    self.ToolPan_Center_Tip:AlignBottom(10)
end