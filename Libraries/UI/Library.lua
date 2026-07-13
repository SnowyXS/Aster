local UserInputService = game:GetService("UserInputService")
local Library = {}
local Base = {}
Base.__index = Base

local screengui = Instance.new("ScreenGui", game.CoreGui)
local BindableEvents = loadstring(game:HttpGet("https://raw.githubusercontent.com/SnowyXS/Aster/refs/heads/stable/Libraries/Dependencies/BindableEvents.lua"))()


do
	function Base:create_button(title) 
		local Window = self.Window
		local button = {
			Window = Window,
		}

		local bindable = BindableEvents:Create()
		local objects = self.objects

		local row = Library.create_row(self.category_frame, title)
		button.instance = row

		function button:on_changed(func)
			bindable:Connect(func)
		end

		function button:fire(...)
			bindable:Fire(...)
		end

		function button:click()
			local window = self.Window
			local linked_category = self.linked_category

			if linked_category then
				window:open_category(linked_category)
			else
				bindable:Fire()
			end
		end

		function button:set_category(category)
			local image_label = Instance.new("ImageLabel", row)
			image_label.AnchorPoint = Vector2.new(1, 0.5)
			image_label.BackgroundTransparency = 1
			image_label.Position = UDim2.new(1, -5, 0.5, 1)
			image_label.Size = UDim2.new(0, 25, 0, 25)
			image_label.Image = "rbxassetid://133800611596665"

			button.linked_category = category
		end

		table.insert(objects, button)

		Library.init_highlight(self, row)

		self.size = self.size + 1
		if Window.current_category == self then
			Window:resize(self)
		end

		return button
	end

	function Base:create_toggle(title) 
		local Window = self.Window
		local toggle = {
			Window = Window,
			Value = false,
		}

		local bindable = BindableEvents:Create()
		local objects = self.objects

		local row = Library.create_row(self.category_frame, title)
		toggle.instance = row

		local toggle_status = Instance.new("Frame", row)
		toggle_status.AnchorPoint = Vector2.new(1, 0.5)
		toggle_status.BackgroundColor3 = Color3.fromRGB(255, 0, 4)
		toggle_status.Position = UDim2.new(1, -12, 0.5, 1)
		toggle_status.Size = UDim2.new(0, 10, 0, 10)

		local UICorner = Instance.new("UICorner", toggle_status)
		UICorner.CornerRadius = UDim.new(0, 90)

		function toggle:on_changed(func)
			bindable:Connect(func)
		end

		function toggle:fire(...)
			bindable:Fire(...)
		end

		function toggle:click()
			self.Value = not self.Value

			toggle_status.BackgroundColor3 = self.Value and Color3.fromRGB(18, 255, 1) or Color3.fromRGB(255, 0, 4)

			bindable:Fire(self.Value)
		end

		table.insert(objects, toggle)

		Library.init_highlight(self, row)

		self.size = self.size + 1
		if Window.current_category == self then
			Window:resize(self)
		end

		return toggle
	end


	function Base:create_slider(title, options) 
		local Window = self.Window
		local slider = {
			Window = Window,
			Min = options.Min,
			Max = options.Max,
			Increment = options.Increment or 1,
			Prefix = options.Prefix or "",
			Value = options.Default
		}

		local bindable = BindableEvents:Create()
		local objects = self.objects

		local row = Library.create_row(self.category_frame, title)
		slider.instance = row

		local slider_value = Instance.new("TextLabel", row)
		slider_value.AnchorPoint = Vector2.new(1, 0.5)
		slider_value.TextColor3 = Color3.fromRGB(184, 184 ,184)
		slider_value.BackgroundTransparency = 1
		slider_value.Text = `< {slider.Value}{slider.Prefix} >`
		slider_value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		slider_value.TextSize = 14
		slider_value.TextXAlignment = Enum.TextXAlignment.Right
		slider_value.Position = UDim2.new(1, -6, 0.5, 1)
		slider_value.Size = UDim2.new(1, 0, 0, 35)

		function slider:on_changed(func)
			bindable:Connect(func)
		end

		function slider:fire(...)
			bindable:Fire(...)
		end

		function slider:set_value(direction)
			local value = Library.round_float(math.clamp(
				self.Value + direction * self.Increment, 
				self.Min, 
				self.Max
				))

			self.Value = value
			slider_value.Text = `< {value}{self.Prefix} >`
			bindable:Fire(value)
		end

		table.insert(objects, slider)

		Library.init_highlight(self, row)

		self.size = self.size + 1

		if Window.current_category == self then
			Window:resize(self)
		end

		return slider
	end

	function Base:create_dropdown(title, options)
		if not options.Options or #options.Options == 0 then return end

		local Window = self.Window
		local dropdown = {
			Window = Window,
			Options = options.Options,
			Multi = options.Multi or false,
			Index  = 1,
			Selected = {},
		}

		local bindable = BindableEvents:Create()
		local objects = self.objects

		local row = Library.create_row(self.category_frame, title)
		dropdown.instance = row

		local dropdown_value = Instance.new("TextLabel", row)
		dropdown_value.AnchorPoint = Vector2.new(1, 0.5)
		dropdown_value.TextColor3 = Color3.fromRGB(184, 184, 184)
		dropdown_value.BackgroundTransparency = 1
		dropdown_value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
		dropdown_value.TextSize = 14
		dropdown_value.Text = `< {dropdown.Options[dropdown.Index]} >`
		dropdown_value.TextXAlignment = Enum.TextXAlignment.Right
		dropdown_value.Position = UDim2.new(1, -6, 0.5, 1)
		dropdown_value.Size = UDim2.new(1, 0, 0, 35)
		dropdown_value.RichText = true

		function dropdown:on_changed(func)
			bindable:Connect(func)
		end

		function dropdown:fire(...)
			bindable:Fire(...)
		end

		function dropdown:get_value()
			local count = #self.Options
			if count == 0 then return end

			local value = self.Options[self.Index]

			if self.Multi then
				local list = {}

				for i, _ in ipairs(self.Options) do
					if self.Selected[i] then
						table.insert(list, self.Options[i])
					end
				end

				value = list
			end

			return value
		end

		function dropdown:set_options(new_options)
			new_options = new_options or {}

			local old_selected_values = {}
			if self.Multi then
				for i, was_selected in pairs(self.Selected) do
					if was_selected and self.Options[i] then
						old_selected_values[self.Options[i]] = true
					end
				end
			end

			local old_value = self.Options[self.Index]

			self.Options = new_options
			self.Selected = {}

			self.Index = 1
			if old_value ~= nil then
				for i, opt in ipairs(self.Options) do
					if opt == old_value then
						self.Index = i
						break
					end
				end
			end

			if self.Multi then
				for i, opt in ipairs(self.Options) do
					if old_selected_values[opt] then
						self.Selected[i] = true
					end
				end
			end

			local value = self.Options[self.Index]
			dropdown_value.Text = `< {value} >`
			dropdown_value.TextColor3 = self.Selected[self.Index] and Color3.fromRGB(39, 255, 6) or Color3.fromRGB(184, 184, 184)

			if self.Multi then
				local list = {}
				for i in ipairs(self.Options) do
					if self.Selected[i] then
						table.insert(list, self.Options[i])
					end
				end
				bindable:Fire(list)
			end
		end

		function dropdown:set_value(direction)
			local count = #self.Options
			if count == 0 then return end

			local new_index = (self.Index  - 1 + direction) % count + 1
			local value = self.Options[new_index]

			self.Index  = new_index
			dropdown_value.Text = `< {value} >`
			dropdown_value.TextColor3 = self.Selected[new_index] and Color3.fromRGB(39, 255, 6) or Color3.fromRGB(184, 184, 184)

			if not self.Multi then
				bindable:Fire(value)
			end
		end

		function dropdown:click()
			local count = #self.Options
			if count == 0 then return end

			if self.Multi then
				local index = self.Index
				self.Selected[index] = not self.Selected[index]

				dropdown_value.TextColor3 = self.Selected[index] and Color3.fromRGB(39, 255, 6) or Color3.fromRGB(184, 184, 184)

				local list = {}
				for i, _ in ipairs(self.Options) do
					if self.Selected[i] then
						table.insert(list, self.Options[i])
					end
				end

				bindable:Fire(list)
			end
		end

		table.insert(objects, dropdown)

		Library.init_highlight(self, row)

		self.size = self.size + 1
		if Window.current_category == self then
			Window:resize(self)
		end

		return dropdown
	end
	
	function Base:create_label(title)
		local Window = self.Window
		local label = {
			Window = Window,
			Keybind = nil,
			is_pressed = false,
		}

		local changed_bindable = BindableEvents:Create()
		local pressed_bindable = BindableEvents:Create()
		local objects = self.objects

		local row = Library.create_row(self.category_frame, title)
		label.instance = row

		function label:on_changed(func)
			changed_bindable:Connect(func)
		end
		
		function label:on_keypress(func)
			pressed_bindable:Connect(func)
		end
		
		function label:add_keybind(keybind)
			self.Keybind = keybind
			
			local keybind_value = Instance.new("TextLabel", row)
			keybind_value.AnchorPoint = Vector2.new(1, 0.5)
			keybind_value.TextColor3 = Color3.fromRGB(184, 184, 184)
			keybind_value.BackgroundTransparency = 1
			keybind_value.FontFace = Font.fromEnum(Enum.Font.SourceSans)
			keybind_value.TextSize = 14
			keybind_value.Text = `[ {keybind.Name} ]`
			keybind_value.TextXAlignment = Enum.TextXAlignment.Right
			keybind_value.Position = UDim2.new(1, -6, 0.5, 1)
			keybind_value.Size = UDim2.new(1, 0, 0, 35)
			
			function label:set_keybind(bind)
				keybind_value.Text = `[ {bind.Name} ]`
				keybind_value.TextColor3 = Color3.fromRGB(184, 184, 184)
				
				self.Keybind = bind
				changed_bindable:Fire(bind)
			end
			
			function label:get_state()
				return self.is_pressed
			end
			
			function label:cancel_bind()
				keybind_value.Text = `[ {self.Keybind.Name} ]`
				keybind_value.TextColor3 = Color3.fromRGB(184, 184, 184)
			end

			function label:click()
				keybind_value.Text = "[ ... ]"
				keybind_value.TextColor3 = Color3.fromRGB(255, 200, 0)
				Window.binder = self
			end
			
			UserInputService.InputBegan:Connect(function(input)
				local key = input.KeyCode
				
				if key == self.Keybind then
					self.is_pressed = true
					pressed_bindable:Fire(key, true)
				end
			end)
			
			UserInputService.InputEnded:Connect(function(input)
				local key = input.KeyCode

				if key == self.Keybind then
					self.is_pressed = false
					pressed_bindable:Fire(key, false)
				end
			end)
		end
		
		table.insert(objects, label)

		Library.init_highlight(self, row)

		self.size = self.size + 1
		if Window.current_category == self then
			Window:resize(self)
		end

		return label

	end
	
	function Base:create_category(title)
		local Window = self.Window
		local category = Window:create_category(title)
		self:create_button(title):set_category(category)

		return category
	end

	function Base:move(amount)
		local objects = self.objects
		local count = #objects
		local old_selected = self.selected
		if not old_selected or #objects <= 1 then return end

		self.selected = self.selected + amount

		if self.selected > count then
			self.selected = 1
		elseif self.selected < 1 then
			self.selected = count
		end

		local current_object = objects[self.selected].instance
		Library.set_properties(current_object, {
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.5,
			BackgroundColor3 = Color3.fromRGB(77, 15, 138) 
		})

		local old_object = objects[old_selected].instance
		Library.set_properties(old_object, {
			TextColor3 = Color3.fromRGB(184, 184 ,184),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		})
	end

	function Base:click()
		local obj = self.objects[self.selected]

		if obj and obj.click then
			obj:click()
		end
	end

	function Base:slider_step(direction)
		local obj = self.objects[self.selected]

		if obj and obj.set_value then
			obj:set_value(direction)
		end
	end
