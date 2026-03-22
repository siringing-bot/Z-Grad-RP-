--[[---------------------------------------------------------------------------
Z-Grad RP — Context Menu (Server)
Item selling logic
---------------------------------------------------------------------------]]

util.AddNetworkString("ZGrad_ContextMenu_SellItem")

net.Receive("ZGrad_ContextMenu_SellItem", function(len, ply)
    local ent = net.ReadEntity()
    
    if not IsValid(ent) then return end
    if ply:GetPos():DistToSqr(ent:GetPos()) > 62500 then return end
    
    -- Owner check
    if ent:GetNW2Entity("owner") ~= ply and (ent.Getowning_ent and ent:Getowning_ent() ~= ply) then
        DarkRP.notify(ply, 1, 4, "Вы не владелец этого предмета!")
        return
    end

    local class = ent:GetClass()
    local price = 0
    local found = false
    
    -- Search in entities
    if DarkRPEntities then
        for _, e in pairs(DarkRPEntities) do
            if e.ent == class then
                price = e.price or 0
                found = true
                break
            end
        end
    end
    
    -- Search in shipments (incase it's a crate or something)
    if not found and CustomShipments then
         for _, s in pairs(CustomShipments) do
            if s.entity == class then
                price = s.price or 0
                found = true
                break
            end
        end
    end

    if not found or price <= 0 then
        DarkRP.notify(ply, 1, 4, "Этот предмет нельзя продать таким способом!")
        return
    end

    local sellPrice = math.floor(price * 0.5)
    
    -- Give money
    ply:addMoney(sellPrice)
    DarkRP.notify(ply, 0, 4, "Предмет продан за $" .. sellPrice)
    
    -- Удаляем предмет (лимит сбросится автоматически в sv_cleanup.lua)

    -- Remove entity
    ent:Remove()
    
    -- Sound
    ply:EmitSound("ambient/levels/labs/coinslot1.wav")
end)

print("[Z-Grad RP] Context Menu (Server) Loaded")
