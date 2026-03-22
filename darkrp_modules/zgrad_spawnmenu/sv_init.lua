--[[---------------------------------------------------------------------------
Z-Grad RP — Tool & Spawn Restrictions (SERVER)
---------------------------------------------------------------------------]]

local allowedTools = {
    ["adv_duplicator2"] = true,
    ["advdupe2"] = true,
    ["button"] = true,
    ["material"] = true,
    ["colour"] = true,
    ["fading_door"] = true,
    ["keypad_willox"] = true,
    ["keypad"] = true,
    ["zgrad_stacker"] = true,
    ["zgrad_precision"] = true,
    ["camera"] = true,
    ["weld"] = true,
    ["remover"] = true,
    -- ["rope"] = true, -- Убрано по просьбе
}

-- Глобальные лимиты (через консольные переменные для базы)
RunConsoleCommand("sbox_maxprops", "60")
RunConsoleCommand("sbox_maxbuttons", "6")
RunConsoleCommand("sbox_maxkeypads", "6")

-- Следим за Fading Door (так как у них нет стандартного лимита)
hook.Add("CanTool", "ZGrad_FinalBlock", function(ply, trace, tool)
    if not IsValid(ply) then return end
    if ply:IsSuperAdmin() then return true end
    
    local tid = string.lower(tool or "")
    
    -- Проверка вайтлиста
    if not allowedTools[tid] then
        return false
    end

    -- Лимит для Fading Door (10 штук)
    if tid == "fading_door" then
        local count = 0
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent.isFadingDoor and ent:GetNWEntity("owner") == ply then
                count = count + 1
            end
        end
        if count >= 10 then
            ply:ChatPrint("[Z-Grad] Лимит Fading Door исчерпан (макс: 10)!")
            return false
        end
    end
end)

-- Хук для отслеживания установки Fading Door (установка пометки)
hook.Add("CanTool", "ZGrad_MarkFadingDoor", function(ply, trace, tool)
    if tool == "fading_door" and trace.Entity and IsValid(trace.Entity) then
        trace.Entity.isFadingDoor = true
        trace.Entity:SetNWEntity("owner", ply)
    end
end)

hook.Add("PlayerDisconnected", "ZGrad_CleanupStackerProps", function(ply)
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:GetNWEntity("owner") == ply then
            if ent:GetModel() and not ent:IsPlayer() then
                ent:Remove()
            end
        end
    end
end)

-- Ограничение пропов (60 штук) через хук (для надежности)
hook.Add("PlayerSpawnProp", "ZGrad_LimitProps", function(ply, model)
    if not IsValid(ply) or ply:IsSuperAdmin() then return end
    
    if ply:GetCount("props") >= 60 then
        ply:ChatPrint("[Z-Grad] Превышен лимит пропов (макс: 60)!")
        return false
    end
end)

local function AdminOnlySpawn(ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return false end
end

hook.Add("PlayerSpawnEntity", "ZGrad_RestrictSpawn", AdminOnlySpawn)
hook.Add("PlayerSpawnNPC", "ZGrad_RestrictSpawn", AdminOnlySpawn)
hook.Add("PlayerSpawnVehicle", "ZGrad_RestrictSpawn", AdminOnlySpawn)
hook.Add("PlayerSpawnSENT", "ZGrad_RestrictSpawn", AdminOnlySpawn)

print("[Z-Grad RP] Server Tool Shield & Limits LOADED")
