ENT.Type = "anim"

util.PrecacheSound("ZMPower.PhysExplode_Buildup")
util.PrecacheSound("ZMPower.PhysExplode_Boom")

function ENT:DelayedExplode(delay)
	self:CreateDelayEffects(delay)
	self:NextThink(CurTime() + delay)
	self.delayset = true
end

function ENT:Think()
	if self.delayset then
		self:EmitSound("ZMPower.PhysExplode_Boom")

		//make players in range drop their stuff, radius is cvar'd
		for _, pl in pairs(ents.FindInSphere(self:LocalToWorld(self:OBBCenter()), GetConVar("zm_physexp_forcedrop_radius"):GetFloat())) do
			if IsValid(pl) and pl:IsPlayer() then
				pl:ForceDropOfCarriedPhysObjects()
			end
		end

		//actual physics explosion
		local entity = ents.Create( "env_physexplosion" )
		if IsValid( entity ) then
			entity:SetPos( self:GetPos() )
			entity:SetKeyValue( "magnitude", ZM_PHYSEXP_DAMAGE )
			entity:SetKeyValue( "radius", ZM_PHYSEXP_RADIUS )
			local flags = bit.band(entity:GetSpawnFlags(), SF_PHYSEXPLOSION_NODAMAGE )
			local spawnflags = bit.band(flags, SF_PHYSEXPLOSION_DISORIENT_PLAYER )
			entity:SetKeyValue( "spawnflags", spawnflags )
			entity:Spawn( )
			entity:Activate()
			entity:Fire( "Explode", "", 0 )
			entity:Fire( "Kill", "", 0.5 )
		end
		
		//another run for good measure
		local effectdata = EffectData()
		effectdata:SetOrigin(self:LocalToWorld(self:OBBCenter()))
		effectdata:SetMagnitude(15)
		effectdata:SetScale(3)
		util.Effect("Sparks",effectdata)

		//TGB: clean ourselves up, else we stay around til round end
		self:Remove()
	end
	return true
end

function ENT:CreateDelayEffects(delay)
	self:EmitSound("ZMPower.PhysExplode_Buildup")

	//TGB: we want a particle effect instead
	local effectdata = EffectData()
	effectdata:SetOrigin(self:LocalToWorld(self:OBBCenter()))
	effectdata:SetMagnitude(1)
	effectdata:SetScale(5)
	util.Effect("Sparks",effectdata)

	-- How do I add spawn flags in LUA? - FMX
	local ent = ents.Create("env_spark")
	if IsValid(ent) then
		local spawnflags = bit.band(ent:GetSpawnFlags(), 64 + 128 + 256 )

		ent:KeyValue("spawnflags", spawnflags)
		ent:KeyValue("MaxDelay", 0.1)
		ent:KeyValue("Magnitude", 2)
		ent:KeyValue("TrailLength", 1.5)

		//modify delay to account for delayed dying of sparker
		delay = delay - 2.2
		ent:KeyValue("DeathTime", (CurTime() + delay))

		ent:Spawn()
		ent:SetPos(self:LocalToWorld(self:OBBCenter()))
	end
end