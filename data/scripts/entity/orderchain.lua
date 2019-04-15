package.path = package.path .. ";data/scripts/lib/?.lua"

local OrderTypes = require ("ordertypes")
require ("callable")
require ("faction")
require ("stringutility")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace OrderChain
OrderChain = {}

OrderChain.chain = {}
OrderChain.activeOrder = 0

function OrderChain.getUpdateInterval()
    return 1
end

function OrderChain.secure()
    return {chain = OrderChain.chain, activeOrder = OrderChain.activeOrder};
end

function OrderChain.restore(data)
    OrderChain.chain = data.chain
    OrderChain.activeOrder = data.activeOrder

    if OrderChain.activeOrder > 0 then
        OrderChain.activateOrder(OrderChain.chain[OrderChain.activeOrder])
    end
end


function OrderChain.getNumActions()
    return OrderType.NumActions - 1
end


function OrderChain.updateServer(timeStep)

    local entity = Entity()
    if entity:getPilotIndices() then
        ShipAI():setStatus("Player /* ship AI status*/"%_T, {})
        return
    end

    if OrderChain.activeOrder == 0 then
        -- setting this every tick is a safeguard against other potential issues
        -- setting the status is efficient enough to not send updates if nothing changed
        ShipAI():setStatus("Idle /* ship AI status */"%_T, {})
        return
    end

    local currentOrder = OrderChain.chain[OrderChain.activeOrder]
    local orderFinished = false

    if currentOrder.action == OrderType.Jump then
        if OrderChain.jumpOrderFinished(currentOrder.x, currentOrder.y) then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.Mine then
        if OrderChain.mineOrderFinished(currentOrder.persistent) then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.Salvage then
        if OrderChain.salvageOrderFinished(currentOrder.persistent) then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.Loop then
        orderFinished = true
    elseif currentOrder.action == OrderType.Aggressive then
        if OrderChain.aggressiveOrderFinished() then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.BuyGoods then
        if OrderChain.buyGoodsOrderFinished() then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.SellGoods then
        if OrderChain.sellGoodsOrderFinished() then
            orderFinished = true
        end
--    elseif currentOrder.action == OrderType.Patrol then
--         cannot finish
--    elseif currentOrder.action == OrderType.Escort then
--         cannot finish
    elseif currentOrder.action == OrderType.AttackCraft then
        if OrderChain.attackCraftOrderFinished(currentOrder.targetId) then
            orderFinished = true
        end
    elseif currentOrder.action == OrderType.FlyThroughWormhole then
        if OrderChain.flyThroughWormholeOrderFinished(currentOrder.x, currentOrder.y) then
            orderFinished = true
        end
--    elseif currentOrder.action == OrderType.FlyToPosition then
--         cannot finish
--    elseif currentOrder.action == OrderType.GuardPosition then
--         cannot finish
    elseif currentOrder.action == OrderType.RefineOres then
        if OrderChain.refineOresOrderFinished(currentOrder.x, currentOrder.y) then
            orderFinished = true
        end
    end

    if orderFinished then
        OrderChain.activeOrder = OrderChain.activeOrder + 1

        if #OrderChain.chain >= OrderChain.activeOrder then
            -- activate next order
            OrderChain.activateOrder(OrderChain.chain[OrderChain.activeOrder])
        else
            -- end of chain reached
            OrderChain.activeOrder = 0

            ShipAI():setStatus("Idle /* ship AI status */"%_T, {})
        end

        OrderChain.updateShipOrderInfo()
    end
end

