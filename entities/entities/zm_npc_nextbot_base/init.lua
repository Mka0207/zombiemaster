AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.m_iClass         = CLASS_ZOMBIE
ENT.m_fMaxYawSpeed  = 20
ENT.ClawHitSounds     = "Zombie.AttackHit"
ENT.ClawMissSounds     = "Zombie.AttackMiss"
ENT.AlertSounds        = "Zombie.Alert"
ENT.DoorHitSound    = "npc/zombie/zombie_hit.wav"
ENT.NextIdleMoan     = CurTime()
ENT.MoveSounds         = {
    "Zombie.FootstepRight",
    "Zombie.ScuffRight"
}
ENT.AttackDamage    = 13
ENT.AttackRange        = 70
ENT.NextSwatScan     = CurTime()
ENT.CanSwatPhysicsObjects = true
ENT.FootStepTime     = 0.3
ENT.MoveTime        = CurTime()
ENT.NextBreakableScan = CurTime()
ENT.DamageType      = DMG_SLASH
ENT.GoalTolerance 	= 26
ENT.MaxStuckAttempts = 5
ENT.LastStuckTime = 0
ENT.ClearStuckTime = 5
ENT.IdleWander = CurTime()

ENT.AnimationPlaybackMultiplier = 1
ENT.StepHeight = 18
ENT.JumpHeight = 18

ENT.AttackHullZMul = 1.4

-- this will only work on listen servers and singleplayer
ENT.DebugPath = false

function ENT:EnemyDistanceScan()
	return 1024 * 1024
end

