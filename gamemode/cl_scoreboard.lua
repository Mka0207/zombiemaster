local PANEL = {}
local RemortColors = {
	[19] = COLOR_RUST,
	[18] = COLOR_TURQ,
	[17] = COLOR_CERISE,
	[16] = COLOR_LVIOLET,
	[15] = COLOR_SLATEBLUE,
	[14] = COLOR_SEAGREEN,
	[13] = COLOR_GLIME,
	[12] = COLOR_LEMONLIME,
	[11] = COLOR_BRASS,
	[10] = COLOR_SALMON,
	[9] = COLOR_TAN,
	[8] = COLOR_BROWN,
	[7] = COLOR_RPINK,
	[6] = COLOR_RPURPLE,
	[5] = COLOR_CYAN,
	[4] = COLOR_GREEN,
	[3] = COLOR_YELLOW,
	[2] = COLOR_RORANGE,
	[1] = COLOR_RED
}


local function BetterScreenScale()
	return math.Clamp(ScrH() / 1080, 0.6, 1)
end


function PANEL:Init()
    self:Dock(TOP)
    self:DockPadding(3, 3, 3, 3)
    self:SetHeight(48)
    self:DockMargin(2, 0, 2, 2)

    self.Avatar = self:Add("DClickableAvatar")
    self.Avatar:AlignLeft(18)
    self.Avatar:SetSize(44, 44)

    self.Avatar:CenterVertical()
    self.Avatar.DoClick = function() self.Player:ShowProfile() end

    self.SpecialImage = self:Add("DImage")
    self.SpecialImage:SetSize(16, 16)
    self.SpecialImage:SetMouseInputEnabled(true)
    self.SpecialImage:CenterVertical(0.5)

    self.Name = self:Add("DLabel")
    self.Name:Dock(FILL)
    self.Name:SetFont("ZMScoreBoardPlayerBold")
    self.Name:DockMargin(72, 0, 0, 0)
    self.Name:SetColor(color_white)

    self.Mute = self:Add("DImageButton")
    self.Mute:SetSize(32, 32)
    self.Mute:Dock(RIGHT)

    self.Ping = self:Add("DLabel")
    self.Ping:Dock(RIGHT)
    self.Ping:DockMargin(0, 0, 18, 0)
    self.Ping:SetWidth(50)
    self.Ping:SetFont("ZMScoreBoardPlayerSmallBold")
    self.Ping:SetContentAlignment(5)

    self.Deaths = self:Add("DLabel")
    self.Deaths:Dock(RIGHT)
    self.Deaths:DockMargin(0, 0, 18, 0)
    self.Deaths:SetWidth(50)
    self.Deaths:SetFont("ZMScoreBoardPlayerSmallBold")
    self.Deaths:SetContentAlignment(5)

    self.Kills = self:Add("DLabel")
    self.Kills:Dock(RIGHT)
    self.Kills:DockMargin(0, 0, 26, 0)
    self.Kills:SetWidth(50)
    self.Kills:SetFont("ZMScoreBoardPlayerSmallBold")
    self.Kills:SetContentAlignment(5)

    self.Remorts = self:Add("DLabel")
    self.Remorts:Dock(RIGHT)
    self.Remorts:DockMargin(0, 0, 15, 0)
    self.Remorts:SetWidth(50)
    self.Remorts:SetFont("ZMScoreBoardPlayerSmallBold")
    self.Remorts:SetContentAlignment(5)
end

function PANEL:Setup(pl)
    self.m_Flash = pl:SteamID() == "STEAM_0:1:3307510" or pl:IsAdmin() or pl:IsSuperAdmin()
    self.Player = pl
    self.Avatar:SetPlayer(pl, 64)
    self.Ping:SetPlayer(pl)
    self:Think(self)

    if hook.Call("IsSpecialPerson", GAMEMODE, pl, self.SpecialImage) then
        self.SpecialImage:SetVisible(true)
    else
        self.SpecialImage:SetTooltip()
        self.SpecialImage:SetVisible(false)
    end
