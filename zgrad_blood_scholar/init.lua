AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/player/magnusson.mdl")
    self:SetHullType(HULL_HUMAN)
    self:SetHullSizeNormal()
    self:SetNPCState(NPC_STATE_IDLE)
    self:SetSolid(SOLID_BBOX)
    self:CapabilitiesAdd(CAP_ANIMATEDFACE)
    self:CapabilitiesAdd(CAP_TURN_HEAD)
    self:SetUseType(SIMPLE_USE)
    self:DropToFloor()
    self:SetMaxYawSpeed(90)

    -- Animation Fix
    self:SetAutomaticFrameAdvance(true)
    local seq = self:LookupSequence("idle_all_01")
    if seq == -1 then seq = self:LookupSequence("idle") end
    if seq ~= -1 then
        self:SetSequence(seq)
    end
end

function ENT:Think()
    self:FrameAdvance(CurTime())

    if self:GetSequence() == 0 then
        local seq = self:LookupSequence("idle_all_01")
        if seq ~= -1 then self:SetSequence(seq) end
    end

    self:NextThink(CurTime())
    return true
end

-- Use hooks for better reliability
function ENT:AcceptInput(name, activator, caller)
    if name == "Use" and IsValid(activator) and activator:IsPlayer() then
        self:HandleBloodSale(activator)
    end
end

function ENT:Use(activator, caller)
    if IsValid(activator) and activator:IsPlayer() then
        self:HandleBloodSale(activator)
    end
end

-- New: Support for thrown/dropped blood bags
function ENT:StartTouch(ent)
    if not IsValid(ent) then return end
    if ent:IsPlayer() then return end

    local class = ent:GetClass()
    local model = ent:GetModel() or ""
    
    -- Detect blood bag by class or by model (in case it's a dropped phys prop or spawned_weapon)
    if class == "weapon_bloodbag" or model:find("bloodbag.mdl") or class == "spawned_weapon" then
        self:HandleBloodSaleFromEntity(ent)
    end
end

function ENT:HandleBloodSaleFromEntity(ent)
    -- Don't process the same entity twice
    if ent.ZGrad_ProcessingSale then return end

    -- Extract level of blood
    local amount = 0
    if ent.modeValues and ent.modeValues[1] then
        amount = ent.modeValues[1]
    elseif ent.GetNetVar then
        local mv = ent:GetNetVar("modeValues")
        amount = (mv and mv[1]) or 0
    end

    -- Strict check
    if amount < 0.999 then return end

    -- Identify who to pay
    local ply = ent:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() then
        -- Fallback: try to find the person who threw it or just the nearest player
        local nearest = nil
        local minDist = 250
        for _, p in ipairs(player.GetAll()) do
            local d = p:GetPos():Distance(self:GetPos())
            if d < minDist then
                minDist = d
                nearest = p
            end
        end
        ply = nearest
    end

    if not IsValid(ply) then return end

    -- Success!
    ent.ZGrad_ProcessingSale = true
    ent:Remove()
    
    ply:addMoney(700)
    self:EmitSound("mvm/mvm_money_pickup.wav")
    DarkRP.notify(ply, 0, 4, "Вы продали брошенный пакет крови за 700$!")
end

function ENT:HandleBloodSale(ply)
    local wep = ply:GetActiveWeapon()
    
    if not IsValid(wep) or wep:GetClass() ~= "weapon_bloodbag" then
        DarkRP.notify(ply, 1, 4, "Возьмите ПОЛНЫЙ пакет крови в руки!")
        return
    end

    -- Robust way to get blood amount
    local amount = 0
    if wep.modeValues and wep.modeValues[1] then
        amount = wep.modeValues[1]
    elseif wep.GetNetVar then
        local mv = wep:GetNetVar("modeValues")
        amount = (mv and mv[1]) or 0
    end

    -- Strict fullness check (1.0 is full in weapon_bloodbag.lua)
    if amount < 0.999 then
        local percent = math.floor(amount * 100)
        DarkRP.notify(ply, 1, 4, "Этот пакет еще не полон! (" .. percent .. "%). Мне нужна ПОЛНАЯ доза.")
        return
    end

    -- Remove bag and pay
    ply:StripWeapon("weapon_bloodbag")
    ply:addMoney(700)
    
    -- Sound and notify
    self:EmitSound("mvm/mvm_money_pickup.wav")
    DarkRP.notify(ply, 0, 4, "Вы успешно сдали ПОЛНЫЙ пакет крови за 700$!")
end

-- Хук для установки КД, если игрок сдает кровь (наполняет мешок)
-- В weapon_bloodbag.lua наполнение происходит в Think: 
-- self.modeValues[1] = math.min(self.modeValues[1] + FrameTime() * ..., 1)
-- Мы можем отследить момент, когда пакет становится полным через игрока.
hook.Add("Think", "ZGrad_BloodBag_FillCheck", function()
    -- Это может быть тяжелым в глобальном Think, но для точности КД "после сдачи единицы мешка"
    -- Мы проверим активный веапон всех игроков раз в секунду
end)

-- Альтернативно, мы можем добавить КД именно в момент продажи, 
-- так как "сдача крови" в контексте данного НПС - это продажа его результата.
