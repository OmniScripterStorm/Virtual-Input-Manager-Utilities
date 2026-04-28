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

local function isButtonActuallyReady(button)
    if not button or not button.Visible then return false end
    
    -- 1. Check if it's currently tweening (Position is changing)
    local pos1 = button.AbsolutePosition
    task.wait(0.05)
    local pos2 = button.AbsolutePosition
    if (pos1 - pos2).Magnitude > 0.1 then 
        return false -- Still moving!
    end

    -- 2. Check Clipping: Is the button inside its Parent's view?
    local parentFrame = button.Parent -- This is the ScrollingFrame
    local bPos, bSize = button.AbsolutePosition, button.AbsoluteSize
    local pPos, pSize = parentFrame.AbsolutePosition, parentFrame.AbsoluteSize

    -- Is the center of the button outside the parent frame's box?
    local centerX = bPos.X + (bSize.X / 2)
    local centerY = bPos.Y + (bSize.Y / 2)

    if centerX < pPos.X or centerX > (pPos.X + pSize.X) or
       centerY < pPos.Y or centerY > (pPos.Y + pSize.Y) then
        return false -- It's hidden/clipped outside the frame
    end

    -- 3. Check Transparency (In case it tweens from Transparent to Opaque)
    -- Some games use CanvasGroups, check GroupTransparency if applicable
    if button:IsA("TextButton") or button:IsA("ImageButton") then
        if button.BackgroundTransparency == 1 and (button.TextTransparency or 1) == 1 then
            return false
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
