# ShoshanaUI Documentation

## 1. Purpose

ShoshanaUI is a reusable Roblox UI library for client-side scripts that require a consistent interface layer. The library creates a structured application-style window with navigation, grouped content sections, animated controls, and notifications.

It is intended to serve as a common visual and functional baseline across multiple projects so that separate scripts share the same presentation standard.

## 2. Runtime Model

ShoshanaUI is written for client execution.

### Expected environment

- `LocalScript`
- Access to `Players.LocalPlayer`
- Access to `LocalPlayer.PlayerGui`

### Core services used

- `TweenService`
- `UserInputService`
- `Players`

Because the library resolves `Players.LocalPlayer` during initialization, it should not be treated as a server-side module.

## 3. Initialization

### Signature

```lua
local ui = ShoshanaUI.new(config)
```

### Configuration fields

| Field | Type | Required | Default | Notes |
|---|---|---:|---|---|
| `Parent` | `Instance` | No | `LocalPlayer.PlayerGui` | Parent used for the generated `ScreenGui`. |
| `Name` | `string` | No | `"ShoshanaUI"` | The name assigned to the `ScreenGui`. An existing GUI with the same name is destroyed first. |
| `Title` | `string` | No | `"Shoshana"` | Displayed in the window header and sidebar branding area. |
| `Subtitle` | `string` | No | `"Premium Interface"` | Displayed under the main title. |
| `Keybind` | `Enum.KeyCode` | No | `Enum.KeyCode.RightShift` | Toggles the GUI visibility through `ScreenGui.Enabled`. |
| `Size` | `UDim2` | No | `UDim2.fromOffset(840, 510)` | Initial window size. |

### Example

```lua
local ui = ShoshanaUI.new({
    Name = "ShoshanaInterface",
    Title = "Shoshana",
    Subtitle = "Roblox UI Framework",
    Keybind = Enum.KeyCode.RightShift,
    Size = UDim2.fromOffset(840, 510),
})
```

## 4. Window Structure

A ShoshanaUI instance creates the following top-level structure:

- `ScreenGui`
- `Root`
- `NotificationLayer`
- `Shadow`
- `Window`
  - `Topbar`
  - `Body`
    - `Sidebar`
    - `Content`
      - `PageHolder`

### Interface regions

#### Topbar
Contains:
- title block
- subtitle block
- minimize control
- close control

The top bar also acts as a drag handle.

#### Sidebar
Contains:
- brand mark
- title repetition
- fixed subtitle text (`Unified UI System`)
- tab buttons

The sidebar also acts as a drag handle.

#### Content area
Contains one scrolling page per tab. Only the active page is visible at a time.

#### Notification layer
Anchored in the upper-right corner of the screen. Notifications stack vertically.

## 5. Public Instance API

### `ui:SetVisible(state)`

Enables or disables the generated `ScreenGui`.

```lua
ui:SetVisible(true)
ui:SetVisible(false)
```

**Parameters**
- `state: boolean`

**Notes**
- This does not destroy the UI.
- It updates `ui.Open` and `ScreenGui.Enabled`.

---

### `ui:ToggleVisible()`

Toggles the current visibility state.

```lua
ui:ToggleVisible()
```

**Notes**
- Equivalent to switching between enabled and disabled GUI states.

---

### `ui:SetMinimized(state)`

Collapses or restores the window body.

```lua
ui:SetMinimized(true)
ui:SetMinimized(false)
```

**Parameters**
- `state: boolean`

**Behavior**
- When minimized, the body is hidden and the window shrinks to the top bar height.
- When restored, the original configured size is applied again.

---

### `ui:Notify(data)`

Displays a temporary notification.

```lua
ui:Notify({
    Title = "Shoshana",
    Text = "Interface loaded successfully.",
    Duration = 4,
})
```

**Supported fields**

| Field | Type | Default | Description |
|---|---|---|---|
| `Title` | `string` | window title | Notification heading. |
| `Text` | `string` | `"Notification"` | Notification body text. |
| `Duration` | `number` | `4` | Time in seconds before dismissal. |

**Behavior**
- Notifications animate in from the right.
- Notifications dismiss automatically.
- Multiple notifications stack in the order they are created.

---

### `ui:CreateTab(name)`

Creates a new tab and corresponding content page.

```lua
local tab = ui:CreateTab("Dashboard")
```

**Parameters**
- `name: string`

**Returns**
- `tab` table with section creation support

**Behavior**
- The first created tab becomes active automatically.
- Selecting a tab updates both the sidebar button state and page visibility.

## 6. Tab API

