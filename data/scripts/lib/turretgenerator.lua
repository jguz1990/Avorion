package.path = package.path .. ";data/scripts/lib/?.lua"

require("galaxy")
require("randomext")
local WeaponGenerator = require ("weapongenerator")
require("weapontype")

local rand = random()

local TurretGenerator =  {}

function TurretGenerator.initialize(seed)
    if seed then
        rand = Random(seed)
    end
end

function TurretGenerator.generate(x, y, offset_in, rarity_in, type_in, material_in)

    local offset = offset_in or 0
    local seed = rand:createSeed()
    local dps = 0
    local sector = math.max(0, math.floor(length(vec2(x, y))) + offset)

    local weaponDPS, weaponTech = Balancing_GetSectorWeaponDPS(sector, 0)
    local miningDPS, miningTech = Balancing_GetSectorMiningDPS(sector, 0)
    local materialProbabilities = Balancing_GetTechnologyMaterialProbability(sector, 0)
    local material = material_in or Material(getValueFromDistribution(materialProbabilities))
    local weaponType = type_in or getValueFromDistribution(Balancing_GetWeaponProbability(sector, 0))

    local tech = 0
    if weaponType == WeaponType.MiningLaser then
        dps = miningDPS * 2
        tech = miningTech
    elseif weaponType == WeaponType.RawMiningLaser then
        dps = miningDPS * 4
        tech = miningTech
    elseif weaponType == WeaponType.ForceGun then
        dps = rand:getFloat(800, 1200); -- force
        tech = weaponTech
    else
        dps = weaponDPS
        tech = weaponTech
    end

    local rarities = {}
    rarities[5] = 0.1 -- legendary
    rarities[4] = 1 -- exotic
    rarities[3] = 8 -- exceptional
    rarities[2] = 16 -- rare
    rarities[1] = 0 -- uncommon
    rarities[0] = 0 -- common

    local rarity = rarity_in or Rarity(getValueFromDistribution(rarities))

    return TurretGenerator.generateSeeded(seed, weaponType, dps, tech, rarity, material)
end

function TurretGenerator.generateArmed(x, y, offset_in, rarity_in, material_in)

    local offset = offset_in or 0
    local sector = math.floor(length(vec2(x, y))) + offset
    local types = Balancing_GetWeaponProbability(sector, 0)

    types[WeaponType.RepairBeam] = nil
    types[WeaponType.MiningLaser] = nil
    types[WeaponType.SalvagingLaser] = nil
    types[WeaponType.RawSalvagingLaser] = nil
    types[WeaponType.RawMiningLaser] = nil
    types[WeaponType.ForceGun] = nil

    local weaponType = getValueFromDistribution(types)

    return TurretGenerator.generate(x, y, offset_in, rarity_in, weaponType, material_in)
end

function TurretGenerator.generateSeeded(seed, weaponType, dps, tech, rarity, material)

    local secured = rand

    TurretGenerator.initialize(seed)
    local turret = TurretGenerator.generateTurret(rand, weaponType, dps, tech, material, rarity)

    rand = secured

    return turret
end





local scales = {}
scales[WeaponType.ChainGun] = {
    {from = 0, to = 15, size = 0.5, usedSlots = 1},
    {from = 16, to = 31, size = 1.0, usedSlots = 1},
    {from = 32, to = 52, size = 1.5, usedSlots = 1},
}

scales[WeaponType.PointDefenseChainGun] = {
    {from = 0, to = 52, size = 0.5, usedSlots = 1},
}

scales[WeaponType.PointDefenseLaser] = {
    {from = 0, to = 52, size = 0.5, usedSlots = 1},
}

scales[WeaponType.Bolter] = {
    {from = 0, to = 18, size = 0.5, usedSlots = 1},
    {from = 19, to = 33, size = 1.0, usedSlots = 1},
    {from = 34, to = 45, size = 1.5, usedSlots = 1},
    {from = 46, to = 52, size = 2.0, usedSlots = 1},
}

scales[WeaponType.Laser] = {
    {from = 0, to = 24, size = 0.5, usedSlots = 1},
    {from = 25, to = 35, size = 1.0, usedSlots = 1},
    {from = 36, to = 46, size = 1.5, usedSlots = 1},
    {from = 47, to = 49, size = 2.0, usedSlots = 1},
    {from = 50, to = 52, size = 3.5, usedSlots = 1},
}

scales[WeaponType.MiningLaser] = {
    {from = 0, to = 12, size = 0.5, usedSlots = 1},
    {from = 13, to = 30, size = 0.5, usedSlots = 1},
    {from = 31, to = 49, size = 0.5, usedSlots = 1},
    {from = 50, to = 52, size = 0.5, usedSlots = 1},
}
scales[WeaponType.RawMiningLaser] = scales[WeaponType.MiningLaser]

scales[WeaponType.SalvagingLaser] = {
    {from = 0, to = 12, size = 0.5, usedSlots = 1},
    {from = 13, to = 30, size = 1.0, usedSlots = 1},
    {from = 31, to = 49, size = 1.0, usedSlots = 1},
    {from = 50, to = 52, size = 1.0, usedSlots = 1},
}
scales[WeaponType.RawSalvagingLaser] = scales[WeaponType.SalvagingLaser]

scales[WeaponType.PlasmaGun] = {
    {from = 0, to = 30, size = 0.5, usedSlots = 1},
    {from = 31, to = 39, size = 1.0, usedSlots = 1},
    {from = 40, to = 48, size = 1.5, usedSlots = 1},
    {from = 49, to = 52, size = 2.0, usedSlots = 1},
}

scales[WeaponType.RocketLauncher] = {
    {from = 0, to = 32, size = 1.0, usedSlots = 1},
    {from = 33, to = 40, size = 1.5, usedSlots = 1},
    {from = 41, to = 48, size = 2.0, usedSlots = 1},
    {from = 49, to = 52, size = 3.0, usedSlots = 1},
}

scales[WeaponType.Cannon] = {
    {from = 0, to = 28, size = 1.5, usedSlots = 1},
    {from = 29, to = 38, size = 2.0, usedSlots = 1},
    {from = 39, to = 49, size = 3.0, usedSlots = 1},
    --dummy for cooaxial, add 1 to size and level
    {from = 50, to = 52, size = 3.5, usedSlots = 1},
}

