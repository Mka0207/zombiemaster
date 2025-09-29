ENT.Type = "anim"

local defaultcolor = Vector( 62.0/255.0, 88.0/255.0, 106.0/255.0 )
function ENT:GetPlayerColor()
	local owner = self:GetOwner()
	if owner and owner:IsValid() and owner.GetPlayerColor then
		return owner:GetPlayerColor()
	end

	return defaultcolor
end

function ENT:GetObject()
	return self:GetDTEntity(0)
end

function ENT:SetObject(object)
	self:SetDTEntity(0, object)
end

function ENT:SetupMove(pl, ent, mv, cmd)
    if mv:KeyDown(IN_ATTACK) or mv:KeyDown(IN_ATTACK2) then
        DropEntityIfHeld(ent)
        
        if mv:KeyDown(IN_ATTACK) then
            local ang = Angle(util.SharedRandom("physpax", 1.2, 2.0), util.SharedRandom("physpay", -0.5, 0.5), 0.0)
            pl:ViewPunch(ang)
            
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                local massFactor = math.Remap(math.Clamp(phys:GetMass(), 0.5, 15), 0.5, 15, 0.5, 4)
                phys:ApplyForceCenter(pl:GetAimVector() * (GetConVar("player_throwforce"):GetInt() * massFactor))
                
                local aVel = VectorRand( -10, 10 ) * massFactor
                phys:ApplyTorqueCenter(aVel)
                
                ent:SetPhysicsAttacker(pl)
                phys:AddGameFlag(FVPHYSICS_WAS_THROWN)
            end
        end
        
        if SERVER then
            ent:SetPhysicsAttacker(pl)
            self:Remove()
        end
        
        pl:ConCommand("-attack")
        pl:ConCommand("-attack2")
        
        local newbuttons = bit.band(mv:GetButtons(), bit.bnot(bit.bor(IN_ATTACK, IN_ATTACK2)))
        mv:SetButtons(newbuttons)
    end
end