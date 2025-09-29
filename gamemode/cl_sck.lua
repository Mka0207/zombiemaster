local meta = FindMetaTable("Weapon")

local E_Meta = FindMetaTable("Entity")
local E_LookupBone = E_Meta.LookupBone
local E_GetBoneMatrix = E_Meta.GetBoneMatrix
local E_GetBonePosition = E_Meta.GetBonePosition
local E_SetRenderOrigin = E_Meta.SetRenderOrigin
local E_SetRenderAngles = E_Meta.SetRenderAngles
local E_SetModelScale = E_Meta.SetModelScale
local E_GetOwner = E_Meta.GetOwner
local E_GetNoDraw = E_Meta.GetNoDraw
local E_GetTable = E_Meta.GetTable
local E_IsValid = E_Meta.IsValid
local E_SetLOD = E_Meta.SetLOD

local VM_Meta = FindMetaTable("VMatrix")
local VM_GetTranslation = VM_Meta.GetTranslation
local VM_GetAngles = VM_Meta.GetAngles

local Ang_Meta = FindMetaTable("Angle")
local A_Forward = Ang_Meta.Forward
local A_Right = Ang_Meta.Right
local A_Up = Ang_Meta.Up
local A_RotateAroundAxis = Ang_Meta.RotateAroundAxis

local function ResetBonePositions(self)
    local owner = self:GetOwner()
    if IsValid(owner) then
        local vm, vm2 = owner:GetViewModel(), owner:GetViewModel(1)
        if IsValid(vm) then
            self:ResetSCKBonePositions(vm)
        end
        if IsValid(vm2) then
            self:ResetSCKBonePositions(vm2)
        end
    end
end

function meta:SCKInit()
    self.VElements = table.FullCopy( self.VElements )
    self.WElements = table.FullCopy( self.WElements )
    self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

    if self.WElementPurge then
        for k, _ in pairs(self.WElementPurge) do
            self.WElements[k] = nil
        end
    end

    self:CreateSCKModels(self.VElements)
    self:CreateSCKModels(self.WElements)

    ResetBonePositions(self)
end

function meta:SCKInitAkimbo()
    self.VElementsL = table.FullCopy( self.VElementsL )
    self.VElementsR = table.FullCopy( self.VElementsR )
    self.WElements = table.FullCopy( self.WElements )

    self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

    if self.WElementPurge then
        for k, _ in pairs(self.WElementPurge) do
            self.WElements[k] = nil
        end
    end

    self:CreateSCKModels(self.VElementsL)
    self:CreateSCKModels(self.VElementsR)
    self:CreateSCKModels(self.WElements)

    ResetBonePositions(self)
end

function meta:SCKHolster()
    ResetBonePositions(self)

    return true
end

function meta:SCKOnRemove()
    self:SCKHolster()
end

local vec_zero, ang_zero = Vector(0, 0, 0), Angle(0, 0, 0)
local E_GetBoneMatrix = E_Meta.GetBoneMatrix
local E_LookupBone = E_Meta.LookupBone
local Ang_Forward = Ang_Meta.Forward
local Ang_Right = Ang_Meta.Right
local Ang_Up = Ang_Meta.Up

local cur_sck_table
local bone_orient_left
local bone_orient_override
local bone_orient_ent = NULL
local relative_bone_cache_pos = {}
local relative_bone_cache_ang = {}
local relative_inspection
local ang_con = Angle

local function GetSCKBoneOrientation(self, tab)
    local pos, ang
    if tab.rel and tab.rel != "" then
        local v = cur_sck_table[tab.rel]
        if not v then return end

        relative_inspection = tab.rel
        pos, ang = GetSCKBoneOrientation(self, v)

        if not pos then return end

        local ang_f, ang_r, ang_u = Ang_Forward(ang), Ang_Right(ang), Ang_Up(ang)
        pos = pos + ang_f * v.pos.x + ang_r * v.pos.y + ang_u * v.pos.z

        ang:RotateAroundAxis(ang_f, v.angle.r)
        ang:RotateAroundAxis(ang_r, v.angle.p)
        ang:RotateAroundAxis(ang_u, v.angle.y)
    else
        pos, ang = relative_bone_cache_pos[relative_inspection], ang_con(relative_bone_cache_ang[relative_inspection])
    end

    return pos, ang
