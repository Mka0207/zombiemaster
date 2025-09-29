include("buffthefps.lua")

include("cl_team.lua")
include("cl_credits.lua")
include("cl_utility.lua")
include("cl_deathnotice.lua")
include("cl_killicons.lua")
include("cl_scoreboard.lua")
include("cl_dermaskin.lua")
include("cl_entites.lua")
include("cl_halo.lua")
include("cl_sck.lua")

include("cl_zm_options.lua")
include("cl_targetid.lua")
include("cl_hud.lua")
include("cl_zombie.lua")
include("cl_powers.lua")

include("vgui/dmainhud.lua")
include("vgui/dteamheading.lua")
include("vgui/dzombiepanel.lua")
include("vgui/dpowerpanel.lua")
include("vgui/dmodelselector.lua")
include("vgui/dclickableavatar.lua")
include("vgui/dcrosshairinfo.lua")
include("vgui/dhintpanel.lua")
include("vgui/dlobby.lua")
include("vgui/dhealthhud.lua")
include("vgui/dflashlighthud.lua")
include("vgui/doxygenhud.lua")
include("vgui/dreloadhud.lua")

include("shared.lua")
include("cl_collision.lua")

local ipairs = ipairs
local Lerp = Lerp
local CurTime = CurTime
local IsValid = IsValid

local STENCIL_ALWAYS = STENCIL_ALWAYS
local STENCIL_REPLACE = STENCIL_REPLACE
local STENCIL_KEEP = STENCIL_KEEP
local STENCIL_EQUAL = STENCIL_EQUAL
local STENCILCOMPARISONFUNCTION_ALWAYS = STENCILCOMPARISONFUNCTION_ALWAYS
local STENCILOPERATION_REPLACE = STENCILOPERATION_REPLACE
local STENCILOPERATION_KEEP = STENCILOPERATION_KEEP
local STENCILCOMPARISONFUNCTION_NOTEQUAL = STENCILCOMPARISONFUNCTION_NOTEQUAL

local render = render
local render_MaterialOverride = render.MaterialOverride
local render_OverrideDepthEnable = render.OverrideDepthEnable
local render_SetStencilEnable = render.SetStencilEnable
local render_SetStencilReferenceValue = render.SetStencilReferenceValue
local render_SetStencilWriteMask = render.SetStencilWriteMask
local render_SetStencilCompareFunction = render.SetStencilCompareFunction
local render_SetStencilPassOperation = render.SetStencilPassOperation
local render_SetStencilFailOperation = render.SetStencilFailOperation
local render_SetStencilZFailOperation = render.SetStencilZFailOperation
local render_SetStencilTestMask = render.SetStencilTestMask
local render_SetBlend = render.SetBlend
local render_OverrideAlphaWriteEnable = render.OverrideAlphaWriteEnable
local render_OverrideColorWriteEnable = render.OverrideColorWriteEnable
local render_SetColorModulation = render.SetColorModulation
local render_SuppressEngineLighting = render.SuppressEngineLighting
local render_SetMaterial = render.SetMaterial
local render_DrawQuadEasy = render.DrawQuadEasy
local render_GetRenderTarget = render.GetRenderTarget
local render_CopyRenderTargetToTexture = render.CopyRenderTargetToTexture
local render_Clear = render.Clear
local render_SetRenderTarget = render.SetRenderTarget
local render_DrawScreenQuad = render.DrawScreenQuad
local render_DrawScreenQuadEx = render.DrawScreenQuadEx
local render_ClearStencil = render.ClearStencil

local cam = cam
local cam_Start3D = cam.Start3D
local cam_End3D = cam.End3D
local cam_Start2D = cam.Start2D
local cam_End2D = cam.End2D

local surface = surface
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect

local math = math
local math_TimeFraction = math.TimeFraction

local table = table
local table_remove = table.remove

local hook = hook
local hook_Remove = hook.Remove

local zombieMenu = nil

local LocalW = ScrW()
local LocalH = ScrH()

GM.ItemEnts = {}
GM.SilhouetteEnts = {}
GM.QuadDraws = {}
GM.RagdollEnts = {}

ZM_Vision = CreateMaterial("ZM_Vision_Material_LD", "VertexLitGeneric", {
    ["$basetexture"] = "models/debug/debugwhite",
    ["$model"] = 1,
    ["$ignorez"] = 1
})

MySelf = NULL
GM.PlayerReadyList = {}
function GM:PostClientInit()
    MySelf:SetFlashlightBattery(100)

    game.AddParticles( "particles/burning_fx.pcf" )
    PrecacheParticleSystem("burning_character")

    timer.Simple(0, function()
        net.Start("zm_player_ready")
        net.SendToServer()
    end)

    self.ZM_Center_Hints = vgui.Create("zm_tippanel")
    self.ZM_Center_Hints:SetSize(ScrW() * 0.1, ScrH() * 0.05)
    self.ZM_Center_Hints:InvalidateLayout(true)
    self.ZM_Center_Hints:AlignBottom(ScrH() * 0.25)
    self.ZM_Center_Hints:ParentToHUD()

    if GetConVar("zm_debug_nolobby"):GetBool() then return end

    local bRoundActive = self:GetRoundActive() or team.NumPlayers(TEAM_ZOMBIEMASTER) > 0
    if not bRoundActive then
        self:OpenLobbyMenu()
    end
end

function GM:OnReloaded()
    MySelf = LocalPlayer()
    hook.Remove("PreRender", "PreRender.StopErrors")

    self.bLUARefresh = true

    if IsValid(g_Scoreboard) then
        g_Scoreboard:Remove()
    end

    if MySelf:IsZM() then
        hook.Call("RemoveZMPanels", self)
        hook.Call("CreateVGUI", self)
    end

    for _, pl in ipairs(player.GetAllNoCopy()) do
        hook.Call("OnPlayerCreated", self, pl)
        hook.Call("OnPlayerChangedTeam", self, pl, TEAM_SPECTATOR, pl:Team())
    end

    hook.Call("BuildZombieDataTable", self)
    hook.Call("SetupNetworkingCallbacks", self)
    hook.Call("SetupCustomItems", self)

    if IsValid(GAMEMODE.HumanHealthHUD) then
        GAMEMODE.HumanHealthHUD:Remove()
        GAMEMODE.HumanHealthHUD = vgui.Create("CHudHealthInfo")
    end

    if IsValid(GAMEMODE.FlashlightHUD) then
        GAMEMODE.FlashlightHUD:Remove()
        GAMEMODE.FlashlightHUD = vgui.Create("CHudFlashlight")
        GAMEMODE.FlashlightHUD:SetAlpha(255)
    end

    if IsValid(GAMEMODE.OxygenHUD) then
        GAMEMODE.OxygenHUD:Remove()
        GAMEMODE.OxygenHUD = vgui.Create("CHudOxygen")
        GAMEMODE.OxygenHUD:SetAlpha(255)
    end

    if IsValid(GAMEMODE.ReloadHUD) then
        GAMEMODE.ReloadHUD:Remove()
        GAMEMODE.ReloadHUD = vgui.Create("CHudReloadTime")
        GAMEMODE.ReloadHUD:SetAlpha(255)
    end

    self.bLUARefresh = false
