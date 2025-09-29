AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

DEFINE_BASECLASS("zm_npc_nextbot_base")

ENT.AttackDamage = 8
ENT.CanSwatPhysicsObjects = false
ENT.FootStepTime = 0.3
ENT.DamageType   = DMG_BURN

ENT.ImmolationSounds = "NPC_BurnZombie.Alert"
ENT.AttackSounds = "NPC_Barnacle.Scream"
ENT.DeathSounds  = "NPC_BurnZombie.Die"
ENT.PainSounds   = "NPC_BurnZombie.Pain"
ENT.MoanSounds   = "NPC_BurnZombie.Idle"
ENT.AlertSounds  = "NPC_Barnacle.PullPant"

ENT.NoHitGroupFix = true

ENT.RunSpeedMultiplier = 2.4 // roughly to match their default ground speed

ENT.IdleSequences = { 1, 2, 3 } // "idle1", "idle2", "idle3"

local seq_walk = 4
local seq_walk2 = 5

function ENT:Initialize()
	BaseClass.Initialize(self)
	
	self.WalkSeq = math.random(2) == 2 and seq_walk or seq_walk2
	self.IdleSeq = self.IdleSequences[ math.random( #self.IdleSequences ) ]
	
end

function ENT:OverrideAttackLogic( enemy )
	
	local dist = self:GetPos():DistToSqr(enemy:GetPos())
	
	if self:VisibleVec(enemy:WorldSpaceCenter()) and dist < 250 * 250 and not self.OnFire then    
		self:StartImmolation( 5 )
		self.OnFire = true
	else
		local melee = self:MeleeAttack1Conditions(self:GetPos():Dot(enemy:GetPos()), self:GetPos():DistToSqr(enemy:GetPos()))
		if melee and not self.IsAttacking and not self.Leaping then 
			self.IsAttacking = true
		end
	end

end

function ENT:StartImmolation( die_time )
	
	self:PlayVoiceSound(self.ImmolationSounds)
	
	self:Ignite( 9999, 100 )
	
	self.DesiredSpeed = self.DesiredSpeed * self.RunSpeedMultiplier
	self.loco:SetDesiredSpeed( self.DesiredSpeed )
	
	self.ExplodeTime = CurTime() + die_time or 5
	
end

function ENT:Explode()
	
	if self.Exploded then return end
	self.Exploded = true

	self:EmitSound("PropaneTank.Burst")
            
	local dmginfo = DamageInfo()
        dmginfo:SetAttacker(IsValid( self:GetEnemy() ) and self:GetEnemy() or self)
		dmginfo:SetInflictor(self)
		dmginfo:SetDamage(math.random(10, 20))
		dmginfo:SetDamagePosition(self:GetPos())
		dmginfo:SetDamageType(DMG_BURN)
	util.BlastDamageInfo(dmginfo, self:GetPos(), 128)
            
	local effect = EffectData()
		effect:SetOrigin(self:GetPos())
		effect:SetScale(2)
	util.Effect("Explosion", effect, true, true)
        
	self:TakeDamage(self:Health(), self, self)
	
end

function ENT:CustomThink()
   if self:WaterLevel() >= 2 then
        self:TakeDamage(self:Health(), self, self)
        return
    end
	
	if self.ExplodeTime and self.ExplodeTime < CurTime() then
		self:Explode()
	end
end

-- OLD FIRE, DONT FORGET TO REPLACE IT
function ENT:OnRemove()
    if self:WaterLevel() >= 2 then return end
    
    for i = 1, 5 do
        local fire = ents.Create("env_fire")
        fire:SetPos(self:GetPos() + Vector(math.random(-40, 40), math.random(-40, 40), 0))
        fire:SetKeyValue("health", "25")
        fire:SetKeyValue("firesize", "60")
        fire:SetKeyValue("fireattack", "8")
        fire:SetKeyValue("damagescale", "1.0")
        fire:SetKeyValue("StartDisabled", "0")
        fire:SetKeyValue("firetype", "0" )
        fire:SetKeyValue("spawnflags", "132")
        fire:Spawn()
        fire:Fire("StartFire", "", 0)
        fire.OwnerTeam = TEAM_ZOMBIEMASTER
    end
end

function ENT:OnInjured( dmginfo )
	
	local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
    if not IsValid(attacker) then
        attacker = self
    end
	
	if not IsValid(inflictor) then
        inflictor = self
    end
	
	local attackowner = attacker:GetOwner()
    if IsValid(attacker) and attacker:GetClass() == "env_fire" and IsValid(attackowner) and attackowner:GetClass() == self:GetClass() then
        dmginfo:SetDamage(0)
        dmginfo:ScaleDamage(0)
        return
    end
	
	BaseClass.OnInjured(self, dmginfo)
end

local seq_Walk_OnFire = 6
local seq_Idle_OnFire = 7

function ENT:BodyUpdate()

	local speed = self.loco:GetVelocity()
	local len = speed:LengthSqr()
	
	if self.IsPlayingSequence and self.IsPlayingSequence >= CurTime() then
	else
		if len > 10 then
			local speed = self.DesiredSpeed or 100
			local delta = ( len ) / ( speed * speed ) * self.AnimationPlaybackMultiplier
	
			self:ResetSequence( self.OnFire and seq_Walk_OnFire or self.WalkSeq )

			self:SetPlaybackRate( math.Clamp( delta, 0.01, 10 ) )
		else
			self:ResetSequence( self.OnFire and seq_Idle_OnFire or self.IdleSeq )
			self:SetPlaybackRate( 1 )
		end
	end

	self:FrameAdvance()

end