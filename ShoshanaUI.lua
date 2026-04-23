local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local ShoshanaUI = {}
ShoshanaUI.__index = ShoshanaUI

local Theme = {
    Background = Color3.fromRGB(8, 11, 18),
    Window = Color3.fromRGB(11, 15, 24),
    Sidebar = Color3.fromRGB(14, 18, 28),
    Surface = Color3.fromRGB(18, 24, 36),
    SurfaceHover = Color3.fromRGB(25, 33, 47),
    SurfaceAlt = Color3.fromRGB(21, 27, 41),
    Stroke = Color3.fromRGB(39, 51, 74),
    StrokeSoft = Color3.fromRGB(30, 39, 57),
    Text = Color3.fromRGB(243, 247, 255),
    Subtext = Color3.fromRGB(144, 155, 179),
    Accent = Color3.fromRGB(131, 105, 255),
    AccentDark = Color3.fromRGB(82, 60, 188),
    AccentSoft = Color3.fromRGB(100, 185, 255),
    Success = Color3.fromRGB(72, 201, 140),
    Danger = Color3.fromRGB(255, 88, 109),
    Shadow = Color3.fromRGB(4, 6, 10),
}

local Anim = {
    Instant = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Medium = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

local function create(className, properties, children)
    local instance = Instance.new(className)

    if properties then
        for key, value in pairs(properties) do
            instance[key] = value
        end
    end

    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end

    return instance
end

local function tween(object, info, goal)
    local animation = TweenService:Create(object, info, goal)
    animation:Play()
    return animation
end

local function applyCorner(object, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 12),
        Parent = object,
    })
end

local function applyStroke(object, color, transparency, thickness)
    return create("UIStroke", {
        Color = color or Theme.Stroke,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = object,
    })
end

local function applyGradient(object, rotation, colors)
    return create("UIGradient", {
        Rotation = rotation or 0,
        Color = ColorSequence.new(colors or {
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentSoft),
        }),
        Parent = object,
    })
end

local function formatNumber(value)
    if math.abs(value % 1) < 0.000001 then
        return tostring(math.floor(value + 0.5))
    end

    return string.format("%.2f", value)
end

local function roundToStep(value, step)
    if not step or step <= 0 then
        return value
    end

    return math.floor((value / step) + 0.5) * step
end

local function safeCall(callback, ...)
    if typeof(callback) ~= "function" then
        return
    end

    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[ShoshanaUI] Callback error:", err)
    end
end

local function makeRipple(button)
    button.ClipsDescendants = true

    local overlay = create("Frame", {
        Name = "RippleOverlay",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = button.ZIndex + 1,
        Parent = button,
    })

    button.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local absolutePosition = button.AbsolutePosition
        local absoluteSize = button.AbsoluteSize
        local relativeX = input.Position.X - absolutePosition.X
        local relativeY = input.Position.Y - absolutePosition.Y
        local diameter = math.max(absoluteSize.X, absoluteSize.Y) * 1.8

        local ripple = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, relativeX, 0, relativeY),
            Size = UDim2.fromOffset(0, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.82,
            ZIndex = overlay.ZIndex,
            Parent = overlay,
        })

        applyCorner(ripple, 999)

        tween(ripple, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(diameter, diameter),
            BackgroundTransparency = 1,
        })

        task.delay(0.48, function()
            if ripple then
                ripple:Destroy()
            end
        end)
    end)
end