end

function GM:SetupNormalizedSilhouetteColor()
    local brightness = self.SilhouetteStrength
    local r, g, b = util.NormalizeColor(self.SilhouetteColor)
    self.SilhouetteNormalColor[1] = r*brightness
    self.SilhouetteNormalColor[2] = g*brightness
    self.SilhouetteNormalColor[3] = b*brightness
end

hook.Add("PreRender", "PreRender.StopErrors", function()
    return true
end, HOOK_MONITOR_HIGH)

function GM:InitPostEntity()
    MySelf = LocalPlayer()
    hook.Remove("PreRender", "PreRender.StopErrors")

    self:SetupNormalizedSilhouetteColor()

    hook.Call("PostClientInit", self)

    local ammotbl = hook.Call("GetCustomAmmo", self)
    if table.Count(ammotbl) > 0 then
        for _, ammo in ipairs(ammotbl) do
            game.AddAmmoType({name = ammo.Type, dmgtype = ammo.DmgType, tracer = ammo.TracerType, plydmg = 0, npcdmg = 0, force = 2000, maxcarry = ammo.MaxCarry})
        end
    end

    hook.Call("OnPlayerCreated", self, MySelf)

	RunConsoleCommand('mat_colorcorrection', 0)
	RunConsoleCommand('r_queued_ropes', 1)
	RunConsoleCommand('mat_queue_mode', -1)
	RunConsoleCommand('studio_queue_mode', 1)
	RunConsoleCommand('gmod_mcore_test', 1)
	RunConsoleCommand('pp_bloom', 1)

    MySelf.m_OldInterpNPCs = GetConVar("cl_interp_npcs"):GetInt()
    MySelf.m_OldYawSpeed = GetConVar("cl_yawspeed"):GetInt()
    MySelf.m_OldPitchSpeed = GetConVar("cl_pitchspeed"):GetInt()

	RunConsoleCommand('cl_interp_npcs', 0.2)
	RunConsoleCommand('cl_yawspeed', 160)
	RunConsoleCommand('cl_pitchspeed', 100)
end

local last_draw_context = {}
local DRAW_CONTEXT_COUNTER = DRAW_CONTEXT_COUNTER or 0
local E_DrawModel = FindMetaTable("Entity").DrawModel

local function NPCRenderOverride(self)
    if self.DrawingSilhouette then
        GAMEMODE:CallZombieFunction(self, "Draw")
        return
    end

    if GAMEMODE:CallZombieFunction(self, "PreDraw") then return end

    GAMEMODE:CallZombieFunction(self, self.FadeFinished and "Draw" or "SpawnDraw")
    GAMEMODE:CallZombieFunction(self, "PostDraw")
end
local flesh = Material("models/flesh")
local flesh_skeleton = Material( "models/skeleton/skeleton_bloody" )
function GM:NetworkEntityCreated(ent)
    if ent:GetClass() == "npc_headcrab_poison" then
        ent:SetNoDraw(true)
        return
    end

    if ent:IsNPC() then
        ent:UseClientSideAnimation(true)

        if ent:IsNPC() then
            local data = scripted_ents.Get("zm_npc_nextbot_base")
            ent.DrawGore = data.DrawGore
            ent.AddGore = data.AddGore
        end

        self:CallZombieFunction(ent, "OnSpawned")
        self:CallZombieFunction(ent, "SetupModel")

        if ent:IsScripted() then
            ent:SetNoDraw(true)

            timer.Simple(0, function()
                if not IsValid(ent) then return end

                ent.Time = 0.55
                ent.LifeTime = CurTime() + 0.55

                ent:SetNoDraw(false)
                ent.fadeAlpha = 0
                ent.RenderOverride = NPCRenderOverride
            end)
        else
            ent.Time = 0.55
            ent.LifeTime = CurTime() + 0.55

            ent.fadeAlpha = 0
            ent.RenderOverride = NPCRenderOverride
        end
    elseif ent:IsPlayer() then
        hook.Call("OnPlayerCreated", self, ent)
    end
end

local function PlayerRenderOverride(self)
    if DRAW_CONTEXT_COUNTER == self.LAST_DRAW_CONTEXT then return end
    self.LAST_DRAW_CONTEXT = DRAW_CONTEXT_COUNTER
    E_DrawModel(self)
end
function GM:OnPlayerCreated(pl)
    pl.RenderOverride = PlayerRenderOverride
end

function GM:PreDrawOpaqueRenderables()
    DRAW_CONTEXT_COUNTER = DRAW_CONTEXT_COUNTER + 1
end

function GM:SetupFonts()
    surface.CreateFont("zm_powerhud_smaller", {font = "Consolas", size = ScreenScale(6)})
    surface.CreateFont("zm_powerhud_small", {font = "Consolas", size = ScreenScale(7)})

    surface.CreateFont("OptionsHelp", {font = "Verdana RU", size = ScreenScale(7), weight = 450})
    surface.CreateFont("OptionsHelpBig", {font = "Verdana RU", size = ScreenScale(8), weight = 450})

    surface.CreateFont("zm_hud_font_tiny", {font = "Verdana RU", size = ScreenScale(6), weight = 1000})
    surface.CreateFont("zm_hud_font_smaller", {font = "Verdana RU", size = ScreenScale(5), weight = 1000})
    surface.CreateFont("zm_hud_font_small", {font = "Verdana RU", size = ScreenScale(9), weight = 1000})
    surface.CreateFont("zm_hud_font_normal", {font = "Verdana RU", size = ScreenScale(14), weight = 1000})
    surface.CreateFont("zm_hud_font_big", {font = "Verdana RU", size = ScreenScale(24), weight = 1000})
    surface.CreateFont("zm_hud_font_bigger", {font = "Verdana RU", size = ScreenScale(30), weight = 1000})
    surface.CreateFont("zm_hud_font_huge", {font = "Verdana RU", size = ScreenScale(42), weight = 1000})

    surface.CreateFont("zm_game_text_small", {font = "Dead Font Walking", size = ScreenScale(9)})
    surface.CreateFont("zm_game_text", {font = "Dead Font Walking", size = ScreenScale(11)})

    surface.CreateFont("ZMHudNumbers", {font = "Built Titling Rg", size = ScreenScale(30), weight = 1000})
    surface.CreateFont("ZMHudNumbersSmall", {font = "Built Titling Rg", size = ScreenScale(22), weight = 1000})

    surface.CreateFont("ZMScoreBoardTitle", {font = "Verdana RU", size = ScreenScale(11)})
    surface.CreateFont("ZMScoreBoardTitleSub", {font = "Verdana RU", size = ScreenScale(5), weight = 1000})
    surface.CreateFont("ZMScoreBoardPlayer", {font = "Verdana RU", size = ScreenScale(5)})
    surface.CreateFont("ZMScoreBoardPlayerSmall", {font = "arial", size = ScreenScale(7)})
    surface.CreateFont("ZMScoreBoardHeading", {font = "Verdana RU", size = ScreenScale(8)})

    surface.CreateFont("ZMScoreBoardPlayerBold", {font = "Verdana RU", size = ScreenScale(8), weight = 1000, outline = true, antialias = false})
    surface.CreateFont("ZMScoreBoardPlayerSmallBold", {font = "arial", size = ScreenScale(8), weight = 1000, outline = true, antialias = false})

    surface.CreateFont("ZMDeathFonts", {font = "zmweapons", extended = false, size = ScreenScale(40), weight = 500})
    surface.CreateFont("ZMDeathNotice", {font = "HL2MP", extended = false, size = ScreenScale(40), weight = 500})

    surface.CreateFont("ZMDeathNotify", {font = "Trebuchet MS", antialias = true, shadow = true, extended = false, size = ScreenScale(8), weight = 700})
    surface.CreateFont("WeaponIconsSmall", {font = "HalfLife2", antialias = true, additive = true, extended = false, size = ScreenScale(32)})

    surface.CreateFont("ZMDeathFontsLarge", {font = "zmweapons", extended = false, size = ScreenScale(55), weight = 500})

    surface.CreateFont("zm_hud_font_small_scan", {font = "Verdana RU", size = ScreenScale(9), blursize = 2, scanlines = 2, weight = 1000})
    surface.CreateFont("zm_hud_font_normal_scan", {font = "Verdana RU", size = ScreenScale(14), blursize = 2, scanlines = 2, weight = 1000})
