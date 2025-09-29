hook.Add("OnEntityCreated", "OnEntityCreated.FixLegsObjective", function(ent)
    local this = ent
    timer.Simple(0, function()
        if not IsValid(this) then return end
        if this:GetName() == "obj_leg" then
            if this:GetClass() == "prop_dynamic" then
                this:PhysicsInit(SOLID_VPHYSICS)
                this:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
            end
            
            if this:GetClass() == "func_physbox" then
                this:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
            end
        end
    end)
end)