AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
function ENT:Initialize()
    self:SetModel("models/props/cs_office/microwave.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:SetTrigger(true)
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
end

function ENT:Touch(ent)
    if not IsValid(ent) or self:GetHasFood() then return end
    
    if ent:GetClass() == "zgrad_noodle_box" and ent:GetFoodState() == 0 then
        -- Начинаем готовить
        ent:Remove()
        self:SetHasFood(true)
        self:SetIsCooking(true)
        self:SetIsBurned(false)
        self:SetCookEndTime(CurTime() + 30)
        
        -- Звук работы
        if not self.HumSound then
            self.HumSound = CreateSound(self, Sound("ambient/machines/lab_loop1.wav"))
        end
        self.HumSound:PlayEx(0.7, 100)
        self:EmitSound("ambient/machines/microwave_1.wav", 60, 100) -- Проигрываем стартовый звук разово
    end
end


function ENT:Think()
    if self:GetIsCooking() then
        if CurTime() >= self:GetCookEndTime() then
            -- Приготовлено!
            self:SetIsCooking(false)
            self:SetBurnEndTime(CurTime() + 10)
            self:EmitSound("buttons/blip1.wav", 75, 100)
            
            if self.HumSound then
                self.HumSound:Stop()
            end
        end
    elseif self:GetHasFood() and not self:GetIsBurned() then
        if CurTime() >= self:GetBurnEndTime() then
            -- Сгорело!
            self:SetIsBurned(true)
            self:EmitSound("ambient/fire/ignite.wav", 60, 100)
        end
    end
    self:NextThink(CurTime() + 0.5)
    return true
end

function ENT:OnRemove()
    if self.HumSound then
        self.HumSound:Stop()
    end
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    
    if not self:GetHasFood() then
        DarkRP.notify(activator, 1, 4, "Микроволновка пуста. Положите сырую лапшу вовнутрь!")
        return
    end
    
    if self:GetIsCooking() then
        DarkRP.notify(activator, 1, 4, "Лапша еще готовится!")
        return
    end
    
    -- Выдача готовой/сгоревшей лапши
    local box = ents.Create("zgrad_noodle_box")
    -- Выдаем перед микроволновкой
    local spawnPos = self:GetPos() + self:GetForward() * 30 + Vector(0, 0, 10)
    box:SetPos(spawnPos)
    box:SetAngles(self:GetAngles())
    box:Spawn()
    
    if self:GetIsBurned() then
        box:SetFoodState(2)
        box:SetColor(Color(30, 30, 30))
    else
        box:SetFoodState(1)
    end
    
    self:SetHasFood(false)
    self:SetIsBurned(false)
    self:SetBurnEndTime(math.huge) -- Сбрасываем таймер сгорания, чтобы он не сработал снова
    self:EmitSound("items/ammocrate_open.wav", 60, 100)
end
