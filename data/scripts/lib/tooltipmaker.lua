package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("utility")
require ("stringutility")
require ("cargotransportlicenseutility")
require ("inventoryitemprice")


local iconColor = ColorRGB(0.5, 0.5, 0.5)

local headLineSize = 25
local headLineFont = 15

local function fillWeaponTooltipData(obj, tooltip)

    -- rarity name
    local line = TooltipLine(5, 12)
    line.ctext = tostring(obj.rarity)
    line.ccolor = obj.rarity.color
    tooltip:addLine(line)

    -- primary stats, one by one
    local fontSize = 14
    local lineHeight = 20

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Tech"%_t
    line.rtext = round(obj.averageTech, 1)
    line.icon = "data/textures/icons/circuitry.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Material"%_t
    line.rtext = obj.material.name
    line.rcolor = obj.material.color
    line.icon = "data/textures/icons/metal-bar.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    if obj.damage > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Damage /s"%_t
        line.rtext = round(obj.dps, 1)
        line.icon = "data/textures/icons/screen-impact.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        if not obj.continuousBeam then
            -- damage
            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = "Damage"%_t
            line.rtext = round(obj.damage, 1)
            if obj.shotsPerFiring > 1 then
                line.rtext = line.rtext .. " x" .. obj.shotsPerFiring
            end
            line.icon = "data/textures/icons/screen-impact.png";
            line.iconColor = iconColor
            tooltip:addLine(line)

            -- fire rate
            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = "Fire Rate"%_t
            line.rtext = round(obj.fireRate, 1)
            line.icon = "data/textures/icons/bullets.png";
            line.iconColor = iconColor
            tooltip:addLine(line)
        end
    end

    if obj.otherForce > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Push"%_t
        line.rtext = toReadableValue(obj.otherForce, "N /* unit: Newton*/"%_t)
        line.icon = "data/textures/icons/back-forth.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    elseif obj.otherForce < 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Pull"%_t
        line.rtext = toReadableValue(-obj.otherForce, "N /* unit: Newton*/"%_t)
        line.icon = "data/textures/icons/back-forth.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    if obj.selfForce > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Self Push"%_t
        line.rtext = toReadableValue(obj.selfForce, "N /* unit: Newton*/"%_t)
        line.icon = "data/textures/icons/back-forth.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    elseif obj.selfForce < 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Self Pull"%_t
        line.rtext = toReadableValue(-obj.selfForce, "N /* unit: Newton*/"%_t)
        line.icon = "data/textures/icons/back-forth.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    if obj.stoneRefinedEfficiency > 0 and obj.metalRefinedEfficiency > 0 then

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Eff. Stone"%_t
        line.rtext = round(obj.stoneRefinedEfficiency * 100, 1)
        line.icon = "data/textures/icons/scrap-metal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Eff. Metal"%_t
        line.rtext = round(obj.metalRefinedEfficiency * 100, 1)
        line.icon = "data/textures/icons/scrap-metal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

    elseif obj.stoneRefinedEfficiency > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Efficiency"%_t
        line.rtext = round(obj.stoneRefinedEfficiency * 100, 1)
        line.icon = "data/textures/icons/scrap-metal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    elseif obj.metalRefinedEfficiency > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Efficiency"%_t
        line.rtext = round(obj.metalRefinedEfficiency * 100, 1)
        line.icon = "data/textures/icons/scrap-metal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    if obj.stoneRawEfficiency > 0 and obj.metalRawEfficiency > 0 then

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Eff. Stone"%_t
        line.rtext = round(obj.stoneRawEfficiency * 100, 1)
        line.icon = "data/textures/icons/scrap-metal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Eff. Metal"%_t
        line.rtext = round(obj.metalRawEfficiency * 100, 1)
        line.icon = "data/textures/icons/scrap-metal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

    elseif obj.stoneRawEfficiency > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Efficiency"%_t
        line.rtext = round(obj.stoneRawEfficiency * 100, 1)
        line.icon = "data/textures/icons/scrap-metal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    elseif obj.metalRawEfficiency > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Efficiency"%_t
        line.rtext = round(obj.metalRawEfficiency * 100, 1)
        line.icon = "data/textures/icons/scrap-metal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    if obj.hullRepairRate > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Hull Repair /s"%_t
        line.rtext = round(obj.hullRepairRate, 1)
        line.icon = "data/textures/icons/health-normal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    if obj.shieldRepairRate > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Shield Repair /s"%_t
        line.rtext = round(obj.shieldRepairRate, 1)
        line.icon = "data/textures/icons/health-normal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Accuracy"%_t
    line.rtext = round(obj.accuracy * 100, 1)
    line.icon = "data/textures/icons/gunner.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Range"%_t
    line.rtext = round(obj.reach * 10 / 1000, 2)
    line.icon = "data/textures/icons/target-shot.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    local weapon = obj:getWeapons() -- take first weapon
    if weapon and weapon.blockPenetration > 1 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Hull Penetration"%_t
        line.rtext = weapon.blockPenetration .. " blocks"%_t
        line.icon = "data/textures/icons/drill.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    if obj.shotsUntilOverheated > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Continuous Shots"%_t
        line.rtext = obj.shotsUntilOverheated
        line.icon = "data/textures/icons/bullets.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Time Until Overheated"%_t
        line.rtext = round(obj.shootingTime, 1) .. "s /* Unit for seconds */"%_t
        line.icon = "data/textures/icons/overheat.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Cooling Time"%_t
        line.rtext = round(obj.coolingTime, 1) .. "s /* Unit for seconds */"%_t
        line.icon = "data/textures/icons/weapon-cooldown.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        -- empty line
        tooltip:addLine(TooltipLine(15, 15))
    end

    if obj.coolingType == 1 or obj.coolingType == 2 then

        local line = TooltipLine(lineHeight, fontSize)

        if obj.coolingType == 2 then
            line.ltext = "Energy /s"%_t
        else
            line.ltext = "Energy /shot"%_t
        end
        line.rtext = round(obj.baseEnergyPerSecond)
        line.icon = "data/textures/icons/electric.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Energy Increase /s"%_t
        line.rtext = round(obj.energyIncreasePerSecond, 1)
        line.icon = "data/textures/icons/electric.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        -- empty line
        tooltip:addLine(TooltipLine(15, 15))
    end
