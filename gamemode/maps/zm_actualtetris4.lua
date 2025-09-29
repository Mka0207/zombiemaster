hook.Add("OnEntityCreated", "OnEntityCreated.ScaleBlockHealth", function(ent)

	if ent:GetClass() == "func_physbox" then
		timer.Simple(0, function()
			if not IsValid(ent) then return end

			local max = ent:GetMaxHealth() or 100

			local NumPlayers = team.NumPlayers(TEAM_SURVIVOR) + team.NumPlayers(TEAM_SPECTATOR)
			local health = math.Remap( math.max( NumPlayers, 15 ), 15, 128, max, max * 3  )

			ent:SetHealth( health )
			ent:SetMaxHealth( health )

		end)
	end

end)

GM.ForceSingleZM = true