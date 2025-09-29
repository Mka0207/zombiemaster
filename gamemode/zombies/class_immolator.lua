NPC.Class = "npc_burnzombie"
NPC.Name = translate.Get("npc_class_immolator")
NPC.Description = translate.Get("npc_description_immolator")
NPC.Icon = "VGUI/zombies/info_immolator"
NPC.IconSmall = "VGUI/zombies/queue_immolator"
NPC.Flag = FL_SPAWN_IMMOLATOR_ALLOWED
NPC.Cost = GetConVar("zm_cost_immolator"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_immolator"):GetInt()
NPC.Health = GetConVar("zm_burnzombie_health"):GetInt()

NPC.Speed = 79

NPC.Model = "models/zombie/burnzie.mdl"

NPC.HullSizeMins = Vector(-13, -13, 0)
NPC.HullSizeMaxs = Vector(13, 13, 70)

NPC.DrawSkeleton = false
NPC.GoreScale = 1

function NPC:OnKilled(npc, attacker, inflictor)
    self.BaseClass.OnKilled(self, npc, attacker, inflictor)
    
    if npc.bHasExploded then
        npc.bHasExploded = true
        
        if attacker == npc then
            util.BlastDamage(npc, npc, npc:GetPos(), 150, 25)
        else
            local effect = EffectData()
                effect:SetOrigin(npc:GetPos())
            util.Effect("Explosion", effect, true, true)
            
            util.BlastDamage(npc, npc, npc:GetPos(), 95, 25)
        end
    end
end