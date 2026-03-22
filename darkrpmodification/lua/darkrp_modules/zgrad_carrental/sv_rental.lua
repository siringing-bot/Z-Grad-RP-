--[[---------------------------------------------------------------------------
Z-Grad Car Rental - Server
---------------------------------------------------------------------------]]

util.AddNetworkString("ZGrad_Rental_OpenMenu")
util.AddNetworkString("ZGrad_Rental_Request")
util.AddNetworkString("ZGrad_Rental_Sync")

local ActiveRentals = {} -- [class] = { ply = Player, endTime = time, ent = Entity }
local PlayerRentals = {} -- [ply] = class

local function SyncRentalData(ply)
    local data = {}
    for class, info in pairs(ActiveRentals) do
        data[class] = {
            endTime = info.endTime
        }
    end
    net.Start("ZGrad_Rental_Sync")
        net.WriteTable(data)
    if ply then net.Send(ply) else net.Broadcast() end
end

local function GetFreeSpawnPoint()
    for _, pos in ipairs(ZGrad_CarRental.SpawnPoints) do
        local found = false
        for _, ent in ipairs(ents.FindInSphere(pos, 150)) do
            if ent:IsVehicle() or ent:IsPlayer() then
                found = true
                break
            end
        end
        if not found then return pos end
    end
    return nil
end

local function EndRental(class)
    local info = ActiveRentals[class]
    if not info then return end

    if IsValid(info.ent) then
        info.ent:Remove()
    end

    if IsValid(info.ply) then
        PlayerRentals[info.ply] = nil
        DarkRP.notify(info.ply, 1, 6, "Срок аренды вашего транспорта " .. class .. " истек.")
    end

    ActiveRentals[class] = nil
    SyncRentalData()
end

net.Receive("ZGrad_Rental_Request", function(len, ply)
    local class = net.ReadString()
    local duration = math.Clamp(net.ReadUInt(8), 1, ZGrad_CarRental.MaxDuration)

    print("[ZGrad Rental] Request from " .. ply:Nick() .. " for " .. class .. " for " .. duration .. " mins")

    -- Checks
    if PlayerRentals[ply] then
        DarkRP.notify(ply, 1, 4, "Вы уже арендуете транспорт!")
        return
    end

    if ActiveRentals[class] then
        DarkRP.notify(ply, 1, 4, "Этот транспорт уже арендован!")
        return
    end

    local count = 0
    for _ in pairs(ActiveRentals) do count = count + 1 end
    if count >= ZGrad_CarRental.GlobalLimit then
        DarkRP.notify(ply, 1, 4, "Лимит арендованных машин в городе исчерпан (макс. 5)")
        return
    end

    local carData = nil
    for _, v in ipairs(ZGrad_CarRental.Vehicles) do
        if v.class == class then carData = v; break end
    end

    if not carData then 
        print("[ZGrad Rental] Error: carData not found for class: " .. tostring(class))
        return 
    end

    if carData.condition and not carData.condition(ply) then
        DarkRP.notify(ply, 1, 4, carData.conditionName or "У вас нет доступа к этому транспорту.")
        return
    end

    local totalCost = carData.price * duration
    if not ply:canAfford(totalCost) then
        DarkRP.notify(ply, 1, 4, "У вас недостаточно денег! Нужно: " .. DarkRP.formatMoney(totalCost))
        return
    end

    local spawnPos = GetFreeSpawnPoint()
    if not spawnPos then
        DarkRP.notify(ply, 1, 4, "Нет свободных мест для спауна! Подождите, пока кто-то уедет.")
        return
    end

    -- Process
    local vehicleList = list.Get("Vehicles")
    local vehInfo = vehicleList[class]
    local isSimfphys = false

    if not vehInfo then
        local simfphysList = list.Get("simfphys_vehicles")
        if simfphysList and simfphysList[class] then
            vehInfo = simfphysList[class]
            isSimfphys = true
            print("[ZGrad Rental] Found " .. class .. " in simfphys_vehicles")
        end
    end
    
    if not vehInfo then
        print("[ZGrad Rental] Error: class " .. class .. " not found in standard or simfphys lists!")
        
        -- Debug: print a few available classes to console to help the user find the right names
        print("[ZGrad Rental] Available standard vehicles (first 5):")
        local count = 0
        for k, _ in pairs(vehicleList) do
            print("- " .. k)
            count = count + 1
            if count >= 5 then break end
        end

        -- DarkRP.notify(ply, 1, 4, "Ошибка: класс транспорта не найден в базе сервера. Проверьте консоль.")
    end

    ply:addMoney(-totalCost)

    local ent
    if isSimfphys then
        ent = simfphys.SpawnVehicle(ply, vehInfo.Model, vehInfo.Class, vehInfo.Data)
    elseif vehInfo then
        -- Стандартная машина из списка
        ent = ents.Create(vehInfo.Class)
        if IsValid(ent) then
            ent:SetModel(vehInfo.Model)
            if vehInfo.KeyValues then
                for k, v in pairs(vehInfo.KeyValues) do
                    ent:SetKeyValue(k, v)
                end
            end
        end
    else
        -- Попытка создать напрямую (как Scripted Entity)
        print("[ZGrad Rental] Warning: " .. class .. " not in lists. Trying direct creation...")
        ent = ents.Create(class)
        if IsValid(ent) then
            -- Используем модель из конфига
            ent:SetModel(carData.model)
        end
    end

    if not IsValid(ent) then 
        print("[ZGrad Rental] Final Error: Could not create entity for " .. class)
        DarkRP.notify(ply, 1, 4, "Ошибка: не удалось создать этот транспорт.")
        return 
    end
    
    ent:SetPos(spawnPos + Vector(0, 0, 10))
    ent:SetAngles(Angle(0, 90, 0)) -- Разворачиваем боком для красоты
    ent:Spawn()
    ent:Activate()
    
    if vehInfo and vehInfo.Members then
        table.Merge(ent, vehInfo.Members)
    end

    ent:keysOwn(ply)
    ent:SetNWBool("ZGrad_IsRental", true)
    ent:SetNWString("ZGrad_RentalClass", class)
    ent.isRental = true
    ent.rentalClass = class
    ent.RentalOwner = ply

    ActiveRentals[class] = {
        ply = ply,
        endTime = CurTime() + (duration * 60),
        ent = ent
    }
    PlayerRentals[ply] = class

    SyncRentalData()
    DarkRP.notify(ply, 0, 6, "Вы арендовали " .. carData.name .. " на " .. duration .. " мин. Место: парковка.")

    timer.Create("ZGrad_Rental_" .. class, duration * 60, 1, function()
        EndRental(class)
    end)
end)

