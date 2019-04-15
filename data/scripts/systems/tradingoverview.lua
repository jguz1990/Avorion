package.path = package.path .. ";data/scripts/systems/?.lua"
package.path = package.path .. ";data/scripts/lib/?.lua"
require ("basesystem")
require ("utility")
require ("randomext")
require ("callable")
local TradingUtility = require ("tradingutility")
local RingBuffer = require ("ringbuffer")

-- optimization so that energy requirement doesn't have to be read every frame
FixedEnergyRequirement = true

local tabbedWindow = nil
local routesTab = nil

local sellableGoodFrames = {}
local sellableGoodIcons = {}
local sellableGoodNameLabels = {}
local sellableGoodStockLabels = {}
local sellableGoodPriceLabels = {}
local sellableGoodSizeLabels = {}
local sellableGoodStationLabels = {}
local sellableGoodPriceFactorLabels = {}
local sellableGoodOnShipLabels = {}
local sellableGoodButtons = {}

local buyableGoodFrames = {}
local buyableGoodIcons = {}
local buyableGoodNameLabels = {}
local buyableGoodStockLabels = {}
local buyableGoodPriceLabels = {}
local buyableGoodSizeLabels = {}
local buyableGoodStationLabels = {}
local buyableGoodPriceFactorLabels = {}
local buyableGoodOnShipLabels = {}
local buyableGoodButtons = {}

local routeIcons = {}
local routeFrames = {}
local routePriceLabels = {}
local routeCoordLabels = {}
local routeStationLabels = {}
local routeButtons = {}
local routeAmountOnShipLabels = {}


local sellable = {}
local buyable = {}

local routes = {}
local historySize = 0
local tradingData = nil


local sellablesPage = 0
local buyablesPage = 0
local routesPage = 0

local sellableSortFunction = nil
local buyableSortFunction = nil

function seePrices(seed, rarity)
    return rarity.value >= 0
end

function seePriceFactors(seed, rarity)
    return rarity.value >= 1
end

function getHistorySize(seed, rarity)

    if rarity.value == 2 then
        return 1
    elseif rarity.value >= 3 then
        math.randomseed(seed)

        if rarity.value == 5 then
            return getInt(15, 20)
        elseif rarity.value == 4 then
            return getInt(10, 15)
        elseif rarity.value == 3 then
            return getInt(5, 10)
        end
    end

    return 0
end

function onInstalled(seed, rarity, permanent)

    historySize = getHistorySize(seed, rarity, permanent)

    if onServer() then
        tradingData = RingBuffer(math.max(historySize, 1))
        collectSectorData()
    end

end

function onUninstalled(seed, rarity, permanent)
end

function getName(seed, rarity)
    local prefix = ""
    if rarity.value == 0 then
        return "Basic Trading System"%_t
    elseif rarity.value == 1 then
        return "Improved Trading System"%_t
    elseif rarity.value == 2 then
        return "Advanced Trading System"%_t
    elseif rarity.value == 3 then
        return "High-Tech Trading System"%_t
    elseif rarity.value == 4 then
        return "Salesman's Trading System"%_t
    elseif rarity.value == 5 then
        return "Ultra-Tech Trading System"%_t
    end

    return "Trading System"%_t
end

function getIcon(seed, rarity)
    return "data/textures/icons/cash.png"
end

function getPrice(seed, rarity)
    local num = getHistorySize(seed, rarity)
    local price = (rarity.value + 2) * 4000 + 5000 * num;
    return price * 2.5 ^ rarity.value
end

function getTooltipLines(seed, rarity, permanent)
    local lines = {}

    if seePrices(seed, rarity) then
        table.insert(lines, {ltext = "Display prices of goods"%_t, icon = "data/textures/icons/sell.png"})
    end
    if seePriceFactors(seed, rarity) then
        table.insert(lines, {ltext = "Display price ratios of goods"%_t, icon = "data/textures/icons/sell.png"})
    end

    return lines
end

