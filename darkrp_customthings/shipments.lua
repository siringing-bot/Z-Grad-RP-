--[[---------------------------------------------------------------------------
Z-Grad RP — Shipments & Guns
---------------------------------------------------------------------------]]

DarkRP.createShipment("Аптечка", {
    model = "models/weapons/w_medkit.mdl",
    entity = "weapon_medkit_sh",
    price = 2500,
    amount = 10,
    separate = false,
    pricesep = 300,
    noship = false,
    allowed = {TEAM_MEDIC},
    category = "Медицина",
})

DarkRP.createShipment("Пакет для крови", {
    model = "models/zcity/other/bloodbag.mdl",
    entity = "weapon_bloodbag",
    price = 1000,
    amount = 10,
    separate = false,
    pricesep = 200,
    noship = false,
    allowed = {TEAM_MEDIC},
    category = "Медицина",
})
