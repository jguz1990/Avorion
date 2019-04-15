
require("stringutility")

WeaponType = {}
WeaponType["ChainGun"] = 0
WeaponType["PointDefenseChainGun"] = 1
WeaponType["PointDefenseLaser"] = 2
WeaponType["Laser"] = 3
WeaponType["MiningLaser"] = 4 -- "MiningLaser" is explicitly used in C++ code and must be available
WeaponType["RawMiningLaser"] = 5
WeaponType["SalvagingLaser"] = 6
WeaponType["RawSalvagingLaser"] = 7
WeaponType["PlasmaGun"] = 8
WeaponType["RocketLauncher"] = 9
WeaponType["Cannon"] = 10
WeaponType["RailGun"] = 11
WeaponType["RepairBeam"] = 12
WeaponType["Bolter"] = 13
WeaponType["LightningGun"] = 14
WeaponType["TeslaGun"] = 15
WeaponType["ForceGun"] = 16
WeaponType["PulseCannon"] = 17
WeaponType["AntiFighter"] = 18

WeaponTypes = {}

function WeaponTypes.getArmed()
    return WeaponType.AntiFighter,
            WeaponType.Bolter,
            WeaponType.Cannon,
            WeaponType.ChainGun,
            WeaponType.Laser,
            WeaponType.LightningGun,
            WeaponType.PlasmaGun,
            WeaponType.PointDefenseChainGun,
            WeaponType.PointDefenseLaser,
            WeaponType.PulseCannon,
            WeaponType.RailGun,
            WeaponType.RocketLauncher,
            WeaponType.TeslaGun
end

WeaponTypes.nameByType = {}
WeaponTypes.nameByType[WeaponType.ChainGun] =             "Chaingun /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.PointDefenseChainGun] = "Point Defense Chaingun /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.PointDefenseLaser] =    "Point Defense Laser /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.Laser] =                "Laser /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.MiningLaser] =          "Mining Laser /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.RawMiningLaser] =       "Raw Mining Laser /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.SalvagingLaser] =       "Salvaging Laser /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.RawSalvagingLaser] =    "Raw Salvaging Laser /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.PlasmaGun] =            "Plasma /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.RocketLauncher] =       "Launcher /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.Cannon] =               "Cannon /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.RailGun] =              "Railgun /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.RepairBeam] =           "Repair /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.Bolter] =               "Bolter /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.LightningGun] =         "Lightning Gun /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.TeslaGun] =             "Tesla Gun /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.ForceGun] =             "Force Gun /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.PulseCannon] =          "Pulse Cannon /* Weapon Type */"%_t
WeaponTypes.nameByType[WeaponType.AntiFighter] =          "Anti Fighter /* Weapon Type */"%_t

function WeaponTypes.getRandom(rand)
    return rand:getInt(WeaponType.ChainGun, WeaponType.AntiFighter)
end
