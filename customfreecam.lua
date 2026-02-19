-- CUSTOM FREECAM SCRIPT
--// SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")

--// CONFIG
local CONFIG = {
    toggleKey = Enum.KeyCode.F,
    toggleRequiresShift = true,
    rollLeftKey = Enum.KeyCode.Z,
    rollRightKey = Enum.KeyCode.C,
    rollResetKey = Enum.KeyCode.X,
    uiToggleKey = Enum.KeyCode.U,
    cursorToggleKey = Enum.KeyCode.M,
    controlsToggleKey = Enum.KeyCode.K,
    rotate90Key = Enum.KeyCode.R,
    speedIncreaseKey = Enum.KeyCode.Equals,
    speedDecreaseKey = Enum.KeyCode.Minus,
    speedResetKey = Enum.KeyCode.Zero,
    rollSpeedIncreaseKey = Enum.KeyCode.RightBracket,
    rollSpeedDecreaseKey = Enum.KeyCode.LeftBracket,
    boostKey = Enum.KeyCode.LeftShift,
    slowKey = Enum.KeyCode.LeftControl,

    baseSpeed = 60,
    minSpeed = 1,
    maxSpeed = 500,
    speedStep = 10,
    boostMultiplier = 3,
    slowMultiplier = 0.25,
    sensitivity = 0.2,
    rollSpeed = math.rad(80),
    rollSpeedStep = math.rad(10),
    minRollSpeed = math.rad(10),
    maxRollSpeed = math.rad(180),
    pitchClamp = math.rad(85),

    posSmooth = 10,
    rotSmooth = 12,
    fovSmooth = 12,

    defaultFov = 70,
    minFov = 1,
    maxFov = 120,
    zoomStep = 3,
}

--// VARS
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera
local freecam = false

local speed = CONFIG.baseSpeed
local targetFov = CONFIG.defaultFov
local rollSpeed = CONFIG.rollSpeed

-- Rotation state
local yaw, pitch, roll = 0, 0, 0
local yawTarget, pitchTarget = 0, 0

local currentCFrame
local targetCFrame

local humanoid
local saved = {}
local pendingRestore = false
local uiHidden = false
local playerGui = player:WaitForChild("PlayerGui")
local cursorUnlocked = false
local controlsEnabled = true

--// HUMANOID
local function getHumanoid()
    local char = player.Character or player.CharacterAdded:Wait()
    humanoid = char:WaitForChild("Humanoid")
end
getHumanoid()
player.CharacterAdded:Connect(function()
    getHumanoid()
    if freecam then
        -- Update defaults for the new character while in freecam
        local h = humanoid
        if h then
            saved.Humanoid = {
                WalkSpeed = h.WalkSpeed,
                JumpPower = h.JumpPower,
                JumpHeight = h.JumpHeight,
                UseJumpPower = h.UseJumpPower,
                AutoRotate = h.AutoRotate,
            }
            h.WalkSpeed = 0
            if h.UseJumpPower then
                h.JumpPower = 0
            else
                h.JumpHeight = 0
            end
            h.AutoRotate = false
        end
    elseif pendingRestore then
        local h = humanoid
        local restore = saved.Humanoid
        if h and restore then
            h.WalkSpeed = restore.WalkSpeed
            h.AutoRotate = restore.AutoRotate
            h.UseJumpPower = restore.UseJumpPower
            if restore.UseJumpPower then
                h.JumpPower = restore.JumpPower
            else
                h.JumpHeight = restore.JumpHeight
            end
            pendingRestore = false
        end
    end
end)

--// INPUT STATE
local moveState = {
    [Enum.KeyCode.W] = false,
    [Enum.KeyCode.A] = false,
    [Enum.KeyCode.S] = false,
    [Enum.KeyCode.D] = false,
    [Enum.KeyCode.Q] = false,
    [Enum.KeyCode.E] = false,
}
local rollState = {
    [CONFIG.rollLeftKey] = false,
    [CONFIG.rollRightKey] = false,
}