scales[WeaponType.RailGun] = {
    {from = 0, to = 28, size = 1.0, usedSlots = 1},
    {from = 29, to = 35, size = 1.5, usedSlots = 1},
    {from = 36, to = 42, size = 2.0, usedSlots = 1},
    {from = 43, to = 49, size = 3.0, usedSlots = 1},
    --dummy for cooaxial, add 1 to size and level
    {from = 50, to = 52, size = 3.5, usedSlots = 1},
}

scales[WeaponType.RepairBeam] = {
    {from = 0, to = 28, size = 0.5, usedSlots = 1},
    {from = 29, to = 40, size = 1.0, usedSlots = 1},
    {from = 41, to = 52, size = 1.5, usedSlots = 1},
}

scales[WeaponType.LightningGun] = {
    {from = 0, to = 36, size = 1.0, usedSlots = 1},
    {from = 37, to = 42, size = 1.5, usedSlots = 1},
    {from = 43, to = 46, size = 2.0, usedSlots = 1},
    {from = 47, to = 50, size = 3.0, usedSlots = 1},
    --dummy for cooaxial, add 1 to size and level
    {from = 51, to = 52, size = 3.5, usedSlots = 1},
}

scales[WeaponType.TeslaGun] = {
    {from = 0, to = 25, size = 0.5, usedSlots = 1},
    {from = 26, to = 36, size = 1.0, usedSlots = 1},
    {from = 37, to = 49, size = 1.5, usedSlots = 1},
    {from = 50, to = 52, size = 3.5, usedSlots = 1},
}

scales[WeaponType.ForceGun] = {
    {from = 0, to = 20, size = 0.5, usedSlots = 1},
    {from = 21, to = 36, size = 1.0, usedSlots = 1},
    {from = 37, to = 49, size = 1.5, usedSlots = 1},
    {from = 50, to = 52, size = 3.5, usedSlots = 1},
}

scales[WeaponType.PulseCannon] = {
    {from = 0, to = 25, size = 0.5, usedSlots = 1},
    {from = 26, to = 36, size = 1.0, usedSlots = 1},
    {from = 37, to = 47, size = 1.5, usedSlots = 1},
    {from = 48, to = 52, size = 2.0, usedSlots = 1},
}

scales[WeaponType.AntiFighter] = {
    {from = 0, to = 52, size = 0.5, usedSlots = 1},
}


function TurretGenerator.dpsToRequiredCrew(dps)
    local value = math.floor(2 + (dps / 700))
    value = value + math.min(8, math.floor(dps / 50))

    return value
end

function TurretGenerator.attachWeapons(rand, turret, weapon, numWeapons)
    turret:clearWeapons()

    places = {TurretGenerator.createWeaponPlaces(rand, numWeapons)}

    for _, position in pairs(places) do
        weapon.localPosition = position * turret.size
        turret:addWeapon(weapon)
    end
end

function TurretGenerator.createWeaponPlaces(rand, numWeapons)
    if numWeapons == 1 then
        return vec3(0, 0, 0)

    elseif numWeapons == 2 then
        local case = rand:getInt(0, 1)
        local dist = rand:getFloat(0.1, 0.4)
        if case == 0 then
            return vec3(dist, 0, 0), vec3(-dist, 0, 0)
        else
            return vec3(0, dist + 0.2, 0), vec3(0, -dist + 0.2, 0)
        end

    elseif numWeapons == 3 then
        local case = rand:getInt(0, 1)
        if case == 0 then
            return vec3(0.4, 0, 0), vec3(0, 0.2, 0), vec3(-0.4, 0, 0)
        else
            return vec3(0.4, 0, 0), vec3(0, 0, 0), vec3(-0.4, 0, 0)
        end

    elseif numWeapons == 4 then
        return vec3(0.4, -0.2, 0), vec3(-0.4, 0.2, 0), vec3(0.4, 0.2, 0), vec3(-0.4, -0.2, 0)
    end
end

function TurretGenerator.createStandardCooling(turret, coolingTime, shootingTime)
    turret:updateStaticStats()

    local maxHeat = 10

    local coolingRate = maxHeat / coolingTime -- must be smaller than heating rate or the weapon will never overheat
    local heatDelta = maxHeat / shootingTime
    local heatingRate = heatDelta + coolingRate
    local heatPerShot = heatingRate / turret.firingsPerSecond

    turret.coolingType = CoolingType.Standard
    turret.maxHeat = maxHeat
    turret.heatPerShot = heatPerShot
    turret.coolingRate = coolingRate
end

function TurretGenerator.createPerShotEnergyCooling(turret, energyPerSecond, increasePerSecond)
    turret:updateStaticStats()

    local heatingRate = energyPerSecond
    local heatDelta = increasePerSecond
    local heatPerShot = heatingRate / turret.firingsPerSecond
    local coolingRate = heatingRate - heatDelta

    turret.coolingType = CoolingType.EnergyPerShot
    turret.maxHeat = 0
    turret.heatPerShot = heatPerShot
    turret.coolingRate = coolingRate

    local coolingDescriptionExists = false
    for description, _ in pairs(turret:getDescriptions()) do
        if description == "Consumes Energy"%_T then
            coolingDescriptionExists = true
            break
        end
    end

    if coolingDescriptionExists == false then
        turret:addDescription("Consumes Energy"%_T, "")
    end
end

function TurretGenerator.createContinuousEnergyCooling(turret, energyPerSecond, increasePerSecond)
    TurretGenerator.createPerShotEnergyCooling(turret, energyPerSecond, increasePerSecond)
    turret.coolingType = CoolingType.EnergyContinuous
end

