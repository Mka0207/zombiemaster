AddCSLuaFile()
DEFINE_BASECLASS("player_basezm")

local PLAYER = {}

function PLAYER:Spawn()
    BaseClass.Spawn(self)

    self.Player:KillSilent()
    self.Player:Spectate(OBS_MODE_ROAMING)
    self.Player:SetMoveType(MOVETYPE_NOCLIP)

    self.Player:SendLua([[
        if cvars.Bool("zm_cl_enablehints") and IsValid(GAMEMODE.ZM_Center_Hints) then
            GAMEMODE.ZM_Center_Hints:SetHint(translate.Get("zm_hint_intro"))
            GAMEMODE.ZM_Center_Hints:SetActive(true, 3)

            timer.Simple(9, function()
                if not IsValid(GAMEMODE.ZM_Center_Hints) then return end

                GAMEMODE.ZM_Center_Hints:SetHint(translate.Format("zm_hint_movement", input.LookupBinding("+speed", true)))
                GAMEMODE.ZM_Center_Hints:SetActive(true, 3)

                timer.Simple(9, function()
                    if not IsValid(GAMEMODE.ZM_Center_Hints) then return end

                    GAMEMODE.ZM_Center_Hints:SetHint(translate.Format("zm_hint_vision", input.LookupBinding("impulse 100", true)))
                    GAMEMODE.ZM_Center_Hints:SetActive(true, 3)
                end)
            end)
        end
    ]])

    self.Player.m_nLastMouseUpdate = 0
    self.Player:SetZMPointIncome(GetConVar("zm_resource_refill_min"):GetInt())
end

function PLAYER:SetupMove(mv, cmd)
    if cmd:GetMouseWheel() ~= 0 then
        mv:SetOrigin(mv:GetOrigin() + Vector(0, 0, (cmd:GetMouseWheel() * self.Player:GetInfo("zm_cl_scrollspeed"))))
    end

    if CLIENT then
        if not hook.Call("IsMenuOpen", GAMEMODE) and (input.WasMousePressed(MOUSE_WHEEL_UP) or input.WasMousePressed(MOUSE_WHEEL_DOWN)) and vgui.CursorVisible() then
            RememberCursorPosition()
            gui.EnableScreenClicker(false, true)

            timer.Simple(0, function()
                gui.EnableScreenClicker(true, true)
                RestoreCursorPosition()
            end)
        end
    end
end

function PLAYER:CreateMove(cmd)
    if not isDragging and vgui.CursorVisible() then
        if system.IsWindows() and not system.HasFocus() then return end

        local menuopen = hook.Call("IsMenuOpen", GAMEMODE)
        if not menuopen then
            local mousex, mousey = gui.MousePos()
            local viewangle = cmd:GetViewAngles()
            local bSetViewAng = false

            if mousex <= SCROLL_THRESHOLD then
                viewangle.y = viewangle.y + ((RealFrameTime() * cvars.Number("cl_pitchspeed", 0)) * 0.5)
                bSetViewAng = true
            elseif mousex >= (ScrW() - SCROLL_THRESHOLD) then
                viewangle.y = viewangle.y - ((RealFrameTime() * cvars.Number("cl_pitchspeed", 0)) * 0.5)
                bSetViewAng = true
            end

            if mousey <= SCROLL_THRESHOLD then
                viewangle.p = viewangle.p - ((RealFrameTime() * cvars.Number("cl_pitchspeed", 0)) * 0.5)
                bSetViewAng = true
            elseif mousey >= (ScrH() - SCROLL_THRESHOLD) then
                viewangle.p = viewangle.p + ((RealFrameTime() * cvars.Number("cl_pitchspeed", 0)) * 0.5)
                bSetViewAng = true
            end

            if bSetViewAng then
                cmd:SetViewAngles(viewangle)
            end
        end
    end
end

function PLAYER:InputMouseApply(cmd, x, y, ang)
    if not self.Player.m_nLastMouseUpdate or self.Player.m_nLastMouseUpdate <= CurTime() then
        net.Start("zm_mousemove")
        net.SendToServer()

        self.Player.m_nLastMouseUpdate = CurTime() + 0.5
    end
end