end

function PANEL:RefreshCosmetics(pl)
    local banner = pl.GetScoreboardBannerItem and pl:GetScoreboardBannerItem()
    if banner and not self.BannerMaterial then
        self.BannerMaterial = Material(banner.material_path)
    end
end

PANEL.NextBannerRefresh = 0
function PANEL:Think()
    if not IsValid(self.Player) then
        self:SetZPos( 9999 ) -- Causes a rebuild
        self:Remove()
        return
    end

    if RealTime() >= self.NextBannerRefresh then
        self.NextBannerRefresh = RealTime() + 3

        self:RefreshCosmetics(self.Player)
    end

    if self.PName == nil or self.PName ~= self.Player:Nick() then
        self.PName = self.Player:Nick()
        self.Name:SetText(self.PName)
    end

    if self.NumKills == nil or self.NumKills ~= self.Player:Frags() then
        self.NumKills = self.Player:Frags()
        self.Kills:SetText(self.NumKills)
    end

    if self.NumRemorts == nil or self.NumRemorts ~= self.Player:GetZMRemortLevel() then
        self.NumRemorts = self.Player:GetZMRemortLevel()
        self.Remorts:SetText(self.NumRemorts)

        local rlvlmod = math.floor((self.NumRemorts % 80) / 4)
        local hcolor, hlvl = COLOR_GRAY, 0
        for rlvlr, rcolor in pairs(RemortColors) do
            if rlvlmod >= rlvlr and rlvlr >= hlvl then
                hlvl = rlvlr
                hcolor = rcolor
            end
        end
        self.Remorts:SetColor(hcolor)
        self.Remorts:SetAlpha(240)
    end

    if self.NumDeaths == nil or self.NumDeaths ~= self.Player:Deaths() then
        self.NumDeaths = self.Player:Deaths()
        self.Deaths:SetText( self.NumDeaths )
    end

    if self.NumPing == nil or self.NumPing ~= self.Player:Ping() then
        self.NumPing = self.Player:IsBot() and "Bot" or self.Player:Ping()
        self.Ping:SetText( self.NumPing )

        if not self.Player:IsBot() then
            local ping = self.NumPing
            local pingmul = 1 - math.Clamp((ping - 50) / 200, 0, 1)

            local colPing = Color((1 - pingmul) * 255, pingmul * 255, 60, 255)
            self.Ping:SetTextColor(colPing)
        end
    end

    if self.Muted == nil or self.Muted ~= self.Player:IsMuted() then
        self.Muted = self.Player:IsMuted()
        if self.Player ~= MySelf then
            self.Mute:SetImage(self.Muted and "icon32/muted.png" or "icon32/unmuted.png")
        else
            if self.Mute:IsEnabled() then
                self.Mute:SetCursor("arrow")
                self.Mute:SetEnabled(false)
            end
        end

        self.Mute:SetColor(self.Muted and Color(255, 0, 0) or color_black)
        self.Mute.DoClick = function() self.Player:SetMuted(not self.Muted) end
    end

    if g_Scoreboard.PlayerList:GetVBar():IsVisible() then
        local left, top, right, bottom = self.Ping:GetDockMargin()
        if right == 18 then
            self.Ping:DockMargin(0, 0, 4, 0)
        end
    else
        local left, top, right, bottom = self.Ping:GetDockMargin()
        if right == 4 then
            self.Ping:DockMargin(0, 0, 18, 0)
        end
    end

    if self.Player:Team() ~= self._LastTeam then
        if not IsValid(g_Scoreboard) then return end

        g_Scoreboard.SurvivorsList:InvalidateLayout()
        g_Scoreboard.ZombieMasterList:InvalidateLayout()
        g_Scoreboard.SpectatorsList:InvalidateLayout()

        self._LastTeam = self.Player:Team()
        self:SetParent(self._LastTeam == TEAM_SURVIVOR and g_Scoreboard.SurvivorsList or self._LastTeam == TEAM_ZOMBIEMASTER and g_Scoreboard.ZombieMasterList or g_Scoreboard.SpectatorsList)
        self:SetZPos(9999)
    end

    self:SetZPos((self.NumKills * -50) + self.NumDeaths + self.Player:EntIndex())
