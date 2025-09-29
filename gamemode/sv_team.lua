-- Only track undead or human or spectator teams.
if not P_TeamLoaded then
	TeamSizes = {}
	TeamPlayers = {}
	InitPlayerTeams = {}

	P_TeamLoaded = true
end

hook.Add("Initialize", "team.Initialize", function()
	TeamSizes[TEAM_SURVIVOR] = 0
	TeamSizes[TEAM_ZOMBIEMASTER] = 0
	TeamSizes[TEAM_SPECTATOR] = 0

	TeamPlayers[TEAM_SURVIVOR] = {}
	TeamPlayers[TEAM_ZOMBIEMASTER] = {}
	TeamPlayers[TEAM_SPECTATOR] = {}
end)

function team.NumPlayers(index)
	return TeamSizes[index] or 0
end

function team.GetPlayers(index)
	return table.Copy(TeamPlayers[index] or {})
end

function team.GetPlayersFastMutable(index)
	return TeamPlayers[index] or {}
end

local M_Player = FindMetaTable("Player")
local Old_P_Team = M_Player.Team
function GetPlayerTeam(pl)
	return InitPlayerTeams[pl] or Old_P_Team(pl)
end

local table_insert = table.insert
local table_RemoveByValue = table.RemoveByValue

local function RemoveFromTeam( pl )
	local t = rawget(InitPlayerTeams,pl)
	if t and TeamSizes[t] then
		TeamSizes[t] = TeamSizes[t]-1
		table_RemoveByValue(TeamPlayers[t],pl)
		rawset(InitPlayerTeams,pl,nil)
	end
end

hook.Add("PlayerChangedTeam", "team.PlayerChangedTeam", function(pl, oldteam, newteam)
	if rawget(InitPlayerTeams,pl) ~= newteam then
		RemoveFromTeam(pl)

		if TeamSizes[newteam] then
			TeamSizes[newteam] = TeamSizes[newteam] + 1
			table_insert(TeamPlayers[newteam], pl)
		end
		rawset(InitPlayerTeams, pl, newteam)
	end
end)
hook.Add( "PlayerDisconnected", "team.PlayerDisconnected", RemoveFromTeam)