function getDescriptionLines(seed, rarity, permanent)
    local lines =
    {
        {ltext = "View trading offers of stations in sector"%_t}
    }

    local history = getHistorySize(seed, rarity)
    if history > 0 then
        table.insert(lines, {ltext = plural_t("Display trade routes in current sector", "Display trade routes in last ${i} sectors", history)})
    end

    return lines
end

function gatherData()
    return TradingUtility.detectBuyableAndSellableGoods()
end

function onSectorChanged()
    collectSectorData()
end

function collectSectorData()
    if not tradingData then return end

    local sellable, buyable = gatherData()

    -- print("gathered " .. #sellable .. " sellable goods from sector " .. tostring(vec2(Sector():getCoordinates())))
    -- print("gathered " .. #buyable .. " buyable goods from sector " .. tostring(vec2(Sector():getCoordinates())))

    tradingData:insert({sellable = sellable, buyable = buyable})

    updateTradingRoutes()
end

function updateTradingRoutes()

    if historySize == 0 then
        routes = {}
        return
    end
--    print("analyzing sector history")

    local buyables = {}
    local sellables = {}
    routes = {}

    local counter = 0
    local gc = 0

    -- find best offer in buyables for every good
    for _, sectorData in ipairs(tradingData.data) do
        -- find best offer in buyable for every good
        for _, offer in pairs(sectorData.buyable) do
            local existing = buyables[offer.good.name]
            if existing == nil or offer.price < existing.price then
                buyables[offer.good.name] = offer
            end

            gc = gc + 1
        end

        -- find best offer in sellable for every good
        for _, offer in pairs(sectorData.sellable) do
            local existing = sellables[offer.good.name]
            if existing == nil or offer.price > existing.price then
                sellables[offer.good.name] = offer
            end

            gc = gc + 1
        end

        counter = counter + 1
    end

    -- match those two to find possible trading routes
    for name, offer in pairs(buyables) do

        if offer.stock > 0 then
            local sellable = sellables[name]

            if sellable ~= nil and (sellable.price > offer.price or (sellable.price == 0 and offer.price == 0)) then
                table.insert(routes, {sellable=sellable, buyable=offer})

    --            print(string.format("found trading route for %s, buy price (in sector %s): %i, sell price (in sector %s): %i", name, tostring(offer.coords), offer.price, tostring(sellable.coords), sellable.price))
            end
        end
    end

--    print("analyzed " .. counter .. " data sets with " .. gc .. " different goods")

end

function getData()
    local sellable, buyable = gatherData()

    if tradingData then
        tradingData.data[tradingData.last] = {sellable = sellable, buyable = buyable}
        updateTradingRoutes()
    end

    if callingPlayer then
        invokeClientFunction(Player(callingPlayer), "setData", sellable, buyable, routes)
    end

    return sellable, buyable, routes or {}
end
callable(nil, "getData")



-- if this function returns false, the script will not be listed in the interaction window on the client,
-- even though its UI may be registered
function interactionPossible(playerIndex, option)

    local player = Player()
    if Entity().index == player.craftIndex then
        return true
    end

    return false
end

function initUI()
    local size = vec2(1000, 670)
    local res = getResolution()

    local menu = ScriptUI()
    local mainWindow = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5));
    menu:registerWindow(mainWindow, "Trading Overview"%_t);

    mainWindow.caption = "Trading Overview"%_t
    mainWindow.showCloseButton = 1
    mainWindow.moveable = 1

    -- create a tabbed window inside the main window
    tabbedWindow = mainWindow:createTabbedWindow(Rect(vec2(10, 10), size - 10))

    -- create routes tab
    routesTab = tabbedWindow:createTab("Trading Routes"%_t, "data/textures/icons/trade-route.png", "View detected trading routes"%_t)
    buildRoutesGui(routesTab)

    -- create buy tab
    local buyTab = tabbedWindow:createTab("Buy"%_t, "data/textures/icons/bag.png", "Buy from stations"%_t)
    buildGui(buyTab, 1)

    -- create sell tab
    local sellTab = tabbedWindow:createTab("Sell"%_t, "data/textures/icons/sell.png", "Sell to stations"%_t)
    buildGui(sellTab, 0)

    guiInitialized = 1

