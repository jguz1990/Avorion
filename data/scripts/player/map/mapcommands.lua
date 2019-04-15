package.path = package.path .. ";data/scripts/lib/?.lua"
require("data/scripts/player/map/common")
require("stringutility")
require("utility")
require("goods")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace MapCommands
MapCommands = {}

-- DONE:
-- refresh routes on jump
-- refresh routes on new jump target
-- move transit area for enqueueing
-- show order buttons at new position while queueing
-- queueing jumps after queue was finished earlier might not be possible, see addJumpOrder() in orderchain.lua
-- alliance ships orderinfo callback
-- show notifications on galaxy map
-- notify player if sector isn't loaded
-- Make icons movable to the top of the sector (instead of under it) with Ctrl
-- tooltip to explain that icons can be moved to top
-- display entire queue (incl. mining, loops etc.)
-- all the above must also work with alliance ships
-- Reading current cargo out of ship info
-- Search field for goods
-- Text Box to determine amount of goods sold/bought
-- CheckBox for "prefer own" or not
-- [instead: goods from cargo bay] History of last X goods that were selected (by ship)
-- Looping

-- TODO:
-- \o/


if onServer() then
function MapCommands.initialize()
    Player():addScriptOnce("data/scripts/player/map/maproutes.lua")
end
end

if onClient() then

local OrderButtonType =
{
    Undo = 1,
    Loop = 2,
    Patrol = 3,
    Attack = 4,
    Mine = 5,
    Salvage = 6,
    Escort = 7,
    BuyGoods = 8,
    SellGoods = 9,
    RefineOres = 10,
    Stop = 11,
}

local orders = {}
MapCommands.enchainCoordinates = nil

local shipsContainer
local ordersContainer
local craftPortraits = {}
local playerShipPortraitsByName = {}
local allianceShipPortraitsByName = {}
local orderButtons = {}

local enqueueNextOrder
local buyWindow, sellWindow, escortWindow
local escortData = {}
local buyCombo, sellCombo, escortCombo
local preferOwnStationsCheck
local buyFilterTextBox, sellFilterTextBox
local buyMarginCombo, sellMarginCombo
local buyAmountTextBox, sellAmountTextBox

function MapCommands.initialize()
    local player = Player()
    player:registerCallback("onShowGalaxyMap", "onShowGalaxyMap")
    player:registerCallback("onHideGalaxyMap", "onHideGalaxyMap")
    player:registerCallback("onSelectMapCoordinates", "onSelectMapCoordinates")
    player:registerCallback("onShipOrderInfoUpdated", "onPlayerShipOrderInfoChanged")
    player:registerCallback("onShipPositionUpdated", "onPlayerShipSectorChanged")
    player:registerCallback("onGalaxyMapUpdate", "onGalaxyMapUpdate")
    player:registerCallback("onGalaxyMapMouseDown", "onGalaxyMapMouseDown")
    player:registerCallback("onGalaxyMapMouseUp", "onGalaxyMapMouseUp")

    MapCommands.initUI()
end

