--[[---------------------------------------------------------------------------
Z-Grad RP — Динамическая стоимость дверей
---------------------------------------------------------------------------]]

function ZGrad_GetDoorCost(ply, ent)
    local base = (GAMEMODE.Config and GAMEMODE.Config.doorcost) or 30
    if not IsValid(ply) then return base end
    
    local money = ply:getDarkRPVar("money") or 0
    local extra = math.floor(money / 1000) * 5
    
    return base + extra
end

print("[Z-Grad RP] Dynamic Door Cost (Shared) Loaded")
