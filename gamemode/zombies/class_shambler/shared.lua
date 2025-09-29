NPC.Class = "npc_zombie"
NPC.Name = translate.Get("npc_class_shambler")
NPC.Description = translate.Get("npc_description_shambler")
NPC.Icon = "VGUI/zombies/info_shambler"
NPC.IconSmall = "VGUI/zombies/queue_shambler"
NPC.IsEngineNPC = true
NPC.Flag = FL_SPAWN_SHAMBLER_ALLOWED
NPC.Cost = GetConVar("zm_cost_shambler"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_shambler"):GetInt()
NPC.Health = GetConVar("zm_zombie_health"):GetInt()

NPC.Speed = 50

NPC.HullSizeMins = Vector(-13, -13, 0)
NPC.HullSizeMaxs = Vector(13, 13, 72)

NPC.Model = {
    "models/zombie/zm_classic.mdl",
    "models/zombie/zm_classic_01.mdl",
    "models/zombie/zm_classic_02.mdl",
    "models/zombie/zm_classic_03.mdl",
    "models/zombie/zm_classic_04.mdl",
    "models/zombie/zm_classic_05.mdl",
    "models/zombie/zm_classic_06.mdl",
    "models/zombie/zm_classic_07.mdl",
    "models/zombie/zm_classic_08.mdl",
    "models/zombie/zm_classic_09.mdl"
}