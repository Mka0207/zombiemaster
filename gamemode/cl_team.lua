-- Only track undead or human or spectator teams.
local TeamSizes = {}
local TeamPlayers = {}

hook.Add("Initialize", "LoadTeamData", function()
    TeamSizes[TEAM_SURVIVOR] = 0
    TeamSizes[TEAM_ZOMBIEMASTER] = 0
    TeamSizes[TEAM_SPECTATOR] = 0

    TeamPlayers[TEAM_SURVIVOR] = {}
    TeamPlayers[TEAM_ZOMBIEMASTER] = {}
    TeamPlayers[TEAM_SPECTATOR] = {}
end)

local NextUpdateTeams = 0
local InitPlayerTeams = {}

local function RemoveFromTeam( pl )
	local t = rawget(InitPlayerTeams,pl)
	if t and TeamSizes[t] then
		TeamSizes[t] = TeamSizes[t]-1
		table.RemoveByValue(TeamPlayers[t],pl)
		rawset(InitPlayerTeams,pl,nil)
	end
end

local function UpdatePlayerTeams()
	for i, pl in ipairs(player.GetAllNoCopy()) do
        local t = pl:Team()
        if InitPlayerTeams[pl]~=t then
            local ot = InitPlayerTeams[pl]
            RemoveFromTeam(pl)
            InitPlayerTeams[pl] = t
            if TeamSizes[t] then
                TeamSizes[t] = TeamSizes[t]+1
                table.insert(TeamPlayers[t],pl)
            end
            hook.Call("OnPlayerChangedTeam",GAMEMODE,pl,ot,t)
        end
	end
end

function team.NumPlayers(index)
	if NextUpdateTeams<FrameNumber() then
		NextUpdateTeams = FrameNumber()+30
		UpdatePlayerTeams()
	end
	return TeamSizes[index] or 0
end

function team.GetPlayers(index)
	if NextUpdateTeams<FrameNumber() then
		NextUpdateTeams = FrameNumber()+30
		UpdatePlayerTeams()
	end
	return TeamPlayers[index] or {}
end

function GetPlayerTeam(pl)
    return InitPlayerTeams[pl] or pl:Team()
end

hook.Add( "PlayerDisconnected", "team.PlayerDisconnected", function (pl)
	RemoveFromTeam(pl)
end)

concommand.Add("zm_list_team", function(sender, command, arguments)
	if NextUpdateTeams<FrameNumber() then
		NextUpdateTeams = FrameNumber()+30
		UpdatePlayerTeams()
	end

	print("Teams:")
	for teamid, pls in pairs(TeamPlayers) do
		print("Team["..tostring(teamid).."]="..tostring(TeamSizes[teamid]))
		for i, pl in pairs(pls) do
			print("PL["..tostring(i).."]="..(IsValid(pl) and pl:Nick() or "nil"))
		end
	end
end)

timer.Create("zs_update_teams", 0, 0, function()
	if NextUpdateTeams<FrameNumber() then
		NextUpdateTeams = FrameNumber()+30
		UpdatePlayerTeams()
	end
end)