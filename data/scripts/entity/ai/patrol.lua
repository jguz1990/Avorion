package.path = package.path .. ";data/scripts/lib/?.lua"
require ("stringutility")

if onServer() then

local waypoints
local current = 1
local waypointSpread = 2000 -- fly up to 20 km from the center

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AIPatrol
AIPatrol = {}

function AIPatrol.getUpdateInterval()
    return math.random() + 1.0
end

function AIPatrol.initialize(...)
    if onServer() then
        if not _restoring then
            -- ensure ai state change
            ShipAI():setPassive()
        end
        AIPatrol.setWaypoints({...})
    end
end

-- this function will be executed every frame on the server only
function AIPatrol.updateServer(timeStep)
    local ai = ShipAI()
    ai:setStatus("Patrolling Sector /* ship AI status*/"%_T, {})

    -- check if there are enemies
    -- don't attack civil ships
    if ai:isEnemyPresent(-40000, false) then
        AIPatrol.updateAttacking(timeStep)
    else
        AIPatrol.updateFlying(timeStep)
    end
end

function AIPatrol.updateFlying(timeStep)

    if not waypoints or #waypoints == 0 then
        waypoints = {}
        for i = 1, 5 do
            table.insert(waypoints, vec3(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)) * waypointSpread)
        end

        current = 1
    end

    local ship = Entity()
    local ai = ShipAI()

    local d = (ship:getBoundingSphere().radius * 2)
    local d2 = d * d

    if distance2(ship.translationf, waypoints[current]) < d2 then
        current = current + 1
        if current > #waypoints then
            current = 1
        end
    end

    ai:setFly(waypoints[current], ship:getBoundingSphere().radius)
end

function AIPatrol.updateAttacking(timeStep)
    local ai = ShipAI()
    if ai.state ~= AIState.Aggressive then
        if Entity().aiOwned then
            ai:setAggressive()
        else
            ai:setAggressive(false, true)
        end
    end
end

function AIPatrol.setWaypoints(waypointsIn)
    waypoints = waypointsIn
    current = 1
end

end
