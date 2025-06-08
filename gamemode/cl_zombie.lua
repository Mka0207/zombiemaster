--[[
	- Angry Lawyer: April 17, 2007 -
	
	Note about ZombieFlags 
	These are set by adding the following numbers together: 

	0 - Everything 
	1 - Shamblers 
	2 - Banshees 
	4 - Hulks 
	8 - Drifters
	16 - Immolators
	
	Max: 31
]]

local function CanSpawnZombie(flag)
	local allowed = {}
	allowed[1] = false
	allowed[2] = false
	allowed[4] = false
	allowed[8] = false
	allowed[16] = false
	
	if flag == 0 then
		return true
	else
		for i = 1, 5 do
			if (flag - 16) >= 0 then
				flag = flag -16
				allowed[16] = true
			end

			if (flag - 8) >= 0 then
				flag = flag -8
				allowed[8] = true
			end

			if (flag - 4) >= 0 then
				flag = flag -4
				allowed[4] = true
			end

			if (flag - 2) >= 0 then
				flag = flag -2
				allowed[2] = true
			end

			if (flag - 1) >= 0 then
				flag = flag -1
				allowed[1] = true
			end
		end
		
		return allowed
	end
	
	return false
end

local zombieMenus = {}

function GM:GetZombieMenus()
	return zombieMenus
end

function GM:ResetZombieMenus()
	for k, v in pairs(zombieMenus) do
		v:Remove()
	end
	
	zombieMenus = {}
end

local PANEL = {}

AccessorFunc(PANEL, "m_iFlags", 	"Zombieflags", 	FORCE_NUMBER)
AccessorFunc(PANEL, "m_iCurrent", 	"Current", 		FORCE_NUMBER)

function PANEL:Init()
	self:SetSize(400, 300)
	self:SetTitle("Zombie Spawn Menu")
	self:MakePopup()
	
	self.buttons = vgui.Create("DPanelList", self)
	self.buttons:SetPos(4, 28)
	self.buttons:SetSize(105, self:GetTall() - 32)
	self.buttons:SetPadding(2)
	self.buttons:SetSpacing(4)
	
	self.queue = vgui.Create("DPanelList", self)
	self.queue:SetPos(self:GetWide() - 71, 24)
	self.queue:SetSize(70, self:GetTall() - 62)
	self.queue:SetPadding(1)
	self.queue:SetSpacing(1)
	self.queue:EnableHorizontal(true)
	
	self.queue.Paint = function(self)
		local w, h = self:GetSize()
		draw.DrawSimpleRect(1, 0, 1, h, color_black)
	end
	
	self.removeOne = util.simpleButton(self, self:GetWide() - 70, self:GetTall() - 40, 68, 18, "Remove One", false, function()
		if MySelf:IsZM() then
			if #self.queue:GetItems() > 0 then
				self:UpdateQueue()
				RunConsoleCommand("zm_rqueue", self:GetCurrent())
			end
		end
	end)
	
	self.clearQueue = util.simpleButton(self, self:GetWide() - 70, self:GetTall() - 21, 68, 18, "Clear Queue", false, function()
		if MySelf:IsZM() then
			if #self.queue:GetItems() > 0 then
				self.queue:Clear()
				RunConsoleCommand("zm_rqueue", self:GetCurrent(), "1")
			end
		end
	end)

	self.placeRally = util.simpleButton(self, self:GetWide() - 152, self:GetTall() - 21, 81, 18, "Place RallyPoint", false, function()
		if MySelf:IsZM() then
			gamemode.Call("CreateGhostEntity", false, self:GetCurrent())
			self:Close()
		end
	end)
end

function PANEL:Populate()
	local zombieData = GAMEMODE:GetZombieTable()
	
	for k, data in ipairs(zombieData) do
		local buttonBase = vgui.Create("DPanel")
		buttonBase:SetTall(18)
		buttonBase.Paint = function() end
		
		local buttonSingle = util.simpleButton(buttonBase, 0, 0, 75, 18, data.name, false, function()
			RunConsoleCommand("zm_spawnzombie", self:GetCurrent(), data.class, 1)
		end)
		
		buttonSingle.OnCursorEntered = function()
			self.image = vgui.Create("DImage", self)
			self.image:SetImage(data.icon)
			self.image:SetPos(146, 35)
			self.image:SetSize(142, 142)

			self.base = vgui.Create("DPanel", self)
			self.base:SetPos(120, self:GetTall() - 111)
			self.base:SetSize(200, 106)
			self.base.Paint = function() end
			
			self.costLabel = util.simpleLabel(self.base, "Cost: " .. data.cost, color_white, "DefaultBold", 5, 20)
			
			self.desc = util.simpleLabel(self.base, data.description, color_white, "DefaultBold", 5, 40)
			self.desc:DockMargin(5, 40, 8, 0)
			self.desc:Dock(FILL)
			self.desc:SetContentAlignment(7)
			self.desc:SetWrap(true)
		end
		
		buttonSingle.OnCursorExited = function()
			if (self.image) then
				self.image:Remove()
			end
			
			if (self.base) then
				self.base:Remove()
			end
		end

		local buttonFive = util.simpleButton(buttonBase, 0, 0, 25, 18, "x 5", false, function()
			RunConsoleCommand("zm_spawnzombie", self:GetCurrent(), data.class, 5)
		end)
		
		buttonFive:MoveRightOf(buttonSingle)
		
		local zombieFlags = self:GetZombieflags()
		local allowed = CanSpawnZombie(zombieFlags)
		
		if not allowed[data.flag] then
			buttonSingle:SetDisabled(true)
			buttonFive:SetDisabled(true)
		end
		
		buttonFive.OnCursorEntered = buttonSingle.OnCursorEntered
		buttonFive.OnCursorExited  = buttonSingle.OnCursorExited
		
		self.buttons:AddItem(buttonBase)
	end
