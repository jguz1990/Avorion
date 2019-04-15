package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("galaxy")
require ("stringutility")
require ("randomext")
local PlanGenerator = require ("plangenerator")
local ShipUtility = require ("shiputility")


local PirateGenerator = {}

function PirateGenerator.getScaling()
    local scaling = Sector().numPlayers

    if scaling == 0 then scaling = 1 end
    return scaling
end


function PirateGenerator.createScaledOutlaw(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 0.75 * scaling, "Outlaw"%_T)
end

function PirateGenerator.createScaledBandit(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 1.0 * scaling, "Bandit"%_T)
end

function PirateGenerator.createScaledPirate(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 1.5 * scaling, "Pirate"%_T)
end

function PirateGenerator.createScaledMarauder(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 2.0 * scaling, "Marauder"%_T)
end

function PirateGenerator.createScaledDisruptor(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 2.0 * scaling, "Disruptor"%_T)
end

function PirateGenerator.createScaledRaider(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 4.0 * scaling, "Raider"%_T)
end

function PirateGenerator.createScaledRavager(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 8.0 * scaling, "Ravager"%_T)
end

function PirateGenerator.createScaledBoss(position)
    local scaling = PirateGenerator.getScaling()
    return PirateGenerator.create(position, 30.0 * scaling, "Pirate Mothership"%_T)
end


function PirateGenerator.createOutlaw(position)
    return PirateGenerator.create(position, 0.75, "Outlaw"%_T)
end

function PirateGenerator.createBandit(position)
    return PirateGenerator.create(position, 1.0, "Bandit"%_T)
end

function PirateGenerator.createPirate(position)
    return PirateGenerator.create(position, 1.5, "Pirate"%_T)
end

function PirateGenerator.createMarauder(position)
    return PirateGenerator.create(position, 2.0, "Marauder"%_T)
end

function PirateGenerator.createDisruptor(position)
    return PirateGenerator.create(position, 2.0, "Disruptor"%_T)
end

function PirateGenerator.createRaider(position)
    return PirateGenerator.create(position, 4.0, "Raider"%_T)
end

function PirateGenerator.createRavager(position)
    return PirateGenerator.create(position, 8.0, "Ravager"%_T)
end

function PirateGenerator.createBoss(position)
    return PirateGenerator.create(position, 30.0, "Pirate Mothership"%_T)
end

function PirateGenerator.create(position, volumeFactor, title)
    position = position or Matrix()
    local x, y = Sector():getCoordinates()
    PirateGenerator.pirateLevel = PirateGenerator.pirateLevel or Balancing_GetPirateLevel(x, y)

    local faction = Galaxy():getPirateFaction(PirateGenerator.pirateLevel)

    local volume = Balancing_GetSectorShipVolume(x, y) * volumeFactor;

    local plan = PlanGenerator.makeShipPlan(faction, volume)
    local ship = Sector():createShip(faction, "", plan, position)

    PirateGenerator.addPirateEquipment(ship, title)

    ship.crew = ship.minCrew
    ship.shieldDurability = ship.shieldMaxDurability

    return ship
end

function PirateGenerator.getPirateFaction()
    local x, y = Sector():getCoordinates()
    PirateGenerator.pirateLevel = PirateGenerator.pirateLevel or Balancing_GetPirateLevel(x, y)
    return Galaxy():getPirateFaction(PirateGenerator.pirateLevel)
end

function PirateGenerator.addPirateEquipment(craft, title)
    if title == "Outlaw" then
        ShipUtility.addMilitaryEquipment(craft, 0.25, 0)
    elseif title == "Bandit" then
        ShipUtility.addMilitaryEquipment(craft, 0.5, 0)
    elseif title == "Pirate" then
        ShipUtility.addMilitaryEquipment(craft, 0.75, 0)
    elseif title == "Marauder" then
        local type = random():getInt(1, 3)
        if type == 1 then
            ShipUtility.addDisruptorEquipment(craft)
        elseif type == 2 then
            ShipUtility.addArtilleryEquipment(craft)
        elseif type == 3 then
            ShipUtility.addCIWSEquipment(craft)
        end
    elseif title == "Disruptor" then
        local type = random():getInt(1, 2)
        if type == 1 then
            ShipUtility.addDisruptorEquipment(craft)
        elseif type == 2 then
            ShipUtility.addCIWSEquipment(craft)
        end
    elseif title == "Raider" then
        local type = random():getInt(1, 3)
        if type == 1 then
            ShipUtility.addDisruptorEquipment(craft)
        elseif type == 2 then
            ShipUtility.addPersecutorEquipment(craft)
        elseif type == 3 then
            ShipUtility.addTorpedoBoatEquipment(craft)
        end
    elseif title == "Ravager" then
        local type = random():getInt(1, 2)
        if type == 1 then
            ShipUtility.addArtilleryEquipment(craft)
        elseif type == 2 then
            ShipUtility.addPersecutorEquipment(craft)
        end
    elseif title == "Mothership" then
        local type = random():getInt(1, 2)
        if type == 1 then
            ShipUtility.addCarrierEquipment(craft)
        elseif type == 2 then
            ShipUtility.addFlagShipEquipment(craft)
        end
        ShipUtility.addBossAntiTorpedoEquipment(boss)
    else
        ShipUtility.addMilitaryEquipment(craft, 1, 0)
    end

    if craft.numTurrets == 0 then
        ShipUtility.addMilitaryEquipment(craft, 1, 0)
    end

    ShipAI(craft.index):setAggressive()
    craft.title = title
    craft.shieldDurability = craft.shieldMaxDurability

    craft:setValue("is_pirate", 1)
end


return PirateGenerator