-- Handle destruction/removal
hook.Add("EntityRemoved", "ZGrad_Rental_Cleanup", function(ent)
    if ent.isRental and ent.rentalClass then
        local class = ent.rentalClass
        if ActiveRentals[class] then
            timer.Remove("ZGrad_Rental_" .. class)
            ActiveRentals[class] = nil
            if IsValid(ent.RentalOwner) then
                PlayerRentals[ent.RentalOwner] = nil
            end
            SyncRentalData()
        end
    end
end)

hook.Add("PlayerDisconnected", "ZGrad_Rental_Disconnect", function(ply)
    local class = PlayerRentals[ply]
    if class then
        EndRental(class)
    end
end)

-- Handling persistence
local NPCFile = "zgrad/carrental_npcs/" .. game.GetMap() .. ".json"

local function SaveNPCs()
    local data = {}
    for _, ent in ipairs(ents.FindByClass("zgrad_rental_npc")) do
        table.insert(data, { pos = ent:GetPos(), ang = ent:GetAngles() })
    end
    if not file.Exists("zgrad/carrental_npcs", "DATA") then file.CreateDir("zgrad/carrental_npcs") end
    file.Write(NPCFile, util.TableToJSON(data))
end

local function LoadNPCs()
    if not file.Exists(NPCFile, "DATA") then return end
    local data = util.JSONToTable(file.Read(NPCFile, "DATA"))
    for _, v in ipairs(data) do
        local ent = ents.Create("zgrad_rental_npc")
        ent:SetPos(v.pos)
        ent:SetAngles(v.ang)
        ent:Spawn()
    end
end

hook.Add("InitPostEntity", "ZGrad_Rental_LoadNPCs", function()
    timer.Simple(5, LoadNPCs)
end)

concommand.Add("zgrad_rental_spawnnpc", function(ply)
    if not ply:IsSuperAdmin() then return end
    
    local ent = ents.Create("zgrad_rental_npc")
    ent:SetPos(ply:GetPos())
    ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    ent:Spawn()
    
    SaveNPCs()
    DarkRP.notify(ply, 0, 4, "NPC Аренды заспавнен и сохранен!")
end)

concommand.Add("zgrad_rental_clearnpcs", function(ply)
    if not ply:IsSuperAdmin() then return end
    for _, ent in ipairs(ents.FindByClass("zgrad_rental_npc")) do ent:Remove() end
    SaveNPCs()
    DarkRP.notify(ply, 0, 4, "Все NPC Аренды удалены!")
end)

-- Networking for sync on join
hook.Add("PlayerInitialSpawn", "ZGrad_Rental_InitialSync", function(ply)
    SyncRentalData(ply)
end)