function MapCommands.initUI()

    shipsContainer = GalaxyMap():createContainer()
    ordersContainer = GalaxyMap():createContainer()

    -- buttons for orders
    orderButtons = {}
    orders = {}
    table.insert(orders, {tooltip = "Undo"%_t,              icon = "data/textures/icons/undo.png",              callback = "onUndoPressed",         type = OrderButtonType.Undo})
    table.insert(orders, {tooltip = "Patrol Sector"%_t,     icon = "data/textures/icons/back-forth.png",        callback = "onPatrolPressed",       type = OrderButtonType.Patrol})
    table.insert(orders, {tooltip = "Attack Enemies"%_t,    icon = "data/textures/icons/crossed-rifles.png",    callback = "onAggressivePressed",   type = OrderButtonType.Attack})
    table.insert(orders, {tooltip = "Escort"%_t,            icon = "data/textures/icons/escort.png",            callback = "onEscortPressed",       type = OrderButtonType.Escort})
    table.insert(orders, {tooltip = "Mine"%_t,              icon = "data/textures/icons/mining.png",            callback = "onMinePressed",         type = OrderButtonType.Mine})
    table.insert(orders, {tooltip = "Salvage"%_t,           icon = "data/textures/icons/scrap-metal.png",       callback = "onSalvagePressed",      type = OrderButtonType.Salvage})
    table.insert(orders, {tooltip = "Refine Ores"%_t,       icon = "data/textures/icons/metal-bar.png",         callback = "onRefineOresPressed",   type = OrderButtonType.RefineOres})
    table.insert(orders, {tooltip = "Buy Goods"%_t,         icon = "data/textures/icons/bag.png",               callback = "onBuyGoodsPressed",     type = OrderButtonType.BuyGoods})
    table.insert(orders, {tooltip = "Sell Goods"%_t,        icon = "data/textures/icons/sell.png",              callback = "onSellGoodsPressed",    type = OrderButtonType.SellGoods})
    table.insert(orders, {tooltip = "Loop"%_t,              icon = "data/textures/icons/loop.png",              callback = "onLoopPressed",         type = OrderButtonType.Loop})
    table.insert(orders, {tooltip = "Stop"%_t,              icon = "data/textures/icons/halt.png",              callback = "onStopPressed",         type = OrderButtonType.Stop})

    for i, order in pairs(orders) do
        local button = ordersContainer:createRoundButton(Rect(), order.icon, order.callback)
        button.tooltip = order.tooltip

        table.insert(orderButtons, button)
    end

    local res = getResolution()
    local size = vec2(600, 170)
    local unmatchable = "%+/#$@?{}[]><()"

    -- windows for choosing goods
    -- selling
    sellWindow = GalaxyMap():createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    sellWindow.caption = "Sell Goods /* Order Window Caption Galaxy Map */"%_t

    local hsplit = UIHorizontalMultiSplitter(Rect(sellWindow.size), 10, 10, 3)
    local vsplit = UIVerticalMultiSplitter(hsplit.top, 10, 0, 1)

    sellCombo = sellWindow:createValueComboBox(vsplit.left, "")

    sellFilterTextBox = sellWindow:createTextBox(vsplit.right, "onSellFilterTextChanged")
    sellFilterTextBox.backgroundText = "Filter /* Filter Goods */"%_t
    sellFilterTextBox.forbiddenCharacters = unmatchable

    local vsplit = UIVerticalSplitter(hsplit:partition(1), 10, 0, 0.7)
    sellWindow:createLabel(vsplit.left, "Amount to remain on ship: "%_t, 14)

    sellAmountTextBox = sellWindow:createTextBox(vsplit.right, "")
    sellAmountTextBox.backgroundText = "Amount /* of goods to buy */"%_t

    local vsplit = UIVerticalSplitter(hsplit:partition(2), 10, 0, 0.7)
    sellWindow:createLabel(vsplit.left, "Sell for at least X% of average price:"%_t, 14)
    sellMarginCombo = sellWindow:createValueComboBox(vsplit.right, "")

    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)
    preferOwnStationsCheck = sellWindow:createCheckBox(vsplit.left, "Prefer Own Stations /* Checkbox caption for ship behavior */"%_t, "")
    preferOwnStationsCheck.captionLeft = false
    preferOwnStationsCheck.tooltip = "If checked, the ship will prefer your own stations for delivering the goods."%_t

    sellWindow:createButton(vsplit.right, "Sell /* Start sell order button caption */"%_t, "onSellWindowOKButtonPressed")


    -- buying
    buyWindow = GalaxyMap():createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    buyWindow.caption = "Buy Goods /* Order Window Caption Galaxy Map */"%_t

    local hsplit = UIHorizontalMultiSplitter(Rect(buyWindow.size), 10, 10, 3)
    local vsplit = UIVerticalMultiSplitter(hsplit.top, 10, 0, 1)

    buyCombo = buyWindow:createValueComboBox(vsplit.left, "")

    buyFilterTextBox = buyWindow:createTextBox(vsplit.right, "onBuyFilterTextChanged")
    buyFilterTextBox.backgroundText = "Filter /* Filter Goods */"%_t
    buyFilterTextBox.forbiddenCharacters = unmatchable

    local vsplit = UIVerticalSplitter(hsplit:partition(1), 10, 0, 0.7)
    buyWindow:createLabel(vsplit.left, "Amount to have on ship:"%_t, 14)

    buyAmountTextBox = buyWindow:createTextBox(vsplit.right, "")
    buyAmountTextBox.backgroundText = "Amount /* of goods to buy */"%_t

    local vsplit = UIVerticalSplitter(hsplit:partition(2), 10, 0, 0.7)
    buyWindow:createLabel(vsplit.left, "Buy for at least X% of average price:"%_t, 14)
    buyMarginCombo = buyWindow:createValueComboBox(vsplit.right, "")

    local vsplit = UIVerticalSplitter(hsplit.bottom, 10, 0, 0.5)
    buyWindow:createButton(vsplit.right, "Buy /* Start buy order button caption */"%_t, "onBuyWindowOKButtonPressed")


    -- both
    for _, combo in pairs({buyMarginCombo, sellMarginCombo}) do
        combo:addEntry(false, "Any"%_t)
        for i = 50, 150, 5 do
            combo:addEntry(i / 100, string.format("%i %%", i))
        end
    end

    -- escort window
    local escortSize = vec2(550, 50)
    escortWindow = GalaxyMap():createWindow(Rect(res * 0.5 - escortSize * 0.5, res * 0.5 + escortSize * 0.5))
    escortWindow.caption = "Escort Craft /* Order Window Caption Galaxy Map */"%_t

    local vsplit = UIVerticalSplitter(Rect(escortWindow.size), 10, 10, 0.6)
    escortCombo = escortWindow:createValueComboBox(vsplit.left, "")
    escortButton = escortWindow:createButton(vsplit.right, "Escort /* Start escort order button caption */"%_t, "onEscortWindowOKButtonPressed")


    -- all windows
    for _, window in pairs({buyWindow, sellWindow, escortWindow}) do
        window.showCloseButton = 1
        window.moveable = 1
        window:hide()
    end
