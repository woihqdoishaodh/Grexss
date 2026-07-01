--[[
	AxiomUI — lightweight, elegant Roblox UI library
	Single file. No external assets. Dark minimal theme.

	Usage:
		local Lib = loadstring(game:HttpGet("..."))() -- or require(script)
		local Window = Lib:CreateWindow({ Title = "My Script", Size = UDim2.fromOffset(520, 360) })
		local Tab = Window:AddTab("Main")
		local Section = Tab:AddSection("General")

		Section:AddButton({ Text = "Click me", Callback = function() print("hi") end })
		Section:AddToggle({ Text = "Enabled", Default = false, Callback = function(v) end })
		Section:AddSlider({ Text = "Speed", Min = 0, Max = 100, Default = 50, Callback = function(v) end })
		Section:AddDropdown({ Text = "Mode", Options = {"A","B","C"}, Default = "A", Callback = function(v) end })
		Section:AddLabel("Just some text")
		Section:AddColorPicker({ Text = "Color", Default = Color3.new(1,1,1), Callback = function(c) end })
		Section:AddKeybind({ Text = "Toggle Key", Default = Enum.KeyCode.RightControl, Callback = function() end })

		Window:Notify({ Title = "Saved", Content = "Config saved.", Duration = 3 })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local function protect(g)
	local ok = (syn and syn.protect_gui) or protect_gui or protectgui
	if ok then pcall(ok, g) end
end

local Lib = {}
Lib.Theme = {
	Background = Color3.fromRGB(18, 18, 22),
	Panel      = Color3.fromRGB(24, 24, 29),
	Element    = Color3.fromRGB(30, 30, 36),
	Stroke     = Color3.fromRGB(42, 42, 50),
	Accent     = Color3.fromRGB(120, 140, 255),
	Text       = Color3.fromRGB(235, 235, 240),
	SubText    = Color3.fromRGB(150, 150, 160),
	Font       = Enum.Font.GothamMedium,
	FontBold   = Enum.Font.GothamBold,
}

local FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
local SMOOTH = TweenInfo.new(0.22, Enum.EasingStyle.Quint)

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function new(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	return inst
end

local function corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

local function stroke(color, thickness, transparency)
	return new("UIStroke", {
		Color = color or Lib.Theme.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0.4,
	})
end

local function padding(l, r, t, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingRight = UDim.new(0, r or l or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or t or 0),
	})
end

local function makeDraggable(handle, target)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					conn:Disconnect()
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ==========================================================
-- WINDOW
-- ==========================================================
function Lib:CreateWindow(cfg)
	cfg = cfg or {}
	local Theme = Lib.Theme

	local ScreenGui = new("ScreenGui", {
		Name = "AxiomUI_" .. tostring(math.random(10000, 99999)),
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = (gethui and gethui()) or LocalPlayer:WaitForChild("PlayerGui"),
	})
	protect(ScreenGui)

	local WindowSize = cfg.Size or UDim2.fromOffset(520, 360)

	local Main = new("Frame", {
		Name = "Main",
		Parent = ScreenGui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = WindowSize,
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, { corner(10), stroke(Theme.Stroke, 1, 0.35) })

	-- subtle shadow
	local Shadow = new("ImageLabel", {
		Name = "Shadow",
		Parent = Main,
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.55,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 40, 1, 40),
		ZIndex = -1,
	})

	local TopBar = new("Frame", {
		Parent = Main,
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	}, {
		corner(10),
	})
	-- flatten bottom corners of topbar via a cover frame
	new("Frame", {
		Parent = TopBar,
		Position = UDim2.new(0, 0, 1, -10),
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	})

	local Title = new("TextLabel", {
		Parent = TopBar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 0),
		Size = UDim2.new(1, -80, 1, 0),
		Font = Theme.FontBold,
		Text = cfg.Title or "Window",
		TextColor3 = Theme.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	if cfg.SubTitle then
		Title.Position = UDim2.new(0, 16, 0, -6)
		new("TextLabel", {
			Parent = TopBar,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, 22),
			Size = UDim2.new(1, -80, 0, 14),
			Font = Theme.Font,
			Text = cfg.SubTitle,
			TextColor3 = Theme.SubText,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	local CloseBtn = new("TextButton", {
		Parent = TopBar,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.new(0, 22, 0, 22),
		BackgroundColor3 = Theme.Element,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
	}, { corner(6) })
	new("TextLabel", {
		Parent = CloseBtn,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Theme.FontBold,
		Text = "×",
		TextColor3 = Theme.SubText,
		TextSize = 16,
	})

	makeDraggable(TopBar, Main)

	-- Tab bar (left column)
	local TabBar = new("Frame", {
		Parent = Main,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(0, 130, 1, -42),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
	})
	local TabBarList = new("Frame", {
		Parent = TabBar,
		Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(1, -16, 1, -16),
		BackgroundTransparency = 1,
	}, { new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })

	local Divider = new("Frame", {
		Parent = Main,
		Position = UDim2.new(0, 130, 0, 42),
		Size = UDim2.new(0, 1, 1, -42),
		BackgroundColor3 = Theme.Stroke,
		BorderSizePixel = 0,
	})

	local PagesHolder = new("Frame", {
		Parent = Main,
		Position = UDim2.new(0, 131, 0, 42),
		Size = UDim2.new(1, -131, 1, -42),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	})

	local Window = { Tabs = {}, Root = Main, ScreenGui = ScreenGui, Visible = true }

	CloseBtn.MouseButton1Click:Connect(function()
		Window.Visible = false
		tween(Main, FAST, { Size = UDim2.new(WindowSize.X.Scale, WindowSize.X.Offset - 30, WindowSize.Y.Scale, WindowSize.Y.Offset - 30), BackgroundTransparency = 1 })
		task.delay(0.15, function() ScreenGui.Enabled = false end)
	end)
	CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, FAST, { BackgroundColor3 = Color3.fromRGB(190, 70, 70) }) end)
	CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, FAST, { BackgroundColor3 = Theme.Element }) end)

	function Window:Toggle()
		ScreenGui.Enabled = not ScreenGui.Enabled
	end

	if cfg.ToggleKey then
		UserInputService.InputBegan:Connect(function(input, typing)
			if typing then return end
			if input.KeyCode == cfg.ToggleKey then
				Window:Toggle()
			end
		end)
	end

	local currentPage

	function Window:AddTab(name, icon)
		local Page = new("ScrollingFrame", {
			Parent = PagesHolder,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
		}, {
			padding(14, 14, 14, 14),
			new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		})

		local TabBtn = new("TextButton", {
			Parent = TabBarList,
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			BorderSizePixel = 0,
		}, { corner(6) })
		new("TextLabel", {
			Parent = TabBtn,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(1, -20, 1, 0),
			Font = Theme.Font,
			Text = name,
			TextColor3 = Theme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local Indicator = new("Frame", {
			Parent = TabBtn,
			Size = UDim2.new(0, 3, 0, 0),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
		}, { corner(2) })

		local Tab = { Page = Page, Button = TabBtn }

		local function select()
			if currentPage then
				currentPage.Page.Visible = false
				tween(currentPage.Button, FAST, { BackgroundTransparency = 1 })
				local lbl = currentPage.Button:FindFirstChildOfClass("TextLabel")
				if lbl then tween(lbl, FAST, { TextColor3 = Theme.SubText }) end
				tween(currentPage.Button.Frame or Indicator, FAST, {})
			end
			Page.Visible = true
			currentPage = Tab
			tween(TabBtn, FAST, { BackgroundTransparency = 0 })
			tween(TabBtn:FindFirstChildOfClass("TextLabel"), FAST, { TextColor3 = Theme.Text })
			tween(Indicator, FAST, { Size = UDim2.new(0, 3, 0, 18) })
		end

		TabBtn.MouseButton1Click:Connect(select)
		TabBtn.MouseEnter:Connect(function()
			if currentPage ~= Tab then tween(TabBtn, FAST, { BackgroundTransparency = 0.65 }) end
		end)
		TabBtn.MouseLeave:Connect(function()
			if currentPage ~= Tab then tween(TabBtn, FAST, { BackgroundTransparency = 1 }) end
		end)

		if not currentPage then
			select()
		end

		-- ==========================================================
		-- SECTION
		-- ==========================================================
		function Tab:AddSection(name)
			local Section = new("Frame", {
				Parent = Page,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Panel,
				BorderSizePixel = 0,
			}, {
				corner(8),
				stroke(Theme.Stroke, 1, 0.5),
				padding(12, 12, 10, 12),
			})
			new("UIListLayout", { Parent = Section, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })

			if name then
				new("TextLabel", {
					Parent = Section,
					LayoutOrder = -1,
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Font = Theme.FontBold,
					Text = name,
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
			end

			local Sect = {}

			-- ---------- BUTTON ----------
			function Sect:AddButton(o)
				o = o or {}
				local Btn = new("TextButton", {
					Parent = Section,
					Size = UDim2.new(1, 0, 0, 32),
					BackgroundColor3 = Theme.Element,
					AutoButtonColor = false,
					Text = "",
					BorderSizePixel = 0,
				}, { corner(6), stroke(Theme.Stroke, 1, 0.6) })
				new("TextLabel", {
					Parent = Btn,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Font = Theme.Font,
					Text = o.Text or "Button",
					TextColor3 = Theme.Text,
					TextSize = 13,
				})
				Btn.MouseEnter:Connect(function() tween(Btn, FAST, { BackgroundColor3 = Theme.Accent }) end)
				Btn.MouseLeave:Connect(function() tween(Btn, FAST, { BackgroundColor3 = Theme.Element }) end)
				Btn.MouseButton1Click:Connect(function()
					tween(Btn, TweenInfo.new(0.08), { BackgroundColor3 = Theme.Accent })
					if o.Callback then
						local ok, err = pcall(o.Callback)
						if not ok then warn("[AxiomUI] Button callback error: " .. tostring(err)) end
					end
				end)
				return Btn
			end

			-- ---------- LABEL ----------
			function Sect:AddLabel(text)
				local Lbl = new("TextLabel", {
					Parent = Section,
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Font = Theme.Font,
					Text = tostring(text),
					TextColor3 = Theme.SubText,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
				})
				return {
					Set = function(_, t) Lbl.Text = tostring(t) end,
				}
			end

			-- ---------- TOGGLE ----------
			function Sect:AddToggle(o)
				o = o or {}
				local state = o.Default == true

				local Row = new("Frame", {
					Parent = Section,
					Size = UDim2.new(1, 0, 0, 28),
					BackgroundTransparency = 1,
				})
				new("TextLabel", {
					Parent = Row,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -46, 1, 0),
					Font = Theme.Font,
					Text = o.Text or "Toggle",
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local Track = new("TextButton", {
					Parent = Row,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 38, 0, 20),
					BackgroundColor3 = state and Theme.Accent or Theme.Element,
					AutoButtonColor = false,
					Text = "",
					BorderSizePixel = 0,
				}, { corner(10), stroke(Theme.Stroke, 1, 0.6) })
				local Knob = new("Frame", {
					Parent = Track,
					Size = UDim2.new(0, 14, 0, 14),
					Position = state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
				}, { corner(7) })

				local Toggle = { Value = state }

				local function render()
					tween(Track, FAST, { BackgroundColor3 = Toggle.Value and Theme.Accent or Theme.Element })
					tween(Knob, FAST, { Position = Toggle.Value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
				end

				function Toggle:Set(v)
					Toggle.Value = v == true
					render()
					if o.Callback then pcall(o.Callback, Toggle.Value) end
				end

				Track.MouseButton1Click:Connect(function() Toggle:Set(not Toggle.Value) end)

				if state and o.Callback then pcall(o.Callback, true) end
				return Toggle
			end

			-- ---------- SLIDER ----------
			function Sect:AddSlider(o)
				o = o or {}
				local min, max = o.Min or 0, o.Max or 100
				local value = math.clamp(o.Default or min, min, max)

				local Row = new("Frame", {
					Parent = Section,
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundTransparency = 1,
				})
				new("TextLabel", {
					Parent = Row,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -50, 0, 16),
					Font = Theme.Font,
					Text = o.Text or "Slider",
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local ValLabel = new("TextLabel", {
					Parent = Row,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					Size = UDim2.new(0, 50, 0, 16),
					BackgroundTransparency = 1,
					Font = Theme.Font,
					Text = tostring(value) .. (o.Suffix or ""),
					TextColor3 = Theme.SubText,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
				})
				local Track = new("Frame", {
					Parent = Row,
					Position = UDim2.new(0, 0, 0, 24),
					Size = UDim2.new(1, 0, 0, 6),
					BackgroundColor3 = Theme.Element,
					BorderSizePixel = 0,
				}, { corner(3) })
				local Fill = new("Frame", {
					Parent = Track,
					Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
				}, { corner(3) })
				local Knob = new("Frame", {
					Parent = Track,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
					Size = UDim2.new(0, 12, 0, 12),
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 0,
				}, { corner(6) })

				local Slider = { Value = value }
				local dragging = false

				local function setFromAlpha(alpha)
					alpha = math.clamp(alpha, 0, 1)
					local raw = min + (max - min) * alpha
					local rounded = o.Rounding and (math.floor(raw / o.Rounding + 0.5) * o.Rounding) or math.floor(raw + 0.5)
					rounded = math.clamp(rounded, min, max)
					Slider.Value = rounded
					local realAlpha = (rounded - min) / (max - min)
					Fill.Size = UDim2.new(realAlpha, 0, 1, 0)
					Knob.Position = UDim2.new(realAlpha, 0, 0.5, 0)
					ValLabel.Text = tostring(rounded) .. (o.Suffix or "")
					if o.Callback then pcall(o.Callback, rounded) end
				end

				Track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						setFromAlpha((Mouse.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X)
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
						setFromAlpha((Mouse.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X)
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
					end
				end)

				function Slider:Set(v) setFromAlpha((v - min) / (max - min)) end

				if o.Callback then pcall(o.Callback, value) end
				return Slider
			end

			-- ---------- DROPDOWN ----------
			function Sect:AddDropdown(o)
				o = o or {}
				local options = o.Options or {}
				local selected = o.Default or options[1]
				local open = false

				local Row = new("Frame", {
					Parent = Section,
					Size = UDim2.new(1, 0, 0, 44),
					BackgroundTransparency = 1,
					ClipsDescendants = false,
				})
				new("TextLabel", {
					Parent = Row,
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Font = Theme.Font,
					Text = o.Text or "Dropdown",
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local Box = new("TextButton", {
					Parent = Row,
					Position = UDim2.new(0, 0, 0, 20),
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundColor3 = Theme.Element,
					AutoButtonColor = false,
					Text = "",
					BorderSizePixel = 0,
					ZIndex = 5,
				}, { corner(6), stroke(Theme.Stroke, 1, 0.6) })
				local BoxLabel = new("TextLabel", {
					Parent = Box,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -30, 1, 0),
					BackgroundTransparency = 1,
					Font = Theme.Font,
					Text = tostring(selected or "Select..."),
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 5,
				})
				local Chevron = new("TextLabel", {
					Parent = Box,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.new(0, 16, 0, 16),
					BackgroundTransparency = 1,
					Font = Theme.FontBold,
					Text = "˅",
					TextColor3 = Theme.SubText,
					TextSize = 14,
					ZIndex = 5,
				})

				local ListHolder = new("Frame", {
					Parent = Box,
					Position = UDim2.new(0, 0, 1, 4),
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Theme.Panel,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					ZIndex = 20,
				}, { corner(6), stroke(Theme.Stroke, 1, 0.4) })
				local ListLayout = new("UIListLayout", { Parent = ListHolder, SortOrder = Enum.SortOrder.LayoutOrder })
				new("UIPadding", { Parent = ListHolder, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) })

				local Dropdown = { Value = selected }

				local function close()
					open = false
					tween(ListHolder, FAST, { Size = UDim2.new(1, 0, 0, 0) })
					tween(Chevron, FAST, { Rotation = 0 })
				end

				local function rebuild()
					for _, c in ipairs(ListHolder:GetChildren()) do
						if c:IsA("TextButton") then c:Destroy() end
					end
					for _, opt in ipairs(options) do
						local Item = new("TextButton", {
							Parent = ListHolder,
							Size = UDim2.new(1, 0, 0, 26),
							BackgroundColor3 = Theme.Element,
							BackgroundTransparency = 1,
							AutoButtonColor = false,
							Text = "",
							BorderSizePixel = 0,
							ZIndex = 21,
						})
						new("TextLabel", {
							Parent = Item,
							Position = UDim2.new(0, 10, 0, 0),
							Size = UDim2.new(1, -20, 1, 0),
							BackgroundTransparency = 1,
							Font = Theme.Font,
							Text = tostring(opt),
							TextColor3 = (opt == Dropdown.Value) and Theme.Accent or Theme.Text,
							TextSize = 12,
							TextXAlignment = Enum.TextXAlignment.Left,
							ZIndex = 21,
						})
						Item.MouseEnter:Connect(function() tween(Item, FAST, { BackgroundTransparency = 0.6 }) end)
						Item.MouseLeave:Connect(function() tween(Item, FAST, { BackgroundTransparency = 1 }) end)
						Item.MouseButton1Click:Connect(function()
							Dropdown:Set(opt)
							close()
						end)
					end
				end

				function Dropdown:Set(v)
					Dropdown.Value = v
					BoxLabel.Text = tostring(v)
					rebuild()
					if o.Callback then pcall(o.Callback, v) end
				end

				function Dropdown:Refresh(newOptions)
					options = newOptions or options
					rebuild()
				end

				Box.MouseButton1Click:Connect(function()
					open = not open
					if open then
						rebuild()
						tween(ListHolder, FAST, { Size = UDim2.new(1, 0, 0, math.min(#options, 5) * 26 + 8) })
						tween(Chevron, FAST, { Rotation = 180 })
					else
						close()
					end
				end)

				rebuild()
				if selected and o.Callback then pcall(o.Callback, selected) end
				return Dropdown
			end

			-- ---------- COLOR PICKER (simple RGB sliders popover) ----------
			function Sect:AddColorPicker(o)
				o = o or {}
				local color = o.Default or Color3.new(1, 1, 1)

				local Row = new("Frame", { Parent = Section, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
				new("TextLabel", {
					Parent = Row,
					Size = UDim2.new(1, -40, 1, 0),
					BackgroundTransparency = 1,
					Font = Theme.Font,
					Text = o.Text or "Color",
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local Swatch = new("TextButton", {
					Parent = Row,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 28, 0, 20),
					BackgroundColor3 = color,
					AutoButtonColor = false,
					Text = "",
					BorderSizePixel = 0,
				}, { corner(5), stroke(Theme.Stroke, 1, 0.4) })

				local Popover = new("Frame", {
					Parent = Row,
					Visible = false,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 1, 6),
					Size = UDim2.new(0, 180, 0, 110),
					BackgroundColor3 = Theme.Panel,
					BorderSizePixel = 0,
					ZIndex = 30,
				}, { corner(6), stroke(Theme.Stroke, 1, 0.4), padding(10, 10, 10, 10) })
				new("UIListLayout", { Parent = Popover, Padding = UDim.new(0, 6) })

				local Picker = { Value = color }
				local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
				local channels = { { "R", r }, { "G", g }, { "B", b } }
				local vals = { r, g, b }

				local function apply()
					local c = Color3.fromRGB(vals[1], vals[2], vals[3])
					Picker.Value = c
					Swatch.BackgroundColor3 = c
					if o.Callback then pcall(o.Callback, c) end
				end

				for i, ch in ipairs(channels) do
					local chRow = new("Frame", { Parent = Popover, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1 })
					new("TextLabel", {
						Parent = chRow, Size = UDim2.new(0, 14, 1, 0), BackgroundTransparency = 1,
						Font = Theme.Font, Text = ch[1], TextColor3 = Theme.SubText, TextSize = 11,
					})
					local track = new("Frame", {
						Parent = chRow, Position = UDim2.new(0, 18, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
						Size = UDim2.new(1, -18, 0, 5), BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
					}, { corner(3) })
					local fill = new("Frame", {
						Parent = track, Size = UDim2.new(ch[2] / 255, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
					}, { corner(3) })
					local dragging = false
					local function set(alpha)
						alpha = math.clamp(alpha, 0, 1)
						vals[i] = math.floor(alpha * 255 + 0.5)
						fill.Size = UDim2.new(alpha, 0, 1, 0)
						apply()
					end
					track.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = true
							set((Mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
						end
					end)
					UserInputService.InputChanged:Connect(function(input)
						if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
							set((Mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X)
						end
					end)
					UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
					end)
				end

				local popOpen = false
				Swatch.MouseButton1Click:Connect(function()
					popOpen = not popOpen
					Popover.Visible = popOpen
				end)
				UserInputService.InputBegan:Connect(function(input)
					if popOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
						local p = UserInputService:GetMouseLocation()
						local abs, size = Popover.AbsolutePosition, Popover.AbsoluteSize
						local sAbs, sSize = Swatch.AbsolutePosition, Swatch.AbsoluteSize
						local inPop = p.X >= abs.X and p.X <= abs.X + size.X and p.Y >= abs.Y and p.Y <= abs.Y + size.Y
						local inSwatch = p.X >= sAbs.X and p.X <= sAbs.X + sSize.X and p.Y >= sAbs.Y and p.Y <= sAbs.Y + sSize.Y
						if not inPop and not inSwatch then
							popOpen = false
							Popover.Visible = false
						end
					end
				end)

				function Picker:Set(c)
					vals = { math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255) }
					apply()
				end

				return Picker
			end

			-- ---------- KEYBIND ----------
			function Sect:AddKeybind(o)
				o = o or {}
				local key = o.Default or Enum.KeyCode.Unknown
				local listening = false

				local Row = new("Frame", { Parent = Section, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 })
				new("TextLabel", {
					Parent = Row,
					Size = UDim2.new(1, -70, 1, 0),
					BackgroundTransparency = 1,
					Font = Theme.Font,
					Text = o.Text or "Keybind",
					TextColor3 = Theme.Text,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
				local Box = new("TextButton", {
					Parent = Row,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 64, 0, 22),
					BackgroundColor3 = Theme.Element,
					AutoButtonColor = false,
					Text = key.Name,
					Font = Theme.Font,
					TextColor3 = Theme.SubText,
					TextSize = 11,
					BorderSizePixel = 0,
				}, { corner(5), stroke(Theme.Stroke, 1, 0.5) })

				local Keybind = { Value = key }

				Box.MouseButton1Click:Connect(function()
					listening = true
					Box.Text = "..."
					tween(Box, FAST, { BackgroundColor3 = Theme.Accent })
				end)

				UserInputService.InputBegan:Connect(function(input, typing)
					if listening and input.UserInputType == Enum.UserInputType.Keyboard then
						Keybind.Value = input.KeyCode
						Box.Text = input.KeyCode.Name
						listening = false
						tween(Box, FAST, { BackgroundColor3 = Theme.Element })
						if o.Changed then pcall(o.Changed, input.KeyCode) end
						return
					end
					if not listening and not typing and input.KeyCode == Keybind.Value and o.Callback then
						pcall(o.Callback, true)
					end
				end)
				UserInputService.InputEnded:Connect(function(input)
					if not listening and input.KeyCode == Keybind.Value and o.Callback then
						pcall(o.Callback, false)
					end
				end)

				function Keybind:Set(k)
					Keybind.Value = k
					Box.Text = k.Name
				end

				return Keybind
			end

			return Sect
		end

		Window.Tabs[#Window.Tabs + 1] = Tab
		return Tab
	end

	-- ==========================================================
	-- NOTIFY
	-- ==========================================================
	local NotifyHolder = new("Frame", {
		Parent = ScreenGui,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 260, 1, -32),
		BackgroundTransparency = 1,
	}, {
		new("UIListLayout", {
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	function Window:Notify(o)
		o = o or {}
		local Card = new("Frame", {
			Parent = NotifyHolder,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Panel,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
		}, { corner(8), stroke(Theme.Stroke, 1, 1), padding(12, 12, 10, 10) })
		new("UIListLayout", { Parent = Card, Padding = UDim.new(0, 2) })

		local T = new("TextLabel", {
			Parent = Card,
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Font = Theme.FontBold,
			Text = o.Title or "Notification",
			TextColor3 = Theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = 1,
		})
		local C = new("TextLabel", {
			Parent = Card,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Font = Theme.Font,
			Text = o.Content or "",
			TextColor3 = Theme.SubText,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = 1,
		})

		tween(Card, SMOOTH, { BackgroundTransparency = 0.05 })
		tween(Card:FindFirstChildOfClass("UIStroke"), SMOOTH, { Transparency = 0.5 })
		tween(T, SMOOTH, { TextTransparency = 0 })
		tween(C, SMOOTH, { TextTransparency = 0.15 })

		task.delay(o.Duration or 4, function()
			tween(Card, FAST, { BackgroundTransparency = 1 })
			tween(T, FAST, { TextTransparency = 1 })
			tween(C, FAST, { TextTransparency = 1 })
			local s = Card:FindFirstChildOfClass("UIStroke")
			if s then tween(s, FAST, { Transparency = 1 }) end
			task.wait(0.15)
			Card:Destroy()
		end)
	end

	return Window
end

return Lib
