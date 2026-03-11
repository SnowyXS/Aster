local ScriptContext = game:GetService("ScriptContext")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--local ServerEvents = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/refs/heads/main/Libraries/Fisch/ServerEvents.lua"))()
local RodController = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/SLite/refs/heads/main/Libraries/Fisch/RodController.lua"))()

return function(Window)
    Library:Notify(`Loaded Fisch QoL`, 5)
    
    local Rod = RodController.new()

    local events = ReplicatedStorage:WaitForChild("events")
    local shared = ReplicatedStorage:WaitForChild("shared")
    local modules = shared.modules

    local CharacterModule = require(modules.character)

    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer.PlayerGui
    local backpack = LocalPlayer.Backpack

    local character = LocalPlayer.Character
    local humanoidRootPart = character.HumanoidRootPart
    local humanoid = character.Humanoid

    local camera = workspace.Camera
    local world = workspace.world

    local spawns = world.spawns

    local rand = Random.new()
    
    local locations = {}
    local dropDownLocations = {}
    
    for i, v in pairs(spawns.TpSpots:GetChildren()) do
        local location = v.Name

        locations[location] = v.CFrame
        table.insert(dropDownLocations, location) 
    end

    local function RandomNumber(min, max)
        return math.round(rand.NextNumber(rand, min, max))
    end    

    local fischTab = Window:AddTab("Fisch")
    
    do -- Auto Fish
        local autoTabbox = fischTab:AddLeftTabbox()

        do -- Cast
            local castTab = autoTabbox:AddTab("Cast")

            local autoCastToggle = castTab:AddToggle("AutoCastToggle", {
                Text = "Auto-Cast",
                Default = false,
                Tooltip = "Will automatically cast the bobber.",
            })
            
            local perfectSlider = castTab:AddSlider("CastPerfectSlider", {
                Text = "Perfect Chance",
                Default = 60,
                Min = 1,
                Suffix = "%",
                Max = 100,
                Rounding = 0,
                Compact = false,
            })

            local castType = castTab:AddDropdown("CastTypeDropDown", {
                Values = {"Skip", "Normal"},
                Default = 1,
                Multi = false,
            
                Text = "Type",
                Tooltip = "Skip will cast the bobber without the minigame.\nNormal will cast the bobber normally with the minigame.",
            })

            local percentage

            local function IsPerfect()
                local chance = RandomNumber(1, 100)

                return chance <= perfectSlider.Value
            end

            local function Cast()
                task.wait(0.1)

                if not newValue and autoCastToggle.Value and Rod:IsEquipped() then
                    local isSkip = castType.Value == "Skip"
                    percentage = IsPerfect() and 100 or RandomNumber(82, 90)

                    Rod:Cast(isSkip, percentage)
                end
            end

            Rod:OnCastChanged(function(newValue)
                if not newValue then
                    Cast()
                end
            end)

            Rod:OnEquipped(function()
                Cast()
            end)

            Rod:OnUnEquipped(function()
                humanoid:EquipTool(Tool)
            end)

            local function OnRootPartChildAdded(instance)
                if autoCastToggle.Value and castType.Value == "Skip" then 
                    local powerbar = instance:WaitForChild("powerbar")
                    local bar = powerbar.bar

                    local connection
                    connection = bar:GetPropertyChangedSignal("Size"):Connect(function()
                        if not percentage then return end
                        local scale = percentage / 100

                        if (scale == 1 and bar.Size.Y.Scale == scale) or (scale < 1 and bar.Size.Y.Scale / scale >= 0.94) then
                            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                            connection:Disconnect()
                        end
                    end)
                end
            end

            local function OnCharacterAdded(newCharacter)
                local humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
                backpack = LocalPlayer.Backpack
                humanoidRootPart.ChildAdded:Connect(OnRootPartChildAdded)
            end

            humanoidRootPart.ChildAdded:Connect(OnRootPartChildAdded)
            LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

            autoCastToggle:OnChanged(function(value)
                if not Rod:IsEquipped() or not value then return end 
                local isSkip = castType.Value == "Skip"
                percentage = IsPerfect() and 100 or RandomNumber(82, 90)

                Rod:Cast(isSkip, percentage)
            end)
        end

        do -- Shake
            local shakeTab = autoTabbox:AddTab("Shake")

            local autoShakeToggle = shakeTab:AddToggle("AutoShakeToggle", {
                Text = "Auto-Shake",
                Default = false,
                Tooltip = "Will automatically pass the shake minigame perfectly.",
            })

            local minDelaySlider = shakeTab:AddSlider("ShakeMinSlider", {
                Text = "Minimum Delay",
                Default = 0.2,
                Min = 0,
                Suffix = "s",
                Max = 1,
                Rounding = 1,
                Compact = false,
            })

            local maxDelaySlider = shakeTab:AddSlider("ShakeMaxSlider", {
                Text = "Maximum Delay",
                Default = 0.5,
                Min = 0,
                Suffix = "s",
                Max = 1,
                Rounding = 1,
                Compact = false,
            })
            
            local shakeType = shakeTab:AddDropdown("ShakeTypeDropDown", {
                Values = {"Navigation", "Mouse"},
                Default = 1,
                Multi = false,
            
                Text = "Type",
                Tooltip = "Mouse Click will use VirtualInputManager to click the Shake.\nNavigation will use UI Navigation to press the Shake.",
            })

            local function UIPressButton(button)
                button.Active = true
                button.Selectable = true

                GuiService.SelectedObject = button

                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            end

            local function MousePressButton(button)
                local x = button.AbsolutePosition.X + (button.AbsoluteSize.X / 2)
                local y = button.AbsolutePosition.Y + (button.AbsoluteSize.Y / 2)

                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            end

            local function OnToggle(bool)
                if not bool then return end

                local shakeui = PlayerGui:FindFirstChild("shakeui")
                if not shakeui then return end

                local safezone = shakeui.safezone
                local button = safezone.button

                if shakeType.Value == "Mouse" then
                    MousePressButton(button)
                else
                    UIPressButton(button)
                end
            end


            PlayerGui.ChildAdded:Connect(function(instance)
                if instance.Name == "shakeui" then
                    local safezone = instance.safezone
                    safezone.ChildAdded:Connect(function(button)
                        if autoShakeToggle.Value and button:IsA("ImageButton") then 
                            local minDelay = minDelaySlider.Value
                            local maxDelay = maxDelaySlider.Value
                            task.wait(minDelay, maxDelay)

                            if button.Parent then
                                if shakeType.Value == "Mouse" then
                                    MousePressButton(button)
                                else
                                    UIPressButton(button)
                                end
                            end
                        end
                    end)
                end
            end)

            PlayerGui.ChildRemoved:Connect(function(instance)
                if instance.name == "shakeui" then GuiService.SelectedObject = nil end
            end)

            autoShakeToggle:OnChanged(OnToggle)
        end

        do -- Reel
            local reelTab = autoTabbox:AddTab("Reel")

            local reelFinished = events.reelfinished
    
            local autoReelToggle = reelTab:AddToggle("AutoReelToggle", {
                Text = "Auto-Reel",
                Default = false,
                Tooltip = "Will automatically pass the reel minigame perfectly.",
            })

            local perfectSlider = reelTab:AddSlider("CatchPerfectSlider", {
                Text = "Perfect Chance",
                Default = 44,
                Min = 1,
                Suffix = "%",
                Max = 100,
                Rounding = 0,
                Compact = false,
            })


            PlayerGui.ChildAdded:Connect(function(instance)
                if autoReelToggle.Value and instance.Name == "reel" then
                    local chance = RandomNumber(1, 100)
                    local perfectChance = perfectSlider.Value 
                    local isPerfect = chance <= perfectChance

                    local stringResults = `\n\nRandom:{chance}\nPerfect:{perfectChance}\n\n{chance} <= {perfectChance} = {isPerfect}`

                    if isPerfect then 
                        Library:Notify(`⭐ Perfect catch {stringResults}`, 5)
                    else
                        Library:Notify(`🛡️ Missed on purpose {stringResults}`, 5)
                    end

                    local bar = instance.bar
                    local playerbar = bar.playerbar
                    local fish = bar.fish

                    if not isPerfect then
                        local barConnection
                        barConnection = playerbar:GetPropertyChangedSignal("Position"):Connect(function()
                            playerbar.Position = UDim2.new(-2, 0, 0.5, 0)
                        end)
                        
                        playerbar:GetPropertyChangedSignal("BackgroundTransparency"):Wait()
                        barConnection:Disconnect()
                    end

                    fish:GetPropertyChangedSignal("Position"):Connect(function()
                        local left = bar.AbsolutePosition.X
                        local width = bar.AbsoluteSize.X

                        local playerCenter = playerbar.AbsolutePosition.X + (playerbar.AbsoluteSize.X / 2)

                        local scale = (playerCenter - left) / width
                        
                        fish.Position = UDim2.new(scale, 0, 0.5, 0)
                    end)
                end
            end)
        end 
    end

    do -- Player Tab
        local playerTab = fischTab:AddRightGroupbox("Player")

        local infOxyGenToggle = playerTab:AddToggle("InfOxyGenToggle", {
            Text = "Infinite Oxygen",
            Default = false,
            Tooltip = "Breath like a fish.",
        })
        
        local bypassTempToggle = playerTab:AddToggle("InfOxyGenToggle", {
            Text = "Bypass Temperature",
            Default = false,
            Tooltip = "Temp? Whats that?",
        })

        local freezeToggle = playerTab:AddToggle("FreezeToggle", {
            Text = "Freeze",
            Default = false,
            Tooltip = "Cold player. No move!",
        })

        local antiAfkToggle = playerTab:AddToggle("AntiAFKToggle", {
            Text = "Anti AFK",
            Default = false,
            Tooltip = "Want to go make some coffee? No problem. Go make some coffee.",
        })

        local bodyPosition

        local function OnFreezeChanged(value)
            if bodyPosition then bodyPosition:Destroy() end

            if value then
                bodyPosition = Instance.new("BodyPosition")
                bodyPosition.MaxForce = Vector3.new(400000, 400000, 400000)
                bodyPosition.D = 1000
                bodyPosition.P = 100000
                bodyPosition.Position = humanoidRootPart.Position
                bodyPosition.Parent = humanoidRootPart
            end
        end

        local function AntiAFK()
            if not antiAfkToggle.Value then return end

			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
        end

        local function OnCharacterAdded(newCharacter)
            humanoid = newCharacter:WaitForChild("Humanoid")
            humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")

            Character = newCharacter
        end

        local Oldtick
        Oldtick = hookfunction(tick, function(...)
            local script = getcallingscript()
            
            if script then
                local isOxygen = infOxyGenToggle.Value and (script.Name == "oxygen" or "oxygen(peaks)")
                local isTemp = bypassTempToggle.Value and (script.Name == "temperature" or script.Name == "temperature(heat)")
                
                if isOxygen or isTemp then 
                    return 0 
                end
            end 
        
            return Oldtick(...)
        end)

        antiAfkToggle:OnChanged(AntiAFK)
        freezeToggle:OnChanged(OnFreezeChanged)

        LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
        LocalPlayer.Idled:Connect(AntiAFK)
    end

    do -- Teleports
        local tpTabbox = fischTab:AddLeftTabbox()

        do -- Locations
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

                humanoidRootPart.CFrame = cframe
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
                local rootPart = character.HumanoidRootPart

                humanoidRootPart.CFrame = rootPart.CFrame
            end)
        end
    end

    do -- Misc
        local miscTabbox = fischTab:AddRightTabbox()

        do -- Items
            local npcs = world.npcs
            local chests = world.chests
            
            --local inventory = CharacterModule.PS(LocalPlayer):WaitForChild("Inventory")

            local purchaseRemote = events.purchase
            local library = modules.library

            local allRods = require(library.rods)
            local allFish = require(library.fish)

            local rods, crates = {}, {}

            for i, v in pairs(allRods) do
                if typeof(v) ~= "table" then continue end
                if v.Unpurchasable or not v.Price or v.Price == math.huge then continue end

                table.insert(rods, i)
            end

            for i, v in pairs(allFish) do
                if typeof(v) ~= "table" then continue end
                if not v.IsCrate or not v.BuyMult then continue end
                
                table.insert(crates, i)
            end

            local function clickproximityprompt(prompt)
                local part = Instance.new("Part")
                part.Size = Vector3.new(1, 1, 1) 
                part.Anchored = true
                part.CanCollide = false
                part.Position = humanoidRootPart.Position + (camera.CFrame.LookVector * 10) 
                part.Parent = workspace

                local oldParent = prompt.Parent 

                prompt.MaxActivationDistance = 2e9
                prompt.RequiresLineOfSight = false
                prompt.Parent = part
                
                prompt.PromptShown:wait()

                prompt:InputHoldBegin()
                prompt:InputHoldEnd()

                prompt.MaxActivationDistance = 7
                prompt.RequiresLineOfSight = true
                prompt.Parent = oldParent

                part:Destroy()
            end
            
            local itemsTab = miscTabbox:AddTab("Items")

            local rodsDropDown = itemsTab:AddDropdown("rodsDown", {
                Values = rods,
                Default = 1,
                Multi = false,
            
                Text = "Rods",
                Tooltip = "This is a tooltip",
            })

            itemsTab:AddButton("Buy", function() 
                local rod = rodsDropDown.Value
                purchaseRemote:FireServer(rod, "Rod", nil, 1)
            end)
            itemsTab:AddDivider()

            local cratesDropDown = itemsTab:AddDropdown("cratesDown", {
                Values = crates,
                Default = 1,
                Multi = false,
            
                Text = "Crates",
                Tooltip = "This is a tooltip",
            })

            local cratesAmount = itemsTab:AddSlider("CrateAmountSlider", {
                Text = "Amount",
                Default = 1,
                Min = 1,
                Max = 500,
                Rounding = 0,
                Compact = false,
            })

            itemsTab:AddButton("Buy", function() 
                local crate = cratesDropDown.Value
                local amount = cratesAmount.Value
                purchaseRemote:FireServer(crate, "fish", nil, amount)
            end)
            itemsTab:AddDivider()

            local sellType = itemsTab:AddDropdown("SellDropDown", {
                Values = { "Hand", "All" },
                Default = 1,
                Multi = false,
            
                Text = "Sell Type",
                Tooltip = "This is a tooltip",
            })

            do
                local firstTime = true

                itemsTab:AddButton("Sell", function() 
                    LocalPlayer:RequestStreamAroundAsync(locations.moosewood.p)
                    
                    local type = sellType.Value

                    local marc = npcs:WaitForChild("Marc Merchant")
                    local prompt = marc.ProximityPrompt
                    
                    local sell, sellall = events.Sell, events.SellAll

                    if firstTime then
                        clickproximityprompt(prompt)
                        firstTime = false
                    end

                    if type == "All" then return sellall:InvokeServer() end

                    sell:InvokeServer()
                end)
            end

            itemsTab:AddDivider()

            itemsTab:AddButton("Collect Treasure Chests", function() 
                for _, v in pairs(chests:GetChildren()) do
                    local prompt = v:FindFirstChild("ProximityPrompt")
                    if not prompt then continue end

                    fireproximityprompt(prompt)

                    task.wait()
                end
                --[[
                ** Alternative for the future in case it"s not always rendering the treasure chests. **
                for _, v in pairs(inventory:GetChildren()) do
                    if v.Name:find("Treasure Map") and v.Repaired.Value == true then 
                        local x,y,z = v.x.Value, v.y.Value, v.z.Value
                        local position = Vector3.new(x, y, z)
                        LocalPlayer:RequestStreamAroundAsync(position)

                        local chest = chests:WaitForChild(`TreasureChest_{x}_{y}_{z}`)
                        local prompt = chest.ProximityPrompt

                        fireproximityprompt(prompt)

                        task.wait()
                    end
                end
                ]]
            end)

            do
                local jackPos = Vector3.new(-2830.748046875, 215.2417449951172, 1518.34814453125)
                local firstTime = true

                itemsTab:AddButton("Fix Treasure Maps", function() 
                    LocalPlayer:RequestStreamAroundAsync(jackPos)
                    
                    local jack = npcs:WaitForChild("Jack Marrow")
                    local prompt = jack.ProximityPrompt

                    local treasure = jack.treasure
                    local repairmap = treasure.repairmap

                    if firstTime then
                        clickproximityprompt(prompt)
                        firstTime = false
                    end

                    for _, v in pairs(backpack:GetChildren()) do
                        if v.Name == "Treasure Map" then
                            humanoid:EquipTool(v)
                            repairmap:InvokeServer()
                        end
                    end
                end)
            end
        end

        do -- Bestiary
            local discoverLocation = events.discoverlocation

            local hud = PlayerGui:WaitForChild("hud")
            local safezone = hud.safezone
            local bestiary = safezone.bestiary

            local limitedCatagory = bestiary.NormalCategory
            local normalCatagory = bestiary.NormalCategory

            local bestiaryTab = miscTabbox:AddTab("Bestiary")

            --[[ Soon
            bestiaryTab:AddToggle("BestiaryFarmToggle", {
                Text = "AutoFarm",
                Default = false,
                Tooltip = "Completes your Bestiary!",
            })
            ]]

            bestiaryTab:AddButton("Discover all locations", function() 
                for i, v in pairs(normalCatagory.scroll:GetChildren()) do
                    if not v:IsA("ImageButton") then continue end
                    discoverLocation:FireServer(v.Name)
                end

                for i, v in pairs(limitedCatagory.scroll:GetChildren()) do
                    if not v:IsA("ImageButton") then continue end
                    discoverLocation:FireServer(v.Name)
                end
            end)
        end
    end
end
