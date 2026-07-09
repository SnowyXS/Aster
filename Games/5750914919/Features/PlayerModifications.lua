
local UI = Snowy.UI
local gameTab = UI.gameTab

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character

local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

do -- Player Tab
    local playerTab = gameTab:AddRightGroupbox("Player")
    --[[ // Needs update
    do -- Infinite Oxygen, Bypass Temp
        local infOxyGenToggle = playerTab:AddToggle("InfOxyGenToggle", {
            Text = "Infinite Oxygen",
            Default = false,
            Tooltip = "Breath like a fish.",
        })
            
        local bypassTempToggle = playerTab:AddToggle("bypassTempToggle", {
            Text = "Bypass Temperature",
            Default = false,
            Tooltip = "Temp? Whats that?",
        })

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
    end
    ]]
    do -- Freeze player
        local freezeToggle = playerTab:AddToggle("FreezeToggle", {
            Text = "Freeze",
            Default = false,
            Tooltip = "Cold player. No move!",
        })

        local bodyPosition
        local function OnFreezeChanged(value)
            if bodyPosition then bodyPosition:Destroy() end
            if value then
                bodyPosition = Instance.new("BodyPosition")
                bodyPosition.MaxForce = Vector3.new(400000, 400000, 400000)
                bodyPosition.D = 1000
                bodyPosition.P = 100000
                bodyPosition.Position = rootPart.Position
                bodyPosition.Parent = rootPart
            end
        end

        freezeToggle:OnChanged(OnFreezeChanged)
    end

    do -- Anti-AFK
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local VirtualUser = game:GetService("VirtualUser")
        local UserInputService = game:GetService("UserInputService")
        local Terrain = workspace:WaitForChild("Terrain")

        -- WaterTransparency
        local events = ReplicatedStorage:WaitForChild("events")
        local afkEvent = events.afk

        local antiAfkToggle = playerTab:AddToggle("AntiAFKToggle", {
            Text = "Anti AFK",
            Default = false,
            Tooltip = "Want to go make some coffee? No problem. Go make some coffee.",
        })

        local function SimulatePress()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end

        local function GetConnections()
            local FocusedCons = getconnections(UserInputService.WindowFocused)
            local ReleasedCons = getconnections(UserInputService.WindowFocusReleased)
            local clientFocused, clientReleased

            for _, v in pairs(FocusedCons) do
                if not v.Function then continue end

                local path = getinfo(v.Function).short_src
                local split = string.split(path, ".")
                local scriptName = split[#split]
                
                if scriptName == "client" then
                    clientFocused = v
                    continue
                end

                v:Disable()
            end

            for _, v in pairs(ReleasedCons) do
                if not v.Function then continue end

                local path = getinfo(v.Function).short_src
                local split = string.split(path, ".")
                local scriptName = split[#split]

                if scriptName == "client" then
                    clientReleased = v
                    continue
                end

                v:Disable()
            end

            return clientFocused, clientReleased
        end

        local function init()
            local clientFocused, clientReleased = GetConnections()

            while not clientFocused or not clientReleased do 
                clientFocused, clientReleased = GetConnections()
                task.wait()
            end
            
            local function OnToggle()
                if not clientReleased or not clientFocused then return end

                if not antiAfkToggle.Value then 
                    clientReleased:Enable()
                    clientFocused:Enable()
                else
                    clientReleased:Disable()
                    clientFocused:Disable()
                end
            end

            afkEvent:FireServer(false)
            antiAfkToggle:OnChanged(OnToggle)
            LocalPlayer.Idled:Connect(SimulatePress)
        end

        task.spawn(init)
    end

    do -- WalkSpeed / JumpPower
        local metatable = getrawmetatable(game)
        local __index = metatable.__index
        local __newindex = metatable.__newindex

        local walkSpeedSlider = playerTab:AddSlider("WalkSpeedSlider", {
            Text = "WalkSpeed",
            Default = 16,
            Min = 16,
            Suffix = "",
            Max = 500,
            Rounding = 0,
            Compact = false,
        })

        local jumpPowerSlider = playerTab:AddSlider("JumpPowerSlider", {
            Text = "JumpPower",
            Default = 50,
            Min = 50,
            Suffix = "",
            Max = 500,
            Rounding = 0,
            Compact = false,
        })

        local OldIndex
        OldIndex = oth.hook(__index, function(self, index)
            if not checkcaller() then
                if index == "WalkSpeed" then
                    return 16
                elseif index == "JumpPower" then
                    return 50
                end
            end

            return OldIndex(self, index)
        end)

        local OldNewIndex
        OldNewIndex = oth.hook(__newindex, function(self, index, value)
            if not checkcaller() then
                if index == "WalkSpeed" or index == "JumpPower" then
                    return
                end
            end

            return OldNewIndex(self, index, value) 
        end)

        local function OnWalkSpeedChanged(value)
            humanoid.WalkSpeed = value
        end

        local function OnJumpPowerChanged(value)
            humanoid.JumpPower = value
        end

        walkSpeedSlider:OnChanged(OnWalkSpeedChanged)
        jumpPowerSlider:OnChanged(OnJumpPowerChanged)
    end

    local function OnCharacterAdded(newCharacter)
        rootPart = newCharacter:WaitForChild("HumanoidRootPart")
        humanoid = newCharacter:WaitForChild("Humanoid")

        humanoid.WalkSpeed = Options.WalkSpeedSlider.Value
        humanoid.JumpPower = Options.JumpPowerSlider.Value

        character = newCharacter
    end

    LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
end