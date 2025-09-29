include("shared.lua")

local killicon_Get = killicon.Get
local player_GetCount = player.GetCount
local math_Round = math.Round
local cam_Start3D2D = cam.Start3D2D
local draw_SimpleTextOutlined = draw.SimpleTextOutlined
local surface_SetMaterial = surface.SetMaterial
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawTexturedRect = surface.DrawTexturedRect
local weapons_GetStored = weapons.GetStored
local cam_End3D2D = cam.End3D2D

local EyePos = EyePos
local EyeVector = EyeVector
local Material = Material
local Vector = Vector

local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
local TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM
local color_black = color_black
local color_white = color_white

function ENT:Initialize()
    self:SetCustomGroupAndFlags(ZS_COLLISIONGROUP_ITEMCRATE, ZS_COLLISIONFLAGS_ITEMCRATE, true)
    self:SetCustomCollisionCheck(true)
    
    self:SetRenderBounds(Vector(-72, -72, -72), Vector(72, 72, 128))
end

function ENT:SetObjectHealth(health)
    self:SetDTFloat(0, health)
end

local MaterialCache = {}
local color_black_alpha120 = Color(0, 0, 0, 120)
function ENT:DrawTranslucent()
    if self:GetObjectHealth() <= 0 then return end
    self:DrawModel()
    
    local pos = self:WorldSpaceCenter()
	if (pos - EyePos()):Dot(EyeVector()) < 0 or pos:DistToSqr(EyePos()) > 1048576 then return end
	if not MySelf:IsValid() then return end

    local class = self:GetItemClass()
    local isammo = self:IsAmmo(class)
    local ki = killicon_Get(self:IsAmmo(class) and "ammo_"..GAMEMODE.AmmoClass[class] or class)
    if not ki then return end
    
    local count = self:GetItemCount()
    
    local playercount = player_GetCount()
    if playercount >= 64 then
        count = math_Round(count * 2.5)
    elseif playercount >= 32 then
        count = math_Round(count * 2)
    elseif playercount >= 16 then
        count = math_Round(count * 1.5)
    end
    
    if self:GetLarge() then
        count = count * 2
    end
    
	cam_Start3D2D(self:LocalToWorld(Vector(1, -1, self:OBBMaxs().z)), self:GetAngles(), 0.075)
        if ki and #ki == 3 then
            draw_SimpleTextOutlined(ki[2], ki[1] .. "Large", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 4, color_black)
        elseif ki then
            local material
            if MaterialCache[ki[1]] then
                material = MaterialCache[ki[1]]
            else
                material = Material(ki[1])
                MaterialCache[ki[1]] = material
            end
            
            surface_SetMaterial(material)
            surface_SetDrawColor(color_white:Unpack())
            surface_DrawTexturedRect(0, 0, material:Width(), material:Height())
        end
        
        draw_SimpleTextOutlined(isammo and "#" .. class or weapons_GetStored(class).PrintName, "ZMHudNumbers", 0, -64, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 4, color_black)
        draw_SimpleTextOutlined(count, "ZMHudNumbers", 0, 32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 4, color_black)
	cam_End3D2D()
end
