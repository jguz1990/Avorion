package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")

-- this key is sold by the travelling merchant

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true
Unique = true

function getNumTurrets(seed, rarity, permanent)
    return 30
end

function onInstalled(seed, rarity, permanent)
    if not permanent then return end
    addMultiplyableBias(StatsBonuses.UnarmedTurrets, getNumTurrets(seed, rarity, permanent))
end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    return "XSTN-K IV"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/key4.png"
end

function getPrice(seed, rarity)
    return 3000000
end

function getTooltipLines(seed, rarity, permanent)
    local texts =
    {
        {ltext = "Unarmed Turret Slots"%_t, rtext = "+" .. getNumTurrets(seed, rarity, permanent), icon = "data/textures/icons/turret.png", boosted = permanent}
    }

    if not permanent then
        return {}, texts
    else
        return texts, texts
    end
end

function getDescriptionLines(seed, rarity, permanent)
    return
    {
        {ltext = "This system has 4 vertical "%_t, rtext = "", icon = ""},
        {ltext = "scratches on its surface."%_t, rtext = "", icon = ""}
    }
end
