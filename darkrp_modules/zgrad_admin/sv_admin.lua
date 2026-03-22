--[[---------------------------------------------------------------------------
Z-Grad RP — Admin Commands
---------------------------------------------------------------------------]]

local function SetMoney(ply, cmd, args)
    -- Check if it's the server console or a SuperAdmin
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "Эту команду могут использовать только Super Admin!")
        return
    end

    if #args < 2 then
        local msg = "Использование: zgrad_setmoney <имя/SteamID> <сумма>"
        if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end
        return
    end

    local target = DarkRP.findPlayer(args[1])
    local amount = tonumber(args[2])

    if not target then
        local msg = "Игрок не найден: " .. args[1]
        if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end
        return
    end

    if not amount or amount < 0 then
        local msg = "Укажите корректную сумму!"
        if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, msg) else print(msg) end
        return
    end

    target:setDarkRPVar("money", amount)
    
    -- Save to Database
    MySQLite.query(string.format("UPDATE darkrp_player SET wallet = %d WHERE uid = %s", amount, target:SteamID64()))

    local successMsg = string.format("Баланс игрока %s установлен на $%d", target:Nick(), amount)
    if IsValid(ply) then 
        ply:PrintMessage(HUD_PRINTCONSOLE, successMsg)
    else 
        print(successMsg)
    end
    
    DarkRP.notify(target, 0, 4, string.format("Администратор установил ваш баланс на $%d", amount))
end

concommand.Add("zgrad_setmoney", SetMoney)

print("[Z-Grad RP] Admin Commands Loaded")
