AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

DEFINE_BASECLASS("zm_npc_nextbot_base")

ENT.NextLeap = CurTime()
ENT.LeapSound = "NPC_FastZombie.Scream"
ENT.AttackDamage = 6
ENT.CanSwatPhysicsObjects = false
ENT.FootStepTime = 0.15

ENT.AttackSounds = "NPC_FastZombie.Attack"
ENT.DeathSounds = "NPC_FastZombie.Die"
ENT.PainSounds = "NPC_FastZombie.Pain"
ENT.MoanSounds = "NPC_FastZombie.Idle"
ENT.ClawHitSounds = "NPC_FastZombie.AttackHit"
ENT.ClawMissSounds = "NPC_FastZombie.AttackMiss"
ENT.AlertSounds    = "NPC_FastZombie.AlertNear"
ENT.MoveSounds = {
    "NPC_FastZombie.FootstepRight",
    "NPC_FastZombie.FootstepLeft"
}

ENT.NavJumpHeight = 200
ENT.NextNavJump = CurTime()

function ENT:Initialize()
	BaseClass.Initialize(self)

	self.loco:SetAcceleration( 800 )
	self.loco:SetDeceleration( 800 )
end

function ENT:OverridePathCompute( path, pos )

	self.loco:SetJumpHeight( self.NavJumpHeight )
	path:Compute( self, pos )
	self.loco:SetJumpHeight( self.JumpHeight )

end

function ENT:OverridePathUpdate( path )

	local cur_goal = path:GetCurrentGoal()

	if cur_goal and ( cur_goal.type == 3 or cur_goal.type == 2 ) and self:IsOnGround() then

		local jump_to

		local segments = path:GetAllSegments()
		for i=1, #segments do
			local cur_seg = segments[ i ]
			local next_seg = segments[ i + 1 ]
			if cur_seg and cur_seg.length == cur_goal.length and next_seg then
				jump_to = next_seg.area:GetClosestPointOnArea( cur_goal.pos ) + vector_up * 5 + cur_goal.forward * 5
				break
			end
		end

		if jump_to and self.NextNavJump < CurTime() then
			self:HandleNavJumping( jump_to, cur_goal.forward )
			self.NextNavJump = CurTime() + 2
		end
	else
		path:Update( self )
		local new_pos = NEXTBOT_CustomAvoidOverride( self, path )
		if new_pos then
			self.loco:Approach( new_pos, 1 )
		end
	end

end

local seq_Leap = 6
local seq_LeapStrike = 7

function ENT:HandleNavJumping( pos, dir )

	self.IsNavJumping = true
	self:RefreshStuckInfo( 3 )

	self.loco:FaceTowards( pos )

	coroutine.wait( 0.2 )

	self.loco:FaceTowards( pos )

	self:ResetSequence( seq_Leap )
	local len = self:SequenceDuration()

	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( 1 )

	local dur = len

	self.IsPlayingSequence = CurTime() + dur * 0.65

	coroutine.wait( dur * 0.65 )
	self.loco:FaceTowards( pos )

	self:ResetSequence( seq_LeapStrike )
	local len = self:SequenceDuration()

	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( 1 )

	local mins, maxs = self:GetCollisionBounds()

	local min_height = pos.z - self:GetPos().z + maxs.z
	local vel = self:CalculateJumpVelocity( pos, min_height, 350 )

	self.loco:Jump()
	self.loco:SetVelocity( vel )

	self:PlayVoiceSound(self.LeapSound, CHAN_AUTO + 10)

	self.IsPlayingSequence = CurTime() + 9999

end

function ENT:OnLandOnGround( ent )

	if self.IsNavJumping then
		self.IsPlayingSequence = 0
		self.IsNavJumping = false
	end

	if self.IsLeaping then
		self.IsPlayingSequence = 0
		self.IsLeaping = false
	end

end