local function bindInputs()
    ContextActionService:BindAction("FC_Move", function(_, state, input)
        if not controlsEnabled then
            return Enum.ContextActionResult.Sink
        end
        local key = input.KeyCode
        if moveState[key] ~= nil then
            if state == Enum.UserInputState.Begin or state == Enum.UserInputState.Change then
                moveState[key] = true
            else
                moveState[key] = false
            end
        end
        return Enum.ContextActionResult.Sink
    end, false,
        Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S,
        Enum.KeyCode.D, Enum.KeyCode.Q, Enum.KeyCode.E
    )

    ContextActionService:BindAction("FC_Roll", function(_, state, input)
        if not controlsEnabled then
            return Enum.ContextActionResult.Sink
        end
        local key = input.KeyCode
        if rollState[key] ~= nil then
            if state == Enum.UserInputState.Begin or state == Enum.UserInputState.Change then
                rollState[key] = true
            else
                rollState[key] = false
            end
        end
        return Enum.ContextActionResult.Sink
    end, false, CONFIG.rollLeftKey, CONFIG.rollRightKey)
end

local function bindExtraControls()
    ContextActionService:BindAction("FC_Extra", function(_, state, input)
        if state ~= Enum.UserInputState.Begin then
            return Enum.ContextActionResult.Sink
        end
        if not controlsEnabled then
            return Enum.ContextActionResult.Sink
        end

        -- Speed control
        if input.KeyCode == CONFIG.speedIncreaseKey then
            speed = math.min(CONFIG.maxSpeed, speed + CONFIG.speedStep)
        elseif input.KeyCode == CONFIG.speedDecreaseKey then
            speed = math.max(CONFIG.minSpeed, speed - CONFIG.speedStep)
        elseif input.KeyCode == CONFIG.speedResetKey then
            speed = CONFIG.baseSpeed
        end

        -- Roll reset
        if input.KeyCode == CONFIG.rollResetKey then
            roll = 0
        end

        -- Roll speed control
        if input.KeyCode == CONFIG.rollSpeedIncreaseKey then
            rollSpeed = math.min(CONFIG.maxRollSpeed, rollSpeed + CONFIG.rollSpeedStep)
        elseif input.KeyCode == CONFIG.rollSpeedDecreaseKey then
            rollSpeed = math.max(CONFIG.minRollSpeed, rollSpeed - CONFIG.rollSpeedStep)
        end

        return Enum.ContextActionResult.Sink
    end, false,
        CONFIG.speedIncreaseKey,
        CONFIG.speedDecreaseKey,
        CONFIG.speedResetKey,
        CONFIG.rollResetKey,
        CONFIG.rollSpeedIncreaseKey,
        CONFIG.rollSpeedDecreaseKey
    )
end


local function unbindInputs()
    ContextActionService:UnbindAction("FC_Move")
    ContextActionService:UnbindAction("FC_Roll")
    ContextActionService:UnbindAction("FC_Extra")
    for k in pairs(moveState) do
        moveState[k] = false
    end
    for k in pairs(rollState) do
        rollState[k] = false
    end
end

local function captureCoreGuiState()
    local state = {}
    for _, guiType in ipairs(Enum.CoreGuiType:GetEnumItems()) do
        local ok, enabled = pcall(function()
            return StarterGui:GetCoreGuiEnabled(guiType)
        end)
        if ok then
            state[guiType] = enabled
        end
    end
    return state
end

local function applyCoreGuiState(state, enabledOverride)
    for _, guiType in ipairs(Enum.CoreGuiType:GetEnumItems()) do
        local target
        if enabledOverride ~= nil then
            target = enabledOverride
        else
            target = state and state[guiType]
        end
        if target ~= nil then
            pcall(function()
                StarterGui:SetCoreGuiEnabled(guiType, target)
            end)
        end
    end
