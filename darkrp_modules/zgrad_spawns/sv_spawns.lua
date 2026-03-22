--[[---------------------------------------------------------------------------
Z-Grad RP — Spawn System для карты Bangclaw
Серверный модуль: спауны по профессиям
---------------------------------------------------------------------------
Формат: Vector(X, Y, Z)
---------------------------------------------------------------------------]]

local TeamSpawns = nil
local TeamSpawnAngles = nil

local function InitSpawns()
    if TeamSpawns then return end

    print("[Z-Grad RP] Initializing spawns...")

    TeamSpawns = {}
    
    local function SafeAdd(teamID, posTable)
        if teamID and type(teamID) == "number" then
            TeamSpawns[teamID] = posTable
        end
    end

    SafeAdd(TEAM_POLICE, {
        Vector(4338.428223, -452.386810, 135.767639),    
        Vector(4338.735352, -559.319092, 135.682373),   
        Vector(4356.406738, -722.534485, 135.798431),  
        Vector(4190.952637, -649.719543, 135.790070),  
    })
    SafeAdd(TEAM_FBI, {
        Vector(4338.428223, -452.386810, 135.767639),   
        Vector(4338.735352, -559.319092, 135.682373),  
        Vector(4356.406738, -722.534485, 135.798431), 
    })
    SafeAdd(TEAM_MAYOR, { Vector(519.008179, 2259.899902, 135.617065) })
    SafeAdd(TEAM_MAFIA, { Vector(-8.929579, -2491.449219, 135.599838) })
    SafeAdd(TEAM_MANIAC, { Vector(-8.929579, -2491.449219, 135.599838) })
    SafeAdd(TEAM_GUN, { 
        Vector(-8.929579, -2491.449219, 135.599838),
        Vector(112.959694, -2494.747314, 135.456604),
    })
    SafeAdd(TEAM_KILLER, {
        Vector(-8.929579, -2491.449219, 135.599838),
        Vector(112.959694, -2494.747314, 135.456604),
    })
    
    local citSpawns = {
        Vector(-8.929579, -2491.449219, 135.599838),
        Vector(112.959694, -2494.747314, 135.456604),
        Vector(149.326874, -2660.485596, 135.939560),
        Vector(23.441168, -2700.378174, 135.337616),
        Vector(-71.774727, -2880.073730, 135.453125),
        Vector(134.004959, -2935.959473, 135.635483),
        Vector(65.991249, -3023.556152, 135.645035),
    }
    SafeAdd(TEAM_CITIZEN, citSpawns)
    SafeAdd(TEAM_COOK, citSpawns)
    SafeAdd(TEAM_MEDIC, citSpawns)
    SafeAdd(TEAM_DRUGS, citSpawns)
    SafeAdd(TEAM_TERRORIST, citSpawns)
    SafeAdd(TEAM_AUTOMEHANIK, citSpawns)
    SafeAdd(TEAM_RABOTORGOVEC, citSpawns)
    SafeAdd(TEAM_BUM, citSpawns)
    SafeAdd(TEAM_SECURITY, citSpawns)
    SafeAdd(TEAM_BANKER, citSpawns)
    SafeAdd(TEAM_PARKURIST, citSpawns)
    SafeAdd(TEAM_RADIOHOST, citSpawns)
    SafeAdd(TEAM_MAFIA_BOSS, citSpawns)

    SafeAdd(TEAM_ADMIN, {
        Vector(-858.864075, 2594.509277, 128.940125),
        Vector(-743.629578, 2572.811523, 128.031250),
        Vector(-624.503479, 2501.616455, 128.031250),
        Vector(-725.096069, 2382.411865, 128.031250),
    })
    TeamSpawnAngles = {}
    local function SafeAddAng(teamID, ang)
        if teamID and type(teamID) == "number" then
            TeamSpawnAngles[teamID] = ang
        end
    end

    SafeAddAng(TEAM_POLICE, Angle(0, 90, 0))
    SafeAddAng(TEAM_FBI, Angle(0, 90, 0))
    SafeAddAng(TEAM_MAYOR, Angle(0, 180, 0))
    SafeAddAng(TEAM_MAFIA, Angle(0, 270, 0))
    SafeAddAng(TEAM_MANIAC, Angle(0, 0, 0))
    SafeAddAng(TEAM_GUN, Angle(0, 90, 0))
    SafeAddAng(TEAM_KILLER, Angle(0, 0, 0))
    SafeAddAng(TEAM_CITIZEN, Angle(0, 0, 0))
    SafeAddAng(TEAM_MEDIC, Angle(0, 0, 0))
    SafeAddAng(TEAM_DRUGS, Angle(0, 0, 0))
    SafeAddAng(TEAM_COOK, Angle(0, 0, 0))
    SafeAddAng(TEAM_TERRORIST, Angle(0, 0, 0))
    SafeAddAng(TEAM_AUTOMEHANIK, Angle(0, 0, 0))
    SafeAddAng(TEAM_RABOTORGOVEC, Angle(0, 0, 0))
    SafeAddAng(TEAM_BUM, Angle(0, 0, 0))
    SafeAddAng(TEAM_ADMIN, Angle(0, 0, 0))
    SafeAddAng(TEAM_SECURITY, Angle(0, 0, 0))
    SafeAddAng(TEAM_BANKER, Angle(0, 0, 0))
    SafeAddAng(TEAM_PARKURIST, Angle(0, 0, 0))
    SafeAddAng(TEAM_RADIOHOST, Angle(0, 0, 0))
    TeamSpawnEntities = {}
    for tId, posList in pairs(TeamSpawns) do
        TeamSpawnEntities[tId] = {}
        for _, pos in ipairs(posList) do
            local ent = ents.Create("info_target")
            ent:SetPos(pos)
            local ang = TeamSpawnAngles[tId] or Angle(0,0,0)
            ent:SetAngles(ang)
            ent:Spawn()
            table.insert(TeamSpawnEntities[tId], ent)
        end
    end
    
    print("[Z-Grad RP] Spawns initialized.")
end

local function IsValidTeam(t)
    return t != nil and type(t) == "number"
end

-- Хук для нативного спауна через движок (чтобы не было телепортов)
hook.Add("PlayerSelectSpawn", "ZGrad_NativeSpawns", function(ply)
    if OverrideSpawn then return end

    InitSpawns()
    
    local team = ply:Team()
    if TeamSpawnEntities and TeamSpawnEntities[team] and #TeamSpawnEntities[team] > 0 then
        local validEnts = {}
        for _, ent in ipairs(TeamSpawnEntities[team]) do
            if IsValid(ent) then table.insert(validEnts, ent) end
        end
        if #validEnts > 0 then
            return validEnts[math.random(#validEnts)]
        end
    end
end)

-- Хук при смене профессии переспаунивает игрока
hook.Add("OnPlayerChangedTeam", "ZGrad_ForceRespawn", function(ply, oldTeam, newTeam)
    -- Чтобы обновились оружие и позиция
    timer.Simple(0.1, function()
        if IsValid(ply) then
            ply:Spawn()
        end
    end)
end)

-- Уведомление в консоль
print("[Z-Grad RP] Spawn system loaded for Bangclaw map (V2 Native)")

