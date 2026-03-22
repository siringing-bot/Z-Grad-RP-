--[[---------------------------------------------------------------------------
    Zgrad — Манипринтер (Сервер)
    - Требует: Бумага (Paper), Чернила (Ink), Энергия (HasPower)
    - 1 цикл: 20 сек, -1 бумага, -2 чернила, +100$
    - Макс: 20 бумаги, 40 чернил
    - Включается/выключается нажатием E (меню)
    - Деньги снимаются через меню (нажать E -> Снять деньги)
    - Бумага/Чернила загружаются касанием entity
---------------------------------------------------------------------------]]
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- =============================================
-- Constants
-- =============================================
local MAX_PAPER     = 20
local MAX_INK       = 40
local PRINT_TIME    = 20    -- секунд на один цикл
local PRINT_MONEY   = 100   -- долларов за цикл
local PAPER_COST    = 1     -- бумага за цикл
local INK_COST      = 2     -- чернила за цикл

-- =============================================
-- Initialize
-- =============================================
function ENT:Initialize()
    self:SetModel("models/props_c17/consolebox01a.mdl")
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
    self:SetPaper(0)
    self:SetInk(0)
    self:SetHasPower(false)
    self:SetMoney(0)

    self.PrintTimer = nil
end

-- =============================================
-- Think — проверяем энергию и статус
-- =============================================
function ENT:Think()
    -- Проверяем, пришла ли энергия от ближайшего генератора
    local hasPower = false
    for _, gen in ipairs(ents.FindInSphere(self:GetPos(), 500)) do -- 500 юнитов ≈ 10 метров
        if IsValid(gen) and gen:GetClass() == "zgrad_generator" and gen:GetIsOn() then
            hasPower = true
            break
        end
    end
    self:SetHasPower(hasPower)

    -- Если включён и есть условия — запускаем цикл печати
    if self:GetIsOn() then
        if hasPower and self:GetPaper() >= PAPER_COST and self:GetInk() >= INK_COST then
            if not self.PrintTimerRunning then
                self:StartPrintCycle()
            end
        else
            -- Условия не выполнены — останавливаем
            if self.PrintTimerRunning then
                self:StopPrintCycle()
                if not hasPower then
                    self:MafiaBroadcast("Манипринтер: нет энергии!")
                elseif self:GetPaper() < PAPER_COST then
                    self:MafiaBroadcast("Манипринтер: кончилась бумага!")
                elseif self:GetInk() < INK_COST then
                    self:MafiaBroadcast("Манипринтер: кончились чернила!")
                end
            end
        end
    else
        -- Выключен — стопаем
        if self.PrintTimerRunning then
            self:StopPrintCycle()
        end
    end

    self:NextThink(CurTime() + 1)
    return true
end

-- =============================================
-- Print Cycle
-- =============================================
function ENT:StartPrintCycle()
    if self.PrintTimerRunning then return end
    self.PrintTimerRunning = true
    
    if not self.SoundObj then
        self.SoundObj = CreateSound(self, "ambient/levels/labs/equipment_printer_loop1.wav")
    end
    self.SoundObj:PlayEx(0.8, 100)

    local timerName = "ManiprintCycle_" .. self:EntIndex()
    local cycleTime = self:GetHasUpgradeSpeed() and (PRINT_TIME / 2) or PRINT_TIME

    timer.Create(timerName, cycleTime, 0, function()
        if not IsValid(self) then
            timer.Remove(timerName)
            return
        end

        -- Повторно проверяем условия в момент печати
        local hasPower = self:GetHasPower()
        local paper = self:GetPaper()
        local ink   = self:GetInk()

        if not self:GetIsOn() or not hasPower or paper < PAPER_COST or ink < INK_COST then
            self:StopPrintCycle()
            return
        end

        -- Расходуем ресурсы
        self:SetPaper(paper - PAPER_COST)
        self:SetInk(ink - INK_COST)
        
        local moneyToAdd = PRINT_MONEY
        if self:GetHasUpgradeBoost() then moneyToAdd = moneyToAdd * 2 end
        
        self:SetMoney(self:GetMoney() + moneyToAdd)

        -- Эффект
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos() + Vector(0,0,20))
        effectdata:SetMagnitude(1)
        effectdata:SetScale(1)
        util.Effect("Sparks", effectdata)
    end)
end

function ENT:StopPrintCycle()
    self.PrintTimerRunning = false
    timer.Remove("ManiprintCycle_" .. self:EntIndex())
    
    if self.SoundObj then
        self.SoundObj:Stop()
    end
end

-- =============================================
-- Helper: уведомить всех Мафию
-- =============================================
function ENT:MafiaBroadcast(msg)
    local owner = self:Getowning_ent()
    if IsValid(owner) and owner:IsPlayer() then
        DarkRP.notify(owner, 1, 5, msg)
    end
end

