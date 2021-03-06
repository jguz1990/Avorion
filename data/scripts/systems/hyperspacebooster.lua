package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    local reach = 0
    local cdfactor = 0
    local efactor = 0
    local radar = 0

    -- probability for both of them being used
    local numBonuses = 1

    if rarity.value >= 4 then numBonuses = 4
    elseif rarity.value == 3 then numBonuses = getInt(3, 4)
    elseif rarity.value == 2 then numBonuses = getInt(3, 4)
    elseif rarity.value == 1 then numBonuses = 3
    end

    -- pick bonuses
    local bonuses = {}
    bonuses[StatsBonuses.HyperspaceReach] = 1.5
    bonuses[StatsBonuses.HyperspaceCooldown] = 1
    bonuses[StatsBonuses.HyperspaceRechargeEnergy] = 0.75
    bonuses[StatsBonuses.RadarReach] = 0.25

    local enabled = {}

    for i = 1, numBonuses do
        local bonus = selectByWeight(random(), bonuses)
        enabled[bonus] = 1
        bonuses[bonus] = nil -- remove from list so it wont be picked again
    end

    if enabled[StatsBonuses.HyperspaceReach] then
        reach = math.max(1, rarity.value + 1)
    end

    if enabled[StatsBonuses.HyperspaceCooldown] then
        cdfactor = 10 -- 10% base value (10%)
        cdfactor = cdfactor + (rarity.value * 5) -- add 0% (worst rarity) to +25% (best rarity) (10-35%)
        cdfactor = cdfactor + math.random(20) -- add random value between 1% and 20% (35-55%)
        cdfactor = -cdfactor / 100
    end

    if enabled[StatsBonuses.HyperspaceRechargeEnergy] then
        efactor = 5 -- base value, in percent
        -- add flat percentage based on rarity
        efactor = efactor + (rarity.value + 1) * 3 -- add 0% (worst rarity) to +18% (best rarity)

        -- add randomized percentage, span is based on rarity
        efactor = efactor + math.random() * ((rarity.value + 1) * 4) -- add random value between 0% (worst rarity) and +24% (best rarity)
        efactor = -efactor / 100
    end

    if enabled[StatsBonuses.RadarReach] then
        radar = math.max(0, getInt(rarity.value, rarity.value * 2.0)) + 1
    end

    if permanent then
        reach = reach * 2.5 + rarity.value
        radar = radar * 1.5
    else
        cdfactor = 0
    end

    return reach, cdfactor, efactor, radar
end

function onInstalled(seed, rarity, permanent)
    local reach, cooldown, energy, radar = getBonuses(seed, rarity, permanent)

    addMultiplyableBias(StatsBonuses.HyperspaceReach, reach)
    addBaseMultiplier(StatsBonuses.HyperspaceCooldown, cooldown)
    addBaseMultiplier(StatsBonuses.HyperspaceRechargeEnergy, energy)
    addMultiplyableBias(StatsBonuses.RadarReach, radar)
end

function onUninstalled(seed, rarity, permanent)

end

function getName(seed, rarity)
    local reach, cooldown, energy, radar = getBonuses(seed, rarity)

    local num = ""
    if reach > 0 then
        num = toRomanLiterals(math.floor(reach * 0.75)) .. " "
    end

    return "Quantum ${num}Hyperspace Upgrade"%_t % {num = num}
end

function getIcon(seed, rarity)
    return "data/textures/icons/vortex.png"
end

function getEnergy(seed, rarity, permanent)
    local reach, cdfactor, efactor, radar = getBonuses(seed, rarity, permanent)
    return math.abs(cdfactor) * 2.5 * 1000 * 1000 * 1000 + reach * 125 * 1000 * 1000 + radar * 75 * 1000 * 1000
end

function getPrice(seed, rarity)
    local reach, _, efactor, radar = getBonuses(seed, rarity, false)
    local _, cdfactor, _, _ = getBonuses(seed, rarity, true)
    local price = math.abs(cdfactor) * 100 * 350 + math.abs(efactor) * 100 * 250 + reach * 3000 + radar * 450
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local bonuses = {}
    local reach, _, efactor, radar = getBonuses(seed, rarity, permanent)
    local baseReach, _, _, baseRadar = getBonuses(seed, rarity, false)
    local _, cdfactor, _, _ = getBonuses(seed, rarity, true)

    if reach ~= 0 then
        table.insert(texts, {ltext = "Jump Range"%_t, rtext = string.format("%+i", reach), icon = "data/textures/icons/star-cycle.png", boosted = permanent})
        table.insert(bonuses, {ltext = "Jump Range"%_t, rtext = string.format("%+i", baseReach * 1.5 + rarity.value), icon = "data/textures/icons/star-cycle.png", boosted = permanent})
    end

    if radar ~= 0 then
        table.insert(texts, {ltext = "Radar Range"%_t, rtext = string.format("%+i", radar), icon = "data/textures/icons/radar-sweep.png", boosted = permanent})
        table.insert(bonuses, {ltext = "Radar Range"%_t, rtext = string.format("%+i", baseRadar * 0.5), icon = "data/textures/icons/radar-sweep.png", boosted = permanent})
    end

    if cdfactor ~= 0 then
        if permanent then
            table.insert(texts, {ltext = "Hyperspace Cooldown"%_t, rtext = string.format("%+i%%", cdfactor * 100), icon = "data/textures/icons/hourglass.png", boosted = permanent})
        end
        table.insert(bonuses, {ltext = "Hyperspace Cooldown"%_t, rtext = string.format("%+i%%", cdfactor * 100), icon = "data/textures/icons/hourglass.png", boosted = permanent})
    end

    if efactor ~= 0 then
        table.insert(texts, {ltext = "Recharge Energy"%_t, rtext = string.format("%+i%%", efactor * 100), icon = "data/textures/icons/electric.png"})
    end

    if #bonuses == 0 then bonuses = nil end

    return texts, bonuses
end
