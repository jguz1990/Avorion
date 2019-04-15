
if onClient() then return end

package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

require ("stringutility")
require ("goods")
local DockAI = require ("entity/ai/dock")
local TradeUT = require ("entity/ai/tradeutility")

local self = TradeUT
self.data.name = ""
self.data.margin = nil
self.data.partner = nil

-- ## Things that can go wrong: ## --
-- no station buys the goods                            -> critical error
-- stations buy the goods, but not enough space         -> soft error
-- stations buy the goods, but unfitting prices         -> soft error
-- other player doesn't have enough money               -> soft error

-- Critical Error: notify & block
-- Soft Error: keep trying / wait, after 10 minutes: notify & keep trying

function initialize(name, margin, amount, preferOwn)
    self.data.name = name
    self.data.amount = amount or 0 -- "amount" is the amount that should be LEFT after all selling is done

    -- filters & priority
    if type(margin) == "number" then
        self.data.margin = margin
    else
        self.data.margin = nil
    end

    self.data.preferOwn = preferOwn
end

function sell(ship, station)
    -- buy goods
    local amount = getRemainingAmountToFulfill()
    local script = self.data.partner.script

    -- when the ship sells, the station buys from the ship
    local ok, results = station:invokeFunction(script, "buyFromShip", ship.index, self.data.name, amount, true)

--    print ("sold %i %s to %s", amount, self.data.name, tostring(self.data.partner.script))
--    print ("ok: " .. ok)
end

function updateServer(timeStep)

    TradeUT.updateErrorHandling(timeStep)

    if not Entity():hasScript("tradingoverview.lua") then
        -- critical error: we don't have a trading system to gather sector data
        TradeUT.setCriticalError("You have to install a Trading System in the ship for trading to work."%_T)
        ShipAI():setStatus("Error selling '${name}': No Trading System Installed"%_T, {name = self.data.name})
        return
    end

    -- Check if we're done yet
    local required = getRemainingAmountToFulfill()
    if required == 0 then
--        print ("required: " .. required)
        terminate()
        return
    end

    if not self.data.partner then
        updateFindingPartner()
    else
        TradeUT.updateDocking(timeStep, sell)
    end
end

function updateFindingPartner()
    local stationId, script, full, badMargin = findBuyer()

    if stationId and script then
        self.data.partner = {id = stationId, script = script}
    else
        self.data.partner = nil
    end

    if not self.data.partner then
        if not full and not badMargin then
            -- critical error: No partner found that buys the desired goods
            TradeUT.setCriticalError("No merchant found that buys '%s'."%_T, self.data.name)
            ShipAI():setStatus("Error selling '${name}': No merchant buying"%_T, {name = self.data.name})
            return
        end

        ShipAI():setStatus("Looking for merchant to sell '${name}'"%_T, {name = self.data.name})

        if full and badMargin then
            -- soft error
            TradeUT.setSoftError("No merchant has room for '%s' or a matching price."%_T, self.data.name)
            return
        elseif full then
            -- soft error
            TradeUT.setSoftError("No merchant has room for '%s'."%_T, self.data.name)
            return
        elseif badMargin then
            -- soft error
            TradeUT.setSoftError("No merchant accepts '%s' for a matching price."%_T, self.data.name)
            return
        end
    end
end

function findBuyer()
    local ship = Entity()

    -- find a station that sells the goods
    local ok, sellable, buyable, routes = ship:invokeFunction("tradingoverview.lua", "getData")

    if ok and ok == 3 then
        TradeUT.setCriticalError("You have to install a Trading System in the ship for trading to work."%_T)
        return
    elseif (not ok or ok ~= 0) then
        TradeUT.setCriticalError("Error communicating with trading system, code: %s."%_T, tostring(ok))
        return
    elseif not sellable then
        TradeUT.setSoftError("Error communicating with trading system, no sellables."%_T)
        return
    end

    local full = false
    local badMargin = false
    local offers = {}
    for _, offer in pairs(sellable) do
        if offer.good.name == self.data.name then
            if offer.stock >= offer.maxStock then
                full = true
                goto continue
            end

            -- a bad margin is never possible with our own stations
            if self.data.margin and offer.owner ~= ship.factionIndex then
                local margin = offer.price / goods[offer.good.name].price
                if margin < self.data.margin then
                    badMargin = true
                    goto continue
                end
            end

            table.insert(offers, offer)

            ::continue::
        end
    end

    if #offers == 0 then
        return nil, nil, full, badMargin
    end

    -- order offers in ascending order -> cheapest first, at same price prefer stations with larger stock (-> less flying around)
    table.sort(offers, function(a, b)
            if self.data.preferOwn then
                if a.owner == ship.factionIndex and b.owner ~= ship.factionIndex then
                    return true
                end

                if b.owner == ship.factionIndex and a.owner ~= ship.factionIndex then
                    return false
                end
            end

            if a.price == b.price then
                return a.stock > b.stock
            end

            return a.price > b.price
        end )

    return tostring(offers[1].stationIndex), offers[1].script, full, badMargin
end

function getRemainingAmountToFulfill()
    local cargos = Entity():getCargos()

    for good, amount in pairs(cargos) do
        if good.name == self.data.name then
            return math.max(amount - self.data.amount, 0)
        end
    end

    return self.data.amount
end