end

local function BuildSCKNonRelativeOrientations(self, tab)
    local bone, pos, ang
    bone = E_LookupBone(bone_orient_ent, tab.bone or bone_orient_override)
    if not bone then return end

    pos, ang = vec_zero, ang_zero
    local m = E_GetBoneMatrix(bone_orient_ent, bone)
    if m then
        pos, ang = m:GetTranslation(), m:GetAngles()
    else
        return
    end

    local owner = E_GetOwner(self)
    local self_tb = E_GetTable(self)
    local should_flip = bone_orient_left and self_tb.ViewModelFlipLeft or self_tb.ViewModelFlip
    if should_flip and IsValid(owner) and owner:IsPlayer() and bone_orient_ent == owner:GetViewModel(bone_orient_left and 1 or 0) then
        ang.r = -ang.r
    end

    return pos, ang
end

function meta:SCKViewModel(is_left)
    
    local owner = self:GetOwner()
    if not owner:IsValid() then return end
    
    local vm = owner:GetViewModel(is_left and 1)
    if not IsValid(vm) then return end

    self:UpdateSCKBonePositions(vm)

    local vm_tbl = E_GetTable(self)

    local is_akimbo = vm_tbl.VElementsL

    local view_model_elements_table = is_left and is_akimbo or
                                      is_akimbo and vm_tbl.VElementsR or
                                      vm_tbl.VElements

    local render_order_logic =  is_left and is_akimbo and "vRenderOrderL" or
                                is_akimbo and "vRenderOrderR" or
                                "vRenderOrder"

    local render_order_table =  vm_tbl[render_order_logic]

    if not view_model_elements_table then return end
    if not render_order_table then
        vm_tbl[render_order_logic] = {}

        render_order_table =    is_left and is_akimbo and vm_tbl.vRenderOrderL or
                                is_akimbo and vm_tbl.vRenderOrderR or
                                vm_tbl.vRenderOrder

        for k, v in pairs(view_model_elements_table) do
            if v.type == "Model" then
                table.insert(render_order_table, 1, k)
            elseif v.type == "Sprite" or v.type == "Quad" then
                table.insert(render_order_table, k)
            end
        end
    end

    relative_bone_cache_pos = {}
    relative_bone_cache_ang = {}

    cur_sck_table = view_model_elements_table
    bone_orient_left = is_left
    bone_orient_ent = vm
    bone_orient_override = nil

    for k, name in ipairs(render_order_table) do
        local tab = view_model_elements_table[name]

        if tab.rel and tab.rel != "" then continue end
        local pos, ang = BuildSCKNonRelativeOrientations(self, tab)

        relative_bone_cache_pos[name], relative_bone_cache_ang[name] = pos, ang
    end

    for k, name in ipairs(render_order_table) do

        local v = view_model_elements_table[name]
        if not v then render_order_table = nil break end

        if v.hide then continue end

        local model = v.modelEnt
        local sprite = v.spriteMaterial

        if not v.bone then continue end

        relative_inspection = name
        local pos, ang = GetSCKBoneOrientation(self, v)
        if not pos then continue end

        if v.type == "Model" and IsValid(model) then

            model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)

            model:SetAngles(ang)
            --model:SetModelScale(v.size)
            local matrix = Matrix()
            matrix:Scale(v.size)
            model:EnableMatrix( "RenderMultiply", matrix )

            if v.bonemerge then
                model:SetParent(self:GetOwner())
                model:AddEffects( EF_BONEMERGE )
                model.was_bonemerged = true
            end

            if v.size.x < 0 and not v.inversed then
                v.inversed = true
            end

            if (v.material == "") then
                model:SetMaterial("")
            elseif (model:GetMaterial() != v.material) then
                model:SetMaterial( v.material )
            end

            if (v.skin and v.skin != model:GetSkin()) then
                model:SetSkin(v.skin)
            end

            if (v.bodygroup) then
                for k, v in ipairs( v.bodygroup ) do
                    if (model:GetBodygroup(k) != v) then
                        model:SetBodygroup(k, v)
                    end
                end
            end

            if (v.surpresslightning) then
                render.SuppressEngineLighting(true)
            end

            render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
            render.SetBlend(v.color.a/255)
            if v.inversed then render.CullMode(MATERIAL_CULLMODE_CW) end
            model:DrawModel()
            if v.inversed then render.CullMode(MATERIAL_CULLMODE_CCW) end
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)

            if (v.surpresslightning) then
                render.SuppressEngineLighting(false)
            end

            if v.inversed and v.size.x > 0 then
                v.inversed = nil
            end

        elseif (v.type == "Sprite" and sprite) then

            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            render.SetMaterial(sprite)
            render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)

        elseif (v.type == "Quad" and v.draw_func) then

            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)

            cam.Start3D2D(drawpos, ang, v.size)
                v.draw_func( self )
            cam.End3D2D()

        end
    end
