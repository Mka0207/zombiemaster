NPC.Class = ""
NPC.Name = ""
NPC.Description = ""
NPC.Icon = ""
NPC.IconSmall = ""
NPC.SortIndex = 0

NPC.Health = 0
NPC.Flag = 0
NPC.Cost = 0
NPC.PopCost = 0

NPC.Hidden = true
NPC.DelaySetModel = false

NPC.Model = "models/zombie/zm_classic.mdl"
NPC.SkinNum = 3

function NPC:SetupModel(npc)
    if not self.Model then return end
    
    local mdl = ""
    if type(self.Model) == "table" then
        local rand = math.Round(util.SharedRandom(npc:EntIndex().."_RandModel", 1, #self.Model))
        mdl = self.Model[rand]
    else
        mdl = self.Model
    end
    
    if (self.SkinNum or 0) > 0 then
        local rand = math.Round(util.SharedRandom(npc:EntIndex().."_RandSkin", 0, self.SkinNum))
        npc:SetSkin(rand)
    end
    
    if self.Material ~= nil then
        if istable(self.Material) then
            if #self.Material <= 0 then return end
            npc:SetSubMaterial(0, self.Material[util.SharedRandom(npc:EntIndex().."_RandMaterial", 0, #self.Material)])
        elseif self.Material ~= "" then
            npc:SetSubMaterial(0, self.Material)
        end
    end
    
    if self.DelaySetModel then
        npc:SetModelDelayed(0, mdl)
    else
        npc:SetModel(mdl)
    end
    
    npc.CurrentModel = mdl
end