local function bindHoverStates(targetButton, stateTable)
    targetButton.MouseEnter:Connect(function()
        if stateTable.disabled then
            return
        end

        if stateTable.hover then
            stateTable.hover()
        end
    end)

    targetButton.MouseLeave:Connect(function()
        if stateTable.disabled then
            return
        end

        if stateTable.leave then
            stateTable.leave()
        end
    end)
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart
    local startPosition

    local function update(input)
        if not dragging then
            return
        end

        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end

    handle.InputBegan:Connect(function(input)
        local userInputType = input.UserInputType
        if userInputType ~= Enum.UserInputType.MouseButton1 and userInputType ~= Enum.UserInputType.Touch then
            return
        end

        dragging = true
        dragStart = input.Position
        startPosition = target.Position

        local connection
        connection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if connection then
                    connection:Disconnect()
                end
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        local userInputType = input.UserInputType
        if userInputType == Enum.UserInputType.MouseMovement or userInputType == Enum.UserInputType.Touch then
            update(input)
        end
    end)
end

function ShoshanaUI.new(config)
    config = config or {}

    local parent = config.Parent or LocalPlayer:WaitForChild("PlayerGui")
    local guiName = config.Name or "ShoshanaUI"
    local title = config.Title or "Shoshana"
    local subtitle = config.Subtitle or "Premium Interface"
    local keybind = config.Keybind or Enum.KeyCode.RightShift

    local self = setmetatable({}, ShoshanaUI)
    self.Tabs = {}
    self.CurrentTab = nil
    self.Minimized = false
    self.Open = true

    local existing = parent:FindFirstChild(guiName)
    if existing then
        existing:Destroy()
    end

    self.ScreenGui = create("ScreenGui", {
        Name = guiName,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = parent,
    })

    self.Root = create("Frame", {
        Name = "Root",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = self.ScreenGui,
    })

    self.NotificationLayer = create("Frame", {
        Name = "NotificationLayer",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -24, 0, 24),
        Size = UDim2.fromOffset(360, 500),
        Parent = self.Root,
    })

    create("UIListLayout", {
        Padding = UDim.new(0, 12),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.NotificationLayer,
    })

    self.Shadow = create("Frame", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(866, 536),
        BackgroundColor3 = Theme.Shadow,
        BackgroundTransparency = 0.45,
        Parent = self.Root,
    })
    applyCorner(self.Shadow, 28)

    self.Window = create("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = config.Size or UDim2.fromOffset(840, 510),
        BackgroundColor3 = Theme.Window,
        Parent = self.Root,
    })
    applyCorner(self.Window, 24)
    applyStroke(self.Window, Theme.Stroke, 0, 1)

    create("UISizeConstraint", {
        MinSize = Vector2.new(680, 420),
        MaxSize = Vector2.new(1200, 760),
        Parent = self.Window,
    })

    local scale = create("UIScale", {
        Scale = 0.94,
        Parent = self.Window,
    })

    tween(scale, Anim.Spring, { Scale = 1 })
    tween(self.Shadow, Anim.Slow, { BackgroundTransparency = 0.25 })

    local accentBar = create("Frame", {
        Name = "AccentBar",
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 3),
        Parent = self.Window,
    })
    applyGradient(accentBar, 0, {
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.AccentSoft),
    })

    self.Topbar = create("Frame", {
        Name = "Topbar",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58),
        Parent = self.Window,
    })

    local titleGroup = create("Frame", {
        Name = "TitleGroup",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 18, 0, 12),
        Size = UDim2.new(1, -162, 0, 38),
        Parent = self.Topbar,
    })

    create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 19,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleGroup,
    })

    create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 0, 18),
        Font = Enum.Font.Gotham,
        Text = subtitle,
        TextColor3 = Theme.Subtext,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleGroup,
    })

    local controls = create("Frame", {
        Name = "WindowControls",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -18, 0, 12),
        Size = UDim2.fromOffset(126, 34),
        Parent = self.Topbar,
    })

    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        Parent = controls,
    })

    local function createControlButton(symbol, backgroundColor)
        local button = create("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = backgroundColor,
            Size = UDim2.fromOffset(34, 34),
            Font = Enum.Font.GothamBold,
            Text = symbol,
            TextColor3 = Theme.Text,
            TextSize = 16,
            Parent = controls,
        })
        applyCorner(button, 12)
        applyStroke(button, Theme.Stroke, 0.15, 1)
        makeRipple(button)

        bindHoverStates(button, {
            hover = function()
                tween(button, Anim.Fast, { BackgroundColor3 = Theme.SurfaceHover })
            end,
            leave = function()
                tween(button, Anim.Fast, { BackgroundColor3 = backgroundColor })
            end,
        })

        return button
    end

    local minimizeButton = createControlButton("–", Theme.Surface)
    local closeButton = createControlButton("×", Theme.Surface)

    self.Body = create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 58),
        Size = UDim2.new(1, 0, 1, -58),
        Parent = self.Window,
    })

    self.Sidebar = create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.Sidebar,
        Size = UDim2.new(0, 190, 1, 0),
        Parent = self.Body,
    })
    applyCorner(self.Sidebar, 0)

    local sidebarPadding = create("UIPadding", {
        PaddingLeft = UDim.new(0, 16),
        PaddingRight = UDim.new(0, 16),
        PaddingTop = UDim.new(0, 18),
        PaddingBottom = UDim.new(0, 18),
        Parent = self.Sidebar,
    })
    sidebarPadding.Name = "Padding"

    local sidebarHeader = create("Frame", {
        Name = "SidebarHeader",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 56),
        Parent = self.Sidebar,
    })

    local logo = create("Frame", {
        Name = "Logo",
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.fromOffset(42, 42),
        Parent = sidebarHeader,
    })
    applyCorner(logo, 14)
    applyGradient(logo, 25, {
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.AccentSoft),
    })

    create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Font = Enum.Font.GothamBlack,
        Text = "S",
        TextColor3 = Theme.Text,
        TextSize = 22,
        Parent = logo,
    })

    create("TextLabel", {
        Name = "BrandTitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 54, 0, 2),
        Size = UDim2.new(1, -54, 0, 22),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebarHeader,
    })

    create("TextLabel", {
        Name = "BrandSubtitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 54, 0, 24),
        Size = UDim2.new(1, -54, 0, 18),
        Font = Enum.Font.Gotham,
        Text = "Unified UI System",
        TextColor3 = Theme.Subtext,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sidebarHeader,
    })

    local sidebarDivider = create("Frame", {
        BackgroundColor3 = Theme.StrokeSoft,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 68),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = self.Sidebar,
    })
    sidebarDivider.Name = "Divider"

    self.TabList = create("Frame", {
        Name = "TabList",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 82),
        Size = UDim2.new(1, 0, 1, -82),
        Parent = self.Sidebar,
    })

    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.TabList,
    })

    self.Content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 190, 0, 0),
        Size = UDim2.new(1, -190, 1, 0),
        Parent = self.Body,
    })

    local contentPadding = create("UIPadding", {
        PaddingLeft = UDim.new(0, 18),
        PaddingRight = UDim.new(0, 18),
        PaddingTop = UDim.new(0, 18),
        PaddingBottom = UDim.new(0, 18),
        Parent = self.Content,
    })
    contentPadding.Name = "Padding"

    local pageHolder = create("Frame", {
        Name = "PageHolder",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = self.Content,
    })
    self.PageHolder = pageHolder

    makeDraggable(self.Topbar, self.Window)
    makeDraggable(self.Sidebar, self.Window)

    function self:SetVisible(state)
        self.Open = state
        self.ScreenGui.Enabled = state
    end

    function self:ToggleVisible()
        self:SetVisible(not self.Open)
    end

    function self:SetMinimized(state)
        if self.Minimized == state then
            return
        end

        self.Minimized = state

        if state then
            tween(self.Window, Anim.Medium, { Size = UDim2.new(self.Window.Size.X.Scale, self.Window.Size.X.Offset, 0, 58) })
            tween(self.Shadow, Anim.Medium, { Size = UDim2.new(self.Shadow.Size.X.Scale, self.Shadow.Size.X.Offset, 0, 88) })
            task.delay(0.12, function()
                self.Body.Visible = false
            end)
        else
            self.Body.Visible = true
            tween(self.Window, Anim.Slow, { Size = config.Size or UDim2.fromOffset(840, 510) })
            tween(self.Shadow, Anim.Slow, { Size = UDim2.fromOffset(866, 536) })
        end
    end

    function self:Notify(data)
        data = data or {}

        local wrapper = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 80),
            Parent = self.NotificationLayer,
        })

        local notification = create("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 40, 0, 0),
            BackgroundColor3 = Theme.Surface,
            BackgroundTransparency = 0.18,
            Size = UDim2.new(1, 0, 0, 80),
            Parent = wrapper,
        })
        applyCorner(notification, 18)
        local stroke = applyStroke(notification, Theme.Stroke, 0.05, 1)
        applyGradient(stroke, 0, {
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentSoft),
        })

        local leftAccent = create("Frame", {
            BackgroundColor3 = Theme.Accent,
            Size = UDim2.new(0, 4, 1, 0),
            Parent = notification,
        })
        applyGradient(leftAccent, 0, {
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentSoft),
        })

        local padding = create("UIPadding", {
            PaddingLeft = UDim.new(0, 18),
            PaddingRight = UDim.new(0, 18),
            PaddingTop = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
            Parent = notification,
        })
        padding.Name = "Padding"

        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Font = Enum.Font.GothamBold,
            Text = data.Title or title,
            TextColor3 = Theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = notification,
        })

        create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 24),
            Size = UDim2.new(1, 0, 0, 32),
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            Text = data.Text or "Notification",
            TextColor3 = Theme.Subtext,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = notification,
        })

        tween(notification, Anim.Slow, {
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 0.02,
        })

        task.delay(data.Duration or 4, function()
            if not notification.Parent then
                return
            end

            tween(notification, Anim.Medium, {
                Position = UDim2.new(1, 40, 0, 0),
                BackgroundTransparency = 0.2,
            })
            task.delay(0.22, function()
                if wrapper then
                    wrapper:Destroy()
                end
            end)
        end)
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == keybind then
            self:ToggleVisible()
        end
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        self:SetMinimized(not self.Minimized)
    end)

    closeButton.MouseButton1Click:Connect(function()
        self.ScreenGui:Destroy()
    end)

    return self