CreateConVar("zm_zombieswatforcemin", "20000", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Specifies the min force that a zombie can apply to a prop when swatting it.")
CreateConVar("zm_zombieswatforcemax", "70000", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Specifies the max force that a zombie can apply to a prop when swatting it.")
CreateConVar("zm_zombieswatlift", "20000", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Specifies the amount of lift that is applied to swatted props.")

function ENT:Initialize()

	self.loco:SetJumpHeight( self.JumpHeight )
	self.loco:SetStepHeight( self.StepHeight )
	self.loco:SetDeathDropHeight( 350 )
	self.loco:SetAvoidAllowed( false )
	self:SetSolidMask( MASK_NPCSOLID )

	self:PhysicsInitShadow( true, false )
	local phys = self:GetPhysicsObject()
	if IsValid( phys ) then
		phys:SetMass( 100 )
	end

	self:AddSolidFlags( FSOLID_NOT_STANDABLE )
	self:SetCollisionGroup( COLLISION_GROUP_NPC )
	self:AddFlags( FL_NPC )

	self.IdleWander = CurTime() + 10

end

local melee_attack1_trace = { mask = MASK_NPCSOLID, output = {} }
function ENT:MeleeAttack1Conditions(flDot, flDist)
    if flDist > self:GetClawAttackRange() * self:GetClawAttackRange() then
        return false
    end

    if flDot < 0.7 then
        return false
    end

    local vecMins = self:OBBMins()
    local vecMaxs = self:OBBMaxs()
    vecMins.z = vecMins.x * self.AttackHullZMul
    vecMaxs.z = vecMaxs.x

    local forward = self:GetAngles():Forward()

	melee_attack1_trace.start = self:WorldSpaceCenter()
	melee_attack1_trace.endpos = self:WorldSpaceCenter() + forward * self:GetClawAttackRange()
    melee_attack1_trace.filter = self
    melee_attack1_trace.mins = vecMins
    melee_attack1_trace.maxs = vecMaxs

	local tr = util.TraceHull( melee_attack1_trace )

    /*local tr = util.TraceHull({
        start = self:WorldSpaceCenter(),
        endpos = self:WorldSpaceCenter() + forward * self:GetClawAttackRange(),
        filter = self,
        mins = vecMins,
        maxs = vecMaxs,
        mask = MASK_NPCSOLID
    })*/
    if tr.fraction == 1.0 or not IsValid(tr.Entity) then
        return false
    end

    if tr.Entity == self:GetEnemy() or tr.Entity:IsNPC() then
        return true
    end

    if tr.Entity:IsWorld() then
        local vecToEnemy = self:GetEnemy():WorldSpaceCenter() - self:WorldSpaceCenter()
        local vecTrace = tr.endpos - tr.startpos

        if vecTrace:Length2DSqr() < vecToEnemy:Length2DSqr() then
            return true
        end
    end

    return false
end

function ENT:PlayVoiceSound(sounds, chan)
    local output
    local soundType = type(sounds)

    if soundType == "table" then
        local random = sounds[math.random(#sounds)]

        output = random
        self:EmitSound(random, 75, 100, 1, chan or CHAN_AUTO)
    elseif (soundType == "string") then
        output = sounds
        self:EmitSound(sounds, 75, 100, 1, chan or CHAN_AUTO)
    end

    return output
end

function ENT:GetRelationship(ent)
    if self.PendingRemove then
        return D_LI
    elseif ent:IsNextBot() then
        return D_LI
    elseif ent:IsPlayer() and ent:IsSurvivor() then
        return D_HT
    end

    return D_NU
end

function ENT:OnKilled( dmginfo )

	local attacker, inflictor = dmginfo:GetAttacker() or self, dmginfo:GetInflictor() or self

    self:Input("OnDeath", attacker, inflictor)

	gamemode.Call("OnNPCKilled", self, attacker, inflictor)
    self:PlayVoiceSound(self.DeathSounds)

	self:BecomeRagdoll( dmginfo )

	local bullet_dmg = bit.band(dmginfo:GetDamageType(), DMG_BULLET) ~= 0 or bit.band(dmginfo:GetDamageType(), DMG_CLUB)
	local hitbox = -1

	if bullet_dmg and self.LastHitGroup and ( self.LastHitGroup == 1 or self.LastHitGroup > 3 and self.LastHitGroup < 8 ) and self.LastHitBox and self:Health() < -30 then
		hitbox = self.LastHitBox
	end

	local effect = EffectData()
		effect:SetEntity(self)
		effect:SetOrigin(self:GetPos())
		effect:SetHitBox( hitbox )
	util.Effect("bodydamage_ragdoll", effect)

end

function ENT:OnTraceAttack( dmginfo, dir, trace )
	GAMEMODE:CallZombieFunction(self, "OnScaledDamage", trace.HitGroup, dmginfo)

	self.HitGroupWindow = self.HitGroupWindow or 0

	-- a small workaround for weapons like shotguns
	-- so lets say: you shoot a zombie in the head and bullets hit generic and head hitgroups/hitboxes - this code will make sure that head takes priority for dismemberment
	if self.HitGroupWindow < CurTime() then
		self.HitGroupWindow = CurTime() + 0.01
		self.LastHitGroup = trace.HitGroup
		self.LastHitBox = trace.HitBox
	else
		if trace.HitGroup ~= 0 then
			self.LastHitGroup = trace.HitGroup
			self.LastHitBox = trace.HitBox
		end
	end
end

function ENT:OnInjured(dmginfo)
    local attacker, inflictor = dmginfo:GetAttacker() or self, dmginfo:GetInflictor() or self

    self:Input("OnDamaged", attacker, inflictor)
    if attacker:IsPlayer() then
        self:Input("OnDamagedByPlayer", attacker, inflictor)
    end

    local damage = dmginfo:GetDamage()
    self:SetHealth(self:Health() - damage)

    if self:Health() <= (self:GetMaxHealth() / 2) then
        self:Input("OnHalfHealth", attacker, inflictor)
    end

    if damage > 0 and not self:IsOnFire() then
        self:SpawnBloodEffect(dmginfo:GetDamagePosition(), damage)

        if self:Health() > 0 then
            self:PlayVoiceSound(self.PainSounds)
        end
    end
end

function ENT:SpawnBloodEffect(pos, damage)
    local effect = EffectData()
        effect:SetOrigin(pos)
        effect:SetScale(4)
        effect:SetEntity(self)
        effect:SetColor(self:GetBloodColor())
    util.Effect("BloodImpact", effect, true, true)

    local effect = EffectData()
        effect:SetOrigin(pos)
        effect:SetScale(6)
        effect:SetEntity(self)
        effect:SetColor(self:GetBloodColor())
        effect:SetFlags(3)
    util.Effect("bloodspray", effect, true, true)
end

function ENT:PlayAttackSequence( func )
    if self.AttackSounds then
        self:PlayVoiceSound(self.AttackSounds)
    end

    local do_attack = function( me )
        if IsValid( me ) then
            me:PerformAttack()
            if func then
                func( self )
            end
        end
    end

    self:PlaySequenceAndWaitCallback( self:SelectWeightedSequence( ACT_MELEE_ATTACK1 ), 1, do_attack, 0.55 )
end

--[[function ENT:HandleAnimEvent(event, eventTime, cycle, type, options)
    if event == AE_ZOMBIE_ATTACK_RIGHT or event == AE_ZOMBIE_ATTACK_LEFT or event == AE_ZOMBIE_ATTACK_BOTH then
        self.IsAttacking = true
        self:PerformAttack()
    elseif event == AE_ZOMBIE_SWATITEM then
        self.bPlayingSwatSeq = true
        self:PerformAttack()
    end
end]]

function ENT:CalculateMeleeDamageForce(info, vecMeleeDir, vecForceOrigin, flScale)
    info:SetDamagePosition(vecForceOrigin)

    local flForceScale = info:GetBaseDamage() * (75 * 4)
    local vecForce = vecMeleeDir
    vecForce:Normalize()

    vecForce = vecForce * flForceScale;
    vecForce = vecForce * GetConVar("phys_pushscale"):GetFloat()

    if flScale then
        vecForce = vecForce * flScale
    end

    info:SetDamageForce(vecForce)
end

local check_hull_attack_trace = { mask = MASK_SHOT_HULL, output = {} }
function ENT:CheckTraceHullAttack(vStart, vEnd, mins, maxs, iDamage, iDmgType, flForceScale, bDamageAnyNPC)
    local dmgInfo = DamageInfo()
    dmgInfo:SetAttacker(self)
    dmgInfo:SetInflictor(self)
    dmgInfo:SetDamage(iDamage)
    dmgInfo:SetDamageType(iDmgType)

	check_hull_attack_trace.start = vStart
    check_hull_attack_trace.endpos = vEnd
    check_hull_attack_trace.filter = self
    check_hull_attack_trace.mins = mins
    check_hull_attack_trace.maxs = maxs

	local tr = util.TraceHull( check_hull_attack_trace )

    /*local tr = util.TraceHull({
        start = vStart,
        endpos = vEnd,
        filter = self,
        mins = mins,
        maxs = maxs,
        mask = MASK_SHOT_HULL
    })*/
    local pEntity = tr.Entity
    if not IsValid(pEntity) or (pEntity:IsPlayer() and not pEntity:Alive()) then
        return NULL
    end

    // Must hate the hit entity
    if self:GetRelationship(pEntity) == D_HT and !pEntity:IsNextBot() then
        if iDamage > 0 then
            self:CalculateMeleeDamageForce(dmgInfo, (vEnd - vStart), vStart, flForceScale)
            pEntity:TakeDamageInfo(dmgInfo)

            if bit.band(iDmgType, DMG_BURN) ~= 0 then
                pEntity:Ignite(2)
            end
        end
    end

    return pEntity
end

local claw_attack_trace = { mins = -Vector(8,8,8), maxs = Vector(8,8,8), mask = MASK_SOLID_BRUSHONLY, output = {} }
local claw_attack_trace2 = { mask = MASK_SHOT_HULL, output = {} }
function ENT:ClawAttack(flDist, iDamage, qaViewPunch, vecVelocityPunch)
    local iDamageType = self.DamageType

    if self:IsOnFire() then
        iDamage = iDamage * (math.Rand(1, 2))
        iDamageType = DMG_BURN
    end

    if IsValid(self:GetEnemy()) then

		claw_attack_trace.start = self:WorldSpaceCenter()
		claw_attack_trace.endpos = self:GetEnemy():WorldSpaceCenter()
		claw_attack_trace.filter = self

		local tr = util.TraceHull( claw_attack_trace )

        /*local tr = util.TraceHull({
            start = self:WorldSpaceCenter(),
            endpos = self:GetEnemy():WorldSpaceCenter(),
            filter = self,
            mins = -Vector(8,8,8),
            maxs = Vector(8,8,8),
            mask = MASK_SOLID_BRUSHONLY
        })*/

        if tr.Fraction < 1 then
            return NULL
        end
    end

    local vecMins = self:OBBMins()
    local vecMaxs = self:OBBMaxs()
    vecMins.z = vecMins.x * self.AttackHullZMul
    vecMaxs.z = vecMaxs.x

    local pHurt = self:CheckTraceHullAttack(self:EyePos(), self:EyePos() + self:GetAngles():Forward() * flDist, vecMins, vecMaxs, iDamage, iDamageType)
    if IsValid(pHurt) then
        self:PlayVoiceSound(self.ClawHitSounds)

        local pPlayer = pHurt
        if pPlayer ~= NULL and pPlayer:IsPlayer() and not pPlayer:IsFlagSet(FL_GODMODE) then
            pPlayer:ViewPunch(qaViewPunch)
            pPlayer:SetVelocity(pPlayer:GetVelocity() + vecVelocityPunch)

            local flNoise = 6.0
            local traceHit

            for i=0, 6 do
                local vecTraceDir

                if math.random(0, 10) == 5 then
                    vecTraceDir = pPlayer:EyePos()
                    vecTraceDir.z = vecTraceDir.z - math.Rand(-flNoise, 0.0)
                else
                    local dir = pPlayer:GetPos() - self:GetPos()
                    dir:Normalize()

                    local angles = dir:Angle()
                    local forward = angles:Forward()

                    vecTraceDir = self:WorldSpaceCenter() + (forward * 128 )

                    vecTraceDir.x = vecTraceDir.x + math.Rand(-flNoise, flNoise)
                    vecTraceDir.y = vecTraceDir.y + math.Rand(-flNoise, flNoise)
                    vecTraceDir.z = vecTraceDir.z + math.Rand(-flNoise, flNoise + 10.0)
                end

				claw_attack_trace2.start = self:WorldSpaceCenter()
                claw_attack_trace2.endpos = vecTraceDir
                claw_attack_trace2.filter = self

				traceHit = util.TraceLine( claw_attack_trace2 )

                /*traceHit = util.TraceLine({
                    start = self:WorldSpaceCenter(),
                    endpos = vecTraceDir,
                    filter = self,
                    mask = MASK_SHOT_HULL
                })*/

                local effect = EffectData()
                    effect:SetOrigin(traceHit.HitPos + Vector(0, 0, 40))
                    effect:SetScale(2)
                util.Effect("BloodImpact", effect, true, true)
            end
        end
    else
        self:PlayVoiceSound(self.ClawMissSounds)
    end

    return pHurt
end

local nearest_phys_obj_trace = { output = {} }
function ENT:FindNearestPhysicsObject()
    local entity = NULL
	local barricade = NULL
    local entities = ents.FindInSphere( self:WorldSpaceCenter(), 60 )

	local is_barricade = false

    for k, v in pairs(entities) do
        local class = v:GetClass()
        if (string.find(class, "prop_physics*") or class == "func_breakable" or string.find(class, "func_phys*")) then
			local phys = v:GetPhysicsObject()
			if IsValid( phys ) then
				if phys:IsMotionEnabled() then
					entity = v
					break
				else
					if v:Health() > 0 then
						barricade = v
					end
				end
			end
        end
    end

	if IsValid( entity ) and !self.CanSwatPhysicsObjects then
		entity = NULL
	end

	if !IsValid( entity ) and IsValid( barricade ) then
		entity = barricade
		is_barricade = true
	end

    if IsValid(entity) then

		nearest_phys_obj_trace.start = self:WorldSpaceCenter()
        nearest_phys_obj_trace.endpos = entity:NearestPoint( self:WorldSpaceCenter() )
        nearest_phys_obj_trace.filter = self

		/*local trace = {}
        trace.start = self:WorldSpaceCenter()
        trace.endpos = entity:NearestPoint( self:WorldSpaceCenter() )
        trace.filter = self

        local tr = util.TraceLine(trace)*/

		local tr = util.TraceLine( nearest_phys_obj_trace )
        if not tr.HitWorld or is_barricade then
            return entity, is_barricade
        end
    end
end

function ENT:SwatObject(pPhysObj, direction)
    local targetmass = pPhysObj:GetMass()
    local liftforce = math.Remap(targetmass, 5, 350, 3000, GetConVar("zm_zombieswatlift"):GetFloat())
    local uplift = Vector(0, 0, liftforce)
    local swatforce = math.Remap(targetmass, 5, 500, GetConVar("zm_zombieswatforcemin"):GetFloat(), GetConVar("zm_zombieswatforcemax"):GetFloat())

    pPhysObj:ApplyForceCenter(direction * swatforce + uplift)
    self.ePhysicsEnt = nil
end

function ENT:GetClawAttackRange()
    return self.AttackRange
end

function ENT:PerformAttack()
	self.IdleWander = CurTime() + 20
    if self.IsAttacking then
        local forward = self:GetAngles():Forward()
        local qaPunch = Angle(45, math.random(-5,5), math.random(-5,5))

        forward = forward * 200

        self:ClawAttack(self:GetClawAttackRange(), self.AttackDamage, qaPunch, forward)
    elseif self.bPlayingSwatSeq then
        local swat_ent = self.ePhysicsEnt
        if IsValid(self.ePhysicsEnt) then
            local phys = self.ePhysicsEnt:GetPhysicsObject()
            if IsValid(phys) then
                self:PlayVoiceSound(self.DoorHitSound)

                if self.ePhysicsEnt:GetClass() == "func_breakable" or !phys:IsMotionEnabled() then
                    self.ePhysicsEnt:TakeDamage(self.AttackDamage, self, self)
                    self.bPlayingSwatSeq = false
                    return
                end

                local physicsCenter = self:LocalToWorld(phys:GetMassCenter())

				local dir = self:GetAngles():Forward()

                /*if not IsValid(self:GetEnemy()) then
                    self.bPlayingSwatSeq = false
                    return
                end*/

				if IsValid(self:GetEnemy()) then
					local v = self:GetEnemy():WorldSpaceCenter() - physicsCenter
					v:Normalize()
					dir = v
				end

                self:SwatObject(phys, dir)
            end
        end

        self.bPlayingSwatSeq = false
    end
end

function ENT:PerformSwatScan( force_stuck )
    local swatent, is_cade = self:FindNearestPhysicsObject()
    if IsValid(swatent) then
        local enemy = self:GetEnemy()
        if force_stuck or IsValid(enemy) then

			if is_cade and force_stuck then
				self.FoundBreakable = true
				self.BreakableEnt = swatent
			else
				self.bPlayingSwatSeq = true
				self.ePhysicsEnt = swatent

				if not self.IsSwatting then
					self.IsSwatting = true
				end
			end
        end
		return true
    else
        self.ePhysicsEnt = nil
		return false
    end
end

function ENT:HandleDefenceMode()
	if self.InDefenceMode and self.NextDefenceCheck and CurTime() >= self.NextDefenceCheck then
       self.NextDefenceCheck = CurTime() + 1.0
	   if self:GetPos():DistToSqr(self.DefencePoint or self:GetPos()) > 512 * 512 then
            self:SetEnemy(NULL)
            self:ForceGo(self.DefencePoint or self:GetPos())
        end
        self.IdleWander = CurTime() + 10
    end
end

function ENT:HandleSwatting()
	if self.IsSwatting then
		self:RefreshStuckInfo( 2 )
		local cur_activity = self:GetActivity()
		self:PlayAttackSequence()
		self:StartActivityFixed( cur_activity )
		self.IsSwatting = false
	end
end

function ENT:HandleEnemies()

	self.NextEnemyUpdate = self.NextEnemyUpdate or CurTime() + 1

	local enemy = self:GetEnemy()

	-- move this outside so path repathing option takes priority in how often to update position
	if IsValid( enemy ) and enemy:IsPlayer() then
		self.GoalTolerance = self.AttackRange * 0.7
		self.m_vecLastPosition = enemy:GetPos()
	end

	if self.NextEnemyUpdate >= CurTime() then return end

	local delay = 0.1

    if IsValid(enemy) and enemy:IsPlayer() then

		if enemy:IsPlayer() and !enemy:Alive() then
			self:UpdateEnemy( NULL )
			self.NextEnemyUpdate = CurTime() + math.random(2)
			return
		end

		if self.OverrideAttackLogic then
			self:OverrideAttackLogic( enemy )
		else
			local melee = self:MeleeAttack1Conditions(self:GetPos():Dot(enemy:GetPos()), self:GetPos():DistToSqr(enemy:GetPos()))
			if melee and not self.IsAttacking then
				self.IsAttacking = true
			end
		end

		delay = self.OverrideAttackDelay or 1 // don't change target too fast on your own
    end

	self:FindEnemy()

	self.NextEnemyUpdate = CurTime() + delay

end

function ENT:HandleTargetAttacking()
	if self.IsAttacking then
		self:RefreshStuckInfo( 2 )
		local cur_activity = self:GetActivity()
		self:PlayAttackSequence()
		self:StartActivityFixed( cur_activity )
		self.IsAttacking = false
	end
end

function ENT:Think()

	local phys = self:GetPhysicsObject()

	if IsValid( phys ) then
		phys:SetPos( self:GetPos(), true )
	end

	if self.NextIdleMoan < CurTime() then
        self:PlayVoiceSound(self.MoanSounds, CHAN_AUTO + 2  )
        self.NextIdleMoan = CurTime() + math.random(15, 25)
    end

    if not self.IsAttacking and CurTime() >= self.NextSwatScan then
        self:PerformSwatScan()
        self.NextSwatScan = CurTime() + math.random(5, 10)
    end

    if self:GetGroundSpeedVelocity():LengthSqr() > 0 and self:IsOnGround() and self:GetGroundEntity() ~= nil and not self.IsFloating then
        if self.MoveTime < CurTime() and self.MoveSounds then
            self:PlayVoiceSound(self.MoveSounds, CHAN_AUTO + 3)
			if self.OnFootStepSound then
				self:OnFootStepSound()
			end
            self.MoveTime = CurTime() + self.FootStepTime
        end
    end

	if self.IsAttacking and IsValid( self:GetEnemy() ) and self:GetEnemy():IsPlayer() and ( self.NextAttackTracking or 0 ) < CurTime() then
		self.loco:FaceTowards( self:GetEnemy():GetPos() )
		self.NextAttackTracking = CurTime() + 0.25
	end

	self:HandleDefenceMode()
	self:HandleEnemies()

    if self.CustomThink then
        self:CustomThink()
    end
end

function ENT:OnContact( ent )
	self.LastTouched = ent
end
-- Force idle bots out of the way if we touch them
function ENT:HandlePathCollision( path )

    local ent = self.LastTouched

    if IsValid( ent ) then

        if ent:IsNextBot() and !IsValid( ent.CurPath ) then
            local push_dir = ent:WorldSpaceCenter() - self:WorldSpaceCenter()
            push_dir:Normalize()

            local goal_pos = ent:GetPos() + push_dir * math.random( 70, 90 ) + VectorRand( -5, 5 )
            local goal_area = navmesh.GetNavArea( goal_pos, 10 )
            if IsValid( goal_area ) then
                goal_pos = goal_area:GetClosestPointOnArea( goal_pos )
                ent:ForceGo( goal_pos )
            end
        end

    end

end

local cheap_stuck_trace = { mins = -Vector( 20, 20, 20 ), maxs = Vector( 20, 20, 20 ), collisiongroup = COLLISION_GROUP_NPC, mask = MASK_NPCSOLID, ignoreworld = true, output = {} }
local cheap_ground_trace = { collisiongroup = COLLISION_GROUP_DEBRIS, output = {} }
function ENT:HandleStuck( path )

	if !self:IsOnGround() then
		self:SetPos( self:GetPos() + self:GetAngles():Forward() * 20 + vector_up * 20 )
	end

	if not self.IsAttacking then

		local ent

		cheap_stuck_trace.start = self:WorldSpaceCenter()
		cheap_stuck_trace.endpos = self:WorldSpaceCenter() + self:GetForward() * 10
		cheap_stuck_trace.filter = self

		local tr = util.TraceHull( cheap_stuck_trace )
		-- check the trace first, that ignores world, since OnTouch can sometimes return the world if bot is stuck between the wall and anotehr bot
		if IsValid( tr.Entity ) and tr.Entity:IsNextBot() and !IsValid( tr.Entity.CurPath ) then
			ent = tr.Entity
		end
		-- then check the touch entity
		if IsValid( self.LastTouched ) and self.LastTouched:IsNextBot() and !IsValid( self.LastTouched.CurPath ) then
			ent = self.LastTouched
		end
		-- force idle bot to the side and reset stuck info
		if IsValid( ent ) then
			local push_dir = ent:WorldSpaceCenter() - self:WorldSpaceCenter()
			push_dir:Normalize()

			push_dir = push_dir * math.random( 70, 90 ) + VectorRand( -5, 5 )

			local goto_pos = ent:GetPos() + push_dir

			cheap_ground_trace.start = goto_pos + vector_up * 5
			cheap_ground_trace.endpos = goto_pos - vector_up * 5

			local tr = util.TraceLine( cheap_ground_trace )

			if !tr.HitWorld then
				goto_pos = ent:GetPos() - push_dir
			end

			ent:ForceGo( goto_pos )

			self.StuckAttempts = 0
			return
		end

        local can_swat = self:PerformSwatScan( true )

		if !can_swat and self.OverrideHandleStuck then
			self:OverrideHandleStuck()
		end

        self.NextSwatScan = CurTime() + math.random(5, 15) // delay just in case
    end

end

function ENT:OnStuck()
	//print( tostring(self).." IS STUCK" )
end

function ENT:OnUnStuck()
	//print( tostring(self).." IS NO LONGER STUCK" )
end

function ENT:OnNavAreaChanged( old, new )

end

-- a small snippet from how jump velocity is calculated in Zombie Master Reborn, cus default jumping is bad
function ENT:CalculateJumpVelocity( end_pos, min_height, max_horz_vel )

	local gravity = math.max( 1, self.loco:GetGravity() )

	local start_pos = self:GetPos()

	local step_height = end_pos.z - start_pos.z

	local target_dir_2d = end_pos - start_pos
	target_dir_2d.z = 0

	local distance = target_dir_2d:GetNormalized():Length()

	local min_horz_time = distance / max_horz_vel
	local min_horz_height = 0.5 * gravity * ( min_horz_time * 0.5 ) * ( min_horz_time * 0.5 )

	min_height = math.max( min_height, min_horz_height )
	min_height = math.max( min_height, step_height )

	local t0 = math.sqrt( ( 2 * min_height ) / gravity )
	local t1 = math.sqrt( ( 2 * math.abs( min_height - step_height ) ) / gravity )

	local vel_horz = distance / ( t0 + t1 )

	local jump_vel = target_dir_2d * vel_horz

	jump_vel.z = math.sqrt( 2 * self.loco:GetGravity() * min_height)

	return jump_vel

end

function ENT:RefreshStuckInfo( time )
	self.StuckPos = self:GetPos()
	self.NextStuckCheck = CurTime() + ( time or 2 )
end

function ENT:MoveToPos( pos, options )

	local options = options or {}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 200 )
	path:SetGoalTolerance( options.tolerance or self.GoalTolerance )
	if self.OverridePathCompute then
		self:OverridePathCompute( path, self.m_vecValidPosition or self.m_vecLastPosition or pos )
	else
		path:Compute( self, self.m_vecValidPosition or self.m_vecLastPosition or pos )
	end

	if ( !path:IsValid() ) then return "failed" end

	self.CurPath = path
	self.StuckAttempts = 0

	self:RefreshStuckInfo( 2 )

	self.loco:ClearStuck()

	while ( path:IsValid() ) do

		self.NextBreakableScan = CurTime() + 2.0

		-- handle stuff mid path
		GAMEMODE:CallZombieFunction(self, "RunBehaviour")
		self:HandleSwatting()
		self:HandleTargetAttacking()

		local repath = 1

		local enemy = self:GetEnemy()

		-- force faster repath when tracking enemies, but only when close enough (to fix banshee's pathing and for optimisation, I guess)
		if IsValid( enemy ) and enemy:IsPlayer() and self:GetPos():DistToSqr( enemy:GetPos() ) < ( self.AttackRange * 3 * self.AttackRange * 3 ) then
			repath = 0.1
		end

		-- a very hacky and very stupid way to prevent bots from going onto unreachable areas
		-- UPDATE 26/01/21: not needed anymore but I'll keep the code just in case
		/*local cur_goal = path:GetCurrentGoal()
		local first = path:FirstSegment()
		local segments = path:GetAllSegments()

		if first and cur_goal and !first.area:IsConnected( cur_goal.area ) and #segments == 2 then
			if not self.m_vecValidPosition then
				self.m_vecValidPosition = first.area:GetClosestPointOnArea( self.m_vecLastPosition or pos )
				self.m_vecValidPosition = self.m_vecValidPosition - cur_goal.forward * 32
				repath = 0.01 // no need to delay this
			end
		end*/

		if self.OverridePathUpdate then
			self:OverridePathUpdate( path )
		else
			path:Update( self )
			local new_pos = NEXTBOT_CustomAvoidOverride( self, path )
			if new_pos then
				self.loco:Approach( new_pos, 1 )
			end
		end

		if ( options.draw ) then
			path:Draw()
		end

		if self.ForceRepath then

			self.StuckAttempts = 0
			self.loco:ClearStuck()
			self:RefreshStuckInfo( 0.5 )

			if path.idle then
				self.ForceRepath = nil
				return "stopping idle path"
			else
				path:SetGoalTolerance( self.GoalTolerance )
				if self.OverridePathCompute then
					self:OverridePathCompute( path, self.ForceRepath )
				else
					path:Compute( self, self.ForceRepath )
				end
			end

			self.ForceRepath = nil
		end

		local override_stuck = false

		-- extra measures cus csometimes locomotion stuck is very slow
		if self.NextStuckCheck < CurTime() then
			if self:GetPos():DistToSqr( self.StuckPos ) < 3 * 3 then
				self:HandlePathCollision( path )
				override_stuck = true
			end
			self:RefreshStuckInfo( 0.5 )
		end

		if ( self.loco:IsStuck() ) or override_stuck then
			self.LastStuckTime = CurTime() + self.ClearStuckTime

			self.StuckAttempts = self.StuckAttempts + 1
			self:HandleStuck( path )

			//print(self, " is stuck  #",self.StuckAttempts)

			if self.StuckAttempts >= self.MaxStuckAttempts then
				return "stuck"
			else
				self.loco:ClearStuck()
			end
		end

		if self.StuckAttempts > 0 and self.LastStuckTime < CurTime() then
			self.StuckAttempts = 0
		end

		if ( options.maxage ) then
			if ( path:GetAge() > options.maxage ) then return "timeout" end
		end

		-- only use in non idle path
		if ( options.repath and repath ) then
			if ( path:GetAge() > repath ) then
				if self.OverridePathCompute then
					self:OverridePathCompute( path, self.m_vecValidPosition or self.m_vecLastPosition or pos )
				else
					path:Compute( self, self.m_vecValidPosition or self.m_vecLastPosition or pos )
				end
			end
		end

		coroutine.yield()

	end

	return "ok"

end

local options = { repath = 0.1 }
options.draw = ENT.DebugPath

local options_idle = { idle = true, maxage = 5 }
options_idle.draw = ENT.DebugPath

function ENT:RunBehaviour()

	while ( true ) do

		GAMEMODE:CallZombieFunction(self, "RunBehaviour")

		-- handle stuff when we have NO path
		self:HandleSwatting()
		self:HandleTargetAttacking()

		if self.m_vecLastPosition and not self.IsAttacking then

			self.PlayIdleAnims = false
			if self:GetMoveActivity() then
				self:StartActivityFixed( self:GetMoveActivity() )
			end

			local move = self:MoveToPos( self.m_vecLastPosition, options )
			self.m_vecLastPosition = nil
			self.ReceivedOrders = 0
			self.NextBreakableScan = CurTime() + 2.0
		else
			-- hacky stuff, no time to explain
			if !self.PlayIdleAnims then
				self.PlayIdleAnims = true
			end

			if self.IdleWander < CurTime() then

				if math.random(2) == 2 then
					local random_pos = self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 200
					local area = navmesh.GetNavArea( random_pos, 30 )
					if IsValid( area ) and self.loco:IsAreaTraversable( area ) then
						random_pos = area:GetClosestPointOnArea( random_pos )
						self.PlayIdleAnims = false
						if self:GetMoveActivity() then
							self:StartActivityFixed( self:GetMoveActivity() )
						end
						self:MoveToPos( random_pos, options_idle )
					end
				end

				self.IdleWander = CurTime() + math.random( 10, 15 )
			end
		end

		coroutine.yield()
	end

end

function ENT:StartActivityFixed( act )
	self:StartActivity( ACT_RESET )
	self:StartActivity( act )
end

function ENT:PlaySequenceAndWait( name, speed )

	self.PlayIdleAnims = false

	self:ResetSequence( name )
	local len = self:SequenceDuration()
	speed = speed or 1

	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( speed )

	self.IsPlayingSequence = CurTime() + len / speed

	coroutine.wait( len / speed )

end

-- same as above but mid animation you can call something (basically it is like a timer but less shitty)
function ENT:PlaySequenceAndWaitCallback( name, speed, func, offset )

	self.PlayIdleAnims = false

	self:ResetSequence( name )
	local len = self:SequenceDuration()
	speed = speed or 1

	self:ResetSequenceInfo()
	self:SetCycle( 0 )
	self:SetPlaybackRate( speed )

	local dur = len / speed

	self.IsPlayingSequence = CurTime() + dur

	coroutine.wait( dur * offset )

	func( self )

	coroutine.wait( dur * ( 1 - offset ) )

end

function ENT:BodyUpdate()

	local act = self:GetActivity()

	local speed = self.loco:GetVelocity()
	speed.z = 0
	local len = speed:LengthSqr()

	if self.IsPlayingSequence and self.IsPlayingSequence >= CurTime() then
	else
		if self.PlayIdleAnims then
			self:ResetSequence( self:GetIdleSequence() )
		else
			if act == self:GetMoveActivity() then
				local speed = self.DesiredSpeed or 100 // do not set "ENT.Desired = blah" outside, so it wont break on lua autorefresh (it is not gamebreaking but very annoying)
				local delta = ( len ) / ( speed * speed ) * self.AnimationPlaybackMultiplier
				self:SetPlaybackRate( math.Clamp( delta, 0, 10 ) )
			else
				self:SetPlaybackRate( 1 )
			end
		end

	end

	self:FrameAdvance()

end

function ENT:GetMoveActivity()
	return ACT_WALK
end

function ENT:GetIdleSequence()
	return "Idle01"
end

function ENT:ResetBreakables()
	self.FoundBreakable = false
    self.BreakableEnt = nil
    self.NextBreakableScan = CurTime() + 2.0
end

-- Backward compatibility

function ENT:ForceGo(targetPos, tolerance)

	self:ResetBreakables()

	self:SetEnemy( NULL )
	self.ReceivedOrders = CurTime() + 5

	self.GoalTolerance = tolerance or 26
	self.m_vecLastPosition = targetPos
	self.ForceRepath = targetPos

	self.m_vecValidPosition = nil

	self.IdleWander = CurTime() + 20

	GAMEMODE:CallZombieFunction(self, "OnForceGo")

end

function ENT:ForceSwat(pTarget, breakable, rawpos )

    if not IsValid(pTarget) then return end
    if pTarget:IsNextBot() then return end

    if pTarget:IsPlayer() then
        self:ForceGo(pTarget:GetPos())
        self:UpdateEnemy( pTarget )
        return
    end

    self:ForceGo( breakable and rawpos or pTarget:GetPos(), self.AttackRange) // get close but not too close :O

    if breakable then
        self.FoundBreakable = true
        self.BreakableEnt = pTarget
    end

end

function ENT:StopMoving()
end

local team_GetPlayers = team.GetPlayers
local cached_survivors = {}
local table_Shuffle = table.Shuffle
function ENT:FindEnemy()

	if self.ReceivedOrders and self.ReceivedOrders > CurTime() then return end

	self.NextEnemyCache = self.NextEnemyCache or 0

	if self.NextEnemyCache < CurTime() then
		cached_survivors  = team_GetPlayers( TEAM_SURVIVOR )
		table_Shuffle(cached_survivors)
		self.NextEnemyCache = CurTime() + 3
	end

	local survivors = cached_survivors
	local cur_enemy = self:GetEnemy()

	local new_enemy
	local dist_to_new_enemy_sqr

	for i=1, #survivors do
		local pl = survivors[ i ]
		if IsValid( pl ) and pl:Alive() and pl ~= cur_enemy then
            if !self:Visible( pl ) then continue end
			local dist_sqr = self:GetPos():DistToSqr( pl:GetPos() )
			if dist_sqr > self:EnemyDistanceScan() then continue end

			if IsValid( new_enemy ) and dist_to_new_enemy_sqr then
				if dist_sqr < dist_to_new_enemy_sqr then
					new_enemy = pl
					dist_to_new_enemy_sqr = dist_sqr * 1
				end
			else
				new_enemy = pl
				dist_to_new_enemy_sqr = dist_sqr * 1
			end
			//break
		end
	end

	-- target closer enemy
	if IsValid( cur_enemy ) then
		if IsValid( new_enemy ) and dist_to_new_enemy_sqr then
			if dist_to_new_enemy_sqr < self:GetPos():DistToSqr( cur_enemy:GetPos() ) then
				self:UpdateEnemy( new_enemy )
			end
		else
			-- nothing
		end
	else
		self:UpdateEnemy( new_enemy )
	end

end

function ENT:UpdateEnemy(enemy)
	if IsValid(enemy) and enemy ~= self then

		-- prevent mini spam when bot is trying to target between enemies
		if !IsValid( self:GetEnemy() ) then
			if self.PlayVoiceSound then
				self:PlayVoiceSound(self.AlertSounds)
			end
        else
            if self:GetEnemy():IsPlayer() then
                self:Input("OnLostPlayer", nil, self)
            end
            self:Input("OnLostEnemy", nil, self)
		end

        if enemy:IsPlayer() then
            self:Input("OnFoundPlayer", nil, self, enemy:GetName())
        end
        self:Input("OnFoundEnemy", nil, self, enemy:GetName())

		self:SetEnemy(enemy)

		self.m_vecLastPosition = targetPos
		self.ForceRepath = targetPos

		if self.OnEnemyFound then
			self:OnEnemyFound()
		end

    else
        self:SetEnemy(NULL)
    end
end

function ENT:SetEnemy( enemy )
	if enemy == self then enemy = NULL end
	self.m_Enemy = enemy
end

function ENT:GetEnemy()
	return self.m_Enemy
end

function ENT:KeyValue(key, value)
    key = string.lower(key)
    if string.Left(key, 2) == "on" then
        self:StoreOutput(key, value)
    end
end

function ENT:AcceptInput(name, caller, activator, arg)
    name = string.lower(name)
    if string.Left(name, 2) == "on" then
        self:TriggerOutput(name, activator, arg)
    end
end

function ENT:SetMaxYawSpeed( speed )
end

function ENT:SetHullType( hull )
end

function ENT:IsCurrentSchedule( sched )
	return false
end

function ENT:SetSchedule( sched )
end

function ENT:SetCondition( cond )
end

function ENT:SetTarget( target )
end

function ENT:HasCondition( cond )
	return false
end

function ENT:CapabilitiesAdd()
end

function ENT:CapabilitiesClear()
end

local function AcceptInputNextBot( ent, inp, activator, caller, value )
    if ent:GetClass() == "trigger_push" then
        if activator:IsNextBot() then

            local speed = caller:GetInternalVariable( "speed" )
            local dir = caller:GetInternalVariable( "pushdir" )

            if speed and dir then
                activator.loco:Jump()
                activator.loco:SetVelocity( ( dir + vector_up * 0.4 ) * speed )
            end

        end
    end
end
hook.Add( "AcceptInput", "AcceptInputNextBot", AcceptInputNextBot )

local function TriggerPushOutput()
    for k, v in pairs( ents.FindByClass( "trigger_push" ) ) do
        v:Fire( "AddOutput", "OnStartTouch !self" )
    end
end
hook.Add( "InitPostEntity", "TriggerPushOutput", TriggerPushOutput )
hook.Add( "PostCleanupMap", "TriggerPushOutput", TriggerPushOutput )