--[[---------------------------------------------------------------------------
Z-Grad RP — Banker System (Server)
Система выдачи кредитов
---------------------------------------------------------------------------]]

util.AddNetworkString("ZGrad_Banker_Offer")
util.AddNetworkString("ZGrad_Banker_Respond")
util.AddNetworkString("ZGrad_Banker_GetDebts")

local ActiveLoans = {} -- [borrowerSteamID] = { creditor = ply, total = x, paid = y, per_tick = z, ticks = w, current_tick = v }

-- =============================================
-- Обработка предложения от банкира
-- =============================================
net.Receive("ZGrad_Banker_Offer", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_BANKER then return end

    local target = net.ReadEntity()
    local amount = net.ReadUInt(32)
    local percent = net.ReadUInt(16)
    local timeMin = net.ReadUInt(16) -- Срок в минутах

    if not IsValid(target) or not target:IsPlayer() or target == ply then
        DarkRP.notify(ply, 1, 4, "Неверный игрок!")
        return
    end

    if target:GetPos():DistToSqr(ply:GetPos()) > 60000 then
        DarkRP.notify(ply, 1, 4, "Игрок слишком далеко!")
        return
    end

    local plyMoney = ply:getDarkRPVar("money") or 0
    if plyMoney < amount then
        DarkRP.notify(ply, 1, 4, "У вас недостаточно денег для выдачи кредита!")
        return
    end

    if ActiveLoans[target:SteamID()] then
        DarkRP.notify(ply, 1, 4, "У этого игрока уже есть непогашенный кредит!")
        return
    end

    -- Отправляем предложение игроку
    net.Start("ZGrad_Banker_Offer")
        net.WriteEntity(ply)
        net.WriteUInt(amount, 32)
        net.WriteUInt(percent, 16)
        net.WriteUInt(timeMin, 16)
    net.Send(target)

    DarkRP.notify(ply, 0, 4, "Предложение отправлено игроку " .. target:Nick())
end)