end

local function capturePlayerGuiState()
    local state = {}
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("ScreenGui") then
            state[gui] = gui.Enabled
        end
    end
    return state
end

local function applyPlayerGuiState(state, enabledOverride)
    for gui, enabled in pairs(state or {}) do
        if gui and gui.Parent and gui:IsA("ScreenGui") then
            if enabledOverride ~= nil then
                gui.Enabled = enabledOverride
            else
                gui.Enabled = enabled
            end
        end
    end
    if enabledOverride ~= nil then
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("ScreenGui") then
                gui.Enabled = enabledOverride
            end
        end
    end
end

local function setControlsEnabled(value)
    controlsEnabled = value
    if not controlsEnabled then
        for k in pairs(moveState) do
            moveState[k] = false
        end
        for k in pairs(rollState) do
            rollState[k] = false
        end
    end
end

local function setCursorUnlocked(value)
    cursorUnlocked = value
    if not freecam then return end
    if cursorUnlocked then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end
end

local function setUiHidden(value)
    if not freecam then return end
    uiHidden = value
    task.defer(function()
        if uiHidden then
            applyCoreGuiState(nil, false)
            applyPlayerGuiState(nil, false)
        else
            applyCoreGuiState(saved.CoreGui, nil)
            applyPlayerGuiState(saved.PlayerGui, nil)
        end
    end)
end

local function toggleFreecam()
    freecam = not freecam

    if freecam then
        saved = {
            Camera = {
                CFrame = cam.CFrame,
                Type = cam.CameraType,
                Fov = cam.FieldOfView,
                Subject = cam.CameraSubject,
            },
            Humanoid = humanoid and {
                WalkSpeed = humanoid.WalkSpeed,
                JumpPower = humanoid.JumpPower,
                JumpHeight = humanoid.JumpHeight,
                UseJumpPower = humanoid.UseJumpPower,
                AutoRotate = humanoid.AutoRotate,
            } or nil,
            Mouse = {
                Behavior = UserInputService.MouseBehavior,
                Icon = UserInputService.MouseIconEnabled,
            },
            CoreGui = captureCoreGuiState(),
            PlayerGui = capturePlayerGuiState(),
        }

        local x, y = cam.CFrame:ToOrientation()
        pitch, yaw, roll = x, y, 0
        pitchTarget, yawTarget = pitch, yaw

        if humanoid then
            humanoid.WalkSpeed = 0
            if humanoid.UseJumpPower then
                humanoid.JumpPower = 0
            else
                humanoid.JumpHeight = 0
            end
            humanoid.AutoRotate = false
        end

        cam.CameraType = Enum.CameraType.Scriptable
        cam.FieldOfView = CONFIG.defaultFov
        targetFov = CONFIG.defaultFov

        currentCFrame = cam.CFrame
        targetCFrame = cam.CFrame

        setCursorUnlocked(false)
        setControlsEnabled(true)
        bindExtraControls()
        bindInputs()
    else
        unbindInputs()

        if saved.Camera then
            cam.CameraType = saved.Camera.Type
            cam.CFrame = saved.Camera.CFrame
            cam.FieldOfView = saved.Camera.Fov
            cam.CameraSubject = saved.Camera.Subject
        end

        if humanoid and saved.Humanoid then
            humanoid.WalkSpeed = saved.Humanoid.WalkSpeed
            humanoid.AutoRotate = saved.Humanoid.AutoRotate
            humanoid.UseJumpPower = saved.Humanoid.UseJumpPower
            if saved.Humanoid.UseJumpPower then
                humanoid.JumpPower = saved.Humanoid.JumpPower
            else
                humanoid.JumpHeight = saved.Humanoid.JumpHeight
            end
        elseif saved.Humanoid and not humanoid then
            pendingRestore = true
        end

        task.defer(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true

            task.wait()
            UserInputService.MouseBehavior = (saved.Mouse and saved.Mouse.Behavior) or Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = not (saved.Mouse and saved.Mouse.Icon == false)
        end)

        if uiHidden then
            uiHidden = false
            task.defer(function()
                applyCoreGuiState(saved.CoreGui, nil)
                applyPlayerGuiState(saved.PlayerGui, nil)
            end)
        end
        cursorUnlocked = false
        controlsEnabled = true
    end