end

function PANEL:AddQueue(type)
	local data = GAMEMODE:GetZombieData(type)
	local smallImage = "VGUI/zombies/queue_"..string.lower(data.name)
	
	local image = vgui.Create("DImage")
	image:SetImage(smallImage)
	image:SetSize(32, 32)
	
	self.queue:AddItem(image)
end

function PANEL:UpdateQueue()
	local items = self.queue:GetItems()
	self.queue:RemoveItem(table.GetFirstValue(items))
end

function PANEL:Close()
	self:SetVisible(false)
end

function PANEL:Think()
	if self:IsVisible() then
		GAMEMODE:SetDragging(false)
	end
end

vgui.Register("zm_zombiemenu", PANEL, "DFrame")

net.Receive("zm_queue", function(len)
	local type = net.ReadString()
	local id = ents.GetByIndex(net.ReadInt(32))
	local menu = zombieMenus[id]
	
	if menu then
		menu:AddQueue(type)
	end
end)

net.Receive("zm_remove_queue", function(um)
	local id = ents.GetByIndex(net.ReadInt(32))
	local menu = zombieMenus[id]
	
	if menu then
		menu:UpdateQueue()
	end
end)

local PANEL = {}

local image1 = surface.GetTextureID("VGUI/minicrosshair")
local image2 = surface.GetTextureID("VGUI/minishockwave")
local image3 = surface.GetTextureID("VGUI/minigroupadd")
	
function PANEL:Init()
	self.last = nil
	
	self:SetSize(128, 128)
	self:SetPos(ScrW() - 130, ScrH() - 130)
	
	self.list = vgui.Create("DPanelList", self)
	self.list:SetSize(self:GetWide() - 4, self:GetTall() - 37)
	self.list:SetPos(2, 34)
	self.list:SetPadding(4)
	self.list:SetSpacing(8)
	self.list:EnableHorizontal(true)
	self.list.Paint = function() end
	
	self.button1 = vgui.Create("DPanel", self)
	self.button1:SetPos(1, 0)
	self.button1:SetSize(34, 34)
	self.button1.alpha = 100
	
	self.button1.buttons = {}
	
	self.button1.Paint = function(self)
		local w, h = self:GetSize()
		
		draw.DrawSimpleRect(0, 0, w, h, Color(60, 0, 0, self.alpha))
		
		surface.SetDrawColor(255, 255, 255, self.alpha)
		surface.SetTexture(image1)
		surface.DrawTexturedRect(2, 0, 32, 32)
		
		draw.DrawSimpleOutlined(0, 0, w, h -1, color_black)
	end
	
	self.button1.OnMousePressed = function(_self, code)
		if self.last then
			self.last.alpha = 100
		end
		
		_self.alpha = 255
		self.last = _self
		
		self.list:Clear()
		
		for k, v in ipairs(_self.buttons) do
			local button = vgui.Create("DImageButton")
			button:SetSize(32, 32)
			button:SetImage(v.image)
			button:SetToolTip(v.tooltip)
			button.DoClick = function()
				v.func()
			end
			
			self.list:AddItem(button)
		end
	end
	
	self.button2 = vgui.Create("DPanel", self)
	self.button2:SetPos(self:GetWide() /2 - 17, 0)
	self.button2:SetSize(34, 34)
	self.button2.alpha = 100
	
	self.button2.buttons = {
		{image = "VGUI/minieye", func = function() RunConsoleCommand("zm_power_nightvision") end, tooltip = "Toggle Nightvision."},
		{image = "VGUI/minishockwave", func = function() RunConsoleCommand("zm_power_physexplode") end, tooltip = "Create a shockwave which will blast props away (Costs 400)."},
		{image = "VGUI/minideletezombies", func = function() RunConsoleCommand("zm_power_killzombies") end, tooltip = "Remove all selected zombies."},
		{image = "VGUI/minispotcreate", func = function() RunConsoleCommand("zm_power_spotcreate") end, tooltip = "Hidden Summon: Click in the world to create a Shambler. Only works out of sight of the humans (Costs 100)."}
	}
	
	self.button2.Paint = function(self)
		local w, h = self:GetSize()
		
		draw.DrawSimpleRect(0, 0, w, h, Color(60, 0, 0, self.alpha))
		
		surface.SetDrawColor(255, 255, 255, self.alpha)
		surface.SetTexture(image2)
		surface.DrawTexturedRect(2, 1, 30, 30)
		
		draw.DrawSimpleOutlined(0, 0, w, h -1, color_black)
	end
	
	self.button2.OnMousePressed = self.button1.OnMousePressed
	
	self.button3 = vgui.Create("DPanel", self)
	self.button3:SetPos(self:GetWide() - 35, 0)
	self.button3:SetSize(34, 34)
	self.button3.alpha = 100
	
	self.button3.buttons = {
	}
	
	self.button3.Paint = function(self)
		local w, h = self:GetSize()
		
		draw.DrawSimpleRect(0, 0, w, h, Color(60, 0, 0, self.alpha))
		
		surface.SetDrawColor(255, 255, 255, self.alpha)
		surface.SetTexture(image3)
		surface.DrawTexturedRect(2, 0, 32, 32)
		
		draw.DrawSimpleOutlined(0, 0, w, h -1, color_black)
	end
	
	self.button3.OnMousePressed = self.button1.OnMousePressed
end

function PANEL:Paint()
	local w, h = self:GetSize()
	
	draw.DrawSimpleRect(0, 32, w, h - 32, Color(60, 0, 0, 200))
	draw.DrawSimpleOutlined(0, 32, w, h - 32, color_black)
end

vgui.Register("zm_powerpanel", PANEL, "DPanel")