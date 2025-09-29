NPC.HullType = HULL_HUMAN
NPC.SolidType = SOLID_BBOX
NPC.MoveType = MOVETYPE_STEP
NPC.BloodColor = BLOOD_COLOR_RED

NPC.bUseAdvancedZombieAI = true
NPC.AnimationSpeed = 1

NPC.SpawnFlags = bit.bor(SF_NPC_ALWAYSTHINK, SF_NPC_ALTCOLLISION, SF_NPC_LONG_RANGE, SF_NPC_FALL_TO_GROUND)
NPC.Capabilities = bit.bor(CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1, CAP_SKIP_NAV_GROUND_CHECK)

function NPC:OnSpawned(npc)
    npc:SetBloodColor(self.BloodColor)
    
    self:SetupCapabilities(npc)
    
    if self.HullType then
        npc:SetHullType(self.HullType)
    end
    
    if self.HullSizeMins and self.HullSizeMaxs then
        npc:SetCollisionBounds(self.HullSizeMins, self.HullSizeMaxs)
        timer.Simple( 0, function()
            if IsValid( npc ) and self.HullSizeMins and self.HullSizeMaxs then
                npc:SetCollisionBounds(self.HullSizeMins, self.HullSizeMaxs)
            end
        end)
    end
    
    if self.IsEngineNPC ~= nil then
        npc:SetSaveValue("m_fIsHeadless", true)
        if self.Class == "npc_poisonzombie" then
            npc:SetSaveValue("m_fIsTorso", true)
        end
        npc:SetKeyValue("crabcount", "0")
        npc.IsEngineNPC = self.IsEngineNPC 
    end
  
    npc.NextBreakableScan = CurTime()
    
    npc:SetSolid(self.SolidType)
	if not npc:IsNextBot() then
		npc:SetMoveType(self.MoveType)
	end
    //npc:SetSelected(false)
	npc:SetSelected(nil)
    
    if self.Health and self.Health ~= 0 then
        npc:SetHealth(self.Health)
        npc:SetMaxHealth(self.Health)
    end
    
    if self.MaxYawSpeed then
        npc:SetMaxYawSpeed(self.MaxYawSpeed)
    end
    
	if self.AnimationPlaybackMultiplier then
        npc.AnimationPlaybackMultiplier = self.AnimationPlaybackMultiplier
	end
    
	if npc:IsNextBot() and self.Speed then
		npc.DesiredSpeed = self.Speed
		npc.loco:SetDesiredSpeed( self.Speed )
	end

    if not npc:IsNextBot() then
        npc:SetNPCState(NPC_STATE_ALERT)
    end
    
    if npc:IsNextBot() then
        npc:SetLagCompensated(true)
    end
    
    npc:UpdateEnemy(npc:FindEnemy())
    npc:AddSolidFlags(FSOLID_NOT_STANDABLE)
    
    npc.FriendlyName = Name
end

function NPC:GetHullSizes(npc)
    if self.HullSizeMins and self.HullSizeMaxs then
        return Vector(self.HullSizeMins), Vector(self.HullSizeMaxs)
    end
    
    if self.HullType then
        local mins, maxs = GetAIHullSize(self.HullType)
        if not mins:IsZero() and not maxs:IsZero() then
            return mins, maxs
        end
    end

    return Vector(npc:OBBMins()), Vector(npc:OBBMaxs())
end

function NPC:SetupCapabilities(npc)
    if not self.Capabilities then return end
    
    npc:CapabilitiesClear()
    npc:CapabilitiesAdd(self.Capabilities)
end

function NPC:OnScaledDamage(npc, hitgroup, dmginfo)
    local damagetype = dmginfo:GetDamageType()
    if damagetype ~= DMG_CLUB then
        if hitgroup == HITGROUP_HEAD then
            if bit.band(damagetype, DMG_BUCKSHOT) ~= 0 then
                local flDist = 1024
                if IsValid(dmginfo:GetAttacker()) then
                    flDist = (npc:GetPos() - dmginfo:GetAttacker():GetPos()):Length()
                end

                if flDist <= ZOMBIE_BUCKSHOT_TRIPLE_DAMAGE_DIST then
                    dmginfo:ScaleDamage(3)
                end
            else
                dmginfo:ScaleDamage(2)
            end
        elseif hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then
            dmginfo:ScaleDamage(0.25)
        end
    end
end

