-- zgrad_hunger/sv_hunger.lua
-- Improved persistent hunger system for DarkRP

local hungerCache = {}
local immunityCache = {}

local function SaveHunger(ply)
    if not IsValid(ply) then return end
    local energy = ply:getDarkRPVar("energy") or 100
    hungerCache[ply:SteamID64()] = energy
    
    if ply.ZGrad_HungerImmune and ply.ZGrad_HungerImmuneEnd and ply.ZGrad_HungerImmuneEnd > CurTime() then
        immunityCache[ply:SteamID64()] = ply.ZGrad_HungerImmuneEnd
    else
        immunityCache[ply:SteamID64()] = nil
    end
end

-- Periodically save all players' hunger to handle unexpected disconnects or crashes
timer.Create("zgrad_Hunger_AutoSave", 60, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        SaveHunger(ply)
    end
end)

-- Real-time sync: Save hunger to cache whenever it changes
-- This prevents "rollback" bugs when standing up from fake/ragdoll
hook.Add("DarkRPVarChanged", "zgrad_Hunger_RealTimeSync", function(ply, var, old, new)
    if var == "energy" then
        hungerCache[ply:SteamID64()] = new
    end
end)

-- Custom Hunger Drain Logic
-- This ensures hunger falls even if DarkRP's internal module is acting up
print("[Z-Grad RP] Initializing Hunger Drain Timer...")
timer.Create("zgrad_Hunger_Drain", 20, 0, function()
    local drainAmount = (GAMEMODE.Config.hungerspeed or 2)
    
    -- Если 0 игроков за повара (TEAM_COOK), голод тратится в 2 раза медленнее
    if TEAM_COOK and team.NumPlayers(TEAM_COOK) == 0 then
        drainAmount = drainAmount / 2
    end

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() then continue end
        if ply.ZGrad_HungerImmune then continue end
        
        local current = ply:getDarkRPVar("energy") or 100
        local nextVal = math.max(0, current - drainAmount)
        
        if nextVal ~= current then
            ply:setDarkRPVar("energy", nextVal)
        end
    end
end)

-- Save hunger when player dies
hook.Add("DoPlayerDeath", "zgrad_Hunger_SaveOnDeath", function(ply)
    SaveHunger(ply)
end)

-- Save hunger when player changes job
hook.Add("OnPlayerChangedTeam", "zgrad_Hunger_SaveOnJobChange", function(ply, before, after)
    SaveHunger(ply)
end)

-- Restore hunger when player spawns
hook.Add("PlayerSpawn", "zgrad_Hunger_RestoreOnSpawn", function(ply)
    local steamID = ply:SteamID64()
    
    if hungerCache[steamID] then
        local savedEnergy = hungerCache[steamID]
        
        -- Allow hunger below 10% to persist, but keep at least 1% to prevent instant death frame
        savedEnergy = math.max(savedEnergy, 1)
        
        -- We use multiple timers to ensure we override DarkRP's default reset to 100
        -- DarkRP usually resets on spawn, so we catch it shortly after.
        timer.Simple(0.5, function()
            if IsValid(ply) then
                ply:setDarkRPVar("energy", savedEnergy)
            end
        end)
        
        timer.Simple(1.5, function()
            if IsValid(ply) then
                ply:setDarkRPVar("energy", savedEnergy)
            end
        end)
    end
    
    if immunityCache[steamID] and immunityCache[steamID] > CurTime() then
        ply.ZGrad_HungerImmune = true
        ply.ZGrad_HungerImmuneEnd = immunityCache[steamID]
        ply:setDarkRPVar("hungerImmuneEnd", ply.ZGrad_HungerImmuneEnd)
    end
end)

-- Save when player leaves the server
hook.Add("PlayerDisconnected", "zgrad_Hunger_SaveOnDisconnect", function(ply)
    SaveHunger(ply)
end)

print("[Z-Grad RP] Persistent Hunger Module Loaded")