end

local function fillDescriptions(obj, tooltip, additional)

    -- now count the lines, as there will have to be lines inserted
    -- to make sure that the icon of the weapon won't overlap with the stats
    local extraLines = 0
    local fontSize = 14
    local lineHeight = 18
    additional = additional or {}

    -- one line for flavor text
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = obj.flavorText
    line.lcolor = ColorRGB(1.0, 0.7, 0.7)
    tooltip:addLine(line)

    extraLines = extraLines + 1

    local descriptions = obj:getDescriptions()

    if obj.shotsUntilOverheated > 0 then
        if obj.shootingTime > 2 then
            table.insert(additional, "Overheats"%_t)
        else
            table.insert(additional, "Burst Fire"%_t)
        end
    end

    if obj.seeker then
        table.insert(additional, "Seeker Missiles"%_t)
    end

    if obj.shieldDamageMultiplicator == 0 then
        table.insert(additional, "No damage to shields"%_t)
    end

    if obj.metalRawEfficiency > 0 then
        table.insert(additional, "Breaks Alloys down into Scrap Metal"%_t)
    end

    if obj.stoneRawEfficiency > 0 then
        table.insert(additional, "Breaks Stone down into Ores"%_t)
    end

    if obj.stoneRefinedEfficiency > 0 then
        table.insert(additional, "Refinement: Refines Stone into Resources"%_t)
    end
    if obj.metalRefinedEfficiency > 0 then
        table.insert(additional, "Refinement: Refines Alloys into Resources"%_t)
    end


    for desc, value in pairs(descriptions) do
        local line = TooltipLine(lineHeight, fontSize)

        if value == "" then
            line.ltext = desc % _t
        else
            line.ltext = string.format(desc % _t, value)
        end

        local existsAlready
        for _, desc in pairs(additional) do
            if desc == line.ltext then
                existsAlready = true
            end
        end

        if not existsAlready then
            tooltip:addLine(line)
            extraLines = extraLines + 1
        end
    end

    for _, text in pairs(additional) do
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = text
        tooltip:addLine(line)
        extraLines = extraLines + 1
    end

    for i = 1, 3 - extraLines do
        -- empty line
        tooltip:addLine(TooltipLine(15, 15))
    end

end

