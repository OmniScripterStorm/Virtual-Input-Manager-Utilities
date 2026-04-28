# Virtual Input Manager Utilities (VIMU)

**VIMU** is a robust Lua library designed for modified Roblox clients (Script Identity Level 3 and above). It provides a hardware-level interaction layer using `VirtualInputManager`, allowing scripts to bypass standard UI restrictions and interact with buttons as a human would.

Unlike standard `firesignal` or `Click` methods, VIMU verifies that a button is **actually interactable**, ensuring it isn't hidden behind another menu or currently moving during a tween.

## Features
- **Tween Stability:** Automatically waits for UI animations to finish before clicking.
- **Occlusion Detection:** Checks if other GUI elements (even in different ScreenGuis) are blocking the button.
- **Deep Clipping:** Handles buttons nested deep within `ScrollingFrames` with `ClipsDescendants` enabled.
- **Hardware Simulation:** Uses `VirtualInputManager` to simulate raw mouse events, making it more resilient against basic detection.

## Installation
Load the library directly into your environment using `loadstring`:

```lua
local VIMR = loadstring(game:HttpGet("https://raw.githubusercontent.com/OmniScripterStorm/Virtual-Input-Manager-Utilities/refs/heads/main/R-vimu.lua"))()
```

---

## Documentation

### ## OBSERVER FUNCTIONS

#### `VIMR.isReady(button: GuiObject) -> boolean`
The core verification engine. Returns `true` only if:
1. The button and all ancestors are `Visible`.
2. The button has a physical size (`AbsoluteSize > 0`).
3. The button is not currently moving (Position is stable for >0.05s).
4. The button's center is not clipped by a parent with `ClipsDescendants`.
5. No other solid GUI element is covering the button at its screen coordinates.

#### `VIMR.waitForText(targetObject: Instance, text: string, timeout: number) -> Instance | nil`
Yields until the `targetObject.Text` contains the specified string.
- **Default Timeout:** 10 seconds.

#### `VIMR.waitForProperty(targetObject: Instance, propertyName: string, value: any, timeout: number) -> Instance | nil`
Yields until the specified property matches the target value. Useful for waiting for cooldowns or color changes.

---

### ## GUI INTERACTIONS

#### `VIMR.clickButton(button: GuiObject)`
Calculates the absolute center of the button, adjusts for the Roblox Topbar inset, and sends a hardware-level MouseButton1 Down/Up sequence.

#### `VIMR.waitAndClick(pathString: string, timeout: number) -> boolean`
The primary automation tool. It resolves a string path (e.g., `"MainGui.Frame.Button"`), waits for the object to satisfy `isReady`, and clicks it.
- **Path Root:** Always starts from `PlayerGui`.
- **Example:** `VIMR.waitAndClick("PlayerGUI.Abilities.Flame Bolt", 15)`

#### `VIMR.scrollTo(target: GuiObject)`
Automatically adjusts the `CanvasPosition` of the target's parent `ScrollingFrame` to bring the button into the center of the viewable area.

---

### ## SEARCH FUNCTIONS

#### `VIMR.findObjectByText(text: string, root: Instance) -> Instance | nil`
Scans all descendants of `root` (defaults to PlayerGui) for any `TextLabel`, `TextButton`, or `TextBox` containing the search string.

#### `VIMR.findObjectByProperty(propertyName: string, value: any, root: Instance) -> Instance | nil`
Finds an object where the specified property exactly matches the value. Excellent for finding buttons by `ImageId` or obfuscated names.

#### `VIMR.getAllInteractables(root: Instance) -> table`
Scans the root for all `GuiButtons` and returns an array containing only the buttons that currently pass the `isReady` check.

---

## Technical Considerations
- **Background Operation:** VIMU works while the Roblox window is in the background (Alt-Tabbed). 
- **Minimized State:** VIMU will **fail** if the window is minimized, as the Roblox engine pauses UI rendering and coordinate calculation.
- **Wait Times:** The library includes small `task.wait()` buffers to ensure the engine has updated the UI state before attempting interaction.

## Practical Example
```lua
local VIMR = loadstring(game:HttpGet("YOUR_LINK_HERE"))()

-- Clicking an ability that appears after a menu animation
local path = "PlayerGUI.SkillMenu.ScrollingFrame.Flame Bolt"
local success = VIMR.waitAndClick(path, 10)

if success then
    print("Ability activated!")
end
```
