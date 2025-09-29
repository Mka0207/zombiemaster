include("shared.lua")

ENT.RenderGroup = RENDERGROUP_OTHER

ENT.AnimTime = 0.25

local IgnoreFadeOut = {
	["models/props_junk/plasticcrate01a.mdl"]=true,
	["models/props_c17/lamp_standard_off01.mdl"]=true,
	["models/items/item_item_crate.mdl"]=true
}

local function FadeOutCarriedObject(self)
	if self.fadeAlpha ~= 0.425 then
		self.fadeAlpha = (self.fadeAlpha or 1) - (1 * FrameTime())
		self.fadeAlpha = math.Clamp(self.fadeAlpha, 0.425, 1)
	end
	
    render.OverrideDepthEnable(true, true)
    self:SetAlpha(self.fadeAlpha * 255)
    self:DrawModel()
    render.OverrideDepthEnable(false, false)
end

local function FadeInCarriedObject(self)
	if self.fadeAlpha ~= 1 then
		self.fadeAlpha = (self.fadeAlpha or 1) + (1 * FrameTime())
		self.fadeAlpha = math.Clamp(self.fadeAlpha, 0.425, 1)
	else
        if self.PreHoldAlpha ~= nil then
            self:SetAlpha(self.PreHoldAlpha)
        end
        if self.PreHoldRenderMode ~= nil then
            self:SetRenderMode(self.PreHoldRenderMode)
        end
		self.RenderOverride = nil
        self.PreHoldAlpha = nil
        self.PreHoldRenderMode = nil
        return
	end
    
    render.OverrideDepthEnable(true, true)
    self:SetAlpha(self.fadeAlpha * 255)
    self:DrawModel()
    render.OverrideDepthEnable(false, false)
end

function ENT:OnRemove()
	local owner = self:GetOwner()
    if not (owner and owner:IsValid()) then return end
    
    owner.CarryProp = NULL
    
	if owner == MySelf then
        owner:DrawViewModel(true)

		local wep = owner:GetActiveWeapon()
		if wep:IsValid() then
            wep:SendWeaponAnim(ACT_VM_DRAW)
            timer.Remove(tostring(self).."_HolsterTimer")
		end
	end
    
    local object = self:GetObject()
    if not (object and object:IsValid()) then return end
    
    object.bHeldBy = nil
    object.bIsHolding = false
    
    if owner == MySelf and not IgnoreFadeOut[object:GetModel()] then
        if object:GetClass() == "env_sprite" then return end
        
        object.RenderOverride = FadeInCarriedObject
        
        local children = object:GetChildren()
        for _, child in pairs(children) do
            if not child:IsValid() or child:GetClass() == "env_sprite" then continue end
            child.RenderOverride = FadeInCarriedObject
            child.bIsHolding = false
        end
    end
end

function ENT:Initialize()
	self.Created = CurTime()

    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    
    owner.player_pickup = self
    owner.CarryProp = self:GetObject()
    
    if owner == MySelf then
        local wep = owner:GetActiveWeapon()
        if wep:IsValid() then
            wep:SendWeaponAnim(ACT_VM_HOLSTER)
            
            if wep:SelectWeightedSequence(ACT_VM_HOLSTER) == -1 then
                owner:DrawViewModel(false)
            else
                timer.Create(tostring(self).."_HolsterTimer", wep:SequenceDuration(), 1, function()
                    if not IsValid(self) or not IsValid(owner) then return end
                    owner:DrawViewModel(false)
                end)
            end
            
            wep:SetNextPrimaryFire(CurTime() + wep:SequenceDuration())
            wep:SetNextSecondaryFire(CurTime() + wep:SequenceDuration())
        end
    end
    
    local object = self:GetObject()
    if not IsValid(object) then return end
    
    if owner == MySelf then
        local tr = util.TraceLine( {
            start = owner:EyePos(),
            endpos = object:WorldSpaceCenter(),
            filter = function( ent ) return ent == object end
        } )
        
        local data = util.GetSurfaceData(tr.SurfaceProps)
        if data and data.impactHardSound and data.impactHardSound ~= "" then
            object:EmitSound(data.impactHardSound)
        end
    end
    
    object.bHeldBy = owner
    object.bIsHolding = true

    if owner == MySelf and not IgnoreFadeOut[object:GetModel()] then
        if object:GetClass() == "env_sprite" then return end
        
        object.PreHoldAlpha = object.PreHoldAlpha or object:GetAlpha()
        object.PreHoldRenderMode = object.PreHoldRenderMode or object:GetRenderMode()
        object:SetRenderMode(RENDERMODE_TRANSALPHA)
        object.RenderOverride = FadeOutCarriedObject
        
        local children = object:GetChildren()
        for _, child in pairs(children) do
            if not child:IsValid() or child:GetClass() == "env_sprite" then continue end
            
            child.PreHoldAlpha = child.PreHoldAlpha or child:GetAlpha()
            child.PreHoldRenderMode = child.PreHoldRenderMode or child:GetRenderMode()
            child:SetRenderMode(RENDERMODE_TRANSALPHA)
            child.RenderOverride = FadeOutCarriedObject
            child.bIsHolding = true
        end
    end
end