function TurretGenerator.scale(rand, turret, type, tech, turnSpeedFactor)
    local scaleTech = tech
    if rand:test(0.5) then
        scaleTech = math.floor(math.max(1, scaleTech * rand:getFloat(0, 1)))
    end

    local scale = TurretGenerator.getScale(type, scaleTech)

    turret.size = scale.size
    turret.coaxial = (scale.usedSlots >= 5)
    turret.slots = scale.usedSlots
    turret.turningSpeed = lerp(turret.size, 0.5, 3, 1, 0.3) * rand:getFloat(0.8, 1.2) * turnSpeedFactor

    local coaxialDamageScale = turret.coaxial and 3 or 1

    local weapons = {turret:getWeapons()}
    for _, weapon in pairs(weapons) do
        weapon.localPosition = weapon.localPosition * scale.size

        if scale.usedSlots > 1 then
            -- scale damage, etc. linearly with amount of used slots
            if weapon.damage ~= 0 then
                weapon.damage = weapon.damage * scale.usedSlots * coaxialDamageScale
            end

            if weapon.hullRepair ~= 0 then
                weapon.hullRepair = weapon.hullRepair * scale.usedSlots * coaxialDamageScale
            end

            if weapon.shieldRepair ~= 0 then
                weapon.shieldRepair = weapon.shieldRepair * scale.usedSlots * coaxialDamageScale
            end

            if weapon.selfForce ~= 0 then
                weapon.selfForce = weapon.selfForce * scale.usedSlots * coaxialDamageScale
            end

            if weapon.otherForce ~= 0 then
                weapon.otherForce = weapon.otherForce * scale.usedSlots * coaxialDamageScale
            end

            local increase = 0
            if type == WeaponType.MiningLaser or type == WeaponType.SalvagingLaser then
                -- mining and salvaging laser reach is scaled more
                increase = (scale.size + 2) * 2
            else
                -- scale reach a little
                increase = (scale.usedSlots + 1) * 1
            end

            weapon.reach = weapon.reach * (1 + increase)

            local shotSizeFactor = scale.size * 2
            if weapon.isProjectile then weapon.psize = weapon.psize * shotSizeFactor end
            if weapon.isBeam then weapon.bwidth = weapon.bwidth * shotSizeFactor end
        end
    end

    turret:clearWeapons()
    for _, weapon in pairs(weapons) do
        turret:addWeapon(weapon)
    end
end

function TurretGenerator.getScale(type, tech)
    for _, scale in pairs(scales[type]) do
        if tech >= scale.from and tech <= scale.to then return scale end
    end

    return {from = 0, to = 0, size = 1, usedSlots = 1}
end

local Specialty = {
    HighDamage = 0,
    SlightlyHigherDamage = 1,
    HighDamageEnergyCooling = 2,
    HighDamageStandardCooling = 3,
    HighFireRate = 4,
    HighRange = 5,
    HighHullDamage = 6,
    SlightlyHigherHullDamage = 7,
    HighShieldDamage = 8,
    SlightlyHigherShieldDamage = 9,
    HighEfficiency = 10,
    ShieldPenetration = 11,
    LessCoolingTime = 12,
    HighShootingTime = 13,
    LessEnergyConsumption = 14,
    LessEnergyConsumptionIncrease = 15,
    BurstFire = 16,
    AutomaticFireDPSReduced = 17,
    AutomaticFire = 18,
    IonizedProjectile = 19,
}

local possibleSpecialties = {}
possibleSpecialties[WeaponType.Laser] = {
    Specialty.HighRange,
    Specialty.HighHullDamage,
    Specialty.HighShieldDamage,
    Specialty.LessEnergyConsumption,
    Specialty.LessEnergyConsumptionIncrease,
}

possibleSpecialties[WeaponType.TeslaGun] = {
    Specialty.HighRange,
    Specialty.SlightlyHigherHullDamage,
    Specialty.LessEnergyConsumption,
    Specialty.LessEnergyConsumptionIncrease,
    Specialty.AutomaticFire,
}

possibleSpecialties[WeaponType.LightningGun] = {
    Specialty.HighDamage,
    Specialty.HighRange,
    Specialty.SlightlyHigherHullDamage,
    Specialty.HighFireRate,
    Specialty.LessEnergyConsumption,
    Specialty.LessEnergyConsumptionIncrease,
}

possibleSpecialties[WeaponType.MiningLaser] = {
    Specialty.SlightlyHigherDamage,
    Specialty.HighRange,
    Specialty.HighEfficiency,
}
possibleSpecialties[WeaponType.RawMiningLaser] = possibleSpecialties[WeaponType.MiningLaser]

possibleSpecialties[WeaponType.SalvagingLaser] = {
    Specialty.HighRange,
    Specialty.SlightlyHigherDamage,
    Specialty.HighEfficiency,
}
possibleSpecialties[WeaponType.RawSalvagingLaser] = possibleSpecialties[WeaponType.SalvagingLaser]

possibleSpecialties[WeaponType.RepairBeam] = {
    Specialty.HighDamage,
    Specialty.HighRange,
    Specialty.HighHullDamage,
    Specialty.HighShieldDamage,
    Specialty.LessEnergyConsumption,
    Specialty.LessEnergyConsumptionIncrease,
}

possibleSpecialties[WeaponType.PlasmaGun] = {
    Specialty.HighDamage,
    Specialty.HighFireRate,
    Specialty.HighRange,
    Specialty.SlightlyHigherHullDamage,
    Specialty.LessEnergyConsumption,
    Specialty.LessEnergyConsumptionIncrease,
    Specialty.BurstFire,
    Specialty.AutomaticFire,
}

possibleSpecialties[WeaponType.Cannon] = {
    Specialty.HighDamage,
    Specialty.HighFireRate,
    Specialty.HighRange,
    Specialty.HighHullDamage,
    Specialty.HighShieldDamage,
    Specialty.ShieldPenetration,
    Specialty.LessCoolingTime,
    Specialty.HighShootingTime,
    Specialty.BurstFire,
}

possibleSpecialties[WeaponType.ChainGun] = {
    Specialty.HighFireRate,
    Specialty.HighRange,
    Specialty.SlightlyHigherShieldDamage,
    Specialty.AutomaticFire,
}

possibleSpecialties[WeaponType.PointDefenseChainGun] = {
    Specialty.HighDamage,
    Specialty.HighFireRate,
    Specialty.HighRange,
    Specialty.HighHullDamage,
}

possibleSpecialties[WeaponType.PointDefenseLaser] = {
    Specialty.SlightlyHigherDamage,
    Specialty.HighRange,
}

possibleSpecialties[WeaponType.Bolter] = {
    Specialty.HighDamage,
    Specialty.HighFireRate,
    Specialty.HighRange,
    Specialty.SlightlyHigherShieldDamage,
    Specialty.LessCoolingTime,
    Specialty.HighShootingTime,
    Specialty.BurstFire,
    Specialty.AutomaticFire,
}

possibleSpecialties[WeaponType.RailGun] = {
    Specialty.HighDamage,
    Specialty.HighFireRate,
    Specialty.HighRange,
    Specialty.SlightlyHigherShieldDamage,
    Specialty.LessCoolingTime,
    Specialty.HighShootingTime,
    Specialty.BurstFire,
}

possibleSpecialties[WeaponType.RocketLauncher] = {
    Specialty.HighDamage,
    Specialty.HighFireRate,
    Specialty.HighRange,
    Specialty.HighHullDamage,
    Specialty.HighShieldDamage,
    Specialty.ShieldPenetration,
    Specialty.LessCoolingTime,
    Specialty.HighShootingTime,
    Specialty.BurstFire,
}

