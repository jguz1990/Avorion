package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("galaxy")
require ("faction")
require ("stringutility")
require ("callable")
local SectorSpecifics = require ("sectorspecifics")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace AncientGate
AncientGate = {}

local gateReady
local enabledTime = 0

function AncientGate.getUpdateInterval()
    return 1
end

function AncientGate.initialize()
    local entity = Entity()

    if onServer() then
        -- get callbacks for sector readiness
        entity:registerCallback("destinationSectorReady", "updateTooltip")

        AncientGate.updateTooltip()
    end

    if onClient() then
        invokeServerFunction("updateTooltip")
        entity:registerCallback("onSelected", "updateTooltip")

        if EntityIcon().icon == "" then
            EntityIcon().icon = "data/textures/icons/pixel/gate.png"
        end

        entity.title = "Ancient Gate"%_t

        AncientGate.updateClient(0.0)
    end
end

function AncientGate.disableMeshes()
    local mesh = PlanMesh()

    mesh:disableMesh(BlockShading.WormHole, MaterialType.Iron)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Titanium)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Naonite)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Trinium)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Xanion)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Ogonite)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Avorion)
end

function AncientGate.enableMeshes()
    local mesh = PlanMesh()
    mesh:enableAll()
end

function AncientGate.update(timeStep)
    enabledTime = enabledTime - timeStep

    local first = Sector():getEntitiesByScript("data/scripts/systems/teleporterkey1.lua")

    if first then
        enabledTime = 15 * 60
    end

    WormHole().enabled = enabledTime > 0
end

function AncientGate.updateClient(timeStep)

    if enabledTime > 0 then
        AncientGate.enableMeshes()
    else
        AncientGate.disableMeshes()
    end
end

function AncientGate.updateTooltip(ready)

    if onServer() then
        -- on the server, check if the sector is ready,
        -- then invoke client sided tooltip update with the ready variable
        local entity = Entity()
        local transferrer = EntityTransferrer(entity.index)

        ready = transferrer.sectorReady

        if not callingPlayer then
            broadcastInvokeClientFunction("updateTooltip", ready);
        else
            invokeClientFunction(Player(callingPlayer), "updateTooltip", ready)
        end
    else
        if type(ready) == "boolean" then
            gateReady = ready
        end

        -- on the client, calculate the fee and update the tooltip
        local user = Player()
        local ship = Sector():getEntity(user.craftIndex)

        -- during login/loading screen it's possible that the player still has to be placed in his drone, so ship is nil
        if not ship then return end

        local shipFaction = Faction(ship.factionIndex)
        if shipFaction then
            user = shipFaction
        end

        local tooltip = EntityTooltip(Entity().index)

        if not gateReady then
            tooltip:setDisplayTooltip(1, "Status"%_t, "Not Ready"%_t)
        else
            tooltip:setDisplayTooltip(1, "Status"%_t, "Ready"%_t)
        end
    end
end
callable(AncientGate, "updateTooltip")

function AncientGate.canTransfer(index)
    return enabledTime > 0
end
