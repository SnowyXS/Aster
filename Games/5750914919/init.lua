local HttpService = game:GetService("HttpService")

local UI = Snowy.UI
local Library = UI.Library
local Window = UI.Window
local Category = UI.Category

local paths = Snowy.paths
local featuresPath = paths.features
local infoPath = paths.info

local LoadedFeatures = {
    "Bypass",
    "AutoFish",
    "PlayerModifications",
    "Automation",
    "Teleport",
    --"Misc",
}

local info = HttpService:JSONDecode(readfile(infoPath))
local name, version = info.name, info.version
UI.gameTab = Category:create_category(name)

for _, feature in ipairs(LoadedFeatures) do
    local featurePath = string.format(featuresPath .. "/%s.lua", feature)
    assert(isfile(featurePath), feature.. " file couldn't be found.")
    
    loadfile(featurePath)()
end

print(`Loaded {name} {version}`)