end

function onShowWindow()
    invokeServerFunction("getData")
end

function setData(sellable_received, buyable_received, routes_received)

    sellable = sellable_received
    buyable = buyable_received
    routes = routes_received

    local ship = Entity()

    for _, route in pairs(routes) do
        for j, offer in pairs({route.buyable, route.sellable}) do
            offer.amountOnShip = ship:getCargoAmount(offer.good)

            -- translate argument values of station title
            for k, v in pairs(offer.titleArgs) do
                offer.titleArgs[k] = v%_t
            end
        end
    end

    for _, good in pairs(buyable) do
        good.amountOnShip = ship:getCargoAmount(good.good)

        -- translate argument values of station title
        for k, v in pairs(good.titleArgs) do
            good.titleArgs[k] = v%_t
        end
    end

    for _, good in pairs(sellable) do
        good.amountOnShip = ship:getCargoAmount(good.good)

        -- translate argument values of station title
        for k, v in pairs(good.titleArgs) do
            good.titleArgs[k] = v%_t
        end
    end


    refreshUI()
end

function sortByNameAsc(a, b) return a.good:displayName(2) < b.good:displayName(2) end
function sortByNameDes(a, b) return a.good:displayName(2) > b.good:displayName(2) end

function sortByStockAsc(a, b) return a.stock / a.maxStock < b.stock / b.maxStock end
function sortByStockDes(a, b) return a.stock / a.maxStock > b.stock / b.maxStock end

function sortByPriceAsc(a, b) return a.good.price < b.good.price end
function sortByPriceDes(a, b) return a.good.price > b.good.price end

function sortByVolAsc(a, b) return a.good.size < b.good.size end
function sortByVolDes(a, b) return a.good.size > b.good.size end

function sortByPriceFactorAsc(a, b) return a.price / a.good.price < b.price / b.good.price end
function sortByPriceFactorDes(a, b) return a.price / a.good.price > b.price / b.good.price end

function sortByStationAsc(a, b) return a.station < b.station end
function sortByStationDes(a, b) return a.station > b.station end

function sortByAmountOnShipAsc(a, b) return a.amountOnShip < b.amountOnShip end
function sortByAmountOnShipDes(a, b) return a.amountOnShip > b.amountOnShip end

function routesByProfit(a, b)
    -- calculate max profit
    local pa = (a.sellable.price - a.buyable.price) * a.buyable.stock
    local pb = (b.sellable.price - b.buyable.price) * b.buyable.stock
    return pa > pb
end

function routesByPriceMargin(a, b)
    -- calculate max profit
    local pa = (a.sellable.price - a.buyable.price)
    local pb = (b.sellable.price - b.buyable.price)
    return pa > pb
end



sellableSortFunction = sortByNameAsc
buyableSortFunction = sortByNameAsc

