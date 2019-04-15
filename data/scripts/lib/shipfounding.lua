
local ShipFounding = {}

ShipFounding.costs = {}
local costs = ShipFounding.costs

costs[0] = {material = Material(MaterialType.Iron),     money = 0}
costs[1] = {material = Material(MaterialType.Iron),     money = 0}
costs[2] = {material = Material(MaterialType.Iron),     money = 1000}
costs[3] = {material = Material(MaterialType.Titanium), money = 5000}
costs[4] = {material = Material(MaterialType.Titanium), money = 10000}
costs[5] = {material = Material(MaterialType.Titanium), money = 20000}
costs[6] = {material = Material(MaterialType.Naonite),  money = 50000}
costs[7] = {material = Material(MaterialType.Naonite),  money = 100000}
costs[8] = {material = Material(MaterialType.Trinium),  money = 200000}
costs[9] = {material = Material(MaterialType.Trinium),  money = 500000}
costs[10] = {material = Material(MaterialType.Xanion),  money = 750000}
costs[11] = {material = Material(MaterialType.Xanion),  money = 1000000}
costs[12] = {material = Material(MaterialType.Xanion),  money = 1500000}
costs[13] = {material = Material(MaterialType.Xanion),  money = 2000000}
costs[14] = {material = Material(MaterialType.Xanion),  money = 2500000}
costs[15] = {material = Material(MaterialType.Ogonite), money = 3000000}
costs[16] = {material = Material(MaterialType.Ogonite), money = 3500000}
costs[17] = {material = Material(MaterialType.Ogonite), money = 4000000}
costs[18] = {material = Material(MaterialType.Ogonite), money = 4500000}
costs[19] = {material = Material(MaterialType.Ogonite), money = 5000000}
costs[20] = {material = Material(MaterialType.Avorion), money = 6000000}
costs[21] = {material = Material(MaterialType.Avorion), money = 7000000}
costs[22] = {material = Material(MaterialType.Avorion), money = 8000000}
costs[23] = {material = Material(MaterialType.Avorion), money = 9000000}
costs[24] = {material = Material(MaterialType.Avorion), money = 10000000}

function ShipFounding.getCosts(ships)
    local money = 0
    local resources = {}

    for i = 0, MaterialType.Avorion do
        resources[i+1] = 0
    end

    local highest = 24

    if ships <= highest then
        money = costs[ships].money
        resources[costs[ships].material.value+1] = 500
    else
        resources[MaterialType.Avorion+1] = 500
        money = costs[highest].money
    end

    return money, resources, ships
end

function ShipFounding.getNextShipCosts(faction)

    if faction.isAlliance then
        faction = Alliance(faction.index)
    elseif faction.isPlayer then
        faction = Player(faction.index)
    end

    -- count number of ships
    local ships = 0
    for _, name in pairs({faction:getShipNames()}) do
        if faction:getShipType(name) == EntityType.Ship then
            ships = ships + 1
        end
    end

    return ShipFounding.getCosts(ships)
end

return ShipFounding
