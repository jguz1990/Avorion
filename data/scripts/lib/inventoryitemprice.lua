package.path = package.path .. ";data/scripts/lib/?.lua"
require ("utility")

function ArmedObjectPrice(object)

    local costFactor = 1.0

    -- collect turret stats
    local dps = object.dps
    local material = object.material

    if object.coolingType == 0 and object.heatPerShot > 0 then
        dps = dps * object.shootingTime / (object.shootingTime + object.coolingTime)
    end

    dps = dps + dps * object.shieldDamageMultiplicator + dps * object.hullDamageMultiplicator

    dps = dps + object.hullRepairRate * 2.0 + object.shieldRepairRate * 3.0
    dps = dps + math.abs(object.selfForce) * 0.005 + math.abs(object.otherForce) * 0.01

    local value = dps * 0.5 * object.reach * 0.5

    -- mining laser value scales with the used material and the efficiency
    if object.stoneRefinedEfficiency > 0 or object.stoneRawEfficiency > 0 then
        costFactor = 3.0

        local materialFactor = material.strengthFactor * 5.0
        local efficiencyFactor = object.stoneRefinedEfficiency * 25.0 + object.stoneRawEfficiency * 8.0

        value = value * materialFactor
        value = value * (1.0 + efficiencyFactor) / 4
    end

    if object.metalRefinedEfficiency > 0 or object.metalRawEfficiency > 0 then
        costFactor = 3.0

        local efficiencyFactor = object.metalRefinedEfficiency * 25.0 + object.metalRawEfficiency * 8.0
        value = value * (1.0 + efficiencyFactor) / 4
    end

    -- rocket launchers gain value if they fire seeker rockets
    if object.seeker then
        value = value * 2.5
    end

    --value = value * 1.5
    local rarityFactor = 1.0 + 1.35 ^ object.rarity.value

    value = value * rarityFactor
    value = value * (1.0 + object.shieldPenetration)
    value = value * costFactor

    -- check for numerical errors that can occur by changing weapon stats to things like NaN or inf
    value = math.max(0, value)
    if value ~= value then value = 0 end
    if not (value > -math.huge and value < math.huge) then value = 0 end

    return value
end

function FighterPrice(fighter)
    local value = ArmedObjectPrice(fighter) * 3.0

    if value == 0 then
        value = 100000
    end

    -- the smaller the fighter, the more expensive
    local sizeFactor = lerp(fighter.diameter, 1, 2, 1.3, 1)
    value = value * sizeFactor

    -- durability of 100 makes the fighter twice as expensive, 200 three times etc.
    local hpFactor = fighter.durability / 150 + 1
    value = value * hpFactor

    -- speed of 20 is median, above makes it more expensive, below makes it cheaper
    local speedFactor = fighter.maxVelocity / 40
    value = value * speedFactor

    -- maneuverability of 2 is median, above makes it more expensive, below makes it cheaper
    local maneuverFactor = fighter.turningSpeed / 2
    value = value * maneuverFactor

    value = round(value)

    return value / 80
end

function TorpedoPrice(torpedo)

    -- print ("## price calculation for " .. torpedo.rarity.name .. " " .. torpedo.name)
    local value = 0

    -- primary stat: damage value, calculation is very similar to turrets
    local damageValue = (torpedo.hullDamage + torpedo.shieldDamage) * 0.5 -- use the average since usually only either one will be dealt
    damageValue = damageValue + torpedo.maxVelocity * torpedo.damageVelocityFactor * 0.75 -- don't weigh velocity damage as high since it depends on the situation
    if torpedo.shieldAndHullDamage then damageValue = damageValue * 2 end  -- in this case we deal both shield and hull damage -> re-increase price back to 100%

    local reachValue = torpedo.reach * 0.35

    value = value + damageValue * reachValue
    value = value / 3500  -- lower value since you can fire torpedoes only once

    -- penetration, value is two and a half times the normal value because penetration is very strong
    local penetrationValue = 0
    if torpedo.shieldPenetration then penetrationValue = value * 1.5 end
    value = value + penetrationValue

    -- EMP
    local empValue = 0
    if torpedo.shieldDeactivation then empValue = empValue + 100000 end
    if torpedo.energyDrain then empValue = empValue + 100000 end
    value = value + empValue

    -- durability
    local durabilityValue = torpedo.durability * 20
    value = value + durabilityValue

    local speedValue = value * torpedo.maxVelocity / 300 * 0.1
    value = value + speedValue

    -- maneuverability of 1 is median, above makes it more expensive, below makes it cheaper
    local maneuverValue = value * torpedo.turningSpeed * 0.25
    value = value + maneuverValue

    -- rarity
    local rarityFactor = (1.1 ^ torpedo.rarity.value) - 1
    local rarityValue = value * rarityFactor
    value = value + rarityValue

    -- check for numerical errors that can occur by changing weapon stats to things like NaN or inf
    value = math.max(0, value)
    if value ~= value then value = 0 end
    if not (value > -math.huge and value < math.huge) then value = 0 end

    if value == 0 then
        value = 100000
    end

    value = (round(value / 100) * 100) / 10

    -- print ("damage + reach: " .. createMonetaryString(damageValue * reachValue * 0.001))
    -- print ("durability: " .. createMonetaryString(durabilityValue))
    -- print ("speed: " .. createMonetaryString(speedValue))
    -- print ("maneuver: " .. createMonetaryString(maneuverValue))
    -- print ("emp: " .. createMonetaryString(empValue))
    -- print ("penetration: " .. createMonetaryString(penetrationValue))
    -- print ("rarity: " .. createMonetaryString(rarityValue))
    -- print ("total: " .. createMonetaryString(value))
    -- print ("## end")

    return value
end
