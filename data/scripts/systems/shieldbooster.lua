package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")

-- dynamic stats
local rechargeReady = 0
local recharging = 0
local rechargeSpeed = 0

-- static stats
rechargeDelay = 300
rechargeTime = 5
rechargeAmount = 0.35

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

function getUpdateInterval()
    return 0.25
end

function updateServer(timePassed)
    rechargeReady = math.max(0, rechargeReady - timePassed)

    if recharging > 0 then
        recharging = recharging - timePassed
        Entity():healShield(rechargeSpeed * timePassed)
    end

end

function startCharging()

    if rechargeReady == 0 then
        local shield = Entity().shieldMaxDurability
        if shield > 0 then
            rechargeReady = rechargeDelay
            recharging = rechargeTime
            rechargeSpeed = shield * rechargeAmount / rechargeTime
        end
    end

end

function getBonuses(seed, rarity, permanent)
    math.randomseed(seed)

    local durability = 5 -- base value, in percent
    -- add flat percentage based on rarity
    durability = durability + (rarity.value + 1) * 15 -- add 0% (worst rarity) to +80% (best rarity)

    -- add randomized percentage, span is based on rarity
    durability = durability + math.random() * (rarity.value + 1) * 10 -- add random value between 0% (worst rarity) and +60% (best rarity)
    durability = durability * 0.8
    durability = durability / 100

    local recharge = 5 -- base value, in percent
    -- add flat percentage based on rarity
    recharge = recharge + rarity.value * 2 -- add -2% (worst rarity) to +10% (best rarity)

    -- add randomized percentage, span is based on rarity
    recharge = recharge + math.random() * (rarity.value * 2) -- add random value between -2% (worst rarity) and +10% (best rarity)
    recharge = recharge * 0.8
    recharge = recharge / 100

    -- probability for both of them being used
    -- when rarity.value >= 4, always both
    -- when rarity.value <= 0 always only one
    local probability = math.max(0, rarity.value * 0.25)
    if math.random() > probability then
        -- only 1 will be used
        if math.random() < 0.5 then
            durability = 0
        else
            recharge = 0
        end
    end

    local emergencyRecharge = 0

    if permanent then
        durability = durability * 1.5
        recharge = recharge * 1.5

        if rarity.value >= 2 then
            emergencyRecharge = 1
        end
    end

    return durability, recharge, emergencyRecharge
end

function onInstalled(seed, rarity, permanent)
    local durability, recharge, emergencyRecharge = getBonuses(seed, rarity, permanent)

    addBaseMultiplier(StatsBonuses.ShieldDurability, durability)
    addBaseMultiplier(StatsBonuses.ShieldRecharge, recharge)

    if emergencyRecharge == 1 then
        Entity():registerCallback("onShieldDeactivate", "startCharging")
    else
        -- delete this function so it won't be called by the game
        -- -> saves performance
        updateServer = nil
    end

end

function onUninstalled(seed, rarity, permanent)

end

function getName(seed, rarity)
    return "Shield Booster"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/shield.png"
end

function getEnergy(seed, rarity, permanent)
    local durability, recharge, emergencyRecharge = getBonuses(seed, rarity)
    return (durability * 0.75 + recharge * 2) * 1000 * 1000 * 1000
end

function getPrice(seed, rarity)
    local durability, recharge, emergencyRecharge = getBonuses(seed, rarity)
    local price = durability * 100 * 500 + recharge * 100 * 250 + emergencyRecharge * 15000
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)

    local texts = {}
    local bonuses = {}
    local durability, recharge, emergencyRecharge = getBonuses(seed, rarity, permanent)
    local baseDurability, baseRecharge, baseEmergencyRecharge = getBonuses(seed, rarity, false)
    local _, _, bonusEmergencyRecharge = getBonuses(seed, rarity, true)

    if durability ~= 0 then
        table.insert(texts, {ltext = "Shield Durability"%_t, rtext = string.format("%+i%%", durability * 100), icon = "data/textures/icons/health-normal.png", boosted = permanent})
        table.insert(bonuses, {ltext = "Shield Durability"%_t, rtext = string.format("%+i%%", baseDurability * 0.5 * 100), icon = "data/textures/icons/health-normal.png"})
    end

    if recharge ~= 0 then
        table.insert(texts, {ltext = "Shield Recharge Rate"%_t, rtext = string.format("%+i%%", recharge * 100), icon = "data/textures/icons/shield-charge.png", boosted = permanent})
        table.insert(bonuses, {ltext = "Shield Recharge Rate"%_t, rtext = string.format("%+i%%", baseRecharge * 0.5 * 100), icon = "data/textures/icons/shield-charge.png"})
    end

    if emergencyRecharge ~= 0 then
        table.insert(texts, {ltext = "Emergency Recharge"%_t, rtext = string.format("%i%%", rechargeAmount * 100), icon = "data/textures/icons/shield-charge.png", boosted = permanent})
    end

    if bonusEmergencyRecharge ~= 0 then
        table.insert(bonuses, {ltext = string.format("Upon depletion: Recharges %i%% of your shield."%_t, rechargeAmount * 100)})
    end

    return texts, bonuses
end

function getDescriptionLines(seed, rarity, permanent)
    local durability, recharge, emergencyRecharge = getBonuses(seed, rarity, permanent)

    local texts = {}

    if emergencyRecharge ~= 0 then
        table.insert(texts, {ltext = string.format("Upon depletion: Recharges %i%% of your shield."%_t, rechargeAmount * 100)})
        table.insert(texts, {ltext = plural_t("This effect can only occur every minute", "This effect can only occur every ${i} minutes.", round(rechargeDelay / 60))})
    end

    return texts
end