### `tab:CreateSection(sectionTitle, description)`

Creates a grouped content container inside the tab page.

```lua
local section = tab:CreateSection("Overview", "Core controls and quick actions.")
```

**Parameters**
- `sectionTitle: string`
- `description: string?`

**Returns**
- `section` table exposing control constructors

**Behavior**
- The section frame auto-sizes vertically.
- The tab page uses a scrolling container with automatic vertical canvas sizing.

## 7. Section API

Each section exposes a set of control constructors.

### `section:CreateButton(data)`

Creates a clickable button row.

```lua
section:CreateButton({
    Text = "Execute",
    Callback = function()
        print("Executed")
    end,
})
```

**Supported fields**

| Field | Type | Default |
|---|---|---|
| `Text` | `string` | `"Button"` |
| `Callback` | `function` | `nil` |

**Behavior**
- Hover state changes row color and arrow color.
- Click executes the callback through a protected call.

---

### `section:CreateLabel(data)`

Creates a static single-line label row.

```lua
local label = section:CreateLabel({
    Text = "Ready",
})

label:SetText("Updated")
```

**Supported fields**

| Field | Type | Default |
|---|---|---|
| `Text` | `string` | `"Label"` |

**Returns**
- API table with `SetText(text)`

**Notes**
- Intended for lightweight status output.

---

### `section:CreateParagraph(data)`

Creates a wrapped multi-line text block.

```lua
section:CreateParagraph({
    Text = "This section contains descriptive content.",
    Height = 82,
})
```

**Supported fields**

| Field | Type | Default |
|---|---|---|
| `Text` | `string` | `"Paragraph"` |
| `Height` | `number` | `78` |

**Returns**
- Row frame instance

**Notes**
- Height is fixed and should be sized to the amount of content you expect.

---

### `section:CreateTextbox(data)`

Creates a text input row with live change callbacks and focus-state animation.

```lua
local searchBox = section:CreateTextbox({
    Text = "Search",
    Placeholder = "Type to filter",
    Callback = function(value)
        print(value)
    end,
})

searchBox:Set("Updated")
print(searchBox:Get())
```

**Supported fields**

| Field | Type | Default |
|---|---|---|
| `Text` | `string` | `"Textbox"` |
| `Placeholder` | `string` | `"Enter text"` |
| `Default` | `string` | `""` |
| `Callback` | `function` | `nil` |
| `Finished` | `function` | `nil` |
| `Live` | `boolean` | `true` |
| `ClearOnFocus` | `boolean` | `false` |
| `MaxLength` | `number` | `nil` |
| `Numeric` | `boolean` | `false` |
| `Height` | `number` | `72` |

**Returns**
- API table with:
  - `Set(value)`
  - `Get()`
  - `SetPlaceholder(text)`
  - `Focus()`

**Behavior**
- `Callback` is invoked during initial rendering and on each text change when `Live` is enabled.
- If `Live` is set to `false`, `Callback` is invoked when focus is lost.
- `Finished` is invoked on focus loss and receives the current text and the `enterPressed` state.
- `Numeric = true` filters the content to digits, `.` and `-`.
- `MaxLength` truncates the stored value before callbacks are fired.

---

### `section:CreateToggle(data)`

Creates a two-state switch control.

```lua
local toggle = section:CreateToggle({
    Text = "Enabled",
    Default = true,
    Callback = function(state)
        print(state)
    end,
})
```

**Supported fields**

| Field | Type | Default |
|---|---|---|
| `Text` | `string` | `"Toggle"` |
| `Default` | `boolean` | `false` |
| `Callback` | `function` | `nil` |

**Returns**
- API table with:
  - `Set(value)`
  - `Get()`

**Behavior**
- The callback is invoked whenever the state changes.
- The default state is rendered immediately during creation.
- Because the initial state is applied through the same setter path, the callback is also invoked once during initialization.

---

### `section:CreateSlider(data)`

Creates a numeric slider with draggable input.

```lua
local slider = section:CreateSlider({
    Text = "Speed",
    Min = 0,
    Max = 100,
    Default = 45,
    Increment = 1,
    Callback = function(value)
        print(value)
    end,
})
```

**Supported fields**

| Field | Type | Default |
|---|---|---|
| `Text` | `string` | `"Slider"` |
| `Min` | `number` | `0` |
| `Max` | `number` | `100` |
| `Default` | `number` | `Min` |
| `Increment` | `number` | `1` |
| `Callback` | `function` | `nil` |

**Returns**
- API table with:
  - `Set(value)`
  - `Get()`