-- =============================================
-- Use — открываем меню (через net)
-- =============================================
function ENT:Use(activator, caller)
    if not IsValid(caller) or not caller:IsPlayer() then return end
    -- Check cooldown to avoid spam
    if self.LastUse and CurTime() - self.LastUse < 1 then return end
    self.LastUse = CurTime()

    net.Start("ZGrad_ManiprintMenu")
        net.WriteEntity(self)
        net.WriteBool(self:GetIsOn())
        net.WriteInt(self:GetMoney(), 32)
    net.Send(caller)
end

-- =============================================
-- Net receivers
-- =============================================
util.AddNetworkString("ZGrad_ManiprintMenu")
util.AddNetworkString("ZGrad_ManiprintAction")

net.Receive("ZGrad_ManiprintAction", function(len, ply)
    local ent    = net.ReadEntity()
    local action = net.ReadString()

    if not IsValid(ent) or ent:GetClass() ~= "zgrad_maniprinter" then return end
    -- Убрали жесткую проверку owner, так как мафия работает сообща

    if action == "toggle" then
        local newState = not ent:GetIsOn()
        ent:SetIsOn(newState)
        if newState then
            ent:EmitSound("buttons/button14.wav", 65, 100)
            DarkRP.notify(ply, 0, 4, "Манипринтер включён!")
        else
            ent:EmitSound("buttons/button10.wav", 65, 100)
            DarkRP.notify(ply, 0, 4, "Манипринтер выключен.")
        end

    elseif action == "collect" then
        local money = ent:GetMoney()
        if money <= 0 then
            DarkRP.notify(ply, 1, 4, "Денег нет!")
            return
        end
        ply:addMoney(money)
        ent:SetMoney(0)
        ent:EmitSound("ambient/levels/canals/drip3.wav", 65, 100)
        DarkRP.notify(ply, 0, 4, "Вы сняли " .. DarkRP.formatMoney(money) .. "!")
    end
end)

-- =============================================
-- Touch — загрузка Бумаги или Чернил
-- =============================================
function ENT:Touch(hit)
    if not IsValid(hit) then return end

    if hit:GetClass() == "zgrad_paper_item" and not hit.IsUsed then
        hit.IsUsed = true
        
        local hasStorage = self:GetHasUpgradeStorage()
        local maxP       = hasStorage and (MAX_PAPER * 2) or MAX_PAPER

        local current = self:GetPaper()
        local add     = hit:GetPaperAmount()
        if current >= maxP then
            return -- полная
        end
        local newAmt = math.min(current + add, maxP)
        self:SetPaper(newAmt)
        self:EmitSound("physics/cardboard/cardboard_box_impact_soft1.wav", 65, 100)

        -- Уведомить тому, кто бросил
        local owner = hit:Getowning_ent()
        if IsValid(owner) and owner:IsPlayer() then
            DarkRP.notify(owner, 0, 4, "Бумага загружена! Бумага: " .. newAmt .. "/" .. maxP)
        end
        hit:Remove()

    elseif hit:GetClass() == "zgrad_ink_item" and not hit.IsUsed then
        hit.IsUsed = true
        
        local hasStorage = self:GetHasUpgradeStorage()
        local maxI       = hasStorage and (MAX_INK * 2) or MAX_INK

        local current = self:GetInk()
        local add     = hit:GetInkAmount()
        if current >= maxI then
            return -- полная
        end
        local newAmt = math.min(current + add, maxI)
        self:SetInk(newAmt)
        self:EmitSound("ambient/water/water_splash1.wav", 65, 100)

        local owner = hit:Getowning_ent()
        if IsValid(owner) and owner:IsPlayer() then
            DarkRP.notify(owner, 0, 4, "Чернила загружены! Чернила: " .. newAmt .. "/" .. maxI)
        end
        hit:Remove()
    
    -- УЛУЧШЕНИЯ
    elseif hit:GetClass() == "zgrad_upgrade_speed" then
        if self:GetHasUpgradeSpeed() then return end
        self:SetHasUpgradeSpeed(true)
        self:EmitSound("items/nvg_off.wav")
        hit:Remove()
        self:MafiaBroadcast("Установлено: Hyper Injector (Скорость x2)")
        -- Перезапускаем цикл если он шел
        if self.PrintTimerRunning then
            self:StopPrintCycle()
            self:StartPrintCycle()
        end
    elseif hit:GetClass() == "zgrad_upgrade_storage" then
        if self:GetHasUpgradeStorage() then return end
        self:SetHasUpgradeStorage(true)
        self:EmitSound("items/nvg_off.wav")
        hit:Remove()
        self:MafiaBroadcast("Установлено: Storage Module (Хранилище x2)")
    elseif hit:GetClass() == "zgrad_upgrade_boost" then
        if self:GetHasUpgradeBoost() then return end
        self:SetHasUpgradeBoost(true)
        self:EmitSound("items/nvg_off.wav")
        hit:Remove()
        self:MafiaBroadcast("Установлено: Production Boost (Прибыль x2)")
    end
end

-- =============================================
-- OnRemove — чистим таймеры и звуки
-- =============================================
function ENT:OnRemove()
    timer.Remove("ManiprintCycle_" .. self:EntIndex())
    if self.SoundObj then
        self.SoundObj:Stop()
    end
end