possibleSpecialties[WeaponType.ForceGun] = {
    Specialty.HighRange,
    Specialty.LessEnergyConsumption,
    Specialty.LessEnergyConsumptionIncrease,
}

possibleSpecialties[WeaponType.PulseCannon] = {
    Specialty.HighFireRate,
    Specialty.HighRange,
    Specialty.HighHullDamage,
    Specialty.HighShieldDamage,
    Specialty.BurstFire,
}

possibleSpecialties[WeaponType.AntiFighter] = {
    Specialty.HighDamage,
    Specialty.HighFireRate,
    Specialty.HighRange,
    Specialty.HighHullDamage,
    Specialty.ShieldPenetration,
}

function TurretGenerator.addSpecialties(rand, turret, type)
    turret:updateStaticStats()

    local simultaneousShootingProbability = 0

    local specialties = {}
    if type == WeaponType.Laser then
        table.insert(specialties, rand:getBool() and Specialty.HighDamage or Specialty.HighDamageEnergyCooling)

    elseif type == WeaponType.TeslaGun then
        table.insert(specialties, rand:getBool() and Specialty.HighDamage or Specialty.HighDamageEnergyCooling)

    elseif type == WeaponType.TeslaGun then
        simultaneousShootingProbability = 0.15

    elseif type == WeaponType.LightningGun then
        simultaneousShootingProbability = 0.15

    elseif type == WeaponType.SalvagingLaser or type == WeaponType.RawSalvagingLaser then
        table.insert(specialties, rand:getBool() and Specialty.SlightlyHigherDamage or Specialty.HighDamageEnergyCooling)

    elseif type == WeaponType.PlasmaGun then
        simultaneousShootingProbability = 0.25

    elseif type == WeaponType.Cannon then
        simultaneousShootingProbability = 0.5

    elseif type == WeaponType.ChainGun then
        table.insert(specialties, rand:getBool() and Specialty.HighDamage or Specialty.HighDamageStandardCooling)
        simultaneousShootingProbability = 0.25

    elseif type == WeaponType.RailGun then
        simultaneousShootingProbability = 0.25

    elseif type == WeaponType.RocketLauncher then
        simultaneousShootingProbability = 0.5

    elseif type == WeaponType.PulseCannon then
        table.insert(specialties, rand:getBool() and Specialty.HighDamage or Specialty.HighDamageStandardCooling)
        simultaneousShootingProbability = 0.25
    end

    for _, s in pairs(possibleSpecialties[type]) do
        table.insert(specialties, s)
    end

    local firstWeapon = turret:getWeapons()
    local maxNumSpecialties = rand:getInt(0, 1 + math.modf(firstWeapon.rarity.value / 2)) -- round to zero

    -- select unique
    if maxNumSpecialties < #specialties then
        local tmp = {}
        while tablelength(tmp) < maxNumSpecialties do
            local element = specialties[rand:getInt(1, #specialties)]
            tmp[element] = element
        end

        specialties = {}
        for _, s in pairs(tmp) do
            table.insert(specialties, s)
        end
    end

    -- pulse cannons always have shield penetration
    if type == WeaponType.PulseCannon then
        -- replace a random specialty with increased shield damage
        if #specialties > 0 then
            table.sort(specialties)
            table.remove(specialties, 1)
        end

        table.insert(specialties, Specialty.IonizedProjectile)
    end

    if type == WeaponType.PointDefenseChainGun
            or type == WeaponType.PointDefenseLaser
            or type == WeaponType.AntiFighter then
        table.insert(specialties, Specialty.AutomaticFire)
    elseif rand:test(0.35) then
        table.insert(specialties, Specialty.AutomaticFireDPSReduced)
    end

    if rand:test(simultaneousShootingProbability) then
        turret.simultaneousShooting = true
    end

    table.sort(specialties)

    -- this is a random number between 0 and 1, with a tendency to be higher when the rarity is higher
    local rarityFactor = rand:getFloat(0, turret.rarity.value / HighestRarity().value)

    local weapons = {turret:getWeapons()}

    for _, s in pairs(specialties) do
        if s == Specialty.AutomaticFire then
            turret.automatic = true
            turret.coaxial = false

        elseif s == Specialty.AutomaticFireDPSReduced then
            turret.automatic = true
            turret.coaxial = false

            local factor = 0.5

            for _, weapon in pairs(weapons) do
                weapon.damage = weapon.damage * factor

                if weapon.shieldRepair ~= 0 then
                    weapon.shieldRepair = weapon.shieldRepair * factor
                end

                if weapon.hullRepair ~= 0 then
                    weapon.hullRepair = weapon.hullRepair * factor
                end
            end

        elseif s == Specialty.SlightlyHigherDamage then
            local maxIncrease = 0.5
            local increase = 0.3 + rarityFactor * maxIncrease

            for _, weapon in pairs(weapons) do
                weapon.damage = weapon.damage * (1 + increase)
            end

            local addition = math.floor(increase * 100 + 0.00001) -- TODO rounding
            turret:addDescription("%s%% Damage"%_T, string.format("%+i", addition))

        elseif s == Specialty.HighDamage then
            local maxIncrease = 3
            local increase = 0.3 + rarityFactor * maxIncrease

            for _, weapon in pairs(weapons) do
                weapon.damage = weapon.damage * (1 + increase)
            end

            local addition = math.floor(increase * 100 + 0.00001) -- TODO rounding
            turret:addDescription("%s%% Damage"%_T, string.format("%+i", addition))

        elseif s == Specialty.HighDamageEnergyCooling then
            local maxIncrease = 5
            local increase = 0.5 + rarityFactor * maxIncrease

            for _, weapon in pairs(weapons) do
                weapon.damage = weapon.damage * (1 + increase)
            end

            local dps = turret.dps

            local damageToEnergy = rand:getFloat(10, 15)
            local energyPerSecond = dps * damageToEnergy
            local increasePerSecond = energyPerSecond * rand:getFloat(0.01, 0.02)

            turret:clearWeapons()
            for _, weapon in pairs(weapons) do
                turret:addWeapon(weapon)
            end

            TurretGenerator.createContinuousEnergyCooling(turret, energyPerSecond, increasePerSecond)

            weapons = {turret:getWeapons()}

            local addition = math.floor(increase * 100)
            turret:addDescription("%s%% Damage"%_T, string.format("%+i", addition))

            -- add a dummy beam weapon
            for _, weapon in pairs(weapons) do
                if weapon.isBeam then
                    local swirlWeapon = copy(weapon)
                    swirlWeapon.damage = 0
                    swirlWeapon.bshape = BeamShape.Swirly
                    swirlWeapon.bshapeSize = 1
                    swirlWeapon.appearanceSeed = 0
                    swirlWeapon.appearance = WeaponAppearance.Invisible

                    turret:addWeapon(swirlWeapon)
                end
            end

            weapons = {turret:getWeapons()}

        elseif s == Specialty.HighDamageStandardCooling then
            local maxIncrease = 5
            local increase = 0.5 + rarityFactor * maxIncrease

            for _, weapon in pairs(weapons) do
                weapon.damage = weapon.damage * (1 + increase)
            end

            turret:clearWeapons()
            for _, weapon in pairs(weapons) do
                turret:addWeapon(weapon)
            end

            local shootingTime = 10
            local coolingTime = 5
            TurretGenerator.createStandardCooling(turret, coolingTime, shootingTime)

            weapons = {turret:getWeapons()}

            local addition = math.floor(increase * 100)
            turret:addDescription("%s%% Damage"%_T, string.format("%+i", addition))

        elseif s == Specialty.HighFireRate then
            local maxIncrease = 1
            local increase = 0.3 + rarityFactor * maxIncrease

            for _, weapon in pairs(weapons) do
                weapon.fireRate = weapon.fireRate * (1 + increase)
            end

            local addition = math.floor(increase * 100 + 0.00001) -- TODO rounding
            turret:addDescription("%s%% Fire Rate"%_T, string.format("%+i", addition))

        elseif s == Specialty.HighRange then
            local maxIncrease = 2
            local increase = 0.1 + rarityFactor * maxIncrease

            for _, weapon in pairs(weapons) do
                weapon.reach = weapon.reach * (1 + increase)
            end

            local addition = math.floor(increase * 100)
            turret:addDescription("%s%% Range"%_T, string.format("%+i", addition))

        elseif s == Specialty.HighEfficiency then
            local maxIncrease = 50.0
            local increase = 0.5 + rarityFactor * maxIncrease

            for _, weapon in pairs(weapons) do
                if weapon.stoneRefinedEfficiency ~= 0 then
                    weapon.stoneRefinedEfficiency = math.min(0.9, weapon.stoneRefinedEfficiency * (1 + increase))
                end

                if weapon.metalRefinedEfficiency ~= 0 then
                    weapon.metalRefinedEfficiency = math.min(0.9, weapon.metalRefinedEfficiency * (1 + increase))
                end

                if weapon.stoneRawEfficiency ~= 0 then
                    weapon.stoneRawEfficiency = math.min(0.9, weapon.stoneRawEfficiency * (1 + increase))
                end

                if weapon.metalRawEfficiency ~= 0 then
                    weapon.metalRawEfficiency = math.min(0.9, weapon.metalRawEfficiency * (1 + increase))
                end
            end

            local addition = math.floor(increase * 200)
            turret:addDescription("%s%% Efficiency"%_T, string.format("%+i", addition))

        elseif s == Specialty.HighHullDamage then
            local maxIncrease = 1
            local increase = 0.3 + rarityFactor * maxIncrease

            local percentage
            for _, weapon in pairs(weapons) do
                weapon.hullDamageMultiplicator = weapon.hullDamageMultiplicator + increase
                if percentage == nil then percentage = weapon.hullDamageMultiplicator end
            end

            percentage = math.floor(percentage * 100 - 100 + 0.00001) -- TODO rounding
            turret:addDescription("%s%% Damage to hull"%_T, string.format("%+i", percentage))

        elseif s == Specialty.SlightlyHigherHullDamage then
            local maxIncrease = 0.5
            local increase = 0.3 + rarityFactor * maxIncrease

            local percentage
            for _, weapon in pairs(weapons) do
                weapon.hullDamageMultiplicator = weapon.hullDamageMultiplicator + increase
                if percentage == nil then percentage = weapon.hullDamageMultiplicator end
            end

            percentage = math.floor(percentage * 100 - 100 + 0.00001) -- TODO rounding
            turret:addDescription("%s%% Damage to hull"%_T, string.format("%+i", percentage))

        elseif s == Specialty.HighShieldDamage then
            local maxIncrease = 0.5
            local increase = 0.05 + rarityFactor * maxIncrease

            local percentage
            for _, weapon in pairs(weapons) do
                weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator + increase
                if percentage == nil then percentage = weapon.shieldDamageMultiplicator end
            end

            percentage = math.floor(percentage * 100 - 100)
            turret:addDescription("%s%% Damage to shields"%_T, string.format("%+i", percentage))

        elseif s == Specialty.SlightlyHigherShieldDamage then
            local maxIncrease = 0.25
            local increase = 0.1 + rarityFactor * maxIncrease

            local percentage
            for _, weapon in pairs(weapons) do
                weapon.shieldDamageMultiplicator = weapon.shieldDamageMultiplicator + increase
                if percentage == nil then percentage = weapon.shieldDamageMultiplicator end
            end

            percentage = math.floor(percentage * 100 - 100)
            turret:addDescription("%s%% Damage to shields"%_T, string.format("%+i", percentage))

        elseif s == Specialty.HighShootingTime then
            local maxIncrease = 2.9
            local increase = 0.1 + rarityFactor * maxIncrease

            local coolingTime = turret.coolingTime
            local shootingTime = turret.shootingTime

            shootingTime = shootingTime * (1 + increase)

            turret:clearWeapons()
            for _, weapon in pairs(weapons) do
                turret:addWeapon(weapon)
            end

            TurretGenerator.createStandardCooling(turret, coolingTime, shootingTime)

            weapons = {turret:getWeapons()}

            local percentage = math.floor(increase * 100)
            turret:addDescription("%s%% Shooting Until Overheated"%_T, string.format("%+i", percentage))

        elseif s == Specialty.LessCoolingTime then
            local maxDecrease = 0.6
            local decrease = 0.1 + rarityFactor * maxDecrease

            local coolingTime = turret.coolingTime
            local shootingTime = turret.shootingTime

            coolingTime = coolingTime * (1 - decrease)

            turret:clearWeapons()
            for _, weapon in pairs(weapons) do
                turret:addWeapon(weapon)
            end

            TurretGenerator.createStandardCooling(turret, coolingTime, shootingTime)

            weapons = {turret:getWeapons()}

            local percentage = math.floor(decrease * 100)
            turret:addDescription("%s%% Faster Cooling"%_T, string.format("%+i", percentage))

        elseif s == Specialty.LessEnergyConsumption then
            local before = turret.coolingType

            local maxDecrease = 0.4
            local decrease = 0.1 + rarityFactor * maxDecrease

            local energyPerSecond = turret.baseEnergyPerSecond
            local energyIncreasePerSecond = turret.energyIncreasePerSecond

            energyPerSecond = energyPerSecond * (1 - decrease)

            turret:clearWeapons()
            for _, weapon in pairs(weapons) do
                turret:addWeapon(weapon)
            end

            TurretGenerator.createPerShotEnergyCooling(turret, energyPerSecond, energyIncreasePerSecond)

            weapons = {turret:getWeapons()}

            local percentage = math.floor(decrease * 100)
            turret:addDescription("%s%% Energy /s"%_T, string.format("%+i", percentage))

            turret.coolingType = before

        elseif s == Specialty.LessEnergyConsumptionIncrease then
            local before = turret.coolingType

            local maxDecrease = 0.4
            local decrease = 0.1 + rarityFactor * maxDecrease

            local energyPerSecond = turret.baseEnergyPerSecond
            local energyIncreasePerSecond = turret.energyIncreasePerSecond

            energyIncreasePerSecond = energyIncreasePerSecond * (1 - decrease)

            turret:clearWeapons()
            for _, weapon in pairs(weapons) do
                turret:addWeapon(weapon)
            end

            TurretGenerator.createPerShotEnergyCooling(turret, energyPerSecond, energyIncreasePerSecond)

            weapons = {turret:getWeapons()}

            local percentage = math.floor(decrease * 100)
            turret:addDescription("%s%% Energy /s Increase"%_T, string.format("%+i", percentage))

            turret.coolingType = before

        elseif s == Specialty.ShieldPenetration then
            local maxChance = 0.4
            local chance = 0.01 + rarityFactor * maxChance

            for _, weapon in pairs(weapons) do
                weapon.shieldPenetration = chance
            end

            local percentage = math.floor(chance * 100 + 0.0000001) -- TODO rounding
            turret:addDescription("%s%% Chance of penetrating shields"%_T, string.format("%i", percentage))

        elseif s == Specialty.BurstFire then
            local fireRate = turret.fireRate
            local fireDelay = 1 / fireRate

            local increase = rand:getFloat(2, 3)
            fireRate = math.max(fireRate * increase, 6)

            local coolingTime = fireRate * fireDelay

            for _, weapon in pairs(weapons) do
                weapon.fireRate = fireRate / turret.numWeapons
            end

            turret:clearWeapons()
            for _, weapon in pairs(weapons) do
                turret:addWeapon(weapon)
            end

            -- time: 1 second
            TurretGenerator.createStandardCooling(turret, coolingTime, 1)

            weapons = {turret:getWeapons()}

        elseif s == Specialty.IonizedProjectile then
            local chance = rand:getFloat(0.7, 0.8)
            local varChance = 1 - chance
            chance = chance + rarityFactor * varChance

            for _, weapon in pairs(weapons) do
                weapon.shieldPenetration = chance
            end

            local percentage = math.floor(chance * 100 + 0.0000001) -- TODO rounding
            turret:addDescription("Ionized Projectiles"%_T, "")
            turret:addDescription("%s%% Chance of penetrating shields"%_T, string.format("%i", percentage))
        end
    end

    turret:clearWeapons()
    for _, weapon in pairs(weapons) do
        turret:addWeapon(weapon)
    end

    turret:updateStaticStats()
end


function TurretGenerator.generateBolterTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local weapons = {1, 2, 4}
    local numWeapons = weapons[rand:getInt(1, #weapons)]

    local weapon = WeaponGenerator.generateBolter(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    local shootingTime = 7 * rand:getFloat(0.9, 1.3)
    local coolingTime = 5 * rand:getFloat(0.8, 1.2)

    TurretGenerator.createStandardCooling(result, coolingTime, shootingTime)

    TurretGenerator.scale(rand, result, WeaponType.Bolter, tech, 0.9)
    TurretGenerator.addSpecialties(rand, result, WeaponType.Bolter)

    return result
end

function TurretGenerator.generateLaserTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 2)

    local weapon = WeaponGenerator.generateLaser(rand, dps, tech, material, rarity)
    weapon.damage = weapon.damage * numWeapons -- original = weapon.damage / numWeapons

    -- attach weapons to turret
    TurretGenerator.scale(rand, result, WeaponType.Laser, tech, 1)
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    local damageToEnergy = rand:getFloat(20, 25)
    local energyPerSecond = dps * damageToEnergy
    local increasePerSecond = energyPerSecond * rand:getFloat(0.05, 0.08)
    TurretGenerator.createContinuousEnergyCooling(result, energyPerSecond, increasePerSecond)

    TurretGenerator.addSpecialties(rand, result, WeaponType.Laser)

    return result
end

function TurretGenerator.generateChaingunTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 3)

    local weapon = WeaponGenerator.generateChaingun(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    -- chainguns don't need cooling
    TurretGenerator.scale(rand, result, WeaponType.ChainGun, tech, 1.2)
    TurretGenerator.addSpecialties(rand, result, WeaponType.ChainGun)

    return result
end

function TurretGenerator.generatePointDefenseChaingunTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(2, 3)

    local weapon = WeaponGenerator.generatePointDefenseChaingun(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    -- chainguns don't need cooling
    TurretGenerator.scale(rand, result, WeaponType.PointDefenseChainGun, tech, 2)
    TurretGenerator.addSpecialties(rand, result, WeaponType.PointDefenseChainGun)

    result:addDescription("Increased Damage to Fighters + Torpedoes"%_T, "")

    return result
end

function TurretGenerator.generatePointDefenseLaserTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = 1

    local weapon = WeaponGenerator.generatePointDefenseLaser(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    -- chainguns don't need cooling
    TurretGenerator.scale(rand, result, WeaponType.PointDefenseLaser, tech, 2)
    TurretGenerator.addSpecialties(rand, result, WeaponType.PointDefenseLaser)

    result:addDescription("Increased Damage to Fighters + Torpedoes"%_T, "")

    return result
end

function TurretGenerator.generateMiningTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Miner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 2)

    local weapon = WeaponGenerator.generateMiningLaser(rand, dps, tech, material, rarity)
    weapon.damage = weapon.damage * numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    local percentage = math.floor(weapon.stoneDamageMultiplicator * 50000)
    result:addDescription("%s%% Damage to Stone"%_T, string.format("%+i", percentage))

    -- normal mining lasers don't need cooling
    TurretGenerator.scale(rand, result, WeaponType.MiningLaser, tech, 1)
    TurretGenerator.addSpecialties(rand, result, WeaponType.MiningLaser)

    return result
end

function TurretGenerator.generateSalvagingTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Miner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 2)

    local weapon = WeaponGenerator.generateSalvagingLaser(rand, dps, tech, material, rarity)
    weapon.damage = weapon.damage * numWeapons -- original = weapon.damage / numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    -- normal mining lasers don't need cooling
    TurretGenerator.scale(rand, result, WeaponType.SalvagingLaser, tech, 1)
    TurretGenerator.addSpecialties(rand, result, WeaponType.SalvagingLaser)

    return result
end

function TurretGenerator.generateRawMiningTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Miner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 2)

    local weapon = WeaponGenerator.generateRawMiningLaser(rand, dps, tech, material, rarity)
    weapon.damage = weapon.damage * numWeapons -- original = weapon.damage / numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    local percentage = math.floor(weapon.stoneDamageMultiplicator * 50000)
    result:addDescription("%s%% Damage to Stone"%_T, string.format("%+i", percentage))

    -- normal mining lasers don't need cooling
    TurretGenerator.scale(rand, result, WeaponType.RawMiningLaser, tech, 1)
    TurretGenerator.addSpecialties(rand, result, WeaponType.RawMiningLaser)

    return result
end

function TurretGenerator.generateRawSalvagingTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Miner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 2)

    local weapon = WeaponGenerator.generateRawSalvagingLaser(rand, dps, tech, material, rarity)
    weapon.damage = weapon.damage * numWeapons -- original = weapon.damage / numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    -- normal mining lasers don't need cooling
    TurretGenerator.scale(rand, result, WeaponType.RawSalvagingLaser, tech, 1)
    TurretGenerator.addSpecialties(rand, result, WeaponType.RawSalvagingLaser)

    return result
end

function TurretGenerator.generatePlasmaTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 4)

    local weapon = WeaponGenerator.generatePlasmaGun(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    local damageToEnergy = rand:getFloat(10, 15)
    local energyPerSecond = dps * damageToEnergy
    local increasePerSecond = energyPerSecond * rand:getFloat(0.01, 0.1)
    TurretGenerator.createPerShotEnergyCooling(result, energyPerSecond, increasePerSecond)

    -- add further descriptions
    TurretGenerator.scale(rand, result, WeaponType.PlasmaGun, tech, 0.9)
    TurretGenerator.addSpecialties(rand, result, WeaponType.PlasmaGun)

    return result
end

function TurretGenerator.generateRocketTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 2)

    local weapon = WeaponGenerator.generateRocketLauncher(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- attach weapons to turret
    local positions = {}
    if rand:getBool() then
        table.insert(positions, vec3(0, 0.3, 0))
    else
        table.insert(positions, vec3(0.4, 0.3, 0))
        table.insert(positions, vec3(-0.4, 0.3, 0))
    end

    -- attach
    for _, position in pairs(positions) do
        weapon.localPosition = position * result.size
        result:addWeapon(weapon)
    end

    local shootingTime = 20 * rand:getFloat(0.8, 1.2)
    local coolingTime = 15 * rand:getFloat(0.8, 1.2)
    TurretGenerator.createStandardCooling(result, coolingTime, shootingTime)

    TurretGenerator.scale(rand, result, WeaponType.RocketLauncher, tech, 0.6)
    TurretGenerator.addSpecialties(rand, result, WeaponType.RocketLauncher)

    return result
end

function TurretGenerator.generateCannonTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 4)

    local weapon = WeaponGenerator.generateCannon(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    local shootingTime = 25 * rand:getFloat(0.8, 1.2)
    local coolingTime = 15 * rand:getFloat(0.8, 1.2)
    TurretGenerator.createStandardCooling(result, coolingTime, shootingTime)

    TurretGenerator.scale(rand, result, WeaponType.Cannon, tech, 0.6)
    TurretGenerator.addSpecialties(rand, result, WeaponType.Cannon)

    return result
end

function TurretGenerator.generateRailGunTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 3)

    local weapon = WeaponGenerator.generateRailGun(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    local shootingTime = 27.5 * rand:getFloat(0.8, 1.2)
    local coolingTime = 10 * rand:getFloat(0.8, 1.2)
    TurretGenerator.createStandardCooling(result, coolingTime, shootingTime)

    TurretGenerator.scale(rand, result, WeaponType.RailGun, tech, 0.75)
    TurretGenerator.addSpecialties(rand, result, WeaponType.RailGun)

    return result
end

function TurretGenerator.generateRepairBeamTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Repair))
    result.crew = crew

    -- generate weapons
    local weapon = WeaponGenerator.generateRepairBeamEmitter(rand, dps, tech, material, rarity)

    -- on rare occasions generate a turret that can do both shield and hull repair
    if rand:test(0.125) == true then
        weapon.localPosition = vec3(0.1, 0, 0)
        result:addWeapon(weapon)

        weapon.localPosition = vec3(-0.1, 0, 0)

        -- swap the two properties
        local shieldRepair = weapon.shieldRepair
        weapon.shieldRepair = weapon.hullRepair
        weapon.hullRepair = shieldRepair

        result:addWeapon(weapon)
    else
        -- just attach normally
        TurretGenerator.attachWeapons(rand, result, weapon, 1)
    end

    local damageToEnergy = rand:getFloat(10, 15)
    local energyPerSecond = dps * damageToEnergy
    local increasePerSecond = energyPerSecond * rand:getFloat(0.01, 0.03)
    TurretGenerator.createContinuousEnergyCooling(result, energyPerSecond, increasePerSecond)

    TurretGenerator.scale(rand, result, WeaponType.RepairBeam, tech, 1)
    TurretGenerator.addSpecialties(rand, result, WeaponType.RepairBeam)

    return result
