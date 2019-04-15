package.path = package.path .. ";data/scripts/lib/?.lua"

require ("galaxy")
require ("randomext")
local PlanGenerator = require ("plangenerator")
local WeaponGenerator = require ("weapongenerator")
require("weapontype")

local rand = random()

local FighterGenerator =  {}

function FighterGenerator.initialize(seed)
    if seed then
        rand = Random(seed)
    end
end

function FighterGenerator.generate(x, y, offset_in, rarity_in, type_in, material_in) -- server

    local offset = offset_in or 0
    local seed = rand:createSeed()
    local dps = 0
    local sector = math.floor(length(vec2(x, y))) + offset

    local weaponDPS, weaponTech = Balancing_GetSectorWeaponDPS(sector, 0)
    local miningDPS, miningTech = Balancing_GetSectorMiningDPS(sector, 0)
    local materialProbabilities = Balancing_GetTechnologyMaterialProbability(sector, 0)
    local material = material_in or Material(getValueFromDistribution(materialProbabilities))

    local weaponTypes = Balancing_GetWeaponProbability(sector, 0)
    weaponTypes[WeaponType.AntiFighter] = nil

    local weaponType = type_in or getValueFromDistribution(weaponTypes)

    miningDPS = miningDPS * 0.5
    weaponDPS = weaponDPS * 0.3

    local tech = 0
    if weaponType == WeaponType.MiningLaser then
        dps = miningDPS
        tech = miningTech
    elseif weaponType == WeaponType.ForceGun then
        dps = random():getFloat(800, 1200); -- force
        tech = weaponTech
    else
        dps = weaponDPS
        tech = weaponTech
    end

    local rarities = {}
    rarities[5] = 0.2 -- legendary
    rarities[4] = 1 -- exotic
    rarities[3] = 4 -- exceptional
    rarities[2] = 8 -- rare
    rarities[1] = 16 -- uncommon
    rarities[0] = 64 -- common

    local rarity = rarity_in or Rarity(getValueFromDistribution(rarities))

    return FighterGenerator.generateFighter(Random(seed), weaponType, dps, tech, material, rarity)
end

function FighterGenerator.generateArmed(x, y, offset_in, rarity_in, material_in) -- server

    local offset = offset_in or 0
    local sector = math.floor(length(vec2(x, y))) + offset
    local types = Balancing_GetWeaponProbability(sector, 0)

    types[WeaponType.RepairBeam] = nil
    types[WeaponType.MiningLaser] = nil
    types[WeaponType.SalvagingLaser] = nil
    types[WeaponType.ForceGun] = nil

    local weaponType = getValueFromDistribution(types)

    return FighterGenerator.generate(x, y, offset_in, rarity_in, weaponType, material_in)
end

function FighterGenerator.generateCargoShuttle(x, y, material_in) -- server

    local seed = rand:createSeed()

    local materialProbabilities = Balancing_GetTechnologyMaterialProbability(x, y)
    local material = material_in or Material(getValueFromDistribution(materialProbabilities))

    local fighter = FighterGenerator.generateUnarmedFighter(Random(seed), material)

    local plan = fighter.plan
    local container = PlanGenerator.makeContainerPlan()

    local size = 0.95 / container.radius
    container:scale(vec3(size, size, size))
    container:displace(vec3(0, -0.7, 0))
    plan:addPlan(plan.rootIndex, container, container.rootIndex)

    fighter.plan = plan
    fighter.type = FighterType.CargoShuttle

    return fighter
end



function FighterGenerator.generateFighter(rand, type, dps, tech, material, rarity)
    if type == nil then
        type = WeaponTypes.getRandom(rand)
    end

    local fighter = FighterGenerator.generateUnarmedFighter(rand, material)
    FighterGenerator.addWeapons(rand, type, dps, rarity, fighter, tech, material)

    return fighter
end

function FighterGenerator.addWeapons(rand, type, dps, rarity, fighter, tech, material)
    if type ~= WeaponType.AntiFighter then
        fighter:addWeapon(WeaponGenerator.generateWeapon(rand, type, dps, tech, material, rarity))
    end

    -- adjust fire rate of fighters so they don't slow down the simulation too much
    local weapons = {fighter:getWeapons()}
    fighter:clearWeapons()

    for _, weapon in pairs(weapons) do
        if weapon.isProjectile and weapon.fireRate > 2 then
            local old  = weapon.fireRate
            weapon.fireRate = rand:getFloat(1, 2)
            weapon.damage = weapon.damage * old / weapon.fireRate
        end

        fighter:addWeapon(weapon)
    end

    fighter:updateStaticStats()
end

function FighterGenerator.generateUnarmedFighter(rand, material)
    local fighter = FighterTemplate()

    local style = GenerateFighterStyle(rand:createSeed())
    local plan = GeneratePlanFromStyle(style, rand:createSeed(), 5000, 50, true, material)

    local diameter = rand:getFloat(fighter.minFighterDiameter, fighter.maxFighterDiameter)
    local scale = diameter / (plan.radius * 2)
    plan:scale(vec3(scale, scale, scale))

    fighter.plan = plan

    -- set crew
    fighter.crew = 1
    fighter.durability = rand:getFloat(5, 25) * material.strengthFactor
    fighter.turningSpeed = rand:getFloat(1, 2.5)
    fighter.maxVelocity = rand:getFloat(12.5, 25)
    fighter.diameter = diameter;

    if rand:test(0.2) then
        fighter.shield = rand:getFloat(5, 25) * material.strengthFactor
    end

    return fighter
end


return FighterGenerator
