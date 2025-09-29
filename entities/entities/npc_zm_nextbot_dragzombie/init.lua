AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

DEFINE_BASECLASS("zm_npc_nextbot_base")

ENT.AttackDamage = 10
ENT.AttackRange     = 120
ENT.NextDoorFind = CurTime()
ENT.NextSpit     = CurTime()
ENT.CanSwatPhysicsObjects = false

ENT.DeathSounds  = "NPC_DragZombie.Die"
ENT.PainSounds   = "NPC_DragZombie.Pain"
ENT.MoanSounds   = "NPC_DragZombie.Idle"
ENT.AlertSounds  = "NPC_DragZombie.Alert"
ENT.ClawHitSounds = ""
ENT.ClawMissSounds = ""
ENT.IsFloating = true
ENT.NoHitGroupFix = true


function ENT:FindDoor()
    local position = self:WorldSpaceCenter()
	
    local doors = ents.FindInSphere( self:WorldSpaceCenter(), 80 )
	
    //doors = table.Add(doors, ents.FindByClass("func_door"))
    //doors = table.Add(doors, ents.FindByClass("func_door_rotating"))
    //doors = table.Add(doors, ents.FindByClass("prop_door_rotating"))
    
    for k, v in pairs(doors) do
        if v:GetClass() == "func_door" or v:GetClass() == "func_door_rotating" or v:GetClass() == "prop_door_rotating" then
            return v
        end
    end
    
    return NULL
end

function ENT:OverrideAttackLogic( enemy )
	
	local dist = self:GetPos():DistToSqr(enemy:GetPos())
	
	if dist <= self:GetClawAttackRange() * self:GetClawAttackRange() and self:VisibleVec(enemy:WorldSpaceCenter()) and not self.IsAttacking then
		self.IsAttacking = true
	end

end

function ENT:PerformAttack()
	self.IdleWander = CurTime() + 20
    if self.IsAttacking then
        local pHurt = self:CheckTraceHullAttack(self:EyePos(), self:EyePos() + self:EyeAngles():Forward() * (self:GetClawAttackRange() + 10), -Vector(16, 16, 32), Vector(16, 16, 32), GetConVar("zm_dragzombie_damage"):GetInt(), DMG_ACID, 5.0)
		if IsValid(pHurt) then
			local obj = 2 //self:LookupAttachment("Mouth")
			local attachment = self:GetAttachment(obj)
			
			local vSpitPos, vSpitAngle = attachment.Pos, attachment.Ang
            
			if pHurt:IsPlayer() then
				pHurt:ViewPunch(Angle(math.Rand(-50.0, 50.0), math.Rand(-50.0, 50.0), math.Rand(-50.0, 50.0)))
				pHurt:SetAbsVelocity(Vector(0, 0, 0))
                    
				local pangle = pHurt:GetAngles()
				pHurt:SetAngles(Angle(pangle.p + math.random(-10, 10), pangle.y + math.random(-10, 10), pangle.r))
			end
			
			local effect = EffectData()
				effect:SetOrigin( vSpitPos )
				effect:SetNormal( vSpitAngle:Right() * -1 )
				effect:SetScale( 8 )
				effect:SetFlags( 0xFF )
				effect:SetColor( 0 )
			util.Effect( "bloodspray", effect )
                
			self:EmitSound("NPC_DragZombie.MeleeAttack")
        end
        
        self.NextEnemyUpdate = CurTime() + 0.8
        
    end
end

function ENT:CustomThink()
    
	if not self.IsAttacking and self.NextDoorFind + 4 < CurTime() then
        local door = self:FindDoor()
        
        if IsValid(door) then
            door:Fire("open", "", 0.1)
            self:PlayVoiceSound(self.MoanSounds)
            self.NextIdleMoan = CurTime() + math.random(15, 25)
        end
        
        self.NextDoorFind = CurTime()
    end
end

local seq_idle2 = 1
function ENT:GetIdleSequence()
	return seq_idle2
end