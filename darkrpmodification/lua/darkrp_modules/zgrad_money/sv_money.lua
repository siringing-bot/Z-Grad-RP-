--[[---------------------------------------------------------------------------
Z-Grad RP — Money Notification (Server)
---------------------------------------------------------------------------]]

util.AddNetworkString("ZGrad_MoneyNotify")

local PM = FindMetaTable("Player")
local oldAddMoney = PM.addMoney

function PM:addMoney(amount)
    if not IsValid(self) then return oldAddMoney(self, amount) end
    
    -- Блокируем потерю денег после смерти, если их 100 или меньше
    if amount < 0 and not self:Alive() then
        local current = self:getDarkRPVar("money") or 0
        if current <= 100 then
            return false
        end
    end
    
    -- Только если приходят деньги (положительное число)
    if amount > 0 then
        net.Start("ZGrad_MoneyNotify")
            net.WriteInt(amount, 32)
        net.Send(self)
    end
    
    return oldAddMoney(self, amount)
end

print("[Z-Grad RP] Money Notification (Server) Loaded")
