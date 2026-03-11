getgenv().Visuals = {
    Circle = loadfile("Modules/Circle.lua")
}

RunService.RenderStepped:Connect(function()
    for _, visual in pairs(Visuals) do
        visual.update()
    end
end)