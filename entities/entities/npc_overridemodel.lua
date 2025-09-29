AddCSLuaFile()

ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_OPAQUE

local function NPCRenderOverride(self)
    if self.DrawingSilhouette or GAMEMODE:CallZombieFunction(self, "PreDraw") then return end
    self.OverrideModel:DrawModel()
    GAMEMODE:CallZombieFunction(self, "PostDraw")
end
function ENT:Initialize()
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL, EF_PARENT_ANIMATES))
    
    self.Time = 0
    self.LifeTime = 0
    
    local owner = self:GetOwner()
    if owner:IsValid() and not owner:IsNextBot() then
		owner.OverrideModel = self
			
		owner.OldRenderOverride = owner.RenderOverride
		owner.RenderOverride = NPCRenderOverride
			
		owner.OldCurrentModel = owner.CurrentModel
		owner.CurrentModel = self:GetModel()
    end
end

function ENT:OnRemove()
    local owner = self:GetOwner()
    if owner:IsValid() and not owner:IsNextBot() then
        owner.OldCurrentModel = nil
        owner.CurrentModel = owner.OldCurrentModel
        owner.OverrideModel = nil
        owner.OldRenderOverride = nil
        owner.RenderOverride = owner.OldRenderOverride
    end
end

if not CLIENT then return end

function ENT:Draw()
	local owner = self:GetOwner()
    if owner:IsValid() and owner:IsNextBot() then
		self:DrawModel()
	end
end