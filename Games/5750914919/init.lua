local HttpService = game:GetService("HttpService")

local UI = Snowy.UI
local Library = UI.Library
local Window = UI.Window

local paths = Snowy.paths
local featuresPath = paths.features
local infoPath = paths.info

local LoadedFeatures = {
    "AutoFish",
    "PlayerModifications",
    "Automation",
    "Teleport",
    "Misc",
}

local info = HttpService:JSONDecode(readfile(infoPath))
local name, version = info.name, info.version
UI.gameTab = Window:AddTab(name)

for _, feature in pairs(LoadedFeatures) do
    local featurePath = string.format(featuresPath .. "/%s.lua", feature)
    assert(isfile(featurePath), feature.. " file couldn't be found.")
    
    loadfile(featurePath)()
end

Library:Notify(`Loaded {name} {version}`, 5)
