local meta = FindMetaTable("Entity")
if not meta then return end

function meta:IsPlayerHolding()
    local isHolding = self.bHeldBy and self.bHeldBy:IsValid()
    if self.bIsHolding ~= isHolding then
        self:SetNW2Bool("holding", isHolding)
    end
    return isHolding
end