end

function TurretGenerator.generateLightningTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 2)

    local weapon = WeaponGenerator.generateLightningGun(rand, dps, tech, material, rarity)
    weapon.damage = weapon.damage * numWeapons -- original = weapon.damage / numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    local damageToEnergy = rand:getFloat(10, 15)
    local energyPerSecond = dps * damageToEnergy
    local increasePerSecond = energyPerSecond * rand:getFloat(0.01, 0.03)
    TurretGenerator.createPerShotEnergyCooling(result, energyPerSecond, increasePerSecond)

    TurretGenerator.scale(rand, result, WeaponType.LightningGun, tech, 0.75)
    TurretGenerator.addSpecialties(rand, result, WeaponType.LightningGun)

    return result
end

function TurretGenerator.generateTeslaTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 2)

    local weapon = WeaponGenerator.generateTeslaGun(rand, dps, tech, material, rarity)
    weapon.damage = weapon.damage * numWeapons -- original = weapon.damage / numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    local damageToEnergy = rand:getFloat(10, 15)
    local energyPerSecond = dps * damageToEnergy
    local increasePerSecond = energyPerSecond * rand:getFloat(0.01, 0.03)
    TurretGenerator.createContinuousEnergyCooling(result, energyPerSecond, increasePerSecond)

    TurretGenerator.scale(rand, result, WeaponType.TeslaGun, tech, 1.2)
    TurretGenerator.addSpecialties(rand, result, WeaponType.TeslaGun)

    return result
