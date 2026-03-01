-- CUSTOM FREECAM SCRIPT
--// SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")

--// CONFIG
local CONFIG = {
    toggleKey = Enum.KeyCode.F,
    toggleRequiresShift = true,
    rollLeftKey = Enum.KeyCode.Z,
    rollRightKey = Enum.KeyCode.C,
    rollResetKey = Enum.KeyCode.X,
    uiToggleKey = Enum.KeyCode.U,
    panelToggleKey = Enum.KeyCode.P,
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

    panelDefaultWidth = 500,
    panelDefaultHeight = 520,
    panelMinWidth = 420,
    panelMinHeight = 340,
    panelMaxWidth = 1000,
    panelMaxHeight = 900,

    dofEnabled = false,
    dofNearIntensity = 0.35,
    dofFarIntensity = 0.35,
    dofFocusDistance = 35,
    dofInFocusRadius = 18,
    dofMinDistance = 0,
    dofMaxDistance = 500,
}

--// VARS
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera
local freecam = false

local speed = CONFIG.baseSpeed
local targetFov = CONFIG.defaultFov
local rollSpeed = CONFIG.rollSpeed
local boostMultiplier = CONFIG.boostMultiplier
local slowMultiplier = CONFIG.slowMultiplier
local sensitivity = CONFIG.sensitivity
local posSmooth = CONFIG.posSmooth
local rotSmooth = CONFIG.rotSmooth
local fovSmooth = CONFIG.fovSmooth
local zoomStep = CONFIG.zoomStep
local pitchClamp = CONFIG.pitchClamp
local dofEnabled = CONFIG.dofEnabled
local dofNearIntensity = CONFIG.dofNearIntensity
local dofFarIntensity = CONFIG.dofFarIntensity
local dofFocusDistance = CONFIG.dofFocusDistance
local dofInFocusRadius = CONFIG.dofInFocusRadius
local dofEffect

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
local panelVisible = true
local uiRefs = {}
local panelWidth = CONFIG.panelDefaultWidth
local panelHeight = CONFIG.panelDefaultHeight

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

local function setPanelVisible(value)
    panelVisible = value
    if uiRefs.panel then
        uiRefs.panel.Visible = panelVisible
        if panelVisible and uiRefs.clampPanel then
            uiRefs.clampPanel()
        end
    end
end

local applyDofSettings

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
        applyDofSettings()
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
        if dofEffect then
            dofEffect.Enabled = false
        end
    end
end

local function rotatePortrait90()
    roll += math.rad(90)
end

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

local function setSensitivityValue(v)
    sensitivity = math.clamp(v, 0.02, 1.5)
end

local function setPosSmoothValue(v)
    posSmooth = math.clamp(v, 1, 40)
end

local function setRotSmoothValue(v)
    rotSmooth = math.clamp(v, 1, 40)
end

local function setFovSmoothValue(v)
    fovSmooth = math.clamp(v, 1, 40)
end

local function setZoomStepValue(v)
    zoomStep = math.clamp(v, 0.2, 20)
end

local function setBoostMultiplierValue(v)
    boostMultiplier = math.clamp(v, 1, 8)
end

local function setSlowMultiplierValue(v)
    slowMultiplier = math.clamp(v, 0.05, 1)
end

local function setPitchClampDeg(v)
    pitchClamp = math.rad(math.clamp(v, 30, 89))
end

local function ensureDofEffect()
    if dofEffect and dofEffect.Parent then
        return dofEffect
    end
    local existing = Lighting:FindFirstChild("FreecamDOFEffect")
    if existing and existing:IsA("DepthOfFieldEffect") then
        dofEffect = existing
    else
        dofEffect = Instance.new("DepthOfFieldEffect")
        dofEffect.Name = "FreecamDOFEffect"
        dofEffect.Parent = Lighting
    end
    return dofEffect
end

applyDofSettings = function()
    local fx = ensureDofEffect()
    fx.NearIntensity = dofNearIntensity
    fx.FarIntensity = dofFarIntensity
    fx.FocusDistance = dofFocusDistance
    fx.InFocusRadius = dofInFocusRadius
    fx.Enabled = dofEnabled and freecam
end

local function setDofEnabled(v)
    dofEnabled = v
    applyDofSettings()
end

local function setDofNearIntensity(v)
    dofNearIntensity = math.clamp(v, 0, 1)
    applyDofSettings()
end

local function setDofFarIntensity(v)
    dofFarIntensity = math.clamp(v, 0, 1)
    applyDofSettings()
end

local function setDofFocusDistance(v)
    dofFocusDistance = math.clamp(v, CONFIG.dofMinDistance, CONFIG.dofMaxDistance)
    applyDofSettings()
end

local function setDofInFocusRadius(v)
    dofInFocusRadius = math.clamp(v, 0, CONFIG.dofMaxDistance)
    applyDofSettings()
end

local function resetDofSettings()
    dofEnabled = CONFIG.dofEnabled
    dofNearIntensity = CONFIG.dofNearIntensity
    dofFarIntensity = CONFIG.dofFarIntensity
    dofFocusDistance = CONFIG.dofFocusDistance
    dofInFocusRadius = CONFIG.dofInFocusRadius
    applyDofSettings()
end