function refreshBuyablesUI()
    table.sort(buyable, buyableSortFunction)

    for index = 1, 15 do
        buyableGoodFrames[index]:hide()
        buyableGoodIcons[index]:hide()
        buyableGoodNameLabels[index]:hide()
        buyableGoodStockLabels[index]:hide()
        buyableGoodPriceLabels[index]:hide()
        buyableGoodSizeLabels[index]:hide()
        buyableGoodStationLabels[index]:hide()
        buyableGoodPriceFactorLabels[index]:hide()
        buyableGoodOnShipLabels[index]:hide()
        buyableGoodButtons[index]:hide()
    end

    local index = 0
    for i, good in pairs(buyable) do

        if i > buyablesPage * 15 and i <= (buyablesPage + 1) * 15 then
            index = index + 1
            if index > 15 then break end

            buyableGoodNameLabels[index].caption = good.good:displayName(2)
            buyableGoodStockLabels[index].caption = math.floor(good.stock) .. " / " .. math.floor(good.maxStock)
            buyableGoodPriceLabels[index].caption = createMonetaryString(good.price)
            buyableGoodPriceFactorLabels[index].caption = string.format("%+i%%", round((good.price / good.good.price - 1.0) * 100))
            buyableGoodSizeLabels[index].caption = round(good.good.size, 2)
            buyableGoodIcons[index].picture = good.good.icon
            buyableGoodStationLabels[index].caption = good.station%_t % good.titleArgs
            if good.amountOnShip > 0 then
                buyableGoodOnShipLabels[index].caption = good.amountOnShip
            else
                buyableGoodOnShipLabels[index].caption = "-"
            end

            buyableGoodFrames[index]:show()
            buyableGoodIcons[index]:show()
            buyableGoodNameLabels[index]:show()
            buyableGoodStockLabels[index]:show()
            buyableGoodPriceLabels[index]:show()
            buyableGoodSizeLabels[index]:show()
            buyableGoodStationLabels[index]:show()
            buyableGoodPriceFactorLabels[index]:show()
            buyableGoodButtons[index]:show()
            buyableGoodOnShipLabels[index]:show()

            if getRarity().value < 0 then
                buyableGoodPriceLabels[index].caption = "-"
            end

            if getRarity().value < 1 then
                buyableGoodPriceFactorLabels[index].caption = "-"
            end

        end
    end



end


function refreshSellablesUI()
    table.sort(sellable, sellableSortFunction)

    for index = 1, 15 do
        sellableGoodFrames[index]:hide()
        sellableGoodIcons[index]:hide()
        sellableGoodNameLabels[index]:hide()
        sellableGoodStockLabels[index]:hide()
        sellableGoodPriceLabels[index]:hide()
        sellableGoodSizeLabels[index]:hide()
        sellableGoodStationLabels[index]:hide()
        sellableGoodPriceFactorLabels[index]:hide()
        sellableGoodOnShipLabels[index]:hide()
        sellableGoodButtons[index]:hide()
    end

    local index = 0
    for i, good in pairs(sellable) do

        if i > sellablesPage * 15 and i <= (sellablesPage + 1) * 15 then
            index = index + 1
            if index > 15 then break end

            local priceFactor = ""
            if good.good.price > 0 then
                priceFactor = string.format("%+i%%", round((good.price / good.good.price - 1.0) * 100))
            end

            sellableGoodNameLabels[index].caption = good.good:displayName(2)
            sellableGoodStockLabels[index].caption = math.floor(good.stock) .. " / " .. math.floor(good.maxStock)
            sellableGoodPriceLabels[index].caption = createMonetaryString(good.price)
            sellableGoodPriceFactorLabels[index].caption = priceFactor
            sellableGoodSizeLabels[index].caption = round(good.good.size, 2)
            sellableGoodIcons[index].picture = good.good.icon
            sellableGoodStationLabels[index].caption = good.station%_t % good.titleArgs
            if good.amountOnShip > 0 then
                sellableGoodOnShipLabels[index].caption = good.amountOnShip
            else
                sellableGoodOnShipLabels[index].caption = "-"
            end

            sellableGoodFrames[index]:show()
            sellableGoodIcons[index]:show()
            sellableGoodNameLabels[index]:show()
            sellableGoodStockLabels[index]:show()
            sellableGoodPriceLabels[index]:show()
            sellableGoodSizeLabels[index]:show()
            sellableGoodStationLabels[index]:show()
            sellableGoodPriceFactorLabels[index]:show()
            sellableGoodOnShipLabels[index]:show()
            sellableGoodButtons[index]:show()


            if getRarity().value < 0 then
                sellableGoodPriceLabels[index].caption = "-"
            end

            if getRarity().value < 1 then
                sellableGoodPriceFactorLabels[index].caption = "-"
            end

        end
    end

end