end

function TurretGenerator.generateForceTurret(rand, force, tech, material, rarity)
    local result = TurretTemplate()

    -- generate weapons
    local numWeapons = rand:getInt(1, 2)

    local weapon = WeaponGenerator.generateForceGun(rand, force, tech, material, rarity)

    force = math.max(math.abs(weapon.selfForce), math.abs(weapon.otherForce))

    local requiredCrew = math.floor(1 + math.sqrt(force / 2000))
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Engine))
    result.crew = crew

    if weapon.otherForce ~= 0 then weapon.otherForce = weapon.otherForce / numWeapons end
    if weapon.selfForce ~= 0 then weapon.selfForce = weapon.selfForce / numWeapons end

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    -- add more beams, for this we add invisible weapons doing nothing but creating beams
    local weapons = {result:getWeapons()}
    for _, weapon in pairs(weapons) do
        weapon.selfForce = 0
        weapon.otherForce = 0
        weapon.bshape = BeamShape.Swirly
        weapon.bshapeSize = 1.25
        weapon.appearance = WeaponAppearance.Invisible
        result:addWeapon(weapon)
    end

    local forceToEnergy = rand:getFloat(1, 4)
    local energyPerSecond = force / 1000 * forceToEnergy
    local increasePerSecond = energyPerSecond * rand:getFloat(0.01, 0.03)
    TurretGenerator.createContinuousEnergyCooling(result, energyPerSecond, increasePerSecond)

    TurretGenerator.scale(rand, result, WeaponType.ForceGun, tech, 1)
    TurretGenerator.addSpecialties(rand, result, WeaponType.ForceGun)

    return result
