AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

DEFINE_BASECLASS("zm_npc_nextbot_base")

ENT.AttackSounds = "Zombie.Attack"
ENT.DeathSounds = "Zombie.Die"
ENT.PainSounds = "Zombie.Pain"
ENT.MoanSounds = "Zombie.Idle"
ENT.DoorHitSound = "npc/shamblie/zombie_pound_door.wav"
ENT.OnFireSound = {
    "NPC_BaseZombie.Moan1",
    "NPC_BaseZombie.Moan2",
    "NPC_BaseZombie.Moan3",
    "NPC_BaseZombie.Moan4"
}

ENT.WalkSequences = { 1, 2, 3, 4 } // "a_walk1", "walk2", "walk3", "walk4"

function ENT:Initialize()

	BaseClass.Initialize(self)
	
	self.WalkSeq = self.WalkSequences[ math.random( #self.WalkSequences ) ]
	
end

function ENT:PlayOnFireSound()
    
	self.FireSoundLoop = self.FireSoundLoop or CurTime()
	
	if self.FireSoundLoop < CurTime() then
        local sndfile = self:PlayVoiceSound(self.OnFireSound)
		self.FireSoundLoop = CurTime() + SoundDuration(sndfile)
	end

end

function ENT:CustomThink()
    if self:IsOnFire() then
       self:PlayOnFireSound()
    end
end

local seq_FireIdle = 6
local seq_Idle01 = 0
function ENT:GetIdleSequence()
	return self:IsOnFire() and seq_FireIdle or seq_Idle01
end

local seq_FireWalk = 5

function ENT:BodyUpdate()

	local speed = self.loco:GetVelocity()
    speed.z = 0
	local len = speed:LengthSqr()
	
	if self.IsPlayingSequence and self.IsPlayingSequence >= CurTime() then
	else
		if len > 10 then
            if not self.bSelectedWalkSeq then
                self.WalkSeq = self.WalkSequences[ math.random( #self.WalkSequences ) ]
                self.bSelectedWalkSeq = true
            end
            
            local act = self:IsOnFire() and seq_FireWalk or self.WalkSeq
			local speed = self.DesiredSpeed or 100
			local delta = ( len ) / ( speed * speed ) * self.AnimationPlaybackMultiplier
            
            self:ResetSequence(act)

			self:SetPlaybackRate( math.Clamp( delta, 0.01, 1 ) )
		else
            if self.bSelectedWalkSeq then self.bSelectedWalkSeq = false end
            
			self:ResetSequence( self:GetIdleSequence() )
			self:SetPlaybackRate( 1 )
		end
	end

	self:FrameAdvance()

end