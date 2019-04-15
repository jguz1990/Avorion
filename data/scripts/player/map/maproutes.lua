package.path = package.path .. ";data/scripts/lib/?.lua"
require("data/scripts/player/map/common")
require("ordertypes")
require("stringutility")
require("utility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace MapRoutes
MapRoutes = {}

if onClient() then

local routesContainer
local routesByShip = {}

function MapRoutes.initialize()
    local player = Player()

    player:registerCallback("onShowGalaxyMap", "onShowGalaxyMap")
    player:registerCallback("onSelectMapCoordinates", "onSelectMapCoordinates")

    player:registerCallback("onMapRenderAfterUI", "onMapRenderAfterUI")

    player:registerCallback("onShipOrderInfoUpdated", "onPlayerShipOrderInfoUpdated")
    player:registerCallback("onShipPositionUpdated", "onPlayerShipPositionUpdated")

    routesContainer = GalaxyMap():createContainer()
end

function MapRoutes.makeRoutes(faction, x, y)
    if not valid(faction) then return end

    for i, name in pairs({faction:getNamesOfShipsInSector(x, y)}) do
        local info = faction:getShipOrderInfo(name)
        MapRoutes.makeRoute(faction, name, info, {x=x, y=y})
    end
end

function MapRoutes.makeRoute(faction, name, info, start)

    local id = name .. "_" .. tostring(faction.index)
    local route = routesByShip[id]
    if route then
        route.container:clear()
    else
        local container = routesContainer:createContainer(Rect())
        route = {container = container}
        routesByShip[id] = route
    end

    route.info = info
    route.start = start

    if not info then return end
    if not start then return end
    if not info.chain then return end
    if #info.chain == 0 then return end
    if not info.currentIndex then return end
    if info.currentIndex == 0 then return end

    -- plot routes
    local visited = {}

    local i = info.currentIndex
    local cx, cy = start.x, start.y
    while i <= #info.chain do

        if visited[i] then break end
        visited[i] = true

        local current = info.chain[i]
        if not current then break end

        if current.action == OrderType.Jump then
            local line = route.container:createMapArrowLine()
            line.from = ivec2(cx, cy)
            line.to = ivec2(current.x, current.y)
            line.color = ColorARGB(0.4, 0, 0.8, 0)
            line.width = 10

            cx, cy = current.x, current.y
        end

        if current.action == OrderType.Loop then
            i = current.loopIndex
        else
            i = i + 1
        end
    end
end

function MapRoutes.onSelectMapCoordinates(x, y)
    -- we CANNOT rely on this callback happening after the MapCommands equivalent!
    -- update portraits
    routesContainer:clear()
    routesByShip = {}

    local player = Player()
    MapRoutes.makeRoutes(player, x, y)
    MapRoutes.makeRoutes(player.alliance, x, y)

end

function MapRoutes.onShowGalaxyMap()
    local player = Player()
    local alliance = player.alliance
    if alliance then
        alliance:registerCallback("onShipOrderInfoUpdated", "onAllianceShipOrderInfoUpdated")
        alliance:registerCallback("onShipPositionUpdated", "onAllianceShipPositionUpdated")
    end
end

function MapRoutes.onPlayerShipOrderInfoUpdated(name, info)
    if not info then return end

--    printTable(info)

    local player = Player()
    local x, y = player:getShipPosition(name)
    MapRoutes.makeRoute(player, name, info, {x=x, y=y})
end

function MapRoutes.onAllianceShipOrderInfoUpdated(name, info)
--    print ("onAllianceShipOrderInfoUpdated")
--    printTable(info)

    local player = Player()
    local alliance = player.alliance
    local x, y = alliance:getShipPosition(name)
    MapRoutes.makeRoute(alliance, name, info, {x=x, y=y})
end

function MapRoutes.onMapRenderAfterUI()
    MapRoutes.renderIcons()
    MapRoutes.renderTooltips()
end

function MapRoutes.renderIcons()
    local map = GalaxyMap()
    local renderer = UIRenderer()

    for name, route in pairs(routesByShip) do
        local info = route.info
        if not info then goto continue end

        local i = info.currentIndex
        local cx, cy = route.start.x, route.start.y
        while i <= #info.chain do

            local current = info.chain[i]
            if not current then break end

            if current.action == OrderType.Jump then
                cx, cy = current.x, current.y
            end

            if current.action then
                local sx, sy = GalaxyMap():getCoordinatesScreenPosition(ivec2(cx, cy))

                local orderType = OrderTypes[current.action]
                if orderType and orderType.pixelIcon and orderType.pixelIcon ~= "" then
                    renderer:renderCenteredPixelIcon(vec2(sx, sy), ColorRGB(1, 1, 1), orderType.pixelIcon)
                end
            end

            i = i + 1
        end

        ::continue::
    end

    renderer:display()
end

function MapRoutes.renderTooltips()
    local portraits = MapCommands.getSelectedPortraits()
    if #portraits == 0 then return end

    local tooltip = Tooltip()

    if #portraits == 1 then
        local portrait = portraits[1]
        local info = portrait.info

        MapRoutes.fillOrderInfoTooltip(tooltip, info)
    end

    local ship = Player().craft
    if ship then
        for _, portrait in pairs(portraits) do
            if portrait.name == ship.name and portrait.owner == ship.factionIndex then
                local line = TooltipLine(15, 14)
                line.ctext = "You can't command the craft you're steering."%_t
                line.ccolor = ColorRGB(1, 0.3, 0.3)
                tooltip:addLine(line)

                tooltip:addLine(TooltipLine(15, 15))
            end
        end
    end

    local line = TooltipLine(15, 14)
    line.ltext = "Ctrl:"%_t
    line.lcolor = ColorRGB(0, 1, 1)
    line.rtext = "Move icons"%_t
    line.rcolor = ColorRGB(0, 1, 1)
    tooltip:addLine(line)

    tooltip:addLine(TooltipLine(10, 10))

    local line = TooltipLine(15, 14)
    line.ltext = "Shift (hold):"%_t
    line.lcolor = ColorRGB(0, 1, 1)
    line.rtext = "Enchain commands"%_t
    line.rcolor = ColorRGB(0, 1, 1)
    tooltip:addLine(line)

    local renderer = TooltipRenderer(tooltip)

    local resolution = getResolution()
    renderer:draw(vec2(10, resolution.y))
end

function MapRoutes.fillOrderInfoTooltip(tooltip, info)
    if not info then return end
    if info.currentIndex == 0 then return end

    for i, action in pairs(info.chain) do

        local line = TooltipLine(20, 14)

        MapRoutes.getOrderDescription(action, i, line)

        if i == info.currentIndex then
            line.lcolor = ColorRGB(0, 1, 0)
            line.ccolor = ColorRGB(0, 1, 0)
            line.rcolor = ColorRGB(0, 1, 0)
        end

        if action.action and OrderTypes[action.action] and OrderTypes[action.action].icon then
            line.icon = OrderTypes[action.action].icon
            line.iconColor = ColorRGB(1, 1, 1)
        end

        tooltip:addLine(line)
    end

    tooltip:addLine(TooltipLine(20, 10))

end

function MapRoutes.getOrderDescription(order, i, line)
    if order.action == OrderType.Jump then
        line.ltext = "[${i}] Jump"%_t % {i=i}
        line.ctext = " >>> "
        line.rtext = order.x .. " : " .. order.y
    elseif order.action == OrderType.Mine then
        line.ltext = "[${i}] Mine Asteroids"%_t % {i=i}
    elseif order.action == OrderType.Salvage then
        line.ltext = "[${i}] Salvage Wreckages"%_t % {i=i}
    elseif order.action == OrderType.Loop then
        line.ltext = "[${i}] Loop"%_t % {i=i}
        line.ctext = " >>> "
        line.rtext = order.loopIndex
    elseif order.action == OrderType.Aggressive then
        line.ltext = "[${i}] Attack Enemies"%_t % {i=i}
    elseif order.action == OrderType.Patrol then
        line.ltext = "[${i}] Patrol Sector"%_t % {i=i}
    elseif order.action == OrderType.BuyGoods then
        line.ltext = "[${i}] Buy '${good}'"%_t % {i = i, good = order.args[1]}
        line.rtext = "Until ${amount} units"%_t % {amount = order.args[3]}
    elseif order.action == OrderType.SellGoods then
        line.ltext = "[${i}] Sell '${good}'"%_t % {i = i, good = order.args[1]}
        line.rtext = "Until ${amount} units"%_t % {amount = order.args[3]}
    elseif order.action == OrderType.RefineOres then
        line.ltext = "[${i}] Refine Ores"%_t % {i = i}
    end
end

function MapRoutes.onPlayerShipPositionUpdated(name, x, y)
--    print("onPlayerShipPositionUpdated %s %i %i", name, x, y)
end

function MapRoutes.onAllianceShipPositionUpdated(name, x, y)
--    print("onAllianceShipPositionUpdated %s %i %i", name, x, y)
end

end -- onClient()
