package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    local amplification = 20
    -- add flat percentage based on rarity
    amplification = amplification + (rarity.value + 1) * 15 -- add 0% (worst rarity) to +120% (best rarity)

    -- add randomized percentage, span is based on rarity
    amplification = amplification + math.random() * (rarity.value + 1) * 10 -- add random value between 0% (worst rarity) and +60% (best rarity)
    amplification = amplification / 100

    energy = -amplification * 0.4 / (1.1 ^ rarity.value) -- note the minus

    amplification = amplification * 0.8
    if permanent then
        amplification = amplification * 1.4
    end

    return amplification, energy
end

function getEnergyChange(seed, rarity)
end

function onInstalled(seed, rarity, permanent)
    local amplification, energy = getBonuses(seed, rarity, permanent)

    addBaseMultiplier(StatsBonuses.ShieldDurability, amplification)
    addBaseMultiplier(StatsBonuses.GeneratedEnergy, energy)
end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    return "Energy to Shield Converter"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/shield.png"
end

function getPrice(seed, rarity)
    local amplification = getBonuses(seed, rarity)
    local price = 7500 * amplification;
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)
    local texts = {}
    local bonuses = {}
    local amplification, energy = getBonuses(seed, rarity, permanent)
    local baseAmplification, baseEnergy = getBonuses(seed, rarity, false)

    table.insert(texts, {ltext = "Shield Durability"%_t, rtext = string.format("%+i%%", amplification * 100), icon = "data/textures/icons/health-normal.png", boosted = permanent})
    table.insert(bonuses, {ltext = "Shield Durability"%_t, rtext = string.format("%+i%%", baseAmplification * 0.4 * 100), icon = "data/textures/icons/health-normal.png"})

    table.insert(texts, {ltext = "Generated Energy"%_t, rtext = string.format("%i%%", energy * 100), icon = "data/textures/icons/electric.png"})

    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Re-routes energy to shields"%_t, rtext = "", icon = ""}
    }
end