function ENT:OverrideAttackLogic( enemy )

	local dist = self:GetPos():DistToSqr(enemy:GetPos())

	if self:VisibleVec(enemy:WorldSpaceCenter()) and (dist < 360 * 360 and dist > self:GetClawAttackRange() * self:GetClawAttackRange() ) and not self.IsAttacking and ( self.NextLeap + 4 ) < CurTime() and not self.IsNavJumping then
		self.LeapAttack = true
	else
		local melee = self:MeleeAttack1Conditions( self:GetPos():Dot(enemy:GetPos()), dist )
		if melee and not self.IsAttacking and not self.Leaping then
			self.IsAttacking = true
		end
	end

end

function ENT:HandleTargetAttacking()
	if self.IsAttacking then
		self:RefreshStuckInfo( 5 )
		local cur_activity = self:GetActivity()
		self:PlayAttackSequence()
		self:StartActivityFixed( cur_activity )
		self.IsAttacking = false
		self.NextLeap = CurTime()
	end

	if self.LeapAttack then
		self:RefreshStuckInfo( 5 )
		self:PerformLeapAttack()
		self.LeapAttack = false
		self.NextLeap = CurTime()
	end
end

function ENT:PerformLeapAttack()

	local enemy = self:GetEnemy()
	if !IsValid( enemy ) then return end

	local pos = enemy:WorldSpaceCenter()

	self.IsLeaping = true

	self.loco:FaceTowards( pos )

	self:ResetSequence( seq_Leap )
	local len = self:SequenceDuration()

	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( 1 )

	local dur = len

	self.IsPlayingSequence = CurTime() + dur

	coroutine.wait( dur )

	if !IsValid( enemy ) then return end

	pos = enemy:WorldSpaceCenter()
	self.loco:FaceTowards( pos )

	self:ResetSequence( seq_LeapStrike )
	local len = self:SequenceDuration()

	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( 1 )

	local dir = enemy:GetPos() - self:GetPos()
	dir.z = 0
	dir:Normalize()

	local min_height = 40
	local vel = self:CalculateJumpVelocity( pos + dir * 120, min_height, 350 )

	self.loco:Jump()
	self.loco:SetVelocity( vel )

	self:PlayVoiceSound(self.LeapSound, CHAN_AUTO + 10)

	self.IsPlayingSequence = CurTime() + 9999

	self.NextEnemyUpdate = CurTime() + 2

end

local seq_Melee = 10
local seq_BR2_Roar = 20
local seq_BR2_Attack = 12

function ENT:PlayAttackSequence( func )

	local speed = 1

    if self.AttackSounds then
        self:PlayVoiceSound(self.AttackSounds)
    end

	self:ResetSequence( seq_Melee )
	local len = self:SequenceDuration()

	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( speed )

	local dur = len / speed
	local offset = 0.55

	self.IsPlayingSequence = CurTime() + dur

	self:PerformAttack()
	if func then
		func( self )
	end
	coroutine.wait( dur * offset )
	self:PerformAttack()
	if func then
		func( self )
	end
	coroutine.wait( dur * ( 1 - offset ) )

	self:ResetSequence( seq_BR2_Roar )
	len = self:SequenceDuration()

	self:ResetSequenceInfo()
	self:SetCycle( 0 )

	dur = len / speed

	self.IsPlayingSequence = CurTime() + dur

	self:PlayVoiceSound( "NPC_FastZombie.Frenzy" )

	coroutine.wait( dur )

	if math.random(3) == 3 then
		self:ResetSequence( seq_BR2_Attack )
		len = self:SequenceDuration()

		dur = len / speed

		self.IsPlayingSequence = CurTime() + dur

		coroutine.wait( dur * offset )
		self:PerformAttack()
		if func then
			func( self )
		end
		coroutine.wait( dur * ( 1 - offset ) )
	end

end

function ENT:IsCeilingFlat(plane_normal)
    local flat = Vector(0, 0, -1)
    local roofdot = math.abs(plane_normal:Dot(flat))

    if roofdot > 0.95 then
        return true
    end

    return false