end

function MapCommands.mirrorPointY(p, y)
    local d = y - p.y
    p.y = p.y + 2 * d
    return p
end

function MapCommands.mirrorUIElementY(element, y)
    local rect = element.rect

    local lower = MapCommands.mirrorPointY(rect.lower, y)
    local upper = MapCommands.mirrorPointY(rect.upper, y)

    lower.y, upper.y = upper.y, lower.y

    element.rect = Rect(lower, upper)
end

function MapCommands.updateButtonLocations()
    if #craftPortraits == 0 then
        MapCommands.hideOrderButtons()
        return
    end

    MapCommands.enchainCoordinates = nil

    local enqueueing = MapCommands.isEnqueueing()
    local sx, sy = GalaxyMap():getSelectedCoordinatesScreenPosition()
    local cx, cy = GalaxyMap():getSelectedCoordinates()
    local selected = MapCommands.getSelectedPortraits()

    local usedPortraits
    if #selected > 0 and enqueueing then
        usedPortraits = selected

        local x, y = MapCommands.getLastLocationFromInfo(selected[1].info)
        if x and y then
            sx, sy = GalaxyMap():getCoordinatesScreenPosition(ivec2(x, y))
            cx, cy = x, y
            MapCommands.enchainCoordinates = {x=x, y=y}
        else
            MapCommands.enchainCoordinates = {x=cx, y=cy}
        end
    else
        usedPortraits = craftPortraits
    end


    for _, portrait in pairs(craftPortraits) do
        if enqueueing and not portrait.portrait.selected then
            portrait.portrait:hide()
            portrait.icon:hide()
        end
    end

    local showAbove = Keyboard():keyPressed(KeyboardKey.LControl) or Keyboard():keyPressed(KeyboardKey.RControl)

    -- portraits
    local diameter = 50
    local padding = 10

    local columns = math.min(#usedPortraits, math.max(4, round(math.sqrt(#usedPortraits))))

    local offset = vec2(columns * diameter + (columns - 1) * padding, padding * 3)
    offset.x = -offset.x / 2
    offset = offset + vec2(sx, sy)

    local x = 0
    local y = 0
    for _, portrait in pairs(usedPortraits) do
        local rect = Rect()
        rect.lower = vec2(x * (diameter + padding), y * (diameter + padding)) + offset
        rect.upper = rect.lower + vec2(diameter, diameter)
        portrait.portrait.rect = rect
        portrait.portrait:show()

        if portrait.picture and portrait.picture ~= "" then
            portrait.icon.rect = Rect(rect.topRight - vec2(8, 8), rect.topRight + vec2(8, 8))
            portrait.icon:show()
            portrait.icon.picture = portrait.picture
        end

        if showAbove then
            MapCommands.mirrorUIElementY(portrait.portrait, sy)
            MapCommands.mirrorUIElementY(portrait.icon, sy)
        end

        x = x + 1
        if x >= columns then
            x = 0
            y = y + 1
        end

        ::continue::
    end


    -- buttons
    if #selected > 0 then
        if x ~= 0 then
            y = y + 1
        end

        local visibleButtons = {}
        for i, button in pairs(orderButtons) do
            local add = true

            if orders[i].type == OrderButtonType.Stop and MapCommands.isEnqueueing() then
                -- cannot enqueue a "stop"
                add = false
            elseif orders[i].type == OrderButtonType.Undo then

                -- cannot undo if there is nothing to undo
                local hasCommands = false

                for _, portrait in pairs(selected) do
                    if MapCommands.hasCommandToUndo(portrait.info) then
                        hasCommands = true
                        break
                    end
                end

                if not hasCommands then
                    add = false
                end

            elseif orders[i].type == OrderButtonType.Loop then
                -- cannot loop if there are no commands based in the selected sector
                local hasCommands = false

                if MapCommands.isEnqueueing() then
                    for _, portrait in pairs(selected) do
                        local commands = MapCommands.getCommandsFromInfo(portrait.info, cx, cy)
                        if #commands > 0 then
                            hasCommands = true
                            break
                        end
                    end
                end

                if not hasCommands then
                    add = false
                end
            end

            if add then
                table.insert(visibleButtons, button)
            else
                button:hide()
            end
        end


        local oDiameter = 35

        local offset = vec2(#visibleButtons * oDiameter + (#visibleButtons - 1) * padding, padding * 5)
        offset.x = -offset.x / 2
        offset = offset + vec2(sx, sy)

        for _, button in pairs(visibleButtons) do
            local rect = Rect()
            rect.lower = vec2(x * (oDiameter + padding), y * (oDiameter + padding)) + offset
            rect.upper = rect.lower + vec2(oDiameter, oDiameter)
            button.rect = rect

            if showAbove then
                MapCommands.mirrorUIElementY(button, sy)
            end

            button:show()

            x = x + 1
        end
    else
        MapCommands.hideOrderButtons()
    end
end

function MapCommands.updateTransitArea()
    local portraits = MapCommands.getSelectedPortraits()
    if #portraits == 0 then
        GalaxyMap():resetTransitArea()
        return
    end

    local player = Player()
    local alliance = player.alliance

    local reach = 10000
    for _, portrait in pairs(portraits) do
        local shipReach

        if portrait.owner == player.index then
            shipReach = player:getShipHyperspaceReach(portrait.name)
        elseif alliance then
            shipReach = alliance:getShipHyperspaceReach(portrait.name)
        end

        if shipReach and shipReach > 0 then
            reach = math.min(reach, shipReach)
        end
    end

    if reach == 10000 then return end

    local map = GalaxyMap()
    local x, y = map:getSelectedCoordinates()

    -- while enqueueing, move transit area to the location that we'll be jumping from
    if MapCommands.isEnqueueing() then
        local selected = MapCommands.getSelectedPortraits()
        if #selected > 0 then
            local ix, iy = MapCommands.getLastLocationFromInfo(selected[1].info)
            if ix and iy then
                x, y = ix, iy
            end
        end
    end

    map:setTransitArea(ivec2(x, y), reach)
end

function MapCommands.hideOrderButtons()
    for _, button in pairs(orderButtons) do
        button:hide()
    end
    sellWindow:hide()
    buyWindow:hide()
    escortWindow:hide()
end

function MapCommands.makePortraits(faction, x, y)
    if not valid(faction) then return end

    for i, name in pairs({faction:getNamesOfShipsInSector(x, y)}) do

        local portrait = shipsContainer:createCraftPortrait(Rect())
        portrait.craftName = name
        portrait.tooltip = name
        portrait.alliance = faction.isAlliance


        local icon = shipsContainer:createPicture(Rect(), "")
        icon.flipped = true
        icon.isIcon = true
        icon:hide()

        local info = faction:getShipOrderInfo(name)
        local portraitWrapper = {portrait = portrait, info = info, icon = icon, name = name, owner = faction.index, coordinates = {x=x, y=y}, picture = MapCommands.getActionIconFromInfo(info)}

        table.insert(craftPortraits, portraitWrapper)

        if faction.isPlayer then
            playerShipPortraitsByName[name] = portraitWrapper
        else
            allianceShipPortraitsByName[name] = portraitWrapper
        end
    end
end

function MapCommands.isEnqueueing()
    return Keyboard():keyPressed(KeyboardKey.LShift) or Keyboard():keyPressed(KeyboardKey.RShift)
end

function MapCommands.onSelectMapCoordinates(x, y)

    -- update portraits
    shipsContainer:clear()
    craftPortraits = {}
    playerShipPortraitsByName = {}
    allianceShipPortraitsByName = {}

    local player = Player()
    MapCommands.makePortraits(player, x, y)
    MapCommands.makePortraits(player.alliance, x, y)

end

function MapCommands.onPlayerShipOrderInfoChanged(name, info)
    -- update UI depending on new order info
    local portrait = playerShipPortraitsByName[name]
    if portrait then
        portrait.info = info

        local current = info.chain[info.currentIndex]
        if current and current.icon then
            portrait.picture = current.icon
        else
            portrait.picture = nil
        end
    end
end

function MapCommands.onAllianceShipOrderInfoChanged(name, info)
    -- update UI depending on new order info
    local portrait = allianceShipPortraitsByName[name]
    if portrait then
        portrait.info = info

        local current = info.chain[info.currentIndex]
        if current and current.icon then
            portrait.picture = current.icon
        else
            portrait.picture = nil
        end
    end
end

function MapCommands.onPlayerShipSectorChanged(name, x, y)
    -- if one of the moved ships is in the selected sector, update the sector
    if playerShipPortraitsByName[name] then

        if playerShipPortraitsByName[name].portrait.selected then
            GalaxyMap():setSelectedCoordinates(x, y)
            MapCommands.onSelectMapCoordinates(x, y)
            playerShipPortraitsByName[name].portrait.selected = true
        else
            MapCommands.onSelectMapCoordinates(GalaxyMap():getSelectedCoordinates())
        end
    end
end

function MapCommands.onAllianceShipSectorChanged(name, x, y)
    -- if one of the moved ships is in the selected sector, update the sector
    if allianceShipPortraitsByName[name] then

        if allianceShipPortraitsByName[name].portrait.selected then
            GalaxyMap():setSelectedCoordinates(x, y)
            MapCommands.onSelectMapCoordinates(x, y)
            allianceShipPortraitsByName[name].portrait.selected = true
        else
            MapCommands.onSelectMapCoordinates(GalaxyMap():getSelectedCoordinates())
        end
    end
end

function MapCommands.onGalaxyMapMouseDown(button, mx, my, cx, cy)

    if button == MouseButton.Right
        and #MapCommands.getSelectedPortraits() > 0 then
        return true
    end

    return false
end

function MapCommands.onGalaxyMapMouseUp(button, mx, my, cx, cy, mapMoved)

    if button == MouseButton.Right
            and #MapCommands.getSelectedPortraits() > 0
            and not mapMoved then

        MapCommands.enqueueJump(cx, cy)
        return true
    end

    return false
end

function MapCommands.onGalaxyMapUpdate(timeStep)
    MapCommands.updateButtonLocations()
    MapCommands.updateTransitArea()
end

function MapCommands.fillTradeCombo(combo, filter)
    combo:clear()

    local values = {}
    local highlighted = {}

    if filter and filter ~= "" then
        for _, good in pairs(goods) do
            local displayName = good:good():displayName(1)
            if not string.match(string.lower(displayName), filter) then
                goto continue
            end

            table.insert(values, {name = good.name, displayName = displayName})

            ::continue::
        end
    else
        -- add all goods that are on board of the selected crafts
        local selected = MapCommands.getSelectedPortraits()
        for _, portrait in pairs(selected) do
            local cargos
            if portrait.alliance then
                cargos = Alliance(portrait.owner):getShipCargos(portrait.name)
            else
                cargos = Player(portrait.owner):getShipCargos(portrait.name)
            end

            for good, amount in pairs(cargos) do
                table.insert(highlighted, {name = good.name, displayName = good:displayName(1)})
            end
        end

        -- no filter for normal goods: add all
        for _, good in pairs(goods) do
            table.insert(values, {name = good.name, displayName = good:good():displayName(1)})
        end
    end

    -- sort goods by name
    table.sort(highlighted, function(a, b) return a.displayName < b.displayName end)
    table.sort(values, function(a, b) return a.displayName < b.displayName end)

    -- add goods to the combo box
    if #highlighted > 0 then
        for _, v in pairs(highlighted) do
            combo:addEntry(v.name, v.displayName)
        end

        if #values > 0 then
            combo:addEntry("", "-------------")
        end
    end

    for _, v in pairs(values) do
        combo:addEntry(v.name, v.displayName)
    end
end

function MapCommands.fillEscortCombo()
    escortCombo:clear()
    escortData = {}

    local x, y = GalaxyMap():getSelectedCoordinates()
    local player = Player()
    local portraits = MapCommands.getSelectedPortraits()

    MapCommands.addEscortComboEntries(player, portraits, player.index, {player:getNamesOfShipsInSector(x, y)}, ColorRGB(0.875, 0.875, 0.875))

    if player.alliance then
        MapCommands.addEscortComboEntries(player, portraits, player.allianceIndex, {player.alliance:getNamesOfShipsInSector(x, y)}, ColorRGB(1, 0, 1))
    end
end

function MapCommands.addEscortComboEntries(player, portraits, factionIndex, crafts, color)
    for _, name in pairs(crafts) do
        local canAdd = true
        for _, portrait in pairs(portraits) do
            if portrait.owner == factionIndex and portrait.name == name then
                canAdd = false
            end
        end

        if canAdd then
            local line = name
            local type
            if factionIndex == player.index then
                type = player:getShipType(name)
            elseif factionIndex == player.allianceIndex then
                type = player.alliance:getShipType(name)
            end

            if type == EntityType.Ship then
                line = string.format("%s (Ship)"%_t, name)
            elseif type == EntityType.Station then
                line = string.format("%s (Station)"%_t, name)
            end

            escortData[line] = name
            escortCombo:addEntry(factionIndex, line, color)
        end
    end
end

function MapCommands.onEscortPressed()
    enqueueNextOrder = MapCommands.isEnqueueing()

    MapCommands.fillEscortCombo()

    buyWindow:hide()
    sellWindow:hide()
    escortWindow:show()
end

function MapCommands.onBuyGoodsPressed()
    enqueueNextOrder = MapCommands.isEnqueueing()

    buyFilterTextBox:clear()
    buyAmountTextBox:clear()
    MapCommands.fillTradeCombo(buyCombo)

    buyWindow:show()
    sellWindow:hide()
    escortWindow:hide()
end

function MapCommands.onSellGoodsPressed()
    enqueueNextOrder = MapCommands.isEnqueueing()

    sellFilterTextBox:clear()
    sellAmountTextBox:clear()
    MapCommands.fillTradeCombo(sellCombo)

    sellWindow:show()
    buyWindow:hide()
    escortWindow:hide()
end

function MapCommands.onRefineOresPressed()
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addRefineOresOrder")
end

function MapCommands.onSellFilterTextChanged(textbox, text)
    MapCommands.fillTradeCombo(sellCombo, textbox.text)
end

function MapCommands.onBuyFilterTextChanged(textbox, text)
    MapCommands.fillTradeCombo(buyCombo, textbox.text)
end

function MapCommands.onBuyWindowOKButtonPressed()
    -- get the good the player wants traded
    local good = buyCombo.selectedValue
    if not good or good == "" then return end

    local amount = tonumber(buyAmountTextBox.text)
    if not amount then return end

    local margin = buyMarginCombo.selectedValue

    MapCommands.clearOrdersIfNecessary(not enqueueNextOrder) -- clear if not enqueueing
    MapCommands.enqueueOrder("addBuyOrder", good, margin, amount)

    buyWindow:hide()
end

function MapCommands.onSellWindowOKButtonPressed()

    local good = sellCombo.selectedValue
    if not good or good == "" then return end

    local amount = tonumber(sellAmountTextBox.text)
    if not amount then return end

    local margin = sellMarginCombo.selectedValue
    local preferOwn = preferOwnStationsCheck.checked

    MapCommands.clearOrdersIfNecessary(not enqueueNextOrder) -- clear if not enqueueing
    MapCommands.enqueueOrder("addSellOrder", good, margin, amount, preferOwn)

    sellWindow:hide()
end

function MapCommands.onEscortWindowOKButtonPressed()
    local player = Player()

    local factionIndex = escortCombo.selectedValue
    local craftLine = escortCombo.selectedEntry
    local craftName = escortData[craftLine]

    MapCommands.clearOrdersIfNecessary(not enqueueNextOrder) -- clear if not enqueueing
    MapCommands.enqueueOrder("addEscortOrder", nil, factionIndex, craftName)

    escortWindow:hide()
end

function MapCommands.onStopPressed()
    MapCommands.enqueueOrder("clearAllOrders")
end

function MapCommands.onShowGalaxyMap()
    local player = Player()
    local alliance = player.alliance
    if alliance then
        alliance:registerCallback("onShipOrderInfoUpdated", "onAllianceShipOrderInfoChanged")
        alliance:registerCallback("onShipPositionUpdated", "onAllianceShipSectorChanged")
    end
end

function MapCommands.onHideGalaxyMap()
--    print("onHideGalaxyMap")
end

function MapCommands.getSelectedPortraits()
    local result = {}

    for _, portrait in pairs(craftPortraits) do
        if portrait.portrait.selected then
            table.insert(result, portrait)
        end
    end

    return result
end

function MapCommands.getActionIconFromInfo(info)
    if info then
        local current = info.chain[info.currentIndex]
        if current and current.icon then
            return current.icon
        end
    end
end

function MapCommands.getLastLocationFromInfo(info)
    if not info then return end
    if not info.chain then return end

    local i = #info.chain

    while i > 0 do
        local current = info.chain[i]
        local x, y = current.x, current.y

        if x and y then return x, y end

        i = i - 1
    end

end

function MapCommands.getCommandsFromInfo(info, x, y)
    if not info then return {} end
    if not info.chain then return {} end
    if not info.coordinates then return {} end

    local cx, cy = info.coordinates.x, info.coordinates.y
    local i = info.currentIndex

    local result = {}
    while i > 0 and i <= #info.chain do
        local current = info.chain[i]

        if cx == x and cy == y then
            table.insert(result, current)
        end

        if current.action == OrderType.Jump then
            cx, cy = current.x, current.y
        end

        i = i + 1
    end

    return result
end

function MapCommands.hasCommandToUndo(info)
    if not info then return false end
    if not info.chain then return false end

    -- if it's not done (index == 0)
    -- and not currently doing the last order, we can still undo orders
    -- exception: jumps can still be undone
    if info.currentIndex > 0 and (info.currentIndex < #info.chain or info.chain[#info.chain].action == OrderType.Jump) then
        return true
    end

    return false
end

function MapCommands.getPortraits()
    return craftPortraits
end

function MapCommands.clearOrders()
    local remoteNotLoaded = "That sector isn't loaded to memory on the server. Please contact your server administrator for help."%_t

    for _, portrait in pairs(craftPortraits) do
        if portrait.portrait.selected then
            invokeRemoteEntityFunction(portrait.coordinates.x, portrait.coordinates.y, remoteNotLoaded, portrait.owner, portrait.name, "data/scripts/entity/orderchain.lua", "clearAllOrders")
        end
    end
end

function MapCommands.enqueueOrder(order, ...)
    local remoteNotLoaded = "That sector isn't loaded to memory on the server. Please contact your server administrator for help."%_t

    for _, portrait in pairs(craftPortraits) do
        if portrait.portrait.selected then
            invokeRemoteEntityFunction(portrait.coordinates.x, portrait.coordinates.y, remoteNotLoaded, portrait.owner, portrait.name, "data/scripts/entity/orderchain.lua", order, ...)
        end
    end
end


end -- onClient()


if onServer() then

-- server gets a special interface here for testing
MapCommands.enqueueing = false
function MapCommands.isEnqueueing()
    return enqueueing
end

MapCommands.names = {}
function MapCommands.setNames(names)
    MapCommands.names = names or {}
end

function MapCommands.clearOrders()
    local player = Player()
    for _, name in pairs(MapCommands.names) do
        local x, y = player:getShipPosition(name)
        invokeRemoteEntityFunction(x, y, nil, player.index, name, "data/scripts/entity/orderchain.lua", "clearAllOrders")
    end
end

function MapCommands.enqueueOrder(order, ...)
    local player = Player()
    for _, name in pairs(MapCommands.names) do
        local x, y = player:getShipPosition(name)
        invokeRemoteEntityFunction(x, y, nil, player.index, name, "data/scripts/entity/orderchain.lua", order, ...)
    end
end

end


-- common for both client and server (mostly for testing)
function MapCommands.clearOrdersIfNecessary(clear)
    if clear == nil then
        if not MapCommands.isEnqueueing() then MapCommands.clearOrders() end
    elseif clear then
        MapCommands.clearOrders()
    end
end

function MapCommands.enqueueJump(x, y)
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addJumpOrder", x, y)
end

function MapCommands.onUndoPressed()
    MapCommands.enqueueOrder("undoOrder", x, y)
end

function MapCommands.onLoopPressed()

    if not MapCommands.enchainCoordinates then return end

    MapCommands.enqueueOrder("addLoop", MapCommands.enchainCoordinates.x, MapCommands.enchainCoordinates.y)
end

function MapCommands.onPatrolPressed()
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addPatrolOrder")
end

function MapCommands.onAggressivePressed()
    local attackCivilShips = true
    local canFinish = true

    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addAggressiveOrder", attackCivilShips, canFinish)
end

function MapCommands.onMinePressed()
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addMineOrder")
end

function MapCommands.onSalvagePressed()
    MapCommands.clearOrdersIfNecessary()
    MapCommands.enqueueOrder("addSalvageOrder")
end


