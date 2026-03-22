AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("ZGrad_VendingMachine_OpenMenu")
util.AddNetworkString("ZGrad_VendingMachine_SetPrice")
util.AddNetworkString("ZGrad_VendingMachine_ConfirmPurchase")
util.AddNetworkString("ZGrad_VendingMachine_DoPurchase")

function ENT:Initialize()
    self:SetModel("models/props_interiors/VendingMachineSoda01a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
    
    self:SetNoodleCount(0)
    self:SetNoodlePrice(0)
end

function ENT:GetPlayerOwner()
    local owner = self:GetNW2Entity("owner")
    if IsValid(owner) and owner:IsPlayer() then return owner end
    
    if self.Getowning_ent and IsValid(self:Getowning_ent()) then 
        return self:Getowning_ent() 
    end
    
    if self.CPPIGetOwner then
        local cppio = self:CPPIGetOwner()
        if IsValid(cppio) and cppio:IsPlayer() then return cppio end
    end
    
    if self.SID then
        for _, p in ipairs(player.GetAll()) do
            if p:SteamID() == self.SID then return p end
        end
    end
    
    return nil
end

function ENT:StartTouch(ent)
    if not IsValid(ent) then return end
    if ent:GetClass() == "zgrad_noodle_box" then
        -- Prevent immediate re-entry (anti-loop)
        if ent.VendingCooldown and ent.VendingCooldown > CurTime() then return end
        
        if ent.IsBeingAbsorbed then return end
        local state = ent:GetFoodState()
        if state == 1 then -- Готовая
            ent.IsBeingAbsorbed = true
            ent:Remove()
            self:SetNoodleCount(self:GetNoodleCount() + 1)
            
            -- Sound for loading (mechanical click and sliding)
            self:EmitSound("ambient/machines/keyboard7_click.wav", 65, 120)
            self:EmitSound("physics/metal/metal_box_impact_soft1.wav", 60, 110)
        end
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    local owner = self:GetPlayerOwner()
    
    if activator == owner then
        net.Start("ZGrad_VendingMachine_OpenMenu")
        net.WriteEntity(self)
        net.Send(activator)
    else
        local count = self:GetNoodleCount()
        if count <= 0 then
            DarkRP.notify(activator, 1, 4, "В автомате нет лапши!")
            self:EmitSound("buttons/button2.wav", 60, 100) -- Error sound
            return
        end
        
        local price = self:GetNoodlePrice()
        if price <= 0 then
            DarkRP.notify(activator, 1, 4, "Владелец не установил цену!")
            return
        end
        
        if price > 1000 then
            net.Start("ZGrad_VendingMachine_ConfirmPurchase")
            net.WriteEntity(self)
            net.WriteInt(price, 32)
            net.Send(activator)
        else
            self:ProcessPurchase(activator)
        end
    end
end

function ENT:ProcessPurchase(ply)
    local count = self:GetNoodleCount()
    local price = self:GetNoodlePrice()
    
    if count <= 0 or price <= 0 then return end
    if not ply:canAfford(price) then
        DarkRP.notify(ply, 1, 4, "Недостаточно денег!")
        self:EmitSound("buttons/button2.wav", 60, 100)
        return
    end
    
    ply:addMoney(-price)
    local owner = self:GetPlayerOwner()
    if IsValid(owner) then 
        owner:addMoney(price) 
        DarkRP.notify(owner, 0, 4, "Вы продали лапшу за " .. DarkRP.formatMoney(price))
    end
    
    self:SetNoodleCount(count - 1)
    
    -- Sounds for purchase
    self:EmitSound("ambient/office/coins_1.wav", 70, 100) -- Coins sound
    self:EmitSound("buttons/button4.wav", 65, 120) -- Click
    
    timer.Simple(0.5, function()
        if not IsValid(self) then return end
        self:EmitSound("items/ammocrate_open.wav", 65, 110) -- Delivery sound
        
        local spawnPos = self:GetPos() + self:GetForward() * 25 + self:GetUp() * -30
        local noodle = ents.Create("zgrad_noodle_box")
        noodle:SetPos(spawnPos)
        noodle:Spawn()
        noodle:SetFoodState(1)
        
        -- Set 5 second cooldown so it doesn't fly back into machine immediately
        noodle.VendingCooldown = CurTime() + 5
    end)
    
    DarkRP.notify(ply, 0, 4, "Вы купили лапшу за " .. DarkRP.formatMoney(price))
end

net.Receive("ZGrad_VendingMachine_SetPrice", function(len, ply)
    local ent = net.ReadEntity()
    local price = net.ReadInt(32)
    if not IsValid(ent) or price < 0 then return end
    if ply ~= ent:GetPlayerOwner() then return end
    
    ent:SetNoodlePrice(price)
    DarkRP.notify(ply, 0, 4, "Цена установлена: " .. DarkRP.formatMoney(price))
end)

net.Receive("ZGrad_VendingMachine_DoPurchase", function(len, ply)
    local ent = net.ReadEntity()
    if IsValid(ent) then 
        if ent:GetPos():DistToSqr(ply:GetPos()) > 62500 then return end -- Shield from long-range exploits
        ent:ProcessPurchase(ply) 
    end
end)

-- Admin command to set owner for testing
concommand.Add("vending_setowner", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    
    local targetEnt = ply:GetEyeTrace().Entity
    if not IsValid(targetEnt) or targetEnt:GetClass() ~= "zgrad_noodle_vending" then
        if IsValid(ply) then ply:ChatPrint("Ошибка: Сначала посмотрите на автомат с лапшой!") end
        return 
    end
    
    local newOwner = ply
    if args[1] then
        local search = string.lower(args[1])
        local found = false
        for _, p in ipairs(player.GetAll()) do
            if string.find(string.lower(p:Nick()), search, 1, true) then
                newOwner = p
                found = true
                break
            end
        end
        
        if not found then
            if IsValid(ply) then ply:ChatPrint("Ошибка: Игрок '" .. args[1] .. "' не найден!") end
            return
        end
    end
    
    -- Set all potential owner fields
    targetEnt:SetNW2Entity("owner", newOwner)
    if targetEnt.Setowning_ent then targetEnt:Setowning_ent(newOwner) end
    if targetEnt.CPPISetOwner then targetEnt:CPPISetOwner(newOwner) end
    
    local msg = "[Vending] Владелец изменен на: " .. newOwner:Nick()
    if IsValid(ply) then ply:ChatPrint(msg) end
    print(msg)
end)