end

function GM:PreCleanupMap()
    RunConsoleCommand("stopsound")

    for _, rag in ipairs(self.RagdollEnts) do
        if not IsValid(rag) then continue end
        rag:Remove()
    end

    self.ItemEnts = {}
    self.SilhouetteEnts = {}
    self.RagdollEnts = {}
    self.QuadDraws = {}

    hook.Remove("PostDrawOpaqueRenderables", "PostDrawOpaqueRenderables.DrawQuads")
    hook.Remove("PostDrawOpaqueRenderables", "PostDrawOpaqueRenderables.ZombieMaster")

    if GAMEMODE.ParsedTextObjects then
        table.Empty(GAMEMODE.ParsedTextObjects)
    end
end

function GM:PostCleanupMap()
end

function GM:GenerateClickedQuadTable(mat, endtime, aimVector, filter)
    aimVector = aimVector or MySelf:GetAimVector()
    endtime = endtime or 0.3
    filter = filter or {MySelf}

    local click_delta = CurTime()

    local tr = util.QuickTrace(MySelf:GetShootPos(), aimVector * 10000, filter)
    local quadang = tr.HitNormal:Angle()
    quadang:RotateAroundAxis(quadang:Right(), 90)

    return {Material = mat, TexW = mat:Width(), TexH = mat:Height(), Delta = CurTime(), EndTime = CurTime() + endtime, Pos = tr.HitPos + tr.HitNormal, Ang = quadang}
end

function GM:PrePlayerDraw(ply)
    return not player_manager.RunClass(MySelf, MySelf == ply and "PreDraw" or "PreDrawOther", ply)
end

function GM:PostPlayerDraw(pl)
    player_manager.RunClass(MySelf, MySelf == pl and "PostDraw" or "PostDrawOther", pl)
end

function GM:ShouldSelectionIgnoreEnt(ent)
    return not (ent:GetClass() == "info_zombiespawn" or ent:GetClass() == "info_manipulate")
end

local lastwarntim = -1
function GM:Think()
    player_manager.RunClass(MySelf, "Think")

    for index, npc in pairs(self.iZombieList) do
        self:CallZombieFunction(npc, "Think")
    end

    if IsValid(self.HiddenCSEnt) then
        local tr = util.QuickTrace(MySelf:GetShootPos(), gui.ScreenToVector(gui.MousePos()) * 10000, player.GetAll())
        self.HiddenCSEnt:SetPos(tr.HitPos)

        local ang = MySelf:EyeAngles()
        ang.x = 0.0
        ang.z = 0.0
        self.HiddenCSEnt:SetAngles(ang)
    end

    if IsValid(self.PlayerLobby) then
        if self:GetRoundActive() then
            self.PlayerLobby:Remove()
        else
            self.PlayerLobby:SetVisible(not gui.IsGameUIVisible())
        end
    end

    if not self:GetRoundActive() then
        local endtime = self:GetReadyCount()
        if endtime ~= -1 then
            local timleft = math.max(0, endtime - CurTime())
            if timleft <= 5 and lastwarntim ~= math.ceil(timleft) then
                lastwarntim = math.ceil(timleft)
                if 0 < lastwarntim then
                    surface.PlaySound("buttons/lightswitch2.wav")
                end
            end
        end
    end
end

