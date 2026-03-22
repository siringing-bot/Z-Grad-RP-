--[[---------------------------------------------------------------------------
Z-Grad RP — Global Save System (NPCs & Doors)
---------------------------------------------------------------------------]]

local NPCSaveFile = "zgrad/npcs/" .. game.GetMap() .. ".json"
local DoorSaveFile = "zgrad/doors/" .. game.GetMap() .. ".json"

-- Список классов NPC для сохранения
local classesToSave = {
    "zgrad_equipment_npc",
    "zgrad_weapon_seller",
    "zgrad_trash_can",
    "zgrad_contraband_dealer",
    "zgrad_hitman_npc",
    "zgrad_meth_scientist",
    "zgrad_meth_buyer",
    "zgrad_blood_scholar",
    "zgrad_mask_kit",
    "zgrad_counterfeiter_npc",
}

-- СОХРАНЕНИЕ NPC
local function SaveZGradNPCs()
    local npcs = {}
    
    for _, class in ipairs(classesToSave) do
        for _, ent in ipairs(ents.FindByClass(class)) do
            table.insert(npcs, {
                class = class,
                pos = ent:GetPos(),
                ang = ent:GetAngles()
            })
        end
    end
    
    if not file.Exists("zgrad/npcs", "DATA") then
        file.CreateDir("zgrad/npcs")
    end
    
    file.Write(NPCSaveFile, util.TableToJSON(npcs))
    print("[ZGrad] Saved " .. #npcs .. " NPCs.")
end

-- СОХРАНЕНИЕ ДВЕРЕЙ
local function SaveZGradDoors()
    local doors = {}
    local doorClasses = {
        ["prop_door_rotating"] = true,
        ["func_door"] = true,
        ["func_door_rotating"] = true,
    }

    for _, ent in ipairs(ents.GetAll()) do
        if doorClasses[ent:GetClass()] then
            local mid = ent:MapCreationID()
            if mid == -1 then continue end -- Пропускаем динамические двери (не с карты)

            local data = {}
            local changed = false

            -- Проверяем параметры DarkRP
            if ent.getKeysNonOwnable and ent:getKeysNonOwnable() then
                data.nonOwnable = true
                changed = true
            end

            local title = ent.getKeysTitle and ent:getKeysTitle()
            if title and title ~= "" then
                data.title = title
                changed = true
            end

            local group = ent.getKeysDoorGroup and ent:getKeysDoorGroup()
            if group then
                data.group = group
                changed = true
            end

            local teams = ent.getKeysDoorTeams and ent:getKeysDoorTeams()
            if teams and table.Count(teams) > 0 then
                data.teams = teams
                changed = true
            end

            if changed then
                doors[tostring(mid)] = data
            end
        end
    end

    if not file.Exists("zgrad/doors", "DATA") then
        file.CreateDir("zgrad/doors")
    end

    file.Write(DoorSaveFile, util.TableToJSON(doors))
    print("[ZGrad] Saved " .. table.Count(doors) .. " Doors.")
end

-- ЗАГРУЗКА NPC
local function LoadZGradNPCs()
    if not file.Exists(NPCSaveFile, "DATA") then return end
    
    local data = file.Read(NPCSaveFile, "DATA")
    local npcs = util.JSONToTable(data)
    if not npcs then return end
    
    print("[ZGrad] Loading NPCs...")
    for _, info in ipairs(npcs) do
        local className = info.class 
        local ent = ents.Create(className)
        if IsValid(ent) then
            ent:SetPos(info.pos)
            ent:SetAngles(info.ang)
            ent:Spawn()
        end
    end
end

-- ЗАГРУЗКА ДВЕРЕЙ
local function LoadZGradDoors()
    if not file.Exists(DoorSaveFile, "DATA") then return end

    local data = file.Read(DoorSaveFile, "DATA")
    local doors = util.JSONToTable(data)
    if not doors then return end

    print("[ZGrad] Loading Door persistency...")
    for _, ent in ipairs(ents.GetAll()) do
        local mid = tostring(ent:MapCreationID())
        if doors[mid] then
            local d = doors[mid]
            if d.nonOwnable and ent.setKeysNonOwnable then ent:setKeysNonOwnable(true) end
            if d.title and ent.setKeysTitle then ent:setKeysTitle(d.title) end
            if d.group and ent.setKeysDoorGroup then ent:setKeysDoorGroup(d.group) end
            if d.teams and ent.setKeysDoorTeams then ent:setKeysDoorTeams(d.teams) end
        end
    end
end

-- ОБЩАЯ КОМАНДА
concommand.Add("zgrad_save", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("Access denied.")
        return
    end

    SaveZGradNPCs()
    SaveZGradDoors()

    if IsValid(ply) then
        ply:ChatPrint("[ZGrad] NPCs and Doors SAVED!")
    else
        print("[ZGrad] NPCs and Doors SAVED!")
    end
end)

-- Автозагрузка
hook.Add("InitPostEntity", "ZGrad_GlobalLoad", function()
    -- Задержка для DarkRP
    timer.Simple(2, function()
        LoadZGradNPCs()
        LoadZGradDoors()
    end)
end)

hook.Add("PostCleanupMap", "ZGrad_GlobalLoad_Cleanup", function()
    timer.Simple(1, function()
        LoadZGradNPCs()
        LoadZGradDoors()
    end)
end)
