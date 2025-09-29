hook.Add("InitPostEntityMap", "InitPostEntityMap.FixBrokenMath", function()
    for _, ent in ipairs(ents.FindByName("CounterGas")) do
        ent:SetKeyValue("StartDisabled", 0)
    end
end)