
if onClient() then return end

package.path = package.path .. ";data/scripts/lib/?.lua"
require("stringutility")

local gateId
local finalPhase

function getUpdateInterval()
    return 2
end

function secure()
    return {gateId = gateId}
end

function restore(data)
    gateId = data.gateId
end

function initialize(gate)
    local ship = Entity()
    ship:registerCallback("onSectorEntered", "stop")

    gateId = gate

    ShipAI():setStatus("Flying Through Gate /* ship AI status*/"%_T, {})
end

-- this function will be executed every frame on the server only
function updateServer(timeStep)
    if gateId == nil then stop() return end

    local ship = Entity()
    local shipRadius = ship:getBoundingSphere().radius

    local gate = Sector():getEntity(Uuid(gateId))
    if gate == nil then stop() end

    -- determine best direction for entering the gate
    local entryDistance = shipRadius * 2 + gate:getBoundingSphere().radius

    local entryPosition
    if dot(gate.look, ship.translationf - gate.translationf) > 0 then
        entryPosition = gate.translationf + gate.look * entryDistance
    else
        entryPosition = gate.translationf - gate.look * entryDistance
    end

    -- determine distance to gate-entry-line
    local entryDirection = gate.look
    local entryShip = ship.translationf - entryPosition
    local entryGate = gate.translationf - entryPosition

    local dist2 = dot(entryGate, entryGate)
    local t = dot(entryShip, entryGate) / dist2

    if t < 0 then t = 0 end
--    if t > 1 then t = 1 end

    local distanceVector = entryPosition + entryGate * t - ship.translationf
    local distanceToEntry2 = dot(distanceVector, distanceVector)

    if finalPhase ~= true and distanceToEntry2 > (shipRadius + 10) * (shipRadius + 10) then
        -- fly to the entry of the gate
        ShipAI():setFly(entryPosition, 0)
    else
        -- fly into the gate
        finalPhase = true
        ShipAI():setFly(gate.translationf, 0, gate)
    end
end

function stop()
    ShipAI():setPassive()
    terminate()
end
