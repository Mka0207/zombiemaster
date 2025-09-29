NPC.CanClingToCeiling = true
NPC.bUseAdvancedZombieAI = false
NPC.HullSizeMins = Vector(-13, -13, 0)
NPC.HullSizeMaxs = Vector(13, 13, 52)

NPC.Capabilities = bit.bor(CAP_MOVE_JUMP, CAP_MOVE_GROUND, CAP_INNATE_RANGE_ATTACK1, CAP_INNATE_MELEE_ATTACK1, CAP_MOVE_CLIMB, CAP_SKIP_NAV_GROUND_CHECK)

function NPC:OnSpawned(npc)
    self.BaseClass.OnSpawned(self, npc)
    
    npc.NextLeap = CurTime()
    
    if npc:IsNPC() then
        npc:SetCeilingCling(false)
    end
end

function NPC:OnKilled(npc, attacker, inflictor)
    self.BaseClass.OnKilled(self, npc, attacker, inflictor)
    if npc:IsNPC() then
        npc:SetCeilingCling(false)
    end
end

function NPC:IsCeilingFlat(npc, plane_normal)
    local flat = Vector(0, 0, -1)
    local roofdot = math.abs(plane_normal:Dot(flat))

    if roofdot > 0.95 then
        return true
    end

    return false
end

function NPC:CheckCeiling(npc, maxheight)
    local upwards = Vector(0, 0, maxheight or 375)
    local trace = {start = npc:GetPos(), endpos = npc:GetPos() + upwards, filter = npc, mask = MASK_SOLID}
    local tr = util.TraceLine(trace)

    if tr.Fraction ~= 1.0 and tr.HitWorld and not tr.HitSky then
        if self:IsCeilingFlat(npc, tr.HitNormal) then
            if npc:IsNPC() then
                local startpos = npc:GetPos()
                local targetpos = tr.HitPos - Vector(0, 0, 12)
                local targetang = npc:GetAngles()
                targetang.roll = -180
                
                npc.OldPos = startpos
                
                local timername = "npc_gotoceiling:"..npc:EntIndex()
                timer.Create(timername, 0, 0, function()
                    if not IsValid(npc) or not npc.m_bClinging then timer.Remove(timername) return end
                    
                    if npc:GetAngles() == targetang then
                        timer.Remove(timername)
                    end
                    
                    local fraction = FrameTime() * 5.0
                    local topos = LerpVector(fraction, npc:GetPos(), targetpos)
                    local toang = LerpAngle(fraction, npc:GetAngles(), targetang)
                    npc:SetPos(topos)
                    npc:SetAngles(toang)
                end)
            else
                local startpos = npc:GetPos()
                local targetpos = tr.HitPos
                
                npc:AttachToCeiling( targetpos )
            end
            
            return true
        end
    end

    return false
end

function NPC:GetClingAmbushTarget(npc)
    local pos = npc.OldPos or npc:GetPos()
    local count = ents.FindInSphere(pos, 64)
    
    local nearest = NULL
    local nearest_dist = 0
    for _, ent in pairs(count) do
        if not ent:IsPlayer() or not ent:IsSurvivor() then continue end

        local current_dist = pos:Distance(ent:GetPos())
        if not IsValid(nearest) or nearest_dist > current_dist then
            nearest = ent
            nearest_dist = current_dist
        end
    end

    return nearest
end

function NPC:OnForceGo(npc)
    if npc.m_bClinging then
        if npc:IsNPC() then
            self:DetachFromCeiling(npc)
        else
            npc:DetachFromCeiling()
        end
    end
end

function NPC:DetachFromCeiling(npc)
    if npc:IsNPC() then
        npc:SetCeilingCling(false)
        npc:SetMoveType(self.MoveType)
        npc:SetSolid(self.SolidType)
        npc:RemoveSolidFlags(FSOLID_FORCE_WORLD_ALIGNED)
        
        npc:SetPos(npc:GetPos() - Vector(0, 0, npc:OBBMaxs().z))
        npc:SetAngles(Angle(0, 0, 0))
    else
        if npc.m_bClinging then
            npc:DetachFromCeiling()
        end
    end
end

function NPC:Think(npc)
    self.BaseClass.Think(self, npc)
    
    if npc:IsNextBot() then return end
    
    if npc.m_bClinging and npc.m_flLastClingCheck and npc.m_flLastClingCheck < CurTime() then
        local nearest = self:GetClingAmbushTarget(npc)
        
        if IsValid(nearest) then
            npc:SetEnemy(nearest)
            self:DetachFromCeiling(npc)
            return
        end
        
        npc.m_flLastClingCheck = CurTime() + 0.25
    end
    
    local enemy = npc:GetEnemy()
    if enemy and enemy:IsValid() and npc:IsUnreachable(enemy) then
        npc:RunEngineTask("TASK_FASTZOMBIE_UNSTICK_JUMP")
    end
end

function NPC:OnDamagedEnt(npc, ent, dmginfo)
    local damage = dmginfo:GetDamage()
    if damage == cvars.Number("sk_fastzombie_clawdamage", 0) then
        dmginfo:SetDamage(GetConVar("zm_fastzombie_clawdamage"):GetInt())
    elseif damage == cvars.Number("sk_fastzombie_leapdamage", 0) then
        dmginfo:SetDamage(GetConVar("zm_fastzombie_leapdamage"):GetInt())
    end
end