--[[---------------------------------------------------------------------------
Z-Grad RP — Radio Server Logic
---------------------------------------------------------------------------]]

util.AddNetworkString("ZGrad_Radio_OpenServerMenu")
util.AddNetworkString("ZGrad_Radio_UpdateServer")
util.AddNetworkString("ZGrad_Radio_OpenRadioMenu")
util.AddNetworkString("ZGrad_Radio_TuneRadio")

-- Глобальная таблица активных волн
-- Index: ServerEntityIndex
-- Value: { name = string, price = number, owner = Player, mic = Entity }
ZGrad_Radio.Waves = ZGrad_Radio.Waves or {}

-- Синхронизация при начале вещания
local function SyncWaves(ply)
    -- В будущем можно добавить сетевую синхронизацию если нужно для UI
end

-- Обработка голоса (Интеграция с Z-City/Homigrad)
hook.Add("HG_PlayerCanHearPlayersVoice", "ZGrad_Radio_VoiceBroadcasting", function(listener, talker)
    if not IsValid(talker) or not IsValid(listener) then return end

    -- Проходим по всем активным серверам радио
    for serverIdx, wave in pairs(ZGrad_Radio.Waves) do
        local server = ents.GetByIndex(serverIdx)
        if not IsValid(server) then continue end

        local mic = wave.mic
        if not IsValid(mic) or not mic:GetIsOn() then continue end
        
        -- Проверяем, находится ли говорящий рядом с микрофоном (500 юнитов)
        if talker:GetPos():DistToSqr(mic:GetPos()) <= (500 * 500) then
            -- Проверяем, стоит ли слушатель рядом с включенным радио этой волны
            for _, radio in ipairs(ents.FindByClass("zgrad_radio")) do
                if radio:GetIsOn() and radio:GetStationIndex() == serverIdx then
                    -- Если слушатель рядом с этим радио (500 юнитов)
                    if listener:GetPos():DistToSqr(radio:GetPos()) <= (500 * 500) then
                        -- Возвращаем true (слышит) и true (3D звук)
                        -- Позиционирование будет переопределено на клиенте для эффекта "из радио"
                        return true, true
                    end
                end
            end
        end
    end
end)

-- Отслеживание активных вещующих (для клиентского 3D позиционирования)
hook.Add("Think", "ZGrad_Radio_BroadcasterTracker", function()
    if (ZGrad_Radio.NextBroadcasterCheck or 0) > CurTime() then return end
    ZGrad_Radio.NextBroadcasterCheck = CurTime() + 0.5

    local activeBroadcasters = {} -- [Player] = waveIdx

    for serverIdx, wave in pairs(ZGrad_Radio.Waves) do
        local mic = wave.mic
        if IsValid(mic) and mic:GetIsOn() then
            for _, ply in ipairs(player.GetAll()) do
                if ply:GetPos():DistToSqr(mic:GetPos()) <= (500 * 500) then
                    activeBroadcasters[ply] = serverIdx
                end
            end
        end
    end

    for _, ply in ipairs(player.GetAll()) do
        local currentWave = activeBroadcasters[ply] or 0
        if ply:GetNWInt("ZGrad_ActiveWave", 0) ~= currentWave then
            ply:SetNWInt("ZGrad_ActiveWave", currentWave)
        end
    end
end)

-- Обновление данных сервера
net.Receive("ZGrad_Radio_UpdateServer", function(len, ply)
    local server = net.ReadEntity()
    local name = net.ReadString()
    local price = math.Clamp(net.ReadInt(32), 0, 10000)

    if not IsValid(server) or server:GetClass() ~= "zgrad_radio_server" then return end
    
    local owner = server:Getowning_ent()
    local isOwner = (IsValid(owner) and owner == ply) or (server.SID == ply:SteamID())
    
    if not isOwner and not ply:IsSuperAdmin() then
        DarkRP.notify(ply, 1, 4, "У вас нет прав для изменения этого сервера!")
        return 
    end

    local idx = server:EntIndex()
    ZGrad_Radio.Waves[idx] = ZGrad_Radio.Waves[idx] or {}
    ZGrad_Radio.Waves[idx].name = name
    ZGrad_Radio.Waves[idx].price = price
    
    server:SetWaveName(name)
    server:SetWavePrice(price)

    DarkRP.notify(ply, 0, 4, "Настройки радиостанции '" .. name .. "' сохранены!")
end)

-- Переключение станции на радио
net.Receive("ZGrad_Radio_TuneRadio", function(len, ply)
    local radio = net.ReadEntity()
    local serverIdx = net.ReadInt(32) -- 0 для выключения

    if not IsValid(radio) or radio:GetClass() ~= "zgrad_radio" then return end
    
    if serverIdx == 0 then
        radio:SetIsOn(false)
        radio:SetStationIndex(0)
        DarkRP.notify(ply, 0, 3, "Радио выключено.")
        return
    end

    local server = ents.GetByIndex(serverIdx)
    if not IsValid(server) or server:GetClass() ~= "zgrad_radio_server" then
        DarkRP.notify(ply, 1, 4, "Эта станция больше не доступна!")
        return
    end

    local wave = ZGrad_Radio.Waves[serverIdx]
    if not wave then return end

    -- Проверка оплаты (каждый раз при подключении)
    if wave.price > 0 then
        if not ply:canAfford(wave.price) then
            DarkRP.notify(ply, 1, 4, "У вас недостаточно денег для прослушивания этой станции (" .. DarkRP.formatMoney(wave.price) .. ")")
            return
        end

        ply:addMoney(-wave.price)
        
        -- Поиск владельца для выплаты
        local receiver = server:Getowning_ent()
        if not IsValid(receiver) and server.SID then
            for _, v in ipairs(player.GetAll()) do
                if v:SteamID() == server.SID then
                    receiver = v
                    break
                end
            end
        end

        if IsValid(receiver) then
            receiver:addMoney(wave.price)
            DarkRP.notify(receiver, 0, 4, "Игрок " .. ply:Nick() .. " оплатил прослушивание вашей волны: +$" .. wave.price)
        end
        
        DarkRP.notify(ply, 0, 4, "Вы оплатили прослушивание: " .. wave.name)
    end

    radio:SetIsOn(true)
    radio:SetStationIndex(serverIdx)
    radio:EmitSound("buttons/lightswitch2.wav", 60, 100)
    DarkRP.notify(ply, 0, 4, "Настроено на: " .. wave.name)
end)

print("[Z-Grad RP] Radio Server Module Loaded")


print("[Z-Grad RP] Radio Server Module Loaded")
