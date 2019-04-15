
package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")
require ("faction")
require ("callable")
require ("ordertypes")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace CraftOrders
CraftOrders = {}


function CraftOrders.initialize()
    if onServer() then
        Entity():registerCallback("onCraftSeatEntered", "onCraftSeatEntered")
    end
end

local function removeSpecialOrders()
    local entity = Entity()

    for index, name in pairs(entity:getScripts()) do
        if string.match(name, "data/scripts/entity/ai/") then
            entity:removeScript(index)
        end
    end
end

function CraftOrders.onCraftSeatEntered(entityId, seat, playerIndex, firstPlayer)
    if firstPlayer == true then
        removeSpecialOrders()
        Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders", nil, true)
    end
end

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function CraftOrders.interactionPossible(playerIndex, option)
    -- giving the own craft orders does not work
    if Entity().index == Player().craftIndex then
        return false
    end

    callingPlayer = Player().index
    if not checkEntityInteractionPermissions(Entity(), AlliancePrivilege.FlyCrafts) then
        return false
    end

    return true
end

-- create all required UI elements for the client side
function CraftOrders.initUI()

    local res = getResolution()
    local size = vec2(250, 370)

    local menu = ScriptUI()
    local window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    menu:registerWindow(window, "Orders"%_t)

    window.caption = "Craft Orders"%_t
    window.showCloseButton = 1
    window.moveable = 1

    local splitter = UIHorizontalMultiSplitter(Rect(window.size), 10, 10, 8)

    window:createButton(splitter:partition(0), "Idle"%_t, "onUserIdleOrder")
    window:createButton(splitter:partition(1), "Passive"%_t, "onUserPassiveOrder")
    window:createButton(splitter:partition(2), "Guard This Position"%_t, "onUserGuardOrder")
    window:createButton(splitter:partition(3), "Patrol Sector"%_t, "onUserPatrolOrder")
    window:createButton(splitter:partition(4), "Escort Me"%_t, "onUserEscortMeOrder")
    window:createButton(splitter:partition(5), "Attack Enemies"%_t, "onUserAttackEnemiesOrder")
    window:createButton(splitter:partition(6), "Mine"%_t, "onUserMineOrder")
    window:createButton(splitter:partition(7), "Salvage"%_t, "onUserSalvageOrder")
    window:createButton(splitter:partition(8), "Refine Ores"%_t, "onUserRefineOresOrder")
    --window:createButton(Rect(10, 250, 230 + 10, 30 + 250), "Attack My Targets", "onWingmanButtonPressed")

end

local function checkCaptain()
    local entity = Entity()

    if not checkEntityInteractionPermissions(Entity(), AlliancePrivilege.FlyCrafts) then
        return false
    end

    local captains = entity:getCrewMembers(CrewProfessionType.Captain)
    if not captains or captains == 0 then
        local faction = Faction()
        if faction then
            faction:sendChatMessage("", 1, "Your ship has no captain!"%_t)
        end

        return false
    end

    local pilot = entity:getPilotIndices()
    if pilot then
        local faction = Faction()
        if faction then
            faction:sendChatMessage("", 1, "Can't assign orders: Ship ${name} is piloted by a player!"%_t % {name = entity.name or ""})
        end

        return false
    end

    return true
end

function CraftOrders.onUserIdleOrder()
    if onClient() then
        invokeServerFunction("onUserIdleOrder")
        ScriptUI():stopInteraction()
        return
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
end

function CraftOrders.onUserPassiveOrder()
    if onClient() then
        invokeServerFunction("onUserPassiveOrder")
        ScriptUI():stopInteraction()
        return
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders", true)
end

if onClient() then
function CraftOrders.onUserGuardOrder()
    CraftOrders.onUserGuardPositionOrder(Entity().translationf)
end
end

function CraftOrders.onUserGuardPositionOrder(position)
    if onClient() then
        invokeServerFunction("onUserGuardPositionOrder", position)
        ScriptUI():stopInteraction()
        return
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "addGuardPositionOrder", position)
end

if onClient() then
function CraftOrders.onUserEscortMeOrder()
    CraftOrders.onUserEscortOrder(Player().craftIndex)
end
end

function CraftOrders.onUserEscortOrder(index)
    if onClient() then
        invokeServerFunction("onUserEscortOrder", index)
        ScriptUI():stopInteraction()
        return
    end

    if index == nil then
        local ship = Player().craft
        if ship == nil then return end
        index = ship.index
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "addEscortOrder", index)
end

function CraftOrders.onUserAttackEntityOrder(index)
    if onClient() then
        invokeServerFunction("onUserAttackEntityOrder", index);
        return
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "addAttackCraftOrder", index)
end

function CraftOrders.onUserFlyToPositionOrder(pos)
    if onClient() then
        invokeServerFunction("onUserFlyToPositionOrder", pos);
        return
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "addFlyToPositionOrder", pos)
end

function CraftOrders.onUserFlyThroughWormholeOrder(index)
    if onClient() then
        invokeServerFunction("onUserFlyThroughWormholeOrder", index);
        return
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "addFlyThroughWormholeOrder", index)
end


function CraftOrders.onUserAttackEnemiesOrder()
    if onClient() then
        invokeServerFunction("onUserAttackEnemiesOrder")
        ScriptUI():stopInteraction()
        return
    end

    local attackCivilShips = true
    local canFinish = false

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "addAggressiveOrder", attackCivilShips, canFinish)
end

