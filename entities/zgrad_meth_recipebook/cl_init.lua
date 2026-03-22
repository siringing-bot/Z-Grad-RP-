include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    
    local pos = self:GetPos() + Vector(0, 0, 12)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)
    
    cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.05)
        draw.SimpleTextOutlined("Книга рецептов", "DermaDefaultBold", 0, 0, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        draw.SimpleTextOutlined("Нажмите E", "DermaDefault", 0, 20, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
    cam.End3D2D()
end

-- Recipe book UI
net.Receive("ZGrad_Meth_RecipeBook", function()
    local recipes = {
        {
            name = "Метамфетамин",
            price = "250$/г",
            output = "50г",
            cookTime = "60 сек",
            steps = {
                "1. Дистиллированная вода (300г) в кастрюлю",
                "2. Красный фосфор (50г)",
                "3. Литий (60г)",
                "4. Псевдоэфедрин (80г)",
                "5. Растворитель (200г)",
                "6. Поставить на плиту (60 сек)",
            }
        },
        {
            name = "Синий Метамфетамин",
            price = "500$/г",
            output = "50г",
            cookTime = "120 сек",
            steps = {
                "1. Дистиллированная вода (300г) в кастрюлю",
                "2. Метиламин (160г)",
                "3. Литий (120г)",
                "4. Красный фосфор (100г)",
                "5. Растворитель (400г)",
                "6. Поставить на плиту (120 сек)",
            }
        },
        {
            name = "Красный Метамфетамин",
            price = "1000$/г",
            output = "50г",
            cookTime = "240 сек",
            steps = {
                "1. Дистиллированная вода (600г) в кастрюлю",
                "2. Литий (120г)",
                "3. Красный фосфор (150г)",
                '4. Реагент "Crimson-X" (20г)',
                "5. Растворитель (600г)",
                "6. Поставить на плиту (240 сек)",
            }
        },
        {
            name = "Fury-13",
            price = "100 000$ / шприц",
            output = "1 шприц",
            cookTime = "Мгновенно (тазик)",
            steps = {
                "1. Метамфетамин (50г) в тазик",
                "2. Синий Метамфетамин (50г)",
                "3. Красный Метамфетамин (50г)",
                "4. Растворитель (800г)",
            }
        }
    }
    
    -- Create frame
    local frame = vgui.Create("DFrame")
    frame:SetSize(650, 550)
    frame:Center()
    frame:SetTitle("Книга Рецептов")
    frame:MakePopup()
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 30, 245))
        draw.RoundedBox(8, 0, 0, w, 28, Color(40, 80, 40, 200))
        draw.SimpleText("📖 Книга Рецептов", "DermaDefaultBold", w / 2, 14, Color(200, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    local sheet = vgui.Create("DPropertySheet", frame)
    sheet:Dock(FILL)
    sheet:DockMargin(5, 5, 5, 5)
    
    for _, recipe in ipairs(recipes) do
        local scroll = vgui.Create("DScrollPanel", sheet)
        scroll:Dock(FILL)
        
        -- Recipe header
        local header = scroll:Add("DPanel")
        header:Dock(TOP)
        header:DockMargin(5, 5, 5, 5)
        header:SetTall(70)
        header.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(40, 40, 50, 200))
            draw.SimpleText(recipe.name, "DermaLarge", 10, 5, Color(255, 255, 255), TEXT_ALIGN_LEFT)
            draw.SimpleText("Цена: " .. recipe.price .. " | Выход: " .. recipe.output, "DermaDefault", 10, 30, Color(100, 255, 100), TEXT_ALIGN_LEFT)
            draw.SimpleText("Время варки: " .. recipe.cookTime, "DermaDefault", 10, 48, Color(255, 200, 100), TEXT_ALIGN_LEFT)
        end
        
        -- Steps
        for i, step in ipairs(recipe.steps) do
            local stepPanel = scroll:Add("DPanel")
            stepPanel:Dock(TOP)
            stepPanel:DockMargin(10, 3, 10, 0)
            stepPanel:SetTall(25)
            local stepColor = (i % 2 == 0) and Color(35, 35, 45, 200) or Color(45, 45, 55, 200)
            stepPanel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, stepColor)
                draw.SimpleText(step, "DermaDefault", 10, h / 2, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end
        
        sheet:AddSheet(recipe.name, scroll, "icon16/book.png")
    end
end)