function makeTurretTooltip(turret)
    local tooltip = Tooltip()

        -- create tool tip
    tooltip.icon = turret.weaponIcon

    -- build title
    local title = ""

    local weapon = turret.weaponPrefix .. " /* Weapon Prefix*/"
    weapon = weapon % _t

    local tbl = {material = turret.material.name, weaponPrefix = weapon}

    if turret.stoneRefinedEfficiency > 0 or turret.metalRefinedEfficiency > 0
        or turret.stoneRawEfficiency > 0 or turret.metalRawEfficiency > 0  then
        if turret.numVisibleWeapons == 1 then
            title = "${material} ${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 2 then
            title = "Double ${material} ${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 3 then
            title = "Triple ${material} ${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 4 then
            title = "Quad ${material} ${weaponPrefix} Turret"%_t % tbl
        else
            title = "Multi ${material} ${weaponPrefix} Turret"%_t % tbl
        end
    elseif turret.coaxial then
        if turret.numVisibleWeapons == 1 then
            title = "Coaxial ${weaponPrefix}"%_t % tbl
        elseif turret.numVisibleWeapons == 2 then
            title = "Double Coaxial ${weaponPrefix}"%_t % tbl
        elseif turret.numVisibleWeapons == 3 then
            title = "Triple Coaxial ${weaponPrefix}"%_t % tbl
        elseif turret.numVisibleWeapons == 4 then
            title = "Quad Coaxial ${weaponPrefix}"%_t % tbl
        else
            title = "Coaxial Multi ${weaponPrefix}"%_t % tbl
        end
    else
        if turret.numVisibleWeapons == 1 then
            title = "${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 2 then
            title = "Double ${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 3 then
            title = "Triple ${weaponPrefix} Turret"%_t % tbl
        elseif turret.numVisibleWeapons == 4 then
            title = "Quad ${weaponPrefix} Turret"%_t % tbl
        else
            title = "Multi ${weaponPrefix} Turret"%_t % tbl
        end
    end

    -- head line
    local line = TooltipLine(headLineSize, headLineFont)
    line.ctext = title
    line.ccolor = turret.rarity.color
    tooltip:addLine(line)

    local fontSize = 14;
    local lineHeight = 20;

    fillWeaponTooltipData(turret, tooltip)

    -- size
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Size"%_t
    line.rtext = round(turret.size, 1)
    line.icon = "data/textures/icons/shotgun.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- slots
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Slots"%_t
    line.rtext = round(turret.slots, 1)
    line.icon = "data/textures/icons/small-square.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    -- automatic/independent firing
    if turret.automatic then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Independent Targeting"%_t
        line.icon = "data/textures/icons/cog.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        -- empty line
        tooltip:addLine(TooltipLine(15, 15))
    end

    -- Refinement
    if turret.stoneRefinedEfficiency > 0 or turret.metalRefinedEfficiency > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Refinement"%_t
        line.icon = "data/textures/icons/metal-bar.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        -- empty line
        tooltip:addLine(TooltipLine(15, 15))
    end

    -- coaxial weaponry
    if turret.coaxial then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Coaxial Weapon"%_t
        line.icon = "data/textures/icons/cog.png";
        line.iconColor = iconColor
        tooltip:addLine(line)

        -- empty line
        tooltip:addLine(TooltipLine(15, 15))
    end

    -- crew requirements
    local crew = turret:getCrew()

    for crewman, amount in pairs(crew:getMembers()) do

        if amount > 0 then
            local profession = crewman.profession

            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = profession:name(amount)
            line.rtext = round(amount)
            line.icon = profession.icon;
            line.iconColor = iconColor
            tooltip:addLine(line)

        end
    end

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    local description = {}
    if turret.automatic then
        table.insert(description, "Independent targeting, but deals less damage"%_t)
    end
    if turret.coaxial then
        table.insert(description, "Coaxial weapon"%_t)
    end

    fillDescriptions(turret, tooltip, description)

    return tooltip
end

function makeFighterTooltip(fighter)

    -- create tool tip
    local tooltip = Tooltip()

    -- title
    local title
    if fighter.type == FighterType.Fighter then
        title = "${weaponPrefix} Fighter"%_t % fighter
        tooltip.icon = fighter.weaponIcon
    elseif fighter.type == FighterType.CargoShuttle then
        title = "Cargo Shuttle"%_t
        tooltip.icon = "data/textures/icons/crate.png"
    elseif fighter.type == FighterType.CrewShuttle then
        title = "Crew Shuttle"%_t
    end

    local line = TooltipLine(headLineSize, headLineFont)
    line.ctext = title
    line.ccolor = fighter.rarity.color
    tooltip:addLine(line)

    -- primary stats, one by one
    local fontSize = 14
    local lineHeight = 20

    if fighter.type == FighterType.Fighter then
        fillWeaponTooltipData(fighter, tooltip)
    end
    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    -- size
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Size"%_t
    line.rtext = round(fighter.volume)
    line.icon = "data/textures/icons/fighter.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- durability
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Durability"%_t
    line.rtext = round(fighter.durability)
    line.icon = "data/textures/icons/health-normal.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    if fighter.shield > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Shield"%_t
        line.rtext = round(fighter.durability)
        line.icon = "data/textures/icons/health-normal.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    -- maneuverability
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Maneuverability"%_t
    line.rtext = round(fighter.turningSpeed, 2)
    line.icon = "data/textures/icons/dodge.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- velocity
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Speed"%_t
    line.rtext = round(fighter.maxVelocity * 10.0)
    line.icon = "data/textures/icons/speedometer.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    local num, postfix = getReadableNumber(FighterPrice(fighter))
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Prod. Effort"%_t
    line.rtext = "${num} ${amount}"%_t % {num = tostring(num), amount = postfix}
    line.icon = "data/textures/icons/cog.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    -- crew requirements
    local pilot = CrewProfession(CrewProfessionType.Pilot)

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = pilot:name(round(fighter.crew))
    line.rtext = round(fighter.crew)
    line.icon = pilot.icon
    line.iconColor = iconColor
    tooltip:addLine(line)


    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    fillDescriptions(fighter, tooltip)

    return tooltip