function OrderChain.canEnchain(order)
    local last = OrderChain.chain[#OrderChain.chain]
    if not last then return true end

    if last.action == OrderType.Loop then
        OrderChain.sendError("Can't enchain anything after a loop."%_T)
        return false
    elseif last.action == OrderType.Patrol then
        OrderChain.sendError("Can't enchain anything after a patrol order."%_T)
        return false
    elseif last.action == OrderType.Escort then
        OrderChain.sendError("Can't enchain anything after an escort order."%_T)
        return false
    elseif last.action == OrderType.FlyToPosition then
        OrderChain.sendError("Can't enchain anything after a fly order."%_T)
        return false
    elseif last.action == OrderType.GuardPosition then
        OrderChain.sendError("Can't enchain anything after a guard order."%_T)
        return false
    elseif last.action == OrderType.Mine and last.persistent then
        OrderChain.sendError("Can't enchain anything after a persistent mine order."%_T)
        return false
    elseif last.action == OrderType.Salvage and last.persistent then
        OrderChain.sendError("Can't enchain anything after a persistent salvage order."%_T)
        return false
    end

    return true
end

function OrderChain.sendError(msg, ...)
    if callingPlayer then
        local player = Player(callingPlayer)
        player:sendChatMessage("", ChatMessageType.Error, msg, ...)
    end
end

function OrderChain.enchain(order)
    -- we only clear when setting a new order, not after the
    -- chain was run through to keep as much information around as possible
    if OrderChain.activeOrder == 0 then
        OrderChain.clear()
    end

    table.insert(OrderChain.chain, order)
    OrderChain.updateChain()
end

function OrderChain.updateChain()

    -- activate the first order if it is the only one
    if #OrderChain.chain == 1 then
        OrderChain.activeOrder = 1
        OrderChain.activateOrder(OrderChain.chain[1])
    end

    OrderChain.updateShipOrderInfo()
end

function OrderChain.undoOrder(x, y)
    if onClient() then
        invokeServerFunction("undoOrder", x, y)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local chain = OrderChain.chain
    local i = OrderChain.activeOrder

    if i and i > 0 and i < #chain then
        OrderChain.chain[#OrderChain.chain] = nil
        OrderChain.updateChain()
    elseif i and i > 0 and i == #chain and chain[#chain].action == OrderType.Jump then
        OrderChain.clearAllOrders()
    else
        OrderChain.sendError("Cannot undo last order."%_T)
    end

end
callable(OrderChain, "undoOrder")

function OrderChain.addJumpOrder(x, y)
    if onClient() then
        invokeServerFunction("addJumpOrder", x, y)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then
            local player = Player(callingPlayer)
            player:sendChatMessage("", ChatMessageType.Error, "You don't have permission to do that."%_T)
            return
        end
    end

    local shipX, shipY = Sector():getCoordinates()

    for _, action in pairs(OrderChain.chain) do
        if action.action == OrderType.Jump then
            shipX = action.x
            shipY = action.y
        end
    end

    local jumpValid, error = Entity():isJumpRouteValid(shipX, shipY, x, y)
    if jumpValid then
        local order = {action = OrderType.Jump, x = x, y = y}

        if OrderChain.canEnchain(order) then
            OrderChain.enchain(order)
        end
    else
        if callingPlayer then
            local player = Player(callingPlayer)
            player:sendChatMessage("", ChatMessageType.Error, error)
        end
    end
end
callable(OrderChain, "addJumpOrder")

function OrderChain.addMineOrder(persistent)
    if onClient() then
        invokeServerFunction("addMineOrder", persistent)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end
    local order = {action = OrderType.Mine, persistent = persistent}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addMineOrder")

function OrderChain.addSalvageOrder(persistent)
    if onClient() then
        invokeServerFunction("addSalvageOrder", persistent)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local order = {action = OrderType.Salvage, persistent = persistent}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addSalvageOrder")

function OrderChain.addLoop(a, b)
    if onClient() then
        invokeServerFunction("addLoop", a, b)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

--    print ("addLoop " .. tostring(a) .. " " .. tostring(b))

    local loopIndex
    if a and not b then
        -- interpret as action index
        loopIndex = a
    elseif a and b then
        -- interpret as coordinates
        local x, y = a, b
        local cx, cy = Sector():getCoordinates()
        local i = OrderChain.activeOrder
        local chain = OrderChain.chain

        while i > 0 and i <= #chain do
            local current = chain[i]

            if cx == x and cy == y then
                loopIndex = i
                break
            end

            if current.action == OrderType.Jump then
                cx, cy = current.x, current.y
            end

            i = i + 1
        end

        if not loopIndex then
            OrderChain.sendError("Could not find any orders at %i:%i!"%_T, x, y)
        end
    end

    if not loopIndex or loopIndex == 0 or loopIndex > #OrderChain.chain then return end

    local order = {action = OrderType.Loop, loopIndex = loopIndex}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addLoop")

function OrderChain.addAggressiveOrder(attackCivilShips, canFinish)
    if onClient() then
        invokeServerFunction("addAggressiveOrder", attackCivilShips, canFinish)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    -- station aggressive orders don't finish
    if Entity().type == EntityType.Station then canFinish = false end

    local order = {
        action = OrderType.Aggressive,
        attackCivilShips = attackCivilShips,
        canFinish = canFinish,
    }

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addAggressiveOrder")

function OrderChain.addPatrolOrder()
    if onClient() then
        invokeServerFunction("addPatrolOrder")
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local order = {action = OrderType.Patrol}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addPatrolOrder")

function OrderChain.addEscortOrder(craftId, factionIndex, craftName)
    if onClient() then
        invokeServerFunction("addEscortOrder", craftId, factionIndex, craftName)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    if not craftId then
        local sector = Sector()
        if not sector then return end

        local entity = sector:getEntityByFactionAndName(factionIndex, craftName)
        if not entity then return end

        craftId = entity.index
    end

    local order = {action = OrderType.Escort, craftId = craftId.string}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addEscortOrder")

function OrderChain.addBuyOrder(...)
    if onClient() then
        invokeServerFunction("addBuyOrder", ...)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local order = {action = OrderType.BuyGoods, args = {...}}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addBuyOrder")

function OrderChain.addSellOrder(...)
    if onClient() then
        invokeServerFunction("addSellOrder", ...)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local order = {action = OrderType.SellGoods, args = {...}}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addSellOrder")

function OrderChain.addAttackCraftOrder(targetId)
    if onClient() then
        invokeServerFunction("addAttackCraftOrder", targetId)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local order = {action = OrderType.AttackCraft, targetId = targetId.string}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addAttackCraftOrder")

function OrderChain.addFlyThroughWormholeOrder(targetId)
    if onClient() then
        invokeServerFunction("addFlyThroughWormholeOrder", targetId)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local order = {action = OrderType.FlyThroughWormhole, targetId = targetId.string}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addFlyThroughWormholeOrder")

function OrderChain.addFlyToPositionOrder(position)
    if onClient() then
        invokeServerFunction("addFlyToPositionOrder", position)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local order = {action = OrderType.FlyToPosition, px = position.x, py = position.y, pz = position.z}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addFlyToPositionOrder")

function OrderChain.addGuardPositionOrder(position)
    if onClient() then
        invokeServerFunction("addGuardPositionOrder", position)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local order = {action = OrderType.GuardPosition, px = position.x, py = position.y, pz = position.z}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addGuardPositionOrder")

function OrderChain.addRefineOresOrder()
    if onClient() then
        invokeServerFunction("addRefineOresOrder")
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    local order = {action = OrderType.RefineOres}

    if OrderChain.canEnchain(order) then
        OrderChain.enchain(order)
    end
end
callable(OrderChain, "addRefineOresOrder")


function OrderChain.clearAllOrders(setPassive, noIdleOrder)
    if onClient() then
        invokeServerFunction("clearAllOrders", setPassive, noIdleOrder)
        return
    end

    if callingPlayer then
        local owner, _, player = checkEntityInteractionPermissions(Entity(), AlliancePrivilege.ManageShips)
        if not owner then return end
    end

    OrderChain.clear()
    OrderChain.updateChain()

    if noIdleOrder ~= true then
        if setPassive then
            Entity():invokeFunction("data/scripts/entity/craftorders.lua", "passive")
        else
            Entity():invokeFunction("data/scripts/entity/craftorders.lua", "idle")
        end
    end
end
callable(OrderChain, "clearAllOrders")


function OrderChain.updateShipOrderInfo()
    local entity = Entity()

    local owner = Faction(entity.factionIndex)
    if owner.isPlayer then
        owner = Player(entity.factionIndex)
    elseif owner.isAlliance then
        owner = Alliance(entity.factionIndex)
    else
        owner = nil
    end

    if owner then
        owner:setShipOrderInfo(Entity().name, OrderChain.getOrderInfo())
    end
end

function OrderChain.getOrderInfo()
    local x, y = Sector():getCoordinates()

    local info = {}
    info.chain = {}
    info.currentIndex = OrderChain.activeOrder
    info.coordinates = {x=x, y=y}

    for _, action in pairs(OrderChain.chain) do
        local newEntry = {}
        for key, value in pairs(action) do
            newEntry[key] = value
        end

        newEntry.name = OrderTypes[action.action].name
        newEntry.icon = OrderTypes[action.action].icon
        newEntry.pixelIcon = OrderTypes[action.action].pixelIcon

        table.insert(info.chain, newEntry)
    end

    return info
end

function OrderChain.activateOrder(order)
    if order.action == OrderType.Jump then
        OrderChain.activateJump(order.x, order.y)
    elseif order.action == OrderType.Mine then
        OrderChain.activateMine()
    elseif order.action == OrderType.Salvage then
        OrderChain.activateSalvage()
    elseif order.action == OrderType.Loop then
        OrderChain.activateLoop(order.loopIndex)
    elseif order.action == OrderType.Aggressive then
        OrderChain.activateAggressive(order.attackCivilShips, order.canFinish)
    elseif order.action == OrderType.Patrol then
        OrderChain.activatePatrol()
    elseif order.action == OrderType.Escort then
        OrderChain.activateEscort(order.craftId)
    elseif order.action == OrderType.BuyGoods then
        OrderChain.activateBuyGoods(unpack(order.args))
    elseif order.action == OrderType.SellGoods then
        OrderChain.activateSellGoods(unpack(order.args))
    elseif order.action == OrderType.AttackCraft then
        OrderChain.activateAttackCraft(order.targetId)
    elseif order.action == OrderType.FlyThroughWormhole then
        OrderChain.activateFlyThroughWormhole(order.targetId)
    elseif order.action == OrderType.FlyToPosition then
        OrderChain.activateFlyToPosition(order.px, order.py, order.pz)
    elseif order.action == OrderType.GuardPosition then
        OrderChain.activateGuardPosition(order.px, order.py, order.pz)
    elseif order.action == OrderType.RefineOres then
        OrderChain.activateRefineOres()
    end
end

function OrderChain.activateJump(x, y)
    local ai = ShipAI()
    ai:setStatus("Jumping to ${x}:${y} /* ship AI status */"%_T, {x=x, y=y})
    ai:setJump(x, y)
--    print("activated jump to sector " .. x .. ":" .. y)
end

function OrderChain.activateMine()
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "mine")
--    print("activated mine")
end

function OrderChain.activateSalvage()
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "salvage")
--    print("activated salvage")
end