end

local function rotatePortrait90()
    roll += math.rad(90)
end

local uiRefs = {}
local scriptKilled = false
local connections = {}

local function setSpeedValue(v)
    speed = math.clamp(v, CONFIG.minSpeed, CONFIG.maxSpeed)
end

local function setRollSpeedDeg(v)
    local minDeg = math.deg(CONFIG.minRollSpeed)
    local maxDeg = math.deg(CONFIG.maxRollSpeed)
    rollSpeed = math.rad(math.clamp(v, minDeg, maxDeg))
end

local function setFovValue(v)
    targetFov = math.clamp(v, CONFIG.minFov, CONFIG.maxFov)
end

local function updateSliderVisual(row, rawValue)
    if not row then return end
    local t = 0
    if row.max > row.min then
        t = math.clamp((rawValue - row.min) / (row.max - row.min), 0, 1)
    end
    row.fill.Size = UDim2.new(t, 0, 1, 0)
    row.knob.Position = UDim2.new(t, -6, 0.5, -6)
    if not row.box:IsFocused() then
        row.box.Text = row.format(rawValue)
    end
end

local function refreshUiText()
    if not uiRefs.status then return end
    uiRefs.status.Text = string.format(
        "FREECAM: %s | CURSOR: %s | UI: %s | CTRL: %s",
        freecam and "ON" or "OFF",
        cursorUnlocked and "UNLOCK" or "LOCK",
        uiHidden and "HIDDEN" or "VISIBLE",
        controlsEnabled and "ON" or "OFF"
    )
    uiRefs.stats.Text = string.format(
        "Speed: %d | RollSpeed: %d deg/s | FOV: %.1f | Roll: %.1f deg",
        math.floor(speed + 0.5),
        math.floor(math.deg(rollSpeed) + 0.5),
        cam.FieldOfView,
        math.deg(roll)
    )
    uiRefs.freecamBtn.Text = freecam and "Disable Freecam" or "Enable Freecam"
    uiRefs.cursorBtn.Text = cursorUnlocked and "Lock Cursor" or "Unlock Cursor"
    uiRefs.uiBtn.Text = uiHidden and "Show UI" or "Hide UI"
    if uiRefs.controlsBtn then
        uiRefs.controlsBtn.Text = controlsEnabled and "Controls Lock" or "Controls Unlock"
    end
    if uiRefs.speedRow then
        updateSliderVisual(uiRefs.speedRow, speed)
    end
    if uiRefs.rollSpeedRow then
        updateSliderVisual(uiRefs.rollSpeedRow, math.deg(rollSpeed))
    end
    if uiRefs.fovRow then
        updateSliderVisual(uiRefs.fovRow, targetFov)
    end
end