function refreshRoutesUI()

    if historySize == 0 then
        tabbedWindow:deactivateTab(routesTab)
        return
    end

    for index = 1, 15 do
        for j = 1, 2 do
            routePriceLabels[index][j]:hide()
            routeStationLabels[index][j]:hide()
            routeCoordLabels[index][j]:hide()
            routeFrames[index][j]:hide()
            routeButtons[index][j]:hide()
            routeIcons[index]:hide()
            routeAmountOnShipLabels[index]:hide()
        end
    end

    table.sort(routes, routesByPriceMargin)

    local index = 0
    for i, route in pairs(routes) do

        if i > routesPage * 15 and i <= (routesPage + 1) * 15 then
            index = index + 1
            if index > 15 then break end

            for j, offer in pairs({route.buyable, route.sellable}) do

                routePriceLabels[index][j].caption = createMonetaryString(offer.price)
                routeStationLabels[index][j].caption = offer.station%_t % offer.titleArgs
                routeCoordLabels[index][j].caption = tostring(offer.coords)
                routeIcons[index].picture = offer.good.icon
                routeIcons[index].tooltip = offer.good:displayName(2)
                if j == 2 then
                    if offer.amountOnShip > 0 then
                        routeAmountOnShipLabels[index].caption = offer.amountOnShip
                    else
                        routeAmountOnShipLabels[index].caption = "-"
                    end
                    routeAmountOnShipLabels[index]:show()
                end

                routePriceLabels[index][j]:show()
                routeStationLabels[index][j]:show()
                routeCoordLabels[index][j]:show()
                routeFrames[index][j]:show()
                routeButtons[index][j]:show()
                routeIcons[index]:show()
            end
        end
    end
end

function refreshUI()

    refreshBuyablesUI()
    refreshSellablesUI()
    refreshRoutesUI()

end

