NPC.HullSizeMins = Vector(-13, -13, 0)
NPC.HullSizeMaxs = Vector(13, 13, 72)

function NPC:OnScaledDamage(npc, hitgroup, dmginfo)
    return false
end