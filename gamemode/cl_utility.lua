function draw.OutlinedBox( x, y, w, h, thickness, clr )
    surface.SetDrawColor( clr )
    for i=0, thickness - 1 do
        surface.DrawOutlinedRect( x + i, y + i, w - i * 2, h - i * 2 )
    end
end

function draw.DrawSimpleRect(x, y, w, h, col)
    surface.SetDrawColor(col)
    surface.DrawRect(x, y, w, h)
end

function draw.DrawSimpleOutlined(x, y, w, h, col)
    surface.SetDrawColor(col)
    surface.DrawOutlinedRect(x, y, w, h)
end

local Tex_Corner8 = surface.GetTextureID( "gui/corner8" )
local Tex_Corner16 = surface.GetTextureID( "gui/corner16" )
function draw.RoundedBoxHollow(bordersize, x, y, w, h, color)
    local bordersize2 = bordersize - 1 -- Gives slightly rounded inner corners

    x = math.Round( x )
    y = math.Round( y )
    w = math.Round( w )
    h = math.Round( h )

    surface.SetDrawColor( color.r, color.g, color.b, color.a )

    -- Draw as much of the rect as we can without textures
    surface.DrawRect( x + bordersize2, y, w - bordersize2 * 2, bordersize2 ) -- Top line
    surface.DrawRect( x + bordersize2, y+h-bordersize2, w - bordersize2 * 2, bordersize2 ) -- Bottom line
    surface.DrawRect( x, y + bordersize2, bordersize2, h - bordersize2 * 2 ) -- Left line
    surface.DrawRect( x + w - bordersize2, y + bordersize2, bordersize2, h - bordersize2 * 2 ) -- Right line

    local tex = Tex_Corner8
    if ( bordersize > 8 ) then tex = Tex_Corner16 end

    surface.SetTexture( tex )

    surface.DrawTexturedRectUV( x, y, bordersize, bordersize, 0, 0, 1, 1 ) -- Top left corner
    surface.DrawTexturedRectUV( x + w - bordersize, y, bordersize, bordersize, 1, 0, 0, 1 ) -- Top right corner
    surface.DrawTexturedRectUV( x, y + h -bordersize, bordersize, bordersize, 0, 1, 1, 0 ) -- Bottom left corner
    surface.DrawTexturedRectUV( x + w - bordersize, y + h - bordersize, bordersize, bordersize, 1, 1, 0, 0 ) -- Bottom right corner
end

local colBlur = Color(0, 0, 0)
function draw.SimpleTextBlurry(text, font, x, y, col, xalign, yalign, fadestart, fadetime)
    colBlur.r = col.r
    colBlur.g = col.g
    colBlur.b = col.b
    colBlur.a = col.a * math.Rand(0.35, 0.6)
    
    draw.SimpleText(text, font.."_blur3", x, y, colBlur, xalign, yalign)
    draw.SimpleTextOutlined(text, font, x, y, col, xalign, yalign, 1, color_black)
    
    if fadetime and fadetime > CurTime() then
        local dur = (fadetime - CurTime()) * 0.5
        local hurttime = CurTime() - fadestart
        local blurpoint = 10
        if dur - hurttime < (dur * 0.5) then
            blurpoint = (dur - hurttime) / (dur * 0.25)
            blurpoint = math.Clamp(math.floor(blurpoint * 6), 1, 10)
        end
        
        draw.SimpleText(text, font.."_blur"..blurpoint, x, y, colBlur, xalign, yalign)
    end
end

surface.OldCreateFont = surface.OldCreateFont or surface.CreateFont
function surface.CreateFont(fontName, fontData)
    surface.OldCreateFont(fontName, fontData)
    
    for i=1, 10 do 
        local blurfont = fontData
        local blurname = fontName.."_blur"..i
        blurfont.blursize = i
        surface.OldCreateFont(blurname, blurfont)
    end
end

function ScaleNumberByResolution(res, num)
    return res * (num / res)
end

-- Scales the screen based around 1080p but doesn't make things TOO tiny on low resolutions.
local math_max = math.max
local scr_h = ScrH
local last_h = 1080
local next_h_check = 0
local fr_n = FrameNumber
function BetterScreenScale()
	if next_h_check < fr_n() then
		next_h_check = fr_n() + 2000
		last_h = scr_h()
	end

	return math_max(last_h / 1080, 0.851)
end

local q = {{},{},{},{}}
function surface.DrawQuad(x1, y1, x2, y2, x3, y3, x4, y4)
    q[1].x, q[1].y = x1, y1
    q[2].x, q[2].y = x2, y2
    q[3].x, q[3].y = x3, y3
    q[4].x, q[4].y = x4, y4
    surface.DrawPoly(q)
end

local ang2rad = 3.141592653589/180
local drawquad = surface.DrawQuad
function surface.DrawArc( _x, _y, r1, r2, aStart, aFinish, steps )
    aStart, aFinish = aStart*ang2rad, aFinish*ang2rad
    local step = (( aFinish - aStart ) / steps)
    local c = steps
    
    local a, c1, s1, c2, s2
    
    c2, s2 = math.cos(aStart), math.sin(aStart)
    for _a = 0, steps - 1 do
        a = _a*step + aStart
        c1, s1 = c2, s2
        c2, s2 = math.cos(a+step), math.sin(a+step)
        
        drawquad(_x+c1*r1, _y+s1*r1, _x+c1*r2, _y+s1*r2, _x+c2*r2, _y+s2*r2, _x+c2*r1, _y+s2*r1)
        c = c - 1
        
        if c < 0 then break end
    end
end

local circleTex = surface.GetTextureID("vgui/white")
function draw.HollowCircle(cx, cy, radius, thickness, startang, endang, color)
    surface.SetTexture(circleTex)
	surface.SetDrawColor(color)
	surface.DrawArc(cx, cy, radius, radius+thickness, startang, endang, 36)
end