function buildGui(window, guiType)

    local buttonCaption = "Show"%_t
    local buttonCallback = ""
    local nextPageFunc = ""
    local previousPageFunc = ""

    if guiType == 1 then
        buttonCallback = "onBuyShowButtonPressed"
        nextPageFunc = "onNextBuyablesPage"
        previousPageFunc = "onPreviousBuyablesPage"
    else
        buttonCallback = "onSellShowButtonPressed"
        nextPageFunc = "onNextSellablesPage"
        previousPageFunc = "onPreviousSellablesPage"
    end

    local size = window.size

    window:createFrame(Rect(size))

    local pictureX = 270
    local nameX = 20
    local stockX = 310
    local volX = 430
    local priceX = 480
    local priceFactorLabelX = 550
    local stationLabelX = 610
    local onShipLabelX = 880
    local buttonX = 940

    -- header
    nameLabel = window:createLabel(vec2(nameX, 10), "Name"%_t, 15)
    stockLabel = window:createLabel(vec2(stockX, 10), "Stock"%_t, 15)
    volLabel = window:createLabel(vec2(volX, 10), "Vol"%_t, 15)
    priceLabel = window:createLabel(vec2(priceX, 10), "Cr"%_t, 15)
    priceFactorLabel = window:createLabel(vec2(priceFactorLabelX, 10), "%", 15)
    stationLabel = window:createLabel(vec2(stationLabelX, 10), "Station"%_t, 15)
    onShipLabel = window:createLabel(vec2(onShipLabelX, 10), "You"%_t, 15)

    nameLabel.width = 250
    stockLabel.width = 90
    volLabel.width = 50
    priceLabel.width = 70
    priceFactorLabel.width = 60
    stationLabel.width = 240
    onShipLabel.width = 70

    if guiType == 1 then
        nameLabel.mouseDownFunction = "onBuyableNameLabelClick"
        stockLabel.mouseDownFunction = "onBuyableStockLabelClick"
        volLabel.mouseDownFunction = "onBuyableVolLabelClick"
        priceLabel.mouseDownFunction = "onBuyablePriceLabelClick"
        priceFactorLabel.mouseDownFunction = "onBuyablePriceFactorLabelClick"
        stationLabel.mouseDownFunction = "onBuyableStationLabelClick"
        onShipLabel.mouseDownFunction = "onBuyableOnShipLabelClick"
    else
        nameLabel.mouseDownFunction = "onSellableNameLabelClick"
        stockLabel.mouseDownFunction = "onSellableStockLabelClick"
        volLabel.mouseDownFunction = "onSellableVolLabelClick"
        priceLabel.mouseDownFunction = "onSellablePriceLabelClick"
        priceFactorLabel.mouseDownFunction = "onSellablePriceFactorLabelClick"
        stationLabel.mouseDownFunction = "onSellableStationLabelClick"
        onShipLabel.mouseDownFunction = "onSellableOnShipLabelClick"
    end

    -- footer
    window:createButton(Rect(10, size.y - 40, 60, size.y - 10), "<", previousPageFunc)
    window:createButton(Rect(size.x - 60, size.y - 40, size.x - 10, size.y - 10), ">", nextPageFunc)

    local y = 35
    for i = 1, 15 do

        local yText = y + 6

        local frame = window:createFrame(Rect(10, y, size.x - 50, 30 + y))

        local iconPicture = window:createPicture(Rect(pictureX, yText - 5, 29 + pictureX, 29 + yText - 5), "")
        local nameLabel = window:createLabel(vec2(nameX, yText), "", 15)
        local stockLabel = window:createLabel(vec2(stockX, yText), "", 15)
        local priceLabel = window:createLabel(vec2(priceX, yText), "", 15)
        local sizeLabel = window:createLabel(vec2(volX, yText), "", 15)
        local priceFactorLabel = window:createLabel(vec2(priceFactorLabelX, yText), "", 15)
        local stationLabel = window:createLabel(vec2(stationLabelX, yText), "", 15)
        local onShipLabel = window:createLabel(vec2(onShipLabelX, yText), "", 15)
        local button = window:createButton(Rect(buttonX, yText - 6, buttonX + 30, 30 + yText - 6), "", buttonCallback)

        stockLabel.font = FontType.Normal
        priceLabel.font = FontType.Normal
        sizeLabel.font = FontType.Normal
        priceFactorLabel.font = FontType.Normal
        stationLabel.font = FontType.Normal
        onShipLabel.font = FontType.Normal

        button.icon = "data/textures/icons/position-marker.png"
        iconPicture.isIcon = 1

        if guiType == 1 then
            table.insert(buyableGoodIcons, iconPicture)
            table.insert(buyableGoodFrames, frame)
            table.insert(buyableGoodNameLabels, nameLabel)
            table.insert(buyableGoodStockLabels, stockLabel)
            table.insert(buyableGoodPriceLabels, priceLabel)
            table.insert(buyableGoodSizeLabels, sizeLabel)
            table.insert(buyableGoodPriceFactorLabels, priceFactorLabel)
            table.insert(buyableGoodStationLabels, stationLabel)
            table.insert(buyableGoodOnShipLabels, onShipLabel)
            table.insert(buyableGoodButtons, button)
        else
            table.insert(sellableGoodIcons, iconPicture)
            table.insert(sellableGoodFrames, frame)
            table.insert(sellableGoodNameLabels, nameLabel)
            table.insert(sellableGoodStockLabels, stockLabel)
            table.insert(sellableGoodPriceLabels, priceLabel)
            table.insert(sellableGoodSizeLabels, sizeLabel)
            table.insert(sellableGoodPriceFactorLabels, priceFactorLabel)
            table.insert(sellableGoodStationLabels, stationLabel)
            table.insert(sellableGoodOnShipLabels, onShipLabel)
            table.insert(sellableGoodButtons, button)
        end

        frame:hide();
        iconPicture:hide();
        nameLabel:hide();
        stockLabel:hide();
        priceLabel:hide();
        sizeLabel:hide();
        stationLabel:hide();
        onShipLabel:hide()
        button:hide();

        y = y + 35
    end

