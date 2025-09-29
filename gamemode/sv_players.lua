local meta = FindMetaTable("Player")
if not meta then return end

meta.m_iZMPriority = 0

function meta:SetZMPoints(points)
    self:SetDTInt(1, math.Clamp(points, 0, GetConVar("zm_resource_limit"):GetInt()))
end

function meta:SetZMPointIncome(amount)
    if amount < 0 then amount = 0 end
    self:SetDTInt(2, amount)
end

function meta:AddZMPoints(amount)
    local resources = self:GetZMPoints()
    self:SetZMPoints(resources + amount)
end

function meta:TakeZMPoints(amount)
    local resources = self:GetZMPoints()
    self:SetZMPoints(resources - amount)
end

function meta:ChangeTeamDelayed(delay, teamid)
    timer.Simple(delay, function() self:ChangeTeam(teamid) end)
end

function meta:ChangeTeam(teamid)
	local oldteam = self:Team()
	self:SetTeam(teamid)
	if oldteam ~= teamid then
		hook.Call("OnPlayerChangedTeam", GAMEMODE, self, oldteam, teamid)
	end

	self:CollisionRulesChanged()
	self:CollisionRulesChanged()
end

function meta:SetClass(class)
    local oldclass = player_manager.GetPlayerClass(self)
    player_manager.SetPlayerClass(self, class)
    if oldclass ~= class then
        hook.Call("OnPlayerClassChanged", GAMEMODE, self, class)
    end
end

function meta:DropAllAmmo()
    local ammotbl = {}
    for _, wep in pairs(self:GetWeapons()) do
        if wep.WeaponIsAmmo then continue end
        
        local ammotype = wep.Primary and wep.Primary.Ammo or ""
        if ammotype ~= "" and ammotype ~= "none" and not ammotbl[ammotype] then
            ammotbl[ammotype] = self:GetAmmoCount(ammotype)
        end
    end
    
    if ammotbl == {} then return end
    
    for ammotype, ammoamount in pairs(ammotbl) do
        local ent = ents.Create("item_zm_ammo")
        if IsValid(ent) then
            local vecOrigin = Vector(math.Rand(-0.25, 0.25), math.Rand(-0.25, 0.25), math.Rand(-0.25, 0.25))
            ent:SetPos(self:GetPos() + vecOrigin)

            local vecAngles = Angle(math.Rand( -20.0, 20.0 ), math.Rand( 0.0, 360.0 ), math.Rand( -20.0, 20.0 ))
            ent:SetAngles(self:GetAngles() + vecAngles)

            local vecActualVelocity = Vector(math.random(-10.0, 10.0), math.random(-10.0, 10.0), math.random(-10.0, 10.0))
            ent:SetVelocity(self:GetVelocity() + vecActualVelocity)
            
            local ammoclass = Either(ammotype == "buckshot", "item_box_"..ammotype, "item_ammo_"..ammotype)
            
            ent.Dropped = true
            ent:SetClassName(ammoclass)
            ent.ClassName = ammoclass
            ent.Model = GAMEMODE.AmmoModels[ammoclass]
            ent.AmmoAmount = ammoamount
            ent.AmmoType = ammotype
            ent:Spawn()
        end
    end
end

function meta:Gib()
    local pos = self:LocalToWorld(self:OBBCenter())

    local effectdata = EffectData()
        effectdata:SetEntity(self)
        effectdata:SetOrigin(pos)
    util.Effect("gib_player", effectdata, true, true)

    self.Gibbed = CurTime()

    timer.Simple(0, function()
        GAMEMODE.CreateGibs(GAMEMODE, pos, self:LocalToWorld(self:OBBMaxs()).z - pos.z)
    end)
end

function meta:SendLua(str)
    net.Start("zm_sendlua")
        net.WriteString(str)
    net.Send(self)
end

meta.OldGetObserverTarget = meta.OldGetObserverTarget or meta.GetObserverTarget
function meta:GetObserverTarget()
    if self:GetObserverMode() == OBS_MODE_ROAMING then
        return NULL
    end
    return self:OldGetObserverTarget()
end

meta.OldPickupObject = meta.OldPickupObject or meta.PickupObject
function meta:PickupObject(ent)
    if self:IsHolding() then
        if ent == self.CarryProp then self:DropObject() end
        return
    end
    
    if not ent.m_AntiPropFly then
        ent.m_AntiPropFly = {}
    end

    if ent.m_AntiPropFly[self] and ent.m_AntiPropFly[self] >= CurTime() then return end
    
    local pickup = ents.Create("prop_player_pickup")
    if pickup:IsValid() then
        pickup:SetPos(self:GetShootPos())
        pickup:SetOwner(self)
        pickup:SetParent(self)
        pickup:SetObject(ent)
        pickup:Spawn()

        ent.m_AntiPropFly[self] = CurTime() + 1.5
        ent.m_AntiPropFlyCallbackID = ent:AddCallback("PhysicsCollide", function(ent, data)
            if ent:OnGround() then
                table.Empty(ent.m_AntiPropFly)
                ent:RemoveCallback("PhysicsCollide", ent.m_AntiPropFlyCallbackID)
            end
        end)
    end
end

meta.OldDropObject = meta.OldDropObject or meta.DropObject
function meta:DropObject()
    if self.player_pickup and self.player_pickup:IsValid() then
        self.player_pickup:Remove()
    end
end