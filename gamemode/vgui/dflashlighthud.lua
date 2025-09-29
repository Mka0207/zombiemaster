local PANEL = {}

local CRITICAL_FLASHLIGHT = 20

function PANEL:Init()
    self:SetPaintBackgroundEnabled(false)
    self:SetColor(Color(255, 255, 255))
    self:SetAlpha(0)
    
    self.m_flLastChange = 0
    self.m_bFadeIn = false
    self.m_bFadeOut = false
    self.m_bLowBattery = false
    
    self.m_OldCvarNum = cvars.Number("zm_hudtype", 0)
    
    self.m_nTexOnId = surface.GetTextureID("zmr_effects/flashlight_on")
    self.m_nTexOffId = surface.GetTextureID("zmr_effects/flashlight_off")
    
    self.m_flBattery = -1
    
    self:ParentToHUD()
end

function PANEL:PerformLayout()
    if cvars.Number("zm_hudtype", 0) == HUD_DEFAULT then
        self.m_flBarWidth = ScreenScale(28)
        self.m_flBarHeight = ScreenScale(2)
        self.m_flBarChunkWidth = ScreenScale(2)
        self.m_flBarChunkGap = ScreenScale(1)
        self.m_flBarInsetX = ScreenScale(4)
        self.m_flBarInsetY = ScreenScale(18)
        self.m_IconX = ScreenScale(4)
        self.m_IconY = ScreenScale(-8)
    
        self:SetSize(ScreenScale(36), ScreenScale(22))
        self:AlignBottom(ScreenScale(11.75))
        self:AlignLeft(ScreenScale(105))
        
        return
    end
    
    self:SetSize(ScrW() * 0.18, ScrH() * 0.075)
    self:AlignBottom(ScreenScale(38))
    self:AlignLeft(ScreenScale(25))
end

local ZMFgColor = Color(255, 255, 255, 255)
local ZMFgColorCrit = Color(200, 0, 0, 255)
function PANEL:Think()
    if not MySelf:IsSurvivor() then
        self:Remove()
        return
    end
    
    if self.m_OldCvarNum ~= cvars.Number("zm_hudtype", 0) then
        self.m_OldCvarNum = cvars.Number("zm_hudtype", 0)
        self:InvalidateLayout(true)
    end
    
    local pPlayer = MySelf
    if not pPlayer:IsValid() then return end
    
    local newbattery = pPlayer:GetFlashlightBattery()
    local ison = pPlayer:FlashlightIsOn()
    
    if ison or not self.bFullBattery then
        if not self.m_bFadeIn then
            self.m_AnimList = nil
            self:AlphaTo(255, 0.2)
        end
        
        self.m_bFadeIn = true
        self.m_bFadeOut = false
        
        if newbattery <= CRITICAL_FLASHLIGHT and not self.m_bLowBattery then
            self.m_bLowBattery = true
            self.m_AnimList = nil
            self:ColorTo(ZMFgColorCrit, 0.2)
        elseif newbattery > CRITICAL_FLASHLIGHT and self.m_bLowBattery then
            self.m_bLowBattery = false
            self.m_AnimList = nil
            self:ColorTo(ZMFgColor, 0.2)
        end
            
        self.m_flLastChange = CurTime()
    elseif ( (CurTime() - self.m_flLastChange) > 1 ) then
        if not self.m_bFadeOut then
            self.m_AnimList = nil
            self:AlphaTo(0, 0.5)
        end
        
        self.m_bFadeIn = false
        self.m_bFadeOut = true
    end
    
    self.m_flBattery = newbattery
    self.m_bIsOn = ison
end

function PANEL:SetColor(c)
    self.m_Color = c
end

function PANEL:GetColor()
    return self.m_Color
end

local m_BgColor = Color(64, 64, 64, 255)
function PANEL:Paint()
    if self:GetAlpha() <= 0 then return end
    
    if cvars.Number("zm_hudtype", 0) == HUD_DEFAULT then
        self:PaintDefault()
        return
    end

    local tex = self.m_bIsOn and self.m_nTexOnId or self.m_nTexOffId

    local size_y = self:GetTall()
    local size_x = size_y * 2

    surface.SetDrawColor(m_BgColor:Unpack())
    surface.SetTexture(tex)
    surface.DrawTexturedRect(0, 0, size_x, size_y)

    local battery = math.min(self.m_flBattery, 100)
    
    self.bFullBattery = (battery == 100)

    if battery <= 0 then return end

    local fill_x = math.Round(size_x * (battery / 100))
    local frac = fill_x / size_x
    
    surface.SetDrawColor(self:GetColor():Unpack())
    surface.SetTexture(tex)
    surface.DrawTexturedRectUV(0, 0, fill_x, size_y, 0, 0, frac, 1)
end

local m_clrNormal = Color(255, 255, 255, 255)
local m_clrCaution = Color(255, 48, 0, 255)
local m_clrBackground = Color(60, 0, 0, 200)
local WCHAR_FLASHLIGHT_ON = "©"
local WCHAR_FLASHLIGHT_OFF = "®"
function PANEL:PaintDefault()
	local bIsOn = self.m_bIsOn

	local chunkCount = math.floor(self.m_flBarWidth / (self.m_flBarChunkWidth + self.m_flBarChunkGap))
	local enabledChunks = math.floor((chunkCount * (self.m_flBattery * 1.0/100.0) + 0.5))

	local clrFlashlight = ( enabledChunks < ( chunkCount / 4 ) ) and m_clrCaution or m_clrNormal
	clrFlashlight.a = (bIsOn and 255 or 32) * (self:GetAlpha() / 255)
    m_clrBackground.a = 200 * (bIsOn and 1 or 0.625)
    
    draw.RoundedBox(8, 0, 0, self:GetWide(), self:GetTall(), m_clrBackground)

	local pState = bIsOn and WCHAR_FLASHLIGHT_ON or WCHAR_FLASHLIGHT_OFF
    
    self.bFullBattery = (enabledChunks == chunkCount)

	surface.SetFont("WeaponIconsSmall")
    surface.SetTextColor(clrFlashlight:Unpack())
    surface.SetTextPos(self.m_IconX, self.m_IconY)
    surface.DrawText(pState)

    surface.SetDrawColor(clrFlashlight:Unpack())
	local xpos, ypos = self.m_flBarInsetX, self.m_flBarInsetY
    for i=0, enabledChunks-1 do
		surface.DrawRect(xpos, ypos, self.m_flBarChunkWidth, self.m_flBarHeight)
		xpos = xpos + (self.m_flBarChunkWidth + self.m_flBarChunkGap)
	end
	
	clrFlashlight.a = clrFlashlight.a / 8

	surface.SetDrawColor(clrFlashlight:Unpack())
	for i=enabledChunks, chunkCount-1 do
		surface.DrawRect(xpos, ypos, self.m_flBarChunkWidth, self.m_flBarHeight)
		xpos = xpos + (self.m_flBarChunkWidth + self.m_flBarChunkGap)
	end
end

vgui.Register("CHudFlashlight", PANEL, "DPanel")