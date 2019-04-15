package.path = package.path .. ";data/scripts/lib/?.lua"
require ("stringutility")
require ("callable")

local seed = nil
local rarity = nil
local permanent = false

function initialize(seed32_in, rarity_in, permanent_in)
    if seed32_in and rarity_in then
        seed = Seed(seed32_in)
        rarity = rarity_in
        permanent = permanent_in
        if seed and rarity then
            onInstalled(seed, rarity, permanent)
        end
    end

    if onClient() then
        invokeServerFunction("remoteInstall")
    end
end

function remoteInstall()
    broadcastInvokeClientFunction("remoteInstallCallback", seed, rarity, permanent)
end
callable(nil, "remoteInstall")

function remoteInstallCallback(seed_in, rarity_in, permanent_in)
    seed = seed_in
    rarity = rarity_in
    permanent = permanent_in or false
    onInstalled(seed, rarity, permanent)
end

-- example: factor 0.3 -> new = old * 1.3
function addBaseMultiplier(bonus, factor)
    if factor == 1 then return end
    if onClient() then return end

    local key = Entity():addBaseMultiplier(bonus, factor)
    return key
end

-- example: factor 0.3 -> new = old * 0.3
function addMultiplier(bonus, factor)
    if factor == 1 then return end
    if onClient() then return end

    local key = Entity():addMultiplier(bonus, factor)
    return key
end

function addMultiplyableBias(bonus, factor)
    if factor == 0 then return end
    if onClient() then return end

    local key = Entity():addMultiplyableBias(bonus, factor)
    return key
end

function addAbsoluteBias(bonus, factor)
    if factor == 0 then return end
    if onClient() then return end

    local key = Entity():addAbsoluteBias(bonus, factor)
    return key
end

function removeBonus(key)
    if onClient() then return end

    Entity():removeBonus(key)
end

function onRemove()
    if onUninstalled then
        onUninstalled(seed, rarity, permanent)
    end
end

function secure()
    -- this acts as a failsafe when something crashes
    seed = seed or Seed(111111)
    rarity = rarity or Rarity(0)
    permanent = permanent or false

    return {seed = seed.value, rarity = rarity.value, permanent = permanent}
end

function restore(data)
    if not data then
        seed = Seed(111111)
        rarity = Rarity(0)
        permanent = false
    else
        seed = Seed(data.seed or 111111)
        rarity = Rarity(data.rarity or 0)
        permanent = data.permanent or false
    end

    onInstalled(seed, rarity, permanent)
end

function makeLine(l)
    local fontSize = 14;
    local lineHeight = 20;

    local iconColor = ColorRGB(0.5, 0.5, 0.5)

    local line = TooltipLine(lineHeight, fontSize)
    line.ltext = l.ltext or ""
    line.ctext = l.ctext or ""
    line.rtext = l.rtext or ""
    line.icon = l.icon or ""
    line.lcolor = l.lcolor or ColorRGB(1, 1, 1)
    line.ccolor = l.ccolor or ColorRGB(1, 1, 1)
    line.rcolor = l.rcolor or ColorRGB(1, 1, 1)
    line.lbold = l.lbold or false
    line.cbold = l.cbold or false
    line.rbold = l.rbold or false
    line.litalic = l.litalic or false
    line.citalic = l.citalic or false
    line.ritalic = l.ritalic or false
    line.iconColor = l.color or iconColor

    return line
end

function makeTooltip(seed, rarity, permanent)

    local tooltip = Tooltip()
    tooltip.icon = getIcon(seed, rarity)

    local iconColor = ColorRGB(0.5, 0.5, 0.5)

    -- head line
    local line = TooltipLine(25, 15)
    line.ctext = getName(seed, rarity)
    line.ccolor = rarity.color
    tooltip:addLine(line)

    -- rarity name
    local line = TooltipLine(5, 12)
    line.ctext = tostring(rarity)
    line.ccolor = rarity.color
    tooltip:addLine(line)

    local fontSize = 14;
    local lineHeight = 20;

    -- empty line to separate headline from descriptions
    tooltip:addLine(TooltipLine(18, 18))

    local bonusLines
    if getTooltipLines then
        local lines
        lines, bonusLines = getTooltipLines(seed, rarity, permanent)
        for _, l in pairs(lines) do
            local line = makeLine(l)
            if l.boosted then line.rcolor = ColorRGB(0, 1, 0) end
            tooltip:addLine(line)
        end
    end

    -- empty lines to separate stats and descriptions
    if bonusLines then
        tooltip:addLine(TooltipLine(15, 15))

        if not permanent then
            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = "Permanent Installation Only (not active):"%_t
            line.icon = "data/textures/icons/anchor.png"
            line.iconColor = ColorRGB(0.9, 0.9, 0.9)
            line.lcolor = ColorRGB(0.9, 0.9, 0.9)
            line.litalic = true
            tooltip:addLine(line)

            for _, l in pairs(bonusLines) do
                local line = makeLine(l)
                line.rcolor = ColorRGB(0.4, 0.4, 0.4)
                line.ccolor = ColorRGB(0.4, 0.4, 0.4)
                line.lcolor = ColorRGB(0.4, 0.4, 0.4)
                tooltip:addLine(line)
            end
        else
            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = "Permanent Installation Bonuses Active"%_t
            line.icon = "data/textures/icons/anchor.png"
            line.iconColor = ColorRGB(1, 1, 1)
            line.litalic = true
            tooltip:addLine(line)
        end
    end

    -- energy consumption (if any)
    if getEnergy then
        tooltip:addLine(TooltipLine(15, 15))

        local energy, unitPrefix = getReadableValue(getEnergy(seed, rarity, permanent))

        if energy ~= 0 then
            local line = TooltipLine(lineHeight, fontSize)
            line.ltext = "Energy Consumption"%_t
            line.rtext = string.format("%g %sW", energy, unitPrefix)
            line.icon = "data/textures/icons/electric.png"
            line.iconColor = iconColor
            tooltip:addLine(line)
        end
    end

    if Unique == true then
        tooltip:addLine(TooltipLine(15, 15))

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Unique: Can only be installed once"%_t
        line.icon = "data/textures/icons/diamonds.png"
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    if PermanentInstallationOnly == true then
        tooltip:addLine(TooltipLine(15, 15))

        local line = TooltipLine(lineHeight, fontSize)
        line.ltext = "Permanent: Can only be installed permanently"%_t
        line.icon = "data/textures/icons/anchor.png"
        line.iconColor = iconColor
        tooltip:addLine(line)
    end

    tooltip:addLine(TooltipLine(15, 15))

    if getDescriptionLines then
        local lines = getDescriptionLines(seed, rarity, permanent)

        for _, l in pairs(lines) do
            tooltip:addLine(makeLine(l))
        end

        -- empty lines so the icon wont overlap with the descriptions
        for i = 1, 3 - #lines do
            tooltip:addLine(TooltipLine(15, 15))
        end

    else
        -- empty lines so the icon wont overlap with the descriptions
        for i = 1, 3 do
            tooltip:addLine(TooltipLine(15, 15))
        end
    end

    return tooltip
end

function getRarity()
    return rarity
end

function getSeed()
    return seed
end

function getPermanent()
    return permanent
end



