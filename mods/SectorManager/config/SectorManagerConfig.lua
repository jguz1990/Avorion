local config = {}

config.Author = "Laserzwei"
config.ModName = "Sector Manager"
config.version = {
    major=0, minor=2, patch = 2,
    string = function()
        return  config.version.major .. '.' ..
                config.version.minor .. '.' ..
                config.version.patch
    end
}

config.maxSectorPerPlayer = 10   --Default: 5

return config
