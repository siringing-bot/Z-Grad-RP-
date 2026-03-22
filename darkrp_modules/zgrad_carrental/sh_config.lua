--[[---------------------------------------------------------------------------
Z-Grad Car Rental - Configuration
---------------------------------------------------------------------------]]

ZGrad_CarRental = ZGrad_CarRental or {}

ZGrad_CarRental.MaxDuration = 20
ZGrad_CarRental.GlobalLimit = 5
ZGrad_CarRental.NPCModel = "models/player/hostage/hostage_02.mdl"

ZGrad_CarRental.Vehicles = {
    {
        name = "Пикап",
        class = "l4d_pickup_b_78",
        price = 20000,
        model = "models/left4dead/vehicles/pickup_truck_b_78_glide.mdl" 
    },
    {
        name = "Тойота Королла",
        class = "l4d_nuke_car",
        price = 5000,
        model = "models/left4dead/vehicles/nuke_car_glide.mdl"
    },
    {
        name = "Фургон",
        class = "l4d_van",
        price = 15000,
        model = "models/left4dead/vehicles/van_glide.mdl"
    },
    {
        name = "Санчес",
        class = "gtav_sanchez",
        price = 3000,
        model = "models/gta5/vehicles/sanchez/chassis.mdl"
    },
    {
        name = "Спортивный Мотоцикл",
        class = "gtav_bati801",
        price = 5000,
        model = "models/gta5/vehicles/bati801/chassis.mdl"
    },
    {
        name = "Грузовик",
        class = "l4d_truck_nuke",
        price = 30000,
        model = "models/left4dead/vehicles/truck_nuke_glide.mdl"
    },
    {
        name = "Маслкар",
        class = "gtav_gauntlet_classic",
        price = 15000,
        model = "models/gta5/vehicles/gauntlet_classic/chassis.mdl"
    },
    {
        name = "Инфернус",
        class = "gtav_infernus",
        price = 20000,
        model = "models/gta5/vehicles/infernus/chassis.mdl"
    },
    {
        name = "Полицейская Машина",
        class = "gtav_police_cruiser",
        price = 4000,
        model = "models/gta5/vehicles/police/chassis.mdl",
        condition = function(ply)
            return ply:Team() == TEAM_POLICE or ply:Team() == TEAM_FBI
        end,
        conditionName = "Только для Полиции/FIB"
    }
}

ZGrad_CarRental.SpawnPoints = {
    Vector(1557.43, -608.95, 135.66),
    Vector(1565.02, -879.54, 135.67),
    Vector(1560.89, -246.95, 135.35),
    Vector(1710.41, -497.56, 135.33),
    Vector(1722.95, -754.78, 135.34)
}