-- =============================================
-- Ответ игрока на предложение
-- =============================================
net.Receive("ZGrad_Banker_Respond", function(len, ply)
    local banker = net.ReadEntity()
    local accept = net.ReadBool()
    local amount = net.ReadUInt(32)
    local percent = net.ReadUInt(16)
    local timeMin = net.ReadUInt(16)

    if not IsValid(banker) or not banker:IsPlayer() or banker:Team() ~= TEAM_BANKER then
        DarkRP.notify(ply, 1, 4, "Банкир больше не доступен.")
        return
    end

    if not accept then
        DarkRP.notify(banker, 1, 4, ply:Nick() .. " отказался от кредита.")
        return
    end

    local bankerMoney = banker:getDarkRPVar("money") or 0
    if bankerMoney < amount then
        DarkRP.notify(ply, 1, 4, "У банкира уже нет нужной суммы!")
        DarkRP.notify(banker, 1, 4, "Сделка сорвалась: недостаточно денег!")
        return
    end

    -- Одобряем кредит
    banker:addMoney(-amount)
    ply:addMoney(amount)

    -- Расчет
    local totalToReturn = amount + math.floor(amount * (percent / 100))
    local ticks = math.max(1, math.floor(timeMin / 5)) -- Кол-во списаний (каждые 5мин)
    local perTick = math.ceil(totalToReturn / ticks)

    ActiveLoans[ply:SteamID()] = {
        creditor = banker,
        creditorID = banker:SteamID(),
        total = totalToReturn,
        paid = 0,
        per_tick = perTick,
        ticks = ticks,
        current_tick = 0,
    }

    DarkRP.notify(ply, 0, 6, "Вы взяли кредит! К возврату: $" .. totalToReturn .. " ($"..perTick.." каждые 5 мин)")
    DarkRP.notify(banker, 0, 6, "Кредит выдан игроку " .. ply:Nick())

    -- Запускаем таймер списания для этого игрока
    local timerName = "ZGrad_Loan_" .. ply:SteamID()
    timer.Create(timerName, 300, ticks, function()
        if not IsValid(ply) then
            timer.Remove(timerName)
            return
        end

        local loanInfo = ActiveLoans[ply:SteamID()]
        if not loanInfo then
            timer.Remove(timerName)
            return
        end

        loanInfo.current_tick = loanInfo.current_tick + 1
        
        -- Оставшаяся сумма может быть меньше per_tick на последнем тике
        local toPay = loanInfo.per_tick
        local remaining = loanInfo.total - loanInfo.paid
        if toPay > remaining then toPay = remaining end

        -- Списываем
        if not ply:canAfford(toPay) then
            -- Ушел в минус, но спишем сколько есть (или вгоним в долг, DarkRP разрешает минусовой баланс если addMoney, 
            -- но лучше просто отнимать)
            ply:addMoney(-toPay)
            DarkRP.notify(ply, 1, 6, "Списание по кредиту: $" .. toPay .. ". Вы в долгах!")
        else
            ply:addMoney(-toPay)
            DarkRP.notify(ply, 0, 5, "Списание по кредиту: -$" .. toPay)
        end

        loanInfo.paid = loanInfo.paid + toPay

        -- Начисляем банкиру (если он онлайн)
        if IsValid(loanInfo.creditor) and loanInfo.creditor:IsPlayer() then
            loanInfo.creditor:addMoney(toPay)
            DarkRP.notify(loanInfo.creditor, 0, 5, "Поступление по кредиту от " .. ply:Nick() .. ": +$" .. toPay)
        end

        -- Если выплачено
        if loanInfo.paid >= loanInfo.total or loanInfo.current_tick >= loanInfo.ticks then
            DarkRP.notify(ply, 0, 6, "Кредит полностью погашен!")
            if IsValid(loanInfo.creditor) then
                DarkRP.notify(loanInfo.creditor, 0, 6, "Игрок " .. ply:Nick() .. " погасил свой кредит!")
            end
            ActiveLoans[ply:SteamID()] = nil
            timer.Remove(timerName)
        end
    end)
end)

-- =============================================
-- Запрос списка должников
-- =============================================
net.Receive("ZGrad_Banker_GetDebts", function(len, ply)
    if not IsValid(ply) or ply:Team() ~= TEAM_BANKER then return end

    local debts = {}
    for borrowerSID, loan in pairs(ActiveLoans) do
        if IsValid(loan.creditor) and loan.creditor == ply then
            local borrower = player.GetBySteamID(borrowerSID)
            local borrowerName = IsValid(borrower) and borrower:Nick() or (borrowerSID .. " (Оффлайн)")
            
            local timerName = "ZGrad_Loan_" .. borrowerSID
            local repsLeft = timer.RepsLeft(timerName) or 0
            local timeLeftOnTick = timer.TimeLeft(timerName) or 0
            
            local totalSecondsLeft = math.ceil(repsLeft * 300 + timeLeftOnTick)
            if repsLeft == 0 and timeLeftOnTick == 0 then totalSecondsLeft = 0 end

            table.insert(debts, {
                sid = borrowerSID,
                name = borrowerName,
                amount = loan.total - loan.paid,
                time = totalSecondsLeft
            })
        end
    end

    net.Start("ZGrad_Banker_GetDebts")
        net.WriteTable(debts)
    net.Send(ply)
end)

-- Удалить кредит если игрок ливнул (опционально, сейчас просто удаляем таймер, чтобы не крашило)
hook.Add("PlayerDisconnected", "ZGrad_Banker_Disconnect", function(ply)
    local timerName = "ZGrad_Loan_" .. ply:SteamID()
    if timer.Exists(timerName) then timer.Remove(timerName) end
    ActiveLoans[ply:SteamID()] = nil
end)

print("[Z-Grad RP] Banker System (Server) Loaded")
