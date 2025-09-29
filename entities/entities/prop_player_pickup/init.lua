AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:RestorePickupParameters(object, objectphys)
    object.bHeldBy = nil
    object.bIsHolding = false
    
	local owner = self:GetOwner()
	if owner:IsValid() and owner:IsPlayer() then
        owner:SimulateGravGunDrop(object)
    end
    
    if object._OldCG ~= nil then
        object:SetCollisionGroup(object._OldCG)
        object._OldCG = nil
    end

    local objectphys = object:GetPhysicsObject()
    if objectphys:IsValid() then
        objectphys:ClearGameFlag(bit.bor(FVPHYSICS_NO_IMPACT_DMG, FVPHYSICS_NO_NPC_IMPACT_DMG, FVPHYSICS_PLAYER_HELD))
        objectphys:EnableGravity(true)
        
        if object._OriginalMass  ~= nil then
            objectphys:SetMass(object._OriginalMass)
            object._OriginalMass = nil
        end
        
        if object._OriginalEnableDrag ~= nil then
            objectphys:EnableDrag(object._OriginalEnableDrag)
            object._OriginalEnableDrag = nil
        end
        
        for i=0, object:GetPhysicsObjectCount() - 1 do
            local phys = object:GetPhysicsObjectNum(i)
            local ld, ad = phys:GetDamping()
            if object.m_savedMass ~= nil and object.m_savedMass[i] then
                phys:SetMass(object.m_savedMass[i])
                object.m_savedMass[i] = nil
            end
            
            if object.m_savedRotDamping ~= nil and object.m_savedRotDamping[i] then
                phys:SetDamping(ld, object.m_savedRotDamping[i])
                object.m_savedRotDamping[i] = nil
            end
        end

        object:CollisionRulesChanged()
    end
end

function ENT:ApplyPickupParameters(object, objectphys)
	local owner = self:GetOwner()
	if owner:IsValid() and owner:IsPlayer() then
        object.bHeldBy = owner
        owner:SimulateGravGunPickup(object)
    end

    if object._OldCG == nil then
        object._OldCG = object:GetCollisionGroup()
    end
    object:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    object.bIsHolding = true
            
    if objectphys:IsValid() then
        objectphys:AddGameFlag(bit.bor(FVPHYSICS_NO_IMPACT_DMG, FVPHYSICS_NO_NPC_IMPACT_DMG, FVPHYSICS_PLAYER_HELD))
        
        local count = object:GetPhysicsObjectCount()
        local damping = 10
        local flFactor = count / 7.5;
        if flFactor < 1 then
            flFactor = 1.0
        end
        
        for i=0, count - 1 do
            local phys = object:GetPhysicsObjectNum(i)
            local ld, ad = phys:GetDamping()
            
            object.m_savedMass = {}
            object.m_savedMass[i] = phys:GetMass()
            
            object.m_savedRotDamping = {}
            object.m_savedRotDamping[i] = ad
            
            phys:SetMass(REDUCED_CARRY_MASS / flFactor)
            phys:SetDamping(ld, damping)
        end
        
        objectphys:EnableGravity(false)
        
        object._OriginalMass = object._OriginalMass or objectphys:GetMass()
        object._OriginalEnableDrag = object._OriginalEnableDrag ~= nil and object._OriginalEnableDrag or objectphys:IsDragEnabled()
        objectphys:SetMass(REDUCED_CARRY_MASS)
        objectphys:EnableDrag(false)
    end
    
    object:CollisionRulesChanged()
end

function ENT:Initialize()
    self:DrawShadow(false)
    self:SetNotSolid(true)

    local owner = self:GetOwner()
    if owner:IsValid() and owner:IsPlayer() then
        owner.player_pickup = self
        owner.CarryProp = self:GetObject()

        owner:DrawWorldModel(false)

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
        end
    end

    local object = self:GetObject()
    if object:IsValid() then
        local children = object:GetChildren()
        for _, child in ipairs(children) do
            if not child:IsValid() then continue end
            self:ApplyPickupParameters(child, child:GetPhysicsObject())
        end

        self:ApplyPickupParameters(object, object:GetPhysicsObject())
    end

    self.m_NextFireDamage = CurTime() + 2
    self.iAllowDrop = CurTime() + 0.25
end

