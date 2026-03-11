local BindableEvents = {
    _cache = {}
}
BindableEvents.__index = BindableEvents

function BindableEvents:Create()
    local bindable = Instance.new("BindableEvent")

    return setmetatable({
        _bindable = bindable
    }, BindableEvents)
end

function BindableEvents:Connect(callback)
    local bindable = self._bindable

    assert(bindable and typeof(callback) == "function", "Invalid connection.")

    bindable.Event:Connect(callback)
end

function BindableEvents:Fire(...)
    local bindable = self._bindable

    assert(bindable, "Couldn't find the event.")

    bindable:Fire(...)
end

return BindableEvents