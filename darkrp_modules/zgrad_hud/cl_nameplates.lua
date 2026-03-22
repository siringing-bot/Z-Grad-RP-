--[[---------------------------------------------------------------------------
Z-Grad RP — Overhead Nameplates
---------------------------------------------------------------------------]]

surface.CreateFont("ZGrad_Nameplate", {
    font = "Roboto",
    size = 48,
    weight = 800,
    antialias = true,
})

surface.CreateFont("ZGrad_Jobplate", {
    font = "Roboto",
    size = 36,
    weight = 500,
    antialias = true,
})

local function DrawNameplate(ply)
    if not IsValid(ply) or not ply:Alive() or ply == LocalPlayer() then return end
    if ply:GetNoDraw() or (ply:GetColor() and ply:GetColor().a == 0) then return end
    
    local dist = LocalPlayer():GetPos():Distance(ply:GetPos())
    if dist > 500 then return end -- Дистанция видимости
    
    -- Прозрачность в зависимости от дистанции
    local alpha = 255
    if dist > 300 then
        alpha = math.Remap(dist, 300, 500, 255, 0)
    end

    local pos = ply:GetPos() + Vector(0, 0, ply:GetModelRadius() + 15)
    local ang = LocalPlayer():EyeAngles()
    
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    local distScale = math.Clamp(dist / 500, 0.5, 1)
    
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.08)
        local nick = ply:Nick()
        local job = ply:getDarkRPVar("job") or "Безработный"
        local jobColor = (ply.getDarkRPVar and ply:getDarkRPVar("jobColor")) or team.GetColor(ply:Team())
        
        -- Никнейм
        draw.SimpleTextOutlined(nick, "ZGrad_Nameplate", 0, 0, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0, 0, 0, alpha))
        
        -- Профессия
        draw.SimpleTextOutlined(job, "ZGrad_Jobplate", 0, 5, Color(jobColor.r, jobColor.g, jobColor.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1.5, Color(0, 0, 0, alpha))
    cam.End3D2D()
end

hook.Add("PostPlayerDraw", "ZGrad_DrawNameplates", function(ply)
    DrawNameplate(ply)
end)

-- Отключаем стандартные имена DarkRP, чтобы они не накладывались
hook.Add("HUDShouldDraw", "ZGrad_HideDefaultNames", function(name)
    if name == "DarkRP_EntityDisplay" then return false end
end)
