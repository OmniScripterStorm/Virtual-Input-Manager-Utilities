local VIM = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local VIMR = {}

function VIMR.clickButton(button)
    if not button then return end
    
    local absPos = button.AbsolutePosition
    local absSize = button.AbsoluteSize
    local inset = GuiService:GetGuiInset()
    
    -- Calculate center and adjust for the Roblox topbar inset
    local centerX = absPos.X + (absSize.X / 2) + inset.X
    local centerY = absPos.Y + (absSize.Y / 2) + inset.Y
    
    -- Simulate hardware events
    VIM:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1) -- Down
    task.wait(0.05)
    VIM:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1) -- Up
end

function VIMR.isReady(button)
    if not button or not button:IsA("GuiObject") then return false end
    
    -- 1. Check if the button and all its ancestors are Visible
    local current = button
    while current:IsA("GuiObject") do
        if not current.Visible then return false end
        current = current.Parent
    end
    
    -- 2. Check if the ScreenGui is enabled
    local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
    if not screenGui or not screenGui.Enabled then return false end

    -- 3. Check if it's within the screen boundaries (Viewport)
    local viewport = workspace.CurrentCamera.ViewportSize
    local absPos = button.AbsolutePosition
    if absPos.X < 0 or absPos.Y < 0 or absPos.X > viewport.X or absPos.Y > viewport.Y then
        return false
    end

    -- 4. Check if the button is covered by another UI element
    -- We get all objects at the button's center point
    local centerX = absPos.X + (button.AbsoluteSize.X / 2)
    local centerY = absPos.Y + (button.AbsoluteSize.Y / 2)
    local guisAtPoint = player.PlayerGui:GetGuiObjectsAtPosition(centerX, centerY)
    
    -- If the first object in the list isn't our button (or a child of it), 
    -- something else is blocking it.
    if #guisAtPoint > 0 then
        local topObject = guisAtPoint[1]
        if not topObject:IsDescendantOf(button) and topObject ~= button then
            -- Note: Some invisible frames might block clicks. 
            -- Check if the blocking object is actually visible/active.
            if topObject.Visible and topObject.BackgroundTransparency < 1 then
                return false 
            end
        end
    end

    return true
end

-- Function 3: Wait for a button to be ready, then click it
function VIMR.waitAndClick(pathString, timeout)
    local start = tick()
    timeout = timeout or 10
    
    print("Waiting for: " .. pathString)
    
    while tick() - start < timeout do
        -- Try to find the object
        local success, target = pcall(function()
            local parts = pathString:split(".")
            local current = player.PlayerGui
            for _, name in ipairs(parts) do
                current = current:WaitForChild(name, 1)
            end
            return current
        end)

        if success and target and VIMR.isReady(target) then
            task.wait(0.1)
            VIMR.clickButton(target)
            return true
        end
        
        task.wait(0.5)
    end
    
    warn("Timeout reached waiting for " .. pathString)
    return false
end

return VIMR
