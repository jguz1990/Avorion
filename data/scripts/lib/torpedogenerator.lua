package.path = package.path .. ";data/scripts/lib/?.lua"

require ("galaxy")
require ("randomext")

local rand = random()

local TorpedoGenerator =  {}

local blue = ColorRGB(0.2, 0.2, 1.0)
local red = ColorRGB(1.0, 0.2, 0.2)
local yellow = ColorRGB(0.8, 0.8, 0.2)

local BodyType =
{
    Orca = 1,
    Hammerhead = 2,
    Stingray = 3,
    Ocelot = 4,
    Lynx = 5,
    Panther = 6,
    Osprey = 7,
    Eagle = 8,
    Hawk = 9,
}
TorpedoGenerator.BodyType = BodyType

local Bodies = {}
table.insert(Bodies, {type = BodyType.Orca,        name = "Orca"%_T,        velocity = 1, agility = 1, stripes = 1, size = 1.0, reach = 4, color = blue})
table.insert(Bodies, {type = BodyType.Hammerhead,  name = "Hammerhead"%_T,  velocity = 1, agility = 2, stripes = 2, size = 1.0, reach = 5, color = blue})
table.insert(Bodies, {type = BodyType.Stingray,    name = "Stingray"%_T,    velocity = 1, agility = 3, stripes = 3, size = 1.0, reach = 6, color = blue})
table.insert(Bodies, {type = BodyType.Ocelot,      name = "Ocelot"%_T,      velocity = 2, agility = 1, stripes = 1, size = 1.0, reach = 5, color = red})
table.insert(Bodies, {type = BodyType.Lynx,        name = "Lynx"%_T,        velocity = 2, agility = 2, stripes = 2, size = 1.0, reach = 6, color = red})
table.insert(Bodies, {type = BodyType.Panther,     name = "Panther"%_T,     velocity = 2, agility = 3, stripes = 3, size = 1.0, reach = 7, color = red})
table.insert(Bodies, {type = BodyType.Osprey,      name = "Osprey"%_T,      velocity = 3, agility = 1, stripes = 1, size = 1.0, reach = 6, color = yellow})
table.insert(Bodies, {type = BodyType.Eagle,       name = "Eagle"%_T,       velocity = 3, agility = 2, stripes = 2, size = 1.0, reach = 7, color = yellow})
table.insert(Bodies, {type = BodyType.Hawk,        name = "Hawk"%_T,        velocity = 3, agility = 3, stripes = 3, size = 1.0, reach = 8, color = yellow})

local WarheadType =
{
    Nuclear = 1,
    Neutron = 2,
    Fusion = 3,
    Tandem = 4,
    Kinetic = 5,
    Ion = 6,
    Plasma = 7,
    Sabot = 8,
    EMP = 9,
    AntiMatter = 10,
}
TorpedoGenerator.WarheadType = WarheadType


local Warheads = {}
table.insert(Warheads, {type = WarheadType.Nuclear,     name = "Nuclear"%_T,        hull = 1,     shield = 1,       size = 1.0, color = ColorRGB(0.8, 0.8, 0.8)})
table.insert(Warheads, {type = WarheadType.Neutron,     name = "Neutron"%_T,        hull = 3,     shield = 1,       size = 1.0, color = ColorRGB(0.8, 0.8, 0.3)})
table.insert(Warheads, {type = WarheadType.Fusion,      name = "Fusion"%_T,         hull = 1,     shield = 3,       size = 1.0, color = ColorRGB(1.0, 0.4, 0.1)})
table.insert(Warheads, {type = WarheadType.Tandem,      name = "Tandem"%_T,         hull = 1.5,   shield = 2,       size = 1.0, color = ColorRGB(0.8, 0.2, 0.2), shieldAndHullDamage = true})
table.insert(Warheads, {type = WarheadType.Kinetic,     name = "Kinetic"%_T,        hull = 2.5,   shield = 0.25,    size = 1.0, color = ColorRGB(0.7, 0.3, 0.7), damageVelocityFactor = true})
table.insert(Warheads, {type = WarheadType.Ion,         name = "Ion"%_T,            hull = 0.25,  shield = 3,       size = 1.0, color = ColorRGB(0.2, 0.7, 1.0), energyDrain = true})
table.insert(Warheads, {type = WarheadType.Plasma,      name = "Plasma"%_T,         hull = 1,     shield = 5,       size = 1.0, color = ColorRGB(0.2, 0.8, 0.2)})
table.insert(Warheads, {type = WarheadType.Sabot,       name = "Sabot"%_T,          hull = 2,     shield = 0,       size = 1.0, color = ColorRGB(1.0, 0.1, 0.5), penetrateShields = true})
table.insert(Warheads, {type = WarheadType.EMP,         name = "EMP"%_T,            hull = 0,     shield = 0.025,   size = 1.0, color = ColorRGB(0.3, 0.3, 0.9), deactivateShields = true})
table.insert(Warheads, {type = WarheadType.AntiMatter,  name = "Anti-Matter"%_T,    hull = 8,     shield = 6,       size = 1.0, color = ColorRGB(0.2, 0.2, 0.2), storageEnergyDrain = 50000000})
TorpedoGenerator.Warheads = Warheads


function TorpedoGenerator.initialize(seed)
    if seed then
        rand = Random(seed)
    end
end

