--[[---------------------------------------------------------------------------
Z-Grad RP — Skin Fix
Серверный скрипт для принудительной установки модели при смене работы
Учитывает донат-скины (zgrad_donate модуль)
---------------------------------------------------------------------------]]

hook.Add("PlayerSpawn", "ZGrad_ForceModel onSpawn", function(ply)
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        
        local job = RPExtraTeams[ply:Team()]
        if not job then return end

        -- Проверяем наличие экипированного донат-скина для текущей профессии
        -- Если есть — не трогаем модель, донат-система сама её установит
        if ZGRAD_GetSkinByID and ZGRAD_GetTeamByCommand then
            local steamid = ply:SteamID()
            local inv = sql.Query("SELECT skin_id FROM zgrad_donate_inventory WHERE steamid = " .. sql.SQLStr(steamid) .. " AND equipped = 1")
            if inv then
                for _, row in ipairs(inv) do
                    local skinData = ZGRAD_GetSkinByID(row.skin_id)
                    if skinData and skinData.job == job.command then
                        -- У игрока есть донат-скин для этой профессии — не перезаписываем
                        return
                    end
                end
            end
        end

        local model = job.model
        if istable(model) then
            -- Если модель — таблица, выбираем случайную или текущую, если она подходит
            local current = ply:GetModel()
            local found = false
            for _, v in pairs(model) do
                if v == current then
                    found = true
                    break
                end
            end
            
            if not found then
                model = model[math.random(#model)]
                ply:SetModel(model)
            end
        elseif isstring(model) then
            -- Если модель — строка, устанавливаем её
            ply:SetModel(model)
        end
        
        ply:SetupHands() -- Обновляем руки (v_model)
    end)
end)

print("[Z-Grad RP] Skin Fix Loaded")