end

function ENT:OnContact( ent )

	BaseClass.OnContact( self, ent )

	if self.IsTryingToAttach and not self:IsOnGround() and self.loco:IsClimbingOrJumping() and ent:IsWorld() then
		self.loco:SetGravity(0)
		self.m_bClinging = true
		self.IsTryingToAttach = false
	end

	if self.IsLeaping and not self:IsOnGround() and ent:IsPlayer() and ent:IsSurvivor() then
        local forward = self:GetAngles():Forward()
        local qaPunch = Angle(5, math.random(-2,2), math.random(-2,2))

        forward = forward * 40

        self:ClawAttack(self.AttackRange * 0.9, math.floor(self.AttackDamage * 0.25), qaPunch, forward)

		self.NextEnemyUpdate = CurTime() + 1
		self.IsPlayingSequence = 0
		self.IsLeaping = false
    end

end

function ENT:AttachToCeiling( pos )

	self.IsTryingToAttach = true

	local height = pos.z - self:GetPos().z

	self:ResetBreakables()
	self:SetEnemy( NULL )
	self.ReceivedOrders = CurTime() + 5
	self.m_vecLastPosition = nil
	self.IdleWander = CurTime() + 9999

	self.loco:SetJumpHeight( height * 1.1 )
	self.loco:Jump()
	self.loco:SetJumpHeight( self.JumpHeight )

end

function ENT:DetachFromCeiling()

	self.loco:SetGravity( 1000 )
	self.m_bClinging = false

end

function ENT:CustomThink()

	if self.m_bClinging then
		self.loco:SetVelocity( vector_origin )
	end

	if self.IsLeaping and IsValid( self:GetEnemy() ) and self:GetEnemy():IsPlayer() and ( self.NextAttackTracking or 0 ) < CurTime() then
		self.loco:FaceTowards( self:GetEnemy():GetPos() )
		self.NextAttackTracking = CurTime() + 0.05
	end

end

function ENT:EnemyDistanceScan()
	return self.m_bClinging and 120 * 120 or 512 * 512
end

function ENT:OnEnemyFound()
	if self.m_bClinging then
		self:DetachFromCeiling()
	end
end

function ENT:OverrideHandleStuck()

	self.loco:SetVelocity( vector_origin )

	local vel = self:CalculateJumpVelocity( self:GetPos() + self:GetAngles():Forward() * 40 + vector_up * 140, 70, 350 )

	-- move them back just a little bit
	self:SetPos( self:GetPos() - self:GetAngles():Forward() * 13 )

	self.loco:Jump()
	self.loco:SetVelocity( vel )

	self:PlayVoiceSound(self.LeapSound, CHAN_AUTO + 10)

	self:RefreshStuckInfo( 1 )

end

local seq_idle_rot = 5
local seq_walkRun = 21

function ENT:BodyUpdate()

	local speed = self.loco:GetVelocity()
	local len = speed:LengthSqr()

	if self.IsPlayingSequence and self.IsPlayingSequence >= CurTime() then
	else
		if self.m_bClinging then
			self:ResetSequence( seq_idle_rot )
			self:SetPlaybackRate( 1 )
		else
			if len > 2 then
				local speed = self.DesiredSpeed or 100
				local delta = ( len ) / ( speed * speed ) * self.AnimationPlaybackMultiplier
				if self:IsOnGround() then
					self:ResetSequence( seq_walkRun )
				else
					self:ResetSequence( seq_LeapStrike )
				end
				self:SetPlaybackRate( math.Clamp( delta, 0.2, 10 ) )
			else
				self:ResetSequence( self:GetIdleSequence() )
				self:SetPlaybackRate( 1 )
			end
		end
	end

	self:FrameAdvance()

end

-- we are using sequences instead
function ENT:StartActivityFixed( act )
end

function ENT:GetMoveActivity()
	return nil
end

local seq_idle3 = 2
function ENT:GetIdleSequence()
	return seq_idle3
end