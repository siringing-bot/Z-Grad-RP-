--[[---------------------------------------------------------------------------
Z-Grad RP — Crates System (Shared)
---------------------------------------------------------------------------]]

ZGrad_Crates = ZGrad_Crates or {}

-- Настройки ящиков
ZGrad_Crates.Types = {
    ["zgrad_crate_small"] = {
        name = "Маленький ящик",
        model = "models/props_junk/cardboard_box001a.mdl",
        capacity = 5,
        price = 5000,
    },
    ["zgrad_crate_large"] = {
        name = "Большой ящик",
        model = "models/props_junk/wood_crate001a.mdl",
        capacity = 10,
        price = 9000,
    }
}

-- Сетевые сообщения
if SERVER then
    util.AddNetworkString("ZGrad_Crates_OpenMenu")
    util.AddNetworkString("ZGrad_Crates_TakeItem")
    util.AddNetworkString("ZGrad_Crates_SyncItems")
    util.AddNetworkString("ZGrad_Crates_ToggleLock")
end

-- Вспомогательная функция для проверки замка
function ZGrad_Crates.IsLocked(ent)
    if not IsValid(ent) then return false end
    
    if ent.isKeysLocked then return ent:isKeysLocked() end
    if ent.getDoorData then
        local data = ent:getDoorData()
        return data and data.locked or false
    end
    
    return ent:GetNWBool("locked", false) -- Fallback
end

print("[Z-Grad RP] Crates System (Shared) Loaded")