function OrderChain.activateLoop(loopIndex)
    OrderChain.activeOrder = loopIndex
    OrderChain.activateOrder(OrderChain.chain[OrderChain.activeOrder])
--    print("activated loop: " .. loopIndex)
end

function OrderChain.activateAggressive(attackCivilShips, canFinish)
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "attackEnemies", attackCivilShips, canFinish)
--    print("activated aggressive")
end

function OrderChain.activatePatrol()
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "patrolSector")
--    print("activated patrol")
end

function OrderChain.activateEscort(craftId)
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "escortEntity", craftId)
--    print("activated escort")
end

function OrderChain.activateBuyGoods(...)
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "buyGoods", ...)
--    print("activated buy goods")
end

function OrderChain.activateSellGoods(...)
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "sellGoods", ...)
--    print("activated sell goods")
end

function OrderChain.activateAttackCraft(targetId)
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "attackEntity", targetId)
--    print("activated attack craft")
end
function OrderChain.activateFlyThroughWormhole(targetId)
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "flyThroughWormhole", targetId)
--    print("activated fly through wormhole")
end
function OrderChain.activateFlyToPosition(px, py, pz)
    local position = vec3(px, py, pz)
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "flyToPosition", position)
--    print("activated fly to position")
end
function OrderChain.activateGuardPosition(px, py, pz)
    local position = vec3(px, py, pz)
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "guardPosition", position)
--    print("activated guard position")
end
function OrderChain.activateRefineOres()
    Entity():invokeFunction("data/scripts/entity/craftorders.lua", "refineOres")
