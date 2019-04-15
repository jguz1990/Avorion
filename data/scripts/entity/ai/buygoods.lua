
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
-- not enough cargo space for desired amount of goods   -> critical error
-- no station sells the goods                           -> critical error
-- stations sell the goods, but none in stock           -> soft error
-- stations sell the goods, but not enough in stock     -> soft error
-- stations sell the goods, but unfitting prices        -> soft error
-- own player doesn't have enough money                 -> soft error

-- Critical Error: notify & block
-- Soft Error: keep trying / wait, after 10 minutes: notify & keep trying

function initialize(name, margin, amount)
    self.data.name = name
    self.data.amount = amount

    -- filters & priority
    if type(margin) == "number" then
        self.data.margin = margin
    else
        self.data.margin = nil
    end

--    print ("init buy goods: %i %s for at least %s", amount, name, margin)

end

function buy(ship, station)
    -- buy goods
    local amount = getRemainingAmountToFulfill()
    local script = self.data.partner.script

    -- when the ship buys, the station sells to the ship
    local ok, results = station:invokeFunction(script, "sellToShip", ship.index, self.data.name, amount, true)

--    print ("bought %i %s from %s", amount, self.data.name, tostring(self.data.partner.script))
--    print ("ok: " .. ok)
end

function updateServer(timeStep)

    TradeUT.updateErrorHandling(timeStep)

    if not Entity():hasScript("tradingoverview.lua") then
        -- critical error: we don't have a trading system to gather sector data
        TradeUT.setCriticalError("You have to install a Trading System in the ship for trading to work."%_T)
        ShipAI():setStatus("Error buying '${name}': No Trading System Installed"%_T, {name = self.data.name})
        return
    end

    -- Buy-AI specific
    local possible = getPossibleAmountToFitOnShip()
    local required = getRemainingAmountToFulfill()

    if required > possible then
        -- critical error: we don't have enough cargo space to fulfill the order
        TradeUT.setCriticalError("Not enough cargo space to buy %i '%s'."%_T, self.data.amount, self.data.name)
        ShipAI():setStatus("Error buying '${name}': Not enough cargo space"%_T, {name = self.data.name})
        return
    end

    local possible = getBuyableAmountByMoney()
    if possible and required > possible then
        -- critical error: we don't have enough money to fulfill the order
        TradeUT.setCriticalError("Not enough money to buy %i '%s'."%_T, self.data.amount, self.data.name)
        ShipAI():setStatus("Error buying '${name}': Not enough money"%_T, {name = self.data.name})
        return
    end

    if required == 0 then
        terminate()
        return
    end

    if not self.data.partner then
        updateFindingPartner()
    else
        ShipAI():setStatus("Buying '${name}'"%_T, {name = self.data.name})
        TradeUT.updateDocking(timeStep, buy)
    end
end

function updateFindingPartner()
    local stationId, script, empty, badMargin = findSeller()

    if stationId and script then
        self.data.partner = {id = stationId, script = script}
    else
        self.data.partner = nil
    end

    if not self.data.partner then
        if not empty and not badMargin then
            -- critical error: No partner found that sells the desired goods
            TradeUT.setCriticalError("No merchant found that sells '%s'."%_T, self.data.name)
            ShipAI():setStatus("Error buying '${name}': No merchant selling"%_T, {name = self.data.name})
            return
        end

        ShipAI():setStatus("Looking for merchant selling '${name}'"%_T, {name = self.data.name})

        if empty and badMargin then
            -- soft error
            TradeUT.setSoftError("No merchant has any '%s' in stock or for a matching price."%_T, self.data.name)
            return
        elseif empty then
            -- soft error
            TradeUT.setSoftError("No merchant has any '%s' in stock."%_T, self.data.name)
            return
        elseif badMargin then
            -- soft error
            TradeUT.setSoftError("No merchant sells '%s' for a matching price."%_T, self.data.name)
            return
        end
    end
end

function findSeller()
    local ship = Entity()

    -- find a station that sells the goods
    local ok, sellable, buyable, routes = ship:invokeFunction("tradingoverview.lua", "getData")

    if ok and ok == 3 then
        TradeUT.setCriticalError("You have to install a Trading System in the ship for trading to work."%_T)
        return
    elseif (not ok or ok ~= 0) then
        TradeUT.setCriticalError("Error communicating with trading system, code: %s."%_T, tostring(ok))
        return
    elseif not buyable then
        TradeUT.setSoftError("Error communicating with trading system, no buyables."%_T)
        return
    end

    local empty = false
    local badMargin = false
    local offers = {}
    for _, offer in pairs(buyable) do
        if offer.good.name == self.data.name then
            if offer.stock == 0 then
                empty = true
                goto continue
            end

            -- a bad margin is never possible with our own stations
            if self.data.margin and offer.owner ~= ship.factionIndex then
                local margin = offer.price / goods[offer.good.name].price
                if margin > self.data.margin then
                    badMargin = true
                    goto continue
                end
            end

            table.insert(offers, offer)

            ::continue::
        end
    end

    if #offers == 0 then
        return nil, nil, empty, badMargin
    end

    -- order offers in ascending order -> cheapest first, at same price prefer stations with larger stock (-> less flying around)
    table.sort(offers, function(a, b)
            if a.price == b.price then
                return a.stock > b.stock
            else
                return a.price < b.price
            end
        end )

    return tostring(offers[1].stationIndex), offers[1].script, empty, badMargin
end

function getRemainingAmountToFulfill()
    local cargos = Entity():getCargos()

    for good, amount in pairs(cargos) do
        if good.name == self.data.name then
            return math.max(self.data.amount - amount, 0)
        end
    end

    return self.data.amount
end

function getPossibleAmountToFitOnShip()
    local free = CargoBay().freeSpace
    local good = goods[self.data.name]

    local buyable = math.floor(free / good.size)

    return buyable
end

function getBuyableAmountByMoney()

    local owner = Player()
    if not owner then owner = Alliance() end

    local amount = getRemainingAmountToFulfill()
    if not owner then return amount end -- if the owner is neither player nor alliance, we can expect them to have infinite money

    local station = nil
    if self.data.partner then
        station = Sector():getEntity(self.data.partner.id)
    end

    if not station then return end

    local script = self.data.partner.script
    local ok, price = station:invokeFunction(script, "getSellPrice", self.data.name, Faction().index)

    -- player may have 0 money but infinite resources enabled
    if owner:canPay(price * amount) then return amount end

    local money = owner.money

    local amountPossible = math.floor(money / price)
    if amountPossible < amount then
        amount = amountPossible
    end

    return amount
end

