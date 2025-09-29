hook.Add("PlayerUse", "stopelevatorspam", function(pl, ent)
    if ent:GetClass() == "func_button" then
        if (ent.m_iClickedTime or 0) > CurTime() then
            return false
        end
        
        ent.m_iClickedTime = CurTime() + 8
    end
end)