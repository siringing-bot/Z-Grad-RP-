include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local methType = self:GetMethType()
    if methType == "" then return end
    
    local grams = self:GetGrams()
    local quality = self:GetQuality()
    
    local name = "Метамфетамин"
    local nameColor = Color(255, 255, 255)
    
    if ZGRAD_METH and ZGRAD_METH.Recipes and ZGRAD_METH.Recipes[methType] then
        name = ZGRAD_METH.Recipes[methType].name
        nameColor = ZGRAD_METH.Recipes[methType].color or nameColor
    end
    
    -- Quality color
    local qualColor = Color(0, 255, 0)
    if quality < 50 then
        qualColor = Color(255, 0, 0)
    elseif quality < 80 then
        qualColor = Color(255, 255, 0)
    end
    
    local pos = self:GetPos() + Vector(0, 0, 15)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.05)
        draw.SimpleTextOutlined(name, "DermaDefaultBold", 0, 0, nameColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined(grams .. "г", "DermaDefault", 0, 20, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined("Качество: " .. quality .. "%", "DermaDefault", 0, 40, qualColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
    cam.End3D2D()
end