end

function buildRoutesGui(window)
    local buttonCaption = "Show"%_t

    local buttonCallback = "onRouteShowStationPressed"
    local nextPageFunc = "onNextRoutesPage"
    local previousPageFunc = "onPreviousRoutesPage"

    local size = window.size

    window:createFrame(Rect(size))

    local priceX = 10
    local stationLabelX = 170
    local coordLabelX = 80
    local onShipLabelX = 360

    -- footer
    window:createButton(Rect(10, size.y - 40, 60, size.y - 10), "<", previousPageFunc)
    window:createButton(Rect(size.x - 60, size.y - 40, size.x - 10, size.y - 10), ">", nextPageFunc)

    local y = 35
    for i = 1, 15 do

        local yText = y + 6

        local msplit = UIVerticalSplitter(Rect(10, y, size.x - 10, 30 + y), 10, 0, 0.5)
        msplit.leftSize = 30

        local icon = window:createPicture(msplit.left, "")
        icon.isIcon = 1
        icon.picture = "data/textures/icons/circuitry.png"
        icon:hide();

        local vsplit = UIVerticalSplitter(msplit.right, 10, 0, 0.5)

        routeIcons[i] = icon
        routeFrames[i] = {}
        routePriceLabels[i] = {}
        routeCoordLabels[i] = {}
        routeStationLabels[i] = {}
        routeButtons[i] = {}
        routeAmountOnShipLabels[i] = nil

        for j, rect in pairs({vsplit.left, vsplit.right}) do

            -- create UI for good + station where to get it
            local ssplit = UIVerticalSplitter(rect, 10, 0, 0.5)
            ssplit.rightSize = 30
            local x = ssplit.left.lower.x

            if i == 1 then
                -- header
                window:createLabel(vec2(x + priceX, 10), "Cr"%_t, 15)
                window:createLabel(vec2(x + coordLabelX, 10), "Coord"%_t, 15)

                if j == 1 then
                    window:createLabel(vec2(x + stationLabelX, 10), "From"%_t, 15)
                else
                    window:createLabel(vec2(x + stationLabelX, 10), "To"%_t, 15)

                    window:createLabel(vec2(x + onShipLabelX, 10), "You"%_t, 15)
                end
            end

            local frame = window:createFrame(ssplit.left)

            local priceLabel = window:createLabel(vec2(x + priceX, yText), "", 15)
            local stationLabel = window:createLabel(vec2(x + stationLabelX, yText), "", 15)
            local coordLabel = window:createLabel(vec2(x + coordLabelX, yText), "", 15)

            local button = window:createButton(ssplit.right, "", buttonCallback)
            button.icon = "data/textures/icons/position-marker.png"

            if j == 2 then
                local onShipLabel = window:createLabel(vec2(x + onShipLabelX, yText), "", 15)
                onShipLabel.font = FontType.Normal
                onShipLabel:hide()
                routeAmountOnShipLabels[i] = onShipLabel
            end

            frame:hide();
            priceLabel:hide();
            coordLabel:hide();
            stationLabel:hide();
            button:hide();

            priceLabel.font = FontType.Normal
            coordLabel.font = FontType.Normal
            stationLabel.font = FontType.Normal

            table.insert(routeFrames[i], frame)
            table.insert(routePriceLabels[i], priceLabel)
            table.insert(routeCoordLabels[i], coordLabel)
            table.insert(routeStationLabels[i], stationLabel)
            table.insert(routeButtons[i], button)
        end


        y = y + 35
    end

end