function CraftOrders.onUserPatrolOrder()
    if onClient() then
        invokeServerFunction("onUserPatrolOrder")
        ScriptUI():stopInteraction()
        return
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "addPatrolOrder")
end

function CraftOrders.onUserMineOrder()
    if onClient() then
        invokeServerFunction("onUserMineOrder")
        ScriptUI():stopInteraction()
        return
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "addMineOrder", true)
end

function CraftOrders.onUserSalvageOrder()
    if onClient() then
        invokeServerFunction("onUserSalvageOrder")
        ScriptUI():stopInteraction()
        return
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "addSalvageOrder", true)
end

function CraftOrders.onUserRefineOresOrder()
    if onClient() then
        invokeServerFunction("onUserRefineOresOrder")
        ScriptUI():stopInteraction()
        return
    end

    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "clearAllOrders")
    Entity():invokeFunction("data/scripts/entity/orderchain.lua", "addRefineOresOrder", true)
end

if onServer() then

function CraftOrders.idle()
    if checkCaptain() then
        removeSpecialOrders()

        ShipAI():setIdle()
        return true
    end
end

function CraftOrders.passive()
    if checkCaptain() then
        removeSpecialOrders()

        ShipAI():setPassive()
        return true
    end
end


function CraftOrders.guardPosition(position)
    if checkCaptain() then
        removeSpecialOrders()

        local shipAI = ShipAI()
        shipAI:setStatus("Guarding Position /* ship AI status*/"%_T, {})
        shipAI:setGuard(position)
        return true
    end
end

function CraftOrders.escortEntity(index)
    local target = Sector():getEntity(index)

    if checkCaptain() and target then
        removeSpecialOrders()

        local shipAI = ShipAI()
        shipAI:setStatus("Escorting ${name} /* ship AI status*/"%_T, {name = target.name})
        shipAI:setEscort(target)
        return true
    end
end

function CraftOrders.attackEntity(index)
    local target = Sector():getEntity(index)

    if checkCaptain() and target then
        removeSpecialOrders()

        local shipAI = ShipAI()
        shipAI:setStatus("Attacking ${name} /* ship AI status*/"%_T, {name = target.name})
        shipAI:setAttack(target)
        return true
    end
end

function CraftOrders.flyToPosition(pos)
    if checkCaptain() then
        removeSpecialOrders()

        local shipAI = ShipAI()
        shipAI:setStatus("Flying to Position /* ship AI status*/"%_T, {})
        shipAI:setFly(pos, 0)
        return true
    end
end

function CraftOrders.flyThroughWormhole(targetId)
    local target = Sector():getEntity(targetId)
    if checkCaptain() and target then
        removeSpecialOrders()

        local ship = Entity()

        if target:hasComponent(ComponentType.Plan) then
            -- gate
            Entity():addScriptOnce("ai/flythroughgate.lua", targetId)
        else
            -- wormhole
            local shipAI = ShipAI()
            shipAI:setStatus("Flying Through Wormhole /* ship AI status*/"%_T, {})
            shipAI:setFly(target.translationf, 0)
        end

        return true
    end
end

function CraftOrders.salvage()
    if checkCaptain() then
        removeSpecialOrders()

        Entity():addScriptOnce("ai/salvage.lua")
        return true
    end
end

function CraftOrders.mine()
    if checkCaptain() then
        removeSpecialOrders()

        Entity():addScriptOnce("ai/mine.lua")
        return true
    end
end

function CraftOrders.patrolSector()
    if checkCaptain() then
        removeSpecialOrders()

        Entity():addScriptOnce("ai/patrol.lua")
        return true
    end
end

function CraftOrders.attackEnemies(attackCivilShips, canFinish)
    if checkCaptain() then
        removeSpecialOrders()

        local shipAI = ShipAI()
        shipAI:setStatus("Attacking Enemies /* ship AI status*/"%_T, {})
        shipAI:setAggressive(attackCivilShips, canFinish)
        return true
    end
end

function CraftOrders.buyGoods(...)
    if checkCaptain() then
        removeSpecialOrders()
        Entity():addScriptOnce("ai/buygoods.lua", ...)
        return true
    end
end

function CraftOrders.sellGoods(...)
    if checkCaptain() then
        removeSpecialOrders()
        Entity():addScriptOnce("ai/sellgoods.lua", ...)
        return true
    end
end

function CraftOrders.refineOres()
    if checkCaptain() then
        removeSpecialOrders()
        Entity():addScriptOnce("ai/refineores.lua")
        return true
    end
end


end

callable(CraftOrders, "onUserIdleOrder")
callable(CraftOrders, "onUserPassiveOrder")
callable(CraftOrders, "onUserGuardPositionOrder")
callable(CraftOrders, "onUserPatrolOrder")
callable(CraftOrders, "onUserEscortOrder")
callable(CraftOrders, "onUserAttackEntityOrder")
callable(CraftOrders, "onUserFlyThroughWormholeOrder")
callable(CraftOrders, "onUserAttackEnemiesOrder")
callable(CraftOrders, "onUserFlyToPositionOrder")
callable(CraftOrders, "onUserMineOrder")
callable(CraftOrders, "onUserSalvageOrder")
callable(CraftOrders, "onUserRefineOresOrder")

-- this function will be executed every frame both on the server and the client
--function update(timeStep)
--
--end
--
---- this function gets called every time the window is shown on the client, ie. when a player presses F
--function onShowWindow()
--
--end
--
---- this function gets called every time the window is shown on the client, ie. when a player presses F
--function onCloseWindow()
--
--end