local function createControlUI()
    local old = playerGui:FindFirstChild("FreecamControlUI")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "FreecamControlUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(470, 452)
    panel.Position = UDim2.new(1, -490, 0, 18)
    panel.BackgroundColor3 = Color3.fromRGB(22, 24, 28)
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Draggable = false
    panel.Parent = gui

    local headerDragZone = Instance.new("Frame")
    headerDragZone.Name = "HeaderDragZone"
    headerDragZone.Size = UDim2.new(1, -130, 0, 32)
    headerDragZone.Position = UDim2.fromOffset(0, 0)
    headerDragZone.BackgroundTransparency = 1
    headerDragZone.Active = true
    headerDragZone.Draggable = false
    headerDragZone.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -130, 0, 26)
    title.Position = UDim2.fromOffset(8, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(230, 230, 230)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Freecam Control Panel"
    title.Parent = panel

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.fromOffset(52, 22)
    minimizeBtn.Position = UDim2.new(1, -114, 0, 6)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(56, 64, 76)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 12
    minimizeBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
    minimizeBtn.Text = "Min"
    minimizeBtn.Parent = panel

    local exitBtn = Instance.new("TextButton")
    exitBtn.Size = UDim2.fromOffset(52, 22)
    exitBtn.Position = UDim2.new(1, -56, 0, 6)
    exitBtn.BackgroundColor3 = Color3.fromRGB(140, 52, 52)
    exitBtn.BorderSizePixel = 0
    exitBtn.Font = Enum.Font.GothamBold
    exitBtn.TextSize = 12
    exitBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
    exitBtn.Text = "Exit"
    exitBtn.Parent = panel

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -12, 1, -38)
    content.Position = UDim2.fromOffset(6, 34)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.fromOffset(0, 430)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollBarThickness = 8
    content.ScrollBarImageColor3 = Color3.fromRGB(120, 130, 145)
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.Parent = panel

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -12, 0, 20)
    status.Position = UDim2.fromOffset(6, 2)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Code
    status.TextSize = 12
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = content

    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, -12, 0, 20)
    stats.Position = UDim2.fromOffset(6, 22)
    stats.BackgroundTransparency = 1
    stats.Font = Enum.Font.Code
    stats.TextSize = 12
    stats.TextColor3 = Color3.fromRGB(200, 200, 200)
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.Parent = content

    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, -12, 0, 216)
    grid.Position = UDim2.fromOffset(6, 50)
    grid.BackgroundTransparency = 1
    grid.Parent = content

    local layout = Instance.new("UIGridLayout")
    layout.CellPadding = UDim2.fromOffset(6, 6)
    layout.CellSize = UDim2.fromOffset(145, 30)
    layout.FillDirectionMaxCells = 3
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = grid

    local function makeButton(text, callback)
        local b = Instance.new("TextButton")
        b.AutoButtonColor = true
        b.BackgroundColor3 = Color3.fromRGB(40, 46, 56)
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 12
        b.TextColor3 = Color3.fromRGB(235, 235, 235)
        b.Text = text
        b.Parent = grid
        table.insert(connections, b.MouseButton1Click:Connect(function()
            if scriptKilled then return end
            callback()
            refreshUiText()
        end))
        return b
    end

    local freecamBtn = makeButton("Enable Freecam", toggleFreecam)
    local cursorBtn = makeButton("Unlock Cursor", function()
        if freecam then setCursorUnlocked(not cursorUnlocked) end
    end)
    local uiBtn = makeButton("Hide UI", function()
        if freecam then setUiHidden(not uiHidden) end
    end)
    local controlsBtn = makeButton("Controls Lock", function()
        if freecam then setControlsEnabled(not controlsEnabled) end
    end)
    makeButton("Portrait +90", function()
        if freecam then rotatePortrait90() end
    end)
    makeButton("Roll Reset", function()
        if freecam then roll = 0 end
    end)
    makeButton("FOV Reset", function()
        if freecam then setFovValue(CONFIG.defaultFov) end
    end)
    makeButton("FOV +", function()
        if freecam then setFovValue(targetFov + CONFIG.zoomStep) end
    end)
    makeButton("FOV -", function()
        if freecam then setFovValue(targetFov - CONFIG.zoomStep) end
    end)
    makeButton("Speed +", function()
        if freecam then setSpeedValue(speed + CONFIG.speedStep) end
    end)
    makeButton("Speed -", function()
        if freecam then setSpeedValue(speed - CONFIG.speedStep) end
    end)
    makeButton("Speed Reset", function()
        if freecam then setSpeedValue(CONFIG.baseSpeed) end
    end)
    makeButton("RollSpeed +", function()
        if freecam then setRollSpeedDeg(math.deg(rollSpeed) + math.deg(CONFIG.rollSpeedStep)) end
    end)
    makeButton("RollSpeed -", function()
        if freecam then setRollSpeedDeg(math.deg(rollSpeed) - math.deg(CONFIG.rollSpeedStep)) end
    end)
    makeButton("RollSpeed Reset", function()
        if freecam then rollSpeed = CONFIG.rollSpeed end
    end)

    local sliderHolder = Instance.new("Frame")
    sliderHolder.Size = UDim2.new(1, -12, 0, 122)
    sliderHolder.Position = UDim2.fromOffset(6, 274)
    sliderHolder.BackgroundTransparency = 1
    sliderHolder.Parent = content

    local activeSliderRow = nil

    local function createSliderRow(parent, y, labelText, minVal, maxVal, getValue, setValue, formatValue)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36)
        row.Position = UDim2.fromOffset(0, y)
        row.BackgroundTransparency = 1
        row.Parent = parent

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromOffset(90, 20)
        label.Position = UDim2.fromOffset(0, 8)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Code
        label.TextSize = 12
        label.TextColor3 = Color3.fromRGB(210, 210, 210)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = labelText
        label.Parent = row

        local box = Instance.new("TextBox")
        box.Size = UDim2.fromOffset(62, 24)
        box.Position = UDim2.new(1, -62, 0, 6)
        box.BackgroundColor3 = Color3.fromRGB(40, 46, 56)
        box.BorderSizePixel = 0
        box.Font = Enum.Font.Code
        box.TextSize = 12
        box.TextColor3 = Color3.fromRGB(235, 235, 235)
        box.ClearTextOnFocus = false
        box.Text = formatValue(getValue())
        box.Parent = row

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -164, 0, 10)
        bar.Position = UDim2.fromOffset(96, 13)
        bar.BackgroundColor3 = Color3.fromRGB(33, 37, 45)
        bar.BorderSizePixel = 0
        bar.Parent = row

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(74, 139, 255)
        fill.BorderSizePixel = 0
        fill.Parent = bar

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(12, 12)
        knob.Position = UDim2.new(0, -6, 0.5, -6)
        knob.BackgroundColor3 = Color3.fromRGB(225, 230, 235)
        knob.BorderSizePixel = 0
        knob.Parent = bar

        local function setFromX(xPos)
            local left = bar.AbsolutePosition.X
            local width = bar.AbsoluteSize.X
            if width <= 0 then return end
            local t = math.clamp((xPos - left) / width, 0, 1)
            local raw = minVal + (maxVal - minVal) * t
            setValue(raw)
            refreshUiText()
        end

        table.insert(connections, bar.InputBegan:Connect(function(input)
            if scriptKilled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                activeSliderRow = {
                    setFromX = setFromX,
                }
                setFromX(input.Position.X)
            end
        end))

        table.insert(connections, box.FocusLost:Connect(function(enterPressed)
            if scriptKilled then return end
            if not enterPressed then
                refreshUiText()
                return
            end
            local n = tonumber(box.Text)
            if n then
                setValue(n)
            end
            refreshUiText()
        end))

        return {
            min = minVal,
            max = maxVal,
            box = box,
            fill = fill,
            knob = knob,
            format = formatValue,
        }
    end

    local speedRow = createSliderRow(
        sliderHolder,
        0,
        "Speed",
        CONFIG.minSpeed,
        CONFIG.maxSpeed,
        function() return speed end,
        setSpeedValue,
        function(v) return string.format("%.0f", v) end
    )

    local rollSpeedRow = createSliderRow(
        sliderHolder,
        40,
        "RollSpeed",
        math.deg(CONFIG.minRollSpeed),
        math.deg(CONFIG.maxRollSpeed),
        function() return math.deg(rollSpeed) end,
        setRollSpeedDeg,
        function(v) return string.format("%.0f", v) end
    )

    local fovRow = createSliderRow(
        sliderHolder,
        80,
        "FOV",
        CONFIG.minFov,
        CONFIG.maxFov,
        function() return targetFov end,
        setFovValue,
        function(v) return string.format("%.1f", v) end
    )

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if scriptKilled then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement and activeSliderRow then
            activeSliderRow.setFromX(input.Position.X)
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if scriptKilled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            activeSliderRow = nil
        end
    end))

    local help = Instance.new("TextLabel")
    help.Size = UDim2.new(1, -12, 0, 32)
    help.Position = UDim2.fromOffset(6, 424)
    help.BackgroundTransparency = 1
    help.Font = Enum.Font.Code
    help.TextSize = 11
    help.TextColor3 = Color3.fromRGB(160, 170, 180)
    help.TextXAlignment = Enum.TextXAlignment.Left
    help.TextYAlignment = Enum.TextYAlignment.Top
    help.Text = "Keys: Shift+F Toggle, WASD/QE Move, Z/C Roll, X Roll Reset, R Portrait, U Hide UI, M Cursor, K Control Lock"
    help.Parent = content

    local function relayoutContent()
        local gridBottom = grid.Position.Y.Offset + layout.AbsoluteContentSize.Y
        sliderHolder.Position = UDim2.fromOffset(6, gridBottom + 12)
        help.Position = UDim2.fromOffset(6, sliderHolder.Position.Y.Offset + sliderHolder.Size.Y.Offset + 12)
        content.CanvasSize = UDim2.fromOffset(0, help.Position.Y.Offset + help.Size.Y.Offset + 12)
    end
    table.insert(connections, layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(relayoutContent))
    relayoutContent()

    local minimized = false
    local normalSize = panel.Size
    local dragging = false
    local dragStart
    local panelStart

    table.insert(connections, headerDragZone.InputBegan:Connect(function(input)
        if scriptKilled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            panelStart = panel.Position
        end
    end))

    table.insert(connections, headerDragZone.InputEnded:Connect(function(input)
        if scriptKilled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if scriptKilled then return end
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(
                panelStart.X.Scale,
                panelStart.X.Offset + delta.X,
                panelStart.Y.Scale,
                panelStart.Y.Offset + delta.Y
            )
        end
    end))

    table.insert(connections, minimizeBtn.MouseButton1Click:Connect(function()
        if scriptKilled then return end
        minimized = not minimized
        if minimized then
            content.Visible = false
            panel.Size = UDim2.fromOffset(normalSize.X.Offset, 34)
            minimizeBtn.Text = "Max"
        else
            content.Visible = true
            panel.Size = normalSize
            minimizeBtn.Text = "Min"
        end
    end))

    table.insert(connections, exitBtn.MouseButton1Click:Connect(function()
        if scriptKilled then return end
        scriptKilled = true
        if freecam then
            toggleFreecam()
        end
        for _, c in ipairs(connections) do
            if c and c.Disconnect then
                c:Disconnect()
            end
        end
        connections = {}
        gui:Destroy()
        print("Freecam script killed via UI")
    end))

    uiRefs = {
        status = status,
        stats = stats,
        freecamBtn = freecamBtn,
        cursorBtn = cursorBtn,
        uiBtn = uiBtn,
        controlsBtn = controlsBtn,
        speedRow = speedRow,
        rollSpeedRow = rollSpeedRow,
        fovRow = fovRow,
    }
    refreshUiText()
