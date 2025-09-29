NPC.Class = "npc_dragzombie"
NPC.Name = translate.Get("npc_class_drifter")
NPC.Description = translate.Get("npc_description_drifter")
NPC.Icon = "VGUI/zombies/info_drifter"
NPC.IconSmall = "VGUI/zombies/queue_drifter"
NPC.Flag = FL_SPAWN_DRIFTER_ALLOWED
NPC.Cost = GetConVar("zm_cost_drifter"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_drifter"):GetInt()
NPC.Health = GetConVar("zm_dragzombie_health"):GetInt()

NPC.Speed = 78

NPC.Model = "models/humans/zm_draggy.mdl"

NPC.Material = {
	"models/charple/charple4_sheet",
	"models/charple/charple4_sheet2",
	"models/charple/charple4_sheet3",
	"models/charple/charple4_sheet4"
}

NPC.DrawSkeleton = false
NPC.MaxGoreElements = 2
NPC.GoreScale = 1