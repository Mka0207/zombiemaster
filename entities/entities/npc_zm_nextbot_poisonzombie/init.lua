AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

DEFINE_BASECLASS("zm_npc_nextbot_base")

ENT.AttackDamage = 50
ENT.AttackRange  = 85
ENT.FootStepTime = 0.4
ENT.CanSwatPhysicsObjects = true

ENT.NoHitGroupFix = true

ENT.AttackSounds = "NPC_PoisonZombie.Attack"
ENT.DeathSounds  = "NPC_PoisonZombie.Die"
ENT.PainSounds   = "NPC_PoisonZombie.Pain"
ENT.MoanSounds   = "NPC_PoisonZombie.Idle"
ENT.AlertSounds     = "NPC_PoisonZombie.Alert"
ENT.AngerSounds = "NPC_PoisonZombie.Throw"

local math_random = math.random

function ENT:OnFootStepSound()
	
	if !self.IsAngry then return end
	
	self.CurFoot = self.CurFoot or true
	
	if self.CurFoot then
		self:EmitSound("^npc/strider/strider_step4.wav", 120, math_random(85, 95), 0.5, CHAN_AUTO + 10)
	else
		self:EmitSound("^npc/strider/strider_step5.wav", 120, math_random(85, 95), 0.5, CHAN_AUTO + 12)
	end
	
	self.CurFoot = not self.CurFoot
	
end

function ENT:OnInjured(dmginfo)
   BaseClass.OnInjured(self,dmginfo)
   
   if self:Health() <= self:GetMaxHealth() * 0.4 and not self.IsAngry then
		self.IsAngry = true
		
		self.DesiredSpeed = self.DesiredSpeed * 1.3
		self.loco:SetDesiredSpeed( self.DesiredSpeed )
		self:PlayVoiceSound(self.AngerSounds)
		self:PlayVoiceSound("Flesh.Break")
		
		self.FootStepTime = 0.3
		//self.AnimationPlaybackMultiplier = 0.75
   end
   
end

local seq_Run = 4
local seq_FireWalk = 2
local seq_walk_fix = 3

function ENT:BodyUpdate()

	local speed = self.loco:GetVelocity()
	local len = speed:LengthSqr()
	
	if self.IsPlayingSequence and self.IsPlayingSequence >= CurTime() then
	else
		if len > 10 then
			local speed = self.DesiredSpeed or 100
			local delta = ( len ) / ( speed * speed ) * self.AnimationPlaybackMultiplier
	
			if self.IsAngry then
				self:ResetSequence( seq_Run )
			else
				self:ResetSequence( self:IsOnFire() and seq_FireWalk or seq_walk_fix )
			end

			self:SetPlaybackRate( math.Clamp( delta, 0.01, 10 ) )
		else
			self:ResetSequence( self:GetIdleSequence() )
			self:SetPlaybackRate( 1 )
		end
	end

	self:FrameAdvance()

end

local seq_Idle01_fix = 1
function ENT:GetIdleSequence()
	return seq_Idle01_fix
end