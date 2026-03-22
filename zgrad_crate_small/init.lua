AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/cardboard_box001a.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end
    
    self.CrateItems = {}
    self:SetNWInt("ZGrad_CrateCount", 0)
    self.IsCrate = true
end

function ENT:Use(ply)
    -- Проверка на закрытость (из DarkRP)
    if ZGrad_Crates.IsLocked(self) then
        self:EmitSound("doors/handle_try1.wav")
        return
    end
    
    print("[Z-Grad Crate] Opened by " .. ply:Nick())

    -- Открываем меню
    net.Start("ZGrad_Crates_OpenMenu")
        net.WriteEntity(self)
        net.WriteTable(self.CrateItems or {})
    net.Send(ply)
end

function ENT:PhysicsCollide(data, phys)
    local ent = data.HitEntity
    if not IsValid(ent) then return end
    
    -- Проверка на закрытость (нельзя класть в закрытый)
    if ZGrad_Crates.IsLocked(self) then return end

    -- Прилипание к транспорту
    if ent:IsVehicle() or ent:GetClass() == "prop_vehicle_jeep" or ent:GetClass() == "prop_vehicle_airboat" then
        -- Если игрок активно перемещает ящик — не прилипаем
        if self:IsPlayerHolding() or self._ZGrad_IsBeingHeld then return end
        
        -- Если у транспорта уже много чего приварено — можно добавить ограничение, но пока просто велдим
        if not constraint.HasConstraints(self) then
            timer.Simple(0, function()
                if IsValid(self) and IsValid(ent) and not self:IsPlayerHolding() then
                    constraint.Weld(self, ent, 0, 0, 0, true, false)
                    self:EmitSound("physics/metal/metal_box_impact_bullet1.wav", 75, 120)
                end
            end)
        end
        return
    end

    -- Пытаемся добавить предмет
    if ZGrad_Crates and ZGrad_Crates.AddItem then
        local success = ZGrad_Crates.AddItem(self, ent)
        if success then
            self:EmitSound("physics/wood/wood_box_impact_soft1.wav")
        end
    end
end