**Behavior**
- Values are clamped between `Min` and `Max`.
- Values are rounded to the configured increment.
- Integer values are displayed without decimals.
- Non-integer values are displayed with two decimal places.
- The callback is invoked during initial rendering and on subsequent updates.

---

### `section:CreateDropdown(data)`

Creates a single-selection dropdown.

```lua
local dropdown = section:CreateDropdown({
    Text = "Mode",
    Options = {"Balanced", "Aggressive", "Silent"},
    Default = "Balanced",
    Callback = function(value)
        print(value)
    end,
})
```

**Supported fields**

| Field | Type | Default |
|---|---|---|
| `Text` | `string` | `"Dropdown"` |
| `Options` | `table` | `{}` |
| `Default` | `any` | first option or `"None"` |
| `Callback` | `function` | `nil` |

**Returns**
- API table with:
  - `Set(value)`
  - `Get()`
  - `SetOptions(newOptions)`

**Behavior**
- Clicking the header expands or collapses the option list.
- Selecting an option sets the current value and closes the list.
- `SetOptions(newOptions)` rebuilds the available choices.
- If the current value is not present in the new list, the selection falls back to the first option or `"None"`.

**Implementation detail**
- `Set(value)` does not validate that the supplied value exists in `Options`. It writes the value directly to the selected display and callback path.

## 8. Callback Handling

All callbacks are executed through an internal protected wrapper.

### Result

- Runtime callback errors do not hard-stop the UI.
- Errors are reported through:

```lua
warn("[ShoshanaUI] Callback error:", err)
```

This is relevant when wiring game logic into controls, especially when rapid iteration may leave unfinished handlers in place.

## 9. Animation and Interaction Model

The library uses TweenService to animate:

- initial window scale-in
- shadow fade-in
- tab activation state
- button hover and click response
- toggle state changes
- slider fill and knob movement
- dropdown expansion and collapse
- notification entry and exit

### Dragging

Dragging is implemented manually through `UserInputService` and does not rely on deprecated GUI drag properties.

Supported drag handles:
- top bar
- sidebar

## 10. Lifecycle Notes

### Visibility toggle

The configured keybind toggles visibility by changing `ScreenGui.Enabled`.

### Minimize

Minimize collapses the body area and leaves the top bar visible.

### Close

The close button destroys the generated `ScreenGui`.

This is a full teardown of the current instance. It is not a hide action. Reopening requires the interface to be created again by script.

## 11. Practical Usage Pattern

A common project structure is:

1. Create a single UI instance.
2. Add high-level tabs that match functional domains.
3. Group controls into sections within each tab.
4. Store returned APIs for controls that require later updates.
5. Use notifications for confirmation and state feedback.

### Example

```lua
local ui = ShoshanaUI.new({
    Title = "Shoshana",
    Subtitle = "Unified Tooling",
})

local systems = ui:CreateTab("Systems")
local controlSection = systems:CreateSection("Runtime", "Live values and actions.")

local systemToggle = controlSection:CreateToggle({
    Text = "System Enabled",
    Default = true,
})

local speedSlider = controlSection:CreateSlider({
    Text = "Speed",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 5,
})

controlSection:CreateButton({
    Text = "Reset",
    Callback = function()
        systemToggle:Set(false)
        speedSlider:Set(50)
        ui:Notify({
            Title = "Shoshana",
            Text = "Values restored.",
            Duration = 3,
        })
    end,
})
```

## 12. Current Limitations

The current public version intentionally keeps the API focused. The following are not exposed as configuration points:

- runtime theme editing
- custom fonts
- icon injection
- multi-select dropdowns
- text input fields
- color pickers
- nested sections
- dynamic layout presets

These can be added later without changing the existing composition pattern.

## 13. Publishing Notes

If you intend to distribute the library through GitHub and load it remotely:

- keep the module as a single self-contained file
- preserve the `return ShoshanaUI` line at the end of the module
- document the target execution context as client-side
- version changes clearly when you modify public method behavior

Recommended repository structure:

```text
README.md
DOCUMENTATION.md
ShoshanaUI.lua
examples/
    basic.client.lua
```

## 14. Minimal Remote Loader Example

```lua
local ShoshanaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/EmiDaDuck/Shoshana-UI/refs/heads/main/ShoshanaUI.lua"))()

local ui = ShoshanaUI.new({
    Title = "Shoshana",
    Subtitle = "Remote Build",
})
```

## 15. Summary

ShoshanaUI provides a fixed visual system and a small, deliberate API surface. Its value lies in repeatability: once adopted as a baseline, separate scripts can share a consistent interface architecture without rebuilding common controls for each project.