function NPC:OnTakeDamage(npc, attacker, inflictor, dmginfo)
    local damage = dmginfo:GetDamage()
    if damage > 0 and ( bit.band(dmginfo:GetDamageType(), DMG_BULLET) ~= 0 or bit.band(dmginfo:GetDamageType(), DMG_CLUB) ~= 0 ) then
        npc.NextGore = npc.NextGore or 0

        if npc.LastHitBox and npc.LastHitGroup and ( npc.LastHitGroup ~= 0 or npc.NoHitGroupFix ) and ( npc:Health() <= npc:GetMaxHealth() * 0.75 or damage >= npc:GetMaxHealth() * 0.25 ) and npc.NextGore < CurTime() then
            local effect = EffectData()
                effect:SetEntity(npc)
                effect:SetOrigin(dmginfo:GetDamagePosition())
                effect:SetStart( dmginfo:GetDamageForce() )
                effect:SetScale( math.Clamp( damage / math.max( npc:GetMaxHealth()/3, 1 ), 0.6, 1.3 ) )
                effect:SetHitBox(npc.LastHitBox)
            util.Effect("bodydamage", effect)
            
            npc.NextGore = CurTime() + 0.05
        end
    end
    
    if IsValid(attacker) then
        local entteam = attacker.OwnerTeam
        if IsValid(attacker) and attacker:GetClass() == "env_fire" and entteam == TEAM_ZOMBIEMASTER then
            dmginfo:SetDamageType(DMG_BULLET)
            dmginfo:SetDamage(0)
            dmginfo:ScaleDamage(0)
            return true
        end
        
        if not IsValid(npc:GetEnemy()) and attacker:IsPlayer() then
            if npc.UpdateEnemy then
                npc:UpdateEnemy(attacker)
            else
                npc:SetEnemy(attacker)
                npc:SetTarget(attacker)
            end
        end
    end
    
    dmginfo:SetDamageType(bit.bor(dmginfo:GetDamageType(), DMG_REMOVENORAGDOLL, DMG_SNIPER))
end

function NPC:PostOnTakeDamage(npc, attacker, inflictor, dmginfo, took)
end

function NPC:OnKilled(npc, attacker, inflictor)
    local owner = npc:GetOwner()
    if IsValid(owner) and owner:IsPlayer() then
        local popCost = self.PopCost
        local population = GAMEMODE:GetCurZombiePop()

        popCost = popCost or 1

        GAMEMODE:TakeCurZombiePop(popCost)
    end
    
    if npc:IsNPC() then
        if npc.OverrideModel and npc.OverrideModel:IsValid() then
            net.Start("zm_forcecustomragdoll")
                net.WriteEntity(npc)
                net.WriteString(npc.OverrideModel:GetModel())
            net.Broadcast()
        else
            net.Start("zm_spawnclientragdoll")
                net.WriteEntity(npc)
            net.Broadcast()
        end
    end
    
    if IsValid(attacker) and attacker:IsPlayer() then
        attacker:AddFrags(1)
    end
end

function NPC:Think(npc)     
    if npc:IsNextBot() then return end
    
    /*if npc:HasCondition(COND_RECEIVED_ORDERS) then
        npc.FoundBreakable = false
        npc.BreakableEnt = nil
        npc.NextBreakableScan = CurTime() + 5.0
    end
    
    if (npc.NextBreakableScan and CurTime() >= npc.NextBreakableScan) or npc.FoundBreakable then
        if not IsValid(npc.BreakableEnt) then
            for _, ent in pairs(ents.FindInSphere(npc:WorldSpaceCenter(), 64)) do
                if string.sub(ent:GetClass(), 0, 5) == "func_" then
                    if ent:Health() > 0 and not ent:IsNPC() and not ent:IsPlayer() then
                        npc.BreakableEnt = ent
                        npc.FoundBreakable = true
                        npc:SetEnemy(ent)
                        npc:SetTarget(ent)
                        npc:SetSchedule(SCHED_TARGET_CHASE)
                        npc:SetNPCState(NPC_STATE_COMBAT)
                        break
                    end
                end
            end
            
            if not IsValid(npc.BreakableEnt) and npc.FoundBreakable then
                npc.FoundBreakable = false
            end
        else
            if npc:GetPos():Distance(npc.BreakableEnt:GetPos()) < (npc.GetClawAttackRange and npc:GetClawAttackRange() or 72) and not npc:IsCurrentSchedule(SCHED_MELEE_ATTACK1) then
                npc:SetNPCState(NPC_STATE_COMBAT)
                npc:SetEnemy(npc.BreakableEnt)
                npc:SetTarget(npc.BreakableEnt)
                npc:SetSchedule(SCHED_TARGET_FACE)
                
                timer.Simple(0.25, function()
                    if not IsValid(npc) then return end
                    
                    npc:SetSchedule(SCHED_MELEE_ATTACK1)
                    
                    if not npc.IsEngineNPC then
                        npc.IsAttacking = true
                        
                        local len = npc:SequenceDuration()
                        timer.Simple(len, function()
                            if not IsValid(npc) or not IsValid(npc.BreakableEnt) then return end
                            npc.BreakableEnt:TakeDamage(npc.AttackDamage, npc, npc)
                        end)
                    end
                end)
            end
        end
        
        npc.NextBreakableScan = CurTime() + 5.0
    end
    
    if IsValid(npc.BreakableEnt) then return end*/
    
    if npc.InDefenceMode and npc.NextDefenceCheck and CurTime() >= npc.NextDefenceCheck then
        if npc:GetPos():Distance(npc.DefencePoint or npc:GetPos()) > 512 then
            npc:SetEnemy(NULL)
            npc:SetSchedule(SCHED_AMBUSH)
            npc:SetCondition(COND_ENEMY_UNREACHABLE)
            npc:ForceGo(npc.DefencePoint or npc:GetPos())
        end
        
        npc.NextDefenceCheck = CurTime() + 1.0
    end
    
    self:ProcessNPCAI(npc)

    if npc:HasCondition(COND_TASK_FAILED) then
        npc.StopAIUntil = CurTime() + 2
    end

    if npc.StopAIUntil and CurTime() < npc.StopAIUntil then
        return
    end
    
    if self.bUseAdvancedZombieAI then
        local enemy = npc:GetEnemy()

        if IsValid(enemy) then
            local enemyDistance = npc:GetPos():Distance(enemy:GetPos())
            local meleeAttacking = npc:GetActivity() == ACT_MELEE_ATTACK1
            
            if enemyDistance <= 75 and not meleeAttacking then
                npc:SetSchedule(SCHED_MELEE_ATTACK1)
            end
            
			if npc.LastFrenzyEnemy ~= enemy or not npc.FrenzyBonus then
				npc.FrenzyBonus = 0
			end
			npc.LastFrenzyEnemy = enemy

			if meleeAttacking then
				npc.FrenzyBonus = math.Clamp(npc.FrenzyBonus + engine.TickInterval() / 3, 0, 2)
				npc:SetKeyValue("playbackrate", tostring(self.AnimationSpeed + npc.FrenzyBonus))
			else
				npc.FrenzyBonus = math.Clamp(npc.FrenzyBonus - engine.TickInterval(), 0, 2)
				npc:SetKeyValue("playbackrate", tostring(self.AnimationSpeed))
			end
        end
    end