function GM:OnEntityCreated(ent)
    if ent:IsNPC() or ent:IsNextBot() then
        local zombietab = self:GetZombieData(entname)
        if zombietab ~= nil then
            self.iZombieList[ent:EntIndex()] = ent
        end

        table.insert(self.SilhouetteEnts, ent)
    elseif ent:GetClass() == "raggib" then
        ent:SetNoDraw(true)
    end

    if ent:GetClass() == "item_zm_ammo" or ent:GetClass() == "item_ammo_revolver" or ent:IsWeapon() then
        self.ItemEnts[#self.ItemEnts + 1] = ent
    end
end

function GM:EntityRemoved(ent)
    if ent:IsNPC() or ent:IsNextBot() then
        table.RemoveByValue(self.iZombieList, ent)
        table.RemoveByValue(self.SilhouetteEnts, ent)

        if ent:IsNPC() then
            if IsValid( ent.Hole ) then
                ent.Hole:Remove()
            end
            if IsValid( ent.Spook ) then
                ent.Spook:Remove()
            end
            if IsValid( ent.Meat ) then
                ent.Meat:Remove()
            end
        end

        if not ent.bCreatedRagdoll and not ent:IsNextBot() then
            ent.bCreatedRagdoll = true
            GAMEMODE:CreateRagdollForEnt(ent)
        end
    elseif ent:IsPlayer() then
		hook.Call("PlayerDisconnected",GAMEMODE,ent)
    elseif ent:IsRagdoll() then
        table.RemoveByValue(self.RagdollEnts, ent)
    end

    table.RemoveByValue(self.ObjectiveObjects, ent)

    if ent:GetClass() == "item_zm_ammo" or ent:GetClass() == "item_ammo_revolver" or ent:IsWeapon() then
        table.RemoveByValue(self.ItemEnts, ent)
    end
end

function GM:SpawnMenuEnabled()
    return false
end

function GM:SpawnMenuOpen()
    return false
end

function GM:ContextMenuOpen()
    return false
end

function GM:GetCurrentZombieGroups()
    return self.ZombieGroups == {} and nil or self.ZombieGroups
end

function GM:GetCurrentZombieGroup()
    return self.SelectedZombieGroups
end

function GM:OnPlayerChat( player, strText, bTeamOnly, bPlayerIsDead )
    local tab = {}

    if bTeamOnly then
        table.insert(tab, Color(30, 160, 40))
        table.insert(tab, "(TEAM) ")
    end

    if IsValid(player) then
        table.insert(tab, player)
    else
        table.insert(tab, "Console")
    end

    table.insert(tab, Color(255, 255, 255))
    table.insert(tab, ": " .. strText)

    chat.AddText(unpack(tab))

    return true
end

function GM:GUIMousePressed(mouseCode, aimVector)
    player_manager.RunClass(MySelf, "MousePressed", mouseCode, aimVector)
end

function GM:GUIMouseDoublePressed(mouseCode, aimVector)
	player_manager.RunClass(MySelf, "MouseDoublePressed", mouseCode, aimVector)
end

function GM:GUIMouseReleased(mouseCode, aimVector)
    player_manager.RunClass(MySelf, "MouseReleased", mouseCode, aimVector)
end

function GM:PlayerBindPress(ply, bind, pressed)
    if player_manager.RunClass(ply, "BindPress", bind, pressed) then return true end
end

function GM:CreateVGUI()
    holdTime = CurTime()
    isDragging = false

    if IsValid(self.trapPanel) then
        trapPanel:Remove()
    end

    gui.EnableScreenClicker(true)
    self.powerMenu = vgui.Create("zm_powerpanel")

    self.InfoHUD = vgui.Create("zm_mainhud")
    self.InfoHUD:SetSize(ScrW() * 0.15, ScrH() * 0.1)
    self.InfoHUD:AlignBottom(3)
    self.InfoHUD:ParentToHUD()

    self.ToolPan_Center_Tip = vgui.Create("DPanel")
    self.ToolPan_Center_Tip:SetAlpha(0)
    self.ToolPan_Center_Tip:SetSize(ScrW() * 0.1, ScrH() * 0.03)
    self.ToolPan_Center_Tip:InvalidateLayout(true)
    self.ToolPan_Center_Tip:Center()
    self.ToolPan_Center_Tip:AlignBottom(10)
    self.ToolPan_Center_Tip:ParentToHUD()

    function self.ToolPan_Center_Tip:Think()
        if GAMEMODE.ToolPan_Center_Tip ~= self then
            self:Remove()
        end
    end

    self.ToolLab_Center_Tip = vgui.Create("DLabel", self.ToolPan_Center_Tip)
    self.ToolLab_Center_Tip:SetTextColor(color_white)
    self.ToolLab_Center_Tip:SetFont("OptionsHelpBig")

    timer.Simple(0.25, function()
        if not IsValid(self.powerMenu) then
            self.powerMenu = vgui.Create("zm_powerpanel")
        else
            self.powerMenu:SetVisible(true)
        end
    end)

    hook.Call("SetupZMPowers", self)
end

function GM:IsMenuOpen()
    if IsValid(self.objmenu) and self.objmenu:IsVisible() then
        return true
    end

    local menus = hook.Call("GetZombieMenus", self)
    if menus then
        for _, menu in ipairs(menus) do
            if IsValid(menu) and menu:IsVisible() then
                return true
            end
        end
    end

    if self.trapMenu and self.trapMenu:IsVisible() then
        return true
    end

    if IsValid(PlayerModelSelectionFrame) and PlayerModelSelectionFrame:IsVisible() then
        return true
    end

    return false
end

function GM:CreateClientsideRagdoll(ent, ragdoll)
    if IsValid(ent) then
        if ent:GetClass() == "raggib" then
            ragdoll:Remove()
            return
        end

        ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        if ent:IsNPC() or ent:IsNextBot() then
            if ent:IsNPC() then
                ent.m_Ragdoll = ragdoll

                local effect = EffectData()
                    effect:SetEntity(ent)
                    effect:SetOrigin(ent:GetPos())
                    effect:SetHitBox(ent:GetNWInt("LastHitBox", -1))
                util.Effect("bodydamage_ragdoll", effect)
            end

            table.RemoveByValue(self.iZombieList, ent)
            table.RemoveByValue(self.SilhouetteEnts, ent)
            table.insert(self.RagdollEnts, ragdoll)

            if ent.LastDamageForce then
                if ent.LastDamageType and bit.band(ent.LastDamageType, DMG_BULLET) ~= 0 then
                    ent.LastDamageForce = ent.LastDamageForce * 25
                end

                if ent.LastHitPhysBone ~= nil then
                    local phys = ragdoll:GetPhysicsObjectNum(ent.LastHitPhysBone)
                    if IsValid(phys) then
                        phys:ApplyForceCenter(ent.LastDamageForce)
                    end
                else
                    local phys = ragdoll:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:ApplyForceCenter(ent.LastDamageForce)
                    end
                end
            end

            if not GetConVar("zm_shouldragdollsfade"):GetBool() then return end

            local ragdollnum = #ents.FindByClass(ragdoll:GetClass())
            if ragdollnum > GetConVar("zm_max_ragdolls"):GetInt() then
                if IsValid(self.RagdollEnts[1]) then
                    self.RagdollEnts[1]:SetSaveValue("m_bFadingOut", true)
                end
            end

            local fadetime = GetConVar("zm_cl_ragdoll_fadetime"):GetInt()
            timer.Simple(fadetime, function()
                if not IsValid(ragdoll) then return end
                ragdoll:SetSaveValue("m_bFadingOut", true)
            end)
        elseif ent:IsPlayer() then
            if ent == MySelf then
                ragdoll.bShouldSpectate = true
                timer.Simple(3, function()
                    local ragdoll = MySelf:GetRagdollEntity()
                    if not (ragdoll and ragdoll:IsValid()) then return end

                    -- This is a super retarded but the position of the ragdoll on the server is the location the player died
                    net.Start("zm_updateragdollpos")
                        net.WriteVector(ragdoll:WorldSpaceCenter())
                    net.SendToServer()
                end)
                timer.Simple(3.15, function()
                    local ragdoll = MySelf:GetRagdollEntity()
                    if not (ragdoll and ragdoll:IsValid()) then return end

                    ragdoll.bShouldSpectate = false
                end)
            end

            ragdoll:SetSubMaterial(ent.bSkinReplacmentIndex, ent.bSkinReplacmentMat)
        end
    end
end

local QuadVec = Vector( 0, 0, 1 )
local function DrawQuads()
    for i, tab in ipairs(GAMEMODE.QuadDraws) do
        local fraction = math.TimeFraction(tab.Delta, tab.EndTime, CurTime())
        local w, h = 0, 0
        if tab.bGrow then
            w = Lerp(fraction, 0, tab.TexW)
            h = Lerp(fraction, 0, tab.TexH)
        else
            w = Lerp(fraction, tab.TexW, 0)
            h = Lerp(fraction, tab.TexH, 0)
        end

        render_SuppressEngineLighting(true)

        render_SetMaterial(tab.Material)
        render_DrawQuadEasy(tab.Pos + QuadVec, QuadVec, w, h, color_white)

        render_SuppressEngineLighting(false)

        if fraction >= 1 then
            table_remove(GAMEMODE.QuadDraws, i)
            if #GAMEMODE.QuadDraws <= 0 then
                hook_Remove("PostDrawOpaqueRenderables", "PostDrawOpaqueRenderables.DrawQuads")
            end
        end
    end
end
function GM:AddQuadDraw(tab)
    table.insert(self.QuadDraws, tab)
    hook.Add("PostDrawOpaqueRenderables", "PostDrawOpaqueRenderables.DrawQuads", DrawQuads)
end

function GM:PostDrawOpaqueRenderables()
end

function GM:CalcView( ply, origin, angles, fov, znear, zfar )
    local target = ply:GetObserverTarget()
	if target and target:IsValid() then
        if (target:IsNPC() or target:IsNextBot()) and self.Player:GetObserverMode() ~= OBS_MODE_ROAMING then
            local tr = {
                start = target:WorldSpaceCenter(),
                endpos = target:WorldSpaceCenter() - (angles:Forward() * 150),
                filter = {target}
            }
            local trace = util.TraceLine(tr)

            origin = trace.HitPos + trace.HitNormal * 10
        end

		if target.SpawnOffset then origin:Set(origin + target.SpawnOffset) end

		local lasttarget = self.LastObserverTarget
		if lasttarget and lasttarget:IsValid() and target ~= lasttarget then
			if self.LastObserverTargetLerp then
				if CurTime() >= self.LastObserverTargetLerp then
					self.LastObserverTarget = nil
					self.LastObserverTargetLerp = nil
				else
					local delta = math.Clamp((self.LastObserverTargetLerp - CurTime()) / 0.3333, 0, 1) ^ 0.5
					origin:Set(self.LastObserverTargetPos * delta + origin * (1 - delta))
				end
			else
				self.LastObserverTargetLerp = CurTime() + 0.3333
			end
		else
			self.LastObserverTarget = target
			self.LastObserverTargetPos = origin
		end
	end

    local ragdoll = ply:GetRagdollEntity()
    if ragdoll and ragdoll:IsValid() and ragdoll.bShouldSpectate then
        local tr = {
            start = ragdoll:WorldSpaceCenter(),
            endpos = ragdoll:WorldSpaceCenter() - (angles:Forward() * 150),
            filter = {ragdoll}
        }
        local trace = util.TraceLine(tr)

        origin = trace.HitPos + trace.HitNormal * 10
    end

    return self.BaseClass.CalcView(self, ply, origin, angles, fov, znear, zfar)
end

function GM:RenderScreenspaceEffects()
    player_manager.RunClass(MySelf, "RenderScreenspaceEffects")
end

function GM:RestartRound()
    hook.Call("RemoveZMPanels", self)

    table.Empty(self.iZombieList)

    GAMEMODE.ZombieGroups = nil
    GAMEMODE.SelectedZombieGroups = nil
    GAMEMODE.NightVision = nil

    hook.Call("ResetZombieMenus", self)

    hook.Remove("PreRender", "PreRender.Fullbright")
    hook.Remove("PostRender", "PostRender.Fullbright")
    hook.Remove("PreDrawHUD", "PreDrawHUD.Fullbright")

    placingShockWave = false
    placingZombie = false
    placingRally = false

    zombieMenu = nil

    mouseX, mouseY  = 0, 0
    isDragging = false

    gui.EnableScreenClicker(false)
end

function GM:RemoveZMPanels()
    if IsValid(self.trapPanel) then
        trapPanel:Remove()
    end

    if IsValid(self.powerMenu) then
        self.powerMenu:Remove()
    end

    if IsValid(self.ToolPan_Center) then
        self.ToolPan_Center_Tip:Remove()
    end

    if IsValid(self.ToolLab_Center_Tip) then
        self.ToolLab_Center_Tip:Remove()
    end

    if IsValid(self.InfoHUD) then
        self.InfoHUD:Remove()
    end
end

function GM:OnScreenSizeChanged(new_w, new_h)
    LocalW = new_w
    LocalH = new_h

    -- This could be unwise but it seems to be the only way to fresh font sizes
    self:SetupFonts()

    if IsValid(MySelf.QuickInfo) then
        MySelf.QuickInfo:Remove()

        MySelf.QuickInfo = vgui.Create("CHudQuickInfo")
        MySelf.QuickInfo:Center()
    end

    -- Couldn't figure out how to fix the panel sizing getting screwed up when changing to a lower res, recreating the panel fixes it
    if MySelf:IsZM() and IsValid(self.powerMenu) then
        self.powerMenu:Remove()
        self.powerMenu = vgui.Create("zm_powerpanel")

        hook.Call("SetupZMPowers", self)
    end
end

function GM:PlayerSwitchWeapon(ply, oldwep, newwep)
    if IsValid(ply.QuickInfo) then
        if newwep.DrawQuickInfo and not ply.QuickInfo:IsVisible() then
            ply.QuickInfo:SetVisible(true)
        elseif not newwep.DrawQuickInfo and ply.QuickInfo:IsVisible() then
            ply.QuickInfo:SetVisible(false)
        end
    end
end

local glowmat = Material("dev/glow_color")
local function DrawZMSilhouettes()
    if GAMEMODE.ZMVisionQuality >= 2 then
        if GAMEMODE.SilhouetteZMVisionOnly and not GAMEMODE.NightVision then return end

        render_MaterialOverride(glowmat)
        render_OverrideDepthEnable(true, false)

        render_SetStencilEnable(true)

        render_SetStencilReferenceValue(2)
        render_SetStencilWriteMask(2)
        render_SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
        render_SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render_SetStencilFailOperation(STENCILOPERATION_KEEP)
        render_SetStencilZFailOperation(STENCILOPERATION_KEEP)

        render_SetBlend(0)
        render_OverrideAlphaWriteEnable(true, false)
        render_OverrideColorWriteEnable(true, false)

        for k, v in ipairs(GAMEMODE.SilhouetteEnts) do
            if not v.ShouldDrawSilhouette then continue end

            v.DrawingSilhouette = true
            v:DrawModel()
            v.DrawingSilhouette = false
        end

        render_OverrideAlphaWriteEnable(false, true)
        render_OverrideColorWriteEnable(false, true)

        render_OverrideDepthEnable(false, false)

        render_SetStencilReferenceValue(3)
        render_SetStencilTestMask(2)
        render_SetStencilWriteMask(1)
        render_SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NOTEQUAL)
        render_SetStencilPassOperation(STENCILOPERATION_REPLACE)
        render_SetStencilZFailOperation(STENCILOPERATION_REPLACE)
        render_SetStencilFailOperation(STENCILOPERATION_KEEP)

        render_SetBlend(1)
        render_SetColorModulation(GAMEMODE.SilhouetteNormalColor[1], GAMEMODE.SilhouetteNormalColor[2], GAMEMODE.SilhouetteNormalColor[3])

        for k, v in ipairs(GAMEMODE.SilhouetteEnts) do
            if not v.ShouldDrawSilhouette then continue end

            v.DrawingSilhouette = true
            v:DrawModel()
            v.DrawingSilhouette = false
        end

        render_MaterialOverride()
        render_SetStencilEnable(false)
    end