end

function Library:create_window(title, icon, version)
	local categories = {}
	local opened_categories = {}

	local Window = {
		categories = categories,
		opened_categories = opened_categories,
		current_category = nil
	}

	local main_frame = Instance.new("Frame", screengui)
	main_frame.Name = "main"
	main_frame.Position = UDim2.new(0, 24, 0, 24)
	main_frame.Size = UDim2.new(0, 300, 0, 70)
	main_frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

	Window.window_frame = main_frame

	Instance.new("UICorner", main_frame)

	local top_bar = Instance.new("Frame", main_frame)
	top_bar.Name = "top_bar"
	top_bar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	top_bar.Size = UDim2.new(0, 300, 0, 35)

	local ui_corner = Instance.new("UICorner", top_bar)
	ui_corner.BottomLeftRadius = UDim.new(0, 0)
	ui_corner.BottomRightRadius = UDim.new(0, 0)

	local title_label = Instance.new("TextLabel", top_bar)
	title_label.Name = "title"
	title_label.Text = title
	title_label.Size = UDim2.new(0.2, 0, 1, 0)
	title_label.TextXAlignment = Enum.TextXAlignment.Left
	title_label.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	title_label.TextSize = 14
	title_label.TextColor3 = Color3.fromRGB(255, 255, 255)
	title_label.BackgroundTransparency = 1

	local UIPadding = Instance.new("UIPadding", title_label)
	UIPadding.PaddingLeft = icon and UDim.new(0, 30) or UDim.new(0,12)

	local icon_label = Instance.new("ImageLabel", top_bar)
	icon_label.Name = "icon"
	icon_label.Position = UDim2.new(0, 2, 0, 2)
	icon_label.Size = UDim2.new(0, 30, 0, 30)
	icon_label.BackgroundTransparency = 1
	icon_label.Image = icon or 0

	local holder_frame = Instance.new("Frame", main_frame)
	holder_frame.Name = "holder"
	holder_frame.Position = UDim2.new(0, 0, 0.5, 0)
	holder_frame.Size = UDim2.new(1, 0, 1, -70)
	holder_frame.AnchorPoint = Vector2.new(0, 0.5)
	holder_frame.BackgroundTransparency = 1

	local bottom_bar = Instance.new("Frame", main_frame)
	bottom_bar.Name = "bottom_bar"
	bottom_bar.AnchorPoint = Vector2.new(0, 1)
	bottom_bar.Position = UDim2.new(0, 0, 1, 0)
	bottom_bar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	bottom_bar.Size = UDim2.new(0, 300, 0, 35)

	local ui_corner = Instance.new("UICorner", bottom_bar)
	ui_corner.TopRightRadius = UDim.new(0, 0)
	ui_corner.TopLeftRadius = UDim.new(0, 0)

	local version_label = Instance.new("TextLabel", bottom_bar)
	version_label.Name = "version"
	version_label.Text = version or "v1.0.0"
	version_label.Size = UDim2.new(0.073, 35, 1, 0)
	version_label.Position = UDim2.new(0, 0, 0, 0)
	version_label.FontFace = Font.new("rbxasset://fonts/families/Roboto.json")
	version_label.TextSize = 12
	version_label.TextColor3 = Color3.fromRGB(148, 148, 148)
	version_label.BackgroundTransparency = 1

	function Window:create_category(name)
		local category_frame = Instance.new("Frame", holder_frame)
		category_frame.Name = name
		category_frame.Size = UDim2.new(1, 0, 1, 0)
		category_frame.BackgroundTransparency = 1
		category_frame.Visible = #categories == 0

		local category = setmetatable({
			Window = Window,
			category_frame = category_frame,
			objects = {},
			selected = nil,
			size = 0,
		}, Base)

		Instance.new("UIListLayout", category_frame)

		function category:SetVisible(bool)
			category_frame.Visible = bool
		end

		if #categories == 0 then
			Window.current_category = category
			table.insert(opened_categories, category)
		end

		table.insert(categories, category)

		return category
	end

	function Window:open_category(category)
		local current_category = Window.current_category

		current_category:SetVisible(false)
		category:SetVisible(true)

		Window.current_category = category

		Window:resize(category)
		table.insert(opened_categories, category)
	end
	
	function Window.set_visible(value)
		main_frame.Visible = value
	end
	
	function Window.is_visible()
		return main_frame.Visible
	end
	
	function Window:close_category()
		if #opened_categories <= 1 then return end 
		table.remove(opened_categories)

		local previous = opened_categories[#opened_categories]
		if not previous then return end

		local current_category = Window.current_category

		current_category:SetVisible(false)
		previous:SetVisible(true)

		Window:resize(previous)
		Window.current_category = previous
	end

	function Window:resize(category)
		main_frame.Size = UDim2.new(0, 300, 0, 70 + category.size * 35)
	end

	UserInputService.InputBegan:Connect(function(input)
		local key = input.KeyCode

		if Window.is_visible() then
			local binder = Window.binder
			
			if binder and binder.Keybind ~= key and key ~= Enum.KeyCode.Unknown then
				Window.binder = nil
				
				if key == Enum.KeyCode.Escape then
					return binder:cancel_bind()
				end
				
				return binder:set_keybind(key)
			end
			
			local category = Window.current_category

			if key == Enum.KeyCode.Up then
				category:move(-1)
			elseif key == Enum.KeyCode.Down then
				category:move(1)
			elseif key == Enum.KeyCode.Left then
				category:slider_step(-1)
			elseif key == Enum.KeyCode.Right then
				category:slider_step(1)
			elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter then
				category:click()
			elseif key == Enum.KeyCode.Backspace then
				Window:close_category()
			end
		end
	end)

	local ContextActionService = game:GetService("ContextActionService")

	ContextActionService:BindActionAtPriority("DisableArrowKeys", function()
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right)

	return Window	
end

function Library.create_row(category_frame, title)
	local text_button = Instance.new("TextLabel", category_frame)
	text_button.Size = UDim2.new(0, 300, 0, 35)
	text_button.FontFace = Font.new("rbxasset://fonts/families/Roboto.json")
	text_button.TextSize = 14
	text_button.Text = title
	text_button.TextXAlignment = Enum.TextXAlignment.Left
	text_button.TextColor3 = Color3.fromRGB(184, 184, 184)
	text_button.BackgroundTransparency = 1
	text_button.BorderSizePixel = 0

	local UIPadding = Instance.new("UIPadding", text_button)
	UIPadding.PaddingLeft = UDim.new(0, 12)

	return text_button
end

function Library.init_highlight(category, text_button)
	if not category.selected then
		category.selected = 1

		text_button.TextColor3 = Color3.fromRGB(255, 255, 255)
		text_button.BackgroundTransparency = 0.5
		text_button.BackgroundColor3 = Color3.fromRGB(77, 15, 138)
	end
end

function Library.round_float(value)
	local ratio = 10 ^ 2
	return math.round(value * ratio) / ratio
end

function Library.set_properties(instance, properties)
	for i, v in pairs(properties) do
		instance[i] = v
	end
end


return Library