end

function TurretGenerator.generatePulseTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 3)

    local weapon = WeaponGenerator.generatePulseCannon(rand, dps, tech, material, rarity)
    weapon.fireDelay = weapon.fireDelay * numWeapons

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    local shootingTime = 15 * rand:getFloat(1, 1.5)
    local coolingTime = 7.5 * rand:getFloat(1, 1.5)

    TurretGenerator.createStandardCooling(result, coolingTime, shootingTime)

    TurretGenerator.scale(rand, result, WeaponType.PulseCannon, tech, 1.2)
    TurretGenerator.addSpecialties(rand, result, WeaponType.PulseCannon)

    return result
end

function TurretGenerator.generateAntiFighterTurret(rand, dps, tech, material, rarity)
    local result = TurretTemplate()

    -- generate turret
    local requiredCrew = TurretGenerator.dpsToRequiredCrew(dps)
    local crew = Crew()
    crew:add(requiredCrew, CrewMan(CrewProfessionType.Gunner))
    result.crew = crew

    -- generate weapons
    local numWeapons = rand:getInt(1, 3)

    local weapon = WeaponGenerator.generateAntiFighterGun(rand, dps, tech, material, rarity)

    -- attach weapons to turret
    TurretGenerator.attachWeapons(rand, result, weapon, numWeapons)

    TurretGenerator.scale(rand, result, WeaponType.AntiFighter, tech, 1.2)
    TurretGenerator.addSpecialties(rand, result, WeaponType.AntiFighter)

    result:addDescription("Increased Damage to Fighters + Torpedoes"%_T, "")

    return result