end

local mat_Copy = Material( "pp/copy" )
local mat_Add = Material( "pp/add" )
local rt_Store = render.GetScreenEffectTexture( 0 )
local rt_Buffer = render.GetScreenEffectTexture( 1 )
local function DrawItemHalos()
    if not GAMEMODE.bDisableHalos then
        local rt_Scene = render_GetRenderTarget()
        render_CopyRenderTargetToTexture(rt_Store)

        render_Clear(0, 0, 0, 255, false, true)

        cam_Start3D()
        render_ClearStencil()
        render_SetStencilEnable(true)
            render_SuppressEngineLighting(true)
                render_SetStencilWriteMask(1)
                render_SetStencilTestMask(1)
                render_SetStencilReferenceValue(1)

                render_SetStencilCompareFunction(STENCIL_ALWAYS)
                render_SetStencilPassOperation(STENCIL_REPLACE)
                render_SetStencilFailOperation(STENCIL_KEEP)
                render_SetStencilZFailOperation(STENCIL_KEEP)

                for k, v in ipairs(GAMEMODE.ItemEnts) do
                    if not IsValid(v) or not v:ShouldDrawOutline() or v:GetNoDraw() then continue end
                    v:DrawModel()
                end

                render_SetStencilCompareFunction(STENCIL_EQUAL)
                render_SetStencilPassOperation(STENCIL_KEEP)

                cam_Start2D()
                    surface_SetDrawColor(GAMEMODE.HaloColor)
                    surface_DrawRect(0, 0, LocalW, LocalH)
                cam_End2D()
            render_SuppressEngineLighting(false)
        render_SetStencilEnable(false)
        cam_End3D()

        render_CopyRenderTargetToTexture(rt_Buffer)
        render_SetRenderTarget(rt_Scene)

        mat_Copy:SetTexture("$basetexture", rt_Store)
        render_SetMaterial(mat_Copy)

        render_DrawScreenQuad()

        render_SetStencilEnable(true)
            render_SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NOTEQUAL)

            mat_Add:SetTexture("$basetexture", rt_Buffer)
            render_SetMaterial(mat_Add)

            render_DrawScreenQuadEx(0, 0, LocalW + GAMEMODE.HaloWidth, LocalH + GAMEMODE.HaloWidth)
            render_DrawScreenQuadEx(0, 0, LocalW - GAMEMODE.HaloWidth, LocalH - GAMEMODE.HaloWidth)
        render_SetStencilEnable(false)

        render_SetStencilTestMask(0)
        render_SetStencilWriteMask(0)
        render_SetStencilReferenceValue(0)
    end
