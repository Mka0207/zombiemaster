function NPC:OnDamagedEnt(npc, ent, dmginfo)
    local damage = dmginfo:GetDamage()
    if damage == cvars.Number("sk_zombie_dmg_one_slash", 0) or damage == cvars.Number("sk_zombie_dmg_both_slash", 0) then
        dmginfo:SetDamage(GetConVar("zm_zombie_dmg_one_slash"):GetInt())
    end
end