end

createControlUI()

--// TOGGLE + SPEED + ROLL RESET
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
    if scriptKilled then return end
    if gp then return end

    if input.KeyCode == CONFIG.toggleKey then
        if CONFIG.toggleRequiresShift and not (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
            return
        end
        toggleFreecam()
        refreshUiText()
        return
    end

    if not freecam then return end

    if input.KeyCode == CONFIG.rotate90Key then
        if not controlsEnabled then return end
        rotatePortrait90()
        refreshUiText()
        return
    end

    if input.KeyCode == CONFIG.cursorToggleKey then
        setCursorUnlocked(not cursorUnlocked)
        refreshUiText()
        return
    end

    if input.KeyCode == CONFIG.uiToggleKey then
        setUiHidden(not uiHidden)
        refreshUiText()
        return
    end

    if input.KeyCode == CONFIG.controlsToggleKey then
        setControlsEnabled(not controlsEnabled)
        refreshUiText()
        return
    end
end))

--// ZOOM
table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if scriptKilled then return end
    if freecam and controlsEnabled and not cursorUnlocked and input.UserInputType == Enum.UserInputType.MouseWheel then
        targetFov = math.clamp(
            targetFov - input.Position.Z * CONFIG.zoomStep,
            CONFIG.minFov, CONFIG.maxFov
        )
        refreshUiText()
    end