end

function GM:OnPlayerChangedTeam(ply, oldTeam, newTeam)
    if newTeam == TEAM_ZOMBIEMASTER then
        hook.Run("PlayerAlphaChanged", ply, 0)
    else
        hook.Run("PlayerAlphaChanged", ply, 1)
        ply.ShadowMan = false
    end

    if ply == MySelf then
        if newTeam == TEAM_ZOMBIEMASTER then
            hook.Add("PostDrawOpaqueRenderables", "PostDrawOpaqueRenderables.ZombieMaster", DrawZMSilhouettes)
            hook.Remove("PostDrawEffects", "PostDrawEffects.HumanHalos")
        else
            if newTeam == TEAM_SURVIVOR then
                hook.Add("PostDrawEffects", "PostDrawEffects.HumanHalos", DrawItemHalos)
            else
                hook.Remove("PostDrawEffects", "PostDrawEffects.HumanHalos")
            end

            hook.Remove("PostDrawOpaqueRenderables", "PostDrawOpaqueRenderables.ZombieMaster")
        end
    end

    if oldTeam == TEAM_SURVIVOR then
        self:ApplyZombieScaling()
    elseif oldTeam == TEAM_ZOMBIEMASTER then
        gui.EnableScreenClicker(false, true)
    end
end

function GM:InputMouseApply(cmd, x, y, ang)
    player_manager.RunClass(MySelf, "InputMouseApply", cmd, x, y, ang)
end

function GM:ShutDown()
    if IsValid(handsent) then
        handsent:Remove()
    end

	RunConsoleCommand('cl_interp_npcs', MySelf.m_OldInterpNPCs or 0.0)
	RunConsoleCommand('cl_yawspeed', MySelf.m_OldYawSpeed or 210)
	RunConsoleCommand('cl_pitchspeed', MySelf.m_OldPitchSpeed or 225)

    for _, rag in ipairs(self.RagdollEnts) do
        if not IsValid(rag) then continue end
        rag:Remove()
    end
end

function GM:PreDrawPlayerHands(hands, vm, ply, weapon)
	if weapon.PreDrawPlayerHands and weapon:PreDrawPlayerHands(vm, weapon, ply) then
		return true
	end

    return self.DisableFPHands
end

function GM:PostDrawPlayerHands(hands, vm, ply, weapon)
	if weapon.PostDrawPlayerHands then
        weapon:PostDrawPlayerHands(vm, weapon, ply)
	end
end

local PosMod, AngMod = Vector(0, 0, 0), Vector(0, 0, 0)
local CurPosMod, CurAngMod = Vector(0, 0, 0), Vector(0, 0, 0)
local mod2 = 0
function GM:PreDrawViewModel(vm, pl, wep)
	if not IsValid(wep) then return true end

    if not wep.bInitBobVars then
        wep.BlendPos = Vector(0, 0, 0)
        wep.BlendAng = Vector(0, 0, 0)
        wep.OldDelta = Angle(0, 0, 0)
        wep.AngleDelta = Angle(0, 0, 0)
        wep.FireMove = 0
        wep.ViewModelMovementScale = wep.ViewModelMovementScale or 1
        wep.ApproachSpeed = wep.ApproachSpeed or 10
        wep.bInitBobVars = true
    end

    local Vec0 = Vector(0, 0, 0)
    local td = {}
    local veldepend = {pitch = 0, yaw = 0, roll = 0}
    local CT = UnPredictedCurTime()
    local EA = EyeAngles()
    local FT = FrameTime()

    local delta = Angle(EA.p, EA.y, 0) - wep.OldDelta
    delta.p = math.Clamp(delta.p, -10, 10)

    wep.OldDelta = Angle(EA.p, EA.y, 0)
    wep.AngleDelta = LerpAngle(math.Clamp(FT * 10, 0, 1), wep.AngleDelta, delta)
    wep.AngleDelta.y = math.Clamp(wep.AngleDelta.y, -10, 10)

    local vel = pl:GetVelocity()
    local len = vel:Length()
    local ws = pl:GetWalkSpeed()

    PosMod, AngMod = Vec0 * 1, Vec0 * 1
    mod2 = 1

    veldepend.roll = math.Clamp((vel:DotProduct(EA:Right()) * 0.04) * len / ws, -5, 5)

    local TargetPos, TargetAng
    TargetPos, TargetAng = Vec0 * 1, Vec0 * 1
    wep.ApproachSpeed = math.Approach(wep.ApproachSpeed, 10, FT * 100)

    local cos1, sin1, tan, mod, sin2, mul
    if len < 10 or not pl:OnGround() then
        cos1, sin1 = math.cos(CT), math.sin(CT)
        tan = math.atan(cos1 * sin1, cos1 * sin1)

        AngMod.x = AngMod.x + tan * 1.15
        AngMod.y = AngMod.y + cos1 * 0.4
        AngMod.z = AngMod.z + tan

        PosMod.y = PosMod.y + tan * 0.2 * mod2
    elseif len > 10 and len < ws * 1.2 then
        mod = 6 + ws / 130
        mul = math.Clamp(len / ws, 0, 1)
        sin1 = math.sin(CT * mod) * mul
        cos1 = math.cos(CT * mod) * mul
        tan1 = math.tan(sin1 * cos1) * mul

        AngMod.x = AngMod.x + tan1 * wep.ViewModelMovementScale * mod2
        AngMod.y = AngMod.y - cos1 * wep.ViewModelMovementScale * mod2
        AngMod.z = AngMod.z + cos1 * wep.ViewModelMovementScale * mod2
        PosMod.x = PosMod.x - sin1 * 0.4 * wep.ViewModelMovementScale * mod2
        PosMod.y = PosMod.y + tan1 * 1 * wep.ViewModelMovementScale * mod2
        PosMod.z = PosMod.z + tan1 * 0.5 * wep.ViewModelMovementScale * mod2
    end

    FT = FrameTime()

    TargetAng.z = TargetAng.z + veldepend.roll
    wep.BlendPos = LerpVector(FT * wep.ApproachSpeed, wep.BlendPos, TargetPos)
    wep.BlendAng = LerpVector(FT * wep.ApproachSpeed, wep.BlendAng, TargetAng)

    CurPosMod = LerpVector(FT * 10, CurPosMod, PosMod)
    CurAngMod = LerpVector(FT * 10, CurAngMod, AngMod)

    wep.FireMove = Lerp(FT * 15, wep.FireMove, 0)

	if wep.ShowViewModel == false then
		render.SetBlend(0)
	end

    player_manager.RunClass(pl, "PreDrawViewModel", vm, wep)

	if wep.PreDrawViewModel == nil then return false end
	return wep:PreDrawViewModel(vm, wep, pl)
