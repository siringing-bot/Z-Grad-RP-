--[[---------------------------------------------------------------------------
Z-Grad RP — Masking Module (Client)
---------------------------------------------------------------------------]]

local IsMasked = false

net.Receive("ZGrad_MaskApply", function()
    IsMasked = true
end)

net.Receive("ZGrad_MaskRemove", function()
    IsMasked = false
end)

-- Extra safety to clear UI
hook.Add("PlayerDeath", "ZGrad_MaskClearUI", function(ply)
    if ply == LocalPlayer() then IsMasked = false end
end)

hook.Add("PlayerSpawn", "ZGrad_MaskClearUI", function(ply)
    if ply == LocalPlayer() then IsMasked = false end
end)

hook.Add("OnPlayerChangedTeam", "ZGrad_MaskClearUI_Job", function(ply)
    if ply == LocalPlayer() then IsMasked = false end
end)

hook.Add("HUDPaint", "ZGrad_MaskHUD", function()
    if not IsMasked then return end

    local w, h = ScrW(), ScrH()
    local text = "Что-бы снять маскировку нажмите клавишу Т"
    
    draw.SimpleTextOutlined(text, "DermaDefaultBold", w / 2, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
end)