--    print("activated refine ores")
end


function OrderChain.jumpOrderFinished(targetX, targetY)
    local x, y = Sector():getCoordinates()

    if x == targetX and y == targetY then
        return true
    end

    return false
end

function OrderChain.mineOrderFinished(persistent)
    local entity = Entity()
    if not entity:hasScript("data/scripts/entity/ai/mine.lua") then
--        print("missing mine script")
        return true
    end

    if persistent then return false end

    for _, asteroid in pairs({Sector():getEntitiesByComponent(ComponentType.MineableMaterial)}) do
        if asteroid.type == EntityType.Asteroid then
            if asteroid:getMineableResources() ~= nil then
                return false
            end
        end
    end

--    print("nothing to mine")
    entity:removeScript("data/scripts/entity/ai/mine.lua")
    return true
end

function OrderChain.salvageOrderFinished(persistent)
    local entity = Entity()
    if not entity:hasScript("data/scripts/entity/ai/salvage.lua") then
--        print("missing salvage script")
        return true
    end

    if persistent then return false end

    for _, wreckage in pairs({Sector():getEntitiesByComponent(ComponentType.MineableMaterial)}) do
        if wreckage.type == EntityType.Wreckage then
            if wreckage:getMineableResources() ~= nil then
                return false
            end
        end
    end

--    print("nothing to salvage")
    entity:removeScript("data/scripts/entity/ai/salvage.lua")
    return true
end

function OrderChain.aggressiveOrderFinished()
    local entity = Entity()
    if ShipAI().state ~= AIState.Aggressive then
        ShipAI():setIdle()
        return true
    end

    return false
end

function OrderChain.buyGoodsOrderFinished()
    return not Entity():hasScript("data/scripts/entity/ai/buygoods.lua")
end

function OrderChain.sellGoodsOrderFinished()
    return not Entity():hasScript("data/scripts/entity/ai/sellgoods.lua")
end

function OrderChain.attackCraftOrderFinished(targetId)
    return Sector():getEntity(targetId) == nil
end

function OrderChain.flyThroughWormholeOrderFinished(x, y)
    local currentX, currentY = Sector():getCoordinates()
    if currentX == x and currentY == y then return true end

    return false
end

function OrderChain.refineOresOrderFinished(x, y)
    return not Entity():hasScript("data/scripts/entity/ai/refineores.lua")
end

function OrderChain.clear()
    OrderChain.chain = {}
    OrderChain.activeOrder = 0
end