end

local colTemp = Color(255, 255, 255, 220)
function PANEL:Paint(w, h)
    local col = Color(0, 0, 0, 180)
    local mul = 0.5
    local pl = self.Player
    if pl:IsValid() then
        col = team.GetColor(pl:Team())

        if self.m_Flash then
            mul = 0.6 + math.abs(math.sin(RealTime() * 4)) * 0.4
        elseif pl == MySelf then
            mul = 0.6 + math.abs(math.sin(RealTime() * 2)) * 0.4
        end

        colTemp = team.GetColor(pl:Team())

        colTemp.r = col.r * mul
        colTemp.g = col.g * mul
        colTemp.b = col.b * mul
    end

    local col = colTemp
    col.a = 85

    if not self.BannerMaterial then
        surface.SetDrawColor(col)

        surface.DrawRect(0, 0, w, h)
    else
        surface.SetDrawColor(255, 255, 255, 200)
        surface.SetMaterial(self.BannerMaterial)

        surface.DrawTexturedRect(0, 0, w, h)
    end


    return true
end

vgui.Register("ZMPlayerLine", PANEL, "DPanel")

local PANEL = {}

function PANEL:Init()
    self.Sprite = vgui.Create("DImage", self)
    self.Sprite:AlignTop(-5)
    self.Sprite:AlignLeft(5)
    self.Sprite:SetSize(ScrW() * 0.07, ScrH() * 0.07)
    self.Sprite:SetImage("vgui/gfx/vgui/hl2mp_logo")

    self.Header = self:Add("Panel")
    self.Header:Dock(TOP)
    self.Header:SetHeight(100)

    self.HeaderBottom = self:Add("Panel")
    self.HeaderBottom:Dock(BOTTOM)
    self.HeaderBottom:DockMargin(8, 0, 0, 4)
    self.HeaderBottom:SetHeight(32)
    self.HeaderBottom:SetWide(self:GetWide())

    self.Name = self.Header:Add( "DLabel" )
    self.Name:SetFont("ZMScoreBoardTitle")
    self.Name:SetTextColor(COLOR_GRAY)
    self.Name:Dock(TOP)
    self.Name:SetHeight(40)
    self.Name:SetContentAlignment(5)

    self.RoundsLeft = self.Header:Add( "DLabel" )
    self.RoundsLeft:SetFont("ZMScoreBoardTitleSub")
    self.RoundsLeft:SetTextColor(COLOR_GRAY)
    self.RoundsLeft:Dock(TOP)
    self.RoundsLeft:DockMargin(0, -12, 0, 0)
    self.RoundsLeft:SetHeight(40)
    self.RoundsLeft:SetContentAlignment(5)

    self.CreditsButton = self.HeaderBottom:Add("DButton")
    self.CreditsButton:Dock(LEFT)
    self.CreditsButton:SetText(translate.Get("button_credits"))
    self.CreditsButton.DoClick = function(but)
        if IsValid(self.CreditsPanel) then return end
        self.CreditsPanel = MakepCredits()
    end

    self.CreatorLabel = self.HeaderBottom:Add("DLabel")
    self.CreatorLabel:Dock(LEFT)
    self.CreatorLabel:DockMargin(12, 0, 0, 0)
    self.CreatorLabel:SetFont("ZMScoreBoardTitleSub")
    self.CreatorLabel:SetText(translate.Get("credit_text"))
    self.CreatorLabel:CenterVertical()
    self.CreatorLabel:SizeToContents()

    self.MapLabel = self.HeaderBottom:Add("DLabel")
    self.MapLabel:Dock(RIGHT)
    self.MapLabel:DockMargin(0, 0, 12, 0)
    self.MapLabel:SetFont("ZMScoreBoardHeading")
    self.MapLabel:SetText(translate.Get("current_map") .. " " .. game.GetMap())
    self.MapLabel:CenterVertical()
    self.MapLabel:SizeToContents()
    self.MapLabel:SetColor(color_white)

    self.HeadersPan = self:Add("Panel")
    self.HeadersPan:SetPos(0, 64)

    self.NameCol = self.HeadersPan:Add("DLabel")
    self.NameCol:Dock(LEFT)
    self.NameCol:SetFont("ZMScoreBoardPlayer")
    self.NameCol:DockMargin(85, 0, 0, 0)
    self.NameCol:SetColor(color_white)
    self.NameCol:SetText(translate.Get("scoreboard_name"))

    self.PingCol = self.HeadersPan:Add("DLabel")
    self.PingCol:Dock(RIGHT)
    self.PingCol:DockMargin(0, 0, 35, 0)
    self.PingCol:SetFont("ZMScoreBoardPlayer")
    self.PingCol:SetColor(color_white)
    self.PingCol:SetText(translate.Get("scoreboard_ping"))

    self.DeathsCol = self.HeadersPan:Add("DLabel")
    self.DeathsCol:Dock(RIGHT)
    self.DeathsCol:DockMargin(0, 0, 15, 0)
    self.DeathsCol:SetFont("ZMScoreBoardPlayer")
    self.DeathsCol:SetColor(color_white)
    self.DeathsCol:SetText(translate.Get("scoreboard_deaths"))

    self.KillsCol = self.HeadersPan:Add("DLabel")
    self.KillsCol:Dock(RIGHT)
    self.KillsCol:SetFont("ZMScoreBoardPlayer")
    self.KillsCol:SetColor(color_white)
    self.KillsCol:SetText(translate.Get("scoreboard_kills"))

    self.RemortsCol = self.HeadersPan:Add("DLabel")
    self.RemortsCol:Dock(RIGHT)
    self.RemortsCol:SetFont("ZMScoreBoardPlayer")
    self.RemortsCol:SetColor(color_white)
    self.RemortsCol:SetText("R.LVL")

    self.PlayerList = self:Add("DScrollPanel")
    self.PlayerList:SetPos(0, 84)

    self.m_ZombieHeading = self.PlayerList:Add("DTeamHeading")
    self.m_ZombieHeading:Dock(TOP)
    self.m_ZombieHeading:SetTeam(TEAM_ZOMBIEMASTER)

    self.ZombieMasterList = self.PlayerList:Add("Panel")
    self.ZombieMasterList:Dock(TOP)
    self.ZombieMasterList:DockMargin(0, 0, 0, 4)

    self.m_HumanHeading = self.PlayerList:Add("DTeamHeading")
    self.m_HumanHeading:Dock(TOP)
    self.m_HumanHeading:SetTeam(TEAM_SURVIVOR)

    self.SurvivorsList = self.PlayerList:Add("Panel")
    self.SurvivorsList:Dock(TOP)
    self.SurvivorsList:DockMargin(0, 0, 0, 4)

    self.m_SpectatorHeading = self.PlayerList:Add("DTeamHeading")
    self.m_SpectatorHeading:Dock(TOP)
    self.m_SpectatorHeading:SetTeam(TEAM_SPECTATOR)

    self.SpectatorsList = self.PlayerList:Add("Panel")
    self.SpectatorsList:Dock(TOP)
    self.SpectatorsList:DockMargin(0, 0, 0, 4)
