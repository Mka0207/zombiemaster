/*
	Start of the death message stuff.
*/

include("vgui/dexnotificationslist.lua")

local function CreateDeathNotify()
    if IsValid(GAMEMODE.TopNotificationHUD) then return end
    
    GAMEMODE.TopNotificationHUD = vgui.Create("DEXNotificationsList")
	GAMEMODE.TopNotificationHUD:SetAlign(RIGHT)
    GAMEMODE.TopNotificationHUD.PerformLayout = function(pan)
        pan:SetSize(ScrW() * 0.4, ScrH() * 0.6)
        pan:AlignTop(16 * BetterScreenScale())
        pan:AlignRight()
    end
	GAMEMODE.TopNotificationHUD.TopNotice = true
	GAMEMODE.TopNotificationHUD:InvalidateLayout()
	GAMEMODE.TopNotificationHUD:ParentToHUD()
end
hook.Add("InitPostEntity", "CreateDeathNotify", CreateDeathNotify)

net.Receive("PlayerKilledByNPC", function(length)
    local victim = net.ReadEntity()
    if not IsValid(victim) then return end
    
    local attacker = net.ReadEntity()
    local inflictor = net.ReadString()
    local attackername = ""
    if attacker:IsValid() and attacker.FriendlyName then
        attackername = attacker.FriendlyName
    else
        for name, tab in ipairs(GAMEMODE:GetZombieTables()) do
            if tab.Class == inflictor then
                attackername = tab.Name
                break
            end
        end
    end

    MsgC(team.GetColor(TEAM_ZOMBIEMASTER), attackername, color_white, " killed ", team.GetColor(victim:Team()), victim:Name(), color_white, "\n")
    
    hook.Call("AddDeathNotice", GAMEMODE, {highlight = victim == MySelf}, team.GetColor(TEAM_ZOMBIEMASTER), attackername, " ", {killicon = "default"}, " ", victim)
end)

net.Receive("PlayerKilledByPlayer", function(length)
	local victim = net.ReadEntity()
	local inflictor = net.ReadString()
	local attacker = net.ReadEntity()

	if not IsValid(attacker) or not IsValid(victim) then return end

    MsgC(team.GetColor(attacker:Team()), attacker:Name(), color_white, " killed ", team.GetColor(victim:Team()), victim:Name(), color_white, " with ", COLOR_YELLOW, inflictor, "\n")

    hook.Call("AddDeathNotice", GAMEMODE, {highlight = victim == MySelf}, attacker, " ", {killicon = inflictor}, " ", victim)
end)

net.Receive("PlayerKilledSelf", function(length)
	local victim = net.ReadEntity()
	if not IsValid(victim) then return end
    
    MsgC(team.GetColor(victim:Team()), victim:Name(), color_white, " died to ", team.GetColor(TEAM_UNASSIGNED), translate.Get("killmessage_something"), "\n")
    
    hook.Call("AddDeathNotice", GAMEMODE, {highlight = victim == MySelf}, team.GetColor(TEAM_UNASSIGNED), translate.Get("killmessage_something"), " ", {killicon = "default"}, " ", victim)
end)

net.Receive("PlayerKilled", function(length)
	local victim = net.ReadEntity()
	local inflictor = net.ReadString()
	local attacker = "#" .. net.ReadString()
	if not IsValid(victim) then return end
    
    local attackername = language.GetPhrase(attacker)
    if attackername == attacker then
        attackername = translate.Get("killmessage_something")
    end
    
    MsgC(team.GetColor(victim:Team()), victim:Name(), color_white, " was killed by ", team.GetColor(TEAM_UNASSIGNED), attackername, "\n")
    
    hook.Call("AddDeathNotice", GAMEMODE, {highlight = victim == MySelf}, team.GetColor(TEAM_UNASSIGNED), attackername, " ", {killicon = "default"}, " ", victim)
end)

/*---------------------------------------------------------
   Name: gamemode:AddDeathNotice( vararg )
   Desc: Adds an death notice entry
---------------------------------------------------------*/
function GM:AddDeathNotice(...)
	if not (self.TopNotificationHUD and self.TopNotificationHUD:IsValid()) then return end
    return self.TopNotificationHUD:AddNotification(...)
end
