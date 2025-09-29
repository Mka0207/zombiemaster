local meta = FindMetaTable("Player")

function meta:ScoreAward(team_index, val)
    if not self.ScoreAwardT then self.ScoreAwardT = {} end
    local team = self.ScoreAwardT
    if not team[team_index] then team[team_index] = {} end

    local score_a = team[team_index]
    if not score_a[val] then score_a[val] = 0 end
    return score_a[val]
end

function meta:ScoreAward_Add(team_index, val, num)
    if not self.ScoreAwardT then self.ScoreAwardT = {} end
    local team = self.ScoreAwardT

    if not team[team_index] then team[team_index] = {} end
    local get = team[team_index]

    self.ScoreAwardT[team_index][val] = (self.ScoreAwardT[team_index][val] or 0) + num
end

function GM:GetVaultFile(pl)
	local steamid = pl:SteamID64() or "null"
	return "zombiemaster_vault/"..steamid..".txt"
end

function GM:SaveAllVaults()
	for _, pl in pairs(player.GetHumans()) do
		self:SaveVault(pl)
	end
end

function GM:LoadVault(pl)
	local filename = self:GetVaultFile(pl)
	if file.Exists(filename, "DATA") then
		local contents = file.Read(filename, "DATA")
		if contents and #contents > 0 then
			if contents then
				if pl.ScoreAwardT then
					pl.ScoreAwardT[TEAM_ZOMBIEMASTER] = contents.ScoreAward_Z or {}
					pl.ScoreAwardT[TEAM_SURVIVOR] = contents.ScoreAward_S or {}
				end
			end
		end
	end
end

function GM:SaveVault(pl)
	local cool = pl.ScoreAwardT
	local tosave = {
		ScoreAward_Z = cool and cool[TEAM_ZOMBIEMASTER] or {},
		ScoreAward_S = cool and cool[TEAM_SURVIVOR] or {}
	}

	local filename = self:GetVaultFile(pl)
	file.CreateDir(string.GetPathFromFilename(filename))
	file.Write(filename, util.TableToJSON(tosave))
end