function PLAYER:MouseDoublePressed(code, vector)
	if code == MOUSE_LEFT then
        local tr = util.QuickTrace(self.Player:GetShootPos(), vector * 56756, function(ent) return ent:IsNPC() or ent:IsNextBot() end)
        if tr.Entity and (tr.Entity:IsNPC() or tr.Entity:IsNextBot()) then

			local ZombieClass = tr.Entity:GetClass()

			self.Player.bIsDragging = false

            if not self.Player.bAddSelection then
                RunConsoleCommand("zm_deselect")
            end

			local SelectedZombies = {}
			for _, npc in pairs(ents.FindByClass( ZombieClass )) do
				SelectedZombies[#SelectedZombies + 1] = npc
			end

            timer.Simple(0, function()
				net.Start("zm_boxselect")
					net.WriteBool(self.Player.bAddSelection)
					net.WriteTable(SelectedZombies)
				net.SendToServer()
            end)

            return
        else
            if not self.Player.bAddSelection then
                RunConsoleCommand("zm_deselect")
            end
        end
	end
end

local healthcircleMaterial = Material("effects/zm_healthring")
local healtheffect         = Material("effects/yellowflare")
local undovision           = false
function PLAYER:PreDrawOther(ply)
    if ply:IsSurvivor() and ply:Alive() then
        local plHealth, plMaxHealth = ply:Health(), ply:GetMaxHealth()
        if plHealth > 0 then
            local pos = ply:GetPos()
            local colour = Color(0, 0, 0, 125)
            local healthfrac = math.max(plHealth, 0) / plMaxHealth

            colour.r = math.Approach(255, 20, math.abs(255 - 20) * healthfrac)
            colour.g = math.Approach(0, 255, math.abs(0 - 255) * healthfrac)
            colour.b = math.Approach(0, 20, math.abs(0 - 20) * healthfrac)

            render.SetMaterial(healthcircleMaterial)
            render.DrawQuadEasy(pos + Vector(0, 0, 1), Vector(0, 0, 1), 40, 40, colour)

            render.SetMaterial(healtheffect)
            render.DrawQuadEasy(pos + Vector(0, 0, 1), Vector(0, 0, 1), 40, 40, Color(255, 255, 255))
        end

        local v_qual = GetConVar("zm_vision_quality"):GetInt()
        if v_qual == 1 and not self.Player:IsLineOfSightClear(ply) then
            if cvars.Bool("zm_silhouette_zmvision_only") and not GAMEMODE.NightVision then return true end

            undovision = true

            render.ModelMaterialOverride(ZM_Vision)
            render.SetColorModulation(1, 0, 0, 1)
        end
    end

    return BaseClass.PreDraw(self, ply)
end

function PLAYER:PostDrawOther(ply)
    if undovision then
        undovision = false

        render.ModelMaterialOverride()
        render.SetColorModulation(1, 1, 1)
    end

    return BaseClass.PostDraw(self, ply)
end

local selection_color_outline = Color(255, 0, 0, 255)
local selection_color_box     = Color(120, 0, 0, 80)
function PLAYER:DrawHUD()
    if self.Player.bIsDragging then
        local x, y = gui.MousePos()
        local mX, mY = self.Player.DragX, self.Player.DragY
        if mX < x then
            if mY < y then
                surface.SetDrawColor(selection_color_outline)
                surface.DrawOutlinedRect(mX, mY, x - mX, y - mY)

                surface.SetDrawColor(selection_color_box)
                surface.DrawRect(mX, mY, x - mX, y - mY)
            else
                surface.SetDrawColor(selection_color_outline)
                surface.DrawOutlinedRect(mX, y, x - mX, mY - y)

                surface.SetDrawColor(selection_color_box)
                surface.DrawRect(mX, y, x - mX, mY - y)
            end
        else
            if mY > y then
                surface.SetDrawColor(selection_color_outline)
                surface.DrawOutlinedRect(x, y, mX - x, mY - y)

                surface.SetDrawColor(selection_color_box)
                surface.DrawRect(x, y, mX - x, mY - y)
            else
                surface.SetDrawColor(selection_color_outline)
                surface.DrawOutlinedRect(x, mY, mX - x, y - mY)

                surface.SetDrawColor(selection_color_box)
                surface.DrawRect(x, mY, mX - x, y - mY)
            end
        end
    end
end

function PLAYER:BindPress(bind, pressed)
    if bind == "impulse 100" and pressed then
        RunConsoleCommand("zm_power_nightvision")
        return true
    elseif bind == "+speed" and pressed then
        if not self.Player:KeyDown(IN_DUCK) then
            self.Player.bIsDragging = false
            gui.EnableScreenClicker(not vgui.CursorVisible(), true)

            if IsValid(GAMEMODE.powerMenu) then
                if vgui.CursorVisible() then
                    GAMEMODE.powerMenu:SetVisible(true)
                else
                    GAMEMODE.powerMenu:SetVisible(false)
                end
            end

            return true
        end
    elseif bind == "+duck" then
        if pressed then
            RunConsoleCommand("+speed")
        else
            RunConsoleCommand("-speed")
        end

        return true
    end
end

function PLAYER:Think()
    BaseClass.Think(self)

    if GAMEMODE.Income_Time and GAMEMODE.Income_Time ~= 0 and GAMEMODE.Income_Time <= CurTime() then
        local NumPlayers = team.NumPlayers(TEAM_SURVIVOR) + team.NumPlayers(TEAM_SPECTATOR)
        //local Increment = math.SimpleSplineRemapVal(NumPlayers, 1, 15, GetConVar("zm_resource_refill_min"):GetInt(), GetConVar("zm_resource_refill_max"):GetInt())
		local Increment = math.Remap(NumPlayers, 1, game.MaxPlayers(), GetConVar("zm_resource_refill_min"):GetInt(), GetConVar("zm_resource_refill_max"):GetInt())

        Increment = math.floor(Increment)

		for k, v in pairs ( GAMEMODE:FindZMs() ) do
			v:AddZMPoints(Increment)
			v:SetZMPointIncome(Increment)
		end
		//self.Player:AddZMPoints(Increment)
		//self.Player:SetZMPointIncome(Increment)

        GAMEMODE.Income_Time = CurTime() + GetConVar("zm_resource_refill_rate"):GetFloat()
    end
end

function PLAYER:KeyPress(key)
    if CLIENT and key == IN_RELOAD and IsFirstTimePredicted() then
        self.Player:ConCommand("zm_power_spotcreate")
    end
end

function PLAYER:PostThink()
    if SERVER and self.Player:IsOnFire() then
        self.Player:Extinguish()
    end
end

function PLAYER:ShouldTaunt(act)
    return false
end

function PLAYER:CanSuicide()
    if not GAMEMODE:GetRoundEnd() then
		if #team.GetPlayers(TEAM_ZOMBIEMASTER) > 1 then
			//self.Player:KillSilent()
			//self.Player:ChangeTeam(TEAM_SPECTATOR)

			self.Player.m_TriggerCount = 0
			self.Player.m_SpawnCount = 0
			self.Player:StripWeapons()
			self.Player:StripAmmo()
			self.Player:Spectate(OBS_MODE_ROAMING)
			self.Player:SetZMPoints(0)
			self.Player:Flashlight(false)

			hook.Call("PlayerSpawnAsSpectator", GAMEMODE, self.Player)

		else
			hook.Call("TeamVictorious", GAMEMODE, true, "zombiemaster_submit", true)
		end
    end

    return false
end

function PLAYER:ButtonDown(button)
    if SERVER then
        if button == self.Player:GetInfoNum("zm_teleportkey", 18) then
            self.Player.SpectatedPlayerKey = (self.Player.SpectatedPlayerKey or 0) + 1
            local players = {}

            for k, v in pairs(team.GetPlayers(TEAM_SURVIVOR)) do
                if v:Alive() and v ~= self.Player then
                    table.insert(players, v)
                end
            end

            if self.Player.SpectatedPlayerKey > #players then
                self.Player.SpectatedPlayerKey = 0
                return
            end

            self.Player:StripWeapons()
            local specplayer = players[self.Player.SpectatedPlayerKey]

            if specplayer then
                self.Player:SetPos(specplayer:EyePos())
            end
        elseif button == self.Player:GetInfoNum("zm_killzombieskey", 73) then
            self.Player:ConCommand("zm_power_killzombies")
        end
    else
        if button == KEY_LCONTROL or button == KEY_RCONTROL then
            self.Player.bAddSelection = true
        end
    end
end

function PLAYER:ButtonUp(button)
    if SERVER or not IsFirstTimePredicted() then return end

    if button == KEY_LCONTROL or button == KEY_RCONTROL then
        self.Player.bAddSelection = false
    end
end

function PLAYER:MousePressed(code, vector)
    local placementtype = self.Player.PlacementType
    if code == MOUSE_LEFT then
        if not self.Player.bIsDragging then
            self.Player.bIsDragging = true
            self.Player.DragX, self.Player.DragY = gui.MousePos()
        end

        local tr = util.QuickTrace(self.Player:GetShootPos(), vector * 56756, function(ent) return ent:IsNPC() or ent:IsNextBot() end)
        if tr.Entity and (tr.Entity:IsNPC() or tr.Entity:IsNextBot()) then
            self.Player.bIsDragging = false

            if not self.Player.bAddSelection then
                RunConsoleCommand("zm_deselect")
            end

            timer.Simple(0, function()
                //net.Start(tr.Entity.bIsSelected and "zm_net_deselect" or "zm_selectnpc")
				net.Start(tr.Entity.IsSelectedByZM and tr.Entity:IsSelectedByZM( self.Player ) and "zm_net_deselect" or "zm_selectnpc")
                    net.WriteEntity(tr.Entity)
                net.SendToServer()
            end)

            return
        else
            if not self.Player.bAddSelection then
                RunConsoleCommand("zm_deselect")
            end
        end

        local trace = {}

        trace.start = self.Player:GetShootPos()
        trace.endpos = self.Player:GetShootPos() + (vector * 10000)
        trace.filter = function(ent) return not hook.Call("ShouldSelectionIgnoreEnt", GAMEMODE, ent) end
        trace.ignoreworld = true

        local ent = util.TraceLine(trace).Entity
        if IsValid(ent) then
            local class = ent:GetClass()
            hook.Call("SpawnTrapMenu", GAMEMODE, class, ent)
        end
     elseif code == MOUSE_RIGHT then
        local click_delta = CurTime()

        local trace = util.GetPlayerTrace(self.Player)
        trace.endpos = self.Player:GetShootPos() + (vector * 10000)
        trace.filter = function(ent)
            return not ent:IsPlayer() and not ent:IsNPC() and not ent:IsNextBot()
        end

        local tr = util.TraceLine(trace)
        local zm_ring_pos = tr.HitPos + tr.HitNormal
        local zm_ring_ang = tr.HitNormal:Angle()
        zm_ring_ang:RotateAroundAxis(zm_ring_ang:Right(), 90)

        hook.Call("AddQuadDraw", GAMEMODE, hook.Call("GenerateClickedQuadTable", GAMEMODE, GAMEMODE.SelectRingMaterial, 0.3, vector, function(ent) return not (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) end))

        if IsValid(tr.Entity) and not tr.Entity:IsWorld() then
            net.Start("zm_npc_target_object")
                net.WriteVector(tr.HitPos)
                net.WriteEntity(tr.Entity)
            net.SendToServer()
        else
            net.Start("zm_command_npcgo")
                net.WriteVector(tr.HitPos)
            net.SendToServer()
        end
    end
end

function PLAYER:MouseReleased(code, vector)
    if self.Player.bIsDragging then
        util.BoxSelect(gui.MousePos())
        self.Player.bIsDragging = false
    end
end

function PLAYER:PreDraw()
    return false
end

local NightVision_ColorMod = {
    ["$pp_colour_addr"] = -1,
    ["$pp_colour_addg"] = -0.35,
    ["$pp_colour_addb"] = -1,
    ["$pp_colour_brightness"] = 0.8,
    ["$pp_colour_contrast"] = 1.1,
    ["$pp_colour_colour"] = 0,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0.028,
    ["$pp_colour_mulb"] = 0
}
function PLAYER:RenderScreenspaceEffects()
    if GAMEMODE.NightVision then
        if cvars.Number("zm_cl_nightvision_type") == 0 then
            GAMEMODE.NightVisionCur = GAMEMODE.NightVisionCur or 0.5

            if GAMEMODE.NightVisionCur < 0.995 then
                GAMEMODE.NightVisionCur = GAMEMODE.NightVisionCur + 0.02 * (1 - GAMEMODE.NightVisionCur)
            end

            NightVision_ColorMod["$pp_colour_brightness"] = GAMEMODE.NightVisionCur * 0.8
            NightVision_ColorMod["$pp_colour_contrast"] = GAMEMODE.NightVisionCur * 1.1

            DrawColorModify(NightVision_ColorMod)
            DrawBloom(0, GAMEMODE.NightVisionCur * 3.6, 0.1, 0.1, 1, GAMEMODE.NightVisionCur * 0.5, 0, 1, 0)
        else
            local dlight = DynamicLight(self.Player:EntIndex())
            if dlight then
                dlight.pos = EyePos()
                dlight.r = 255
                dlight.g = 25
                dlight.b = 8
                dlight.brightness = 6
                dlight.Decay = 1000
                dlight.Size = 2048
                dlight.DieTime = CurTime() + 5
            end
        end
    end
end

player_manager.RegisterClass("player_zombiemaster", PLAYER, "player_basezm")