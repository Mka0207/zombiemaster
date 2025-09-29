if CLIENT then return end

DEFINE_BASECLASS("scripted_trigger")
ENT.Type = "brush"

ENT.TriggerOutput = TriggerOutputOverride

function ENT:KeyValue(key, value)
    key = string.lower(key)
    if string.Left(key, 2) == "on" then
        self:StoreOutput(key, value)
    end
end

function ENT:AcceptInput(name, caller, activator, arg)
    name = string.lower(name)
    if string.Left(name, 2) == "on" then
        self:TriggerOutput(name, activator, arg)
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_NEVER
end