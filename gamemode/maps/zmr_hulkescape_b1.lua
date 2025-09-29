hook.Add("OnEntityCreated", "hulkfix", function(ent)
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        
        if ent:GetClass() == "prop_dynamic" and IsValid(ent:GetParent()) and ent:GetParent():IsNextBot() then
            ent:Remove()
        end
        
        /*if (ent:IsNPC() or ent:IsNextBot()) and ent:GetRenderMode() == RENDERMODE_NONE and ent:GetClass() == "npc_fastzombie" then            
            local CSModel = ents.Create("npc_overridemodel")
            CSModel:SetParent(ent)
            CSModel:SetOwner(ent)
            CSModel:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL))
            CSModel:SetModel("models/gman.mdl") // add fast zombie model here later
            CSModel:Spawn()
        end*/
    end)
end)