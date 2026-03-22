--[[---------------------------------------------------------------------------
Z-Grad RP — Radio Client Logic (UI)
---------------------------------------------------------------------------]]

local C = {
    bg          = Color(16, 16, 22, 250),
    sidebar     = Color(22, 22, 30, 255),
    accent      = Color(0, 180, 255, 255),
    text        = Color(220, 220, 235, 255),
    textDim     = Color(130, 130, 155, 255),
    btn         = Color(28, 28, 40, 255),
    btnHover    = Color(35, 35, 50, 255),
}

-- UI для Сервера
net.Receive("ZGrad_Radio_OpenServerMenu", function()
    local server = net.ReadEntity()
    local name = server:GetWaveName() or ""
    local price = server:GetWavePrice() or 0
    local isMicConnected = server:GetIsMicConnected()

    local Frame = vgui.Create("DFrame")
    Frame:SetSize(350, 400)
    Frame:Center()
    Frame:SetTitle("Настройка Сервера Радио")
    Frame:MakePopup()
    Frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.bg)
    end

    local lbl = vgui.Create("DLabel", Frame)
    lbl:SetText("Название волны:")
    lbl:Dock(TOP)
    lbl:DockMargin(20, 10, 20, 0)

    local txtName = vgui.Create("DTextEntry", Frame)
    txtName:Dock(TOP)
    txtName:DockMargin(20, 5, 20, 10)
    txtName:SetText(name)

    local lbl2 = vgui.Create("DLabel", Frame)
    lbl2:SetText("Цена за вход ($):")
    lbl2:Dock(TOP)
    lbl2:DockMargin(20, 10, 20, 0)

    local txtPrice = vgui.Create("DTextEntry", Frame)
    txtPrice:Dock(TOP)
    txtPrice:DockMargin(20, 5, 20, 10)
    txtPrice:SetNumeric(true)
    txtPrice:SetText(tostring(price))

    local status = vgui.Create("DLabel", Frame)
    status:Dock(TOP)
    status:DockMargin(20, 20, 20, 10)
    status:SetFont("DermaDefaultBold")
    if isMicConnected then
        status:SetText("● Микрофон подключен")
        status:SetTextColor(Color(0, 255, 0))
    else
        status:SetText("○ Микрофон не найден (в радиусе 10м)")
        status:SetTextColor(Color(255, 100, 100))
    end

    local btnSave = vgui.Create("DButton", Frame)
    btnSave:SetText("СОХРАНИТЬ")
    btnSave:Dock(BOTTOM)
    btnSave:DockMargin(20, 10, 20, 20)
    btnSave:SetTall(40)
    btnSave.DoClick = function()
        local priceVal = tonumber(txtPrice:GetValue()) or 0
        net.Start("ZGrad_Radio_UpdateServer")
            net.WriteEntity(server)
            net.WriteString(txtName:GetValue())
            net.WriteInt(priceVal, 32)
        net.SendToServer()
        Frame:Close()
    end
end)

-- UI для Радио
net.Receive("ZGrad_Radio_OpenRadioMenu", function()
    local radio = net.ReadEntity()
    local activeWaves = net.ReadTable() -- Передадим список активных волн через net

    local Frame = vgui.Create("DFrame")
    Frame:SetSize(300, 450)
    Frame:Center()
    Frame:SetTitle("Выбор Радиостанции")
    Frame:MakePopup()
    Frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.bg)
    end

    local scroll = vgui.Create("DScrollPanel", Frame)
    scroll:Dock(FILL)

    -- Кнопка Выключить
    local btnOff = scroll:Add("DButton")
    btnOff:SetText("ВЫКЛЮЧИТЬ")
    btnOff:Dock(TOP)
    btnOff:DockMargin(10, 10, 10, 5)
    btnOff:SetTall(40)
    btnOff.DoClick = function()
        net.Start("ZGrad_Radio_TuneRadio")
            net.WriteEntity(radio)
            net.WriteInt(0, 32)
        net.SendToServer()
        Frame:Close()
    end

    for idx, wave in pairs(activeWaves) do
        local btn = scroll:Add("DButton")
        local priceStr = wave.price > 0 and (" [$" .. wave.price .. "]") or " [Бесплатно]"
        btn:SetText(wave.name .. priceStr)
        btn:Dock(TOP)
        btn:DockMargin(10, 5, 10, 5)
        btn:SetTall(45)
        btn.DoClick = function()
            net.Start("ZGrad_Radio_TuneRadio")
                net.WriteEntity(radio)
                net.WriteInt(idx, 32)
            net.SendToServer()
            Frame:Close()
        end
    end
end)

-- 3D Позиционирование звука радио
-- Используем zzz_ в названии, чтобы наш хук гарантированно шел после Z-City и перебивал его сбросы громкости
hook.Add("Think", "zzz_ZGrad_Radio_3DVoice", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    for _, ply in ipairs(player.GetAll()) do
        if ply == lp then continue end
        
        local waveIdx = ply:GetNWInt("ZGrad_ActiveWave", 0)
        if waveIdx > 0 then
            -- Игрок вещает на этой волне. Найдем ближайшее к нам радио с этой волной.
            local nearestRadio = nil
            local minDist = 1000 * 1000 -- Макс. дистанция "слышимости" 3D
            
            for _, radio in ipairs(ents.FindByClass("zgrad_radio")) do
                if radio:GetIsOn() and radio:GetStationIndex() == waveIdx then
                    local dist = lp:GetPos():DistToSqr(radio:GetPos())
                    if dist < minDist then
                        minDist = dist
                        nearestRadio = radio
                    end
                end
            end
            
            if IsValid(nearestRadio) then
                -- Перенаправляем голос игрока в позицию радио
                ply:SetVoice3D(true)
                ply:SetVoicePosition(nearestRadio:GetPos())
                
                -- Рассчитываем громкость в зависимости от расстояния К РАДИО
                local dist = lp:EyePos():Distance(nearestRadio:GetPos())
                
                -- Логика затухания: 
                -- До 100 юнитов - 100% громкость
                -- От 100 до 800 - плавное затухание до 0
                local vol = 1
                if dist > 100 then
                    vol = math.Clamp(1 - ((dist - 100) / 700), 0, 1)
                end
                
                -- Дополнительно проверяем "слышимость" радио (прозрачность стен)
                -- Если между нами и радио стена - звук тише на 40%
                local tr = util.TraceLine({
                    start = lp:EyePos(),
                    endpos = nearestRadio:GetPos() + Vector(0,0,10),
                    mask = MASK_SOLID_BRUSHONLY
                })
                if tr.Hit then vol = vol * 0.6 end

                -- Принудительно ставим громкость каждый кадр, чтобы Z-City не сбрасывал её
                ply:SetVoiceVolumeScale(vol)
            end
        end
    end
end)