end

local handsent = ClientsideModel("models/weapons/tfa_ins2/c_ins2_pmhands.mdl")
function GM:PostDrawViewModel(vm, pl, wep)
	if not IsValid(wep) then return false end

	if wep.UseHands or not wep:IsScripted() then
		local hands = pl:GetHands()
		if IsValid(hands) and IsValid(hands:GetParent()) then
			if not hook.Call("PreDrawPlayerHands", self, hands, vm, pl, wep) then
                if vm:LookupBone("R ForeTwist") and not vm:LookupBone("ValveBiped.Bip01_R_Hand") then
                    handsent:SetParent(vm)
                    handsent:SetPos(vm:GetPos())
                    handsent:SetAngles(vm:GetAngles())
                    handsent:AddEffects(EF_BONEMERGE)
                    handsent:AddEffects(EF_BONEMERGE_FASTCULL)
                    handsent:InvalidateBoneCache()

                    hands:SetParent(handsent)
                    hands:AddEffects(EF_BONEMERGE)
                    hands:AddEffects(EF_BONEMERGE_FASTCULL)
                end

				if wep.ViewModelFlip then render.CullMode(MATERIAL_CULLMODE_CW) end
				hands:DrawModel()
				render.CullMode(MATERIAL_CULLMODE_CCW)
			end

			hook.Call("PostDrawPlayerHands", self, hands, vm, pl, wep)
		end
	end

    if wep.ShowViewModel == false then
        render.SetBlend(1)
    end

	player_manager.RunClass(pl, "PostDrawViewModel", vm, wep)

	if wep.PostDrawViewModel == nil then return false end
	return wep:PostDrawViewModel( vm, wep, pl )
end

function GM:CalcViewModelView(wep, vm, oldPos, oldAng, pos, ang)
	if not IsValid(wep) then return pos, ang end

	if wep.bInitBobVars then
        --wep.ViewModelFOV = wep.ViewModelFOV_Orig

        ang:RotateAroundAxis(ang:Right(), CurAngMod.x + wep.BlendAng.x + wep.AngleDelta.p * mod2)

        if not wep.ViewModelFlip then
            ang:RotateAroundAxis(ang:Up(), CurAngMod.y + wep.BlendAng.y + wep.AngleDelta.y * 0.3 * mod2)
            ang:RotateAroundAxis(ang:Forward(), CurAngMod.z + wep.BlendAng.z + wep.AngleDelta.y * 0.3 * mod2)
        else
            ang:RotateAroundAxis(ang:Up(), CurAngMod.y + wep.BlendAng.y - wep.AngleDelta.y * 0.3 * mod2)
            ang:RotateAroundAxis(ang:Forward(), CurAngMod.z - wep.BlendAng.z - wep.AngleDelta.y * 0.3 * mod2)
        end

        if not wep.ViewModelFlip then
            pos = pos + (CurPosMod.x + wep.BlendPos.x + wep.AngleDelta.y * 0.1 * mod2) * ang:Right()
        else
            pos = pos + (CurPosMod.x + wep.BlendPos.x - wep.AngleDelta.y * 0.1 * mod2) * ang:Right()
        end

        pos = pos + (CurPosMod.y + wep.BlendPos.y - wep.FireMove) * ang:Forward()
        pos = pos + (CurPosMod.z + wep.BlendPos.z - wep.AngleDelta.p * 0.1) * ang:Up()
	end

	if wep.VMAng and wep.VMPos then
		ang:RotateAroundAxis(ang:Right(), wep.VMAng.x)
		ang:RotateAroundAxis(ang:Up(), wep.VMAng.y)
		ang:RotateAroundAxis(ang:Forward(), wep.VMAng.z)

		pos:Add( ang:Right() * (wep.VMPos.x) )
		pos:Add( ang:Forward() * (wep.VMPos.y) )
		pos:Add( ang:Up() * (wep.VMPos.z) )
	end

	local vm_origin, vm_angles = pos, ang
	local func = wep.GetViewModelPosition
	if func then
		local epos, eang = func(wep, pos*1, ang*1)
		vm_origin = epos or vm_origin
		vm_angles = eang or vm_angles
	end

	func = wep.CalcViewModelView
	if func then
		local epos, eang = func(wep, vm, oldPos*1, oldAng*1, pos*1, ang*1)
		vm_origin = epos or vm_origin
		vm_angles = eang or vm_angles
	end

	return vm_origin, vm_angles
end

function GM:CreateRagdollForEnt(ent, forcemdl, bforcecustom)
    if jit.arch == "x64" or bforcecustom then
        local mdl = forcemdl or ent.CurrentModel or ent:GetModel()
        if mdl == "" or mdl == nil then return end

        local ragdoll = ClientsideRagdoll(mdl, ent:GetRenderGroup())
        if IsValid(ragdoll) then
            ragdoll:SetPos(ent:GetPos())
            ragdoll:SetAngles(ent:GetAngles())
            ragdoll:SetNoDraw(false)
            ragdoll:Spawn()
            ragdoll:Activate()
            ragdoll:SetSkin(ent:GetSkin())
            local bgt = ent:GetBodyGroups()

            local bgs = ""

            for k, t in pairs(bgt) do
                bgs = bgs..ent:GetBodygroup(t.id)
            end

            ragdoll:SetBodyGroups(bgs)
            ragdoll:SetRenderMode(ent:GetRenderMode())
            ragdoll:SetColor(ent:GetColor())
            ragdoll:SetMaterial(ent:GetMaterial())
            ragdoll:SetVelocity(ent:GetVelocity())
            for i=0, ragdoll:GetPhysicsObjectCount() - 1 do
                local bonephys = ragdoll:GetPhysicsObjectNum(i)
                if IsValid(bonephys) then
                    local bonepos,boneang = ent:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
                    if bonepos then
                        bonephys:SetPos(bonepos)
                        bonephys:SetAngles(boneang)
                    end
                end
            end

            if ent:IsOnFire() then
                local m_hEffect = CreateParticleSystem(ragdoll, "burning_character", PATTACH_ABSORIGIN_FOLLOW)
                m_hEffect:AddControlPoint(1, ragdoll, PATTACH_ABSORIGIN_FOLLOW)
                m_hEffect:SetControlPoint(0, ragdoll:GetPos())
                m_hEffect:SetControlPoint(1, ragdoll:GetPos())
                m_hEffect:SetControlPointEntity(0, ragdoll)
                m_hEffect:SetControlPointEntity(1, ragdoll)
            end

            hook.Call("CreateClientsideRagdoll", self, ent, ragdoll)
            ent:SetNoDraw(true)
        end
    else
        ent:BecomeRagdollOnClient()
    end
