hook.Add("EntityKeyValue", "changing", function(ent, key, value)
    if ent:GetClass() == "func_door" and key == "spawnpos" then
        return value == 0 and 1 or 0
    end
end)