end

function PANEL:PerformLayout()
    self.PlayerList:SetSize(self:GetWide(), self:GetTall() * 0.87)
    self.HeadersPan:SetSize(self:GetWide(), 20)

    self.SurvivorsList:SetWide(self:GetWide())
    self.ZombieMasterList:SetWide(self:GetWide())
    self.SpectatorsList:SetWide(self:GetWide())

    self.m_HumanHeading:MoveAbove(self.SurvivorsList, 5)
    self.m_HumanHeading:SetWide(self:GetWide())
    self.SurvivorsList:MoveBelow(self.m_HumanHeading, 5)

    self.m_ZombieHeading:MoveAbove(self.ZombieMasterList, 5)
    self.m_ZombieHeading:SetWide(self:GetWide())
    self.ZombieMasterList:MoveBelow(self.m_ZombieHeading, 5)

    self.m_SpectatorHeading:MoveAbove(self.SpectatorsList, 5)
    self.m_SpectatorHeading:SetWide(self:GetWide())
    self.SpectatorsList:MoveBelow(self.m_SpectatorHeading, 5)
end

function PANEL:Paint(w, h)
    draw.RoundedBoxEx(8, 0, 64, w, h - 64, Color(5, 5, 5, 180), false, false, true, true)
    draw.RoundedBoxEx(8, 0, 0, w, 64, Color(5, 5, 5, 220), true, true, false, false)