end

function GM:SetupNetworkingCallbacks()
    self:AddNetworkingCallbacks("bClingingCeiling", function(ent, value) ent:SetCeilingCling(value) end)
    self:AddNetworkingCallbacks("bIsEngineNPC", function(ent, value) if ent:IsNPC() then ent:SetEngineNPC(value) end end)
    self:AddNetworkingCallbacks("bSkinReplacmentIndex", function(ent, value) ent:SetSkinReplacmentIndex(value) end)
    self:AddNetworkingCallbacks("bSkinReplacmentMat", function(ent, value) ent:SetSkinReplacmentMat(value) end)
    //self:AddNetworkingCallbacks("selected", function(ent, value) ent:SetSelected(value) end)
    self:AddNetworkingCallbacks("m_bIsFlashLightOn", function(ent, value) ent.m_bIsFlashLightOn = value ent:ClientSetFlashlight(value==true) end)

    self:AddNetworkingCallbacks("bObjectiveHalos",function(ent, value)
        if value==true then
            table.insert(GAMEMODE.ObjectiveObjects, ent)
        else
            table.RemoveByValue(GAMEMODE.ObjectiveObjects, ent)
        end
    end)
end

function GM:PreDrawHalos()
    if #self.ObjectiveObjects > 0 then
        halo.Add(self.ObjectiveObjects, COLOR_SOFTRED, 2, 2, 2, true, true)
    end
end

net.Receive("zm_infostrings", function(length)
    GAMEMODE.MapInfo = net.ReadString()
    GAMEMODE.HelpInfo = net.ReadString()
end)

net.Receive("zm_sendcurrentgroups", function(length)
    GAMEMODE.ZombieGroups = net.ReadTable()
    GAMEMODE.bUpdateGroups = true
end)

net.Receive("zm_sendselectedgroup", function(length)
    GAMEMODE.SelectedZombieGroups = net.ReadUInt(8)
end)

net.Receive("zm_spawnclientragdoll", function(length)
    local ent = net.ReadEntity()
    if IsValid(ent) then
        ent.bCreatedRagdoll = true
        GAMEMODE:CreateRagdollForEnt(ent)
    end
end)

net.Receive("zm_forcecustomragdoll", function(length)
    local ent = net.ReadEntity()
    if IsValid(ent) then
        ent.bCreatedRagdoll = true
        GAMEMODE:CreateRagdollForEnt(ent, net.ReadString(), true)
    end
end)

net.Receive("zm_coloredprintmessage", function(length)
    util.PrintMessage(net.ReadString(), MySelf, net.ReadTable())
end)

net.Receive("zm_sendlua", function(length)
    RunString(net.ReadString(), "SendLua")
end)

-- by magicswap
net.Receive("zs_playtaunt", function(length)
    local slot = net.ReadUInt(4)
    local anim = net.ReadString()
    local ply = net.ReadEntity()

    if not ply:IsValid() then return end

    local animid = ply:LookupSequence(anim)

    ply:AddVCDSequenceToGestureSlot(slot, animid, 0, true)
end)

net.Receive("zm_updateclientreadytable", function(length)
    local bFullUpdate = net.ReadBool()
    if bFullUpdate then
        GAMEMODE.PlayerReadyList = net.ReadTable()
        return
    end

    local pl = net.ReadEntity()
    if not IsValid(pl) then return end

    local bReady = net.ReadBool()
    GAMEMODE.PlayerReadyList[pl] = bReady
end)

local DrawTravelTime = 0
local function DrawTravelInfo()
	surface.SetFont("CloseCaption_Bold")
	local xs, ys = surface.GetTextSize(GAMEMODE.PendingURL)
	local t = (CurTime() - DrawTravelTime)
	local bx = xs+36
	local by = ys+24
	local x = ScrW()*0.5
	local y = ScrH()*0.35
	local bDrawText = false
	local bDrawTimer = false
	local bgColor = Color(0,0,0,86)

	if t<0.4 then
		t = t/0.4
		bx = bx*t
	elseif t<0.5 then
		if t<0.45 then
			t = (t-0.4)/0.05
		else
			t = 1 - ((t-0.45)/0.05)
			bDrawText = true
		end
		local cv = math.ceil(t*255)
		local ca = math.ceil(Lerp(t,86,255))
		bgColor = Color(cv,cv,cv,ca)
	else
		bDrawText = true
		bDrawTimer = (t>1)
	end

	draw.RoundedBox(6,x-(bx*0.5),y-(by*0.5),bx,by,bgColor)
	if bDrawTimer then
		t = math.min((t-1) / 5,1)
		surface.SetDrawColor( 255, 0, 0, 200 )
		surface.DrawRect( x-(bx*0.5), y+(ys*0.55), bx*t, 8 )
	end

	if bDrawText then
        draw.SimpleText(GAMEMODE.PendingURL, "CloseCaption_Bold", x-(xs*0.5), y-(ys*0.5), color_white)
	end
end
net.Receive("zm_servertravel", function(length)
	if net.ReadBool() then
		local NextMap = net.ReadString()
		GAMEMODE.PendingURL = "Server traveling to "..NextMap
		DrawTravelTime = CurTime()
		hook.Add("HUDPaint","HUDPaint_DrawServerTravel",DrawTravelInfo)
		hook.Call("ServerTravel",nil,NextMap)
	else
		GAMEMODE.PendingURL = nil
		hook.Remove("HUDPaint", "HUDPaint_DrawServerTravel")
		hook.Call("ServerTravel")
	end
end)

net.Receive("zm_navloaded", function(length)
    GAMEMODE.bReplaceZombiesWithNextBots = net.ReadBool()
    GAMEMODE:ApplyZombieClasses()
end)

local function DestroyShadow(ent)
    if ent:IsValid() and (ent:IsPlayer() or ent:IsWeapon()) then
        ent:AddEffects(EF_NOSHADOW)
        ent:DrawShadow(false)
        ent:DestroyShadow()
    end
end
hook.Add("OnEntityCreated", "DestroyShadow.OnEntityCreated", DestroyShadow)
hook.Add("NetworkEntityCreated", "DestroyShadow.NetworkEntityCreated", DestroyShadow)