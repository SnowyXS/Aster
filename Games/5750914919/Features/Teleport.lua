local UI = Snowy.UI
local gameTab = UI.gameTab
local Category = UI.Category

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character

local rootPart = character:WaitForChild("HumanoidRootPart")
local teleportTab = Category:create_category("Teleport")

local function get_players_string()
    local player_list = {}

    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            table.insert(player_list, v.Name)
        end
    end

    return player_list
end

do -- Teleports
    do -- Players
        local playersTab = teleportTab:create_category("Players")

        local playersDropDown = playersTab:create_dropdown("Players", {
            Options = get_players_string()
        })

        local teleportButton = playersTab:create_button("Teleport")

        teleportButton:on_changed(function() 
            local player = Players:FindFirstChild(playersDropDown:get_value())
            if not player then return end
            
            local character = player.Character

            LocalPlayer:RequestStreamAroundAsync(character:GetPivot().p)

            local TRootPart = character.HumanoidRootPart
            rootPart.CFrame = TRootPart.CFrame
        end)

        local function on_player_change()
            playersDropDown:set_options(get_players_string())
        end

        Players.PlayerAdded:Connect(on_player_change)
        Players.PlayerRemoving:Connect(on_player_change)
    end

    do -- Locations
        local world = workspace:WaitForChild("world")
        local spawns = world.spawns

        local locations = {}
        local dropDownLocations = {}
        
        for i, v in pairs(spawns.TpSpots:GetChildren()) do
            local location = v.Name

            locations[location] = v.CFrame
            table.insert(dropDownLocations, location) 
        end

        local locationTab = teleportTab:create_category("Locations")

        local dropDown = locationTab:create_dropdown("Locations", {
            Options = dropDownLocations,
        })

        local teleportButton = locationTab:create_button("Teleport")

        teleportButton:on_changed(function() 
            local location = dropDown:get_value()
            if not location then return end

            local cframe = locations[location]

            LocalPlayer:RequestStreamAroundAsync(cframe.p)

            rootPart.CFrame = cframe
        end)
    end

    local function OnCharacterAdded(newCharacter)
        character = newCharacter
        rootPart = character:WaitForChild("HumanoidRootPart")
    end

    LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
end