function onRouteShowStationPressed(button_in)

    for i, buttons in pairs(routeButtons) do
        for j, button in pairs(buttons) do
            if button.index == button_in.index then
                local stationIndex
                local coords
                if j == 1 then
                    stationIndex = routes[routesPage * 15 + i].buyable.stationIndex
                    coords = routes[routesPage * 15 + i].buyable.coords
                else
                    stationIndex = routes[routesPage * 15 + i].sellable.stationIndex
                    coords = routes[routesPage * 15 + i].sellable.coords
                end

                local x, y = Sector():getCoordinates()

                if coords.x == x and coords.y == y then
                    Player().selectedObject = Sector():getEntity(stationIndex)
                else
                    GalaxyMap():setSelectedCoordinates(coords.x, coords.y)
                    GalaxyMap():show(coords.x, coords.y)
                end

                return
            end
        end
    end

end

function onNextRoutesPage()
    routesPage = routesPage + 1
    refreshUI()
end

function onPreviousRoutesPage()
    routesPage = math.max(0, routesPage - 1)
    refreshUI()
end

function onNextSellablesPage()
    sellablesPage = sellablesPage + 1
    refreshUI()
end

function onPreviousSellablesPage()
    sellablesPage = math.max(0, sellablesPage - 1)
    refreshUI()
end

function onNextBuyablesPage()
    buyablesPage = buyablesPage + 1
    refreshUI()
end

function onPreviousBuyablesPage()
    buyablesPage = math.max(0, buyablesPage - 1)
    refreshUI()
end

function onBuyShowButtonPressed(button_in)

    for index, button in pairs(buyableGoodButtons) do
        if button.index == button_in.index then
            Player().selectedObject = Sector():getEntity(buyable[buyablesPage * 15 + index].stationIndex)
            return
        end
    end

end

function onSellShowButtonPressed(button_in)

    for index, button in pairs(sellableGoodButtons) do
        if button.index == button_in.index then
            Player().selectedObject = Sector():getEntity(sellable[sellablesPage * 15 + index].stationIndex)
            return
        end
    end

end

function setSortFunction(default, alternative, buyable)

    if buyable == 1 then
        if buyableSortFunction == default then
            buyableSortFunction = alternative
        else
            buyableSortFunction = default
        end
    else
        if sellableSortFunction == default then
            sellableSortFunction = alternative
        else
            sellableSortFunction = default
        end
    end

    refreshUI()
end


function onBuyableNameLabelClick(index, button)
    setSortFunction(sortByNameAsc, sortByNameDes, 1)
end

function onBuyableStockLabelClick()
    setSortFunction(sortByStockAsc, sortByStockDes, 1)
end

function onBuyableVolLabelClick()
    setSortFunction(sortByVolAsc, sortByVolDes, 1)
end

function onBuyablePriceLabelClick()
    if getRarity().value < 1 then return end
    setSortFunction(sortByPriceAsc, sortByPriceDes, 1)
end

function onBuyablePriceFactorLabelClick()
    if getRarity().value < 2 then return end
    setSortFunction(sortByPriceFactorAsc, sortByPriceFactorDes, 1)
end

function onBuyableStationLabelClick()
    setSortFunction(sortByStationAsc, sortByStationDes, 1)
end

function onBuyableOnShipLabelClick()
    setSortFunction(sortByAmountOnShipDes, sortByAmountOnShipAsc, 1)
end


function onSellableNameLabelClick(index, button)
    setSortFunction(sortByNameAsc, sortByNameDes, 0)
end

function onSellableStockLabelClick()
    setSortFunction(sortByStockAsc, sortByStockDes, 0)
end

function onSellableVolLabelClick()
    setSortFunction(sortByVolAsc, sortByVolDes, 0)
end

function onSellablePriceLabelClick()
    if getRarity().value < 1 then return end
    setSortFunction(sortByPriceAsc, sortByPriceDes, 0)
end

function onSellablePriceFactorLabelClick()
    if getRarity().value < 2 then return end
    setSortFunction(sortByPriceFactorAsc, sortByPriceFactorDes, 0)
end

function onSellableStationLabelClick()
    setSortFunction(sortByStationAsc, sortByStationDes, 0)
end

function onSellableOnShipLabelClick()
    setSortFunction(sortByAmountOnShipDes, sortByAmountOnShipAsc, 0)
end
