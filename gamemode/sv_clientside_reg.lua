local DM = FindMetaTable("CTakeDamageInfo")
local DMG_SetDamage = DM.SetDamage
local DMG_GetDamage = DM.GetDamage
local DMG_SetDamagePosition = DM.SetDamagePosition
local DMG_SetDamageForce = DM.SetDamageForce
local DMG_SetAttacker = DM.SetAttacker
local DMG_SetInflictor = DM.SetInflictor
local DMG_SetDamageType = DM.SetDamageType

local ply_trace_list = {}
function GetDataFromRecordTrack(pl)
    return ply_trace_list[pl]
end

function AddDataToRecordTrack(pl, data)
    if not ply_trace_list[pl] then
        ply_trace_list[pl] = {}
    end

    ply_trace_list[pl][#ply_trace_list[pl] + 1] = data
end

local function ClientsideHitProcess(len, ply)
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end -- Impossible!

    local CT = CurTime()
    if CT >= ((ply.LastTimeShoot or 0) + 1) then return end -- Too long... possible cheater...

    local primary_fired = (wep:GetNextPrimaryFire() + 1) >= CT
    local secondary_fired = (wep:GetNextSecondaryFire() + 1) >= CT
    local firebullet_last_called = ((ply.LastTimeCallFireBullet or 0) + 1) >= CT

    if (firebullet_last_called or primary_fired or secondary_fired) then
        -- decompress them!
        local bytes_amount = net.ReadUInt( 16 )
        local data_compressed = net.ReadData( bytes_amount )
        if bytes_amount == 0 then return end -- empty..
        local str_decompressed = util.Decompress( data_compressed )
        if not str_decompressed then return end -- EMPTY COMPRESSS?!!!!!

        local damage_list = {} -- multi shot or pen or whatever...
        local has_damage_to_do = false
        -- Example; "Index:HitGroup|Index2:HitGroup2|Index3:HitGroup3"
        -- Now we need extract these string with using split.
        local str_splited = string.Split(str_decompressed, "|")
        for i = 1, #str_splited do
            local str_splited_infos = str_splited[i]
            if not str_splited_infos then continue end

            local str_hitinfo_splitted = string.Split(str_splited_infos, ":")
            if not str_hitinfo_splitted then continue end

            local target_entindex = tonumber(str_hitinfo_splitted[1])
            if not target_entindex then continue end

            local target_hitbone = tonumber(str_hitinfo_splitted[2])
            if not target_hitbone then continue end

            local ent = Entity(target_entindex)
            if not IsValid(ent) then continue end

            local bullet_data = GetDataFromRecordTrack(ply) -- data from firebullet (serverside)

            local data_info = bullet_data and bullet_data[1]
            if not data_info then return end -- EMPTY?

            local target_hitgroup = HITGROUP_GENERIC
            local target_hitbox = 0
            local hitboxsets = ent.GetHitBoxSetCount and ent:GetHitBoxSetCount() or 1

            for hitboxset = 0, hitboxsets - 1 do
                local hitboxes = ent:GetHitBoxCount(hitboxset)
                if hitboxes then
                    for hitbox = 0, hitboxes - 1 do
                        local bone = ent:GetHitBoxBone(hitbox, hitboxset)
                        if bone and bone == target_hitbone then
                            target_hitgroup = ent:GetHitBoxHitGroup(hitbox, hitboxset)
                            target_hitbox = hitbox
                            break
                        end
                    end
                end
            end

            local cur_damage = damage_list[ent]
            local ent_player = EntityIsPlayer(ent)
            local ent_npc = ent:IsNPC()
            local ent_nextbot = ent:IsNextBot()
            local damageinfo = DamageInfo()

            local targetpos = ((ent_player or ent_npc or ent_nextbot) and ent:GetBonePosition(target_hitbone)) or data_info.tr.HitPos -- this is expensive...

            -- Override them
            data_info.tr.HitPos = targetpos or data_info.tr.HitPos
            data_info.tr.HitGroup = target_hitgroup or data_info.tr.HitGroup
            data_info.tr.HitBox = target_hitbox or data_info.tr.HitBox

            DMG_SetDamageType(damageinfo, DMG_BULLET)
            DMG_SetDamage(damageinfo, data_info.damage)
            DMG_SetDamagePosition(damageinfo, data_info.tr.HitPos)
            DMG_SetAttacker(damageinfo, data_info.attacker)
            DMG_SetInflictor(damageinfo, data_info.inflictor and IsValid(data_info.inflictor) and data_info.inflictor or wep)

            local vecForce = data_info.dir:GetNormalized()
            vecForce = vecForce * GetConVar("phys_pushscale"):GetFloat()
            vecForce = vecForce * data_info.force_mul
            vecForce = vecForce * game.GetAmmoForce(data_info.ammo_id)
            DMG_SetDamageForce(damageinfo, vecForce)

            local ret = wep:DefaultCallBack(data_info.attacker, data_info.tr, damageinfo)
            if ret then
                if ret.tracer ~= nil then use_tracer = ret.tracer end
                if ret.impact ~= nil then use_impact = ret.impact end
                if ret.ragdoll_impact ~= nil then use_ragdoll_impact = ret.ragdoll_impact end
                if ret.damage ~= nil then use_damage = ret.damage end
            end

            if ent_player then
                gamemode.Call("ScalePlayerDamage", ent, target_hitgroup, damageinfo)
            elseif ent_npc then
                gamemode.Call("NPCTraceAttack", ent, damageinfo, data_info.dir, data_info.tr)
            end

            if not cur_damage then
                cur_damage = {
                    Info = damageinfo,
                    Pos = targetpos or data_info.tr.HitPos,
                    Trace = data_info.tr,
                    Damage = DMG_GetDamage(damageinfo) * (damage_multiplier or 1),
                    Hits = 1
                }

                damage_list[ent] = cur_damage
            else
                cur_damage.Damage = cur_damage.Damage + DMG_GetDamage(damageinfo)
                cur_damage.Hits = cur_damage.Hits + 1
            end

            table.remove(data_info, 1) -- remove table that done in loop.

            has_damage_to_do = true
        end

        if not has_damage_to_do then return end

        for ent, dmg_data in pairs(damage_list) do
            local final_dmginfo = dmg_data.Info

            DMG_SetDamage(final_dmginfo, dmg_data.Damage)
            DMG_SetDamagePosition(final_dmginfo, dmg_data.Pos)

            ent:DispatchTraceAttack(final_dmginfo, dmg_data.Trace)
        end
    end

    ply_trace_list[ply] = {} -- clear
end

hook.Add("EntityFireBullets", "CL_EntityFireBullets", function(attacker, data)
    if not EntityIsPlayer(attacker) then return end

    attacker.LastTimeCallFireBullet = CurTime()

    data.Damage = 0 -- we dont need damage anything.
    return data
end)

util.AddNetworkString( "zm_infos" )
net.Receive("zm_infos", ClientsideHitProcess)