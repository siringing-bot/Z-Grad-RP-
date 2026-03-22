--[[---------------------------------------------------------------------------
Z-Grad RP — Coup Act (Client)
---------------------------------------------------------------------------]]
if SERVER then return end

surface.CreateFont("ZGrad_CoupTitle", { font = "Roboto", size = 40, weight = 800 })
surface.CreateFont("ZGrad_CoupSub", { font = "Roboto", size = 26, weight = 600 })

local activeCoup = nil
local activeResult = nil

net.Receive("ZGrad_Coup_Notify", function()
    local ply = net.ReadEntity()
    local reason = net.ReadString()
    
    activeResult = nil
    if IsValid(ply) then
        activeCoup = {
            terrorist = ply,
            reason = reason,
            time = UnPredictedCurTime() + 10 -- Показываем HUD 10 секунд
        }
        
        surface.PlaySound("ambient/alarms/klaxon1.wav")
    else
        activeCoup = nil
    end
end)

net.Receive("ZGrad_Coup_Result", function()
    local winnerType = net.ReadString() -- "mafia" or "government"
    local message = net.ReadString()
    
    activeCoup = nil
    activeResult = {
        winner = winnerType,
        msg = message,
        time = UnPredictedCurTime() + 10
    }
    
    surface.PlaySound("ambient/levels/canals/headcrab_canister_open1.wav")
end)

hook.Add("HUDPaint", "ZGrad_CoupHUD", function()
    local w, h = ScrW(), ScrH()

    if activeCoup and activeCoup.time > UnPredictedCurTime() then
        -- Пульсирующий эффект как у теракта
        local alpha = math.abs(math.sin(CurTime() * 4)) * 100 + 155
        
        draw.RoundedBox(0, 0, h/4, w, 120, Color(150, 80, 20, alpha * 0.8)) -- Чуть оранжевее
        draw.RoundedBox(0, 0, h/4 - 4, w, 4, Color(255, 140, 50, alpha))
        draw.RoundedBox(0, 0, h/4 + 120, w, 4, Color(255, 140, 50, alpha))
        
        draw.SimpleText("ВНИМАНИЕ! ГОС ПЕРЕВОРОТ!", "ZGrad_CoupTitle", w/2, h/4 + 35, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Организатор: " .. (IsValid(activeCoup.terrorist) and activeCoup.terrorist:Nick() or "Неизвестный") .. " | Причина: " .. activeCoup.reason, "ZGrad_CoupSub", w/2, h/4 + 80, Color(255, 200, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif activeResult and activeResult.time > UnPredictedCurTime() then
        local isMafia = activeResult.winner == "mafia"
        local bgCol = isMafia and Color(50, 50, 50, 200) or Color(20, 150, 20, 200)
        local borderCol = isMafia and Color(150, 150, 150, 255) or Color(100, 255, 100, 255)

        draw.RoundedBox(0, 0, h/4, w, 120, bgCol)
        draw.RoundedBox(0, 0, h/4 - 4, w, 4, borderCol)
        draw.RoundedBox(0, 0, h/4 + 120, w, 4, borderCol)

        draw.SimpleText("ГОС ПЕРЕВОРОТ ОКОНЧЕН!", "ZGrad_CoupTitle", w/2, h/4 + 35, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(activeResult.msg, "ZGrad_CoupSub", w/2, h/4 + 80, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        activeCoup = nil
        activeResult = nil
    end
end)

print("[Z-Grad RP] Coup HUD Loaded")
