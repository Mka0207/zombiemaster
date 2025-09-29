ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetObjectHealth(health)
    self:SetDTFloat(0, health)
    if health <= 0 and not self.Destroyed then
        self.Destroyed = true

        local ent = ents.Create("prop_physics")
        if ent:IsValid() then
            ent:SetModel(self:GetModel())
            ent:SetMaterial(self:GetMaterial())
            ent:SetAngles(self:GetAngles())
            ent:SetPos(self:GetPos())
            ent:SetSkin(self:GetSkin() or 0)
            ent:SetColor(self:GetColor())
            ent:Spawn()
            ent:Fire("break", "", 0)
            ent:Fire("kill", "", 0.1)
        end
    end
end

function ENT:GetObjectHealth()
    return self:GetDTFloat(0)
end

function ENT:SetMaxObjectHealth(health)
    self:SetDTFloat(1, health)
end

function ENT:GetMaxObjectHealth()
    return self:GetDTFloat(1)
end

function ENT:SetObjectOwner(ent)
    self:SetDTEntity(0, ent)
end

function ENT:GetObjectOwner()
    return self:GetDTEntity(0)
end

function ENT:SetItemClass(class)
    self:SetDTString(0, class)
end

function ENT:GetItemClass()
    return self:GetDTString(0)
end

function ENT:SetItemCount(count)
    self:SetDTInt(0, count)
end

function ENT:GetItemCount()
    return self:GetDTInt(0)
end

function ENT:SetLarge(b)
    self:SetDTBool(0, b)
end

function ENT:GetLarge()
    return self:GetDTBool(0)
end

function ENT:IsAmmo(class)
    return string.find(class, "item_ammo") or string.find(class, "item_box")
end