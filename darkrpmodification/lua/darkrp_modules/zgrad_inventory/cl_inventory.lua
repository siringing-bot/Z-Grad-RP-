--[[---------------------------------------------------------------------------
Z-Grad RP — Inventory System (Client)
---------------------------------------------------------------------------]]

local MyInventory = {}

net.Receive("ZGrad_Inventory_Sync", function()
    MyInventory = net.ReadTable()
end)

function ZGrad_Inventory.OpenMenu()
    if IsValid(ZGrad_InvFrame) then ZGrad_InvFrame:Close() end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Инвентарь (3 слота)")
    frame:SetSize(400, 180)
    frame:Center()
    frame:MakePopup()
    ZGrad_InvFrame = frame

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 240))
        draw.SimpleText("Нажмите на предмет, чтобы выкинуть его", "DermaDefault", w/2, h - 20, Color(200, 200, 200), TEXT_ALIGN_CENTER)
    end

    local layout = vgui.Create("DIconLayout", frame)
    layout:SetPos(20, 40)
    layout:SetSize(360, 100)
    layout:SetSpaceX(15)

    for i = 1, 3 do
        local slot = vgui.Create("DPanel", layout)
        slot:SetSize(100, 100)
        slot.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(50, 50, 50, 200))
            if not MyInventory[i] then
                draw.SimpleText("Пусто", "DermaDefault", w/2, h/2, Color(100, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        if MyInventory[i] then
            local icon = vgui.Create("SpawnIcon", slot)
            icon:SetSize(100, 100)
            icon:SetModel(MyInventory[i].model)
            icon:SetToolTip(MyInventory[i].name)
            
            icon.DoClick = function()
                net.Start("ZGrad_Inventory_Drop")
                net.WriteUInt(i, 4)
                net.SendToServer()
                
                -- Мы не удаляем предмет локально, ждем синхронизации от сервера (Sync).
                -- Это предотвратит исчезновение вещей при лимите.
                frame:Close()
            end
        end
    end
end
