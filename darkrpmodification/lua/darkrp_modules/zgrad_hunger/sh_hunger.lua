-- zgrad_hunger/sh_hunger.lua
-- Register the energy variable to avoid warnings and ensure it networks correctly

DarkRP.registerDarkRPVar("energy", net.WriteFloat, net.ReadFloat)
DarkRP.registerDarkRPVar("hungerImmuneEnd", net.WriteFloat, net.ReadFloat)

print("[Z-Grad RP] Hunger Shared Module Loaded")
