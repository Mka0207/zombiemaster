hook.Add("OnEntityCreated", "fixobjectives", function(ent)
    if ent:GetClass() == "func_tracktrain" then
        local this = ent
        timer.Simple(0, function()
            if not IsValid(this) then return end
            if this:GetName() == "train" then
                this:SetSaveValue("m_flBlockDamage", 100)
            end
        end)
    elseif ent:GetClass() == "prop_physics" then
        local this = ent
        timer.Simple(0, function()
            if not IsValid(this) then return end
            if this:GetName() == "suitcase_props" then
                this:SetNW2Bool("bObjectiveHalos", true)
            end
        end)
    end
end)

hook.Add("EntityRemoved", "fixobjectives", function(ent)
    if ent:GetClass() == "prop_physics" and ent:GetName() == "suitcase_props" then
        ent:SetNW2Bool("bObjectiveHalos", false)
    end
end)