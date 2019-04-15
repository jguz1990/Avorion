package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")
require ("faction")
require ("callable")

-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace ClaimFromAlliance
ClaimFromAlliance = {}

-- if this function returns false, the script will not be listed in the interaction window,
-- even though its UI may be registered
function ClaimFromAlliance.interactionPossible(playerIndex, option)

    if onClient() then
        return not Galaxy():factionExists(Entity().factionIndex)
    else
        return not Galaxy():findFaction(Entity().factionIndex)
    end
end

-- create all required UI elements for the client side
function ClaimFromAlliance.initUI()
    ScriptUI():registerInteraction("Claim"%_t, "onClaim");
end

function ClaimFromAlliance.onClaim()
    invokeServerFunction("claim")
end

function ClaimFromAlliance.claim()
    if not ClaimFromAlliance.interactionPossible(callingPlayer) then return end

    local faction, ship, player = getInteractingFaction(callingPlayer)
    if not faction then return end

    Entity().factionIndex = faction.index

    terminate()
end
callable(ClaimFromAlliance, "claim")
