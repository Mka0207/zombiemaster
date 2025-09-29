NPC.Class = "npc_poisonzombie"
NPC.Name = translate.Get("npc_class_hulk")
NPC.Description = translate.Get("npc_description_hulk")
NPC.Icon = "VGUI/zombies/info_hulk"
NPC.IconSmall = "VGUI/zombies/queue_hulk"
NPC.IsEngineNPC = true
NPC.Flag = FL_SPAWN_HULK_ALLOWED
NPC.Cost = GetConVar("zm_cost_hulk"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_hulk"):GetInt()
NPC.Health = GetConVar("zm_zombie_poison_health"):GetInt()

NPC.Speed = 130

NPC.Model = "models/zombie/hulk.mdl"
NPC.SkinNum = 3

NPC.MeatModel = Model( "models/player/zombie_fast.mdl" )
NPC.DrawSkeleton = true
NPC.GoreScale = 1.35
NPC.MaxGoreElements = 4