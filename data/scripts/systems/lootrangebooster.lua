package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require("utility")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getLootCollectionRange(seed, rarity, permanent)
    local range = (rarity.value + 2) * 2 * (1.3 ^ rarity.value) * 5 -- one unit is 10 meters

    if permanent then
        range = (range * 3) * 2
    end

    range = round(range)

    return range
end

function onInstalled(seed, rarity, permanent)
    addAbsoluteBias(StatsBonuses.LootCollectionRange, getLootCollectionRange(seed, rarity, permanent))
end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    return "RCN-00 Tractor Beam Upgrade MK ${mark}"%_t % {mark = toRomanLiterals(rarity.value + 2)}
end

function getIcon(seed, rarity)
    return "data/textures/icons/sell.png"
end

function getEnergy(seed, rarity, permanent)
    local range = getLootCollectionRange(seed, rarity)
    return range * 20 * 1000 * 1000 / (1.1 ^ rarity.value) / 5
end

function getPrice(seed, rarity)
    return 500 * getLootCollectionRange(seed, rarity) / 5
end

function getTooltipLines(seed, rarity, permanent)
    local range = getLootCollectionRange(seed, rarity, permanent)
    local baseRange = getLootCollectionRange(seed, rarity, false)

    return
    {
        {ltext = "Loot Collection Range"%_t, rtext = "+${distance} km"%_t % {distance = range / 100}, icon = "data/textures/icons/sell.png", boosted = permanent}
    },
    {
        {ltext = "Loot Collection Range"%_t, rtext = "+${distance} km"%_t % {distance = baseRange * 2 / 100}, icon = "data/textures/icons/sell.png"}
    }
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "Gotta catch 'em all!"%_t, lcolor = ColorRGB(1, 0.5, 0.5)}
    }
end