end

function NPC:ProcessNPCAI(npc)
    local state = npc:GetNPCState()
    
    local dead = state == NPC_STATE_DEAD or npc:Health() <= 0
    if dead then return end
    
    local enemy = npc:GetEnemy()
    if IsValid(enemy) then
        if npc.LastEnemy ~= enemy then
            npc.LastEnemy = enemy
            npc:UpdateEnemyMemory(enemy, enemy:GetPos())
        end
    end
end

function NPC:RunBehaviour(npc)
	if not IsValid(npc.BreakableEnt) and npc.FoundBreakable then
		npc.FoundBreakable = false
	end
	
    if (npc.NextBreakableScan and CurTime() >= npc.NextBreakableScan) or npc.FoundBreakable then        
        npc.NextBreakableScan = CurTime() + 2.0
        local enemy = npc:GetEnemy()
        if not (IsValid(enemy) and enemy:IsPlayer()) or npc.StuckAttempts and npc.StuckAttempts > 0 then
            if not IsValid(npc.BreakableEnt) then
                for _, ent in pairs(ents.FindInSphere(npc:WorldSpaceCenter(), 64)) do					
					local found = false
					
					if string.sub(ent:GetClass(), 0, 5) == "func_" then
						found = true
					elseif string.sub(ent:GetClass(), 0, 12) == "prop_physics" then
						local phys = ent:GetPhysicsObject()
						if IsValid( phys ) and !phys:IsMotionEnabled()then
							found = true
						end
					end
					if found and ent:Health() > 0 and not ent:IsNPC() and not ent:IsNextBot() and not ent:IsPlayer() then
						npc.BreakableEnt = ent
						npc.FoundBreakable = true
						npc:UpdateEnemy(ent)
						break
					end
                end
            else				
				if npc:WorldSpaceCenter():Distance(npc.BreakableEnt:NearestPoint( npc:WorldSpaceCenter() )) < (npc.GetClawAttackRange and npc:GetClawAttackRange() or 72) then
					npc.loco:FaceTowards( npc.BreakableEnt:GetPos() )
					npc.loco:FaceTowards( npc.BreakableEnt:GetPos() )
					
					local hit = function( self )
						if IsValid( self ) and IsValid( self.BreakableEnt ) then
							self.BreakableEnt:TakeDamage(self.AttackDamage, self, self)
						end
					end
					
					npc.IsAttacking = true
					npc:RefreshStuckInfo( 5 )
					local cur_activity = npc:GetActivity()
					npc:PlayAttackSequence( hit )
					npc:StartActivityFixed( cur_activity )
					npc.IsAttacking = false
                end
            end
        end
    end	
end