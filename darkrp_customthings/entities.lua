--[[---------------------------------------------------------------------------
DarkRP custom entities
---------------------------------------------------------------------------]]

DarkRP.createEntity("Маскировка", {
    ent = "zgrad_mask_kit",
    model = "models/props_c17/SuitCase_Passenger_Physics.mdl",
    price = 1000,
    max = 1,
    cmd = "buymaskkit",
    category = "Криминал",
    allowed = {TEAM_MAFIA, TEAM_MANIAC, TEAM_KILLER, TEAM_DRUGS},
    customCheck = function(ply)
        return ZGrad_Utility.IsCriminal(ply)
    end,
    CustomCheckFailMsg = "Вы не принадлежите к криминальному миру!"
})

-- =============================================
-- Метаварщик — Оборудование для варки
-- =============================================

DarkRP.createEntity("Кастрюля", {
    ent = "zgrad_meth_pot",
    model = "models/props_c17/metalPot001a.mdl",
    price = 300,
    max = 2,
    cmd = "buymethpot",
    category = "Метаварщик",
    allowed = {TEAM_DRUGS},
})

DarkRP.createEntity("Газовая плита", {
    ent = "zgrad_meth_stove",
    model = "models/props_c17/furnitureStove001a.mdl",
    price = 1000,
    max = 1,
    cmd = "buymethstove",
    category = "Метаварщик",
    allowed = {TEAM_DRUGS},
})

DarkRP.createEntity("Тазик для смешивания", {
    ent = "zgrad_meth_basin",
    model = "models/props_junk/MetalBucket02a.mdl",
    price = 500,
    max = 1,
    cmd = "buymethbasin",
    category = "Метаварщик",
    allowed = {TEAM_DRUGS},
})

DarkRP.createEntity("Книга рецептов", {
    ent = "zgrad_meth_recipebook",
    model = "models/props_lab/bindergreen.mdl",
    price = 300,
    max = 1,
    cmd = "buymethrecipebook",
    category = "Метаварщик",
    allowed = {TEAM_DRUGS},
})

-- =============================================
-- ПОВАР — Оборудование и еда
-- =============================================

DarkRP.createEntity("Микроволновка", {
    ent = "zgrad_microwave",
    model = "models/props/cs_office/microwave.mdl",
    price = 1500,
    max = 2,
    cmd = "buymicrowave",
    allowed = {TEAM_COOK},
    category = "Гражданские",
})

DarkRP.createEntity("Лапша", {
    ent = "zgrad_noodle_box",
    model = "models/props_junk/garbage_takeoutcarton001a.mdl",
    price = 100,
    max = 5,
    cmd = "buynoodles",
    allowed = {TEAM_COOK},
    category = "Гражданские",
})

DarkRP.createEntity("Автомат с лапшой", {
    ent = "zgrad_noodle_vending",
    model = "models/props_interiors/VendingMachineSoda01a.mdl",
    price = 2500,
    max = 2,
    cmd = "buyvendingmachine",
    allowed = {TEAM_COOK},
    category = "Гражданские",
})

-- =============================================
-- МАФИЯ — Манипринтер и Генератор
-- =============================================

DarkRP.createEntity("Манипринтер", {
    ent     = "zgrad_maniprinter",
    model   = "models/props_c17/consolebox01a.mdl",
    price   = 3000,
    max     = 2,
    cmd     = "buymanipriter",
    category = "Мафия",
    allowed  = {TEAM_MAFIA},
})

DarkRP.createEntity("Генератор", {
    ent     = "zgrad_generator",
    model   = "models/props_vehicles/generatortrailer01.mdl",
    price   = 2000,
    max     = 1,
    cmd     = "buygenerator",
    category = "Мафия",
    allowed  = {TEAM_MAFIA},
})

-- =============================================
-- ЯЩИКИ / ТАЙНИКИ
-- =============================================

DarkRP.createEntity("Маленький ящик", {
    ent = "zgrad_crate_small",
    model = "models/props_junk/cardboard_box001a.mdl",
    price = 5000,
    max = 3,
    cmd = "buysmallcrate",
    category = "Ящики",
})

DarkRP.createEntity("Большой ящик", {
    ent = "zgrad_crate_large",
    model = "models/props_junk/wood_crate001a.mdl",
    price = 9000,
    max = 2,
    cmd = "buylargecrate",
    category = "Ящики",
})

DarkRP.createEntity("Мотошлем", {
    ent = "ent_armor_helmet2",
    model = "models/weapons/w_armor_helmet2.mdl",
    price = 1000,
    max = 2,
    cmd = "buymotorhelmet",
    category = "Автомеханик",
    allowed = {TEAM_AUTOMEHANIK},
})

DarkRP.createEntity("Ремонтный набор", {
    ent = "glide_repair",
    model = "models/weapons/w_physics.mdl",
    price = 1000,
    max = 1,
    cmd = "buyrepairkit",
    category = "Автомеханик",
    allowed = {TEAM_AUTOMEHANIK},
})

-- =============================================
-- РАДИО СИСТЕМА
-- =============================================

DarkRP.createEntity("Радио", {
    ent = "zgrad_radio",
    model = "models/props/cs_office/radio.mdl",
    price = 1000,
    max = 3,
    cmd = "buyradio",
    category = "Бизнес",
})

DarkRP.createEntity("Микрофон", {
    ent = "zgrad_radio_mic",
    model = "models/ivancorn/microphone_hyperx_s_gaming.mdl",
    price = 500,
    max = 1,
    cmd = "buymic",
    category = "Радио",
    allowed = {TEAM_RADIOHOST},
})

DarkRP.createEntity("Радио Сервер", {
    ent = "zgrad_radio_server",
    model = "models/props_lab/reciever01b.mdl",
    price = 2500,
    max = 1,
    cmd = "buyserver",
    category = "Радио",
    allowed = {TEAM_RADIOHOST},
})

DarkRP.createEntity("Этамбутол", {
    ent = "weapon_ethambutol",
    model = "models/props_junk/cardboard_box001a.mdl",
    price = 1000,
    max = 1,
    cmd = "buyethambutol",
    category = "Бизнес",
    allowed = {TEAM_MEDIC},
})

DarkRP.createEntity("Детоксин R", {
    ent = "weapon_detoxinr",
    model = "models/props_junk/cardboard_box001a.mdl",
    price = 1000,
    max = 1,
    cmd = "buydetoxinr",
    category = "Бизнес",
    allowed = {TEAM_MEDIC},
})