GM.NotifyFadeTime = 8

local PANEL  = {}

local Material = Material
local surface = surface
local surface_SetMaterial = surface.SetMaterial
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local RIGHT = RIGHT
local CENTER = CENTER
local LEFT = LEFT
local color_white =  color_white
local vgui = vgui
local vgui_Create = vgui.Create
local table = table
local table_insert = table.insert
local ipairs = ipairs
local type = type
local draw_GetFontWidth = draw.GetFontWidth
local draw_GetFontHeight = draw.GetFontHeight
local team = team
local team_GetColor = team.GetColor
local TEAM_UNASSIGNED = TEAM_UNASSIGNED
local tostring = tostring
local pairs = pairs
local TOP = TOP
local RealTime = RealTime
local GetPlayerTeam = GetPlayerTeam

function PANEL:Init()
	self:DockPadding(8, 2, 8, 2)
end

local matGrad = Material("VGUI/gradient-r")
function PANEL:Paint()
    if self.bHighlight then
        surface.SetMaterial(matGrad)
        surface.SetDrawColor(95, 0, 0, 125)

        local align = self:GetParent():GetAlign()
        if align == RIGHT then
            surface.DrawTexturedRect(self:GetWide() * 0.25, 0, self:GetWide(), self:GetTall())
        elseif align == CENTER then
            surface.DrawTexturedRect(self:GetWide() * 0.25, 0, self:GetWide() * 0.25, self:GetTall())
            surface.DrawTexturedRectRotated(self:GetWide() * 0.625, self:GetTall() / 2, self:GetWide() * 0.25, self:GetTall(), 180)
        else
            surface.DrawTexturedRectRotated(self:GetWide() * 0.25, self:GetTall() / 2, self:GetWide() / 2, self:GetTall(), 180)
        end
    end
end

function PANEL:AddLabel(text, col, font, extramargin)
	local label = vgui_Create("DLabel", self)
	label:SetText(text)
	label:SetFont(font or "ZMDeathNotify")
	label:SetTextColor(col or color_white)
	label:SizeToContents()
	if extramargin then
		label:SetContentAlignment(7)
		label:DockMargin(0, label:GetTall() * 0.2, 0, 0)
	else
		label:SetContentAlignment(4)
	end
	label:Dock(LEFT)
end

function PANEL:AddImage(mat, col)
	local img = vgui_Create("DImage", self)
	img:SetImage(mat)
	if col then
		img:SetImageColor(col)
	end
	img:SizeToContents()
	local height = img:GetTall()
	if height > self:GetTall() then
		img:SetSize(self:GetTall() / height * img:GetWide(), self:GetTall())
	end
	img:DockMargin(0, (self:GetTall() - img:GetTall()) / 2, 0, 0)
	img:Dock(LEFT)
end

function PANEL:AddKillIcon(class)
	local icondata = killicon.GetIcon(class)
	if icondata then
		local ic = icondata[1]
		if istable(ic) then
			for i=1, #ic do
				self:AddImage(ic[i], icondata[2])
			end
		else
			self:AddImage(ic, icondata[2])
		end
	else
		local fontdata = killicon.GetFont(class) or killicon.GetFont("default")
		if fontdata then
			self:AddLabel(fontdata[2], fontdata[3], fontdata[1], true)
		end
	end
end

function PANEL:SetNotification(...)
	local args = {...}

	local defaultcol = color_white
	local defaultfont
	for k, v in ipairs(args) do
		local vtype = type(v)

		if vtype == "table" then
			if v.r and v.g and v.b then
				defaultcol = v
			elseif v.font then
				if v.font == "" then
					defaultfont = nil
				else
					local th = draw_GetFontHeight(v.font)
					if th then
						defaultfont = v.font
					end
				end
			elseif v.killicon then
				self:AddKillIcon(v.killicon)
				if v.headshot then
					self:AddKillIcon("headshot")
				end
			elseif v.image then
				self:AddImage(v.image, v.color)
            elseif v.highlight then
                self.bHighlight = v.highlight
			end
		elseif vtype == "Player" then
			local avatar = vgui_Create("AvatarImage", self)
			local size = self:GetTall() >= 32 and 32 or 16
			avatar:SetSize(size, size)
			if IsValid(v) then
				if v.IsAltUser then
					avatar:SetSteamID(v:SteamID64(),size)
				else
					avatar:SetPlayer(v, size)
				end
			end
			avatar:SetAlpha(220)
			avatar:Dock(LEFT)
			avatar:DockMargin(0, (self:GetTall() - avatar:GetTall()) / 2, 0, 0)

			if IsValid(v) then
                self:AddLabel(" "..v:Name(), team_GetColor(GetPlayerTeam(v)), "ZMDeathNotify")
			else
				self:AddLabel(" ?", team_GetColor(TEAM_UNASSIGNED), "ZMDeathNotify")
			end
		elseif vtype == "Entity" then
			self:AddLabel("["..(IsValid(v) and v:GetClass() or "?").."]", COLOR_RED, "ZMDeathNotify")
		else
			local text = tostring(v)

			self:AddLabel(text, defaultcol, defaultfont)
		end
	end
end

vgui.Register("DEXNotification", PANEL, "Panel")

local PANEL  = {}

AccessorFunc(PANEL, "m_Align", "Align", FORCE_NUMBER)
AccessorFunc(PANEL, "m_MessageHeight", "MessageHeight", FORCE_NUMBER)

function PANEL:Init()
	self:SetAlign(LEFT)
	self:SetMessageHeight(32)
	self:ParentToHUD()
	self:InvalidateLayout()
end

function PANEL:PerformLayout()
end

function PANEL:Paint()
end

function PANEL:AddNotification(...)
	-- Check if overflow
	local topchild = nil
	local totaly = 0
	local lasty = nil
	local rtime = RealTime()

	for _, p in pairs(self:GetChildren()) do
		if p.DieTime and rtime<p.DieTime then
			if not topchild then -- cache top item.
				topchild = p
			end
			lasty = p:GetTall()
			totaly = totaly+lasty
		end
	end
	
	if topchild then
		if (totaly+lasty)>self:GetTall() then
			-- Kill off top one.
			topchild.DieTime = rtime-1
		end
	end

	local notif = vgui_Create("DEXNotification", self)
	notif:SetTall(BetterScreenScale() * self:GetMessageHeight())
	notif:SetNotification(...)
	local w = 0
	for _, p in pairs(notif:GetChildren()) do
		w = w + p:GetWide()
	end
	if self:GetAlign() == RIGHT then
		notif:DockPadding(self:GetWide() - w - 32, 0, 8, 0)
	elseif self:GetAlign() == CENTER then
		notif:DockPadding((self:GetWide() - w) / 2, 0, 0, 0)
	else
		notif:DockPadding(8, 0, 8, 0)
	end
	
	notif:Dock(TOP)

	notif:SetAlpha(1)
	notif:AlphaTo(255, 0.5)
	notif:AlphaTo(1, 1, GAMEMODE.NotifyFadeTime - 1)

	notif.DieTime = rtime + GAMEMODE.NotifyFadeTime

	return notif
end

function PANEL:Think()
	local rtime = RealTime()

	for i, pan in pairs(self:GetChildren()) do
		if pan.DieTime and rtime >= pan.DieTime then
			pan:Remove()
			local dummy = vgui_Create("Panel", self)
			dummy:SetTall(0)
			dummy:Dock(TOP)
			dummy:Remove()
		end
	end
end

vgui.Register("DEXNotificationsList", PANEL, "Panel")
