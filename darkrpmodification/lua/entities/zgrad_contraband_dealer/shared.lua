ENT.Type = "ai"
ENT.Base = "base_ai"
ENT.PrintName = "Контрабандист"
ENT.Author = "Z-Grad RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.AutomaticFrameAdvance = true

-- Конфигурация магазина
-- Редактируй содержимое здесь!
ENT.ShopItems = {
    Weapons = {
        { name = "Транквилизатор", class = "weapon_tranquilizer", price = 3000, model = "models/fc5/weapons/handguns/m9.mdl" },
        { name = "Barrett M98B", class = "weapon_m98b", price = 6000, model = "models/weapons/zcity/gleb/w_kar98k.mdl" },
        { name = "SR25", class = "weapon_sr25", price = 7000, model = "models/weapons/zcity/gleb/w_kar98k.mdl" },
        { name = "Арбалет", class = "weapon_hg_crossbow", price = 5000, model = "models/weapons/w_crossbow.mdl" },
        { name = "PTRD", class = "weapon_ptrd", price = 7000, model = "models/weapons/zcity/gleb/w_kar98k.mdl" },
        { name = "Kar98", class = "weapon_kar98", price = 2500, model = "models/weapons/zcity/gleb/w_kar98k.mdl" },
        { name = "M249", class = "weapon_m249", price = 4000, model = "models/weapons/zcity/gleb/w_kar98k.mdl" },
        { name = "Шокер", class = "weapon_taser", price = 600, model = "models/weapons/zcity/gleb/w_kar98k.mdl" },
        { name = "AKM", class = "weapon_akm", price = 3250, model = "models/weapons/arccw/c_ud_m16.mdl" },
    },
    Ammo = {
        { name = "Дротик для транквилизатора", ammoType = "ent_ammo_tranquilizerdarts", amount = 20, price = 500 },
        { name = "Арбалетный болт", ammoType = "ent_ammo_armature", amount = 2, price = 200 }, -- SMG1 often used for rifles in HL2 base
        { name = "14.5х114mm B32", ammoType = "ent_ammo_14.5x114mmb32", amount = 8, price = 1000 },
        { name = "5.56x45mm", ammoType = "ent_ammo_5.56x45mm", amount = 20, price = 150 },
        { name = "7.62x51mm", ammoType = "ent_ammo_7.62x51mm", amount = 20, price = 300 },
        { name = ".338 Lapua Magnum", ammoType = "ent_ammo_.338lapuamagnum", amount = 20, price = 500 },
    },
    Attachments = {
        -- Пример: Обвес как entity или через функцию. 
        -- Если это ARC9/TFA, там своя система. Пока сделаем просто выдачу энтити или предмета.
        { name = "Тяжёлый бронижилет", class = "ent_armor_vest5", price = 2000, model = "models/player/armor_arctic/armor_arctic.mdl" },
        { name = "Наручники", class = "weapon_handcuffs", price = 600, model = "models/weapons/w_fists_t.mdl" },
        { name = "Ключи от наручников", class = "weapon_handcuffs_key", price = 1000, model = "models/items/ammocrate_smg1.mdl" },
        { name = "Оптический прицел Leupold Mark 4 LR", class = "ent_att_optic6", price = 1000, model = "models/items/ammocrate_smg1.mdl" },
        { name = "Оптический прицел Kar98", class = "ent_att_optic12", price = 1000, model = "models/items/ammocrate_smg1.mdl" },
        { name = "Оптический прицел OСО-1", class = "ent_att_optic4", price = 1000, model = "models/items/ammocrate_smg1.mdl" },
        { name = "Шприц с Рицином", class = "weapon_syringericin", price = 2000, model = "models/items/ammocrate_smg1.mdl" },
        { name = "Шприц с Туберкулезом", class = "weapon_syringetubik", price = 4000, model = "models/items/ammocrate_smg1.mdl" },
        { name = "Шприц с Транквилизатором", class = "weapon_tranquilizer_syringe", price = 1000, model = "models/items/ammocrate_smg1.mdl" },
        { name = "Набор для маскировки", class = "zgrad_mask_kit", price = 1000, model = "models/props_c17/SuitCase_Passenger_Physics.mdl", isCriminal = true },
    }
}

function ENT:SetAutomaticFrameAdvance(bUsingAnim)
    self.AutomaticFrameAdvance = bUsingAnim
end
