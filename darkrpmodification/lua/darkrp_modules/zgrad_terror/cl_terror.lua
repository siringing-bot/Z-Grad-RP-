--[[---------------------------------------------------------------------------
Z-Grad RP — Terror Act (Client)
---------------------------------------------------------------------------]]

surface.CreateFont("ZGrad_TerrorTitle", { font = "Roboto", size = 40, weight = 800 })
surface.CreateFont("ZGrad_TerrorSub", { font = "Roboto", size = 26, weight = 600 })

local activeTerror = nil

net.Receive("ZGrad_TerrorAct_Notify", function()
    local loc = net.ReadString()
    local ply = net.ReadEntity()

    surface.PlaySound("ambient/alarms/klaxon1.wav")
    
    activeTerror = {
        location = loc,
        terrorist = ply,
        time = UnPredictedCurTime() + 10 -- Show for 10 seconds
    }
end)

hook.Add("HUDPaint", "ZGrad_TerrorHUD", function()
    if activeTerror and activeTerror.time > UnPredictedCurTime() then
        local w, h = ScrW(), ScrH()
        -- Pulse effect
        local alpha = math.abs(math.sin(CurTime() * 4)) * 100 + 155
        
        draw.RoundedBox(0, 0, h/4, w, 120, Color(150, 20, 20, alpha * 0.8))
        draw.RoundedBox(0, 0, h/4 - 4, w, 4, Color(255, 50, 50, alpha))
        draw.RoundedBox(0, 0, h/4 + 120, w, 4, Color(255, 50, 50, alpha))

        draw.SimpleText("ВНИМАНИЕ! НАЧАЛСЯ ТЕРАКТ!", "ZGrad_TerrorTitle", w/2, h/4 + 35, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Место: " .. activeTerror.location, "ZGrad_TerrorSub", w/2, h/4 + 80, Color(255, 200, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif activeTerror then
        activeTerror = nil
    end
end)

print("[Z-Grad RP] Terror Act HUD Loaded")