end))

table.insert(connections, UserInputService.WindowFocusReleased:Connect(function()
    if scriptKilled then return end
    if not freecam then return end
    for k in pairs(moveState) do
        moveState[k] = false
    end
    for k in pairs(rollState) do
        rollState[k] = false
    end
end))

local function smooth(k, dt)
    return 1 - math.exp(-k * dt)
end

table.insert(connections, RunService.RenderStepped:Connect(function(dt)
    if scriptKilled then return end
    if not freecam then return end
    if dt > 0.05 then dt = 0.05 end

    -- Mouse look
    if controlsEnabled then
        local delta = UserInputService:GetMouseDelta()
        yawTarget   -= delta.X * CONFIG.sensitivity * 0.01
        pitchTarget -= delta.Y * CONFIG.sensitivity * 0.01
        pitchTarget = math.clamp(pitchTarget, -CONFIG.pitchClamp, CONFIG.pitchClamp)
    end

    local rotAlpha = smooth(CONFIG.rotSmooth, dt)
    yaw += (yawTarget - yaw) * rotAlpha
    pitch += (pitchTarget - pitch) * rotAlpha

    -- Roll (MANUAL, NO AUTO RETURN)
    local rollDir = controlsEnabled and ((rollState[CONFIG.rollRightKey] and 1 or 0) - (rollState[CONFIG.rollLeftKey] and 1 or 0)) or 0
    roll += rollDir * rollSpeed * dt
    --roll = math.clamp(roll, math.rad(-45), math.rad(45))

    local rot =
        CFrame.Angles(0,yaw,0) *
        CFrame.Angles(pitch,0,0) *
        CFrame.Angles(0,0,roll)

    local inputVec = Vector3.new(
        (moveState[Enum.KeyCode.D] and 1 or 0) - (moveState[Enum.KeyCode.A] and 1 or 0),
        (moveState[Enum.KeyCode.E] and 1 or 0) - (moveState[Enum.KeyCode.Q] and 1 or 0),
        (moveState[Enum.KeyCode.S] and 1 or 0) - (moveState[Enum.KeyCode.W] and 1 or 0)
    )

    local move = Vector3.zero
    if controlsEnabled and inputVec.Magnitude > 0 then
        local speedNow = speed
        if UserInputService:IsKeyDown(CONFIG.boostKey) then
            speedNow *= CONFIG.boostMultiplier
        elseif UserInputService:IsKeyDown(CONFIG.slowKey) then
            speedNow *= CONFIG.slowMultiplier
        end
        move = rot:VectorToWorldSpace(inputVec.Unit) * speedNow * dt
    end

    targetCFrame = CFrame.new(targetCFrame.Position + move) * rot
    currentCFrame = currentCFrame:Lerp(targetCFrame, smooth(CONFIG.posSmooth, dt))
    cam.CFrame = currentCFrame

    cam.FieldOfView += (targetFov - cam.FieldOfView) * smooth(CONFIG.fovSmooth, dt)
    refreshUiText()
end))

print("Hi!")
