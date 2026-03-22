ENT.Type = "ai"
ENT.Base = "base_ai"
ENT.PrintName = "Торговец оружием"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

ENT.ShopItems = {
    Weapons = {
        { name = "Glock 26", class = "weapon_glock26", price = 500, model = "models/weapons/tfa_ins2/w_glock_p80.mdl" },
        { name = "CZ-75A", class = "weapon_cz75a", price = 650, model = "models/weapons/zcity/w_cz75.mdl" },
        { name = "VPO-136", class = "weapon_vpo136", price = 1250, model = "models/weapons/zcity/akpack/w_akm.mdl" },
        { name = "AR-15", class = "weapon_ar15", price = 1250, model = "models/weapons/arccw/c_ud_m16.mdl" },
        { name = "XM1014", class = "weapon_xm1014", price = 1500, model = "models/weapons/tfa_ins2/w_m1014.mdl" },
        { name = "Knife", class = "weapon_melee", price = 100, model = "models/weapons/w_knife_t.mdl" },
        { name = "USP", class = "weapon_hk_usp", price = 400, model = "models/weapons/zcity/w_usp_9mm.mdl" },
        { name = "Пневматический пистолет", class = "weapon_mp-80", price = 200, model = "models/weapons/tfa_ins2/w_pm.mdl" },
        { name = "TMP", class = "weapon_tmp", price = 840, model = "models/weapons/zcity/w_tmp.mdl" },
        { name = "Remington 870", class = "weapon_remington870", price = 900, model = "models/weapons/zcity/w_shot_m3juper90.mdl" },
    },
    Ammo = {
        { name = "9x19mm", ammoType = "ent_ammo_9x19mmparabellum", amount = 20, price = 100 },
        { name = ".45rubber", ammoType = "ent_ammo_.45rubber", amount = 20, price = 50 },
        { name = "7.62x39mm", ammoType = "ent_ammo_7.62x39mm", amount = 30, price = 200 },
        { name = "12/70gauge", ammoType = "ent_ammo_12/70gauge", amount = 8, price = 150 },
        { name = "5.56x45mm", ammoType = "ent_ammo_5.56x45mm", amount = 20, price = 150 },
    },
    Attachments = {
        { name = "Бронежилет", class = "ent_armor_vest4", price = 1000 },
        { name = "Глушитель USP", class = "ent_att_supressor3", price = 500 },
        { name = "Глушитель Hybrid46", class = "ent_att_supressor8", price = 500 },
        { name = "Глушитель Ротор43 12УК", class = "ent_att_supressor5", price = 500 },
        { name = "Глушитель PBS-1", class = "ent_att_supressor1", price = 500 },
        { name = "Глушитель Tundra-SV 9mm", class = "ent_att_supressor4", price = 500 },
        { name = "Колиматор ОКП-7", class = "ent_att_holo5", price = 500 },
        { name = "Голографический прицел", class = "ent_att_holo14", price = 500 },
    }
}

function ENT:SetAutomaticFrameAdvance(bUsingAnim)
    self.AutomaticFrameAdvance = bUsingAnim
end
