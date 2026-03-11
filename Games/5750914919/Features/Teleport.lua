local UI = Snowy.UI
local gameTab = UI.gameTab

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character

local rootPart = character:WaitForChild("HumanoidRootPart")

do -- Teleports
    local tpTabbox = gameTab:AddLeftTabbox()

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

        local locationTab = tpTabbox:AddTab("Locations")

        local dropDown = locationTab:AddDropdown("LocationsDropDown", {
            Values = dropDownLocations,
            Default = 1,
            Multi = false,
        
            Text = "Locations",
            Tooltip = "This is a tooltip",
        })

        locationTab:AddButton("Teleport", function() 
            local location = dropDown.Value
            if not location then return end

            local cframe = locations[location]

            LocalPlayer:RequestStreamAroundAsync(cframe.p)

            rootPart.CFrame = cframe
        end)
    end

    do -- Players
        local playersTab = tpTabbox:AddTab("Players")

        local playersDropDown = playersTab:AddDropdown("LocationsDropDown", {
            SpecialType = "Player",
            Text = "Players",
            Tooltip = "This is a tooltip",
        })

        playersTab:AddButton("Teleport", function() 
            local player = Players:FindFirstChild(playersDropDown.Value)
            if not player then return end
            
            local character = player.Character

            LocalPlayer:RequestStreamAroundAsync(character:GetPivot().p)

            local TRootPart = character.HumanoidRootPart
            rootPart.CFrame = TRootPart.CFrame
        end)
    end

    local function OnCharacterAdded(newCharacter)
        character = newCharacter
        rootPart = character:WaitForChild("HumanoidRootPart")
    end

    LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
end