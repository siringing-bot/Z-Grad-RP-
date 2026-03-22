--[[---------------------------------------------------------------------------
Z-Grad RP — Terror Act (Server)
---------------------------------------------------------------------------]]

util.AddNetworkString("ZGrad_TerrorAct_Start")
util.AddNetworkString("ZGrad_TerrorAct_Notify")

local TERROR_CD = 3600 -- 1 hour
local lastTerrorTime = -TERROR_CD

net.Receive("ZGrad_TerrorAct_Start", function(len, ply)
    if not IsValid(ply) then return end
    
    local tn = string.lower(team.GetName(ply:Team()) or "")
    local isTerror = ply:Team() == (TEAM_TERROR or -1) or ply:Team() == (TEAM_TERRORIST or -1) or string.find(tn, "террор") or string.find(tn, "terror")
    
    if not isTerror then return end

    if CurTime() < lastTerrorTime + TERROR_CD then
        DarkRP.notify(ply, 1, 4, "Теракт можно начать только раз в час!")
        return
    end

    local location = net.ReadString()
    if not location or location == "" then return end

    lastTerrorTime = CurTime()
    SetGlobalFloat("ZGrad_TerrorCD", lastTerrorTime + TERROR_CD)
    
    -- Send notification to all players
    net.Start("ZGrad_TerrorAct_Notify")
        net.WriteString(location)
        net.WriteEntity(ply)
    net.Broadcast()
end)

print("[Z-Grad RP] Terror Act Module Loaded")
