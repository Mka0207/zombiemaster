AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Spawnable = false

ENT.AdminSpawnable = false

function ENT:Draw()
end

function ENT:Initialize()
	if SERVER then
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_NONE )
        self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		self:DrawShadow( false )
    else
        self.AmbientSound = CreateSound(self, "wick/weapons/l4d1/molotov/fire_idle_loop_1.wav")
	end
    for i = 1, 10 do
        ParticleEffect( "molotov_groundfire", self:GetPos() + Vector(math.random(-80, 80), math.random(-80, 80), 0), self:GetAngles() )
    end
end

function ENT:Think()
    if SERVER then return end
	self.AmbientSound:Play()
end

function ENT:OnRemove()
	self:EmitSound("TFA_L4D1_MOLOTOV.IGNITE")
    
    if SERVER then return end
    self.AmbientSound:Stop()
end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end