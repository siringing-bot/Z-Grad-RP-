AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Конфигурация паков снаряжения
-- Редактируй содержимое паков здесь!
local EquipmentPacks = {
    -- Пак для Полицейских
    [TEAM_POLICE] = {
        items = {
            "weapon_glock17", 
            "weapon_hg_tonfa",
            "ent_armor_vest2", 
            "weapon_medkit_sh",
            "weapon_handcuffs",
            "weapon_handcuffs_key",
            "weapon_taser",
            "ent_ammo_9x19mmparabellum",
        },
        ammo = {
            ["ammo_9x19mmparabellum"] = 60, 
        },
    },

    -- Пак для ФБР
    [TEAM_FBI] = {
        items = {
            "weapon_m4a1",      
            "weapon_glock17",
            "weapon_hg_tonfa",
            "weapon_medkit_sh",
            "ent_armor_vest2",
            "ent_armor_helmet3",
            "weapon_handcuffs",
            "weapon_handcuffs_key",
            "weapon_taser",
            "weapon_ram",
            "ent_ammo_9x19mmparabellum",
            "ent_ammo_5.56x45mm",
        },
        ammo = {
            ["ammo_9x19mmparabellum"] = 60,
            ["ammo_5.56x45mm"] = 90, 
        },
    }
}

function ENT:Initialize()
    self:SetModel("models/player/kleiner.mdl") -- Скин Кляйнера
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

function ENT:AcceptInput(name, activator, caller)
    if name == "Use" and IsValid(caller) and caller:IsPlayer() then
        self:GiveEquipment(caller)
    end
end

function ENT:GiveEquipment(ply)
    local team = ply:Team()

    -- 3. Только Полицейские и ФБР могут использовать
    if not EquipmentPacks[team] then
        DarkRP.notify(ply, 1, 4, "Этот NPC обслуживает только Полицию и ФБР!")
        return
    end

    -- 1. Проверка: брал ли уже снаряжение в этой жизни?
    if ply.HasTakenZGradEquipment then
        DarkRP.notify(ply, 1, 4, "Вы уже получили снаряжение! Приходите после... кхм... следующего выхода на смену (смерти).")
        return
    end

    -- Выдача снаряжения
    local pack = EquipmentPacks[team]

    -- Выдаем предметы
    if pack.items then
        for _, itemClass in ipairs(pack.items) do
            ply:Give(itemClass)
        end
    end

    -- Выдаем патроны
    if pack.ammo then
        for ammoType, amount in pairs(pack.ammo) do
            ply:GiveAmmo(amount, ammoType)
        end
    end

    -- Выдаем здоровье и броню
    if pack.health then
        ply:SetHealth(math.max(ply:Health(), pack.health))
    end
    if pack.armor then
        ply:SetArmor(math.max(ply:Armor(), pack.armor))
    end

    -- Помечаем, что снаряжение получено
    ply.HasTakenZGradEquipment = true
    DarkRP.notify(ply, 0, 4, "Снаряжение выдано! Удачи на службе.")
    
    -- Звук для атмосферы
    self:EmitSound("items/ammo_pickup.wav")
end

-- Сброс ограничения при смерти игрока
hook.Add("PlayerDeath", "ZGrad_ResetEquipmentLimit", function(ply)
    ply.HasTakenZGradEquipment = false
end)

-- Сброс при смене профессии (так как это тоже новая 'жизнь' в RP плане)
hook.Add("OnPlayerChangedTeam", "ZGrad_ResetEquipmentLimit_Job", function(ply)
    ply.HasTakenZGradEquipment = false
end)
