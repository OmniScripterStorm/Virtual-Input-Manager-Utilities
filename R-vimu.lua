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

--## OBSERVER FUNCTIONS

function VIMR.isReady(button)
    if not button or not button:IsA("GuiObject") then return false end
    
    if not button.Visible or button.AbsoluteSize.X <= 0 or button.AbsoluteSize.Y <= 0 then 
        return false 
    end
    
    local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
    if not screenGui or not screenGui.Enabled then return false end

    local pos1 = button.AbsolutePosition
    task.wait(0.05)
    local pos2 = button.AbsolutePosition
    if (pos1 - pos2).Magnitude > 0.1 then 
        return false
    end

    local absPos = button.AbsolutePosition
    local absSize = button.AbsoluteSize
    local center = Vector2.new(absPos.X + (absSize.X / 2), absPos.Y + (absSize.Y / 2))

    local current = button.Parent
    while current and current:IsA("GuiObject") do
        if not current.Visible then return false end
        if current.ClipsDescendants then
            if not isPointInBounds(center, current.AbsolutePosition, current.AbsoluteSize) then
                return false
            end
        end
        current = current.Parent
    end

    local guisAtPoint = player.PlayerGui:GetGuiObjectsAtPosition(center.X, center.Y)
    
    local isBlocked = true
    for _, obj in ipairs(guisAtPoint) do
        if obj == button or obj:IsDescendantOf(button) then
            isBlocked = false
            break
        end
        
        if obj.Visible and obj.BackgroundTransparency < 1 then
            return false 
        end
    end
    
    if isBlocked then return false end

    return true
end

function VIMR.waitForText(targetObject, text, timeout)
    timeout = timeout or 10
    local start = tick()
    
    while tick() - start < timeout do
        local success, currentText = pcall(function() return targetObject.Text end)
        if success and currentText:find(text) then
            return targetObject
        end
        task.wait(0.1)
    end
    
    return nil
end

function VIMR.waitForProperty(targetObject, propertyName, value, timeout)
    timeout = timeout or 10
    local start = tick()
    
    while tick() - start < timeout do
        local success, currentVal = pcall(function() return targetObject[propertyName] end)
        if success and currentVal == value then
            return targetObject
        end
        task.wait(0.1)
    end
    
    return nil
end

--## GUI INTERACTIONS

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

function VIMR.scrollTo(target)
    local scroller = target:FindFirstAncestorOfClass("ScrollingFrame")
    if not scroller then return end

    local targetPos = target.AbsolutePosition
    local targetSize = target.AbsoluteSize
    local scrollerPos = scroller.AbsolutePosition
    local scrollerSize = scroller.AbsoluteSize

    local relativePos = targetPos - scrollerPos + scroller.CanvasPosition

    local centerX = relativePos.X - (scrollerSize.X / 2) + (targetSize.X / 2)
    local centerY = relativePos.Y - (scrollerSize.Y / 2) + (targetSize.Y / 2)

    scroller.CanvasPosition = Vector2.new(centerX, centerY)
    task.wait(0.1)
end

--## SEARCH FUNCTIONS

function VIMR.findObjectByText(text, root)
    root = root or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    for _, v in ipairs(root:GetDescendants()) do
        if (v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox")) and v.Text:find(text) then
            return v
        end
    end
    return nil
end

function VIMR.findObjectByProperty(propertyName, value, root)
    root = root or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    for _, v in ipairs(root:GetDescendants()) do
        local success, currentVal = pcall(function() return v[propertyName] end)
        if success and currentVal == value then
            return v
        end
    end
    return nil
end

function VIMR.getAllInteractables(root)
    root = root or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local interactables = {}
    
    for _, v in ipairs(root:GetDescendants()) do
        if v:IsA("GuiButton") then
            if VIMR.isReady(v) then
                table.insert(interactables, v)
            end
        end
    end
    
    return interactables
end

return VIMR
