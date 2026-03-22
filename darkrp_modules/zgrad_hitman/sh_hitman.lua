--[[---------------------------------------------------------------------------
Z-Grad RP — Hitman Module (Shared)
---------------------------------------------------------------------------]]

if SERVER then
    util.AddNetworkString("ZGrad_HitOrder")
    util.AddNetworkString("ZGrad_HitUpdate")
end

ZGrad_Hitman = ZGrad_Hitman or {}
ZGrad_Hitman.ActiveHits = ZGrad_Hitman.ActiveHits or {}
ZGrad_Hitman.MinPrice = 2000
ZGrad_Hitman.NPCModel = "models/player/gman_high.mdl"

-- Helper to check if someone is a hitman
function ZGrad_Hitman.IsHitman(ply)
    if not IsValid(ply) then return false end
    return ply:Team() == TEAM_KILLER
end
