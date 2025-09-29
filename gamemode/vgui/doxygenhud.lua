local PANEL = {}

local CRITICAL_OXYGEN = 20

function PANEL:Init()
    self:SetPaintBackgroundEnabled(false)
    self:SetColor(Color(255, 255, 255))
    self:SetAlpha(0)
    
    self.m_flLastChange = 0
    self.m_bFadeIn = false
    self.m_bFadeOut = false
    self.m_bLowOxygen = false
    
    self.m_OldCvarNum = cvars.Number("zm_hudtype", 0)
    
    self.m_flOxygen = -1
    
    self:ParentToHUD()
end

function PANEL:PerformLayout()
    self.m_flBarWidth = ScreenScale(28)
    self.m_flBarHeight = ScreenScale(2)
    self.m_flBarChunkWidth = ScreenScale(2)
    self.m_flBarChunkGap = ScreenScale(1)
    self.m_SubScriptX = ScreenScale(0.75)

    if self.m_OldCvarNum == HUD_DEFAULT then
        self.m_flBarInsetX = ScreenScale(4)
        self.m_flBarInsetY = ScreenScale(18)
        self.m_IconX = ScreenScale(11)
        self.m_IconY = ScreenScale(2)
    
        self:SetSize(ScreenScale(36), ScreenScale(22))
        
        if IsValid(GAMEMODE.FlashlightHUD) and GAMEMODE.FlashlightHUD:GetAlpha() ~= 0 then
            self.bAlignedLeft = false
            self.bAlignedFlashlight = true
            self:AlignLeft(ScreenScale(147.5))
        else
            self.bAlignedFlashlight = false
            self.bAlignedLeft = true
            self:AlignLeft(ScreenScale(105))
        end
        
        self:AlignBottom(ScreenScale(11.75))
    else
        self.m_flBarInsetX = ScreenScale(8)
        self.m_flBarInsetY = ScreenScale(22)
        self.m_IconX = ScreenScale(15)
        self.m_IconY = ScreenScale(6)

        self:SetSize(ScreenScale(44), ScreenScale(30))
        self:AlignLeft(ScreenScale(115))
        self:AlignBottom(ScreenScale(7.75))
    end
end

local m_clrNormal = Color(255, 255, 255, 255)
local m_clrCaution = Color(255, 48, 0, 255)
function PANEL:Think()
    if not MySelf:IsSurvivor() then
        self:Remove()
        return
    end

    local pPlayer = MySelf
    if not pPlayer:IsValid() then return end
    
    if self.m_OldCvarNum ~= cvars.Number("zm_hudtype", 0) then
        self.m_OldCvarNum = cvars.Number("zm_hudtype", 0)
        self:InvalidateLayout(true)
    end
    
    if self.m_OldCvarNum == HUD_DEFAULT and ((not self.bAlignedFlashlight and IsValid(GAMEMODE.FlashlightHUD) and GAMEMODE.FlashlightHUD:GetAlpha() ~= 0) or not self.bAlignedLeft) then
        self:InvalidateLayout()
    end
    
    local newoxygen = pPlayer:GetOxygenLevel()
    local underwater = pPlayer:WaterLevel() >= 3
    
    if underwater or not self.bFullOxygen then
        if not self.m_bFadeIn then
            self.m_AnimList = nil
            self:AlphaTo(255, 0.2)
        end
        
        self.m_bFadeIn = true
        self.m_bFadeOut = false
        
        if self.m_bOxygenCritical and not self.m_bLowOxygen then
            self.m_bLowOxygen = true
            self.m_AnimList = nil
            self:ColorTo(m_clrCaution, 0.2)
        elseif not self.m_bOxygenCritical and self.m_bLowOxygen then
            self.m_bLowOxygen = false
            self.m_AnimList = nil
            self:ColorTo(m_clrNormal, 0.2)
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
    
    self.m_flOxygen = newoxygen
    self.m_bUnderwater = underwater
end

function PANEL:SetColor(c)
    self.m_Color = c
end

function PANEL:GetColor()
    return self.m_Color
end

local m_clrBackground = Color(60, 0, 0, 200)
function PANEL:Paint(w, h)
    if self:GetAlpha() <= 0 then return end
    
	local bUnderwater = self.m_bUnderwater

	local chunkCount = math.floor(self.m_flBarWidth / (self.m_flBarChunkWidth + self.m_flBarChunkGap))
	local enabledChunks = math.floor((chunkCount * (self.m_flOxygen * 1.0/100.0) + 0.5))

    local bCritical = enabledChunks < ( chunkCount / 4 )
    self.m_bOxygenCritical = bCritical
    
	local clrOxygen = self:GetColor()
	clrOxygen.a = (bUnderwater and 255 or (self.m_OldCvarNum == HUD_DEFAULT and 32 or 64)) * (self:GetAlpha() / 255)
    m_clrBackground.a = 200 * (bUnderwater and 1 or 0.625)
    
    if self.m_OldCvarNum == HUD_DEFAULT then
        draw.RoundedBox(8, 0, 0, w, h, m_clrBackground)
    elseif IsValid(GAMEMODE.HumanHealthHUD) then
        surface.SetDrawColor(GAMEMODE.HumanHealthHUD:GetBackgroundColor())
        surface.SetMaterial(GAMEMODE.HumanHealthHUD:GetBackgroundImage())
        surface.DrawTexturedRect(0, 0, w, h)
    end

    self.bFullOxygen = (enabledChunks == chunkCount)

	surface.SetFont("zm_hud_font_normal_scan")
    surface.SetTextColor(clrOxygen:Unpack())
    surface.SetTextPos(self.m_IconX, self.m_IconY)
    surface.DrawText("O")
    
    local wid, hei = surface.GetTextSize("O")
	surface.SetFont("zm_hud_font_small_scan")
    surface.SetTextColor(clrOxygen:Unpack())
    surface.SetTextPos(self.m_IconX + wid + self.m_SubScriptX, self.m_IconY)
    surface.DrawText("2")

    surface.SetDrawColor(clrOxygen:Unpack())
	local xpos, ypos = self.m_flBarInsetX, self.m_flBarInsetY
    for i=0, enabledChunks-1 do
		surface.DrawRect(xpos, ypos, self.m_flBarChunkWidth, self.m_flBarHeight)
		xpos = xpos + (self.m_flBarChunkWidth + self.m_flBarChunkGap)
	end
	
	clrOxygen.a = clrOxygen.a / 8

	surface.SetDrawColor(clrOxygen:Unpack())
	for i=enabledChunks, chunkCount-1 do
		surface.DrawRect(xpos, ypos, self.m_flBarChunkWidth, self.m_flBarHeight)
		xpos = xpos + (self.m_flBarChunkWidth + self.m_flBarChunkGap)
	end
end

vgui.Register("CHudOxygen", PANEL, "DPanel")