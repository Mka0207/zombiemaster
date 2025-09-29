local maxbound = Vector(3, 3, 3)
local minbound = maxbound * -1

local gibs = {
	Model( "models/gibs/antlion_gib_small_1.mdl" ),
	Model( "models/gibs/antlion_gib_small_2.mdl" ),
	Model( "models/props_junk/watermelon01_chunk02a.mdl" ),
	Model( "models/props_junk/watermelon01_chunk02a.mdl" ),
	Model( "models/props_junk/watermelon01_chunk02a.mdl" ),
	Model( "models/props_junk/watermelon01_chunk02a.mdl" ),
}

for i=1, 8 do
	CreateMaterial( "zm_blood_decal"..i, "UnlitGeneric", {
		["$basetexture"] = "Decals/blood"..i,
		["$translucent"] = 1,
		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,
		["$decal"] = 1
	})
end

for i=1,3 do
	util.PrecacheSound( "physics/wood/wood_strain"..i..".wav" )
end
util.PrecacheSound("physics/body/body_medium_break2.wav")
util.PrecacheSound("physics/body/body_medium_break3.wav")
util.PrecacheSound("physics/body/body_medium_break4.wav")

local function CollideCallbackSmall(particle, hitpos, hitnormal)
	
	particle.HitSomething = true
	
	local dot = hitnormal:Dot( vector_up )
	
	local ang = hitnormal:Angle()
	ang:RotateAroundAxis( hitnormal, math.random( -90, 90 ) )
	particle:SetAngles( ang )
	
	particle:SetGravity( vector_origin )
	particle:SetPos( particle:GetPos() + hitnormal * 0.2 )
	
	local die_time = math.Rand(3, 4)
	particle:SetDieTime( die_time )
	particle.OverrideAlpha = CurTime() + die_time
	
	if dot > 0.75 then
		particle:SetEndSize( particle:GetStartSize() * math.Rand( 2, 3 ) )
	else
		particle:SetEndSize( particle:GetStartSize() )
	end
end

function EFFECT:Init(data)
	
	local ent = data:GetEntity()
	
	if !IsValid( ent ) then return end
	if not ent.AddGore then return end
	if ent.GoreTable and ent.MaxGoreElements and #ent.GoreTable >= ent.MaxGoreElements then return false end
	
	local pos = data:GetOrigin()
	local hitbox = data:GetHitBox()
	local scale = data:GetScale()
	local force = data:GetStart()
	
	if ent.GoreScale then
		scale = scale * ent.GoreScale
	end
	
	local bone = ent:GetHitBoxBone( hitbox, 0 )
	
	if bone then
		local bonepos, boneang = ent:GetBonePosition( bone )
		if bonepos and boneang then
			
			local dist = bonepos:Distance( pos )
			local norm = ( bonepos - pos ):GetNormal()
			
			local ang = VectorRand():Angle()
			
			local save_pos, save_ang = WorldToLocal( pos + norm * dist * math.Rand( 0.1, 0.4 ), ang, bonepos, boneang )

			ent:AddGore( save_pos, save_ang, bone, scale )
			self:SpawnGiblets( ent, pos, force, scale, ( norm * 0.5 + force:GetNormal() ):GetNormal(), ent:GetVelocity() )
			
			ent:RemoveAllDecals()
			
		end
	end

end

function EFFECT:SpawnGiblets( ent, pos, force, scale, norm, extra_vel )

	local pl = LocalPlayer()

    ent:EmitSound("Gore.Strain")
    ent:EmitSound("Gore.Break")
	
	local power = force:Length() * 0.15
	-- set a minimul power, so pistol does not feels so eh
	power = math.max( 450, power )
	
	local emitter = ParticleEmitter(pos, true)
    for i=1, math.ceil( 8 * scale ) do
        local dir = norm + VectorRand( -1, 1 ) * 0.3
		dir:Normalize()
        local particle = emitter:Add("!zm_blood_decal"..math.random(8), pos + VectorRand( -3, 3 ) * scale )
        particle:SetVelocity(power * math.Rand(0.5, 1) * dir + extra_vel * 0.5)
		particle:SetVelocityScale( true )
		particle:SetAngles( VectorRand():Angle() )
        particle:SetDieTime(math.Rand(4, 6))
        particle:SetStartAlpha(255)
        particle:SetEndAlpha(255)
		local size = math.Rand(3, 8) * scale
        particle:SetStartSize( size )
        particle:SetEndSize( size * 1.2 )
        particle:SetRoll(math.Rand(0, 360))
        particle:SetRollDelta(math.Rand(-10, 10))
		particle:SetAirResistance(100)
        particle:SetGravity(Vector(0, 0, -800))
        particle:SetCollide(true)
        particle:SetLighting(true)
        particle:SetColor(255, 0, 0)
        particle:SetCollideCallback(CollideCallbackSmall)
		particle:SetNextThink( CurTime() )
		particle:SetThinkFunction( function( p )
			
			if IsValid( pl ) and not p.HitSomething then
				local dir = ( p:GetPos() - pl:EyePos() ):GetNormal()
				dir = dir + p:GetVelocity():GetNormal()
				dir:Normalize()
				local ang = dir:Angle()
				ang:RotateAroundAxis( ang:Up(), 180 )
				p:SetAngles( ang )
				p:SetLifeTime( 0 )
			end
			
			if p.OverrideAlpha and p.OverrideAlpha > CurTime() then
				p:SetEndAlpha( 255 * math.Clamp( p.OverrideAlpha - CurTime(), 0, 1 ) )
			end
			
			p:SetNextThink( CurTime() )
		end )
		
    end
    emitter:Finish()	emitter = nil collectgarbage("step", 64)
	
	if scale < 1.2 then return end
	
	for i=1, math.ceil( 4 * scale ) do
		local dir = norm + VectorRand( -1, 1 ) * 0.1
		dir:Normalize()
		
		local ent = ClientsideModel( gibs[math.random(#gibs)], RENDERGROUP_OPAQUE)
		if ent:IsValid() then
			ent:SetMaterial("models/flesh")
			ent:SetModelScale( scale * math.Rand(0.4, 1), 0)
			ent:SetPos(pos + dir * 6)
			ent:PhysicsInitBox(minbound, maxbound)
			ent:SetCollisionBounds(minbound, maxbound)
			ent:SetCollisionGroup( COLLISION_GROUP_DEBRIS_TRIGGER )

			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:SetMaterial("zombieflesh")
				phys:SetVelocityInstantaneous(dir * power * math.Rand( 0.2, 0.7 ) + extra_vel * 0.5 )
				phys:AddAngleVelocity(VectorRand() * 1000)
			end

			SafeRemoveEntityDelayed(ent, math.random(4, 6))
		end
		
	end
	
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end