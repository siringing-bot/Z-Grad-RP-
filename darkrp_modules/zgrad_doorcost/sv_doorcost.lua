--[[---------------------------------------------------------------------------
Z-Grad RP — Динамическая стоимость дверей (Server)
---------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
Z-Grad RP — Динамическая стоимость дверей (SERVER - ULTRA DEBUG VERSION)
---------------------------------------------------------------------------]]

--[[---------------------------------------------------------------------------
Z-Grad RP — Динамическая стоимость дверей (Server)
---------------------------------------------------------------------------]]

local playerCooldowns = {}

local function ApplyDoorTax(ply, ent, cost)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    -- Защита от двойного срабатывания (разные хуки могут стрелять одновременно)
    local plyID = ply:SteamID64()
    if (playerCooldowns[plyID] or 0) > CurTime() then return end
    playerCooldowns[plyID] = CurTime() + 0.5
    
    local basePrice = cost or (GAMEMODE.Config and GAMEMODE.Config.doorcost) or 30
    
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        
        local currentMoney = ply:getDarkRPVar("money") or 0
        local moneyBefore = currentMoney + basePrice
        
        -- Налог: 5$ за каждую тысячу от баланса ДО покупки
        local extraTax = math.floor(moneyBefore / 1000) * 5
        
        -- Логируем в консоль для контроля админом
        print(string.format("[DOOR-TAX] %s: База %d, Налог %d, Баланс до %d", 
            ply:Nick(), basePrice, extraTax, moneyBefore))

        if extraTax > 0 then
            if currentMoney >= extraTax then
                ply:addMoney(-extraTax)
                DarkRP.notify(ply, 0, 6, "Налог на имущество: " .. DarkRP.formatMoney(extraTax) .. " (за баланс " .. DarkRP.formatMoney(moneyBefore) .. ")")
            else
                local available = math.max(0, currentMoney)
                if available > 0 then
                    ply:addMoney(-available)
                    DarkRP.notify(ply, 1, 6, "Не хватило на налог! Списан остаток: " .. DarkRP.formatMoney(available))
                end
            end
        end
    end)
end

-- Регистрируем хуки (теперь с защитой от дублей они не страшны)
hook.Add("onPlayerBuyDoor", "ZGrad_Tax_H1", ApplyDoorTax)
hook.Add("playerBuyDoor", "ZGrad_Tax_H2", ApplyDoorTax)
hook.Add("keysBoughtProperty", "ZGrad_Tax_H5", ApplyDoorTax)

-- Проверка перед покупкой
hook.Add("canBuyDoor", "ZGrad_Tax_Check", function(ply, ent)
    local totalCost = ZGrad_GetDoorCost(ply, ent)
    if not ply:canAfford(totalCost) then
        return false, "Недостаточно средств с учетом налога! Нужно: " .. DarkRP.formatMoney(totalCost)
    end
end)

print("[Z-Grad RP] Door Tax System Loaded (Double-trigger protected)")


