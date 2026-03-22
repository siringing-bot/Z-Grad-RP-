include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local ingredientID = self:GetIngredientID()
    if ingredientID == "" then return end
    
    local grams = self:GetGrams()
    local name = ingredientID
    
    -- Try to get the display name
    if ZGRAD_METH and ZGRAD_METH.Ingredients and ZGRAD_METH.Ingredients[ingredientID] then
        name = ZGRAD_METH.Ingredients[ingredientID].name
    end
    
    local pos = self:GetPos() + Vector(0, 0, 15)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.05)
        draw.SimpleTextOutlined(name, "DermaDefaultBold", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined(grams .. "г", "DermaDefault", 0, 20, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
    cam.End3D2D()
end
