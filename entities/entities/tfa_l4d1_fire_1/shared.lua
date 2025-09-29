AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.Damage = 1

function ENT:Draw()
end

function ENT:Initialize()
	self.Damage = 1
	self:SetNWBool("extinguished",false)
	if SERVER then
        self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_NONE )
		self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
		self:DrawShadow( false )
	end
	self:NextThink( CurTime() )
end

function ENT:Think()
	if SERVER then
		for k, v in ipairs( ents.FindInSphere( self:GetPos(), 150 ) ) do
			if v:IsPlayer() and self:GetOwner() == v and not v:IsOnFire() then
                v:Ignite( 2 )
			elseif v:IsNPC() or v:IsNextBot() then
                v:TakeDamage( 2, self:GetOwner(), self )
				v:Ignite( 30 )
            elseif (v:GetInternalVariable("m_explodeDamage") or 0) > 0 or (v:GetInternalVariable("m_explodeRadius") or 0) > 0 then
                v:TakeDamage( 5, self:GetOwner(), self )
                v:Ignite( 2 )
			end
		end
	end
	self:NextThink( CurTime() + math.Rand( 0.2, 0.7 ) )
end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end