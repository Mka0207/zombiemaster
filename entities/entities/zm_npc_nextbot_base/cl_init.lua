include("shared.lua")

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.UseGore = true
ENT.DrawSkeleton = true
ENT.MaxGoreElements = 2
ENT.GoreScale = 1

ENT.GoreTable = {}

local flesh = Material("models/flesh")
local flesh_skeleton = Material( "models/skeleton/skeleton_bloody" )

-- mimic some code from cl_init
function ENT:Initialize()
	GAMEMODE:CallZombieFunction(self, "OnSpawned")
	GAMEMODE:CallZombieFunction(self, "SetupModel")

	self:SetLOD( -1 )
	//self:SetRenderMode( RENDERMODE_TRANSALPHA )
	
	self:SetNoDraw(true)
			
	timer.Simple(0, function()
        self.Time = 0.55
        self.LifeTime = CurTime() + self.Time
				
		self:SetNoDraw(false)
		self.fadeAlpha = 0
	end)

	local entname = string.lower(self:GetClass())
	
	local zombietab = GAMEMODE:GetZombieData(entname)
	if zombietab ~= nil then
		GAMEMODE.iZombieList[self:EntIndex()] = self
	end
        
	table.insert(GAMEMODE.SilhouetteEnts, self)
	
end

function ENT:OnRemove()
	if IsValid( self.Hole ) then
		self.Hole:Remove()
	end
	if IsValid( self.Spook ) then
		self.Spook:Remove()
	end
	if IsValid( self.Meat ) then
		self.Meat:Remove()
	end
end

function ENT:Draw()
    if self:Health() <= 0 then 
        self.ShouldDrawSilhouette = false
    end

	if self.DrawingSilhouette then
        GAMEMODE:CallZombieFunction(self, "Draw")
        return
    end
	
    if GAMEMODE:CallZombieFunction(self, "PreDraw") then return end
	
	if self.FadeFinished then
		self:DefaultDraw()
	else
        GAMEMODE:CallZombieFunction(self, "SpawnDraw")
	end
   
    GAMEMODE:CallZombieFunction(self, "PostDraw")	
	
end

function ENT:DefaultDraw()
    if not self.DidRenderModeCheck then
        self.NoDraw = self:GetRenderMode() == RENDERMODE_NONE
        self.DidRenderModeCheck = true
    end
    
    if self.NoDraw then return end
    
    if !self:DrawGore() then
        self:DrawModel()
    end
end

local gore_scale = Vector( 1.1, 1.6, 1.6 )
local bounds = Vector( 300, 300, 300 )
local vec_tiny = Vector( 0.01, 0.01, 0.01 )
local vec_skeleton_head = Vector( 0.86, 0.86, 0.86 )
local vec_charple_head = Vector( 1.2, 1.2, 1.2 )

local function FixSkeleton( ent, bonecount )
	if ent then
		local m = ent:GetBoneMatrix( 6 )  // thats head
		if m then
			if m:GetScale().x < vec_skeleton_head.x then return end
			m:SetScale( vec_skeleton_head )
			ent:SetBoneMatrix( 6, m )
		end
	end
end

local function FixCharple( ent, bonecount )
	if ent then
		local m = ent:GetBoneMatrix( 6 )  // thats head
		if m then
			if m:GetScale().x < vec_charple_head.x then return end
			m:SetScale( vec_charple_head )
			ent:SetBoneMatrix( 6, m )
		end
	end
end

