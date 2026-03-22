include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos() + Vector(0, 0, 80)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
        draw.SimpleTextOutlined("Учёный", "DermaLarge", 0, 0, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined("Торгует реактивами", "DermaDefault", 0, 30, Color(180, 220, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
    cam.End3D2D()
end

-- Ingredient shop items (client copy for display)
local shopIngredients = {
    { id = "red_phosphorus",  name = "Красный фосфор",       grams = 50,  price = 1500, model = "models/props_lab/jar01a.mdl" },
    { id = "solvent",         name = "Растворитель",          grams = 200, price = 400,  model = "models/props_junk/garbage_plasticbottle001a.mdl" },
    { id = "distilled_water", name = "Дистиллированная вода", grams = 300, price = 600,  model = "models/props_junk/plasticbucket001a.mdl" },
    { id = "lithium",         name = "Литий",                 grams = 60,  price = 800,  model = "models/props_junk/garbage_metalcan001a.mdl" },
    { id = "pseudoephedrine", name = "Псевдоэфедрин",         grams = 80,  price = 1400, model = "models/props_junk/garbage_milkcarton001a.mdl" },
    { id = "methylamine",     name = "Метиламин",             grams = 80,  price = 1000, model = "models/props_junk/garbage_plasticbottle002a.mdl" },
    { id = "crimson_x",       name = 'Реагент "Crimson-X"',   grams = 20,  price = 3000, model = "models/props_junk/garbage_bag001a.mdl" },
}

net.Receive("ZGrad_Meth_ScientistShop", function()
    local frame = vgui.Create("DFrame")
    frame:SetSize(550, 600)
    frame:Center()
    frame:SetTitle("")
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 30, 245))
        draw.RoundedBox(8, 0, 0, w, 30, Color(40, 40, 80, 200))
        draw.SimpleText("🧪 Учёный — Реактивы", "DermaDefaultBold", w / 2, 15, Color(220, 200, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Ваш баланс: " .. DarkRP.formatMoney(LocalPlayer():getDarkRPVar("money") or 0), "DermaDefault", 10, 45, Color(100, 255, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(0, 60)
    scroll:SetSize(550, 540)
    scroll:DockMargin(5, 5, 5, 5)
    
    for _, item in ipairs(shopIngredients) do
        local panel = scroll:Add("DPanel")
        panel:Dock(TOP)
        panel:DockMargin(10, 5, 10, 5)
        panel:SetTall(80)
        panel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(40, 40, 60, 200))
        end
        
        -- Icon
        local icon = vgui.Create("SpawnIcon", panel)
        icon:SetSize(70, 70)
        icon:SetPos(5, 5)
        icon:SetModel(item.model)
        icon:SetMouseInputEnabled(false)
        
        -- Name
        local lblName = vgui.Create("DLabel", panel)
        lblName:SetPos(85, 10)
        lblName:SetText(item.name .. " (" .. item.grams .. "г)")
        lblName:SetFont("DermaDefaultBold")
        lblName:SetSize(300, 20)
        lblName:SetColor(Color(255, 255, 255))
        
        -- Price
        local lblPrice = vgui.Create("DLabel", panel)
        lblPrice:SetPos(85, 30)
        lblPrice:SetText(DarkRP.formatMoney(item.price))
        lblPrice:SetFont("DermaDefaultBold")
        lblPrice:SizeToContents()
        lblPrice:SetColor(Color(100, 255, 100))
        
        -- Buy button
        local btnBuy = vgui.Create("DButton", panel)
        btnBuy:Dock(RIGHT)
        btnBuy:DockMargin(0, 15, 15, 15)
        btnBuy:SetText("Купить")
        btnBuy:SetWide(100)
        btnBuy:SetColor(Color(255, 255, 255))
        btnBuy.Paint = function(self, w, h)
            local col = self:IsHovered() and Color(60, 60, 120) or Color(40, 40, 100)
            draw.RoundedBox(4, 0, 0, w, h, col)
        end
        btnBuy.DoClick = function()
            net.Start("ZGrad_Meth_BuyIngredient")
            net.WriteString(item.id)
            net.SendToServer()
        end
    end
end)