end

function makeTorpedoTooltip(torpedo)
    -- create tool tip
    local tooltip = Tooltip()
    tooltip.icon = torpedo.icon

    -- title
    local title

    local line = TooltipLine(headLineSize, headLineFont)
    line.ctext = torpedo.name
    line.ccolor = torpedo.rarity.color
    tooltip:addLine(line)

    -- primary stats, one by one
    local fontSize = 14
    local lineHeight = 20

    -- rarity name
    local line = TooltipLine(5, 12)
    line.ctext = tostring(torpedo.rarity)
    line.ccolor = torpedo.rarity.color
    tooltip:addLine(line)

    -- primary stats, one by one
    local fontSize = 14
    local lineHeight = 20

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Tech"%_t
    line.rtext = torpedo.tech
    line.icon = "data/textures/icons/circuitry.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    if torpedo.hullDamage > 0 and torpedo.damageVelocityFactor == 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Damage"%_t
        line.rtext = toReadableValue(round(torpedo.hullDamage), "")
        line.icon = "data/textures/icons/screen-impact.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    elseif torpedo.damageVelocityFactor > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Hull Damage"%_t
        line.rtext = "up to ${damage}"%_t % {damage = toReadableValue(round(torpedo.maxVelocity * torpedo.damageVelocityFactor), "")}
        line.icon = "data/textures/icons/screen-impact.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    if torpedo.shieldDamage > 0 and torpedo.shieldDamage ~= torpedo.hullDamage then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Shield Damage"%_t
        line.rtext = toReadableValue(round(torpedo.shieldDamage), "")
        line.icon = "data/textures/icons/screen-impact.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    -- maneuverability
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Maneuverability"%_t
    line.rtext = round(torpedo.turningSpeed, 2)
    line.icon = "data/textures/icons/dodge.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Speed"%_t
    line.rtext = round(torpedo.maxVelocity * 10.0)
    line.icon = "data/textures/icons/speedometer.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    if torpedo.acceleration > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Acceleration"%_t
        line.rtext = round(torpedo.acceleration * 10.0)
        line.icon = "data/textures/icons/acceleration.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Range"%_t
    line.rtext = "${range} km" % {range = round(torpedo.reach * 10 / 1000, 2)}
    line.icon = "data/textures/icons/target-shot.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    if torpedo.storageEnergyDrain > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Storage Energy"%_t
        line.rtext = toReadableValue(round(torpedo.storageEnergyDrain), "W")
        line.icon = "data/textures/icons/electric.png";
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))

    -- size
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Size"%_t
    line.rtext = round(torpedo.size, 1)
    line.icon = "data/textures/icons/missile-pod.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- durability
    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = "Durability"%_t
    line.rtext = round(torpedo.durability)
    line.icon = "data/textures/icons/health-normal.png";
    line.iconColor = iconColor
    tooltip:addLine(line)

    -- empty line
    tooltip:addLine(TooltipLine(15, 15))
    tooltip:addLine(TooltipLine(15, 15))

    -- specialties
    local extraLines = 0

    if torpedo.damageVelocityFactor > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Damage Dependent on Velocity"%_t
        tooltip:addLine(line)

        extraLines = extraLines + 1
    end

    if torpedo.shieldDeactivation then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Briefly Deactivates Shields"%_t
        tooltip:addLine(line)

        extraLines = extraLines + 1
    end

    if torpedo.energyDrain then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Drains Target's Energy"%_t
        tooltip:addLine(line)

        extraLines = extraLines + 1
    end

    if torpedo.shieldPenetration then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Penetrates Shields"%_t
        tooltip:addLine(line)

        extraLines = extraLines + 1
    end

    if torpedo.shieldAndHullDamage then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Damages Both Shield and Hull"%_t
        tooltip:addLine(line)

        extraLines = extraLines + 1
    end

    if torpedo.storageEnergyDrain > 0 then
        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Requires Energy in Storage"%_t
        tooltip:addLine(line)

        extraLines = extraLines + 1
    end

    for i = 1, 3 - extraLines do
        -- empty line
        tooltip:addLine(TooltipLine(15, 15))
    end


    return tooltip

end
