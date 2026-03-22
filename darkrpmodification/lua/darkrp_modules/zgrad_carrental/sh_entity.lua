--[[---------------------------------------------------------------------------
Z-Grad Car Rental - NPC Entity
---------------------------------------------------------------------------]]

local ENT = {}
ENT.Type = "ai"
ENT.Base = "base_ai"
ENT.PrintName = "Аренда транспорта"
ENT.Author = "Antigravity"
ENT.Spawnable = true
ENT.AdminSpawnable = true

-- Animation Fix (SERVER ONLY since sequence state is synced)
if SERVER then
    function ENT:Initialize()
        self:SetModel(ZGrad_CarRental.NPCModel)
        self:SetHullType(HULL_HUMAN)
        self:SetHullSizeNormal()
        self:SetNPCState(NPC_STATE_IDLE)
        self:SetSolid(SOLID_BBOX)
        self:CapabilitiesAdd(CAP_ANIMATEDFACE + CAP_TURN_HEAD)
        self:SetUseType(SIMPLE_USE)
        self:DropToFloor()

        self:SetAutomaticFrameAdvance(true)
        local seq = self:LookupSequence("idle_all_01")
        if seq == -1 then seq = self:LookupSequence("idle") end
        if seq ~= -1 then
            self:SetSequence(seq)
        end
    end

    function ENT:Think()
        self:FrameAdvance(CurTime())

        if self:GetSequence() == 0 or self:GetSequence() == -1 then
            local seq = self:LookupSequence("idle_all_01")
            if seq ~= -1 then self:SetSequence(seq) end
        end

        self:NextThink(CurTime())
        return true
    end

    function ENT:AcceptInput(name, activator, caller)
        if name == "Use" and IsValid(activator) and activator:IsPlayer() then
            net.Start("ZGrad_Rental_OpenMenu")
            net.Send(activator)
        end
    end
else
    function ENT:Draw()
        self:DrawModel()
        
        local pos = self:GetPos() + Vector(0, 0, 80)
        local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
        
        cam.Start3D2D(pos, ang, 0.1)
            draw.SimpleText("АРЕНДА ТРАНСПОРТА", "ZGrad_Mayor_Title", 0, 0, Color(0, 180, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end

scripted_ents.Register(ENT, "zgrad_rental_npc")
