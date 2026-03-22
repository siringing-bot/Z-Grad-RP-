--[[---------------------------------------------------------------------------
    Zgrad — Генератор (Сервер)
    - Потребляет 1Л бензина каждые 2 минуты
    - Радиус энергии: 500 юнитов (≈10 метров)
    - Максимум 3 манипринтера
    - Включение: мини-игра (5 кнопок, q w e r a s d f)
    - Выключение: просто E
    - Бензин загружается касанием gascan entity
---------------------------------------------------------------------------]]
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local MAX_FUEL        = 5.0   -- максимум литров
local FUEL_PER_TICK   = 1.0 / 120.0  -- литров за тик
local FUEL_TICK_TIME  = 1     -- секунд
local MAX_PRINTERS    = 3     -- максимум принтеров
local POWER_RADIUS    = 500   -- юнитов

-- =============================================
-- Initialize
-- =============================================
function ENT:Initialize()
    self:SetModel("models/props_vehicles/generatortrailer01.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:EnableMotion(true)
    end

    self:SetIsOn(false)
    self:SetFuel(0)
    self:SetPoweredPrinters(0)

    self.FuelTimerRunning = false
end

-- =============================================
-- Think
-- =============================================
function ENT:Think()
    -- Считаем сколько принтеров рядом (независимо от того включен ли)
    local count = 0
    for _, ent in ipairs(ents.FindInSphere(self:GetPos(), POWER_RADIUS)) do
        if IsValid(ent) and ent:GetClass() == "zgrad_maniprinter" then
            count = count + 1
            if count >= MAX_PRINTERS then break end
        end
    end
    self:SetPoweredPrinters(count)

    self:NextThink(CurTime() + 2)
    return true
end

-- =============================================
-- Fuel timers
-- =============================================
function ENT:StartFuelTimer()
    if self.FuelTimerRunning then return end
    self.FuelTimerRunning = true

    local name = "GeneratorFuel_" .. self:EntIndex()
    timer.Create(name, FUEL_TICK_TIME, 0, function()
        if not IsValid(self) then
            timer.Remove(name)
            return
        end
        if not self:GetIsOn() then
            self:StopFuelTimer()
            return
        end

        local fuel = self:GetFuel()
        if fuel <= 0 then
            -- Кончилось топливо
            self:TurnOff()
            local owner = self:Getowning_ent()
            if IsValid(owner) and owner:IsPlayer() then
                DarkRP.notify(owner, 1, 6, "Генератор: кончилось топливо!")
            end
            return
        end
        self:SetFuel(math.max(0, fuel - FUEL_PER_TICK))
    end)
end

function ENT:StopFuelTimer()
    self.FuelTimerRunning = false
    timer.Remove("GeneratorFuel_" .. self:EntIndex())
end

-- =============================================
-- Turn On / Off
-- =============================================
function ENT:TurnOn()
    if self:GetFuel() <= 0 then return false end
    self:SetIsOn(true)
    self:StartFuelTimer()
    return true
end

function ENT:TurnOff()
    self:SetIsOn(false)
    self:StopFuelTimer()
    self:StopLoopSound()
end

function ENT:StopLoopSound()
end

-- =============================================
-- Use — меню или выключение
-- =============================================
function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end

    if self.LastUse and CurTime() - self.LastUse < 0.5 then return end
    self.LastUse = CurTime()

    if self:GetIsOn() then
        -- Выключаем без мини-игры
        self:TurnOff()
        self:EmitSound("buttons/button10.wav", 70, 100)
        DarkRP.notify(caller, 0, 4, "Генератор выключен.")
    else
        -- Запускаем мини-игру на клиенте
        if self:GetFuel() <= 0 then
            DarkRP.notify(caller, 1, 5, "Нет топлива! Залейте бензин.")
            return
        end
        net.Start("ZGrad_GeneratorMiniGame")
            net.WriteEntity(self)
        net.Send(caller)
    end
end

-- =============================================
-- Net — результат мини-игры
-- =============================================
util.AddNetworkString("ZGrad_GeneratorMiniGame")
util.AddNetworkString("ZGrad_GeneratorMiniGameResult")

net.Receive("ZGrad_GeneratorMiniGameResult", function(len, ply)
    local ent     = net.ReadEntity()
    local success = net.ReadBool()

    if not IsValid(ent) or ent:GetClass() ~= "zgrad_generator" then return end

    -- Убрали проверку владельца, чтобы генератор мог завести любой из мафии
    -- или если CPPI не успел назначить овнера

    if success then
        if ent:TurnOn() then
            DarkRP.notify(ply, 0, 5, "Генератор запущен!")
        else
            DarkRP.notify(ply, 1, 5, "Нет топлива!")
        end
    else
        ent:EmitSound("buttons/button8.wav", 70, 100)
        DarkRP.notify(ply, 1, 5, "Генератор не завёлся! Попробуйте ещё раз.")
    end
end)

-- =============================================
-- Touch — загрузка бензина (gascan)
-- =============================================
function ENT:Touch(hit)
    if not IsValid(hit) then return end

    if hit:GetClass() == "zgrad_gascan" and not hit.IsUsed then
        hit.IsUsed = true
        
        local current = self:GetFuel()
        if current >= MAX_FUEL then return end

        local add    = hit.GetFuelAmount and hit:GetFuelAmount() or 1
        local newAmt = math.min(current + add, MAX_FUEL)
        self:SetFuel(math.Round(newAmt, 2))
        self:EmitSound("ambient/water/water_splash1.wav", 65, 100)

        local owner = hit:Getowning_ent()
        if IsValid(owner) and owner:IsPlayer() then
            DarkRP.notify(owner, 0, 4, "Бензин залит! Топливо: " .. self:GetFuel() .. "/" .. MAX_FUEL .. "Л")
        end
        hit:Remove()
    end
end

-- =============================================
-- OnRemove
-- =============================================
function ENT:OnRemove()
    self:StopFuelTimer()
    self:StopLoopSound()
end
