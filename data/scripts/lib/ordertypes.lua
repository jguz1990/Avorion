package.path = package.path .. ";data/scripts/lib/?.lua"

require ("stringutility")

OrderType =
{
    Jump = 1,
    Mine = 2,
    Salvage = 3,
    Loop = 4,
    Aggressive = 5,
    Patrol = 6,
    BuyGoods = 7,
    SellGoods = 8,

    Escort = 9,
    AttackCraft = 10,
    FlyThroughWormhole = 11,
    FlyToPosition = 12,
    GuardPosition = 13,
    RefineOres = 14,

    NumActions = 15,
}

OrderTypes = {}

OrderTypes[OrderType.Jump] = {
    name = "Jump /* short order summary */"%_t,
}
OrderTypes[OrderType.Loop] = {
    name = "Loop /* short order summary */"%_t,
    icon = "data/textures/icons/loop.png",
    pixelIcon = "data/textures/icons/pixel/loop.png",
}
OrderTypes[OrderType.Mine] = {
    name = "Mine /* short order summary */"%_t,
    icon = "data/textures/icons/mining.png",
    pixelIcon = "data/textures/icons/pixel/mining.png",
}
OrderTypes[OrderType.Salvage] = {
    name = "Salvage /* short order summary */"%_t,
    icon = "data/textures/icons/scrap-metal.png",
    pixelIcon = "data/textures/icons/pixel/salvaging.png",
}
OrderTypes[OrderType.Aggressive] = {
    name = "Aggressive /* short order summary */"%_t,
    icon = "data/textures/icons/crossed-rifles.png",
    pixelIcon = "data/textures/icons/pixel/attacking.png",
}
OrderTypes[OrderType.Patrol] = {
    name = "Patrol /* short order summary */"%_t,
    icon = "data/textures/icons/patrol.png",
    pixelIcon = "data/textures/icons/pixel/patrol.png",
}
OrderTypes[OrderType.BuyGoods] = {
    name = "Buy Goods /* short order summary */"%_t,
    icon = "data/textures/icons/bag.png",
    pixelIcon = "data/textures/icons/pixel/buying.png",
}
OrderTypes[OrderType.SellGoods] = {
    name = "Sell Goods /* short order summary */"%_t,
    icon = "data/textures/icons/sell.png",
    pixelIcon = "data/textures/icons/pixel/selling.png",
}

OrderTypes[OrderType.Escort] = {
    name = "Escort /* short order summary */"%_t,
    icon = "data/textures/icons/escort.png",
    pixelIcon = "data/textures/icons/pixel/escort.png",
    color = {r = 64, g = 192, b = 64}
}
OrderTypes[OrderType.AttackCraft] = {
    name = "Attack /* short order summary */"%_t,
    icon = "data/textures/icons/attack.png",
    pixelIcon = "data/textures/icons/pixel/attacking.png",
    color = {r = 192, g = 64, b = 64}
}
OrderTypes[OrderType.FlyThroughWormhole] = {
    name = "Fly Through /* short order summary */"%_t,
    icon = "data/textures/icons/vortex.png",
    pixelIcon = "data/textures/icons/pixel/gate.png",
    color = {r = 64, g = 64, b = 192}
}
OrderTypes[OrderType.FlyToPosition] = {
    name = "Fly to Position /* short order summary */"%_t,
    icon = "data/textures/icons/position-marker.png",
    pixelIcon = "data/textures/icons/pixel/flytoposition.png",
    color = {r = 64, g = 192, b = 64}
}
OrderTypes[OrderType.GuardPosition] = {
    name = "Guard /* short order summary */"%_t,
    icon = "data/textures/icons/shield.png",
    pixelIcon = "data/textures/icons/pixel/guard.png",
    color = {r = 192, g = 192, b = 64}
}
OrderTypes[OrderType.RefineOres] = {
    name = "Refine Ores /* short order summary */"%_t,
    icon = "data/textures/icons/metal-bar.png",
    pixelIcon = "data/textures/icons/pixel/refine.png",
}

return OrderTypes
