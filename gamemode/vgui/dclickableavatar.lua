local PANEL = {}

--shamelessly copied from ZS's implementation
function PANEL:PerformLayout()
	if self.Avatar then
		local avatar = self.Avatar
		local img = self.Image
		local size = self:GetSize()
		local shrink_pct = img and 1 or 1
		if avatar then
			avatar:SetSize(shrink_pct * size, shrink_pct * size)
			avatar:Center()
		end
		if img then
			img:NoClipping(true)
			img:SetSize(size * 1.125, size * 1.125)
			img:Center()
		end
	end
end

local function CreateImage(self, img)
	local image = vgui.Create("DImage", self)
	image:SetImage(img)
	image:SetVisible(false)
	image:SetSize(self:GetSize(), self:GetSize())
	image:SetMouseInputEnabled(false)
	image:SetZPos(1)

	return image
end

function PANEL:SetImage(img)
	local image = self.Image
	if not image then
		image = CreateImage(self, img)
		self.Image = image
	else
		image:SetImage(img)
	end

	image:SetVisible(true)

	return image
end

local function DetermineResolution(size)
	local num = 32

	while num <= 128 do
		if size <= num then return num end

		num = num * 2
	end

	return 128
end

function PANEL:RefreshBanner(pl)
	if pl.GetAvatarFrameItem then
		local frame = pl:GetAvatarFrameItem()
		if frame then
			self:SetImage(frame.material_path)
		end
	end
end

function PANEL:SetPlayer(pl, size)
	local avatar

	if pl.GetAvatarFrameItem then
		local frame = pl:GetAvatarFrameItem()
		if frame then
			self:SetImage(frame.material_path)
		end
	end

	if not self.Avatar then
		avatar = vgui.Create("AvatarImage", self)
		self.Avatar = avatar
		avatar:SetVisible(false)
		avatar:SetPlayer(pl, size or DetermineResolution(self:GetSize()))
		avatar:SetMouseInputEnabled(false)
		avatar:SetZPos(0)
	end

	avatar = self.Avatar
	avatar:SetVisible(true)
end

function PANEL:OnMousePressed(code)
    if code == MOUSE_FIRST then
        self:DoClick()
    end
end

function PANEL:SetEnabled(b)
    if not b then
        self:SetMouseInputEnabled(false)
        self:SetKeyboardInputEnabled(false)
        self:SetCursor("none")
    else
        self:SetMouseInputEnabled(true)
        self:SetKeyboardInputEnabled(true)
        self:SetCursor("hand")
    end
end

function PANEL:DoClick()
end

vgui.Register("DClickableAvatar", PANEL, "AvatarImage")