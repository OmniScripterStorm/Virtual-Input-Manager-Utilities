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
    
    -- 1. Basic checks: Is it visible and has size?
    if not button.Visible or button.AbsoluteSize.X <= 0 or button.AbsoluteSize.Y <= 0 then 
        return false 
    end
    
    local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
    if not screenGui or not screenGui.Enabled then return false end

    -- 2. Check for Tweening (Movement)
    local pos1 = button.AbsolutePosition
    task.wait(0.05)
    local pos2 = button.AbsolutePosition
    if (pos1 - pos2).Magnitude > 0.1 then 
        return false -- Still moving
    end

    -- 3. Calculate Center
    local absPos = button.AbsolutePosition
    local absSize = button.AbsoluteSize
    local center = Vector2.new(absPos.X + (absSize.X / 2), absPos.Y + (absSize.Y / 2))

    -- 4. Deep Hierarchy Visibility & Clipping
    local current = button.Parent
    while current and current:IsA("GuiObject") do
        if not current.Visible then return false end
        if current.ClipsDescendants then
            if not isPointInBounds(center, current.AbsolutePosition, current.AbsoluteSize) then
                return false -- Button is hidden behind parent's border
            end
        end
        current = current.Parent
    end

    -- 5. ULTIMATE OCCLUSION CHECK (The "Topmost" Test)
    -- This scans the entire PlayerGui for anything covering our button
    local guisAtPoint = player.PlayerGui:GetGuiObjectsAtPosition(center.X, center.Y)
    
    local isBlocked = true
    for _, obj in ipairs(guisAtPoint) do
        -- If the object found is our button, or a child of our button (like a Label or Image)
        if obj == button or obj:IsDescendantOf(button) then
            isBlocked = false
            break -- We are at the top!
        end
        
        -- If we find something else ABOVE our button...
        -- Check if it's actually "solid" (Visible and not fully transparent)
        if obj.Visible and obj.BackgroundTransparency < 1 then
            -- This is a solid object blocking our view
            return false 
        end
    end
    
    if isBlocked then return false end

    return true
end

function VIMR.clickButton(button)
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
            return true
        end
        task.wait(0.1)
    end
    return false
end

return VIMR