local function resetAllSettings()
    setSpeedValue(CONFIG.baseSpeed)
    rollSpeed = CONFIG.rollSpeed
    setFovValue(CONFIG.defaultFov)
    setSensitivityValue(CONFIG.sensitivity)
    setPosSmoothValue(CONFIG.posSmooth)
    setRotSmoothValue(CONFIG.rotSmooth)
    setFovSmoothValue(CONFIG.fovSmooth)
    setZoomStepValue(CONFIG.zoomStep)
    setBoostMultiplierValue(CONFIG.boostMultiplier)
    setSlowMultiplierValue(CONFIG.slowMultiplier)
    setPitchClampDeg(math.deg(CONFIG.pitchClamp))
    resetDofSettings()
    roll = 0
    setControlsEnabled(true)
    if freecam then
        setCursorUnlocked(false)
        if uiHidden then
            setUiHidden(false)
        end
        cam.FieldOfView = CONFIG.defaultFov
    end
    setPanelVisible(true)
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
        "FREECAM: %s | CURSOR: %s | UI: %s | CTRL: %s | DOF: %s | PANEL: %s",
        freecam and "ON" or "OFF",
        cursorUnlocked and "UNLOCK" or "LOCK",
        uiHidden and "HIDDEN" or "VISIBLE",
        controlsEnabled and "ON" or "OFF",
        dofEnabled and "ON" or "OFF",
        panelVisible and "ON" or "OFF"
    )
    uiRefs.stats.Text = string.format(
        "Speed: %d | RollSpeed: %d deg/s | FOV: %.1f | Roll: %.1f deg | Sens: %.2f | UI: %dx%d",
        math.floor(speed + 0.5),
        math.floor(math.deg(rollSpeed) + 0.5),
        cam.FieldOfView,
        math.deg(roll),
        sensitivity,
        panelWidth,
        panelHeight
    )
    uiRefs.freecamBtn.Text = freecam and "⬛  Disable Freecam" or "⬛  Enable Freecam"
    uiRefs.cursorBtn.Text  = cursorUnlocked and "⊕  Lock Cursor"   or "⊕  Unlock Cursor"
    uiRefs.uiBtn.Text      = uiHidden and "◑  Show UI"             or "◑  Hide UI"
    if uiRefs.controlsBtn then
        uiRefs.controlsBtn.Text = controlsEnabled and "⊘  Controls Lock" or "⊘  Controls Unlock"
    end
    if uiRefs.dofToggleBtn then
        uiRefs.dofToggleBtn.Text = dofEnabled and "◉  DOF Off" or "◉  DOF On"
    end
    -- Update status pill
    if uiRefs.statusPillLabel then
        if freecam then
            uiRefs.statusPillLabel.Text = "● ON"
            uiRefs.statusPillLabel.TextColor3 = Color3.fromRGB(60, 220, 100)
            if uiRefs.statusPill then
                uiRefs.statusPill.BackgroundColor3 = Color3.fromRGB(22, 68, 38)
            end
        else
            uiRefs.statusPillLabel.Text = "● OFF"
            uiRefs.statusPillLabel.TextColor3 = Color3.fromRGB(140, 148, 165)
            if uiRefs.statusPill then
                uiRefs.statusPill.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
            end
        end
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
    if uiRefs.sensRow then
        updateSliderVisual(uiRefs.sensRow, sensitivity)
    end
    if uiRefs.posSmoothRow then
        updateSliderVisual(uiRefs.posSmoothRow, posSmooth)
    end
    if uiRefs.rotSmoothRow then
        updateSliderVisual(uiRefs.rotSmoothRow, rotSmooth)
    end
    if uiRefs.fovSmoothRow then
        updateSliderVisual(uiRefs.fovSmoothRow, fovSmooth)
    end
    if uiRefs.zoomStepRow then
        updateSliderVisual(uiRefs.zoomStepRow, zoomStep)
    end
    if uiRefs.dofNearRow then
        updateSliderVisual(uiRefs.dofNearRow, dofNearIntensity)
    end
    if uiRefs.dofFarRow then
        updateSliderVisual(uiRefs.dofFarRow, dofFarIntensity)
    end
    if uiRefs.dofFocusRow then
        updateSliderVisual(uiRefs.dofFocusRow, dofFocusDistance)
    end
    if uiRefs.dofRadiusRow then
        updateSliderVisual(uiRefs.dofRadiusRow, dofInFocusRadius)
    end
    if uiRefs.boostRow then
        updateSliderVisual(uiRefs.boostRow, boostMultiplier)
    end
    if uiRefs.slowRow then
        updateSliderVisual(uiRefs.slowRow, slowMultiplier)
    end
    if uiRefs.pitchClampRow then
        updateSliderVisual(uiRefs.pitchClampRow, math.deg(pitchClamp))
    end
end

