--[[---------------------------------------------------------------------------
Z-Grad RP — Inventory System (Shared)
---------------------------------------------------------------------------]]

ZGrad_Inventory = ZGrad_Inventory or {}
ZGrad_Inventory.MaxSlots = 3

if SERVER then
    util.AddNetworkString("ZGrad_Inventory_Sync")
    util.AddNetworkString("ZGrad_Inventory_Drop")
end

-- Вспомогательная функция для получения инвентаря игрока
function ZGrad_Inventory.GetPlayerInv(ply)
    ply.ZGrad_Inventory = ply.ZGrad_Inventory or {}
    return ply.ZGrad_Inventory
end
