# ShoshanaUI

ShoshanaUI is a client-side Roblox interface library designed for projects that need a consistent, polished presentation layer across multiple scripts. The library provides a complete desktop-style window system with tabbed navigation, section containers, animated controls, notifications, and a stable API intended for repeated use.

The current build is suited for `LocalScript` execution and is structured around `PlayerGui`.

## Features

- Windowed layout with header, sidebar navigation, and content pages
- Animated transitions for open state, hover states, clicks, toggles, sliders, dropdowns, and notifications
- Built-in components for common UI workflows
- Consistent visual language across all controls
- Simple tab and section composition model
- Visibility toggle via keybind
- Draggable window surface
- Notification system for transient status messages

## Included Controls

- Button
- Label
- Paragraph
- Toggle
- Slider
- Dropdown
- Textbox

## Installation

### Standard Roblox setup

1. Create a `ModuleScript` named `ShoshanaUI`.
2. Place the contents of `ShoshanaUI.lua` into that module.
3. Store the module in `ReplicatedStorage`.
4. Require it from a `LocalScript`.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShoshanaUI = require(ReplicatedStorage:WaitForChild("ShoshanaUI"))
```

### Remote loading setup

If your environment supports remote execution through `loadstring`, the module can be loaded directly from a raw GitHub URL.

```lua
local ShoshanaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/EmiDaDuck/Shoshana-UI/refs/heads/main/ShoshanaUI.lua"))()
```

## Quick Start

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ShoshanaUI = require(ReplicatedStorage:WaitForChild("ShoshanaUI"))

local ui = ShoshanaUI.new({
    Name = "ShoshanaInterface",
    Title = "Shoshana",
    Subtitle = "Roblox UI Framework",
    Keybind = Enum.KeyCode.RightShift,
    Size = UDim2.fromOffset(840, 510),
})

ui:Notify({
    Title = "Shoshana",
    Text = "Interface loaded successfully.",
    Duration = 4,
})

local mainTab = ui:CreateTab("Main")
local section = mainTab:CreateSection("General", "Reusable controls and actions.")

section:CreateButton({
    Text = "Run Action",
    Callback = function()
        print("Action executed")
    end,
})

local toggle = section:CreateToggle({
    Text = "Enabled",
    Default = true,
    Callback = function(state)
        print("Enabled:", state)
    end,
})

local slider = section:CreateSlider({
    Text = "Speed",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 1,
    Callback = function(value)
        print("Speed:", value)
    end,
})

section:CreateDropdown({
    Text = "Mode",
    Options = {"Balanced", "Aggressive", "Silent"},
    Default = "Balanced",
    Callback = function(value)
        print("Mode:", value)
    end,
})

local search = section:CreateTextbox({
    Text = "Search",
    Placeholder = "Type to filter",
    Callback = function(value)
        print("Search:", value)
    end,
})
```

## API Overview

### Constructor

```lua
local ui = ShoshanaUI.new(config)
```

Supported configuration fields:

| Field | Type | Description |
|---|---|---|
| `Parent` | `Instance` | Optional GUI parent. Defaults to `LocalPlayer.PlayerGui`. |
| `Name` | `string` | ScreenGui name. Existing GUI with the same name is replaced. |
| `Title` | `string` | Main window title. |
| `Subtitle` | `string` | Subtitle shown below the title. |
| `Keybind` | `Enum.KeyCode` | Key used to toggle the full interface visibility. |
| `Size` | `UDim2` | Initial window size. |

### UI methods

```lua
ui:SetVisible(state)
ui:ToggleVisible()
ui:SetMinimized(state)
ui:Notify(data)
ui:CreateTab(name)
```

### Tab methods

```lua
tab:CreateSection(title, description)
```

### Section methods

```lua
section:CreateButton(data)
section:CreateLabel(data)
section:CreateParagraph(data)
section:CreateTextbox(data)
section:CreateToggle(data)
section:CreateSlider(data)
section:CreateDropdown(data)
```

Full reference and behavioral notes are documented in `DOCUMENTATION.md`.

## Behavior Notes

- The library is intended for `LocalScript` use.
- The window can be dragged from the top bar and sidebar.
- Pressing the configured keybind toggles the `ScreenGui.Enabled` state.
- The minimize button collapses the body area and preserves the top bar.
- The close button destroys the UI instance completely.
- Callback execution is protected with `pcall` and reports errors through `warn`.

## Design Scope

ShoshanaUI is opinionated by design. Theme colors, animation timing, layout structure, and component styling are defined internally to preserve a unified presentation standard. The current public API focuses on composition rather than runtime theming.

## File Layout Suggestion

```text
ReplicatedStorage
└── ShoshanaUI (ModuleScript)

StarterPlayer
└── StarterPlayerScripts
    └── YourScript (LocalScript)
```

## License

This project is licensed under the MIT License. See the LICENSE file for details.
