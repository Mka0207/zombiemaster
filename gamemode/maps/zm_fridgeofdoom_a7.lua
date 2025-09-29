hook.Add("OnEntityCreated", "OnEntityCreated.FixLag", function(ent)
    if (ent:IsWeapon() or (ent.IsAmmo and ent:IsAmmo())) and not ent.Dropped then
        local this = ent
        timer.Simple(0, function()
            if not IsValid(this) then return end
            
            local phys = this:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
            end
        end)
    end	
end)


local fridge_map_id = 1621
hook.Add("OnEntityCreated", "OnEntityCreated.ScaleFridgeHealth", function(ent)
	
	if ent:GetClass() == "func_physbox" then
		timer.Simple(0, function()
			if not IsValid(ent) then return end
			if ent:MapCreationID() != fridge_map_id then return end
			
			local NumPlayers = team.NumPlayers(TEAM_SURVIVOR) + team.NumPlayers(TEAM_SPECTATOR)
			local health = math.Remap( math.max( NumPlayers, 15 ), 15, 128, 3500, 28000  )
			
			ent:SetHealth( health )
			ent:SetMaxHealth( health )
			
		end)
	end
	
end)