end

function ShoshanaUI:CreateTab(name)
    local tabButton = create("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(1, 0, 0, 42),
        Font = Enum.Font.GothamSemibold,
        Text = "",
        Parent = self.TabList,
    })
    applyCorner(tabButton, 14)
    local tabStroke = applyStroke(tabButton, Theme.StrokeSoft, 0.1, 1)

    local highlight = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.new(0, 4, 0, 20),
        Position = UDim2.new(0, 10, 0.5, -10),
        BackgroundTransparency = 1,
        Parent = tabButton,
    })
    applyCorner(highlight, 999)
    applyGradient(highlight, 0, {
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Theme.AccentSoft),
    })

    local label = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 24, 0, 0),
        Size = UDim2.new(1, -30, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = name,
        TextColor3 = Theme.Subtext,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tabButton,
    })

    makeRipple(tabButton)

    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = self.PageHolder,
    })

    local pagePadding = create("UIPadding", {
        PaddingBottom = UDim.new(0, 2),
        Parent = page,
    })
    pagePadding.Name = "Padding"

    local pageLayout = create("UIListLayout", {
        Padding = UDim.new(0, 14),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page,
    })
    pageLayout.Name = "Layout"

    local tab = {
        Button = tabButton,
        Label = label,
        Highlight = highlight,
        Stroke = tabStroke,
        Page = page,
        Sections = {},
    }

    function tab:SetActive(state)
        if state then
            tween(tabButton, Anim.Fast, { BackgroundColor3 = Theme.SurfaceHover })
            tween(label, Anim.Fast, { TextColor3 = Theme.Text })
            tween(highlight, Anim.Fast, { BackgroundTransparency = 0 })
            tween(tabStroke, Anim.Fast, { Transparency = 0 })
            tab.Page.Visible = true
        else
            tween(tabButton, Anim.Fast, { BackgroundColor3 = Theme.Surface })
            tween(label, Anim.Fast, { TextColor3 = Theme.Subtext })
            tween(highlight, Anim.Fast, { BackgroundTransparency = 1 })
            tween(tabStroke, Anim.Fast, { Transparency = 0.1 })
            tab.Page.Visible = false
        end
    end

    function self:SelectTab(targetTab)
        if self.CurrentTab == targetTab then
            return
        end

        if self.CurrentTab then
            self.CurrentTab:SetActive(false)
        end

        self.CurrentTab = targetTab
        targetTab:SetActive(true)
    end

    bindHoverStates(tabButton, {
        hover = function()
            if self.CurrentTab ~= tab then
                tween(tabButton, Anim.Fast, { BackgroundColor3 = Theme.SurfaceHover })
                tween(label, Anim.Fast, { TextColor3 = Theme.Text })
            end
        end,
        leave = function()
            if self.CurrentTab ~= tab then
                tween(tabButton, Anim.Fast, { BackgroundColor3 = Theme.Surface })
                tween(label, Anim.Fast, { TextColor3 = Theme.Subtext })
            end
        end,
    })

    tabButton.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    function tab:CreateSection(sectionTitle, description)
        local section = {}

        section.Frame = create("Frame", {
            BackgroundColor3 = Theme.Surface,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, -4, 0, 0),
            Parent = page,
        })
        applyCorner(section.Frame, 18)
        applyStroke(section.Frame, Theme.Stroke, 0.05, 1)

        local sectionPadding = create("UIPadding", {
            PaddingTop = UDim.new(0, 16),
            PaddingBottom = UDim.new(0, 16),
            PaddingLeft = UDim.new(0, 16),
            PaddingRight = UDim.new(0, 16),
            Parent = section.Frame,
        })
        sectionPadding.Name = "Padding"

        local header = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, description and 42 or 22),
            Parent = section.Frame,
        })

        create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Font = Enum.Font.GothamBold,
            Text = sectionTitle,
            TextColor3 = Theme.Text,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = header,
        })

        if description then
            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 22),
                Size = UDim2.new(1, 0, 0, 16),
                Font = Enum.Font.Gotham,
                Text = description,
                TextColor3 = Theme.Subtext,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = header,
            })
        end

        local divider = create("Frame", {
            BackgroundColor3 = Theme.StrokeSoft,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 1),
            Parent = section.Frame,
        })
        divider.Name = "Divider"

        section.Content = create("Frame", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = section.Frame,
        })
        section.Content.Position = UDim2.new(0, 0, 0, header.Size.Y.Offset + 12)

        local contentLayout = create("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = section.Content,
        })
        contentLayout.Name = "Layout"

        header:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            section.Content.Position = UDim2.new(0, 0, 0, header.AbsoluteSize.Y + 12)
            divider.Position = UDim2.new(0, 0, 0, header.AbsoluteSize.Y + 6)
        end)
        divider.Position = UDim2.new(0, 0, 0, header.AbsoluteSize.Y + 6)

        local function createRow(height)
            local row = create("Frame", {
                BackgroundColor3 = Theme.SurfaceAlt,
                Size = UDim2.new(1, 0, 0, height),
                Parent = section.Content,
            })
            applyCorner(row, 14)
            applyStroke(row, Theme.StrokeSoft, 0.08, 1)
            return row
        end

        function section:CreateButton(data)
            data = data or {}

            local row = createRow(46)
            local button = create("TextButton", {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Font = Enum.Font.GothamSemibold,
                Text = "",
                Parent = row,
            })

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 16, 0, 0),
                Size = UDim2.new(1, -32, 1, 0),
                Font = Enum.Font.GothamSemibold,
                Text = data.Text or "Button",
                TextColor3 = Theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local arrow = create("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -16, 0.5, 0),
                Size = UDim2.fromOffset(20, 20),
                Font = Enum.Font.GothamBold,
                Text = ">",
                TextColor3 = Theme.Subtext,
                TextSize = 14,
                Parent = row,
            })

            makeRipple(button)
            bindHoverStates(button, {
                hover = function()
                    tween(row, Anim.Fast, { BackgroundColor3 = Theme.SurfaceHover })
                    tween(arrow, Anim.Fast, { TextColor3 = Theme.Text })
                end,
                leave = function()
                    tween(row, Anim.Fast, { BackgroundColor3 = Theme.SurfaceAlt })
                    tween(arrow, Anim.Fast, { TextColor3 = Theme.Subtext })
                end,
            })

            button.MouseButton1Click:Connect(function()
                safeCall(data.Callback)
            end)

            return row
        end

        function section:CreateLabel(data)
            data = data or {}
            local row = createRow(42)
            row.BackgroundTransparency = 0.15

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 16, 0, 0),
                Size = UDim2.new(1, -32, 1, 0),
                Font = Enum.Font.Gotham,
                Text = data.Text or "Label",
                TextColor3 = Theme.Subtext,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            return {
                SetText = function(_, text)
                    local labelInstance = row:FindFirstChildOfClass("TextLabel")
                    if labelInstance then
                        labelInstance.Text = text
                    end
                end,
            }
        end

        function section:CreateParagraph(data)
            data = data or {}
            local row = createRow(data.Height or 78)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 16, 0, 10),
                Size = UDim2.new(1, -32, 1, -20),
                Font = Enum.Font.Gotham,
                TextWrapped = true,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = data.Text or "Paragraph",
                TextColor3 = Theme.Subtext,
                TextSize = 12,
                Parent = row,
            })

            return row
        end

        function section:CreateToggle(data)
            data = data or {}
            local state = data.Default == true

            local row = createRow(50)
            local button = create("TextButton", {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                Parent = row,
            })

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 16, 0, 0),
                Size = UDim2.new(1, -90, 1, 0),
                Font = Enum.Font.GothamSemibold,
                Text = data.Text or "Toggle",
                TextColor3 = Theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local switch = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -16, 0.5, 0),
                Size = UDim2.fromOffset(52, 28),
                BackgroundColor3 = Theme.Background,
                Parent = row,
            })
            applyCorner(switch, 999)
            local switchStroke = applyStroke(switch, Theme.Stroke, 0, 1)

            local switchFill = create("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                Parent = switch,
            })
            applyCorner(switchFill, 999)
            applyGradient(switchFill, 0, {
                ColorSequenceKeypoint.new(0, Theme.Accent),
                ColorSequenceKeypoint.new(1, Theme.AccentSoft),
            })

            local knob = create("Frame", {
                Position = UDim2.new(0, 3, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.fromOffset(22, 22),
                BackgroundColor3 = Theme.Text,
                Parent = switch,
            })
            applyCorner(knob, 999)

            local api = {}

            local function setState(value)
                state = value

                if state then
                    tween(switchFill, Anim.Fast, { BackgroundTransparency = 0 })
                    tween(knob, Anim.Fast, { Position = UDim2.new(1, -25, 0.5, 0) })
                    tween(switchStroke, Anim.Fast, { Transparency = 0.35 })
                else
                    tween(switchFill, Anim.Fast, { BackgroundTransparency = 1 })
                    tween(knob, Anim.Fast, { Position = UDim2.new(0, 3, 0.5, 0) })
                    tween(switchStroke, Anim.Fast, { Transparency = 0 })
                end

                safeCall(data.Callback, state)
            end

            function api:Set(value)
                setState(value)
            end

            function api:Get()
                return state
            end

            makeRipple(button)
            bindHoverStates(button, {
                hover = function()
                    tween(row, Anim.Fast, { BackgroundColor3 = Theme.SurfaceHover })
                end,
                leave = function()
                    tween(row, Anim.Fast, { BackgroundColor3 = Theme.SurfaceAlt })
                end,
            })

            button.MouseButton1Click:Connect(function()
                setState(not state)
            end)

            setState(state)
            return api
        end

        function section:CreateSlider(data)
            data = data or {}
            local min = data.Min or 0
            local max = data.Max or 100
            local increment = data.Increment or 1
            local value = math.clamp(data.Default or min, min, max)
            local dragging = false

            local row = createRow(66)

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 16, 0, 10),
                Size = UDim2.new(1, -110, 0, 18),
                Font = Enum.Font.GothamSemibold,
                Text = data.Text or "Slider",
                TextColor3 = Theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local valueLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -16, 0, 10),
                Size = UDim2.fromOffset(80, 18),
                Font = Enum.Font.GothamMedium,
                Text = formatNumber(value),
                TextColor3 = Theme.Subtext,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row,
            })

            local bar = create("Frame", {
                Position = UDim2.new(0, 16, 0, 40),
                Size = UDim2.new(1, -32, 0, 8),
                BackgroundColor3 = Theme.Background,
                Parent = row,
            })
            applyCorner(bar, 999)
            applyStroke(bar, Theme.StrokeSoft, 0.2, 1)

            local fill = create("Frame", {
                Size = UDim2.fromScale(0, 1),
                BackgroundColor3 = Theme.Accent,
                Parent = bar,
            })
            applyCorner(fill, 999)
            applyGradient(fill, 0, {
                ColorSequenceKeypoint.new(0, Theme.Accent),
                ColorSequenceKeypoint.new(1, Theme.AccentSoft),
            })

            local knob = create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                BackgroundColor3 = Theme.Text,
                Parent = bar,
            })
            applyCorner(knob, 999)
            applyStroke(knob, Theme.StrokeSoft, 0.15, 1)

            local api = {}

            local function render(newValue, instant)
                value = math.clamp(roundToStep(newValue, increment), min, max)
                local range = max - min
                local alpha = range ~= 0 and ((value - min) / range) or 0
                valueLabel.Text = formatNumber(value)

                if instant then
                    fill.Size = UDim2.new(alpha, 0, 1, 0)
                    knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                else
                    tween(fill, Anim.Fast, { Size = UDim2.new(alpha, 0, 1, 0) })
                    tween(knob, Anim.Fast, { Position = UDim2.new(alpha, 0, 0.5, 0) })
                end

                safeCall(data.Callback, value)
            end

            local function valueFromInput(inputX)
                local alpha = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                return min + ((max - min) * alpha)
            end

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    render(valueFromInput(input.Position.X), false)
                end
            end)

            bar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if not dragging then
                    return
                end

                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    render(valueFromInput(input.Position.X), true)
                end
            end)

            function api:Set(newValue)
                render(newValue, false)
            end

            function api:Get()
                return value
            end

            render(value, true)
            return api
        end

        function section:CreateDropdown(data)
            data = data or {}
            local options = data.Options or {}
            local selected = data.Default or options[1] or "None"
            local open = false

            local root = createRow(46)
            root.ClipsDescendants = true

            local headerButton = create("TextButton", {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 46),
                Text = "",
                Parent = root,
            })

            create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 16, 0, 0),
                Size = UDim2.new(1, -110, 0, 46),
                Font = Enum.Font.GothamSemibold,
                Text = data.Text or "Dropdown",
                TextColor3 = Theme.Text,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = root,
            })

            local selectedLabel = create("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -36, 0.5, 0),
                Size = UDim2.fromOffset(150, 18),
                Font = Enum.Font.Gotham,
                Text = tostring(selected),
                TextColor3 = Theme.Subtext,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = root,
            })

            local icon = create("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -16, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                Font = Enum.Font.GothamBold,
                Text = "v",
                TextColor3 = Theme.Subtext,
                TextSize = 12,
                Parent = root,
            })

            local optionHolder = create("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 46),
                Size = UDim2.new(1, -20, 0, 0),
                ClipsDescendants = true,
                Parent = root,
            })

            local optionList = create("UIListLayout", {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = optionHolder,
            })
            optionList.Name = "Layout"

            local api = {}

            local function refreshHeight(animated)
                local contentHeight = (#options * 30) + math.max(#options - 1, 0) * 8
                local targetOptionHeight = open and contentHeight or 0
                local targetRootHeight = 46 + (open and (contentHeight + 12) or 0)

                if animated then
                    tween(root, Anim.Medium, { Size = UDim2.new(1, 0, 0, targetRootHeight) })
                    tween(optionHolder, Anim.Medium, { Size = UDim2.new(1, -20, 0, targetOptionHeight) })
                    tween(icon, Anim.Fast, { Rotation = open and 180 or 0, TextColor3 = open and Theme.Text or Theme.Subtext })
                else
                    root.Size = UDim2.new(1, 0, 0, targetRootHeight)
                    optionHolder.Size = UDim2.new(1, -20, 0, targetOptionHeight)
                    icon.Rotation = open and 180 or 0
                    icon.TextColor3 = open and Theme.Text or Theme.Subtext
                end
            end

            local function setSelected(value)
                selected = value
                selectedLabel.Text = tostring(value)
                safeCall(data.Callback, value)
            end

            local function rebuildOptions()
                for _, child in ipairs(optionHolder:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                for _, option in ipairs(options) do
                    local optionButton = create("TextButton", {
                        AutoButtonColor = false,
                        BackgroundColor3 = Theme.Background,
                        Size = UDim2.new(1, 0, 0, 30),
                        Font = Enum.Font.Gotham,
                        Text = tostring(option),
                        TextColor3 = Theme.Subtext,
                        TextSize = 12,
                        Parent = optionHolder,
                    })
                    applyCorner(optionButton, 10)
                    applyStroke(optionButton, Theme.StrokeSoft, 0.12, 1)
                    makeRipple(optionButton)

                    bindHoverStates(optionButton, {
                        hover = function()
                            tween(optionButton, Anim.Fast, { BackgroundColor3 = Theme.SurfaceHover, TextColor3 = Theme.Text })
                        end,
                        leave = function()
                            tween(optionButton, Anim.Fast, { BackgroundColor3 = Theme.Background, TextColor3 = Theme.Subtext })
                        end,
                    })

                    optionButton.MouseButton1Click:Connect(function()
                        setSelected(option)
                        open = false
                        refreshHeight(true)
                    end)
                end
            end

            headerButton.MouseButton1Click:Connect(function()
                open = not open
                refreshHeight(true)
            end)

            bindHoverStates(headerButton, {
                hover = function()
                    tween(root, Anim.Fast, { BackgroundColor3 = Theme.SurfaceHover })
                end,
                leave = function()
                    tween(root, Anim.Fast, { BackgroundColor3 = Theme.SurfaceAlt })
                end,
            })

            function api:Set(value)
                setSelected(value)
            end

            function api:Get()
                return selected
            end

            function api:SetOptions(newOptions)
                options = newOptions or {}
                if not table.find(options, selected) then
                    selected = options[1] or "None"
                    selectedLabel.Text = tostring(selected)
                end
                rebuildOptions()
                refreshHeight(false)
            end

            rebuildOptions()
            refreshHeight(false)
            return api
        end

        table.insert(tab.Sections, section)
        return section
    end

    table.insert(self.Tabs, tab)

    if not self.CurrentTab then
        self:SelectTab(tab)
    end

    return tab
end

return ShoshanaUI
