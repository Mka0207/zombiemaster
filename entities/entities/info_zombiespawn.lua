AddCSLuaFile()
DEFINE_BASECLASS("info_node_base")

ENT.Base = "info_node_base"
ENT.Type = "anim"
ENT.Model = Model("models/zombiespawner.mdl")

if CLIENT then
    ENT.GlowMat = Material("models/red2")
    ENT.GlowColor = Color( 237, 37, 37 )
    ENT.GlowSize = 128
end

function ENT:SetupDataTables()
    BaseClass.SetupDataTables(self)
    self:NetworkVar("Int", 0, "ZombieFlags")
end

function ENT:Initialize()
    BaseClass.Initialize(self)

    if SERVER then
        self.m_bDidSpawnSetup = false
        self.m_bSpawning = false
        self.allowspawn = true

        self.nodeName = self.nodeName or nil
        self.rallyName = self.rallyName or nil
        self.spawndelay = 0
        self.query = {}
    end
end

if SERVER then
    function ENT:SetRallyEntity(entity)
        if self.rallyEntity and self.rallyEntity:IsValid() then
            self.rallyEntity:Remove()
        end

        self.rallyEntity = entity
    end

    function ENT:GetRallyEntity()
        return self.rallyEntity
    end

    function ENT:Think()
        return self:SpawnThink()
    end

    function ENT:SpawnThink()
        if not self:GetActive() then
            self:NextThink(CurTime() + 1)

            if self.m_bSpawning then self.m_bSpawning = false end
            if #self.query > 0 then table.Empty(self.query) end

            return true
        end

        if #self.query <= 0 then
            self.m_bSpawning = false
            return false
        end

        if not self.m_bSpawning then return true end

        self:NextThink(CurTime() + GetConVar("zm_spawndelay"):GetFloat())

        local current_type = self.query[1]
        if not current_type then return true end

        local pZM = current_type.ply
        if not IsValid(pZM) then return true end

        if (GAMEMODE:GetCurZombiePop() + current_type.popCost) > GAMEMODE:GetMaxZombiePop() or not pZM:CanAfford(current_type.cost) then
            self:NextThink(CurTime() + GetConVar("zm_spawndelay"):GetFloat() + math.Rand(0.1, 0.2))
            return true
        end

        net.Start("zm_remove_queue")
            net.WriteInt(self:EntIndex(), 32)
        net.Send(pZM)

        table.remove(self.query, 1)

        return self:CreateUnit(current_type)
    end

    function ENT:CreateUnit(data)
        if self.m_bActive == false then return false end

        local spawnPoint = self:FindValidSpawnPoint()

        if spawnPoint:IsZero() then return false end

        local pZM = data.ply
        if not IsValid(pZM) then return false end

        local zombie = hook.Call("SpawnZombie", GAMEMODE, data.ply, data.type, spawnPoint, data.ply:GetAngles(), data.cost)
        if not IsValid(zombie) then return false end

        pZM.m_SpawnCount = (pZM.m_SpawnCount or 0) + 1

        timer.Simple(0.25, function()
            if not IsValid(zombie) then return end

            if IsValid(self) then
                local rally = self:GetRallyEntity()
                if IsValid(rally) then
                    zombie:ForceGo(rally:GetPos())

                    if zombie:IsScripted() then
                        timer.Create("ZombieForceGo_"..zombie:EntIndex(), 0.1, 10, function()
                            if not IsValid(zombie) or not IsValid(rally) then return end
                            zombie:ForceGo(rally:GetPos())
                        end)
                    end
                end
            end
        end)

        return true
    end

    function ENT:KeyValue( key, value )
        BaseClass.KeyValue(self, key, value)

        key = string.lower(key)
        if key == "zombieflags" then
            self:SetZombieFlags(tonumber(value))
        elseif key == "rallyname" then
            self.rallyName = value or self.rallyName

            timer.Simple(1, function()
                if not IsValid(self) then return end

                for _, entity in pairs(ents.FindByName(value)) do
                    self:SetRallyEntity(entity)
                end
            end)
        elseif key == "nodename" then
            self.nodeName = value or self.nodeName
        end
    end

    ENT.nodePoints = {}
    function ENT:FindValidSpawnPoint()
        if self.m_bDidSpawnSetup == false then
            table.Empty(self.nodePoints)

            if self.nodeName then
                local node = ents.FindByName(self.nodeName)[1]
                while IsValid(node) do
                    table.insert(self.nodePoints, node)
                    if not node.GetSpawnNode then break end

                    node = node:GetSpawnNode()
                end
            end

            self.m_bDidSpawnSetup = true;
        end

        local AbsAng = self:GetAngles()
        local vForward, vRight, vUp = AbsAng:Forward(), AbsAng:Right(), AbsAng:Up()

        local tr = {}
        local vSpawnPoint = Vector(0, 0, 0)

        local untried_nodes = table.Copy(self.nodePoints)
		local backup_node = nil

        local max_attempts = math.max(10, #untried_nodes)

        for i=0, max_attempts do
            local node_idx = -1

            if #untried_nodes > 0 then
                local idx = math.random(1, #untried_nodes)
				
                if untried_nodes[idx] then
                    vSpawnPoint = untried_nodes[idx]:GetPos()
					backup_node = untried_nodes[idx]:GetPos()
                    node_idx = idx
                end
            end

            if node_idx == -1 then
                local xDeviation = math.random(-20, 20)
                local yDeviation = math.random(-20, 20)

				if xDeviation < 0 then
					xDeviation = xDeviation - 32
				end

				if yDeviation < 0 then
					yDeviation = yDeviation - 32
				end

				if xDeviation > 0 then
					xDeviation = xDeviation + 32
				end

				if yDeviation > 0 then
					yDeviation = yDeviation + 32
				end

                vSpawnPoint = backup_node or self:GetPos()
                vSpawnPoint.x = vSpawnPoint.x + xDeviation
                vSpawnPoint.y = vSpawnPoint.y + yDeviation
            end

            local tr = util.TraceHull( {
                start = vSpawnPoint,
                endpos = vSpawnPoint + Vector( 0, 0, 1 ),
                filter = self.Owner,
                mins = Vector(-13, -13, 0),
                maxs = Vector(13, 13, 72),
                mask = MASK_NPCSOLID
            } )

			local tr2 = util.TraceHull( {
                start = vSpawnPoint + Vector( 0, 0, 10 ),
                endpos = vSpawnPoint + Vector( 0, 0, 20 ),
                filter = self.Owner,
                mins = Vector(-13, -13, 0),
                maxs = Vector(13, 13, 42),
                mask = MASK_NPCSOLID
            } )
			
			-- for debug purposes
			//debugoverlay.SweptBox(vSpawnPoint + Vector( 0, 0, 10 ), vSpawnPoint + Vector( 0, 0, 20 ), Vector(-13, -13, 0), Vector(13, 13, 42), Angle(0,0,0), 3, (tr.Fraction ~= 1.0 or tr2.Hit) and Color( 255, 0, 0 ) or Color( 255, 255, 255 ) )
			
            if tr.Fraction ~= 1.0 or tr2.Hit then
                
				local vOriginalSpawnPoint = vSpawnPoint * 1
				local space = false
				
				-- check around the node itself
				for i=1, 5 do 
					
					local xDeviation = math.random(-10, 10)
					local yDeviation = math.random(-10, 10)

					if xDeviation < 0 then
						xDeviation = xDeviation - 32
					end

					if yDeviation < 0 then
						yDeviation = yDeviation - 32
					end

					if xDeviation > 0 then
						xDeviation = xDeviation + 32
					end

					if yDeviation > 0 then
						yDeviation = yDeviation + 32
					end
					
					vSpawnPoint = vOriginalSpawnPoint * 1
					vSpawnPoint.x = vSpawnPoint.x + xDeviation
					vSpawnPoint.y = vSpawnPoint.y + yDeviation
					
					local tr = util.TraceHull( {
						start = vSpawnPoint,
						endpos = vSpawnPoint + Vector( 0, 0, 1 ),
						filter = self.Owner,
						mins = Vector(-13, -13, 0),
						maxs = Vector(13, 13, 72),
						mask = MASK_NPCSOLID
					} )

					local tr2 = util.TraceHull( {
						start = vSpawnPoint + Vector( 0, 0, 10 ),
						endpos = vSpawnPoint + Vector( 0, 0, 20 ),
						filter = self.Owner,
						mins = Vector(-13, -13, 0),
						maxs = Vector(13, 13, 42),
						mask = MASK_NPCSOLID
					} )
					
					//debugoverlay.SweptBox(vSpawnPoint + Vector( 0, 0, 10 ), vSpawnPoint + Vector( 0, 0, 20 ), Vector(-13, -13, 0), Vector(13, 13, 42), Angle(0,0,0), 3, (tr.Fraction ~= 1.0 or tr2.Hit) and Color( 255, 0, 0 ) or Color( 55, 255, 55 ) )
					
					if not ( tr.Fraction ~= 1.0 or tr2.Hit ) then
						space = true
						break
					end

				end
				
				if space then 
					break
				else
					if node_idx ~= -1 then
						table.remove(untried_nodes, node_idx)
					end

					vSpawnPoint:Zero()
				end
            else
                break
            end
        end

        return vSpawnPoint
    end

    function ENT:InputToggle()
        if self:GetActive() then
            self:SetActive(false)
            self:AddSolidFlags( FSOLID_NOT_SOLID )
            self:AddEffects( EF_NODRAW )

            if self.nodePoints then
                for _, node in pairs(self.nodePoints) do
                    if IsValid(node) then node:AddEffects(EF_NODRAW) end
                end
            end
        else
            self:SetActive(true)
            self:RemoveSolidFlags( FSOLID_NOT_SOLID )
            self:RemoveEffects( EF_NODRAW )

            if self.nodePoints then
                for _, node in pairs(self.nodePoints) do
                    if IsValid(node) then node:RemoveEffects(EF_NODRAW) end
                end
            end
        end
    end

    function ENT:InputHide()
        if self:GetActive() then
            self:ClearQueue(true)
            self:SetActive(false)
            self:AddSolidFlags( FSOLID_NOT_SOLID )
            self:AddEffects( EF_NODRAW )

            if self.nodePoints then
                for _, node in pairs(self.nodePoints) do
                    if IsValid(node) then  node:AddEffects(EF_NODRAW) end
                end
            end
        end
    end

    function ENT:InputUnhide()
        self:SetActive(true)
        self:RemoveSolidFlags( FSOLID_NOT_SOLID )
        self:RemoveEffects( EF_NODRAW )

        if self.nodePoints then
            for _, node in pairs(self.nodePoints) do
                if IsValid(node) then node:RemoveEffects(EF_NODRAW) end
            end
        end
    end

    function ENT:StartSpawning()
        self:NextThink(CurTime() + GetConVar("zm_spawndelay"):GetFloat())
        self.m_bSpawning = true
    end

    function ENT:AddQuery(ply, zombietype, amount)
        if not self.m_bSpawning then
            self:StartSpawning()
        end

        local data = GAMEMODE:GetZombieData(zombietype)

        if data and #self.query < 18 then
            local zombieFlags = self:GetZombieFlags() or 0
            local allowed = hook.Call("CanSpawnZombie", GAMEMODE, data.Flag or 0, zombieFlags)
            if not allowed then return end

            if amount > 1 and amount < 19 then
                for i = 1, amount do
                    if #self.query == 18 then
                        ply:PrintTranslatedMessage(HUD_PRINTTALK, "queue_is_full")
                    else
                        table.insert(self.query, {type = zombietype, cost = data.Cost, ply = ply, popCost = data.PopCost})

                        net.Start("zm_queue")
                            net.WriteString(zombietype)
                            net.WriteInt(self:EntIndex(), 32)
                        net.Send(ply)
                    end
                end
            else
                table.insert(self.query, {type = zombietype, cost = data.Cost, ply = ply, popCost = data.PopCost})

                net.Start("zm_queue")
                    net.WriteString(zombietype)
                    net.WriteInt(self:EntIndex(), 32)
                net.Send(ply)
            end
        else
            ply:PrintTranslatedMessage(HUD_PRINTTALK, "queue_is_full")
        end
    end

    function ENT:ClearQueue(clear)
        if clear then
            self.query = {}
        else
            if #self.query > 0 then
                table.remove(self.query, 1)
            end
        end
    end
end