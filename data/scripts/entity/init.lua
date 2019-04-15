if not onServer() then return end

local entity = Entity()

if entity:hasComponent(ComponentType.DockingPositions) then
    entity:addScriptOnce("entity/regrowdocks.lua")
end

if entity.allianceOwned then
    entity:addScriptOnce("entity/claimalliance.lua")
end

if entity:hasComponent(ComponentType.ShipAI) then
    entity:addScriptOnce("data/scripts/entity/orderchain.lua")
end

if entity.allianceOwned or entity.playerOwned then


    entity:addScriptOnce("mods/SectorManager/scripts/entity/SectorManager.lua")
    entity:addScriptOnce("mods/CarrierCommander/scripts/entity/CarrierCommander.lua")
end