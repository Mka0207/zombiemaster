local PANEL = {}

function PANEL:Init()
    self:ParentToHUD()
end

function PANEL:PerformLayout()
    local bZMRHUD = cvars.Number("zm_hudtype", 0) == HUD_ZMR
    if bZMRHUD then
        self:SetSize(ScreenScale(32), ScreenScale(28))
    else
        self:SetSize(ScreenScale(26), ScreenScale(22))
    end
    
    local x, y = ScrW() * 0.865, ScrH() * 0.91
    local wid, hei = ScreenScale(60), ScreenScale(21)
    local wid2, hei2 = self:GetWide(), self:GetTall()
    
    self:SetPos(x + ((wid-wid2) * 0.5), y - hei2 - (bZMRHUD and ScreenScale(4) or 0))
    self:SetSize(wid2, hei2)
end

function PANEL:Think()
    if not MySelf:IsSurvivor() then
        self:Remove()
        return
    end
    
    if self.m_OldCvarNum ~= cvars.Number("zm_hudtype", 0) then
        self.m_OldCvarNum = cvars.Number("zm_hudtype", 0)
        self:InvalidateLayout(true)
    end
    
    if self.CurrentWeapon ~= MySelf:GetActiveWeapon() then
        self.CurrentWeapon = MySelf:GetActiveWeapon()
    end
    
    if self.bShouldDraw then
        if not self.m_bFadeIn then
            self.m_AnimList = nil
            self:AlphaTo(230, 0.2)
        end
        
        self.m_bFadeIn = true
        self.m_bFadeOut = false
    else
        if not self.m_bFadeOut then
            self.m_AnimList = nil
            self:AlphaTo(0, 0.2)
        end
        
        self.m_bFadeIn = false
        self.m_bFadeOut = true
    end
end

local c_background = Color(60, 0, 0, 230)
local c_circlebackground = Color(0, 0, 0, 255)
local c_circle = Color(255, 0, 0, 255)
local ammoBG = Material("zmr_effects/hud_bg_ammo")
function PANEL:Paint(w, h)
    if self:GetAlpha() == 0 then return end
    
    local screenscale = BetterScreenScale()
    local boxsize = 32 * screenscale
    
    if cvars.Number("zm_hudtype", 0) == HUD_ZMR then
        surface.SetDrawColor(70, 0, 0, 150)
        surface.SetMaterial(ammoBG)
        surface.DrawTexturedRect(0, 0, w, h)
    else
        draw.RoundedBox(8, 0, 0, w, h, c_background)
    end
    
    local wep = self.CurrentWeapon
    if wep and wep:IsValid() then
        local x2, y2 = (w/2 - boxsize/2) + 1, (h/2 - boxsize/2)
        local cooldown = wep:GetReloadHUDFinish() - CurTime()
        local cooldownMaximum = wep:GetReloadHUDFinish() - wep:GetReloadHUDStart()

        local frac = math.Clamp(1 - (cooldown / cooldownMaximum), 0, 1)
        local thickness = math.max(3 * screenscale, 1)
        local col = Color((1 - frac) * 255, frac * 255, 0, 255)

        draw.HollowCircle(x2 + (boxsize / 2), y2 + (boxsize / 2), boxsize - (thickness * 2), thickness, 0, 360, c_circlebackground)
        draw.HollowCircle(x2 + (boxsize / 2), y2 + (boxsize / 2), boxsize - (thickness * 2), thickness, 0, 360 * frac, col)
        
        local time = wep:GetReloadTimeHUD()
        if time then
            local font = "zm_hud_font_smaller"
            surface.SetFont(font)
            local tx, ty = surface.GetTextSize(time)
            
            draw.SimpleText(time, font, (w-tx) * 0.5, (h-ty) * 0.5, COLOR_GRAY)
        end
    end
end

vgui.Register("CHudReloadTime", PANEL, "DPanel")