end

function meta:SCKWorldModel()
    local owner = self:GetOwner()
    if not owner:IsValid() then return end

    WEAPON_WORLD_CONTEXT = true

    local wm_tbl = E_GetTable(self)

    if (wm_tbl.ShowWorldModel == nil or wm_tbl.ShowWorldModel) then
        if wm_tbl.WMPos and wm_tbl.WMAng then
            handBone = E_LookupBone(owner, "ValveBiped.Bip01_R_Hand")
            if handBone then
                wmpos = wm_tbl.WMPos
                wmang = wm_tbl.WMAng
                bonematrix = E_GetBoneMatrix(owner, handBone)

                if bonematrix then
                    bpos, bang = VM_GetTranslation(bonematrix), VM_GetAngles(bonematrix)
                else
                    bpos, bang = E_GetBonePosition(owner, handBone)
                end

                bpos = bpos + A_Forward(bang) * wmpos.y + A_Right(bang) * wmpos.x + A_Up(bang) * wmpos.z
                
                A_RotateAroundAxis(bang, A_Up(bang), wmang[2])
                A_RotateAroundAxis(bang, A_Right(bang), wmang[1])
                A_RotateAroundAxis(bang, A_Forward(bang), wmang[3])
                
                E_SetRenderOrigin(self, bpos)
                E_SetRenderAngles(self, bang)
                
                if wm_tbl.WMScale then
                    E_SetModelScale(self, wm_tbl.WMScale)
                end
            end
        end
        
        if wm_tbl.InvisModel then render.SetBlend(0) end
        self:DrawModel()
        if wm_tbl.InvisModel then render.SetBlend(1) end
    end

    if not wm_tbl.WElements or owner and owner:IsValid() and owner.ShadowMan then
        WEAPON_WORLD_CONTEXT = nil
        return
    end

    if (!wm_tbl.wRenderOrder) then

        wm_tbl.wRenderOrder = {}

        for k, v in pairs( wm_tbl.WElements ) do
            if (v.type == "Model") then
                table.insert(wm_tbl.wRenderOrder, 1, k)
            elseif (v.type == "Sprite" or v.type == "Quad") then
                table.insert(wm_tbl.wRenderOrder, k)
            end
        end

    end

    if (IsValid(self:GetOwner())) then
        bone_ent = self:GetOwner()
    else
        -- when the weapon is dropped
        bone_ent = self
    end

    local frame_time = FrameTime()

    relative_bone_cache_pos = {}
    relative_bone_cache_ang = {}

    cur_sck_table = wm_tbl.WElements
    bone_orient_left = false
    bone_orient_ent = bone_ent

    for k, name in ipairs(wm_tbl.wRenderOrder) do
        local tab = wm_tbl.WElements[name]

        if tab.rel and tab.rel != "" then continue end
        local pos, ang = BuildSCKNonRelativeOrientations(self, tab)

        relative_bone_cache_pos[name], relative_bone_cache_ang[name] = pos, ang
    end

    for k, name in pairs( wm_tbl.wRenderOrder ) do

        local v = wm_tbl.WElements[name]
        if (!v) then wm_tbl.wRenderOrder = nil break end
        if (v.hide) then continue end

        local pos, ang
        bone_orient_override = v.bone or "ValveBiped.Bip01_R_Hand"

        relative_inspection = name
        pos, ang = GetSCKBoneOrientation(self, v)

        if (!pos) then continue end

        local model = v.modelEnt
        local sprite = v.spriteMaterial

        if (v.type == "Model" and IsValid(model)) then

            model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)

            if v.smooth then
                model.ApproachAng = model.ApproachAng or Angle( ang.p, ang.y, ang.r )
                model.ApproachAng = LerpAngle(frame_time * 100 * 0.012, model.ApproachAng, ang )
                model:SetAngles( model.ApproachAng )
            else
                model:SetAngles( ang )
            end

            local matrix = Matrix()
            matrix:Scale(v.size)
            model:EnableMatrix( "RenderMultiply", matrix )

            if v.bonemerge then
                model:SetParent(self:GetOwner())
                model:AddEffects( EF_BONEMERGE )
                model.was_bonemerged = true
            end

            if v.bbp then
                model:SetParent(self:GetOwner())
            end

            if (v.material == "") then
                model:SetMaterial("")
            elseif (model:GetMaterial() != v.material) then
                model:SetMaterial( v.material )
            end

            if (v.skin and v.skin != model:GetSkin()) then
                model:SetSkin(v.skin)
            end

            if (v.bodygroup) then
                for k, v in ipairs( v.bodygroup ) do
                    if (model:GetBodygroup(k) != v) then
                        model:SetBodygroup(k, v)
                    end
                end
            end

            local disable_light = GAMEMODE.DisableWeaponModelLight and owner:Team() == TEAM_HUMAN

            if v.surpresslightning or disable_light then
                render.SuppressEngineLighting(true)
            end

            render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
            render.SetBlend(v.color.a/255)
            model:DrawModel()
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)

            if v.surpresslightning or disable_light then
                render.SuppressEngineLighting(false)
            end

        elseif (v.type == "Sprite" and sprite) then

            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            render.SetMaterial(sprite)
            render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)

        elseif (v.type == "Quad" and v.draw_func) then

            local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
            ang:RotateAroundAxis(ang:Up(), v.angle.y)
            ang:RotateAroundAxis(ang:Right(), v.angle.p)
            ang:RotateAroundAxis(ang:Forward(), v.angle.r)

            cam.Start3D2D(drawpos, ang, v.size)
                v.draw_func( self )
            cam.End3D2D()

        end

    end

    WEAPON_WORLD_CONTEXT = nil
