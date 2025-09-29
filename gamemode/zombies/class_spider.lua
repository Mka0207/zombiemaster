NPC.Class = "npc_headcrab"
NPC.Name = translate.Get("npc_class_spider")
NPC.Description = translate.Get("npc_description_spider")
NPC.Icon = "VGUI/zombies/info_spider"
NPC.IconSmall = "VGUI/zombies/queue_spider"
NPC.Flag = FL_SPAWN_HULK_ALLOWED
NPC.Cost = GetConVar("zm_cost_spider"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_spider"):GetInt()
NPC.Health = GetConVar("zm_spider_health"):GetInt()
NPC.IsEngineNPC = true

NPC.Model = "models/headcrabclassic_spider.mdl"

if not SERVER then return end

NPC.Capabilities = bit.bor(CAP_SQUAD, CAP_MOVE_GROUND, CAP_INNATE_RANGE_ATTACK1, CAP_SKIP_NAV_GROUND_CHECK)