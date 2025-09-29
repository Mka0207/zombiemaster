hook.Add("OnEntityCreated", "removing", function(ent)
    if ent:GetName() == "zm_trap_cannisters" then
        ent:Remove()
    end
end)

hook.Add("OnEntityCreated", "FixNextbotStepHeight", function(ent)
    if IsValid(ent) and ent.IsNextBot and ent:IsNextBot() and ent.loco then
        timer.Simple( 0, function()
			if !IsValid(ent) then return end
			if ent.loco == nil then return end
			
			ent.loco:SetJumpHeight( 22 )
			ent.loco:SetStepHeight( 22 )
		end)
    end
end)