end

local player_bounds_min, player_bounds_max =
    Vector(-17.030594, -17.102781, -2.736084), Vector(29.347628, 13.000000, 72.000000)

function meta:CreateSCKModels( tab )

    if (!tab) then return end

    -- Create the clientside models here because Garry says we can't do it in the render hook
    for k, v in pairs( tab ) do
        if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and
                string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then

            v.modelEnt = ents.CreateClientProp() --ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
            if (IsValid(v.modelEnt)) then
                v.modelEnt:SetModel(v.model)
                v.modelEnt:SetPos(self:GetPos())
                v.modelEnt:SetAngles(self:GetAngles())
                v.modelEnt:SetParent(self)
                v.modelEnt:SetNoDraw(true)
                v.modelEnt.RenderGroup = RENDER_GROUP_VIEW_MODEL_OPAQUE
                v.modelEnt:SetRenderBounds(player_bounds_min, player_bounds_max)
                v.modelEnt:Spawn()
                v.createdModel = v.model

                if v.bbp then
                    v.modelEnt:SetLOD( 0 )
                    v.modelEnt:AddCallback( "BuildBonePositions", v.bbp )
                end
            else
                v.modelEnt = nil
            end

        elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite)
            and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then

            local name = v.sprite.."-"
            local params = { ["$basetexture"] = v.sprite }
            -- make sure we create a unique name based on the selected options
            local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
            for i, j in pairs( tocheck ) do
                if (v[j]) then
                    params["$"..j] = 1
                    name = name.."1"
                else
                    name = name.."0"
                end
            end

            v.createdSprite = v.sprite
            v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)

        end
    end