local function createControlUI()
    local old = playerGui:FindFirstChild("FreecamControlUI")
    if old then old:Destroy() end

    -- ╔══════════════════════════════════════════╗
    -- ║         THEME & STYLE CONSTANTS          ║
    -- ╚══════════════════════════════════════════╝
    local THEME = {
        -- Background layers
        bg0        = Color3.fromRGB(10, 11, 15),   -- deepest
        bg1        = Color3.fromRGB(15, 17, 22),   -- panel
        bg2        = Color3.fromRGB(20, 23, 30),   -- section
        bg3        = Color3.fromRGB(26, 30, 40),   -- row / card
        bg4        = Color3.fromRGB(32, 37, 50),   -- input box
        -- Accents
        accent     = Color3.fromRGB(92, 168, 255), -- primary blue
        accentDim  = Color3.fromRGB(50, 100, 180),
        accentGlow = Color3.fromRGB(140, 195, 255),
        green      = Color3.fromRGB(60, 200, 120),
        red        = Color3.fromRGB(220, 75, 75),
        amber      = Color3.fromRGB(230, 160, 50),
        purple     = Color3.fromRGB(140, 100, 230),
        cyan       = Color3.fromRGB(60, 210, 210),
        -- Text
        textPrimary   = Color3.fromRGB(230, 235, 245),
        textSecondary = Color3.fromRGB(155, 168, 190),
        textMuted     = Color3.fromRGB(90, 102, 122),
        -- Borders
        border     = Color3.fromRGB(40, 48, 64),
        borderBright = Color3.fromRGB(65, 80, 110),
    }

    local gui = Instance.new("ScreenGui")
    gui.Name = "FreecamControlUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    -- ╔══════════════════════════════════════════╗
    -- ║               MAIN PANEL                 ║
    -- ╚══════════════════════════════════════════╝
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
    panel.Position = UDim2.fromOffset(18, 18)
    panel.BackgroundColor3 = THEME.bg1
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Draggable = false
    panel.Parent = gui
    panel.Visible = panelVisible

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 14)
    panelCorner.Parent = panel

    -- Outer glow border
    local panelStroke = Instance.new("UIStroke")
    panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    panelStroke.Thickness = 1.5
    panelStroke.Color = THEME.borderBright
    panelStroke.Transparency = 0.55
    panelStroke.Parent = panel

    -- Subtle vertical gradient on the panel background
    local panelGradient = Instance.new("UIGradient")
    panelGradient.Rotation = 145
    panelGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(22, 26, 36)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 17, 23)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(10, 12, 18)),
    })
    panelGradient.Parent = panel

    -- Thin accent line at the very top of the panel (decorative)
    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(0.6, 0, 0, 2)
    accentLine.AnchorPoint = Vector2.new(0.5, 0)
    accentLine.Position = UDim2.new(0.5, 0, 0, 0)
    accentLine.BackgroundColor3 = THEME.accent
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 10
    accentLine.Parent = panel
    local accentLineCorner = Instance.new("UICorner")
    accentLineCorner.CornerRadius = UDim.new(1, 0)
    accentLineCorner.Parent = accentLine
    local accentLineGrad = Instance.new("UIGradient")
    accentLineGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
        ColorSequenceKeypoint.new(0.2, THEME.accentGlow),
        ColorSequenceKeypoint.new(0.5, THEME.accentGlow),
        ColorSequenceKeypoint.new(0.8, THEME.accentGlow),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
    })
    accentLineGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.15, 0),
        NumberSequenceKeypoint.new(0.85, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    accentLineGrad.Parent = accentLine

    -- ╔══════════════════════════════════════════╗
    -- ║               HEADER BAR                 ║
    -- ╚══════════════════════════════════════════╝
    local headerBar = Instance.new("Frame")
    headerBar.Size = UDim2.new(1, 0, 0, 42)
    headerBar.Position = UDim2.fromOffset(0, 0)
    headerBar.BackgroundColor3 = THEME.bg2
    headerBar.BorderSizePixel = 0
    headerBar.ZIndex = 2
    headerBar.Parent = panel

    local headerBarCorner = Instance.new("UICorner")
    headerBarCorner.CornerRadius = UDim.new(0, 14)
    headerBarCorner.Parent = headerBar

    -- mask to make bottom of header square
    local headerBarMask = Instance.new("Frame")
    headerBarMask.Size = UDim2.new(1, 0, 0, 14)
    headerBarMask.Position = UDim2.new(0, 0, 1, -14)
    headerBarMask.BackgroundColor3 = THEME.bg2
    headerBarMask.BorderSizePixel = 0
    headerBarMask.ZIndex = 2
    headerBarMask.Parent = headerBar

    -- separator line below header
    local headerSep = Instance.new("Frame")
    headerSep.Size = UDim2.new(1, -24, 0, 1)
    headerSep.AnchorPoint = Vector2.new(0.5, 0)
    headerSep.Position = UDim2.new(0.5, 0, 0, 42)
    headerSep.BackgroundColor3 = THEME.border
    headerSep.BorderSizePixel = 0
    headerSep.ZIndex = 3
    headerSep.Parent = panel

    -- Camera icon (text-based)
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.fromOffset(28, 28)
    iconLabel.Position = UDim2.fromOffset(10, 7)
    iconLabel.BackgroundColor3 = THEME.accentDim
    iconLabel.BorderSizePixel = 0
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 14
    iconLabel.TextColor3 = THEME.accent
    iconLabel.Text = "FC"
    iconLabel.ZIndex = 4
    iconLabel.Parent = panel
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 7)
    iconCorner.Parent = iconLabel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -180, 0, 18)
    title.Position = UDim2.fromOffset(46, 7)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = THEME.textPrimary
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "FREECAM DIRECTOR"
    title.ZIndex = 4
    title.Parent = panel

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -180, 0, 13)
    subtitle.Position = UDim2.fromOffset(46, 25)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextColor3 = THEME.textMuted
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = "Advanced Camera Controller"
    subtitle.ZIndex = 4
    subtitle.Parent = panel

    -- Helper to create a header button
    local function makeHeaderBtn(text, bgColor, xOffset)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(52, 26)
        btn.Position = UDim2.new(1, xOffset, 0, 8)
        btn.BackgroundColor3 = bgColor
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = THEME.textPrimary
        btn.Text = text
        btn.ZIndex = 5
        btn.AutoButtonColor = true
        btn.Parent = panel
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 7)
        c.Parent = btn
        local s = Instance.new("UIStroke")
        s.Thickness = 1
        s.Color = bgColor
        s.Transparency = 0.5
        s.Parent = btn
        return btn
    end

    local minimizeBtn = makeHeaderBtn("MIN", THEME.bg4, -168)
    local exitBtn     = makeHeaderBtn("EXIT", Color3.fromRGB(140, 40, 40), -112)

    -- better exit button look
    exitBtn.BackgroundColor3 = Color3.fromRGB(120, 35, 35)
    local exitGrad = Instance.new("UIGradient")
    exitGrad.Rotation = 90
    exitGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(185, 55, 55)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 30, 30)),
    })
    exitGrad.Parent = exitBtn

    -- Freecam status pill (top-right, header area)
    local statusPill = Instance.new("Frame")
    statusPill.Size = UDim2.fromOffset(48, 18)
    statusPill.Position = UDim2.new(1, -62, 0, 12)  -- will be repositioned
    statusPill.BackgroundColor3 = Color3.fromRGB(30, 70, 35)
    statusPill.BorderSizePixel = 0
    statusPill.ZIndex = 6
    -- reposition next to exit btn
    statusPill.Position = UDim2.new(1, -168 - 58, 0, 12)
    statusPill.Size = UDim2.fromOffset(50, 18)
    statusPill.Parent = panel
    local statusPillCorner = Instance.new("UICorner")
    statusPillCorner.CornerRadius = UDim.new(1, 0)
    statusPillCorner.Parent = statusPill
    local statusPillLabel = Instance.new("TextLabel")
    statusPillLabel.Size = UDim2.new(1, 0, 1, 0)
    statusPillLabel.BackgroundTransparency = 1
    statusPillLabel.Font = Enum.Font.GothamBold
    statusPillLabel.TextSize = 10
    statusPillLabel.TextColor3 = Color3.fromRGB(80, 220, 120)
    statusPillLabel.Text = "● OFF"
    statusPillLabel.ZIndex = 7
    statusPillLabel.Parent = statusPill

    -- Clamp panel
    local function clampPanelToViewport()
        local currentCam = workspace.CurrentCamera
        if not currentCam then return end
        local vp = currentCam.ViewportSize
        local panelSize = panel.AbsoluteSize
        local minVisibleX = 140
        local minVisibleY = 28
        local minX = -panelSize.X + minVisibleX
        local maxX = vp.X - minVisibleX
        local minY = 0
        local maxY = vp.Y - minVisibleY
        if maxX < minX then maxX = minX end
        if maxY < minY then maxY = minY end
        local x = math.clamp(panel.Position.X.Offset, minX, maxX)
        local y = math.clamp(panel.Position.Y.Offset, minY, maxY)
        panel.Position = UDim2.fromOffset(x, y)
    end

    do
        local currentCam = workspace.CurrentCamera
        if currentCam then
            local startX = currentCam.ViewportSize.X - panel.Size.X.Offset - 18
            panel.Position = UDim2.fromOffset(startX, 18)
            clampPanelToViewport()
            table.insert(connections, currentCam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                if scriptKilled then return end
                clampPanelToViewport()
            end))
        end
    end

    -- Header drag zone
    local headerDragZone = Instance.new("Frame")
    headerDragZone.Name = "HeaderDragZone"
    headerDragZone.Size = UDim2.new(1, -240, 0, 42)
    headerDragZone.Position = UDim2.fromOffset(0, 0)
    headerDragZone.BackgroundTransparency = 1
    headerDragZone.Active = true
    headerDragZone.ZIndex = 3
    headerDragZone.Parent = panel

    -- Resize handle
    local resizeHandle = Instance.new("Frame")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Size = UDim2.fromOffset(20, 20)
    resizeHandle.AnchorPoint = Vector2.new(1, 1)
    resizeHandle.Position = UDim2.new(1, -3, 1, -3)
    resizeHandle.BackgroundColor3 = THEME.bg4
    resizeHandle.BorderSizePixel = 0
    resizeHandle.Active = true
    resizeHandle.ZIndex = 8
    resizeHandle.Parent = panel
    local resizeHandleCorner = Instance.new("UICorner")
    resizeHandleCorner.CornerRadius = UDim.new(0, 5)
    resizeHandleCorner.Parent = resizeHandle
    local resizeGlyph = Instance.new("TextLabel")
    resizeGlyph.Size = UDim2.new(1, 0, 1, 0)
    resizeGlyph.BackgroundTransparency = 1
    resizeGlyph.Font = Enum.Font.GothamBold
    resizeGlyph.TextSize = 11
    resizeGlyph.TextColor3 = THEME.textSecondary
    resizeGlyph.Text = "⤡"
    resizeGlyph.Parent = resizeHandle

    -- ╔══════════════════════════════════════════╗
    -- ║        SCROLLING CONTENT AREA            ║
    -- ╚══════════════════════════════════════════╝
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -10, 1, -52)
    content.Position = UDim2.fromOffset(5, 48)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.fromOffset(0, 500)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = THEME.accent
    content.ScrollBarImageTransparency = 0.4
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.Parent = panel

    -- ── Helper: section card ──────────────────────────────────────
    local function makeCard(yPos, height)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -10, 0, height)
        card.Position = UDim2.fromOffset(5, yPos)
        card.BackgroundColor3 = THEME.bg2
        card.BorderSizePixel = 0
        card.Parent = content
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 10)
        cc.Parent = card
        local cs = Instance.new("UIStroke")
        cs.Thickness = 1
        cs.Color = THEME.border
        cs.Transparency = 0.3
        cs.Parent = card
        return card
    end

    -- ── Helper: section label ─────────────────────────────────────
    local function makeSectionLabel(parent, text, yPos, accentColor)
        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(3, 12)
        dot.Position = UDim2.fromOffset(8, yPos + 1)
        dot.BackgroundColor3 = accentColor or THEME.accent
        dot.BorderSizePixel = 0
        dot.Parent = parent
        local dotC = Instance.new("UICorner")
        dotC.CornerRadius = UDim.new(1, 0)
        dotC.Parent = dot

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -20, 0, 14)
        lbl.Position = UDim2.fromOffset(15, yPos)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.TextColor3 = accentColor or THEME.accent
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = string.upper(text)
        lbl.Parent = parent
        return lbl
    end

    -- ╔══════════════════════════════════════════╗
    -- ║         STATUS / STATS CARDS             ║
    -- ╚══════════════════════════════════════════╝
    local statusCard = makeCard(4, 56)

    -- status row
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -12, 0, 22)
    status.Position = UDim2.fromOffset(6, 6)
    status.BackgroundColor3 = THEME.bg3
    status.BorderSizePixel = 0
    status.Font = Enum.Font.Code
    status.TextSize = 10
    status.TextColor3 = THEME.textSecondary
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = statusCard
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 7)
    statusCorner.Parent = status
    local statusPad = Instance.new("UIPadding")
    statusPad.PaddingLeft = UDim.new(0, 6)
    statusPad.Parent = status

    -- stats row
    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, -12, 0, 22)
    stats.Position = UDim2.fromOffset(6, 30)
    stats.BackgroundColor3 = THEME.bg3
    stats.BorderSizePixel = 0
    stats.Font = Enum.Font.Code
    stats.TextSize = 10
    stats.TextColor3 = THEME.textSecondary
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.Parent = statusCard
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 7)
    statsCorner.Parent = stats
    local statsPad = Instance.new("UIPadding")
    statsPad.PaddingLeft = UDim.new(0, 6)
    statsPad.Parent = stats

    -- ACTION BUTTONS GRID

    -- Section label for actions (managed by UIListLayout on content)
    local actionsSectionRow = Instance.new("Frame")
    actionsSectionRow.Size = UDim2.new(1, 0, 0, 18)
    actionsSectionRow.BackgroundTransparency = 1
    actionsSectionRow.BorderSizePixel = 0
    actionsSectionRow.Parent = content

    local actionsDot = Instance.new("Frame")
    actionsDot.Size = UDim2.fromOffset(3, 12)
    actionsDot.Position = UDim2.fromOffset(3, 3)
    actionsDot.BackgroundColor3 = THEME.accent
    actionsDot.BorderSizePixel = 0
    actionsDot.Parent = actionsSectionRow
    local adC = Instance.new("UICorner")
    adC.CornerRadius = UDim.new(1, 0)
    adC.Parent = actionsDot

    local actionsLbl = Instance.new("TextLabel")
    actionsLbl.Size = UDim2.new(1, -12, 1, 0)
    actionsLbl.Position = UDim2.fromOffset(10, 0)
    actionsLbl.BackgroundTransparency = 1
    actionsLbl.Font = Enum.Font.GothamBold
    actionsLbl.TextSize = 10
    actionsLbl.TextColor3 = THEME.accent
    actionsLbl.TextXAlignment = Enum.TextXAlignment.Left
    actionsLbl.Text = "QUICK ACTIONS"
    actionsLbl.Parent = actionsSectionRow

    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, 0, 0, 10) -- height auto via AutomaticSize
    grid.BackgroundColor3 = THEME.bg2
    grid.BorderSizePixel = 0
    grid.AutomaticSize = Enum.AutomaticSize.Y
    grid.Parent = content

    local gridPad = Instance.new("UIPadding")
    gridPad.PaddingLeft   = UDim.new(0, 6)
    gridPad.PaddingRight  = UDim.new(0, 6)
    gridPad.PaddingTop    = UDim.new(0, 6)
    gridPad.PaddingBottom = UDim.new(0, 6)
    gridPad.Parent = grid

    -- UIListLayout stacks rows vertically; each row holds 2 buttons side by side
    local layout = Instance.new("UIListLayout")
    layout.FillDirection  = Enum.FillDirection.Vertical
    layout.Padding        = UDim.new(0, 5)
    layout.SortOrder      = Enum.SortOrder.LayoutOrder
    layout.Parent         = grid

    local minimized = false
    local normalSize = panel.Size
    local dragging = false
    local dragStart, panelStart
    local resizing = false
    local resizeStart, resizeStartSize

    local function setPanelSizeInternal(width, height)
        panelWidth  = math.floor(math.clamp(width,  CONFIG.panelMinWidth,  CONFIG.panelMaxWidth))
        panelHeight = math.floor(math.clamp(height, CONFIG.panelMinHeight, CONFIG.panelMaxHeight))
        normalSize  = UDim2.fromOffset(panelWidth, panelHeight)
        if minimized then
            panel.Size = UDim2.fromOffset(panelWidth, 42)
        else
            panel.Size = normalSize
        end
        clampPanelToViewport()
    end

    -- Row container: holds exactly 2 buttons side by side, always fills grid width
    local rowOrder = 0
    local function makeButtonRow()
        rowOrder = rowOrder + 1
        local row = Instance.new("Frame")
        row.Size              = UDim2.new(1, 0, 0, 32)
        row.BackgroundTransparency = 1
        row.BorderSizePixel   = 0
        row.LayoutOrder       = rowOrder
        row.Parent            = grid

        local rowList = Instance.new("UIListLayout")
        rowList.FillDirection = Enum.FillDirection.Horizontal
        rowList.Padding       = UDim.new(0, 5)
        rowList.SortOrder     = Enum.SortOrder.LayoutOrder
        rowList.Parent        = row
        return row
    end

    -- Button factory ── buttons go inside a row frame, half-width each
    local function makeButton(text, callback, bgColor, textColor, accentColor, parentRow)
        local b = Instance.new("TextButton")
        b.AutoButtonColor = false
        b.BackgroundColor3 = bgColor or THEME.bg3
        b.BorderSizePixel  = 0
        b.Font             = Enum.Font.GothamSemibold
        b.TextSize         = 11
        b.TextColor3       = textColor or THEME.textPrimary
        b.Text             = text
        b.Size             = UDim2.new(0.5, -3, 1, 0)  -- exactly half-width minus half the 5px gap
        b.TextXAlignment   = Enum.TextXAlignment.Left
        b.ClipsDescendants = true
        b.Parent           = parentRow

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.Parent = b

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 8)
        bCorner.Parent = b

        local bStroke = Instance.new("UIStroke")
        bStroke.Thickness    = 1
        bStroke.Color        = accentColor or THEME.border
        bStroke.Transparency = 0.5
        bStroke.Parent       = b

        local bGrad = Instance.new("UIGradient")
        bGrad.Rotation = 90
        local c0 = bgColor or THEME.bg3
        bGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(
                math.min(1, c0.R + 0.04), math.min(1, c0.G + 0.04), math.min(1, c0.B + 0.04))),
            ColorSequenceKeypoint.new(1, Color3.new(
                math.max(0, c0.R - 0.03), math.max(0, c0.G - 0.03), math.max(0, c0.B - 0.03))),
        })
        bGrad.Parent = b

        b.MouseEnter:Connect(function()
            bStroke.Transparency = 0.1
            bStroke.Color = accentColor or THEME.accent
        end)
        b.MouseLeave:Connect(function()
            bStroke.Transparency = 0.5
            bStroke.Color = accentColor or THEME.border
        end)
        b.MouseButton1Down:Connect(function() b.BackgroundTransparency = 0.25 end)
        b.MouseButton1Up:Connect(function()   b.BackgroundTransparency = 0    end)

        table.insert(connections, b.MouseButton1Click:Connect(function()
            if scriptKilled then return end
            callback()
            refreshUiText()
        end))
        return b
    end

    -- Colour palette for button categories
    local COL_BLUE   = Color3.fromRGB(28, 58, 105)
    local COL_TEAL   = Color3.fromRGB(22, 68, 72)
    local COL_PURPLE = Color3.fromRGB(52, 38, 88)
    local COL_AMBER  = Color3.fromRGB(80, 55, 18)
    local COL_RED    = Color3.fromRGB(90, 28, 28)
    local COL_MUTED  = Color3.fromRGB(28, 33, 45)
    local COL_GRAY   = Color3.fromRGB(32, 38, 50)

    -- ── Row 1: Freecam toggle (full width = 1 button spanning both halves)
    -- We make a single-button row for primary action
    local rowFC = makeButtonRow()
    -- override size to full width for the freecam button
    local freecamBtnFrame = Instance.new("Frame")
    freecamBtnFrame.Size = UDim2.new(1, 0, 1, 0)
    freecamBtnFrame.BackgroundTransparency = 1
    freecamBtnFrame.BorderSizePixel = 0
    freecamBtnFrame.Parent = rowFC
    local freecamBtn = makeButton("⬛  Enable Freecam", toggleFreecam, COL_BLUE, THEME.accent, THEME.accent, freecamBtnFrame)
    freecamBtn.Size = UDim2.new(1, 0, 1, 0)  -- full width in its container

    -- ── Row 2: Cursor | Hide UI
    local r2 = makeButtonRow()
    local cursorBtn = makeButton("⊕  Unlock Cursor",  function() if freecam then setCursorUnlocked(not cursorUnlocked) end end, COL_MUTED, THEME.textPrimary, THEME.textSecondary, r2)
    local uiBtn     = makeButton("◑  Hide UI",         function() if freecam then setUiHidden(not uiHidden) end end,              COL_MUTED, THEME.textPrimary, THEME.textSecondary, r2)

    -- ── Row 3: Hide Panel | Controls Lock
    local r3 = makeButtonRow()
    makeButton("✕  Hide Panel",    function() setPanelVisible(false) end,                                                        COL_PURPLE, THEME.textPrimary, THEME.purple, r3)
    local controlsBtn = makeButton("⊘  Controls Lock", function() if freecam then setControlsEnabled(not controlsEnabled) end end, COL_AMBER, Color3.fromRGB(230,175,80), THEME.amber, r3)

    -- ── Row 4: DOF Toggle | DOF Reset
    local r4 = makeButtonRow()
    local dofToggleBtn = makeButton("◉  DOF On",  function() setDofEnabled(not dofEnabled) end, COL_TEAL, THEME.cyan, THEME.cyan, r4)
                         makeButton("↺  DOF Reset", function() resetDofSettings() end,           COL_TEAL, THEME.cyan, THEME.cyan, r4)

    -- ── Row 5: Reset All | UI Size +/-
    local r5 = makeButtonRow()
    makeButton("⚠  Reset All",  function() resetAllSettings() end,                              COL_RED,  Color3.fromRGB(240,100,100), THEME.red, r5)
    makeButton("↔  UI Size +",  function() setPanelSizeInternal(panelWidth+40, panelHeight+40) end, COL_GRAY, THEME.textSecondary, THEME.textMuted, r5)

    -- ── Row 6: UI Size - | Portrait +90
    local r6 = makeButtonRow()
    makeButton("↕  UI Size -",    function() setPanelSizeInternal(panelWidth-40, panelHeight-40) end, COL_GRAY,  THEME.textSecondary, THEME.textMuted, r6)
    makeButton("⟳  Portrait +90", function() if freecam then rotatePortrait90() end end,              COL_MUTED, THEME.textPrimary,   nil,            r6)

    -- ── Row 7: Roll Reset | FOV Reset
    local r7 = makeButtonRow()
    makeButton("—  Roll Reset", function() if freecam then roll = 0 end end,                      COL_MUTED, THEME.textPrimary, nil, r7)
    makeButton("◎  FOV Reset",  function() if freecam then setFovValue(CONFIG.defaultFov) end end, COL_MUTED, THEME.textPrimary, nil, r7)

    -- ── Row 8: FOV + | FOV -
    local r8 = makeButtonRow()
    makeButton("▲  FOV +", function() if freecam then setFovValue(targetFov + zoomStep) end end,  COL_MUTED, THEME.textPrimary, nil, r8)
    makeButton("▼  FOV -", function() if freecam then setFovValue(targetFov - zoomStep) end end,  COL_MUTED, THEME.textPrimary, nil, r8)

    -- ── Row 9: Speed Reset | Speed +/-
    local r9 = makeButtonRow()
    makeButton("◼  Speed Reset", function() if freecam then setSpeedValue(CONFIG.baseSpeed) end end,         COL_MUTED, THEME.textPrimary, nil, r9)
    makeButton("▲  Speed +",     function() if freecam then setSpeedValue(speed + CONFIG.speedStep) end end, COL_MUTED, THEME.textPrimary, nil, r9)

    -- ── Row 10: Speed - | RollSpeed Reset
    local r10 = makeButtonRow()
    makeButton("▼  Speed -",       function() if freecam then setSpeedValue(speed - CONFIG.speedStep) end end,                               COL_MUTED, THEME.textPrimary, nil, r10)
    makeButton("◼  RollSpd Reset", function() if freecam then rollSpeed = CONFIG.rollSpeed end end,                                          COL_MUTED, THEME.textPrimary, nil, r10)

    -- ── Row 11: RollSpeed + | RollSpeed -
    local r11 = makeButtonRow()
    makeButton("▲  RollSpd +", function() if freecam then setRollSpeedDeg(math.deg(rollSpeed) + math.deg(CONFIG.rollSpeedStep)) end end, COL_MUTED, THEME.textPrimary, nil, r11)
    makeButton("▼  RollSpd -", function() if freecam then setRollSpeedDeg(math.deg(rollSpeed) - math.deg(CONFIG.rollSpeedStep)) end end, COL_MUTED, THEME.textPrimary, nil, r11)

    -- ╔══════════════════════════════════════════╗
    -- ║               SLIDERS                    ║
    -- ╚══════════════════════════════════════════╝

    local sliderLabelHolder = nil -- removed; was a placeholder no longer needed

    -- Section label for sliders (managed by content UIListLayout)
    local sliderSectionRow = Instance.new("Frame")
    sliderSectionRow.Size = UDim2.new(1, 0, 0, 18)
    sliderSectionRow.BackgroundTransparency = 1
    sliderSectionRow.BorderSizePixel = 0
    sliderSectionRow.Parent = content

    local sliderDot = Instance.new("Frame")
    sliderDot.Size = UDim2.fromOffset(3, 12)
    sliderDot.Position = UDim2.fromOffset(3, 3)
    sliderDot.BackgroundColor3 = THEME.green
    sliderDot.BorderSizePixel = 0
    sliderDot.Parent = sliderSectionRow
    local sliderDotC = Instance.new("UICorner")
    sliderDotC.CornerRadius = UDim.new(1, 0)
    sliderDotC.Parent = sliderDot

    local sliderSectionLbl = Instance.new("TextLabel")
    sliderSectionLbl.Size = UDim2.new(1, -12, 1, 0)
    sliderSectionLbl.Position = UDim2.fromOffset(10, 0)
    sliderSectionLbl.BackgroundTransparency = 1
    sliderSectionLbl.Font = Enum.Font.GothamBold
    sliderSectionLbl.TextSize = 10
    sliderSectionLbl.TextColor3 = THEME.green
    sliderSectionLbl.TextXAlignment = Enum.TextXAlignment.Left
    sliderSectionLbl.Text = "PARAMETER SLIDERS  ·  drag or type a value"
    sliderSectionLbl.Parent = sliderSectionRow


    local sliderHolder = Instance.new("Frame")
    sliderHolder.Size = UDim2.new(1, 0, 0, 15 * 42)
    -- position managed by content UIListLayout
    sliderHolder.BackgroundColor3 = THEME.bg2
    sliderHolder.BorderSizePixel = 0
    sliderHolder.Parent = content
    local sliderHolderCorner = Instance.new("UICorner")
    sliderHolderCorner.CornerRadius = UDim.new(0, 10)
    sliderHolderCorner.Parent = sliderHolder
    local sliderHolderStroke = Instance.new("UIStroke")
    sliderHolderStroke.Thickness = 1
    sliderHolderStroke.Color = THEME.border
    sliderHolderStroke.Transparency = 0.3
    sliderHolderStroke.Parent = sliderHolder

    local activeSliderRow = nil

    local function createSliderRow(parent, y, labelText, minVal, maxVal, getValue, setValue, formatValue, accentColor)
        accentColor = accentColor or THEME.accent

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 38)
        row.Position = UDim2.fromOffset(0, y)
        row.BackgroundColor3 = THEME.bg3
        row.BorderSizePixel = 0
        row.Parent = parent

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, 8)
        rowCorner.Parent = row

        -- hover effect
        row.MouseEnter:Connect(function()
            row.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
        end)
        row.MouseLeave:Connect(function()
            row.BackgroundColor3 = THEME.bg3
        end)

        -- small accent dot
        local dot2 = Instance.new("Frame")
        dot2.Size = UDim2.fromOffset(3, 3)
        dot2.Position = UDim2.fromOffset(5, 18)
        dot2.BackgroundColor3 = accentColor
        dot2.BorderSizePixel = 0
        dot2.Parent = row
        local dot2C = Instance.new("UICorner")
        dot2C.CornerRadius = UDim.new(1, 0)
        dot2C.Parent = dot2

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromOffset(120, 16)
        label.Position = UDim2.fromOffset(12, 3)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 10
        label.TextColor3 = THEME.textSecondary
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = labelText
        label.Parent = row

        local box = Instance.new("TextBox")
        box.Size = UDim2.fromOffset(64, 22)
        box.Position = UDim2.new(1, -70, 0, 8)
        box.BackgroundColor3 = THEME.bg4
        box.BorderSizePixel = 0
        box.Font = Enum.Font.Code
        box.TextSize = 11
        box.TextColor3 = accentColor
        box.ClearTextOnFocus = false
        box.Text = formatValue(getValue())
        box.Parent = row
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 6)
        boxCorner.Parent = box
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Thickness = 1
        boxStroke.Color = accentColor
        boxStroke.Transparency = 0.7
        boxStroke.Parent = box

        -- Track bar
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -208, 0, 6)
        bar.Position = UDim2.fromOffset(134, 16)
        bar.BackgroundColor3 = THEME.bg0
        bar.BorderSizePixel = 0
        bar.Parent = row
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = bar

        -- Track bar fill
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = accentColor
        fill.BorderSizePixel = 0
        fill.Parent = bar
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill
        local fillGrad = Instance.new("UIGradient")
        fillGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(
                math.min(1, accentColor.R + 0.25),
                math.min(1, accentColor.G + 0.25),
                math.min(1, accentColor.B + 0.25)
            )),
            ColorSequenceKeypoint.new(1, accentColor),
        })
        fillGrad.Parent = fill

        -- Knob
        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(14, 14)
        knob.Position = UDim2.new(0, -7, 0.5, -7)
        knob.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 2
        knob.Parent = bar
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob
        local knobStroke = Instance.new("UIStroke")
        knobStroke.Thickness = 2
        knobStroke.Color = accentColor
        knobStroke.Parent = knob

        local function setFromX(xPos)
            local left = bar.AbsolutePosition.X
            local width = bar.AbsoluteSize.X
            if width <= 0 then return end
            local t = math.clamp((xPos - left) / width, 0, 1)
            setValue(minVal + (maxVal - minVal) * t)
            refreshUiText()
        end

        table.insert(connections, bar.InputBegan:Connect(function(input)
            if scriptKilled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                activeSliderRow = { setFromX = setFromX }
                setFromX(input.Position.X)
            end
        end))

        table.insert(connections, box.FocusLost:Connect(function(enterPressed)
            if scriptKilled then return end
            if not enterPressed then refreshUiText(); return end
            local n = tonumber(box.Text)
            if n then setValue(n) end
            refreshUiText()
        end))

        return { min = minVal, max = maxVal, box = box, fill = fill, knob = knob, format = formatValue }
    end

    -- Slider color palette
    local SC = {
        THEME.accent,            -- blue
        THEME.cyan,              -- cyan
        THEME.green,             -- green
        Color3.fromRGB(180,130,255), -- lavender
        Color3.fromRGB(255,160,60),  -- orange
        Color3.fromRGB(255,100,140), -- pink
        THEME.amber,
        THEME.cyan,
        Color3.fromRGB(130,200,255),
        Color3.fromRGB(100,240,180),
        Color3.fromRGB(200,160,255),
        Color3.fromRGB(255,180,80),
        Color3.fromRGB(160,220,255),
        Color3.fromRGB(255,140,100),
        Color3.fromRGB(100,255,200),
    }

    local speedRow = createSliderRow(sliderHolder, 0, "Speed", CONFIG.minSpeed, CONFIG.maxSpeed, function() return speed end, setSpeedValue, function(v) return string.format("%.0f", v) end, SC[1])
    local rollSpeedRow = createSliderRow(sliderHolder, 42, "Roll Speed", math.deg(CONFIG.minRollSpeed), math.deg(CONFIG.maxRollSpeed), function() return math.deg(rollSpeed) end, setRollSpeedDeg, function(v) return string.format("%.0f", v) end, SC[2])
    local fovRow = createSliderRow(sliderHolder, 84, "FOV", CONFIG.minFov, CONFIG.maxFov, function() return targetFov end, setFovValue, function(v) return string.format("%.1f", v) end, SC[3])
    local sensRow = createSliderRow(sliderHolder, 126, "Sensitivity", 0.02, 1.5, function() return sensitivity end, setSensitivityValue, function(v) return string.format("%.2f", v) end, SC[4])
    local posSmoothRow = createSliderRow(sliderHolder, 168, "Pos Smooth", 1, 40, function() return posSmooth end, setPosSmoothValue, function(v) return string.format("%.1f", v) end, SC[5])
    local rotSmoothRow = createSliderRow(sliderHolder, 210, "Rot Smooth", 1, 40, function() return rotSmooth end, setRotSmoothValue, function(v) return string.format("%.1f", v) end, SC[6])
    local fovSmoothRow = createSliderRow(sliderHolder, 252, "FOV Smooth", 1, 40, function() return fovSmooth end, setFovSmoothValue, function(v) return string.format("%.1f", v) end, SC[7])
    local zoomStepRow = createSliderRow(sliderHolder, 294, "Zoom Step", 0.2, 20, function() return zoomStep end, setZoomStepValue, function(v) return string.format("%.2f", v) end, SC[8])
    local dofNearRow = createSliderRow(sliderHolder, 336, "DOF Near", 0, 1, function() return dofNearIntensity end, setDofNearIntensity, function(v) return string.format("%.2f", v) end, SC[9])
    local dofFarRow = createSliderRow(sliderHolder, 378, "DOF Far", 0, 1, function() return dofFarIntensity end, setDofFarIntensity, function(v) return string.format("%.2f", v) end, SC[10])
    local dofFocusRow = createSliderRow(sliderHolder, 420, "DOF Focus", CONFIG.dofMinDistance, CONFIG.dofMaxDistance, function() return dofFocusDistance end, setDofFocusDistance, function(v) return string.format("%.1f", v) end, SC[11])
    local dofRadiusRow = createSliderRow(sliderHolder, 462, "DOF Radius", 0, CONFIG.dofMaxDistance, function() return dofInFocusRadius end, setDofInFocusRadius, function(v) return string.format("%.1f", v) end, SC[12])
    local boostRow = createSliderRow(sliderHolder, 504, "Boost ×", 1, 8, function() return boostMultiplier end, setBoostMultiplierValue, function(v) return string.format("%.2f", v) end, SC[13])
    local slowRow = createSliderRow(sliderHolder, 546, "Slow ×", 0.05, 1, function() return slowMultiplier end, setSlowMultiplierValue, function(v) return string.format("%.2f", v) end, SC[14])
    local pitchClampRow = createSliderRow(sliderHolder, 588, "Pitch Clamp°", 30, 89, function() return math.deg(pitchClamp) end, setPitchClampDeg, function(v) return string.format("%.0f", v) end, SC[15])

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
            resizing = false
            dragging = false
        end
    end))

    -- ╔══════════════════════════════════════════╗
    -- ║             KEYMAP CARD                  ║
    -- ╚══════════════════════════════════════════╝
    local keymapCard = Instance.new("Frame")
    keymapCard.Size = UDim2.new(1, -10, 0, 145)
    keymapCard.BackgroundColor3 = THEME.bg2
    keymapCard.BorderSizePixel = 0
    keymapCard.Parent = content
    local keymapCorner = Instance.new("UICorner")
    keymapCorner.CornerRadius = UDim.new(0, 10)
    keymapCorner.Parent = keymapCard
    local keymapStroke = Instance.new("UIStroke")
    keymapStroke.Thickness = 1
    keymapStroke.Color = THEME.border
    keymapStroke.Transparency = 0.3
    keymapStroke.Parent = keymapCard

    local keymapTitle = Instance.new("TextLabel")
    keymapTitle.Size = UDim2.new(1, -12, 0, 14)
    keymapTitle.Position = UDim2.fromOffset(10, 6)
    keymapTitle.BackgroundTransparency = 1
    keymapTitle.Font = Enum.Font.GothamBold
    keymapTitle.TextSize = 10
    keymapTitle.TextColor3 = THEME.amber
    keymapTitle.TextXAlignment = Enum.TextXAlignment.Left
    keymapTitle.Text = "⌨  KEYBOARD SHORTCUTS"
    keymapTitle.Parent = keymapCard

    local keySep = Instance.new("Frame")
    keySep.Size = UDim2.new(1, -12, 0, 1)
    keySep.Position = UDim2.fromOffset(6, 22)
    keySep.BackgroundColor3 = THEME.border
    keySep.BorderSizePixel = 0
    keySep.Parent = keymapCard

    local keyList = Instance.new("TextLabel")
    keyList.Size = UDim2.new(1, -12, 0, 115)
    keyList.Position = UDim2.fromOffset(6, 26)
    keyList.BackgroundTransparency = 1
    keyList.Font = Enum.Font.Code
    keyList.TextSize = 10
    keyList.TextColor3 = THEME.textSecondary
    keyList.TextXAlignment = Enum.TextXAlignment.Left
    keyList.TextYAlignment = Enum.TextYAlignment.Top
    keyList.RichText = true
    keyList.Text = table.concat({
        '<font color="#5ca8ff">Shift+F</font> Toggle Freecam     <font color="#5ca8ff">P</font> Toggle Panel     <font color="#5ca8ff">K</font> Controls Lock',
        '<font color="#5ca8ff">W/A/S/D</font> Move   <font color="#5ca8ff">Q/E</font> Up/Down   <font color="#5ca8ff">LShift</font> Boost   <font color="#5ca8ff">LCtrl</font> Slow',
        '<font color="#5ca8ff">Z/C</font> Roll Left/Right   <font color="#5ca8ff">X</font> Roll Reset   <font color="#5ca8ff">R</font> Portrait +90°',
        '<font color="#5ca8ff">M</font> Cursor Toggle   <font color="#5ca8ff">U</font> Hide UI   <font color="#5ca8ff">Scroll</font> Zoom FOV',
        '<font color="#5ca8ff">+/-</font> Speed ±   <font color="#5ca8ff">0</font> Speed Reset   <font color="#5ca8ff">[ ]</font> Roll Speed ±',
        '<font color="#3cd878">DOF:</font> Toggle/sliders in panel   <font color="#3cd878">Resize:</font> drag corner handle',
    }, "\n")
    keyList.Parent = keymapCard

    -- ── Spacer at the bottom so content doesn't hug the resize handle ──
    local bottomSpacer = Instance.new("Frame")
    bottomSpacer.Size = UDim2.new(1, 0, 0, 8)
    bottomSpacer.BackgroundTransparency = 1
    bottomSpacer.BorderSizePixel = 0
    bottomSpacer.Parent = content

    -- Assign LayoutOrder so UIListLayout on content stacks items correctly
    statusCard.LayoutOrder        = 1
    actionsSectionRow.LayoutOrder = 2
    grid.LayoutOrder              = 3
    sliderSectionRow.LayoutOrder  = 4
    sliderHolder.LayoutOrder      = 5
    keymapCard.LayoutOrder        = 6
    bottomSpacer.LayoutOrder      = 7

    -- Remove the old sliderLabelHolder (placeholder TextLabel we no longer need)
    if sliderLabelHolder and sliderLabelHolder.Parent then
        sliderLabelHolder:Destroy()
    end

    -- Install UIListLayout on the scrolling content frame — this is what
    -- eliminates all manual position arithmetic and the resize text-shuffle bug.
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.FillDirection       = Enum.FillDirection.Vertical
    contentLayout.Padding             = UDim.new(0, 6)
    contentLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    contentLayout.Parent              = content

        -- ── Drag / Resize ─────────────────────────────────────────────
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

    table.insert(connections, resizeHandle.InputBegan:Connect(function(input)
        if scriptKilled then return end
        if minimized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            resizeStartSize = Vector2.new(panelWidth, panelHeight)
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if scriptKilled then return end
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            panel.Position = UDim2.fromOffset(panelStart.X.Offset + delta.X, panelStart.Y.Offset + delta.Y)
            clampPanelToViewport()
        elseif resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            setPanelSizeInternal(resizeStartSize.X + delta.X, resizeStartSize.Y + delta.Y)
        end
    end))

    -- ── Minimize button ───────────────────────────────────────────
    table.insert(connections, minimizeBtn.MouseButton1Click:Connect(function()
        if scriptKilled then return end
        minimized = not minimized
        if minimized then
            content.Visible = false
            accentLine.Visible = false
            panel.Size = UDim2.fromOffset(normalSize.X.Offset, 42)
            minimizeBtn.Text = "MAX"
            resizeHandle.Visible = false
            resizing = false
        else
            content.Visible = true
            accentLine.Visible = true
            panel.Size = normalSize
            minimizeBtn.Text = "MIN"
            resizeHandle.Visible = true
        end
        clampPanelToViewport()
    end))

    -- ── Exit button ───────────────────────────────────────────────
    table.insert(connections, exitBtn.MouseButton1Click:Connect(function()
        if scriptKilled then return end
        scriptKilled = true
        if freecam then toggleFreecam() end
        if dofEffect then dofEffect.Enabled = false end
        for _, c in ipairs(connections) do
            if c and c.Disconnect then c:Disconnect() end
        end
        connections = {}
        gui:Destroy()
        print("Freecam script killed via UI")
    end))

    -- ── Store refs ────────────────────────────────────────────────
    uiRefs = {
        panel = panel,
        clampPanel = clampPanelToViewport,
        status = status,
        stats = stats,
        statusPillLabel = statusPillLabel,
        statusPill = statusPill,
        freecamBtn = freecamBtn,
        cursorBtn = cursorBtn,
        uiBtn = uiBtn,
        controlsBtn = controlsBtn,
        dofToggleBtn = dofToggleBtn,
        speedRow = speedRow,
        rollSpeedRow = rollSpeedRow,
        fovRow = fovRow,
        sensRow = sensRow,
        posSmoothRow = posSmoothRow,
        rotSmoothRow = rotSmoothRow,
        fovSmoothRow = fovSmoothRow,
        zoomStepRow = zoomStepRow,
        dofNearRow = dofNearRow,
        dofFarRow = dofFarRow,
        dofFocusRow = dofFocusRow,
        dofRadiusRow = dofRadiusRow,
        boostRow = boostRow,
        slowRow = slowRow,
        pitchClampRow = pitchClampRow,
    }
    refreshUiText()
end

createControlUI()

--// TOGGLE + SPEED + ROLL RESET
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
    if scriptKilled then return end
    if gp then return end

    if input.KeyCode == CONFIG.panelToggleKey then
        setPanelVisible(not panelVisible)
        refreshUiText()
        return
    end

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
            targetFov - input.Position.Z * zoomStep,
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
        yawTarget   -= delta.X * sensitivity * 0.01
        pitchTarget -= delta.Y * sensitivity * 0.01
        pitchTarget = math.clamp(pitchTarget, -pitchClamp, pitchClamp)
    end

    local rotAlpha = smooth(rotSmooth, dt)
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
            speedNow *= boostMultiplier
        elseif UserInputService:IsKeyDown(CONFIG.slowKey) then
            speedNow *= slowMultiplier
        end
        move = rot:VectorToWorldSpace(inputVec.Unit) * speedNow * dt
    end

    targetCFrame = CFrame.new(targetCFrame.Position + move) * rot
    currentCFrame = currentCFrame:Lerp(targetCFrame, smooth(posSmooth, dt))
    cam.CFrame = currentCFrame

    cam.FieldOfView += (targetFov - cam.FieldOfView) * smooth(fovSmooth, dt)
    refreshUiText()
end))

print("Hi!")
