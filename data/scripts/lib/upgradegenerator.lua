
package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("galaxy")
require ("randomext")
require ("utility")

local rand = nil

local scripts = {}
local weights = {}

local UpgradeGenerator = {}

function UpgradeGenerator.add(script, weight)
    table.insert(scripts, script)
    table.insert(weights, weight)
end

-- turrets
UpgradeGenerator.add("data/scripts/systems/arbitrarytcs.lua", 1)
UpgradeGenerator.add("data/scripts/systems/militarytcs.lua", 1)
UpgradeGenerator.add("data/scripts/systems/civiltcs.lua", 1)
UpgradeGenerator.add("data/scripts/systems/bulktcs.lua", 1)


-- simple boosters
UpgradeGenerator.add("data/scripts/systems/batterybooster.lua", 1)
UpgradeGenerator.add("data/scripts/systems/cargoextension.lua", 1)
UpgradeGenerator.add("data/scripts/systems/energybooster.lua", 1)
UpgradeGenerator.add("data/scripts/systems/enginebooster.lua", 1)
UpgradeGenerator.add("data/scripts/systems/hyperspacebooster.lua", 1)
UpgradeGenerator.add("data/scripts/systems/radarbooster.lua", 1)
UpgradeGenerator.add("data/scripts/systems/shieldbooster.lua", 1)
UpgradeGenerator.add("data/scripts/systems/lootrangebooster.lua", 1)
UpgradeGenerator.add("data/scripts/systems/scannerbooster.lua", 1)
UpgradeGenerator.add("data/scripts/systems/shadokenergybooster.lua", 1)

-- special upgrades
UpgradeGenerator.add("data/scripts/systems/miningsystem.lua", 1)
UpgradeGenerator.add("data/scripts/systems/tradingoverview.lua", 1)
UpgradeGenerator.add("data/scripts/systems/valuablesdetector.lua", 1)
UpgradeGenerator.add("data/scripts/systems/shieldimpenetrator.lua", 1)
UpgradeGenerator.add("data/scripts/systems/energytoshieldconverter.lua", 1)
UpgradeGenerator.add("data/scripts/systems/transportersoftware.lua", 1)
UpgradeGenerator.add("data/scripts/systems/velocitybypass.lua", 1)


function UpgradeGenerator.initialize(seed)
    if seed then
        rand = Random(seed)
    else
        rand = random()
    end

    for i = 1, 624 do
        rand:getInt()
    end

end

function UpgradeGenerator.getProbabilities()
    local rarities = {}

    table.insert(rarities, Rarity(-1))
    table.insert(rarities, Rarity(0))
    table.insert(rarities, Rarity(1))
    table.insert(rarities, Rarity(2))
    table.insert(rarities, Rarity(3))
    table.insert(rarities, Rarity(4))
    table.insert(rarities, Rarity(5))

    local weights = {}

    table.insert(weights, 0)
    table.insert(weights, 0)
    table.insert(weights, 0)
    table.insert(weights, 8)
    table.insert(weights, 4)
    table.insert(weights, 1)
    table.insert(weights, 0.2)

    return rarities, weights
end

function UpgradeGenerator.getSectorProbabilities(x, y)
    local rarities = {}

    table.insert(rarities, Rarity(-1))
    table.insert(rarities, Rarity(0))
    table.insert(rarities, Rarity(1))
    table.insert(rarities, Rarity(2))
    table.insert(rarities, Rarity(3))
    table.insert(rarities, Rarity(4))
    table.insert(rarities, Rarity(5))

    local weights = {}
    local pos = length(vec2(x, y)) / (Balancing_GetDimensions() / 2) -- 0 (center) to 1 (edge) to ~1.5 (corner)

    table.insert(weights, 0) -- 16 at edge, 2 in center
    table.insert(weights, 0) -- 48 at edge, 8 in center
    table.insert(weights, 0) -- 16 at edge, 8 in center
    table.insert(weights, 8)
    table.insert(weights, 4)
    table.insert(weights, 1)
    table.insert(weights, 0.2)

    return rarities, weights
end

function UpgradeGenerator.generateSectorSystem(x, y)
    local rarities, rweights = UpgradeGenerator.getSectorProbabilities(x, y)

    local rarity = rarities[selectByWeight(rand, rweights)]
    local script = scripts[selectByWeight(rand, weights)]

    return SystemUpgradeTemplate(script, rarity, rand:createSeed())
end

function UpgradeGenerator.generateSystem(rarity, weights_in)

    if rarity == nil then
        local rarities, rweights = UpgradeGenerator.getProbabilities()
        rweights = weights_in or rweights

        rarity = rarities[selectByWeight(rand, rweights)]
    end

    local script = scripts[selectByWeight(rand, weights)]

    return SystemUpgradeTemplate(script, rarity, rand:createSeed())
end

UpgradeGenerator.scripts = scripts

return UpgradeGenerator