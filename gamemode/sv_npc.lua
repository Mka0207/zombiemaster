local meta = FindMetaTable("NPC")
if not meta then return end

function meta:IsScripted()
    return scripted_ents.GetType(self:GetClass()) == "ai"
end

meta.CustomScheds = {}
function meta:DefineCustomSchedule(sched)
    if self.CustomScheds[sched.DebugName] then return end
    self.CustomScheds[sched.DebugName] = sched
end

function meta:GetCustomSchedule(name)
    return self.CustomScheds[name]
end

function meta:HasCustomSchedule(name)
    return self.CustomScheds[name] ~= nil
end

function meta:ForceGo(targetPos, traceDir)
    self:SetLastPosition(targetPos)
    self:SetSchedule(SCHED_FORCED_GO_RUN)
    self:SetCondition(COND_RECEIVED_ORDERS)
    self:SetEnemy(NULL)
    
    GAMEMODE:CallZombieFunction(self, "OnForceGo")
end

function meta:ForceSwat(pTarget, breakable)
    if not pTarget then return end
    if self:IsCurrentSchedule(SCHED_MELEE_ATTACK1) then return end
    
    if self:GetPos():Distance(pTarget:GetPos()) < (self.GetClawAttackRange and self:GetClawAttackRange() or 72) then
        self:SetEnemy(pTarget)
        self:SetTarget(pTarget)
        self:SetSchedule(SCHED_COMBAT_FACE)
        
        timer.Simple(0.25, function()
            self:SetSchedule(SCHED_MELEE_ATTACK1)
            
            if not self.IsEngineNPC then
                self.IsAttacking = true
                timer.Simple(1, function()
                    if not IsValid(self) then return end
                    pTarget:TakeDamage(self.AttackDamage, self, self)
                end)
            end
        end)
    else
        self:ForceGo(pTarget:GetPos())
    end
end

function meta:FindEnemy()
    local eyepos = self:EyePos()
    local eyedir = self:GetAimVector()
    local mypos = self:WorldSpaceCenter()
    for _, pl in ipairs(team.GetPlayers(TEAM_SURVIVOR)) do
        local pos = pl:WorldSpaceCenter()
        if mypos:DistToSqr(pos) > 1048576 and self:Visible(pl) then continue end
        self:UpdateEnemy(pl)
    end
end

function meta:UpdateEnemy(enemy)
    if self:IsCurrentSchedule(SCHED_FORCED_GO_RUN) then return end
    
    if IsValid(enemy) then
        self:SetEnemy(enemy)
        self:SetTarget(enemy)
        self:SetSchedule(SCHED_TARGET_CHASE)
        
        if self.PlayVoiceSound then
            self:PlayVoiceSound(self.AlertSounds)
        end
    else
        self:SetEnemy(NULL)
    end
end