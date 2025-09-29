ENT.Base = "base_anim"
ENT.Type = "anim"

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/wick/weapons/l4d1/w_molotov.mdl")
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
		self:DrawShadow(false)
	end
    
    self:SetCustomGroupAndFlags(ZS_COLLISIONGROUP_HUMAN, ZS_COLLISIONFLAGS_HUMAN)
    self:SetCustomCollisionCheck(true)
    
	self:EmitSound("TFA_L4D1_SNIPER.DRAW")
	self:EmitSound("TFA_L4D1_MOLOTOV.IGNITE")
	self:EmitSound("TFA_L4D1_MOLOTOV.FLY")
    
	self.ActiveTimer = CurTime() + 1.5
	self.IgniteEnd = 0
	self.IgniteEndTimer = CurTime()
	self.IgniteStage = 0
	self.IgniteStageTimer = CurTime()
    
	ParticleEffectAttach("weapon_molotov_thrown",PATTACH_POINT_FOLLOW,self,1)
	self:PhysicsInitBox(Vector(-6, -6, -2), Vector(6, 6, 2))
end

function ENT:PhysicsCollide( data, phys )
    if self.bDone then return end
    
	if SERVER and self.ActiveTimer > CurTime() || data.Speed >= 150 then
		self:EmitSound(Sound("GlassBottle.ImpactHard"))
	end
    
	local ang = data.HitNormal:Angle()
	ang.p = math.abs( ang.p )
	ang.y = math.abs( ang.y )
	ang.r = math.abs( ang.r )
    
    if data.HitEntity:IsValid() and (data.HitEntity:IsNPC() or data.HitEntity:IsNextBot()) then
        self:SetPos(data.HitEntity:GetPos())
        ang.p = 59
    end
	
    self:DropToFloor()
    self.bDone = true

    if SERVER then
        local molot = ents.Create( "tfa_l4d1_fire_2" )
        molot:SetPos(data.HitPos)
        molot:SetOwner(self:GetOwner())
        molot:Spawn()
        SafeRemoveEntityDelayed(molot, 13)
        
        local molot1 = ents.Create( "tfa_l4d1_fire_1" )
        molot1:SetPos(data.HitPos)
        molot1:SetOwner(self:GetOwner())
        molot1:SetCreator(self)
        molot1:Spawn()
        SafeRemoveEntityDelayed(molot1, 13)
        
        local tr = util.TraceLine( {
            start = data.HitPos,
            endpos = data.HitPos - Vector(0,0,256),
            filter = ents.GetAll()
        } )
        if tr.HitWorld then
            molot:SetPos(tr.HitPos)
            molot1:SetPos(tr.HitPos)
        end
    end
    self:EmitSound("TFA_L4D1_MOLOTOV.DETONATE")
    ParticleEffect("molotov_explosion", self:GetPos(), Angle(0,0,0), nil) 
    self:StopSound("TFA_L4D1_MOLOTOV.FLY")
    self.IgniteEnd = 1
    self.IgniteEndTimer = CurTime() + 7
    self.IgniteStage = 1
    self.IgniteStageTimer = CurTime() + 0.1
    
    SafeRemoveEntityDelayed(self, 10)
    
    util.Decal("Scorch", self:GetPos(), self:GetPos() + Vector(0, 0, -128), ents.GetAll())
    util.ScreenShake(self:GetPos(), 25, 150, 1, 750)
    
    if SERVER then
        util.BlastDamage(self, self:GetOwner(), self:GetPos(), 150, 25)
    end
end

function ENT:Think()
    if self.bDone and not self.bDelete then
        self.bDelete = true
        
        if SERVER then
            self:SetMoveType(MOVETYPE_NONE)
            self:SetSolid(SOLID_NONE)
            self:PhysicsInit(SOLID_NONE)
            self:SetCollisionGroup(COLLISION_GROUP_NONE)
            self:SetRenderMode(RENDERMODE_TRANSALPHA)
            self:SetColor(Color(255, 255, 255, 0))
            self:DrawShadow(false)
            self:StopParticles()
        end
    end
end