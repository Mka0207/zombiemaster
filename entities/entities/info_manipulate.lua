AddCSLuaFile()
DEFINE_BASECLASS("info_node_base")

ENT.Base = "info_node_base"
ENT.Type = "anim"
ENT.Model = Model("models/manipulatable.mdl")

if CLIENT then
    ENT.GlowMat = Material("models/orange")
    ENT.GlowColor = Color( 248, 124, 0 )
    ENT.GlowSize = 128
end

if CLIENT then return end

function ENT:InputToggle()
    BaseClass.InputToggle(self)
    for _, trigger in pairs(ents.FindByClass("info_manipulate_trigger")) do    
        if trigger:GetParent() == self then
            trigger:Remove()
        end
    end
end

function ENT:InputHide()
    BaseClass.InputHide(self)
    for _, trigger in pairs(ents.FindByClass("info_manipulate_trigger")) do    
        if trigger:GetParent() == self then
            trigger:Remove()
        end
    end
end

function ENT:Trigger(activator)
    BaseClass.Trigger(self, activator)
        
    self:Input("OnPressed", activator, self)
        
    for _, trigger in pairs(ents.FindByClass("info_manipulate_trigger")) do    
        if trigger:GetParent() == self then
            trigger:Remove()
        end
    end

    self.m_iTrapCount = 0
    
    local ply = GAMEMODE:FindZM()
    if ply and ply:IsValid() then
        ply.m_TriggerCount = (ply.m_TriggerCount or 0) + 1
    end
end