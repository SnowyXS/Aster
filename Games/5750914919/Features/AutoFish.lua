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

local paths = Snowy.paths
local libraries = paths.libraries

local Rod = loadfile(libraries .. "/RodController.lua")().new()

local rand = Random.new()
local function RandomNumber(min, max)
    return math.round(rand.NextNumber(rand, min, max))
end    

local auto_fish_category = gameTab:create_category("Auto Fish")

do -- Cast
    local castTab = auto_fish_category:create_category("Cast")

    local autoCastToggle = castTab:create_toggle("Auto Cast")

    local autoEquipToggle = castTab:create_toggle("Auto Equip")

    local perfectSlider = castTab:create_slider("Perfect Chance", {
        Default = 42,
        Min = 1,
        Prefix = "%",
        Max = 100,
        Increment = 1
    })

    local castType = castTab:create_slider("Cast Type", {
        Default = 1,
        Min = 1,
        Max = 2,
        Increment = 1
    })

    local function IsPerfect()
        local chance = RandomNumber(1, 100)
        return chance <= perfectSlider.Value
    end

    local function Cast()
        task.wait(.1)

        if autoCastToggle.Value and Rod:IsEquipped() then
            Rod:Cast(
                castType.Value == 1,
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
        if instance.Name == "power" and autoCastToggle.Value and castType.Value == 2 then 
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

    autoCastToggle:on_changed(function(value)
        Cast()
    end)

    LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
    rootPart.ChildAdded:Connect(OnRootPartChildAdded)
end

do -- Shake
    local shakeTab =  auto_fish_category:create_category("Shake")

    local autoShakeToggle = shakeTab:create_toggle("Auto Shake")

    local minDelaySlider = shakeTab:create_slider("Min Delay", {
        Default = 0.1,
        Min = 0,
        Prefix = "s",
        Max = 1,
        Increment = 0.1
    })

    local maxDelaySlider = shakeTab:create_slider("Max Delay", {
        Default = 0.1,
        Min = 0,
        Prefix = "s",
        Max = 1,
        Increment = 0.1
    })

    playerGui.ChildAdded:Connect(function(instance)
        if instance.Name == "shakeui" then
            local safezone = instance.safezone
            local button = safezone:WaitForChild("button")
            local connection = getconnections(button.Activated)[1] 

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

    local reelTab = auto_fish_category:create_category("Reel")

    local autoReelToggle = reelTab:create_toggle("Auto Reel")

    local instantCatchToggle = reelTab:create_toggle("Instant Catch")
    
    local perfectSlider = reelTab:create_slider("Perfect Chance", {
        Default = 32,
        Min = 1,
        Prefix = "%",
        Max = 100,
        Increment = 1
    })

    local CurrentController
    local isPerfect

    local OldNew
    OldNew = hookfunction(ReelController.new, function(...)
        local chance = RandomNumber(1, 100)
        local perfectChance = perfectSlider.Value 
        isPerfect = chance <= perfectChance 
        CurrentController = OldNew(...)

        hookfunction(CurrentController.Log, function()
            return
        end)

        hookfunction(CurrentController.Snapshot, function()
            return
        end)

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
    
    autoReelToggle:on_changed(onReelToggle)
    instantCatchToggle:on_changed(onInstantToggle)
end 