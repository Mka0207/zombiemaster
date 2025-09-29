NPC.FadeSpeed = 1.6

NPC.UseGore = true
NPC.DrawSkeleton = true
NPC.MaxGoreElements = 2
NPC.GoreScale = 1

function NPC:OnSpawned(npc)
    npc.UseGore = self.UseGore
    npc.DrawSkeleton = self.DrawSkeleton
    npc.MaxGoreElements = self.MaxGoreElements
    npc.GoreScale = self.GoreScale
    npc.MeatModel = self.MeatModel
    npc.GoreTable = {}
    npc.FriendlyName = self.Name
    npc.RenderGroup = RENDERGROUP_TRANSLUCENT
end

function NPC:SpawnDraw(npc)
    if cvars.Number("zm_cl_spawntype", 0) == 1 then
        if npc.LifeTime and npc.LifeTime > CurTime() then
            local mn, mx = npc:GetRenderBounds()
            local Down = -npc:GetUp()
            local Bottom = npc:GetPos() + mn
            local Top = npc:GetPos() + mx

            local Fraction = (npc.LifeTime - CurTime()) / npc.Time
            Fraction = math.Clamp(Fraction / 1, 0, 1)

            local Lerped = LerpVector(Fraction, Top, Bottom)

            local normal = Down
            local distance = normal:Dot(Lerped)

            local bEnabled = render.EnableClipping(true)
            render.PushCustomClipPlane(normal, distance)
                render.SetBlend(Lerp(Fraction, 1, 0))
                render.SetColorModulation(1, 0, 0)
                    npc:DrawModel() 
                render.SetBlend(1)
                render.SetColorModulation(1, 1, 1)
            render.PopCustomClipPlane()
            render.EnableClipping(bEnabled)
        else
            npc.ShouldDrawSilhouette = true
            npc.FadeFinished = true
        end
    else
        if npc.fadeAlpha and npc.fadeAlpha < 1 then
            npc.fadeAlpha = npc.fadeAlpha + self.FadeSpeed * FrameTime()
            npc.fadeAlpha = math.Clamp(npc.fadeAlpha, 0, 1)
            
            render.SetBlend(npc.fadeAlpha)
                npc:DrawModel() 
            render.SetBlend(1)
        else
            npc.ShouldDrawSilhouette = true
            npc.FadeFinished = true
        end
    end
end

local circleMaterial        = Material("effects/zombie_select")
local healthcircleMaterial  = Material("effects/zm_healthring")
local undovision            = false
function NPC:PreDraw(npc)
    if MySelf:IsZM() then
        if npc:Health() > 0 then
            local pos = npc:GetPos()
            local healthfrac = math.Clamp(npc:Health() / npc:GetMaxHealth(), 0, 1) * 255
            
            local brightness = math.Clamp(GetConVar("zm_healthcircle_brightness"):GetFloat(), 0, 1)
            if brightness == 0 then return end
                
            local redness = 255 - healthfrac
            local greenness = 255 - redness
            local colour = Color(redness * brightness, greenness * brightness, 0, 255)
            
            render.SetMaterial(healthcircleMaterial)
            render.DrawQuadEasy(pos + Vector(0, 0, 1), Vector(0, 0, 1), 40, 40, colour)
            
            //if npc.bIsSelected then
			if npc.IsSelectedByZM and npc:IsSelectedByZM( MySelf ) then
                render.SetMaterial(circleMaterial)
                render.DrawQuadEasy(pos + Vector(0, 0, 1), Vector(0, 0, 1), 40, 40, colour)
            end
			if IsValid( npc:GetZMSelector() ) and npc:GetZMSelector() ~= MySelf then
				render.SetMaterial(circleMaterial)
                render.DrawQuadEasy(pos + Vector(0, 0, 1), Vector(0, 0, 1), 40, 40, Color( math.Clamp( npc:GetZMSelector():EntIndex() + 20, 0, 255 ), 98, 255, 255 ) )
			end
			
        end
        
        if cvars.Number("zm_cl_spawntype", 0) == 1 then
            if npc.Time == nil then
                return true
            elseif npc.LifeTime > CurTime() then 
                return false 
            end
        end
        
        local v_qual = GetConVar("zm_vision_quality"):GetInt()
        if v_qual == 1 and not MySelf:IsLineOfSightClear(npc) then
            undovision = true
            
            render.ModelMaterialOverride(ZM_Vision)
            render.SetColorModulation(1, 0, 0, 1)
        end
    end
end

function NPC:Draw(npc)
    if not npc:DrawGore() then
        npc:DrawModel()
    end
end

function NPC:PostDraw(npc)
    if undovision then
        undovision = false
        
        render.ModelMaterialOverride()
        render.SetColorModulation(1, 1, 1)
    end
end