function ENT:AddGore( pos, ang, bone, scale )
	
	if not self.UseGore then return end
	
	if not self.GoreTable then
		self.GoreTable = {}
	end
	
	if #self.GoreTable >= self.MaxGoreElements then return end
	
	pos = pos or vector_origin
	ang = ang or Angle( 0, 0, 0 )
	bone = bone or 0
	scale = scale or 1
	
	if not IsValid( self.Hole ) then
		self.Hole = ClientsideModel("models/props_junk/rock001a.mdl", RENDERGROUP_TRANSLUCENT)
		self.Hole:SetNoDraw(true)
		self.Hole:SetRenderBounds( -bounds, bounds )
		self.Hole:DrawShadow( false )
        self.Hole:AddEffects(EF_NOSHADOW)
        self.Hole:DestroyShadow() 
	end
	
	if self.DrawSkeleton then
		if not IsValid( self.Spook ) then
			self.Spook = ClientsideModel("models/player/skeleton.mdl", RENDERGROUP_TRANSLUCENT)
			self.Spook:SetNoDraw(true)
			self.Spook:SetRenderBounds( -bounds, bounds )
			self.Spook:SetParent( self )
            self.Spook:DrawShadow( false )
            self.Spook:AddEffects(EF_NOSHADOW)
            self.Spook:DestroyShadow() 
			self.Spook:AddCallback( "BuildBonePositions", FixSkeleton )
		end
		
		if not IsValid( self.Meat ) then
			self.Meat = ClientsideModel( self.MeatModel or "models/player/charple.mdl", RENDERGROUP_TRANSLUCENT )
			self.Meat:SetNoDraw(true)
			self.Meat:SetRenderBounds( -bounds, bounds )
			self.Meat:SetParent( self )
            self.Meat:DrawShadow( false )
            self.Meat:AddEffects(EF_NOSHADOW)
            self.Meat:DestroyShadow() 
			self.Meat:AddCallback( "BuildBonePositions", FixCharple )
		end
	end
	
	self.GoreTable[ #self.GoreTable + 1 ] = { pos = pos, ang = ang, bone = bone, scale = scale }
	
end

local LocalToWorld = LocalToWorld

-- make sure to call bone pos/ang once per gore element (instead of 4-5)
local function SetHolePositions( self, parent )
	
	for i=1, #self.GoreTable do
		local tbl = self.GoreTable[i]
		
		local pos, ang
		
		if parent then
			pos, ang = parent:GetBonePosition( tbl.bone ) 
		else
			pos, ang = self:GetBonePosition( tbl.bone ) 
		end
		
		if pos and ang then
		
			pos, ang = LocalToWorld( tbl.pos, tbl.ang, pos, ang )
		
			self.GoreTable[i].bone_pos = pos * 1
			self.GoreTable[i].bone_ang = ang * 1
		end
	end
	
end

local function DrawHoles( self, ent, parent )

	for i=1, #self.GoreTable do
		local tbl = self.GoreTable[i]
		
		local pos, ang = tbl.bone_pos, tbl.bone_ang
		
		/*if parent then
			pos, ang = parent:GetBonePosition( tbl.bone ) 
		else
			pos, ang = self:GetBonePosition( tbl.bone ) 
		end*/
		
		if pos and ang then
			
			//pos, ang = LocalToWorld( tbl.pos, tbl.ang, pos, ang )

			local m = Matrix()
				m:SetScale( gore_scale * tbl.scale * self.GoreScale )
			ent:EnableMatrix( "RenderMultiply", m )
			
			ent:SetPos( pos )
			ent:SetAngles( ang )
			
			ent:SetupBones()
			ent:DrawModel()
		end
	end
	
end

local STENCIL_KEEP = STENCIL_KEEP
local STENCIL_ALWAYS = STENCIL_ALWAYS
local STENCIL_ZERO = STENCIL_ZERO
local STENCIL_DECR = STENCIL_DECR
local STENCIL_INCR = STENCIL_INCR
local STENCIL_LESSEQUAL = STENCIL_LESSEQUAL
local STENCIL_NOTEQUAL = STENCIL_NOTEQUAL
local STENCIL_REPLACE = STENCIL_REPLACE
local STENCIL_EQUAL = STENCIL_EQUAL

local MATERIAL_CULLMODE_CW = MATERIAL_CULLMODE_CW
local MATERIAL_CULLMODE_CCW = MATERIAL_CULLMODE_CCW


local function DrawMask( self, parent )
	
	render.ClearStencil()
	render.SetStencilEnable(true)

	render.SetStencilTestMask(255)
	render.SetStencilWriteMask(255)
	
	render.SetStencilReferenceValue(1)
	
	render.SetStencilFailOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilPassOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilZFailOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilCompareFunction( STENCIL_ALWAYS )

	-- normal
	render.OverrideDepthEnable( true, true )
	render.SetBlend(0)	
	if parent then
		parent:DrawModel()
	else
		self:DrawModel()
	end
	render.SetBlend(1)
	render.OverrideDepthEnable( false )
	
	
	render.SetStencilReferenceValue(2)
	
	render.SetStencilFailOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilPassOperation( STENCIL_ZERO ) // STENCIL_KEEP
	render.SetStencilZFailOperation( STENCIL_DECR ) //STENCIL_DECR
	render.SetStencilCompareFunction( STENCIL_ALWAYS ) // STENCIL_ALWAYS
	
	render.SetBlend(0)
	render.CullMode( MATERIAL_CULLMODE_CW )
	DrawHoles( self, self.Hole, parent )
	render.CullMode( MATERIAL_CULLMODE_CCW )
	render.SetBlend(1)
	
	render.SetStencilReferenceValue(3)

	render.SetStencilFailOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilPassOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilZFailOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilCompareFunction( STENCIL_LESSEQUAL ) // STENCIL_LESS

	render.OverrideDepthEnable( true, true )
	render.SetBlend(0)
	DrawHoles( self, self.Hole, parent )
	render.SetBlend(1)
	render.OverrideDepthEnable( false )
	
	-- actual model
	render.SetStencilReferenceValue(3)
	
	render.SetStencilFailOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilPassOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilZFailOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilCompareFunction( STENCIL_NOTEQUAL ) // STENCIL_NOTEQUAL
	
	if parent then
		parent:DrawModel()
	else
		self:DrawModel()
	end

	render.SetStencilEnable(false)

end

local function DrawFlesh( self, parent )
	
	render.ClearStencil()
	render.SetStencilEnable(true)	
	
	render.SetStencilTestMask(255)
	render.SetStencilWriteMask(255)
	
	render.SetStencilReferenceValue(1) // 1
	
	render.SetStencilFailOperation( STENCIL_KEEP ) // keep
	render.SetStencilPassOperation( STENCIL_REPLACE ) // replace
	render.SetStencilZFailOperation( STENCIL_REPLACE ) // replace
	render.SetStencilCompareFunction( STENCIL_ALWAYS ) // always

	-- inversed
	render.OverrideDepthEnable( true, true )
	render.SetBlend(0)
	render.CullMode( MATERIAL_CULLMODE_CW )
	if parent then
		parent:DrawModel()
	else
		self:DrawModel()
	end
	render.CullMode( MATERIAL_CULLMODE_CCW )
	render.SetBlend(1)
	render.OverrideDepthEnable( false )
	
	
	render.SetStencilReferenceValue(1)

	render.SetStencilFailOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilPassOperation( STENCIL_INCR ) // STENCIL_KEEP
	render.SetStencilZFailOperation( STENCIL_KEEP ) // STENCIL_KEEP
	render.SetStencilCompareFunction( STENCIL_EQUAL ) // STENCIL_LESS
	
	render.OverrideDepthEnable( true, false )
	render.SetBlend(0)
	DrawHoles( self, self.Hole, parent )
	render.SetBlend(1)
	render.OverrideDepthEnable( false )

	render.SetStencilReferenceValue(2) // 1
	
	render.SetStencilFailOperation( STENCIL_KEEP ) //STENCIL_KEEP
	render.SetStencilPassOperation( STENCIL_KEEP ) //STENCIL_KEEP
	render.SetStencilZFailOperation( STENCIL_KEEP ) //STENCIL_KEEP
	render.SetStencilCompareFunction( STENCIL_EQUAL ) //STENCIL_EQUAL
	
	render.OverrideDepthEnable( true, false )	
	render.CullMode( MATERIAL_CULLMODE_CW )
	render.ModelMaterialOverride( flesh )
	render.SuppressEngineLighting( true )
	render.SetColorModulation( 0.8, 0, 0 )
	DrawHoles( self, self.Hole, parent )
	render.SetColorModulation( 1, 1, 1 )
	render.SuppressEngineLighting( false )
	render.ModelMaterialOverride(  )
	render.CullMode( MATERIAL_CULLMODE_CCW )	
	render.OverrideDepthEnable( false )

	render.SetStencilEnable(false)
	
end

local function DrawSkeleton( self, parent )
	
	render.ClearStencil()
	render.SetStencilEnable(true)		
	
	render.SetStencilTestMask(255)
	render.SetStencilWriteMask(255)
	
	render.SetStencilReferenceValue(1)
	
	render.SetStencilFailOperation( STENCIL_KEEP )
	render.SetStencilPassOperation( STENCIL_REPLACE )
	render.SetStencilZFailOperation( STENCIL_KEEP )
	render.SetStencilCompareFunction( STENCIL_ALWAYS )

	render.OverrideDepthEnable( true, false )
	render.SetBlend(0)
	DrawHoles( self, self.Hole, parent )
	render.SetBlend(1)
	render.OverrideDepthEnable( false )
	
	render.SetStencilReferenceValue(1)
	
	render.SetStencilPassOperation( STENCIL_KEEP )
	render.SetStencilFailOperation( STENCIL_KEEP )
	render.SetStencilZFailOperation( STENCIL_KEEP )
	render.SetStencilCompareFunction( STENCIL_EQUAL )
	
	render.OverrideDepthEnable( true, true )
	render.ModelMaterialOverride( flesh )
	render.SetColorModulation( 0.8, 0, 0 )
	self.Meat:DrawModel()
	self.Spook:DrawModel()
	render.ModelMaterialOverride()
	render.SetColorModulation( 1, 1, 1 )
	render.OverrideDepthEnable( false )
	
	render.SetStencilEnable(false)	
	
end

-- return false here if you want to prevent gore from drawing (live zombie only, scroll down for on corpse gore)
function ENT:DrawGore()
	if self.DrawingSilhouette then return false end
	if not self.UseGore then return false end
	if self.GoreTable and #self.GoreTable < 1 then return false end
	
	SetHolePositions( self )
	
	if self.DrawSkeleton and IsValid( self.Spook ) and IsValid( self.Meat ) then
		
		local pos, ang = self:GetPos(), self:GetAngles()
		
		self.Spook:SetPos( pos )
		self.Spook:SetAngles( ang )
		self.Spook:SetParent( self )
		self.Spook:AddEffects( EF_BONEMERGE )
		
		self.Meat:SetPos( pos )
		self.Meat:SetAngles( ang )
		self.Meat:SetParent( self )
		self.Meat:AddEffects( EF_BONEMERGE )
		
		DrawSkeleton( self )
	end

	if !IsValid( self.Hole ) then return end
	
	self:RemoveAllDecals()
	
	DrawFlesh( self )
	DrawMask( self )

end

hook.Add( "CreateClientsideRagdoll", "NextBotGetRagdollEntity", function( entity, ragdoll )
	if entity:IsNextBot() and not entity.GetRagdollEntity then
		entity.GetRagdollEntity = function( self ) return ragdoll end
	end
end )

-- the only reason why im registering effect there is that i dont have to copypaste all of these cool local functions (plus you can modify them at once)
local EFFECT = {}

function EFFECT:Init( data )
	
	local ent = data:GetEntity()
	
	if !IsValid( ent ) then return end
	if not ent.GoreTable then return end
	if not ent.GetRagdollEntity then return end
	if #ent.GoreTable < 1 then return end
	
	
	self.GoreTable = ent.GoreTable
	self.GoreScale = ent.GoreScale
	self.DrawSkeleton = ent.DrawSkeleton
	self.MeatModel = ent.MeatModel
	
	self.RagdollEntity = ent:GetRagdollEntity()
	
	if !IsValid( self.RagdollEntity ) then return end
	
	local hitbox = data:GetHitBox()
	
	if hitbox ~= -1 then
		local bone = self.RagdollEntity:GetHitBoxBone( hitbox, 0 )
		
		if bone and bone ~= 0 then		
			self.RagdollEntity:ManipulateBoneScale( bone, vec_tiny )

			for k, v in pairs( self.RagdollEntity:GetChildBones( bone ) ) do
				if v then
					self.RagdollEntity:ManipulateBoneScale( v, vec_tiny )
					-- this is stupid, do not repeat my laziness
					for k1, v1 in pairs( self.RagdollEntity:GetChildBones( v ) ) do
						if v1 then
							self.RagdollEntity:ManipulateBoneScale( v1, vec_tiny )
						end
					end
				end
			end
			
			self.BleedBone = bone
			self.BleedTime = CurTime() + 4
			
			local pos, ang = self.RagdollEntity:GetBonePosition( bone )

			if ent:IsNPC() then
				pos = self:GetPos() + vector_up * 64
			end

			if pos then
                sound.Play("player/headshot"..math.random(2)..".wav", pos, 55, math.Rand(80, 90))
				sound.Play("player/headshot"..math.random(2)..".wav", pos, 55, math.Rand(80, 90))
				
				local emitter = ParticleEmitter(pos)
				for i=1, math.random( 9, 13 ) do
					local particle = emitter:Add("effects/blood_core", pos + VectorRand( -1, 1 ) )
					particle:SetVelocity( VectorRand( -110, 110 ) )
					particle:SetVelocityScale( true )
					particle:SetDieTime(math.Rand(2, 3))
					particle:SetStartAlpha(250)
					particle:SetEndAlpha(0)
					local size = math.Rand(7, 11)
					particle:SetStartSize( size )
					particle:SetEndSize( size * 1.4 )
					particle:SetRoll(math.Rand(0, 360))
					particle:SetRollDelta(math.Rand(-1, 1))
					particle:SetAirResistance(1000)
					particle:SetGravity(Vector(0, 0, 100))
					//particle:SetLighting(true)
					particle:SetColor(175, 0, 0)
				end
				emitter:Finish()	emitter = nil collectgarbage("step", 64)
				
			end

		end
		
	end
	
	self.RagdollEntity:SetNoDraw( true )
	self.RagdollEntity:RemoveAllDecals()
	
	self:CreateGore()
	
	self:SetRenderBounds( -bounds, bounds )
	
end

function EFFECT:CreateGore()
	
	if not IsValid( self.Hole ) then
		self.Hole = ClientsideModel("models/props_junk/rock001a.mdl")
		self.Hole:SetNoDraw(true)
		self.Hole:SetRenderBounds( -bounds, bounds )
		self.Hole:DrawShadow( false )
	end
	
	if self.DrawSkeleton then
		if not IsValid( self.Spook ) then
			self.Spook = ClientsideModel("models/player/skeleton.mdl")
			self.Spook:SetNoDraw(true)
			self.Spook:SetRenderBounds( -bounds, bounds )
			self.Spook:SetParent( self.RagdollEntity )
			self.Spook:DrawShadow( false )
			self.Spook:AddCallback( "BuildBonePositions", FixSkeleton )
		end
		
		if not IsValid( self.Meat ) then
			self.Meat = ClientsideModel( self.MeatModel or "models/player/charple.mdl")
			self.Meat:SetNoDraw(true)
			self.Meat:SetRenderBounds( -bounds, bounds )
			self.Meat:SetParent( self.RagdollEntity )
			self.Meat:DrawShadow( false )
			self.Meat:AddCallback( "BuildBonePositions", FixCharple )
		end
	end
	
end

function EFFECT:Think()
	if self.RagdollEntity and self.RagdollEntity:IsValid() and not self.DestroyGore then
		self:SetPos( self.RagdollEntity:GetPos() )

		if self.RagdollEntity:GetInternalVariable( "m_bFadingOut" ) and not self.DestroyGore then
			self.DestroyGore = true
			self.RagdollEntity:SetNoDraw( false )
			-- prevent the annoying engine warning spam about child entities having incorrect parent
			for k, v in pairs( self.RagdollEntity:GetChildren() ) do
				if v and v:GetClass() == "manipulate_bone" then
					SafeRemoveEntity(v)
				end
			end
		end
		return true
	else
		if IsValid( self.Hole ) then
			self.Hole:Remove()
		end
		if IsValid( self.Spook ) then
			self.Spook:SetParent( nil )
			self.Spook:Remove()
		end
		if IsValid( self.Meat ) then
			self.Meat:SetParent( nil )
			self.Meat:Remove()
		end
		return false
	end
end

function EFFECT:DrawGore()
	if self.DestroyGore or GAMEMODE.bDisableGore then return end
	if !IsValid( self.RagdollEntity ) then return end
	
	if self.GoreTable and #self.GoreTable < 1 then return false end
	
	SetHolePositions( self, self.RagdollEntity )
	
	if self.DrawSkeleton and IsValid( self.Spook ) and IsValid( self.Meat ) then
		
		local pos, ang = self.RagdollEntity:GetPos(), self.RagdollEntity:GetAngles()
		
		self.Spook:SetPos( pos )
		self.Spook:SetAngles( ang )
		self.Spook:SetParent( self.RagdollEntity )
		self.Spook:AddEffects( EF_BONEMERGE )
		
		self.Meat:SetPos( pos )
		self.Meat:SetAngles( ang )
		self.Meat:SetParent( self.RagdollEntity )
		self.Meat:AddEffects( EF_BONEMERGE )
		
		DrawSkeleton( self, self.RagdollEntity )
	end

	if !IsValid( self.Hole ) then return end
	
	self.RagdollEntity:RemoveAllDecals()
	
	DrawFlesh( self, self.RagdollEntity )
	DrawMask( self, self.RagdollEntity )
	
	if self.BleedBone and self.BleedTime and self.BleedTime > CurTime() then
		
		self.NextBleed = self.NextBleed or 0
		
		local pos, ang = self.RagdollEntity:GetBonePosition( self.BleedBone )
		if pos and ang then
			
			if self.NextBleed < CurTime() then
				self.NextBleed = CurTime() + 0.07
				
				local emitter = ParticleEmitter(pos)
				for i=1, 2 do
					local particle = emitter:Add("!zm_blood_decal"..math.random(8), pos + VectorRand( -2, 2 ) )
					particle:SetVelocity( ang:Forward() * 1 * math.random( 60, 70 ) + VectorRand( -26, 26 ) )
					particle:SetVelocityScale( true )
					particle:SetDieTime(math.Rand(0.2, 0.3))
					particle:SetStartAlpha(255)
					particle:SetEndAlpha(255)
					local size = math.Rand(3, 4)
					particle:SetStartSize( size )
					particle:SetEndSize( size * 1.2 )
					particle:SetRoll(math.Rand(0, 360))
					particle:SetRollDelta(math.Rand(-1, 1))
					particle:SetAirResistance(300)
					particle:SetGravity(Vector(0, 0, -160))
					particle:SetLighting(true)
					particle:SetColor(255, 0, 0)
				end
				emitter:Finish()	emitter = nil collectgarbage("step", 64)
			end
		end

	end
	
end

function EFFECT:Render()
	self:DrawGore()
end

effects.Register( EFFECT, "bodydamage_ragdoll" )