end

function PANEL:Think()
    self.Name:SetText(GetHostName())

    local maxrounds = GetConVar("zm_roundlimit"):GetInt()
    local roundsleft = GAMEMODE:GetRoundsPlayed()
    local roundcount = maxrounds - roundsleft
    if roundcount > 0 then
        if roundcount == 1 then
            self.RoundsLeft:SetText(translate.Format("x_round_left", roundcount))
        else
            self.RoundsLeft:SetText(translate.Format("x_rounds_left", roundcount))
        end
    elseif roundcount == 0 then
        self.RoundsLeft:SetText(translate.Get("final_round"))
    else
        self.RoundsLeft:SetText(translate.Get("changing_map"))
    end

    if roundcount <= math.floor(maxrounds * 0.25) then
        self.RoundsLeft:SetTextColor(Color(255, 0, 0))
    elseif roundcount <= math.floor(maxrounds * 0.5) then
        self.RoundsLeft:SetTextColor(Color(255, 255, 0))
    else
        self.RoundsLeft:SetTextColor(Color(0, 255, 0))
    end

    for id, pl in ipairs(player.GetAllNoCopy()) do
        if IsValid(pl.ScoreEntry) then continue end

        pl.ScoreEntry = vgui.Create("ZMPlayerLine")
        pl.ScoreEntry:Setup(pl)
        pl.ScoreEntry:Dock(TOP)
        pl.ScoreEntry:DockMargin(8, 2, 8, 2)

        if pl:IsSurvivor() then
            self.SurvivorsList:Add(pl.ScoreEntry)
        elseif pl:IsZM() then
            self.ZombieMasterList:Add(pl.ScoreEntry)
        else
            self.SpectatorsList:Add(pl.ScoreEntry)
        end
    end

    if IsValid(self.SurvivorsList) then self.SurvivorsList:SizeToChildren(false, true) end
    if IsValid(self.ZombieMasterList) then self.ZombieMasterList:SizeToChildren(false, true) end
    if IsValid(self.SpectatorsList) then self.SpectatorsList:SizeToChildren(false, true) end
end

vgui.Register("ZMScoreBoard", PANEL, "EditablePanel")

function GM:ScoreboardShow()
    if not IsValid(g_Scoreboard) then
        g_Scoreboard = vgui.Create("ZMScoreBoard")
        g_Scoreboard:MakePopup()
    end

    if IsValid(g_Scoreboard) then
        g_Scoreboard:SetSize(math.min(ScrW(), ScrH()) - 5, ScrH() * 0.9)
        g_Scoreboard:AlignTop(ScrH() * 0.05)
        g_Scoreboard:CenterHorizontal()
        g_Scoreboard:SetAlpha(0)
        g_Scoreboard:AlphaTo(255, 0.5, 0)
        g_Scoreboard:SetVisible(true)
    end
end

function GM:ScoreboardHide()
    if IsValid(g_Scoreboard) then
        if IsValid(g_Scoreboard.CreditsPanel) then
            g_Scoreboard.CreditsPanel:Close()
        end
        g_Scoreboard:Hide()
    end
end

function GM:HUDDrawScoreBoard()
end