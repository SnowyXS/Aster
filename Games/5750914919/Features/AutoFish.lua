local UI = Snowy.UI
local gameTab = UI.gameTab

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local character = LocalPlayer.character
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local autoTabbox = gameTab:AddLeftTabbox()

local paths = Snowy.paths
local libraries = paths.libraries

local Rod = loadfile(libraries .. "/RodController.lua")().new()

local rand = Random.new()
local function RandomNumber(min, max)
    return math.round(rand.NextNumber(rand, min, max))
end    

do -- Cast
    local castTab = autoTabbox:AddTab("Cast")

    local autoCastToggle = castTab:AddToggle("AutoCastToggle", {
        Text = "Auto-Cast",
        Default = false,
        Tooltip = "Will automatically cast the bobber.",
    })

    local autoEquipToggle = castTab:AddToggle("AutoEquipToggle", {
        Text = "Auto-Equip",
        Default = false,
        Tooltip = "Will automatically equip the rod when unequipped.",
    })

    local perfectSlider = castTab:AddSlider("CastPerfectSlider", {
        Text = "Perfect Chance",
        Default = 42,
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

    local function IsPerfect()
        local chance = RandomNumber(1, 100)
        return chance <= perfectSlider.Value
    end

    local function Cast()
        task.wait(.1)

        if autoCastToggle.Value and Rod:IsEquipped() then
            Rod:Cast(
                castType.Value == "Skip",
                IsPerfect() and 100 or RandomNumber(82, 90)
            )
        end
    end

    Rod:OnStateChanged(function(state)
        if state == 3 then
            Cast()
        end
    end)

    Rod:OnEquipped(function()
        Cast()
    end)

    Rod:OnUnEquipped(function()
        if autoEquipToggle.Value and autoCastToggle.Value then
            task.wait(.1)
            humanoid:EquipTool(Rod:GetRod())
        end
    end)

    local function OnRootPartChildAdded(instance)
        if instance.Name == "power" and autoCastToggle.Value and castType.Value == "Normal" then 
            local powerbar = instance:FindFirstChild("powerbar")
            local bar = powerbar.bar
            
            local connection
            connection = bar:GetPropertyChangedSignal("Size"):Connect(function()
                local scale = RandomNumber(82, 90) / 100

                if (scale == 1 and bar.Size.Y.Scale == scale) or (scale < 1 and bar.Size.Y.Scale / scale >= 0.94) then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    connection:Disconnect()
                end
            end)
        end
    end

    local function OnCharacterAdded(newCharacter)
        local newRootPart = character:WaitForChild("HumanoidRootPart")
        local newHumanoid = character:WaitForChild("Humanoid")

        character = newCharacter
        rootPart = newRootPart
        humanoid = newHumanoid

        rootPart.ChildAdded:Connect(OnRootPartChildAdded)
    end

    autoCastToggle:OnChanged(function(value)
        Cast()
    end)

    LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
    rootPart.ChildAdded:Connect(OnRootPartChildAdded)
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
        Default = 0.1,
        Min = 0,
        Suffix = "s",
        Max = 1,
        Rounding = 1,
        Compact = false,
    })

    local maxDelaySlider = shakeTab:AddSlider("ShakeMaxSlider", {
        Text = "Maximum Delay",
        Default = 0.1,
        Min = 0,
        Suffix = "s",
        Max = 1,
        Rounding = 1,
        Compact = false,
    })
            
    local shakeType = shakeTab:AddDropdown("ShakeTypeDropDown", {
        Values = {"Navigation", "Mouse", "Remote"},
        Default = 1,
        Multi = false,
    
        Text = "Type",
        Tooltip = "Mouse Click will use VirtualInputManager to click the Shake.\nNavigation will use UI Navigation to press the Shake.",
    })

    playerGui.ChildAdded:Connect(function(instance)
        if instance.Name == "shakeui" then
            local safezone = instance.safezone
            local button = safezone:WaitForChild("button")
            local connection = getconnection(button.Activated, 1)

            if connection then
                local Shake = connection.Function

                if autoShakeToggle.Value then 
                    local minDelay = minDelaySlider.Value
                    local maxDelay = maxDelaySlider.Value

                    repeat 
                        Shake()
                        task.wait(minDelay, maxDelay)
                    until not instance.Parent 
                end
            end
        end
    end)
end

do -- Reel
    local client = ReplicatedStorage.client
    local legacyControllers = client.legacyControllers
    local ReelController = require(legacyControllers.ReelController)

    local reelTab = autoTabbox:AddTab("Reel")

    local autoReelToggle = reelTab:AddToggle("AutoReelToggle", {
        Text = "Auto-Reel",
        Default = false,
        Tooltip = "Will automatically pass the reel minigame perfectly.",
    })

    local instantCatchToggle = reelTab:AddToggle("AutoReelToggle", {
        Text = "Instant-Catch",
        Default = false,
        Tooltip = "Instantly kills one palestinian children.",
    })
    
    local perfectSlider = reelTab:AddSlider("CatchPerfectSlider", {
        Text = "Perfect Chance",
        Default = 32,
        Min = 1,
        Suffix = "%",
        Max = 100,
        Rounding = 0,
        Compact = false,
    })

    local CurrentController
    local isPerfect

    local OldNew
    OldNew = hookfunction(ReelController.new, function(...)
        local chance = RandomNumber(1, 100)
        local perfectChance = perfectSlider.Value 
        isPerfect = chance <= perfectChance 
        CurrentController = OldNew(...)
        if instantCatchToggle.Value then CurrentController:AddModifier("progress", "force", 100) end

        if autoReelToggle.Value then
            local notifyString = `\n\nRandom:{chance}\nPerfect:{perfectChance}\n\n{chance} <= {perfectChance} = {isPerfect}`

            if not isPerfect then
                print(`🛡️ Missed on purpose {notifyString}`, 5)
            else
                print(`⭐ Perfect catch {notifyString}`, 5)
            end

            CurrentController:AddModifier("barSize", "force", 2)
            CurrentController:AddModifier("moveIntervalFactor", "force", 0)
            CurrentController.perfect = isPerfect
        end

        return CurrentController
    end)

    local function onReelToggle(value)
        if value and CurrentController then
            CurrentController:AddModifier("barSize", "force", 2)
            CurrentController:AddModifier("moveIntervalFactor", "force", 0)
            CurrentController.perfect = isPerfect
        end
    end
    
    local function onInstantToggle(value)
        if value and CurrentController then
            CurrentController:AddModifier("progress", "force", 100)
        end
    end
    
    autoReelToggle:OnChanged(onReelToggle)
    instantCatchToggle:OnChanged(onInstantToggle)
end 