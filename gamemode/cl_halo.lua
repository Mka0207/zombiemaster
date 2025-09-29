local mat_Copy = Material( "pp/copy" )
local mat_Add = Material( "pp/add" )
local rt_Store = render.GetScreenEffectTexture( 0 )
local rt_Buffer = render.GetScreenEffectTexture( 1 )

local List = {}
local RenderEnt = NULL

function halo.Add( entities, color, blurx, blury, passes, add, ignorez )
	if table.IsEmpty(entities) then return end
	if add == nil then add = true end
	if ignorez == nil then ignorez = false end

	local t =
	{
		Ents = entities,
		Color = color,
		Hidden = when_hidden,
		BlurX = blurx or 2,
		BlurY = blury or 2,
		DrawPasses = passes or 1,
		Additive = add,
		IgnoreZ = ignorez
	}

	table.insert(List, t)
end

function halo.RenderedEntity()
	return RenderEnt
end

function halo.Render( entry )
    if not GAMEMODE.bDisableHalos then
        local rt_Scene = render.GetRenderTarget()
        render.CopyRenderTargetToTexture(rt_Store)

        render.Clear(0, 0, 0, 255, false, true)

        cam.Start3D()
        render.ClearStencil()
        render.SetStencilEnable(true)
            cam.IgnoreZ(entry.IgnoreZ)
            render.SuppressEngineLighting(true)
                render.SetStencilWriteMask(1)
                render.SetStencilTestMask(1)
                render.SetStencilReferenceValue(1)

                render.SetStencilCompareFunction(STENCIL_ALWAYS)
                render.SetStencilPassOperation(STENCIL_REPLACE)
                render.SetStencilFailOperation(STENCIL_KEEP)
                render.SetStencilZFailOperation(STENCIL_KEEP)
                
                for k, v in ipairs(entry.Ents) do
                    if not IsValid(v) or v:GetNoDraw() then continue end

                    RenderEnt = v
                    v:DrawModel()
                end

                RenderEnt = NULL

                render.SetStencilCompareFunction(STENCIL_EQUAL)
                render.SetStencilPassOperation(STENCIL_KEEP)

                cam.Start2D()
                    surface.SetDrawColor(entry.Color)
                    surface.DrawRect(0, 0, ScrW(), ScrH())
                cam.End2D()
            cam.IgnoreZ(false)
            render.SuppressEngineLighting(false)
        render.SetStencilEnable(false)
        cam.End3D()

        render.CopyRenderTargetToTexture(rt_Buffer)
        render.SetRenderTarget(rt_Scene)
        
        mat_Copy:SetTexture("$basetexture", rt_Store)
        render.SetMaterial(mat_Copy)
        
        render.DrawScreenQuad()

        render.SetStencilEnable(true)
            render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NOTEQUAL)

			if entry.Additive then
                mat_Add:SetTexture("$basetexture", rt_Buffer)
                render.SetMaterial(mat_Add)
			else
                mat_Sub:SetTexture("$basetexture", rt_Buffer)
                render.SetMaterial(mat_Sub)
			end

            for i = 0, entry.DrawPasses do
                render.DrawScreenQuadEx(0, 0, ScrW() + entry.BlurX, ScrH() + entry.BlurY)
                render.DrawScreenQuadEx(0, 0, ScrW() - entry.BlurX, ScrH() - entry.BlurY)
            end
        render.SetStencilEnable(false)

        render.SetStencilTestMask(0)
        render.SetStencilWriteMask(0)
        render.SetStencilReferenceValue(0)
    end
end

function GM:PostDrawEffects()
	hook.Run("PreDrawHalos")

	if #List == 0 then return end

	for k, v in ipairs(List) do
		halo.Render(v)
	end

	List = {}
end
