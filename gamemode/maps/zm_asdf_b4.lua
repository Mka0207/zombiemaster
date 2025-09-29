hook.Add("OnEntityCreated", "disablegman", function(ent)
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        
        if ent:GetClass() == "prop_dynamic" and ent:GetModel() == "models/gman.mdl" then
            ent:Remove()
        end
        
        if (ent:IsNPC() or ent:IsNextBot()) and ent:GetRenderMode() == RENDERMODE_NONE and ent:GetClass() == "npc_fastzombie" then            
            local CSModel = ents.Create("npc_overridemodel")
            CSModel:SetParent(ent)
            CSModel:SetOwner(ent)
            CSModel:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL))
            CSModel:SetModel("models/gman.mdl")
            CSModel:Spawn()
        end
    end)
end)