end


local generatorFunction = {}
generatorFunction[WeaponType.ChainGun            ] = TurretGenerator.generateChaingunTurret
generatorFunction[WeaponType.PointDefenseChainGun] = TurretGenerator.generatePointDefenseChaingunTurret
generatorFunction[WeaponType.PointDefenseLaser   ] = TurretGenerator.generatePointDefenseLaserTurret
generatorFunction[WeaponType.Laser               ] = TurretGenerator.generateLaserTurret
generatorFunction[WeaponType.MiningLaser         ] = TurretGenerator.generateMiningTurret
generatorFunction[WeaponType.RawMiningLaser      ] = TurretGenerator.generateRawMiningTurret
generatorFunction[WeaponType.SalvagingLaser      ] = TurretGenerator.generateSalvagingTurret
generatorFunction[WeaponType.RawSalvagingLaser   ] = TurretGenerator.generateRawSalvagingTurret
generatorFunction[WeaponType.PlasmaGun           ] = TurretGenerator.generatePlasmaTurret
generatorFunction[WeaponType.RocketLauncher      ] = TurretGenerator.generateRocketTurret
generatorFunction[WeaponType.Cannon              ] = TurretGenerator.generateCannonTurret
generatorFunction[WeaponType.RailGun             ] = TurretGenerator.generateRailGunTurret
generatorFunction[WeaponType.RepairBeam          ] = TurretGenerator.generateRepairBeamTurret
generatorFunction[WeaponType.Bolter              ] = TurretGenerator.generateBolterTurret
generatorFunction[WeaponType.LightningGun        ] = TurretGenerator.generateLightningTurret
generatorFunction[WeaponType.TeslaGun            ] = TurretGenerator.generateTeslaTurret
generatorFunction[WeaponType.ForceGun            ] = TurretGenerator.generateForceTurret
generatorFunction[WeaponType.PulseCannon         ] = TurretGenerator.generatePulseTurret
generatorFunction[WeaponType.AntiFighter         ] = TurretGenerator.generateAntiFighterTurret

function TurretGenerator.generateTurret(rand, type, dps, tech, material, rarity)
    if rarity == nil then
        local index = rand:getValueOfDistribution(32, 32, 16, 8, 4, 1)

        rarity = Rarity(index - 1)
    end

    return generatorFunction[type](rand, dps, tech, material, rarity)
end


return TurretGenerator
