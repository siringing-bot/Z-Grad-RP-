--[[---------------------------------------------------------------------------
    Zgrad — Генератор (Клиент)
    3D2D HUD: Топливо / Статус
    Мини-игра: 5 кнопок из [q,w,e,r,a,s,d,f]
---------------------------------------------------------------------------]]
include("shared.lua")

local MAX_FUEL = 5.0

-- =============================================
-- Client Think (Sound)
-- =============================================
function ENT:Think()
    if self:GetIsOn() then
        if not self.SoundObj then
            self.SoundObj = CreateSound(self, "ambient/machines/diesel_engine_idle1.wav")
            self.SoundObj:PlayEx(0.6, 100)
        end
    else
        if self.SoundObj then
            self.SoundObj:Stop()
            self.SoundObj = nil
        end
    end
end

function ENT:OnRemove()
    if self.SoundObj then
        self.SoundObj:Stop()
        self.SoundObj = nil
    end
end

-- =============================================
-- 3D2D HUD
-- =============================================
function ENT:Draw()
    self:DrawModel()

    local dist = LocalPlayer():GetPos():Distance(self:GetPos())
    if dist > 400 then return end

    local pos = self:GetPos() + Vector(0, 0, 90)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    local isOn    = self:GetIsOn()
    local fuel    = self:GetFuel()
    local powered = self:GetPoweredPrinters()

    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.07)
        draw.RoundedBox(6, -120, -50, 240, 110, Color(10, 10, 10, 200))
        draw.RoundedBox(6, -118, -48, 236, 106, Color(25, 25, 40, 220))

        -- Заголовок
        draw.SimpleTextOutlined("⚡ ГЕНЕРАТОР", "DermaDefaultBold", 0, -38, Color(220, 180, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

        -- Статус
        local statusText  = isOn and "● РАБОТАЕТ" or "● ВЫКЛЮЧЕН"
        local statusColor = isOn and Color(50, 255, 100) or Color(200, 60, 60)
        draw.SimpleTextOutlined(statusText, "DermaDefault", 0, -18, statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

        -- Разделитель
        surface.SetDrawColor(80, 80, 100, 180)
        surface.DrawRect(-108, -4, 216, 1)

        -- Топливо
        local fuelPercent = fuel / MAX_FUEL
        local fuelColor
        if fuelPercent > 0.5 then
            fuelColor = Color(50, 220, 80)
        elseif fuelPercent > 0.2 then
            fuelColor = Color(255, 180, 50)
        else
            fuelColor = Color(255, 60, 60)
        end

        draw.SimpleTextOutlined("⛽ Топливо: " .. string.format("%.1f", fuel) .. "/" .. MAX_FUEL .. "Л", "DermaDefault", 0, 8, fuelColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

        -- Полоска топлива
        local barW = 200
        local barH = 10
        local barX = -100
        local barY = 28
        draw.RoundedBox(3, barX, barY, barW, barH, Color(40, 40, 40, 200))
        draw.RoundedBox(3, barX, barY, math.max(0, barW * fuelPercent), barH, fuelColor)

        -- Принтеры
        draw.SimpleTextOutlined("🔌 Принтеров: " .. powered .. "/3", "DermaDefault", 0, 48, Color(150, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

    cam.End3D2D()
end

-- =============================================
-- Мини-игра
-- =============================================
local MiniGameActive = false
local MiniGameEnt    = nil

local ALLOWED_KEYS = {
    [KEY_Q] = "Q", [KEY_W] = "W", [KEY_R] = "R",
    [KEY_A] = "A", [KEY_S] = "S", [KEY_D] = "D", [KEY_F] = "F"
}
local ALL_KEYS = {KEY_Q, KEY_W, KEY_R, KEY_A, KEY_S, KEY_D, KEY_F}

local MiniGameSequence  = {}
local MiniGameCurrent   = 1
local MiniGameTotalKeys = 5
local MiniGameFlash     = nil -- текущая мигание (правильно/нет)

local function GenerateSequence()
    local seq = {}
    for i = 1, MiniGameTotalKeys do
        seq[i] = ALL_KEYS[math.random(1, #ALL_KEYS)]
    end
    return seq
end

local function StartMiniGame(ent)
    MiniGameActive   = true
    MiniGameEnt      = ent
    MiniGameSequence = GenerateSequence()
    MiniGameCurrent  = 1
    MiniGameFlash    = nil
end

local function EndMiniGame(success)
    MiniGameActive = false

    if IsValid(MiniGameEnt) then
        net.Start("ZGrad_GeneratorMiniGameResult")
            net.WriteEntity(MiniGameEnt)
            net.WriteBool(success)
        net.SendToServer()
    end
    MiniGameEnt = nil
end

-- Net — сервер просит открыть мини-игру
net.Receive("ZGrad_GeneratorMiniGame", function()
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end
    StartMiniGame(ent)
end)

-- HUD Hook — рисуем мини-игру
hook.Add("HUDPaint", "ZGrad_GeneratorMiniGame_HUD", function()
    if not MiniGameActive then return end
    if not IsValid(MiniGameEnt) then
        MiniGameActive = false
        return end

    local sw = ScrW()
    local sh = ScrH()

    -- Затемнение фона
    surface.SetDrawColor(0, 0, 0, 150)
    surface.DrawRect(0, 0, sw, sh)

    -- Панель
    local panelW = 500
    local panelH = 280
    local panelX = sw / 2 - panelW / 2
    local panelY = sh / 2 - panelH / 2

    draw.RoundedBox(12, panelX, panelY, panelW, panelH, Color(15, 15, 25, 245))
    draw.RoundedBox(12, panelX+1, panelY+1, panelW-2, panelH-2, Color(30, 30, 50, 240))
    draw.RoundedBoxEx(12, panelX, panelY, panelW, 50, Color(40, 40, 80, 255), true, true, false, false)

    -- Заголовок
    draw.SimpleTextOutlined("⚙  ЗАПУСК ГЕНЕРАТОРА", "DermaDefaultBold", sw/2, panelY + 25, Color(220, 180, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

    -- Инструкция
    draw.SimpleTextOutlined("Нажимайте клавиши по порядку!", "DermaDefault", sw/2, panelY + 68, Color(180, 180, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

    -- Прогресс
    draw.SimpleTextOutlined("Шаг " .. MiniGameCurrent .. " из " .. MiniGameTotalKeys, "DermaDefault", sw/2, panelY + 90, Color(150, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

    -- Текущая кнопка
    if MiniGameCurrent <= #MiniGameSequence then
        local currentKey   = MiniGameSequence[MiniGameCurrent]
        local currentLabel = ALLOWED_KEYS[currentKey] or "?"

        local flashColor = Color(255, 210, 50) -- Обычный цвет
        if MiniGameFlash then
            if MiniGameFlash == "ok" then
                flashColor = Color(50, 255, 100)
            elseif MiniGameFlash == "fail" then
                flashColor = Color(255, 60, 60)
            end
        end

        -- Большая кнопка
        local btnX = sw/2 - 50
        local btnY = panelY + 120
        draw.RoundedBox(10, btnX, btnY, 100, 80, Color(40, 40, 70, 220))
        draw.RoundedBox(10, btnX+2, btnY+2, 96, 76, flashColor)
        draw.SimpleTextOutlined(currentLabel, "DermaLarge", sw/2, btnY + 40, Color(15, 15, 25), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0))
    end

    -- Подсказка все кнопки
    local allKeys = "Q  W  R  A  S  D  F"
    draw.SimpleTextOutlined(allKeys, "DermaDefault", sw/2, panelY + 235, Color(100, 100, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))

    -- ESC выход
    draw.SimpleTextOutlined("[ESC] - Отмена", "DermaDefault", sw/2, panelY + 256, Color(100, 100, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0,0,0))
end)

-- Key press hook
hook.Add("PlayerButtonDown", "ZGrad_GeneratorMiniGame_Keys", function(ply, btn)
    if not IsFirstTimePredicted() then return end
    if not MiniGameActive then return end
    if ply ~= LocalPlayer() then return end

    -- ESC - отмена
    if btn == KEY_ESCAPE then
        MiniGameActive = false
        MiniGameEnt = nil
        return
    end

    if MiniGameCurrent > #MiniGameSequence then return end

    local expected = MiniGameSequence[MiniGameCurrent]
    if btn == expected then
        -- Правильно
        MiniGameFlash   = "ok"
        MiniGameCurrent = MiniGameCurrent + 1
        -- Звук рывка шнура
        surface.PlaySound("weapons/357/357_spin1.wav")

        timer.Simple(0.3, function()
            MiniGameFlash = nil
            if MiniGameCurrent > MiniGameTotalKeys then
                -- Успех!
                EndMiniGame(true)
            end
        end)
    else
        -- Неправильно
        if ALLOWED_KEYS[btn] then -- реагируем только на наши клавиши
            MiniGameFlash = "fail"
            surface.PlaySound("buttons/button8.wav")
            timer.Simple(0.4, function()
                -- Рестарт последовательности
                MiniGameFlash    = nil
                MiniGameSequence = GenerateSequence()
                MiniGameCurrent  = 1
            end)
        end
    end
end)
