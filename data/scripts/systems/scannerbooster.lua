package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("randomext")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    local scanner = 1

    scanner = 5 -- base value, in percent
    -- add flat percentage based on rarity
    scanner = scanner + (rarity.value + 2) * 15 -- add +15% (worst rarity) to +105% (best rarity)

    -- add randomized percentage, span is based on rarity
    scanner = scanner + math.random() * ((rarity.value + 1) * 15) -- add random value between +0% (worst rarity) and +90% (best rarity)
    scanner = scanner / 100

    if permanent then
        scanner = scanner * 2
    end

    return scanner
end

function onInstalled(seed, rarity, permanent)
    local scanner = getBonuses(seed, rarity, permanent)

    addBaseMultiplier(StatsBonuses.ScannerReach, scanner)
end

function onUninstalled(seed, rarity, permanent)

end

function getName(seed, rarity)
    return "Scanner Upgrade"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/signal-range.png"
end

function getEnergy(seed, rarity, permanent)
    local scanner = getBonuses(seed, rarity)
    return scanner * 550 * 1000 * 1000
end

function getPrice(seed, rarity)
    local scanner = getBonuses(seed, rarity)
    local price = scanner * 100 * 250
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local bonuses = {}
    local scanner = getBonuses(seed, rarity, permanent)
    local baseScanner = getBonuses(seed, rarity, false)

    if scanner ~= 0 then
        table.insert(texts, {ltext = "Scanner Range"%_t, rtext = string.format("%+i%%", scanner * 100), icon = "data/textures/icons/signal-range.png", boosted = permanent})
        table.insert(bonuses, {ltext = "Scanner Range"%_t, rtext = string.format("%+i%%", baseScanner * 100), icon = "data/textures/icons/signal-range.png"})
    end

    return texts, bonuses
end

