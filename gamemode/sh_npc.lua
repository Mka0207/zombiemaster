local meta = FindMetaTable("NPC")
if not meta then return end

function meta:Alive()
    return self:Health() > 0
end

function meta:Team()
    return TEAM_ZOMBIEMASTER
end

function meta:SetSelected(b)
    self.bIsSelected = b
    if SERVER then
        //self:SetNW2Bool("selected", b)
		self:SetDTEntity( 10, b )
    end
end

function meta:IsSelectedByZM( zm )
	return IsValid( self:GetDTEntity( 10 ) ) and self:GetDTEntity( 10 ) == zm
end

function meta:GetZMSelector()
	return IsValid( self:GetDTEntity( 10 ) ) and self:GetDTEntity( 10 )
end

function meta:SetCeilingCling(b)
    self.m_bClinging = b
    if SERVER then
        self:SetNW2Bool("bClingingCeiling", b)
    end
end

function meta:SetEngineNPC(b)
    self.IsEngineNPC = b
    if SERVER then
        self:SetNW2Bool("bIsEngineNPC", b)
    end
end

local NEXTBOT_Meta = FindMetaTable("NextBot")
if not NEXTBOT_Meta then return end

NEXTBOT_Meta.Team = meta.Team
NEXTBOT_Meta.SetSelected = meta.SetSelected
NEXTBOT_Meta.SetEngineNPC = meta.SetEngineNPC
NEXTBOT_Meta.IsSelectedByZM = meta.IsSelectedByZM
NEXTBOT_Meta.GetZMSelector = meta.GetZMSelector

function NEXTBOT_Meta:Alive()
    return self:Health() > 0
end

if not CLIENT then return end

function meta:GetRagdollEntity()
    return self.m_Ragdoll
end