function ENT:OnRemove()
	if self.Removing then return end
	self.Removing = true

	local owner = self:GetOwner()
	if owner:IsValid() then
        owner.CarryProp = NULL
		owner:DrawWorldModel(true)
		owner:DrawViewModel(true)
        
        local wep = owner:GetActiveWeapon()
        if wep:IsValid() then
            wep:SendWeaponAnim(ACT_VM_DRAW)
            
            timer.Remove(tostring(self).."_HolsterTimer")
            
            wep:SetNextPrimaryFire(CurTime() + wep:SequenceDuration())
            wep:SetNextSecondaryFire(CurTime() + wep:SequenceDuration())
        end
	end

	local object = self:GetObject()
	if object:IsValid() then
        object:SetOwner(NULL)
        
        self:RestorePickupParameters(object, object:GetPhysicsObject())
        
        local children = object:GetChildren()
        for _, child in ipairs(children) do
            if not child:IsValid() then continue end
            self:RestorePickupParameters(child, child:GetPhysicsObject())
        end

		object._LastDroppedBy = owner
		object._LastDropped = CurTime()
	end
end

local ShadowParams = {secondstoarrive = 0.01, maxangular = 1000, maxangulardamp = 10000, maxspeed = 500, maxspeeddamp = 1000, dampfactor = 0.65, teleportdistance = 0}
function ENT:Think()
	local ct = CurTime()
    
	local frametime = ct - (self.LastThink or ct)
	self.LastThink = ct

	local object = self:GetObject()
	local owner = self:GetOwner()
	if not object:IsValid() or not owner:IsValid() or not owner:Alive() or not owner:IsSurvivor() then
		self:Remove()
		return
	end

	local objectphys = object:GetPhysicsObject()
	if object:GetMoveType() ~= MOVETYPE_VPHYSICS or not objectphys:IsValid() or owner:GetGroundEntity() == object then
        self:Remove()
		return
	end

	local shootpos = owner:GetShootPos()
	local nearestpoint = object:NearestPoint(shootpos)
	if nearestpoint:DistToSqr(shootpos) >= 8196 then
		self:Remove()
		return
	end
    
    if not objectphys:IsMotionEnabled() or not objectphys:IsCollisionEnabled() then
		self:Remove()
		return
    end
    
    if object:IsOnFire() and (self.m_NextFireDamage or 0) < CurTime() then
        self.m_NextFireDamage = CurTime() + 2
        
        local d = DamageInfo()
        d:SetDamage(4)
        d:SetAttacker(ent)
        d:SetDamageType(DMG_BURN)

        owner:TakeDamageInfo(d)
    end

	objectphys:Wake()

	if owner:KeyDown(IN_USE) and self.iAllowDrop < ct then
		object:SetPhysicsAttacker(owner)
		self:Remove()
		return
	else
        local obbcenter = object:OBBCenter()
        local objectpos = shootpos + owner:GetAimVector() * 48
        objectpos = objectpos - obbcenter.z * object:GetUp()
        objectpos = objectpos + obbcenter.y * object:GetRight()
        objectpos = objectpos - obbcenter.x * object:GetForward()
        self.ObjectPosition = objectpos
        
        local pref_angle = owner:GetPreferredCarryAngles(object)
        if pref_angle then
            local mat = Matrix()
            mat:SetAngles(owner:EyeAngles())
            mat:Rotate(owner:WorldToLocalAngles(pref_angle))
            ShadowParams.angle = mat:GetAngles()
        else
            -- Necrossin saved my ass here - FMX
            if not self.ObjectLocalAngles then
                self.ObjectLocalPos, self.ObjectLocalAngles = WorldToLocal(vector_origin, object:GetAngles(), vector_origin, owner:EyeAngles())
            end
            self.ObjectPos, self.ObjectAngles = LocalToWorld(vector_origin, self.ObjectLocalAngles, vector_origin, owner:EyeAngles()) 
            ShadowParams.angle = self.ObjectAngles
        end
        
        objectphys:SetVelocityInstantaneous(vector_origin)
        
		ShadowParams.pos = self.ObjectPosition
		ShadowParams.deltatime = frametime
        objectphys:ComputeShadowControl(ShadowParams)
	end

	object:SetPhysicsAttacker(owner)
	object.LastHeld = CurTime()
    
	self:NextThink(ct)
	return true
end