package.path = package.path .. ";data/scripts/lib/?.lua"
require("goodsindex")

function tableToGood(s)
    local g = TradingGood(s.name, s.plural, s.description, s.icon, s.price, s.size)
    g.illegal = s.illegal or false
    g.suspicious = s.suspicious or false
    g.stolen = s.stolen or false
    g.dangerous = s.dangerous or false
    return g
end

function goodToTable(g)
    return
    {
        name = g.name,
        plural = g.plural,
        description = g.description,
        icon = g.icon,
        price = g.price,
        size = g.size,
        illegal = g.illegal,
        stolen = g.stolen,
        suspicious = g.suspicious,
        dangerous = g.dangerous,
    }
end

goodsArray = {}
spawnableGoods = {}
for name, good in pairs(goods) do
    if good.price == 0 then
        good.price = 500
    end

    good.good = tableToGood

    table.insert(goodsArray, good)

    if not (string.match(good.name, "Iron ")
        or string.match(good.name, "Titanium ")
        or string.match(good.name, "Naonite ")
        or string.match(good.name, "Trinium ")
        or string.match(good.name, "Xanion ")
        or string.match(good.name, "Ogonite ")
        or string.match(good.name, "Avorion ")) then

        table.insert(spawnableGoods, good)
    end
end

local function comp(a, b) return a.name < b.name end
table.sort(goodsArray, comp)

function getGoodAttribute(name, attribute)
    local good = goods[name]
    return good[attribute]
end
