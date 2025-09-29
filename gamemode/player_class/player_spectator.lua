AddCSLuaFile()
DEFINE_BASECLASS("player_basezm")

local PLAYER = {}

PLAYER.bIgnoreAFK = true

function PLAYER:Spawn()
    self.Player:KillSilent()
    self.Player:Spectate(OBS_MODE_ROAMING)
    self.Player:SetMoveType(MOVETYPE_NOCLIP)
    
    self.Player:SendLua([[
        hook.Call("RemoveZMPanels", GAMEMODE)
    ]])
end

function PLAYER:CanSuicide()
    return false
end

function PLAYER:PostOnDeath(inflictor, attacker)
    BaseClass.PostOnDeath(self, inflictor, attacker)
    
    timer.Simple(1, function()
        if IsValid(self.Player) and self.Player:IsSpectator() and self.Player:GetObserverMode() ~= OBS_MODE_ROAMING then
            self.Player:Spectate(OBS_MODE_ROAMING)
        end
    end)
end

function PLAYER:KeyPress(key)
    if SERVER and self.Player.AllowKeyPress then
		local specplayer = NULL
		local bChangeTarget = false
		if self.Player:KeyPressed(IN_RELOAD) then
			if self.Player:GetObserverMode() ~= OBS_MODE_ROAMING then
				self.Player:Spectate(OBS_MODE_ROAMING)
				self.Player:SpectateEntity(NULL)
			end
		elseif self.Player:KeyPressed(IN_ATTACK) then
			self.Player:StripWeapons()
			specplayer = self:GetNextViewablePlayer(1)
			bChangeTarget = true
		elseif self.Player:KeyPressed(IN_ATTACK2) then
			self.Player:StripWeapons()
			specplayer = self:GetNextViewablePlayer(-1)
			bChangeTarget = true
		end
		
		if bChangeTarget then
			if IsValid(specplayer) then
				self.Player:Spectate(OBS_MODE_CHASE)
				self.Player:SpectateEntity(specplayer)
			else
				self.Player:Spectate(OBS_MODE_ROAMING)
				self.Player:SpectateEntity(NULL)
			end
		end
    end
end

function PLAYER:CalcView(view)
    local target = self.Player:GetObserverTarget()
    if IsValid(target) and (target:IsNPC() or target:IsNextBot()) and self.Player:GetObserverMode() ~= OBS_MODE_ROAMING then
        local tr = {
            start = target:WorldSpaceCenter(),
            endpos = target:WorldSpaceCenter() - (view.angles:Forward() * 150),
            filter = {target}
        }
        local trace = util.TraceLine(tr)
        
        view.origin = trace.HitPos + trace.HitNormal * 10
    end
end

function PLAYER:PostThink()  
    if SERVER then
        if self.Player:IsOnFire() then
            self.Player:Extinguish()
        end
        
        if self.Player:GetObserverMode() ~= OBS_MODE_ROAMING then
            local target = self.Player:GetObserverTarget()
            if not IsValid(target) or (target.Alive and not target:Alive()) or (target.Team and target:Team() == TEAM_SPECTATOR) then
                self.Player:StripWeapons()
                self.Player:Spectate(OBS_MODE_ROAMING)
                self.Player:SpectateEntity(NULL)
            end
        end
    end
end

local lobbyMenu_ColorMod = {
    ["$pp_colour_contrast"] = 1,
    ["$pp_colour_colour"] = 0,
    ["$pp_colour_addr"] = 0,
    ["$pp_colour_addg"] = 0,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = 0,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0,
    ["$pp_colour_mulb"] = 0
}
local Dead_ColorMod = {
    ["$pp_colour_contrast"] = 1,
    ["$pp_colour_colour"] = 0.1,
    ["$pp_colour_addr"] = 0,
    ["$pp_colour_addg"] = 0,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = 0,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0,
    ["$pp_colour_mulb"] = 0
}
local spec_overlay = Material("zm_overlay.png", "smooth unlitgeneric nocull")
function PLAYER:RenderScreenspaceEffects()
    if not GAMEMODE:GetRoundActive() and IsValid(GAMEMODE.PlayerLobby) then
        DrawColorModify(lobbyMenu_ColorMod)
    else
        if GAMEMODE.ColorModEnabled and self.Player.m_flEnd and self.Player.m_flEnd >= CurTime() then
            local v = self.Player.m_flEnd - CurTime()
            Dead_ColorMod["$pp_colour_colour"] = 1 - (math.Clamp(v / 2.5, 0, 1) - 0.1)
            DrawColorModify(Dead_ColorMod)
        end
        
        render.SetMaterial(spec_overlay)
        render.DrawScreenQuad()
    end
end

player_manager.RegisterClass("player_spectator", PLAYER, "player_basezm")