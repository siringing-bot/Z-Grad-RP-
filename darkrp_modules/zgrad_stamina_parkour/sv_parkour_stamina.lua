--[[---------------------------------------------------------------------------
Z-Grad RP — Parkourist Stamina Module
---------------------------------------------------------------------------]]

print("[Z-Grad RP] Initializing Parkourist Stamina Module...")

hook.Add("Think", "ZGrad_Parkourist_Stamina", function()
    -- Ensure TEAM_PARKURIST exists before proceeding
    if not TEAM_PARKURIST then return end

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() then continue end
        
        if ply:Team() == TEAM_PARKURIST then
            -- 1. Support for Homigrad organism system (if present)
            if ply.organism and ply.organism.stamina then
                -- Keep stamina at max
                ply.organism.stamina[1] = ply.organism.stamina.max or 180
            end
            
            -- 2. Support for Networked Variable stamina (used in some huds/systems)
            -- We set it to 100 to ensure the bar stays full
            if ply.SetNWFloat then
                ply:SetNWFloat("stamina", 100)
            end
        end
    end
end)

print("[Z-Grad RP] Parkourist Stamina Module Loaded")
