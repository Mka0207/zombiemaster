hook.Add("OnEntityCreated", "OnEntityCreated.FixLag", function(ent)
    if IsValid(ent) and ent:GetClass() == "prop_ragdoll" then
       SafeRemoveEntity( ent )
    end	
	
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



