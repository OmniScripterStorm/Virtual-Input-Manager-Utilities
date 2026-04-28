local VIM = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local VIMR = {}

-- Helper to check if a point is within a Rect
local function isPointInBounds(point, framePos, frameSize)
    return point.X >= framePos.X and point.X <= (framePos.X + frameSize.X) and
           point.Y >= framePos.Y and point.Y <= (framePos.Y + frameSize.Y)
end

function VIMR.isReady(button)
    if not button or not button:IsA("GuiObject") then return false end
    
    -- 1. Basic Visibility Check (Self and ScreenGui)
    if not button.Visible then return false end
    local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
    if not screenGui or not screenGui.Enabled then return false end

    -- 2. Check for Movement (Tweening)
    -- If AbsolutePosition changes in 0.05s, the menu is still sliding
    local pos1 = button.AbsolutePosition
    task.wait(0.05)
    local pos2 = button.AbsolutePosition
    if (pos1 - pos2).Magnitude > 0.1 then 
        return false 
    end

    -- Recalculate properties after the wait
    local absPos = button.AbsolutePosition
    local absSize = button.AbsoluteSize
    local center = Vector2.new(absPos.X + (absSize.X / 2), absPos.Y + (absSize.Y / 2))

    -- 3. Viewport Check (Is it actually on the game window?)
    local viewSize = camera.ViewportSize
    if not isPointInBounds(center, Vector2.new(0,0), viewSize) then
        return false
    end

    -- 4. Deep Clipping Check (Iterate through all parents)
    -- This handles if a frame 3 levels up has ClipsDescendants enabled
    local current = button.Parent
    while current and current:IsA("GuiObject") do
        if not current.Visible then return false end
        if current.ClipsDescendants then
            if not isPointInBounds(center, current.AbsolutePosition, current.AbsoluteSize) then
                return false -- Button center is clipped out of view
            end
        end
        current = current.Parent
    end

    -- 5. Transparency Check
    if (button:IsA("TextButton") or button:IsA("ImageButton")) then
        -- If it's fully invisible, we probably shouldn't be clicking it yet
        if button.BackgroundTransparency == 1 then
            -- If it's a text button with no visible text, or image with no visible image
            if (button:IsA("TextButton") and button.TextTransparency == 1) or 
               (button:IsA("ImageButton") and button.ImageTransparency == 1) then
                return false
            end
        end
    end

    -- 6. Occlusion Check (Is something on a higher DisplayOrder/ZIndex covering it?)
    local objectsAtPoint = player.PlayerGui:GetGuiObjectsAtPosition(center.X, center.Y)
    if #objectsAtPoint > 0 then
        local topObject = objectsAtPoint[1]
        -- If the very top object isn't our button (or a child of our button like a label)
        if topObject ~= button and not topObject:IsDescendantOf(button) then
            -- If the blocking object is actually visible/opaque, then the button is covered
            if topObject.Visible and topObject.BackgroundTransparency < 1 then
                return false
            end
        end
    end

    return true
end

function VIMR.clickButton(button)
    if not button then return end
    
    local absPos = button.AbsolutePosition
    local absSize = button.AbsoluteSize
    local inset = GuiService:GetGuiInset()
    
    local centerX = absPos.X + (absSize.X / 2) + inset.X
    local centerY = absPos.Y + (absSize.Y / 2) + inset.Y
    
    VIM:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
    task.wait(0.05)
    VIM:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
end

function VIMR.waitAndClick(pathString, timeout)
    local start = tick()
    timeout = timeout or 10
    
    print("VIMR: Searching for " .. pathString)
    
    while tick() - start < timeout do
        local target = nil
        pcall(function()
            local parts = pathString:split(".")
            local current = player.PlayerGui
            for _, name in ipairs(parts) do
                current = current:WaitForChild(name, 0.5)
            end
            target = current
        end)

        if target and VIMR.isReady(target) then
            VIMR.clickButton(target)
            print("VIMR: Successfully clicked " .. target.Name)
            return true
        end
        
        task.wait(0.1)
    end
    
    warn("VIMR: Timeout reached for " .. pathString)
    return false
end

return VIMR
