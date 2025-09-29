ENT.Base = "base_nextbot"
ENT.Type = "nextbot"

ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()
    self:NetworkVar("Vector", 0, "DamageForce")
end

util.PrecacheModel( "models/props_junk/rock001a.mdl" )
util.PrecacheModel( "models/player/skeleton.mdl" )
util.PrecacheModel( "models/player/charple.mdl" )
util.PrecacheModel( "models/player/zombie_fast.mdl" )

util.PrecacheSound( "player/headshot1.wav" )
util.PrecacheSound( "player/headshot2.wav" )

for i=1,3 do
	util.PrecacheSound( "physics/wood/wood_strain"..i..".wav" )
end
util.PrecacheSound("physics/body/body_medium_break2.wav")
util.PrecacheSound("physics/body/body_medium_break3.wav")
util.PrecacheSound("physics/body/body_medium_break4.wav")

util.PrecacheModel( "models/gibs/antlion_gib_small_1.mdl" )
util.PrecacheModel( "models/gibs/antlion_gib_small_2.mdl" )
util.PrecacheModel( "models/props_junk/watermelon01_chunk02a.mdl" )