function TorpedoGenerator.getBodyProbability(x, y)
    local distFromCenter = length(vec2(x, y)) / Balancing_GetMaxCoordinates()

    local data = {}

    data[BodyType.Orca] =       {p = 1.0}
    data[BodyType.Hammerhead] = {d = 0.8, p = 1.5}
    data[BodyType.Ocelot] =     {d = 0.8, p = 1.5}
    data[BodyType.Stingray] =   {d = 0.6, p = 2.0}
    data[BodyType.Lynx] =       {d = 0.6, p = 2.0}
    data[BodyType.Osprey] =     {d = 0.6, p = 2.0}
    data[BodyType.Panther] =    {d = 0.45, p = 2.5}
    data[BodyType.Eagle] =      {d = 0.45, p = 2.5}
    data[BodyType.Hawk] =       {d = 0.35, p = 3.0}

    local probabilities = {}

    for t, specs in pairs(data) do
        if not specs.d or distFromCenter < specs.d then
            probabilities[t] = specs.p
        end
    end

    return probabilities
end

function TorpedoGenerator.getWarheadProbability(x, y)
    local distFromCenter = length(vec2(x, y)) / Balancing_GetMaxCoordinates()

    local data = {}

    data[WarheadType.Nuclear] =    {p = 1.0}
    data[WarheadType.Neutron] =    {d = 0.8, p = 1.5}
    data[WarheadType.Fusion] =     {d = 0.8, p = 1.5}
    data[WarheadType.Tandem] =     {d = 0.65, p = 2.0}
    data[WarheadType.Kinetic] =    {d = 0.65, p = 2.0}
    data[WarheadType.Ion] =        {d = 0.5, p = 2.5}
    data[WarheadType.Plasma] =     {d = 0.5, p = 2.5}
    data[WarheadType.Sabot] =      {d = 0.35, p = 3.0}
    data[WarheadType.EMP] =        {d = 0.35, p = 3.0}
    data[WarheadType.AntiMatter] = {d = 0.25, p = 3.5}

    local probabilities = {}

    for t, specs in pairs(data) do
        if not specs.d or distFromCenter < specs.d then
            probabilities[t] = specs.p
        end
    end

    return probabilities
end

function TorpedoGenerator.generate(x, y, offset_in, rarity_in, warhead_in, body_in) -- server

    local offset = offset_in or 0
    local seed = rand:createSeed()
    local sector = math.floor(length(vec2(x, y))) + offset

    local dps, tech = Balancing_GetSectorWeaponDPS(sector, 0)
    dps = dps * Balancing_GetSectorTurretsUnrounded(sector, 0) -- remove turret bias

    local rarities = {}
    rarities[5] = 0.1 -- legendary
    rarities[4] = 1 -- exotic
    rarities[3] = 8 -- exceptional
    rarities[2] = 16 -- rare
    rarities[1] = 0 -- uncommon
    rarities[0] = 0 -- common

    local rarity = rarity_in or Rarity(getValueFromDistribution(rarities))

    local bodyProbabilities = TorpedoGenerator.getBodyProbability(sector, 0)
    local body = Bodies[selectByWeight(rand, bodyProbabilities)]
    if body_in then body = Bodies[body_in] end

    local warheadProbabilities = TorpedoGenerator.getWarheadProbability(sector, 0)

    local torpedo = TorpedoTemplate()
    torpedo.type = warhead_in or selectByWeight(rand, warheadProbabilities)
    local warhead = Warheads[torpedo.type]

    -- normal properties
    torpedo.rarity = rarity
    torpedo.tech = tech
    torpedo.size = round(body.size * warhead.size, 1)

    -- body properties
    torpedo.durability = (2 + tech / 10) * (rarity.value + 1) + 4;
    torpedo.turningSpeed = 0.3 + 0.1 * ((body.agility * 2) - 1) * 5
    torpedo.maxVelocity = 250 + 100 * body.velocity * 2
    torpedo.reach = (body.reach * 4 + 3 * rarity.value) * 150 * 2

    -- warhead properties
    local damage = dps * (1 + rarity.value * 0.25) * 10

    torpedo.shieldDamage = round(damage * warhead.shield / 100) * 100
    torpedo.hullDamage = round(damage * warhead.hull / 100) * 100
    torpedo.shieldPenetration = warhead.penetrateShields or false
    torpedo.shieldDeactivation = warhead.deactivateShields or false
    torpedo.shieldAndHullDamage = warhead.shieldAndHullDamage or false
    torpedo.energyDrain = warhead.energyDrain or false
    torpedo.storageEnergyDrain = (warhead.storageEnergyDrain or 0.0) * tech
    torpedo.acceleration = 0.5 * torpedo.maxVelocity * torpedo.maxVelocity / 1000 -- reach max velocity after 10km of travelled way

    if warhead.damageVelocityFactor then
        -- scale to normal dps damage dependent on maxVelocity
        torpedo.damageVelocityFactor = damage * warhead.hull / torpedo.maxVelocity
        torpedo.maxVelocity = torpedo.maxVelocity * 2.0
        torpedo.hullDamage = 0
    end

    -- torpedo visuals
    torpedo.visualSeed = rand:getInt()
    torpedo.stripes = body.stripes
    torpedo.stripeColor = body.color
    torpedo.headColor = warhead.color
    torpedo.prefix = warhead.name
    torpedo.name = "${speed}-Class ${warhead} Torpedo"%_T % {speed = body.name, warhead = warhead.name}
    torpedo.icon = "data/textures/icons/missile-pod.png"

    -- impact visuals
    torpedo.numShockwaves = 1
    torpedo.shockwaveSize = 5000
    torpedo.shockwaveDuration = 5
    --torpedo.shockwaveColor = ColorRGB(0.9, 0.6, 0.3)
    torpedo.shockwaveColor = ColorRGB(0.1, 0.3, 1.2) -- this looks cool :)
    torpedo.explosionSize = 500
    torpedo.flashSize = 1000
    torpedo.flashDuration = 10

    return torpedo
end

return TorpedoGenerator
