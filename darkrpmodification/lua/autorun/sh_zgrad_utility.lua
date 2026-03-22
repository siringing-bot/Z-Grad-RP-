--[[---------------------------------------------------------------------------
Z-Grad RP — Global Utility
---------------------------------------------------------------------------]]

ZGrad_Utility = ZGrad_Utility or {}

function ZGrad_Utility.IsCriminal(ply)
    if not IsValid(ply) then return false end
    
    local t = ply:Team()
    local jobName = ply:getDarkRPVar("job") or (team and team.GetName(t)) or "N/A"
    
    print("[ZGrad Utility Debug] Checking job for " .. ply:Nick() .. ". TeamID: " .. tostring(t) .. ", JobName: " .. tostring(jobName))

    -- Check by constants if they exist
    if (TEAM_MAFIA and t == TEAM_MAFIA) or 
       (TEAM_MANIAC and t == TEAM_MANIAC) or 
       (TEAM_KILLER and t == TEAM_KILLER) or
       (TEAM_DRUGS and t == TEAM_DRUGS) then
        print("[ZGrad Utility Debug] Result: TRUE (via Team ID constant)")
        return true
    end

    -- Fallback by job name keywords
    local criminalKeywords = {"мафия", "маньяк", "убийца", "варок", "meth"}
    local lowerJob = string.lower(jobName)
    
    for _, kw in ipairs(criminalKeywords) do
        if string.find(lowerJob, kw) then
            print("[ZGrad Utility Debug] Result: TRUE (via Job Name keyword: " .. kw .. ")")
            return true
        end
    end

    print("[ZGrad Utility Debug] Result: FALSE")
    return false
end

MsgC(Color(0, 255, 0), "[ZGrad Utility] Loaded successfully!\n")