end

local vec_one = Vector(1, 1, 1)
local E_MBoneScale = E_Meta.ManipulateBoneScale
local E_MBoneAngles = E_Meta.ManipulateBoneAngles
local E_MBonePos = E_Meta.ManipulateBonePosition
function meta:UpdateSCKBonePositions(vm)
    if self.ViewModelBoneMods then
        if (!vm:GetBoneCount()) then return end

        local loopthrough = GAMEMODE.NoCentreViewModels and self.ViewModelBoneModsNoCentre or self.ViewModelBoneMods
        for k, v in pairs( loopthrough ) do
            local bone = vm:LookupBone(k)
            if not bone then continue end

            local s = Vector(v.scale.x,v.scale.y,v.scale.z)
            local p = Vector(v.pos.x,v.pos.y,v.pos.z)
            local ms = Vector(1,1,1)

            s = s * ms

            if vm:GetManipulateBoneScale(bone) != s then
                E_MBoneScale(vm, bone, s)
            end
            if vm:GetManipulateBoneAngles(bone) != v.angle then
                E_MBoneAngles(vm, bone, v.angle)
            end
            if vm:GetManipulateBonePosition(bone) != p then
                E_MBonePos(vm, bone, p)
            end
        end
    else
        self:ResetSCKBonePositions(vm)
    end
end

function meta:ResetSCKBonePositions(vm)
    vm:SetColor(color_white)
    vm:SetMaterial("")

    local bone_count = vm:GetBoneCount()
    if not bone_count then return end
    for i=0, bone_count do
        E_MBoneScale(vm, i, vec_one)
        E_MBoneAngles(vm, i, ang_zero)
        E_MBonePos(vm, i, vec_zero)
    end
end

function table.FullCopy( tab )
    if (!tab) then return nil end

    local res = {}
    for k, v in pairs( tab ) do
        if (type(v) == "table") then
            res[k] = table.FullCopy(v)
        elseif (type(v) == "Vector") then
            res[k] = Vector(v.x, v.y, v.z)
        elseif (type(v) == "Angle") then
            res[k] = Angle(v.p, v.y, v.r)
        else
            res[k] = v
        end
    end

    return res
end

function meta:RemoveSCKModels()
    if self.VElements then
        for k, v in pairs( self.VElements ) do
            if (IsValid( v.modelEnt )) then
                v.modelEnt:Remove()
                v.modelEnt = nil
            end
        end
    end
    if self.VElementsR then
        for k, v in pairs( self.VElementsR ) do
            if (IsValid( v.modelEnt )) then
                v.modelEnt:Remove()
                v.modelEnt = nil
            end
        end
    end
    if self.VElementsL then
        for k, v in pairs( self.VElementsL ) do
            if (IsValid( v.modelEnt )) then
                v.modelEnt:Remove()
                v.modelEnt = nil
            end
        end
    end


    if self.WElements then
        for k, v in pairs( self.WElements ) do
            if (IsValid( v.modelEnt )) then
                v.modelEnt:Remove()
                v.modelEnt = nil
            end
        end
    end
end
