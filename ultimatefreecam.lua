-- CUSTOM FREECAM SCRIPT
--// SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

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
    stickOverlayToggleKey = Enum.KeyCode.I,
    gamepadToggleKey = Enum.KeyCode.ButtonSelect,
    gamepadFlightModeKey = Enum.KeyCode.ButtonY,
    orbitToggleKey = Enum.KeyCode.O,
    orbitPickKey = Enum.KeyCode.T,
    orbitClearKey = Enum.KeyCode.Y,
    orbitSelfKey = Enum.KeyCode.G,
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

    orbitDefaultDistance = 16,
    orbitMinDistance = 2,
    orbitMaxDistance = 500,
    orbitPickDistance = 10000,

    panelDefaultWidth = 500,
    panelDefaultHeight = 580,
    panelMinWidth = 420,
    panelMinHeight = 400,
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

--// PER-MODE SETTINGS
local modeSettings = {
    Normal = {
        speed           = 60,
        sensitivity     = 0.20,
        posSmooth       = 10,
        rotSmooth       = 12,
        fovSmooth       = 12,
        zoomStep        = 3,
        pitchClamp      = math.rad(85),
        rollSpeed       = math.rad(80),
        boostMultiplier = 3,
        slowMultiplier  = 0.25,
    },
    Drone = {
        speed               = 4.5,
        sensitivity         = 0.18,
        posSmooth           = 8,
        rotSmooth           = 10,
        fovSmooth           = 12,
        zoomStep            = 3,
        pitchClamp          = math.rad(89),
        boostMultiplier     = 3,
        slowMultiplier      = 0.25,
        verticalSpeedMult   = 1.0,
        droneDeadzone       = 0.05,
        droneRollRate       = 360,
        dronePitchRate      = 360,
        droneYawRate        = 240,
        droneRollExpo       = 0.30,
        dronePitchExpo      = 0.30,
        droneYawExpo        = 0.25,
        droneRollSuper      = 0.50,
        dronePitchSuper     = 0.50,
        droneYawSuper       = 0.40,
        droneRateResponse   = 10,
        droneAngularDamping = 0.20,
        droneThrottleMid    = 0.50,
        droneThrottleExpo   = 0.30,
        droneThrustResponse = 5,
        droneThrottlePower  = 1.8,
        droneCameraTilt     = 20,
        droneFullRotation   = true,
        droneGravity        = 196.2,
        droneHoverThrottle  = 0.50,
        droneDrag           = 0.25,
        droneQuadDrag       = 0.05,
        droneInertia        = 0.60,
        droneMass           = 1.0,
        droneFlightMode         = "Acro",
        droneAngleMaxTilt       = 45,
        droneAngleLevelStrength = 8,
        droneAngleYawCoord      = 0.5,
        droneMoiPitch           = 1.0,
        droneMoiRoll            = 0.7,
        droneMoiYaw             = 1.5,
        droneDragForward        = 0.15,
        droneDragSideways       = 0.45,
        droneDragVertical       = 0.55,
        droneMotorSpinUp        = 15,
        droneMotorSpinDown      = 10,
        dronePropwashStrength   = 0.35,
        dronePropwashZone       = 0.40,
        droneGroundEffectHeight = 3.0,
        droneGroundEffectStrength = 0.12,
    },
    Gyro = {
        speed           = 60,
        sensitivity     = 0.25,
        posSmooth       = 12,
        rotSmooth       = 14,
        fovSmooth       = 12,
        zoomStep        = 3,
        pitchClamp      = math.rad(85),
        rollSpeed       = math.rad(80),
        boostMultiplier = 3,
        slowMultiplier  = 0.25,
        gyroStrength    = 6,
    },
}

--// VARS
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera
local freecam = false
local currentMode = "Normal"

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
local orbitEnabled = false
local orbitTarget = nil
local orbitTargetLabel = "None"
local orbitRadius = CONFIG.orbitDefaultDistance

-- Mode-specific vars
local gyroStrength = 6
local droneVertMult = 1.0
local droneDeadzone = 0.05
local droneRollRate = 360
local dronePitchRate = 360
local droneYawRate = 240
local droneRollExpo = 0.30
local dronePitchExpo = 0.30
local droneYawExpo = 0.25
local droneRollSuper = 0.50
local dronePitchSuper = 0.50
local droneYawSuper = 0.40
local droneRateResponse = 10
local droneAngularDamping = 0.20
local droneThrottleMid = 0.50
local droneThrottleExpo = 0.30
local droneThrustResponse = 5
local droneThrottlePower = 1.8
local droneCameraTilt = 20
local droneFullRotation = true
local droneGravity = 196.2
local droneHoverThrottle = 0.50
local droneDrag = 0.25
local droneQuadDrag = 0.05
local droneInertia = 0.60
local droneMass = 1.0
local droneVelocity = Vector3.zero
local droneThrottleState = 0
local droneOrient = nil
local droneAngVel = Vector3.zero

-- Drone flight mode: "Acro", "Angle", "3D"
local droneFlightMode = "Acro"
local droneAngleMaxTilt = 45
local droneAngleLevelStrength = 8
local droneAngleYawCoord = 0.5

-- Advanced physics
local droneMoiPitch = 1.0
local droneMoiRoll = 0.7
local droneMoiYaw = 1.5
local droneDragForward = 0.15
local droneDragSideways = 0.45
local droneDragVertical = 0.55
local droneMotorSpinUp = 15
local droneMotorSpinDown = 10
local dronePropwashStrength = 0.35
local dronePropwashZone = 0.40
local droneGroundEffectHeight = 3.0
local droneGroundEffectStrength = 0.12
local droneMotorOutput = 0

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
local stickOverlayVisible = false
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

        local step = CONFIG.speedStep
        if currentMode == "Drone" then
            step = 0.25
        end
        if input.KeyCode == CONFIG.speedIncreaseKey then
            speed = math.min(CONFIG.maxSpeed, speed + step)
        elseif input.KeyCode == CONFIG.speedDecreaseKey then
            speed = math.max(CONFIG.minSpeed, speed - step)
        elseif input.KeyCode == CONFIG.speedResetKey then
            speed = CONFIG.baseSpeed
        end

        if input.KeyCode == CONFIG.rollResetKey then
            roll = 0
        end

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

function setControlsEnabled(value)
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

function setCursorUnlocked(value)
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

function setUiHidden(value)
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

function setPanelVisible(value)
    panelVisible = value
    if uiRefs.panel then
        uiRefs.panel.Visible = panelVisible
        if panelVisible and uiRefs.clampPanel then
            uiRefs.clampPanel()
        end
    end
end

function setStickOverlayVisible(value)
    stickOverlayVisible = value
    if uiRefs.stickOverlay then
        uiRefs.stickOverlay.Visible = stickOverlayVisible
    end
end

local function shortenLabel(text, maxLen)
    if not text then
        return "None"
    end
    if #text <= maxLen then
        return text
    end
    return text:sub(1, maxLen - 3) .. "..."
end

local function getOrbitTargetLabel(target)
    if not target then
        return "None"
    end
    if target:IsA("Player") then
        if target.DisplayName and target.DisplayName ~= target.Name then
            return target.DisplayName
        end
        return target.Name
    end
    return target.Name
end

local function getOrbitTargetPosition(target)
    if not target then
        return nil
    end
    if not target.Parent then
        return nil
    end
    if target:IsA("Player") then
        local char = target.Character
        if not char then
            return nil
        end
        local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
        if hrp and hrp:IsA("BasePart") then
            return hrp.Position
        end
        return char:GetPivot().Position
    elseif target:IsA("Model") then
        return target:GetPivot().Position
    elseif target:IsA("BasePart") then
        return target.Position
    elseif target:IsA("Attachment") then
        return target.WorldPosition
    end
    return nil
end

local function resolveOrbitTarget(inst)
    if not inst then
        return nil
    end
    if inst:IsA("Player") then
        return inst
    end
    if inst:IsA("Model") then
        local plr = Players:GetPlayerFromCharacter(inst)
        return plr or inst
    end
    if inst:IsA("Humanoid") then
        local model = inst.Parent
        if model and model:IsA("Model") then
            local plr = Players:GetPlayerFromCharacter(model)
            return plr or model
        end
    end
    if inst:IsA("BasePart") then
        local model = inst:FindFirstAncestorWhichIsA("Model")
        if model then
            local plr = Players:GetPlayerFromCharacter(model)
            return plr or model
        end
        return inst
    end
    return nil
end

function setOrbitTarget(target, enableOrbit)
    orbitTarget = target
    orbitTargetLabel = getOrbitTargetLabel(target)

    if not target then
        orbitEnabled = false
        return
    end

    if enableOrbit then
        orbitEnabled = true
    end

    local pos = getOrbitTargetPosition(target)
    if not pos then
        return
    end

    local camPos = cam.CFrame.Position
    local offset = camPos - pos
    local dist = offset.Magnitude
    if dist < 0.01 then
        dist = CONFIG.orbitDefaultDistance
        offset = Vector3.new(0, 0, dist)
    end
    orbitRadius = math.clamp(dist, CONFIG.orbitMinDistance, CONFIG.orbitMaxDistance)

    if offset.Magnitude > 0.01 then
        local dir = offset.Unit
        local newYaw = math.atan2(dir.X, dir.Z)
        local newPitch = math.asin(-dir.Y)
        newPitch = math.clamp(newPitch, -pitchClamp, pitchClamp)
        yaw, yawTarget = newYaw, newYaw
        pitch, pitchTarget = newPitch, newPitch
    end
end

local function clearOrbitTarget()
    orbitTarget = nil
    orbitTargetLabel = "None"
    orbitEnabled = false
end

function setOrbitEnabled(value)
    if value then
        if orbitTarget then
            setOrbitTarget(orbitTarget, true)
        else
            orbitEnabled = false
        end
    else
        orbitEnabled = false
    end
end

local function pickOrbitTarget()
    if not freecam then
        return
    end
    local camNow = workspace.CurrentCamera
    if not camNow then
        return
    end
    local mousePos = UserInputService:GetMouseLocation()
    local inset = GuiService:GetGuiInset()
    local x = mousePos.X - inset.X
    local y = mousePos.Y - inset.Y
    local ray = camNow:ViewportPointToRay(x, y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local exclude = {}
    if player.Character then
        table.insert(exclude, player.Character)
    end
    params.FilterDescendantsInstances = exclude
    local result = workspace:Raycast(ray.Origin, ray.Direction * CONFIG.orbitPickDistance, params)
    if result and result.Instance then
        local target = resolveOrbitTarget(result.Instance)
        if target then
            setOrbitTarget(target, true)
        end
    end
end

function setOrbitTargetSelf()
    setOrbitTarget(player, true)
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
        droneOrient = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, 0, roll)
        droneVelocity = Vector3.zero
        droneThrottleState = 0
        droneAngVel = Vector3.zero
        droneMotorOutput = 0

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
        orbitEnabled = false
        droneVelocity = Vector3.zero
        droneThrottleState = 0
        droneOrient = nil
        droneAngVel = Vector3.zero
        droneMotorOutput = 0
    end
end

local function rotatePortrait90()
    roll += math.rad(90)
end

local scriptKilled = false
local connections = {}

--// SETTERS
function setSpeedValue(v)
    speed = math.clamp(v, CONFIG.minSpeed, CONFIG.maxSpeed)
end

function setDroneTwr(v)
    local val = math.clamp(v, 1, 20)
    modeSettings.Drone.speed = val
    if currentMode == "Drone" then
        speed = val
    end
end

function setRollSpeedDeg(v)
    local minDeg = math.deg(CONFIG.minRollSpeed)
    local maxDeg = math.deg(CONFIG.maxRollSpeed)
    rollSpeed = math.rad(math.clamp(v, minDeg, maxDeg))
end

function setFovValue(v)
    targetFov = math.clamp(v, CONFIG.minFov, CONFIG.maxFov)
end

function setSensitivityValue(v)
    sensitivity = math.clamp(v, 0.02, 1.5)
end

function setPosSmoothValue(v)
    posSmooth = math.clamp(v, 1, 40)
end

function setRotSmoothValue(v)
    rotSmooth = math.clamp(v, 1, 40)
end

function setFovSmoothValue(v)
    fovSmooth = math.clamp(v, 1, 40)
end

function setZoomStepValue(v)
    zoomStep = math.clamp(v, 0.2, 20)
end

function setBoostMultiplierValue(v)
    boostMultiplier = math.clamp(v, 1, 8)
end

function setSlowMultiplierValue(v)
    slowMultiplier = math.clamp(v, 0.05, 1)
end

function setPitchClampDeg(v)
    pitchClamp = math.rad(math.clamp(v, 30, 89))
end

function setGyroStrength(v)
    gyroStrength = math.clamp(v, 0.5, 20)
    modeSettings.Gyro.gyroStrength = gyroStrength
end

function setDroneVertMult(v)
    droneVertMult = math.clamp(v, 0.1, 3)
    modeSettings.Drone.verticalSpeedMult = droneVertMult
end

function setDroneDeadzone(v)
    droneDeadzone = math.clamp(v, 0, 0.3)
    modeSettings.Drone.droneDeadzone = droneDeadzone
end

function setDroneRollRate(v)
    droneRollRate = math.clamp(v, 50, 1200)
    modeSettings.Drone.droneRollRate = droneRollRate
end

function setDronePitchRate(v)
    dronePitchRate = math.clamp(v, 50, 1200)
    modeSettings.Drone.dronePitchRate = dronePitchRate
end

function setDroneYawRate(v)
    droneYawRate = math.clamp(v, 50, 1200)
    modeSettings.Drone.droneYawRate = droneYawRate
end

function setDroneRollExpo(v)
    droneRollExpo = math.clamp(v, 0, 1)
    modeSettings.Drone.droneRollExpo = droneRollExpo
end

function setDronePitchExpo(v)
    dronePitchExpo = math.clamp(v, 0, 1)
    modeSettings.Drone.dronePitchExpo = dronePitchExpo
end

function setDroneYawExpo(v)
    droneYawExpo = math.clamp(v, 0, 1)
    modeSettings.Drone.droneYawExpo = droneYawExpo
end

function setDroneRollSuper(v)
    droneRollSuper = math.clamp(v, 0, 1)
    modeSettings.Drone.droneRollSuper = droneRollSuper
end

function setDronePitchSuper(v)
    dronePitchSuper = math.clamp(v, 0, 1)
    modeSettings.Drone.dronePitchSuper = dronePitchSuper
end

function setDroneYawSuper(v)
    droneYawSuper = math.clamp(v, 0, 1)
    modeSettings.Drone.droneYawSuper = droneYawSuper
end

function setDroneRateResponse(v)
    droneRateResponse = math.clamp(v, 1, 25)
    modeSettings.Drone.droneRateResponse = droneRateResponse
end

function setDroneAngularDamping(v)
    droneAngularDamping = math.clamp(v, 0, 5)
    modeSettings.Drone.droneAngularDamping = droneAngularDamping
end

function setDroneThrottleMid(v)
    droneThrottleMid = math.clamp(v, 0.05, 0.95)
    modeSettings.Drone.droneThrottleMid = droneThrottleMid
end

function setDroneThrottleExpo(v)
    droneThrottleExpo = math.clamp(v, 0, 1)
    modeSettings.Drone.droneThrottleExpo = droneThrottleExpo
end

function setDroneThrustResponse(v)
    droneThrustResponse = math.clamp(v, 1, 25)
    modeSettings.Drone.droneThrustResponse = droneThrustResponse
end

function setDroneThrottlePower(v)
    droneThrottlePower = math.clamp(v, 1, 3)
    modeSettings.Drone.droneThrottlePower = droneThrottlePower
end

function setDroneCameraTilt(v)
    droneCameraTilt = math.clamp(v, 0, 60)
    modeSettings.Drone.droneCameraTilt = droneCameraTilt
end

function setDroneGravity(v)
    droneGravity = math.clamp(v, 0, 400)
    modeSettings.Drone.droneGravity = droneGravity
end

function setDroneHoverThrottle(v)
    droneHoverThrottle = math.clamp(v, 0.05, 0.95)
    modeSettings.Drone.droneHoverThrottle = droneHoverThrottle
end

function setDroneDrag(v)
    droneDrag = math.clamp(v, 0, 3)
    modeSettings.Drone.droneDrag = droneDrag
end

function setDroneQuadDrag(v)
    droneQuadDrag = math.clamp(v, 0, 0.2)
    modeSettings.Drone.droneQuadDrag = droneQuadDrag
end

function setDroneInertia(v)
    droneInertia = math.clamp(v, 0, 1)
    modeSettings.Drone.droneInertia = droneInertia
end

function setDroneMass(v)
    droneMass = math.clamp(v, 0.2, 8)
    modeSettings.Drone.droneMass = droneMass
end

local updateDroneFlightModeUI

function setDroneFlightMode(mode)
    droneFlightMode = mode
    modeSettings.Drone.droneFlightMode = mode
    -- Reset orientation state on mode switch
    droneVelocity = Vector3.zero
    droneThrottleState = 0
    droneAngVel = Vector3.zero
    droneMotorOutput = 0
    if updateDroneFlightModeUI then
        updateDroneFlightModeUI()
    end
end

local droneFlightModeOrder = { "Acro", "Angle", "3D" }

updateDroneFlightModeUI = function()
    local dt = uiRefs.droneTabRows
    if dt and dt._flightModeBtns and dt._flightModes then
        if dt._updateFlightModeBtns then
            dt._updateFlightModeBtns()
        end
        for _, fm in ipairs(dt._flightModes) do
            local btn = dt._flightModeBtns[fm.name]
            if btn then
                if droneFlightMode == fm.name then
                    btn.BackgroundColor3 = fm.color
                    btn.TextColor3 = Color3.fromRGB(15, 15, 15)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(28, 36, 32)
                    btn.TextColor3 = Color3.fromRGB(170, 190, 180)
                end
            end
        end
    end
    if uiRefs.droneAngleSection then
        uiRefs.droneAngleSection.Visible = (droneFlightMode == "Angle")
    end
end

local function cycleDroneFlightMode(dir)
    local idx = 1
    for i, name in ipairs(droneFlightModeOrder) do
        if name == droneFlightMode then
            idx = i
            break
        end
    end
    local newIndex = ((idx - 1 + dir) % #droneFlightModeOrder) + 1
    setDroneFlightMode(droneFlightModeOrder[newIndex])
    updateDroneFlightModeUI()
end

function setDroneAngleMaxTilt(v)
    droneAngleMaxTilt = math.clamp(v, 5, 85)
    modeSettings.Drone.droneAngleMaxTilt = droneAngleMaxTilt
end

function setDroneAngleLevelStrength(v)
    droneAngleLevelStrength = math.clamp(v, 0.5, 20)
    modeSettings.Drone.droneAngleLevelStrength = droneAngleLevelStrength
end


function setDroneAngleYawCoord(v)
    droneAngleYawCoord = math.clamp(v, 0, 1)
    modeSettings.Drone.droneAngleYawCoord = droneAngleYawCoord
end

function setDroneMoiPitch(v)
    droneMoiPitch = math.clamp(v, 0.2, 5)
    modeSettings.Drone.droneMoiPitch = droneMoiPitch
end

function setDroneMoiRoll(v)
    droneMoiRoll = math.clamp(v, 0.2, 5)
    modeSettings.Drone.droneMoiRoll = droneMoiRoll
end

function setDroneMoiYaw(v)
    droneMoiYaw = math.clamp(v, 0.2, 5)
    modeSettings.Drone.droneMoiYaw = droneMoiYaw
end

function setDroneDragForward(v)
    droneDragForward = math.clamp(v, 0, 3)
    modeSettings.Drone.droneDragForward = droneDragForward
end

function setDroneDragSideways(v)
    droneDragSideways = math.clamp(v, 0, 3)
    modeSettings.Drone.droneDragSideways = droneDragSideways
end

function setDroneDragVertical(v)
    droneDragVertical = math.clamp(v, 0, 3)
    modeSettings.Drone.droneDragVertical = droneDragVertical
end

function setDroneMotorSpinUp(v)
    droneMotorSpinUp = math.clamp(v, 1, 30)
    modeSettings.Drone.droneMotorSpinUp = droneMotorSpinUp
end

function setDroneMotorSpinDown(v)
    droneMotorSpinDown = math.clamp(v, 1, 30)
    modeSettings.Drone.droneMotorSpinDown = droneMotorSpinDown
end

function setDronePropwashStrength(v)
    dronePropwashStrength = math.clamp(v, 0, 1)
    modeSettings.Drone.dronePropwashStrength = dronePropwashStrength
end

function setDronePropwashZone(v)
    dronePropwashZone = math.clamp(v, 0, 1)
    modeSettings.Drone.dronePropwashZone = dronePropwashZone
end

function setDroneGroundEffectHeight(v)
    droneGroundEffectHeight = math.clamp(v, 0, 20)
    modeSettings.Drone.droneGroundEffectHeight = droneGroundEffectHeight
end

function setDroneGroundEffectStrength(v)
    droneGroundEffectStrength = math.clamp(v, 0, 0.5)
    modeSettings.Drone.droneGroundEffectStrength = droneGroundEffectStrength
end
--// SETTINGS IMPORT / EXPORT
local function serializeSettings()
    local parts = {
        "FCv1",
        "mode="      .. currentMode,
        "speed="     .. tostring(speed),
        "sens="      .. tostring(sensitivity),
        "posSmooth=" .. tostring(posSmooth),
        "rotSmooth=" .. tostring(rotSmooth),
        "fovSmooth=" .. tostring(fovSmooth),
        "zoomStep="  .. tostring(zoomStep),
        "pitchClamp=" .. tostring(math.deg(pitchClamp)),
        "rollSpeed=" .. tostring(math.deg(rollSpeed)),
        "boost="     .. tostring(boostMultiplier),
        "slow="      .. tostring(slowMultiplier),
        "fov="       .. tostring(targetFov),
        "dofOn="     .. (dofEnabled and "1" or "0"),
        "dofNear="   .. tostring(dofNearIntensity),
        "dofFar="    .. tostring(dofFarIntensity),
        "dofFocus="  .. tostring(dofFocusDistance),
        "dofRadius=" .. tostring(dofInFocusRadius),
        "gyroStr="   .. tostring(gyroStrength),
        "dfm="       .. droneFlightMode,
        "dRollR="    .. tostring(droneRollRate),
        "dPitchR="   .. tostring(dronePitchRate),
        "dYawR="     .. tostring(droneYawRate),
        "dRollE="    .. tostring(droneRollExpo),
        "dPitchE="   .. tostring(dronePitchExpo),
        "dYawE="     .. tostring(droneYawExpo),
        "dRollS="    .. tostring(droneRollSuper),
        "dPitchS="   .. tostring(dronePitchSuper),
        "dYawS="     .. tostring(droneYawSuper),
        "dRateRsp="  .. tostring(droneRateResponse),
        "dAngDamp="  .. tostring(droneAngularDamping),
        "dThrMid="   .. tostring(droneThrottleMid),
        "dThrExp="   .. tostring(droneThrottleExpo),
        "dThrResp="  .. tostring(droneThrustResponse),
        "dThrPow="   .. tostring(droneThrottlePower),
        "dCamTilt="  .. tostring(droneCameraTilt),
        "dGrav="     .. tostring(droneGravity),
        "dHover="    .. tostring(droneHoverThrottle),
        "dDrag="     .. tostring(droneDrag),
        "dQDrag="    .. tostring(droneQuadDrag),
        "dInertia="  .. tostring(droneInertia),
        "dMass="     .. tostring(droneMass),
        "dDeadz="    .. tostring(droneDeadzone),
        "dVertM="    .. tostring(droneVertMult),
        "dAngTilt="  .. tostring(droneAngleMaxTilt),
        "dAngStr="   .. tostring(droneAngleLevelStrength),
        "dAngYawC="  .. tostring(droneAngleYawCoord),
        "dMoiP="     .. tostring(droneMoiPitch),
        "dMoiR="     .. tostring(droneMoiRoll),
        "dMoiY="     .. tostring(droneMoiYaw),
        "dDrgFwd="   .. tostring(droneDragForward),
        "dDrgSide="  .. tostring(droneDragSideways),
        "dDrgVert="  .. tostring(droneDragVertical),
        "dMotUp="    .. tostring(droneMotorSpinUp),
        "dMotDn="    .. tostring(droneMotorSpinDown),
        "dPwStr="    .. tostring(dronePropwashStrength),
        "dPwZone="   .. tostring(dronePropwashZone),
        "dGeHt="     .. tostring(droneGroundEffectHeight),
        "dGeStr="    .. tostring(droneGroundEffectStrength),
    }
    return table.concat(parts, "|")
end

local function applySettingsString(str)
    str = tostring(str):match("^%s*(.-)%s*$")
    if not str:match("^FCv1|") then
        return false, "Format tidak valid. Pastikan dimulai dengan 'FCv1|'."
    end
    local data = {}
    for pair in str:gmatch("[^|]+") do
        local k, v = pair:match("^([^=]+)=(.*)$")
        if k and v then data[k] = v end
    end
    local function num(k, default)
        return tonumber(data[k]) or default
    end
    -- Mode switch (tanpa reset state)
    if data.mode and modeSettings[data.mode] and data.mode ~= currentMode then
        saveModeSettings(currentMode)
        currentMode = data.mode
        applyModeSettings(currentMode)
    end
    -- General
    setSpeedValue(num("speed", speed))
    setSensitivityValue(num("sens", sensitivity))
    setPosSmoothValue(num("posSmooth", posSmooth))
    setRotSmoothValue(num("rotSmooth", rotSmooth))
    setFovSmoothValue(num("fovSmooth", fovSmooth))
    setZoomStepValue(num("zoomStep", zoomStep))
    setPitchClampDeg(num("pitchClamp", math.deg(pitchClamp)))
    setRollSpeedDeg(num("rollSpeed", math.deg(rollSpeed)))
    setBoostMultiplierValue(num("boost", boostMultiplier))
    setSlowMultiplierValue(num("slow", slowMultiplier))
    setFovValue(num("fov", targetFov))
    -- DoF
    dofEnabled      = (num("dofOn", dofEnabled and 1 or 0) == 1)
    dofNearIntensity = math.clamp(num("dofNear",   dofNearIntensity),   0, 1)
    dofFarIntensity  = math.clamp(num("dofFar",    dofFarIntensity),    0, 1)
    dofFocusDistance = math.clamp(num("dofFocus",  dofFocusDistance),   0, 500)
    dofInFocusRadius = math.clamp(num("dofRadius", dofInFocusRadius),   0, 500)
    applyDofSettings()
    -- Gyro
    setGyroStrength(num("gyroStr", gyroStrength))
    -- Drone flight mode
    if data.dfm and (data.dfm == "Acro" or data.dfm == "Angle" or data.dfm == "3D") then
        setDroneFlightMode(data.dfm)
    end
    -- Drone params
    setDroneRollRate(num("dRollR", droneRollRate))
    setDronePitchRate(num("dPitchR", dronePitchRate))
    setDroneYawRate(num("dYawR", droneYawRate))
    setDroneRollExpo(num("dRollE", droneRollExpo))
    setDronePitchExpo(num("dPitchE", dronePitchExpo))
    setDroneYawExpo(num("dYawE", droneYawExpo))
    setDroneRollSuper(num("dRollS", droneRollSuper))
    setDronePitchSuper(num("dPitchS", dronePitchSuper))
    setDroneYawSuper(num("dYawS", droneYawSuper))
    setDroneRateResponse(num("dRateRsp", droneRateResponse))
    setDroneAngularDamping(num("dAngDamp", droneAngularDamping))
    setDroneThrottleMid(num("dThrMid", droneThrottleMid))
    setDroneThrottleExpo(num("dThrExp", droneThrottleExpo))
    setDroneThrustResponse(num("dThrResp", droneThrustResponse))
    setDroneThrottlePower(num("dThrPow", droneThrottlePower))
    setDroneCameraTilt(num("dCamTilt", droneCameraTilt))
    setDroneGravity(num("dGrav", droneGravity))
    setDroneHoverThrottle(num("dHover", droneHoverThrottle))
    setDroneDrag(num("dDrag", droneDrag))
    setDroneQuadDrag(num("dQDrag", droneQuadDrag))
    setDroneInertia(num("dInertia", droneInertia))
    setDroneMass(num("dMass", droneMass))
    setDroneDeadzone(num("dDeadz", droneDeadzone))
    setDroneVertMult(num("dVertM", droneVertMult))
    setDroneAngleMaxTilt(num("dAngTilt", droneAngleMaxTilt))
    setDroneAngleLevelStrength(num("dAngStr", droneAngleLevelStrength))
    setDroneAngleYawCoord(num("dAngYawC", droneAngleYawCoord))
    setDroneMoiPitch(num("dMoiP", droneMoiPitch))
    setDroneMoiRoll(num("dMoiR", droneMoiRoll))
    setDroneMoiYaw(num("dMoiY", droneMoiYaw))
    setDroneDragForward(num("dDrgFwd", droneDragForward))
    setDroneDragSideways(num("dDrgSide", droneDragSideways))
    setDroneDragVertical(num("dDrgVert", droneDragVertical))
    setDroneMotorSpinUp(num("dMotUp", droneMotorSpinUp))
    setDroneMotorSpinDown(num("dMotDn", droneMotorSpinDown))
    setDronePropwashStrength(num("dPwStr", dronePropwashStrength))
    setDronePropwashZone(num("dPwZone", dronePropwashZone))
    setDroneGroundEffectHeight(num("dGeHt", droneGroundEffectHeight))
    setDroneGroundEffectStrength(num("dGeStr", droneGroundEffectStrength))
    refreshUiText()
    return true, "✔ Settingan berhasil diterapkan!"
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

function setDofEnabled(v)
    dofEnabled = v
    applyDofSettings()
end

function setDofNearIntensity(v)
    dofNearIntensity = math.clamp(v, 0, 1)
    applyDofSettings()
end

function setDofFarIntensity(v)
    dofFarIntensity = math.clamp(v, 0, 1)
    applyDofSettings()
end

function setDofFocusDistance(v)
    dofFocusDistance = math.clamp(v, CONFIG.dofMinDistance, CONFIG.dofMaxDistance)
    applyDofSettings()
end

function setDofInFocusRadius(v)
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

--// MODE SYSTEM
local function applyModeSettings(mode)
    local s = modeSettings[mode]
    if not s then return end
    speed           = s.speed
    sensitivity     = s.sensitivity
    posSmooth       = s.posSmooth
    rotSmooth       = s.rotSmooth
    fovSmooth       = s.fovSmooth
    zoomStep        = s.zoomStep
    pitchClamp      = s.pitchClamp
    boostMultiplier = s.boostMultiplier
    slowMultiplier  = s.slowMultiplier
    if s.rollSpeed    then rollSpeed    = s.rollSpeed    end
    if s.gyroStrength then gyroStrength = s.gyroStrength end
    if s.verticalSpeedMult ~= nil then droneVertMult = s.verticalSpeedMult end
    if s.droneDeadzone ~= nil then droneDeadzone = s.droneDeadzone end
    if s.droneRollRate ~= nil then droneRollRate = s.droneRollRate end
    if s.dronePitchRate ~= nil then dronePitchRate = s.dronePitchRate end
    if s.droneYawRate ~= nil then droneYawRate = s.droneYawRate end
    if s.droneRollExpo ~= nil then droneRollExpo = s.droneRollExpo end
    if s.dronePitchExpo ~= nil then dronePitchExpo = s.dronePitchExpo end
    if s.droneYawExpo ~= nil then droneYawExpo = s.droneYawExpo end
    if s.droneRollSuper ~= nil then droneRollSuper = s.droneRollSuper end
    if s.dronePitchSuper ~= nil then dronePitchSuper = s.dronePitchSuper end
    if s.droneYawSuper ~= nil then droneYawSuper = s.droneYawSuper end
    if s.droneRateResponse ~= nil then droneRateResponse = s.droneRateResponse end
    if s.droneAngularDamping ~= nil then droneAngularDamping = s.droneAngularDamping end
    if s.droneThrottleMid ~= nil then droneThrottleMid = s.droneThrottleMid end
    if s.droneThrottleExpo ~= nil then droneThrottleExpo = s.droneThrottleExpo end
    if s.droneThrustResponse ~= nil then droneThrustResponse = s.droneThrustResponse end
    if s.droneThrottlePower ~= nil then droneThrottlePower = s.droneThrottlePower end
    if s.droneCameraTilt ~= nil then droneCameraTilt = s.droneCameraTilt end
    if s.droneFullRotation ~= nil then droneFullRotation = s.droneFullRotation end
    if s.droneGravity ~= nil then droneGravity = s.droneGravity end
    if s.droneHoverThrottle ~= nil then droneHoverThrottle = s.droneHoverThrottle end
    if s.droneDrag ~= nil then droneDrag = s.droneDrag end
    if s.droneQuadDrag ~= nil then droneQuadDrag = s.droneQuadDrag end
    if s.droneInertia ~= nil then droneInertia = s.droneInertia end
    if s.droneMass ~= nil then droneMass = s.droneMass end
    if s.droneFlightMode ~= nil then droneFlightMode = s.droneFlightMode end
    if s.droneAngleMaxTilt ~= nil then droneAngleMaxTilt = s.droneAngleMaxTilt end
    if s.droneAngleLevelStrength ~= nil then droneAngleLevelStrength = s.droneAngleLevelStrength end
    if s.droneAngleYawCoord ~= nil then droneAngleYawCoord = s.droneAngleYawCoord end
    if s.droneMoiPitch ~= nil then droneMoiPitch = s.droneMoiPitch end
    if s.droneMoiRoll ~= nil then droneMoiRoll = s.droneMoiRoll end
    if s.droneMoiYaw ~= nil then droneMoiYaw = s.droneMoiYaw end
    if s.droneDragForward ~= nil then droneDragForward = s.droneDragForward end
    if s.droneDragSideways ~= nil then droneDragSideways = s.droneDragSideways end
    if s.droneDragVertical ~= nil then droneDragVertical = s.droneDragVertical end
    if s.droneMotorSpinUp ~= nil then droneMotorSpinUp = s.droneMotorSpinUp end
    if s.droneMotorSpinDown ~= nil then droneMotorSpinDown = s.droneMotorSpinDown end
    if s.dronePropwashStrength ~= nil then dronePropwashStrength = s.dronePropwashStrength end
    if s.dronePropwashZone ~= nil then dronePropwashZone = s.dronePropwashZone end
    if s.droneGroundEffectHeight ~= nil then droneGroundEffectHeight = s.droneGroundEffectHeight end
    if s.droneGroundEffectStrength ~= nil then droneGroundEffectStrength = s.droneGroundEffectStrength end
end

local function saveModeSettings(mode)
    local s = modeSettings[mode]
    s.speed           = speed
    s.sensitivity     = sensitivity
    s.posSmooth       = posSmooth
    s.rotSmooth       = rotSmooth
    s.fovSmooth       = fovSmooth
    s.zoomStep        = zoomStep
    s.pitchClamp      = pitchClamp
    s.boostMultiplier = boostMultiplier
    s.slowMultiplier  = slowMultiplier
    if mode ~= "Drone" then s.rollSpeed = rollSpeed end
    if mode == "Gyro"  then s.gyroStrength = gyroStrength end
    if mode == "Drone" then
        s.verticalSpeedMult = droneVertMult
        s.droneDeadzone = droneDeadzone
        s.droneRollRate = droneRollRate
        s.dronePitchRate = dronePitchRate
        s.droneYawRate = droneYawRate
        s.droneRollExpo = droneRollExpo
        s.dronePitchExpo = dronePitchExpo
        s.droneYawExpo = droneYawExpo
        s.droneRollSuper = droneRollSuper
        s.dronePitchSuper = dronePitchSuper
        s.droneYawSuper = droneYawSuper
        s.droneRateResponse = droneRateResponse
        s.droneAngularDamping = droneAngularDamping
        s.droneThrottleMid = droneThrottleMid
        s.droneThrottleExpo = droneThrottleExpo
        s.droneThrustResponse = droneThrustResponse
        s.droneThrottlePower = droneThrottlePower
        s.droneCameraTilt = droneCameraTilt
        s.droneFullRotation = droneFullRotation
        s.droneGravity = droneGravity
        s.droneHoverThrottle = droneHoverThrottle
        s.droneDrag = droneDrag
        s.droneQuadDrag = droneQuadDrag
        s.droneInertia = droneInertia
        s.droneMass = droneMass
        s.droneFlightMode = droneFlightMode
        s.droneAngleMaxTilt = droneAngleMaxTilt
        s.droneAngleLevelStrength = droneAngleLevelStrength
        s.droneAngleYawCoord = droneAngleYawCoord
        s.droneMoiPitch = droneMoiPitch
        s.droneMoiRoll = droneMoiRoll
        s.droneMoiYaw = droneMoiYaw
        s.droneDragForward = droneDragForward
        s.droneDragSideways = droneDragSideways
        s.droneDragVertical = droneDragVertical
        s.droneMotorSpinUp = droneMotorSpinUp
        s.droneMotorSpinDown = droneMotorSpinDown
        s.dronePropwashStrength = dronePropwashStrength
        s.dronePropwashZone = dronePropwashZone
        s.droneGroundEffectHeight = droneGroundEffectHeight
        s.droneGroundEffectStrength = droneGroundEffectStrength
    end
end

    local function setMode(mode)
        if mode == currentMode then return end
        saveModeSettings(currentMode)
        currentMode = mode
        if mode == "Drone" then
            roll = 0
        end
        droneVelocity = Vector3.zero
        droneThrottleState = 0
        droneOrient = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, 0, roll)
        droneAngVel = Vector3.zero
        droneMotorOutput = 0
        applyModeSettings(mode)
    end

local function resetAllSettings()
    -- Reset to mode defaults
    modeSettings.Normal = {
        speed=60, sensitivity=0.20, posSmooth=10, rotSmooth=12, fovSmooth=12,
        zoomStep=3, pitchClamp=math.rad(85), rollSpeed=math.rad(80),
        boostMultiplier=3, slowMultiplier=0.25,
    }
    modeSettings.Drone = {
        speed=4.5, sensitivity=0.18, posSmooth=8, rotSmooth=10, fovSmooth=12,
        zoomStep=3, pitchClamp=math.rad(89),
        boostMultiplier=3, slowMultiplier=0.25, verticalSpeedMult=1.0,
        droneDeadzone=0.05,
        droneRollRate=360, dronePitchRate=360, droneYawRate=240,
        droneRollExpo=0.30, dronePitchExpo=0.30, droneYawExpo=0.25,
        droneRollSuper=0.50, dronePitchSuper=0.50, droneYawSuper=0.40,
        droneRateResponse=10, droneAngularDamping=0.20,
        droneThrottleMid=0.50, droneThrottleExpo=0.30, droneThrustResponse=5, droneThrottlePower=1.8, droneCameraTilt=20,
        droneFullRotation=true,
        droneGravity=196.2, droneHoverThrottle=0.50, droneDrag=0.25, droneQuadDrag=0.05, droneInertia=0.60, droneMass=1.0,
        droneFlightMode="Acro", droneAngleMaxTilt=45, droneAngleLevelStrength=8,
        droneAngleYawCoord=0.5,
        droneMoiPitch=1.0, droneMoiRoll=0.7, droneMoiYaw=1.5,
        droneDragForward=0.15, droneDragSideways=0.45, droneDragVertical=0.55,
        droneMotorSpinUp=15, droneMotorSpinDown=10,
        dronePropwashStrength=0.35, dronePropwashZone=0.40,
        droneGroundEffectHeight=3.0, droneGroundEffectStrength=0.12,
    }
    modeSettings.Gyro = {
        speed=60, sensitivity=0.25, posSmooth=12, rotSmooth=14, fovSmooth=12,
        zoomStep=3, pitchClamp=math.rad(85), rollSpeed=math.rad(80),
        boostMultiplier=3, slowMultiplier=0.25, gyroStrength=6,
    }
    applyModeSettings(currentMode)
    setFovValue(CONFIG.defaultFov)
    resetDofSettings()
    roll = 0
    droneVelocity = Vector3.zero
    droneThrottleState = 0
    droneOrient = nil
    droneAngVel = Vector3.zero
    droneMotorOutput = 0
    orbitEnabled = false
    orbitTarget = nil
    orbitTargetLabel = "None"
    orbitRadius = CONFIG.orbitDefaultDistance
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

--// SLIDER VISUAL
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
    local orbitState = orbitEnabled and "ON" or "OFF"
    local orbitTargetShort = shortenLabel(orbitTargetLabel, 18)
    uiRefs.status.Text = string.format(
        "FREECAM: %s | CURSOR: %s | UI: %s | CTRL: %s | DOF: %s | ORBIT: %s | MODE: %s%s",
        freecam and "ON" or "OFF",
        cursorUnlocked and "UNLOCK" or "LOCK",
        uiHidden and "HIDDEN" or "VISIBLE",
        controlsEnabled and "ON" or "OFF",
        dofEnabled and "ON" or "OFF",
        orbitState,
        currentMode:upper(),
        currentMode == "Drone" and (" ["..droneFlightMode:upper().."]") or ""
    )
    local speedLabel = "Speed"
    local speedValue = string.format("%d", math.floor(speed + 0.5))
    if currentMode == "Drone" then
        speedLabel = "TWR"
        speedValue = string.format("%.2f", speed)
    end
    uiRefs.stats.Text = string.format("%s: %s | FOV: %.1f | Roll: %.1f deg | Sens: %.2f | Orbit: %s (%s)",
        speedLabel,
        speedValue,
        cam.FieldOfView,
        math.deg(roll),
        sensitivity,
        orbitState,
        orbitTargetShort
    )
    uiRefs.freecamBtn.Text = freecam and "Disable Freecam" or "Enable Freecam"
    uiRefs.cursorBtn.Text = cursorUnlocked and "Lock Cursor" or "Unlock Cursor"
    uiRefs.uiBtn.Text = uiHidden and "Show UI" or "Hide UI"
    if uiRefs.orbitToggleBtn then
        uiRefs.orbitToggleBtn.Text = orbitEnabled and "Orbit Off" or "Orbit On"
    end
    if uiRefs.controlsBtn then
        uiRefs.controlsBtn.Text = controlsEnabled and "Controls Lock" or "Controls Unlock"
    end
    if uiRefs.dofToggleBtn then
        uiRefs.dofToggleBtn.Text = dofEnabled and "DOF Off" or "DOF On"
    end
    if uiRefs.stickOverlayBtn then
        uiRefs.stickOverlayBtn.Text = stickOverlayVisible and "Stick Overlay On" or "Stick Overlay Off"
    end
    updateDroneFlightModeUI()
    -- Update mode buttons
    if uiRefs.modeBtns then
        for mName, btn in pairs(uiRefs.modeBtns) do
            if mName == currentMode then
                btn.BackgroundColor3 = uiRefs.modeColors[mName]
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.BackgroundColor3 = Color3.fromRGB(36, 41, 50)
                btn.TextColor3 = Color3.fromRGB(180, 190, 205)
            end
        end
    end
    -- Update settings tab buttons
    if uiRefs.settingTabBtns then
        for tName, btn in pairs(uiRefs.settingTabBtns) do
            if tName == uiRefs.activeSettingsTab then
                btn.BackgroundColor3 = uiRefs.modeColors[tName]
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.BackgroundColor3 = Color3.fromRGB(30, 34, 43)
                btn.TextColor3 = Color3.fromRGB(160, 172, 190)
            end
        end
    end
    -- Normal tab sliders
    local nt = uiRefs.normalTabRows
    if nt then
        if nt.speed     then updateSliderVisual(nt.speed,     speed) end
        if nt.rollSpeed then updateSliderVisual(nt.rollSpeed, math.deg(rollSpeed)) end
        if nt.fov       then updateSliderVisual(nt.fov,       targetFov) end
        if nt.sens      then updateSliderVisual(nt.sens,      sensitivity) end
        if nt.posSmooth then updateSliderVisual(nt.posSmooth, posSmooth) end
        if nt.rotSmooth then updateSliderVisual(nt.rotSmooth, rotSmooth) end
        if nt.fovSmooth then updateSliderVisual(nt.fovSmooth, fovSmooth) end
        if nt.zoomStep  then updateSliderVisual(nt.zoomStep,  zoomStep) end
        if nt.pitchClamp then updateSliderVisual(nt.pitchClamp, math.deg(pitchClamp)) end
        if nt.boost     then updateSliderVisual(nt.boost,     boostMultiplier) end
        if nt.slow      then updateSliderVisual(nt.slow,      slowMultiplier) end
        if nt.dofNear   then updateSliderVisual(nt.dofNear,   dofNearIntensity) end
        if nt.dofFar    then updateSliderVisual(nt.dofFar,    dofFarIntensity) end
        if nt.dofFocus  then updateSliderVisual(nt.dofFocus,  dofFocusDistance) end
        if nt.dofRadius then updateSliderVisual(nt.dofRadius, dofInFocusRadius) end
    end
    -- Drone tab sliders
    local dt = uiRefs.droneTabRows
    if dt then
        if dt.speed     then updateSliderVisual(dt.speed,     modeSettings.Drone.speed) end
        if dt.rollRate  then updateSliderVisual(dt.rollRate,  droneRollRate) end
        if dt.pitchRate then updateSliderVisual(dt.pitchRate, dronePitchRate) end
        if dt.yawRate   then updateSliderVisual(dt.yawRate,   droneYawRate) end
        if dt.rollExpo  then updateSliderVisual(dt.rollExpo,  droneRollExpo) end
        if dt.pitchExpo then updateSliderVisual(dt.pitchExpo, dronePitchExpo) end
        if dt.yawExpo   then updateSliderVisual(dt.yawExpo,   droneYawExpo) end
        if dt.rollSuper then updateSliderVisual(dt.rollSuper, droneRollSuper) end
        if dt.pitchSuper then updateSliderVisual(dt.pitchSuper, dronePitchSuper) end
        if dt.yawSuper  then updateSliderVisual(dt.yawSuper,  droneYawSuper) end
        if dt.rateResp then updateSliderVisual(dt.rateResp, droneRateResponse) end
        if dt.angDamp then updateSliderVisual(dt.angDamp, droneAngularDamping) end
        if dt.deadzone  then updateSliderVisual(dt.deadzone,  droneDeadzone) end
        if dt.thrustMult then updateSliderVisual(dt.thrustMult, droneVertMult) end
        if dt.hoverThrottle then updateSliderVisual(dt.hoverThrottle, droneHoverThrottle) end
        if dt.throttleMid then updateSliderVisual(dt.throttleMid, droneThrottleMid) end
        if dt.throttleExpo then updateSliderVisual(dt.throttleExpo, droneThrottleExpo) end
        if dt.throttlePower then updateSliderVisual(dt.throttlePower, droneThrottlePower) end
        if dt.thrustResponse then updateSliderVisual(dt.thrustResponse, droneThrustResponse) end
        if dt.gravity  then updateSliderVisual(dt.gravity,  droneGravity) end
        if dt.drag     then updateSliderVisual(dt.drag,     droneDrag) end
        if dt.quadDrag then updateSliderVisual(dt.quadDrag, droneQuadDrag) end
        if dt.inertia  then updateSliderVisual(dt.inertia,  droneInertia) end
        if dt.mass     then updateSliderVisual(dt.mass,     droneMass) end
        if dt.fov       then updateSliderVisual(dt.fov,       targetFov) end
        if dt.fovSmooth then updateSliderVisual(dt.fovSmooth, fovSmooth) end
        if dt.zoomStep  then updateSliderVisual(dt.zoomStep,  zoomStep) end
        if dt.cameraTilt then updateSliderVisual(dt.cameraTilt, droneCameraTilt) end
        if dt.pitchClamp then updateSliderVisual(dt.pitchClamp, math.deg(pitchClamp)) end
        if dt.posSmooth then updateSliderVisual(dt.posSmooth, posSmooth) end
        if dt.rotSmooth then updateSliderVisual(dt.rotSmooth, rotSmooth) end
        if dt.moiPitch then updateSliderVisual(dt.moiPitch, droneMoiPitch) end
        if dt.moiRoll then updateSliderVisual(dt.moiRoll, droneMoiRoll) end
        if dt.moiYaw then updateSliderVisual(dt.moiYaw, droneMoiYaw) end
        if dt.dragForward then updateSliderVisual(dt.dragForward, droneDragForward) end
        if dt.dragSideways then updateSliderVisual(dt.dragSideways, droneDragSideways) end
        if dt.dragVertical then updateSliderVisual(dt.dragVertical, droneDragVertical) end
        if dt.motorSpinUp then updateSliderVisual(dt.motorSpinUp, droneMotorSpinUp) end
        if dt.motorSpinDown then updateSliderVisual(dt.motorSpinDown, droneMotorSpinDown) end
        if dt.propwashStrength then updateSliderVisual(dt.propwashStrength, dronePropwashStrength) end
        if dt.propwashZone then updateSliderVisual(dt.propwashZone, dronePropwashZone) end
        if dt.groundEffectHeight then updateSliderVisual(dt.groundEffectHeight, droneGroundEffectHeight) end
        if dt.groundEffectStrength then updateSliderVisual(dt.groundEffectStrength, droneGroundEffectStrength) end

        -- Angle mode sliders
        local at = dt._angleTabRows
        if at then
            if at.angleMaxTilt       then updateSliderVisual(at.angleMaxTilt,       droneAngleMaxTilt) end
            if at.angleLevelStrength then updateSliderVisual(at.angleLevelStrength, droneAngleLevelStrength) end
            if at.angleYawCoord      then updateSliderVisual(at.angleYawCoord,      droneAngleYawCoord) end
        end
        -- Flight mode buttons
        if uiRefs.updateFlightModeBtns then
            uiRefs.updateFlightModeBtns()
        end
        -- Show/hide angle section
        if uiRefs.droneAngleSection then
            uiRefs.droneAngleSection.Visible = (droneFlightMode == "Angle")
        end
    end
    -- Gyro tab sliders
    local gt = uiRefs.gyroTabRows
    if gt then
        if gt.speed        then updateSliderVisual(gt.speed,        speed) end
        if gt.fov          then updateSliderVisual(gt.fov,          targetFov) end
        if gt.sens         then updateSliderVisual(gt.sens,         sensitivity) end
        if gt.rotSmooth    then updateSliderVisual(gt.rotSmooth,    rotSmooth) end
        if gt.fovSmooth    then updateSliderVisual(gt.fovSmooth,    fovSmooth) end
        if gt.zoomStep     then updateSliderVisual(gt.zoomStep,     zoomStep) end
        if gt.rollSpeed    then updateSliderVisual(gt.rollSpeed,    math.deg(rollSpeed)) end
        if gt.boost        then updateSliderVisual(gt.boost,        boostMultiplier) end
        if gt.slow         then updateSliderVisual(gt.slow,         slowMultiplier) end
        if gt.gyroStrength then updateSliderVisual(gt.gyroStrength, gyroStrength) end
    end
end

--// UI
local function createControlUI()
    local old = playerGui:FindFirstChild("FreecamControlUI")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "FreecamControlUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
    panel.Position = UDim2.fromOffset(18, 18)
    panel.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Draggable = false
    panel.Parent = gui
    panel.Visible = panelVisible

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    panelStroke.Thickness = 1
    panelStroke.Color = Color3.fromRGB(72, 80, 94)
    panelStroke.Transparency = 0.2
    panelStroke.Parent = panel

    local panelGradient = Instance.new("UIGradient")
    panelGradient.Rotation = 90
    panelGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 34, 42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 19, 24)),
    })
    panelGradient.Parent = panel

    -- Stick Input Overlay
    local stickOverlay = Instance.new("Frame")
    stickOverlay.Name = "StickOverlay"
    stickOverlay.Size = UDim2.fromOffset(168, 72)
    stickOverlay.AnchorPoint = Vector2.new(0.5, 1)
    stickOverlay.Position = UDim2.new(0.5, 0, 1, -12)
    stickOverlay.BackgroundTransparency = 1
    stickOverlay.Parent = gui
    stickOverlay.Visible = stickOverlayVisible

    local stickLayout = Instance.new("UIListLayout")
    stickLayout.FillDirection = Enum.FillDirection.Horizontal
    stickLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    stickLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    stickLayout.Padding = UDim.new(0, 12)
    stickLayout.Parent = stickOverlay

    local function makeStickBox(name)
        local box = Instance.new("Frame")
        box.Name = name
        box.Size = UDim2.fromOffset(72, 72)
        box.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
        box.BackgroundTransparency = 0.25
        box.BorderSizePixel = 0
        box.Parent = stickOverlay
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.Color = Color3.fromRGB(110, 120, 135)
        stroke.Transparency = 0.55
        stroke.Parent = box

        local vLine = Instance.new("Frame")
        vLine.Name = "CenterV"
        vLine.Size = UDim2.new(0, 1, 1, -10)
        vLine.Position = UDim2.new(0.5, 0, 0, 5)
        vLine.BackgroundColor3 = Color3.fromRGB(140, 150, 165)
        vLine.BackgroundTransparency = 0.55
        vLine.BorderSizePixel = 0
        vLine.Parent = box

        local hLine = Instance.new("Frame")
        hLine.Name = "CenterH"
        hLine.Size = UDim2.new(1, -10, 0, 1)
        hLine.Position = UDim2.new(0, 5, 0.5, 0)
        hLine.BackgroundColor3 = Color3.fromRGB(140, 150, 165)
        hLine.BackgroundTransparency = 0.55
        hLine.BorderSizePixel = 0
        hLine.Parent = box

        local dot = Instance.new("Frame")
        dot.Name = "Dot"
        dot.Size = UDim2.fromOffset(10, 10)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.new(0.5, 0, 0.5, 0)
        dot.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        dot.BackgroundTransparency = 0.1
        dot.BorderSizePixel = 0
        dot.Parent = box
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        return box, dot
    end

    local leftBox, leftDot = makeStickBox("LeftStick")
    local rightBox, rightDot = makeStickBox("RightStick")

    -- Header bar
    local headerBar = Instance.new("Frame")
    headerBar.Size = UDim2.new(1, 0, 0, 36)
    headerBar.Position = UDim2.fromOffset(0, 0)
    headerBar.BackgroundColor3 = Color3.fromRGB(28, 32, 39)
    headerBar.BorderSizePixel = 0
    headerBar.Parent = panel

    local headerBarCorner = Instance.new("UICorner")
    headerBarCorner.CornerRadius = UDim.new(0, 12)
    headerBarCorner.Parent = headerBar

    local headerBarMask = Instance.new("Frame")
    headerBarMask.Size = UDim2.new(1, 0, 0, 18)
    headerBarMask.Position = UDim2.fromOffset(0, 18)
    headerBarMask.BackgroundColor3 = Color3.fromRGB(28, 32, 39)
    headerBarMask.BorderSizePixel = 0
    headerBarMask.Parent = headerBar

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

    local headerDragZone = Instance.new("Frame")
    headerDragZone.Name = "HeaderDragZone"
    headerDragZone.Size = UDim2.new(1, -140, 0, 36)
    headerDragZone.Position = UDim2.fromOffset(0, 0)
    headerDragZone.BackgroundTransparency = 1
    headerDragZone.Active = true
    headerDragZone.Draggable = false
    headerDragZone.Parent = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -140, 0, 28)
    title.Position = UDim2.fromOffset(10, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextColor3 = Color3.fromRGB(236, 238, 244)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Ultimate Freecam"
    title.Parent = panel

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.fromOffset(58, 24)
    minimizeBtn.Position = UDim2.new(1, -122, 0, 6)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(52, 61, 74)
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 12
    minimizeBtn.TextColor3 = Color3.fromRGB(235, 235, 235)
    minimizeBtn.Text = "Min"
    minimizeBtn.Parent = panel
    Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 7)

    local exitBtn = Instance.new("TextButton")
    exitBtn.Size = UDim2.fromOffset(58, 24)
    exitBtn.Position = UDim2.new(1, -60, 0, 6)
    exitBtn.BackgroundColor3 = Color3.fromRGB(150, 57, 57)
    exitBtn.BorderSizePixel = 0
    exitBtn.Font = Enum.Font.GothamBold
    exitBtn.TextSize = 12
    exitBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
    exitBtn.Text = "Exit"
    exitBtn.Parent = panel
    Instance.new("UICorner", exitBtn).CornerRadius = UDim.new(0, 7)

    local resizeHandle = Instance.new("Frame")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.Size = UDim2.fromOffset(18, 18)
    resizeHandle.AnchorPoint = Vector2.new(1, 1)
    resizeHandle.Position = UDim2.new(1, -4, 1, -4)
    resizeHandle.BackgroundColor3 = Color3.fromRGB(56, 64, 76)
    resizeHandle.BorderSizePixel = 0
    resizeHandle.Active = true
    resizeHandle.ZIndex = 5
    resizeHandle.Parent = panel
    Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0, 6)

    local resizeGlyph = Instance.new("TextLabel")
    resizeGlyph.Size = UDim2.new(1, 0, 1, 0)
    resizeGlyph.BackgroundTransparency = 1
    resizeGlyph.Font = Enum.Font.Code
    resizeGlyph.TextSize = 14
    resizeGlyph.TextColor3 = Color3.fromRGB(220, 228, 238)
    resizeGlyph.Text = "+"
    resizeGlyph.Parent = resizeHandle

    -- Content ScrollingFrame
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -16, 1, -46)
    content.Position = UDim2.fromOffset(8, 40)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.fromOffset(0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollBarThickness = 7
    content.ScrollBarImageColor3 = Color3.fromRGB(120, 130, 145)
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.Parent = panel

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 4)
    contentLayout.Parent = content

    local contentPad = Instance.new("UIPadding")
    contentPad.PaddingLeft = UDim.new(0, 4)
    contentPad.PaddingRight = UDim.new(0, 4)
    contentPad.PaddingTop = UDim.new(0, 4)
    contentPad.PaddingBottom = UDim.new(0, 8)
    contentPad.Parent = content

    -- Status bar
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 26)
    status.LayoutOrder = 1
    status.BackgroundColor3 = Color3.fromRGB(28, 33, 41)
    status.BorderSizePixel = 0
    status.Font = Enum.Font.Code
    status.TextSize = 11
    status.TextColor3 = Color3.fromRGB(218, 224, 235)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextTruncate = Enum.TextTruncate.AtEnd
    status.Parent = content
    Instance.new("UICorner", status).CornerRadius = UDim.new(0, 7)
    do
        local sp = Instance.new("UIPadding")
        sp.PaddingLeft = UDim.new(0, 8)
        sp.PaddingRight = UDim.new(0, 4)
        sp.Parent = status
    end

    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, 0, 0, 26)
    stats.LayoutOrder = 2
    stats.BackgroundColor3 = Color3.fromRGB(28, 33, 41)
    stats.BorderSizePixel = 0
    stats.Font = Enum.Font.Code
    stats.TextSize = 11
    stats.TextColor3 = Color3.fromRGB(205, 212, 226)
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.TextTruncate = Enum.TextTruncate.AtEnd
    stats.Parent = content
    Instance.new("UICorner", stats).CornerRadius = UDim.new(0, 7)
    do
        local sp = Instance.new("UIPadding")
        sp.PaddingLeft = UDim.new(0, 8)
        sp.PaddingRight = UDim.new(0, 4)
        sp.Parent = stats
    end

    ---- MODE SELECTOR ----
    local modeColors = {
        Normal = Color3.fromRGB(58, 118, 210),
        Drone  = Color3.fromRGB(48, 150, 100),
        Gyro   = Color3.fromRGB(148, 72, 190),
    }

    local modeSectionLabel = Instance.new("TextLabel")
    modeSectionLabel.Size = UDim2.new(1, 0, 0, 14)
    modeSectionLabel.LayoutOrder = 3
    modeSectionLabel.BackgroundTransparency = 1
    modeSectionLabel.Font = Enum.Font.GothamSemibold
    modeSectionLabel.TextSize = 10
    modeSectionLabel.TextColor3 = Color3.fromRGB(130, 145, 165)
    modeSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    modeSectionLabel.Text = "  CAMERA MODE"
    modeSectionLabel.Parent = content

    local modeSelectorRow = Instance.new("Frame")
    modeSelectorRow.Size = UDim2.new(1, 0, 0, 36)
    modeSelectorRow.LayoutOrder = 4
    modeSelectorRow.BackgroundColor3 = Color3.fromRGB(22, 26, 33)
    modeSelectorRow.BorderSizePixel = 0
    modeSelectorRow.Parent = content
    Instance.new("UICorner", modeSelectorRow).CornerRadius = UDim.new(0, 9)

    local modeRowLayout = Instance.new("UIListLayout")
    modeRowLayout.FillDirection = Enum.FillDirection.Horizontal
    modeRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
    modeRowLayout.Padding = UDim.new(0, 4)
    modeRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    modeRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    modeRowLayout.Parent = modeSelectorRow

    local modeRowPad = Instance.new("UIPadding")
    modeRowPad.PaddingLeft = UDim.new(0, 4)
    modeRowPad.PaddingRight = UDim.new(0, 4)
    modeRowPad.PaddingTop = UDim.new(0, 4)
    modeRowPad.PaddingBottom = UDim.new(0, 4)
    modeRowPad.Parent = modeSelectorRow

    local modeBtns = {}
    local modeOrder = {"Normal", "Drone", "Gyro"}
    local modeIcons = {Normal = "●", Drone = "◈", Gyro = "⟳"}

    local function updateModeButtonsLocal()
        for mName, btn in pairs(modeBtns) do
            if mName == currentMode then
                btn.BackgroundColor3 = modeColors[mName]
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.BackgroundColor3 = Color3.fromRGB(36, 41, 50)
                btn.TextColor3 = Color3.fromRGB(180, 190, 205)
            end
        end
    end


    for _, mName in ipairs(modeOrder) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.333, -4, 1, -8)
        btn.AutoButtonColor = false
        btn.BackgroundColor3 = Color3.fromRGB(36, 41, 50)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(180, 190, 205)
        btn.Text = modeIcons[mName] .. " " .. mName
        btn.LayoutOrder = _ 
        btn.Parent = modeSelectorRow
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local bStroke = Instance.new("UIStroke")
        bStroke.Thickness = 1
        bStroke.Color = modeColors[mName]
        bStroke.Transparency = 0.7
        bStroke.Parent = btn

        modeBtns[mName] = btn

        table.insert(connections, btn.MouseButton1Click:Connect(function()
            if scriptKilled then return end
            setMode(mName)
            updateModeButtonsLocal()
            refreshUiText()
        end))
    end
    updateModeButtonsLocal()

    ---- ACTIONS GRID ----
    local actionsSectionLabel = Instance.new("TextLabel")
    actionsSectionLabel.Size = UDim2.new(1, 0, 0, 14)
    actionsSectionLabel.LayoutOrder = 5
    actionsSectionLabel.BackgroundTransparency = 1
    actionsSectionLabel.Font = Enum.Font.GothamSemibold
    actionsSectionLabel.TextSize = 10
    actionsSectionLabel.TextColor3 = Color3.fromRGB(130, 145, 165)
    actionsSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    actionsSectionLabel.Text = "  ACTIONS"
    actionsSectionLabel.Parent = content

    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, 0, 0, 0)
    grid.LayoutOrder = 6
    grid.AutomaticSize = Enum.AutomaticSize.Y
    grid.BackgroundColor3 = Color3.fromRGB(25, 29, 36)
    grid.BorderSizePixel = 0
    grid.Parent = content
    Instance.new("UICorner", grid).CornerRadius = UDim.new(0, 9)

    local layout = Instance.new("UIGridLayout")
    layout.CellPadding = UDim2.fromOffset(5, 5)
    layout.CellSize = UDim2.new(0.5, -8, 0, 30)
    layout.FillDirectionMaxCells = 2
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = grid

    local gridPad = Instance.new("UIPadding")
    gridPad.PaddingLeft = UDim.new(0, 6)
    gridPad.PaddingTop = UDim.new(0, 6)
    gridPad.PaddingRight = UDim.new(0, 6)
    gridPad.PaddingBottom = UDim.new(0, 6)
    gridPad.Parent = grid

    local minimized = false
    local normalSize = panel.Size
    local dragging = false
    local dragStart
    local panelStart
    local resizing = false
    local resizeStart
    local resizeStartSize

    local function setPanelSizeInternal(width, height)
        panelWidth = math.floor(math.clamp(width, CONFIG.panelMinWidth, CONFIG.panelMaxWidth))
        panelHeight = math.floor(math.clamp(height, CONFIG.panelMinHeight, CONFIG.panelMaxHeight))
        normalSize = UDim2.fromOffset(panelWidth, panelHeight)
        if minimized then
            panel.Size = UDim2.fromOffset(panelWidth, 34)
        else
            panel.Size = normalSize
        end
        clampPanelToViewport()
    end

    local function makeButton(text, callback, tone)
        local b = Instance.new("TextButton")
        b.AutoButtonColor = true
        b.BackgroundColor3 = tone or Color3.fromRGB(42, 49, 61)
        b.BorderSizePixel = 0
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 12
        b.TextColor3 = Color3.fromRGB(238, 241, 247)
        b.Text = text
        b.Parent = grid
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        local bStroke = Instance.new("UIStroke")
        bStroke.Thickness = 1
        bStroke.Color = Color3.fromRGB(73, 86, 104)
        bStroke.Transparency = 0.35
        bStroke.Parent = b
        table.insert(connections, b.MouseButton1Click:Connect(function()
            if scriptKilled then return end
            callback()
            refreshUiText()
        end))
        return b
    end

    local freecamBtn = makeButton("Enable Freecam", toggleFreecam, Color3.fromRGB(42, 79, 126))
    local cursorBtn = makeButton("Unlock Cursor", function()
        if freecam then setCursorUnlocked(not cursorUnlocked) end
    end, Color3.fromRGB(55, 64, 80))
    local uiBtn = makeButton("Hide UI", function()
        if freecam then setUiHidden(not uiHidden) end
    end, Color3.fromRGB(55, 64, 80))
    local stickOverlayBtn = makeButton("Stick Overlay", function()
        setStickOverlayVisible(not stickOverlayVisible)
    end, Color3.fromRGB(64, 70, 88))
    makeButton("Hide Panel", function() setPanelVisible(false) end, Color3.fromRGB(64, 60, 84))
    local controlsBtn = makeButton("Controls Lock", function()
        if freecam then setControlsEnabled(not controlsEnabled) end
    end, Color3.fromRGB(78, 63, 51))
    local orbitToggleBtn = makeButton("Orbit On", function()
        if freecam then setOrbitEnabled(not orbitEnabled) end
    end, Color3.fromRGB(60, 86, 92))
    makeButton("Orbit Pick",  function() if freecam then pickOrbitTarget() end end, Color3.fromRGB(60, 86, 92))
    makeButton("Orbit Self",  function() if freecam then setOrbitTargetSelf() end end, Color3.fromRGB(60, 86, 92))
    makeButton("Orbit Clear", function() clearOrbitTarget() end, Color3.fromRGB(86, 62, 62))
    local dofToggleBtn = makeButton("DOF On", function() setDofEnabled(not dofEnabled) end, Color3.fromRGB(59, 76, 109))
    makeButton("DOF Reset",     function() resetDofSettings() end, Color3.fromRGB(59, 76, 109))
    makeButton("Reset All",     function() resetAllSettings() end, Color3.fromRGB(120, 68, 52))
    makeButton("UI Size +",     function() setPanelSizeInternal(panelWidth + 40, panelHeight + 40) end, Color3.fromRGB(58, 74, 96))
    makeButton("UI Size -",     function() setPanelSizeInternal(panelWidth - 40, panelHeight - 40) end, Color3.fromRGB(58, 74, 96))
    makeButton("Portrait +90",  function() if freecam then rotatePortrait90() end end)
    makeButton("Roll Reset",    function() if freecam then roll = 0 end end)
    makeButton("FOV Reset",     function() if freecam then setFovValue(CONFIG.defaultFov) end end)
    makeButton("Speed Reset",   function() if freecam then setSpeedValue(modeSettings[currentMode].speed or CONFIG.baseSpeed) end end)

    --// SHARE POPUP -------------------------------------------------------
    -- Overlay gelap di atas seluruh panel
    local shareOverlay = Instance.new("Frame")
    shareOverlay.Name        = "ShareOverlay"
    shareOverlay.Size        = UDim2.new(1, 0, 1, 0)
    shareOverlay.Position    = UDim2.fromOffset(0, 0)
    shareOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shareOverlay.BackgroundTransparency = 0.35
    shareOverlay.BorderSizePixel = 0
    shareOverlay.ZIndex      = 20
    shareOverlay.Visible     = false
    shareOverlay.Active      = true
    shareOverlay.Parent      = gui

    -- Card di tengah overlay
    local shareCard = Instance.new("Frame")
    shareCard.Size          = UDim2.fromOffset(440, 272)
    shareCard.AnchorPoint   = Vector2.new(0.5, 0.5)
    shareCard.Position      = UDim2.new(0.5, 0, 0.5, 0)
    shareCard.BackgroundColor3 = Color3.fromRGB(20, 24, 31)
    shareCard.BorderSizePixel = 0
    shareCard.ZIndex        = 21
    shareCard.Parent        = shareOverlay
    Instance.new("UICorner", shareCard).CornerRadius = UDim.new(0, 14)
    do
        local s = Instance.new("UIStroke")
        s.Thickness  = 1.2
        s.Color      = Color3.fromRGB(75, 95, 120)
        s.Transparency = 0.15
        s.Parent     = shareCard
    end
    do
        local g = Instance.new("UIGradient")
        g.Rotation = 120
        g.Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 33, 44)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 19, 26)),
        })
        g.Parent = shareCard
    end

    -- Judul
    local shareTitle = Instance.new("TextLabel")
    shareTitle.Size            = UDim2.new(1, -16, 0, 28)
    shareTitle.Position        = UDim2.fromOffset(14, 12)
    shareTitle.BackgroundTransparency = 1
    shareTitle.Font            = Enum.Font.GothamBold
    shareTitle.TextSize        = 14
    shareTitle.TextColor3      = Color3.fromRGB(225, 232, 248)
    shareTitle.TextXAlignment  = Enum.TextXAlignment.Left
    shareTitle.Text            = "Share Settings"
    shareTitle.ZIndex          = 22
    shareTitle.Parent          = shareCard

    -- Keterangan
    local shareInfo = Instance.new("TextLabel")
    shareInfo.Size            = UDim2.new(1, -16, 0, 32)
    shareInfo.Position        = UDim2.fromOffset(14, 40)
    shareInfo.BackgroundTransparency = 1
    shareInfo.Font            = Enum.Font.Gotham
    shareInfo.TextSize        = 11
    shareInfo.TextColor3      = Color3.fromRGB(135, 152, 178)
    shareInfo.TextXAlignment  = Enum.TextXAlignment.Left
    shareInfo.TextWrapped     = true
    shareInfo.Text            = ""
    shareInfo.ZIndex          = 22
    shareInfo.Parent          = shareCard

    -- TextBox kode settingan
    local shareBox = Instance.new("TextBox")
    shareBox.Size             = UDim2.new(1, -28, 0, 88)
    shareBox.Position         = UDim2.fromOffset(14, 76)
    shareBox.BackgroundColor3 = Color3.fromRGB(12, 15, 20)
    shareBox.BorderSizePixel  = 0
    shareBox.Font             = Enum.Font.Code
    shareBox.TextSize         = 10
    shareBox.TextColor3       = Color3.fromRGB(165, 215, 140)
    shareBox.TextXAlignment   = Enum.TextXAlignment.Left
    shareBox.TextYAlignment   = Enum.TextYAlignment.Top
    shareBox.MultiLine        = true
    shareBox.ClearTextOnFocus = false
    shareBox.Text             = ""
    shareBox.ZIndex           = 22
    shareBox.Parent           = shareCard
    Instance.new("UICorner", shareBox).CornerRadius = UDim.new(0, 8)
    do
        local s = Instance.new("UIStroke")
        s.Thickness   = 1
        s.Color       = Color3.fromRGB(55, 80, 105)
        s.Transparency = 0.25
        s.Parent      = shareBox
    end
    do
        local p = Instance.new("UIPadding")
        p.PaddingLeft  = UDim.new(0, 7)
        p.PaddingTop   = UDim.new(0, 6)
        p.Parent       = shareBox
    end

    -- Status feedback
    local shareStatus = Instance.new("TextLabel")
    shareStatus.Size            = UDim2.new(1, -16, 0, 18)
    shareStatus.Position        = UDim2.fromOffset(14, 170)
    shareStatus.BackgroundTransparency = 1
    shareStatus.Font            = Enum.Font.Gotham
    shareStatus.TextSize        = 11
    shareStatus.TextColor3      = Color3.fromRGB(110, 200, 125)
    shareStatus.TextXAlignment  = Enum.TextXAlignment.Left
    shareStatus.Text            = ""
    shareStatus.ZIndex          = 22
    shareStatus.Parent          = shareCard

    -- Row tombol-tombol
    local shareBtnRow = Instance.new("Frame")
    shareBtnRow.Size              = UDim2.new(1, -28, 0, 34)
    shareBtnRow.Position          = UDim2.fromOffset(14, 194)
    shareBtnRow.BackgroundTransparency = 1
    shareBtnRow.ZIndex            = 22
    shareBtnRow.Parent            = shareCard
    do
        local l = Instance.new("UIListLayout")
        l.FillDirection   = Enum.FillDirection.Horizontal
        l.SortOrder       = Enum.SortOrder.LayoutOrder
        l.Padding         = UDim.new(0, 8)
        l.VerticalAlignment = Enum.VerticalAlignment.Center
        l.Parent          = shareBtnRow
    end

    local function makeShareBtn(text, color, order, cb)
        local b = Instance.new("TextButton")
        b.AutoButtonColor = true
        b.Size            = UDim2.fromOffset(130, 30)
        b.BackgroundColor3 = color
        b.BorderSizePixel = 0
        b.Font            = Enum.Font.GothamSemibold
        b.TextSize        = 11
        b.TextColor3      = Color3.fromRGB(238, 242, 250)
        b.Text            = text
        b.LayoutOrder     = order
        b.ZIndex          = 23
        b.Parent          = shareBtnRow
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
        table.insert(connections, b.MouseButton1Click:Connect(function()
            if scriptKilled then return end
            cb()
        end))
        return b
    end

    local function setShareStatus(msg, isError)
        shareStatus.Text = msg
        shareStatus.TextColor3 = isError
            and Color3.fromRGB(225, 90, 80)
            or  Color3.fromRGB(100, 215, 128)
    end

    -- Tombol: Salin ke Clipboard
    makeShareBtn("Copy Clipboard", Color3.fromRGB(35, 88, 58), 1, function()
        local str = shareBox.Text
        if str == "" then
            setShareStatus("Tidak ada teks untuk disalin.", true)
            return
        end
        local clipOk = pcall(function() setclipboard(str) end)
        if clipOk then
            setShareStatus("Tersalin ke clipboard!", false)
        else
            -- Fallback: fokus & select agar user bisa Ctrl+C manual
            shareBox:CaptureFocus()
            setShareStatus("Pilih semua teks lalu tekan Ctrl+C untuk menyalin.", false)
        end
    end)

    -- Tombol: Terapkan settingan dari box
    makeShareBtn("Terapkan", Color3.fromRGB(45, 55, 105), 2, function()
        local ok, msg = applySettingsString(shareBox.Text)
        setShareStatus(msg, not ok)
    end)

    -- Tombol: Tutup popup
    makeShareBtn("Tutup", Color3.fromRGB(100, 38, 38), 3, function()
        shareOverlay.Visible = false
    end)

    -- Fungsi pembuka popup (dipanggil oleh kedua tombol di grid)
    local function showSharePopup(exportStr)
        setShareStatus("", false)
        if exportStr then
            shareTitle.Text = "Export Settings"
            shareInfo.Text  = "Salin teks ini dan bagikan ke orang lain. Mereka cukup klik 'Paste Settings' lalu tempel di sini."
            shareBox.Text   = exportStr
            -- Coba auto-copy ke clipboard
            task.defer(function()
                local clipOk = pcall(function() setclipboard(exportStr) end)
                shareBox:CaptureFocus()
                if clipOk then
                    setShareStatus("Otomatis tersalin ke clipboard!", false)
                end
            end)
        else
            shareTitle.Text = "Import Settings"
            shareInfo.Text  = "Tempel (Ctrl+V) kode settingan dari orang lain di sini, lalu klik Terapkan."
            shareBox.Text   = ""
            task.defer(function()
                shareBox:CaptureFocus()
            end)
        end
        shareOverlay.Visible = true
    end

    -- Dua tombol di action grid
    makeButton("Copy Settings", function()
        showSharePopup(serializeSettings())
    end, Color3.fromRGB(35, 82, 55))
    makeButton("Paste Settings", function()
        showSharePopup(nil)
    end, Color3.fromRGB(62, 50, 100))
    -- ----------------------------------------------------------------------

    ---- SETTINGS TABS ----
    local settingsSectionLabel = Instance.new("TextLabel")
    settingsSectionLabel.Size = UDim2.new(1, 0, 0, 14)
    settingsSectionLabel.LayoutOrder = 7
    settingsSectionLabel.BackgroundTransparency = 1
    settingsSectionLabel.Font = Enum.Font.GothamSemibold
    settingsSectionLabel.TextSize = 10
    settingsSectionLabel.TextColor3 = Color3.fromRGB(130, 145, 165)
    settingsSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    settingsSectionLabel.Text = "  SETTINGS"
    settingsSectionLabel.Parent = content

    -- Tab bar
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 34)
    tabBar.LayoutOrder = 8
    tabBar.BackgroundColor3 = Color3.fromRGB(22, 26, 33)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = content
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 9)

    local tabBarLayout = Instance.new("UIListLayout")
    tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
    tabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabBarLayout.Padding = UDim.new(0, 4)
    tabBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    tabBarLayout.Parent = tabBar

    local tabBarPad = Instance.new("UIPadding")
    tabBarPad.PaddingLeft = UDim.new(0, 4)
    tabBarPad.PaddingRight = UDim.new(0, 4)
    tabBarPad.PaddingTop = UDim.new(0, 4)
    tabBarPad.PaddingBottom = UDim.new(0, 4)
    tabBarPad.Parent = tabBar

    local activeSettingsTab = "Normal"
    local settingTabBtns = {}
    local settingTabFrames = {}

    local tabIcons = {Normal = "●", Drone = "◈", Gyro = "⟳"}

    for _, tName in ipairs(modeOrder) do
        local tbtn = Instance.new("TextButton")
        tbtn.Size = UDim2.new(0.333, -4, 1, -8)
        tbtn.AutoButtonColor = false
        tbtn.BackgroundColor3 = Color3.fromRGB(30, 34, 43)
        tbtn.BorderSizePixel = 0
        tbtn.Font = Enum.Font.GothamBold
        tbtn.TextSize = 11
        tbtn.TextColor3 = Color3.fromRGB(160, 172, 190)
        tbtn.Text = tabIcons[tName] .. " " .. tName
        tbtn.LayoutOrder = _
        tbtn.Parent = tabBar
        Instance.new("UICorner", tbtn).CornerRadius = UDim.new(0, 6)
        settingTabBtns[tName] = tbtn

        local tabFrame = Instance.new("Frame")
        tabFrame.Name = "Tab_" .. tName
        tabFrame.Size = UDim2.new(1, 0, 0, 0)
        tabFrame.LayoutOrder = 9
        tabFrame.BackgroundColor3 = Color3.fromRGB(25, 29, 36)
        tabFrame.BorderSizePixel = 0
        tabFrame.AutomaticSize = Enum.AutomaticSize.Y
        tabFrame.Visible = (tName == "Normal")
        tabFrame.Parent = content
        Instance.new("UICorner", tabFrame).CornerRadius = UDim.new(0, 9)
        settingTabFrames[tName] = tabFrame
    end


    local function updateSettingsTabButtonsLocal()
        for tName, btn in pairs(settingTabBtns) do
            if tName == activeSettingsTab then
                btn.BackgroundColor3 = modeColors[tName]
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.BackgroundColor3 = Color3.fromRGB(30, 34, 43)
                btn.TextColor3 = Color3.fromRGB(160, 172, 190)
            end
        end
    end

    local function setSettingsTab(name)
        activeSettingsTab = name
        updateSettingsTabButtonsLocal()
        for n, f in pairs(settingTabFrames) do
            f.Visible = (n == name)
        end
        refreshUiText()
    end

    for _, tName in ipairs(modeOrder) do
        local tbtn = settingTabBtns[tName]
        table.insert(connections, tbtn.MouseButton1Click:Connect(function()
            if scriptKilled then return end
            setSettingsTab(tName)
        end))
    end

    ---- SLIDER HELPERS ----
    local activeSliderRow = nil

    local function createSliderRow(parent, labelText, minVal, maxVal, getValue, setValue, formatValue, accentColor)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = Color3.fromRGB(32, 37, 46)
        row.BorderSizePixel = 0
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromOffset(126, 20)
        label.Position = UDim2.fromOffset(8, 9)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 11
        label.TextColor3 = Color3.fromRGB(200, 208, 220)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = labelText
        label.Parent = row

        local box = Instance.new("TextBox")
        box.Size = UDim2.fromOffset(68, 24)
        box.Position = UDim2.new(1, -76, 0, 7)
        box.BackgroundColor3 = Color3.fromRGB(22, 26, 33)
        box.BorderSizePixel = 0
        box.Font = Enum.Font.Code
        box.TextSize = 12
        box.TextColor3 = Color3.fromRGB(235, 235, 235)
        box.ClearTextOnFocus = false
        box.Text = formatValue(getValue())
        box.Parent = row
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

        local barBg = Instance.new("Frame")
        barBg.Size = UDim2.new(1, -214, 0, 8)
        barBg.Position = UDim2.fromOffset(138, 15)
        barBg.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
        barBg.BorderSizePixel = 0
        barBg.Parent = row
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = accentColor or Color3.fromRGB(78, 155, 255)
        fill.BorderSizePixel = 0
        fill.Parent = barBg
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(12, 12)
        knob.Position = UDim2.new(0, -6, 0.5, -6)
        knob.BackgroundColor3 = Color3.fromRGB(230, 238, 248)
        knob.BorderSizePixel = 0
        knob.Parent = barBg
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local function setFromX(xPos)
            local left = barBg.AbsolutePosition.X
            local width = barBg.AbsoluteSize.X
            if width <= 0 then return end
            local t = math.clamp((xPos - left) / width, 0, 1)
            local raw = minVal + (maxVal - minVal) * t
            setValue(raw)
            refreshUiText()
        end

        table.insert(connections, barBg.InputBegan:Connect(function(input)
            if scriptKilled then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                activeSliderRow = { setFromX = setFromX }
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
            if n then setValue(n) end
            refreshUiText()
        end))

        return { min=minVal, max=maxVal, box=box, fill=fill, knob=knob, format=formatValue }
    end

    -- Helper to build a labeled slider section header inside a tab frame
    local function makeTabSection(parent, title, color)
        local header = Instance.new("TextLabel")
        header.Size = UDim2.new(1, -12, 0, 22)
        header.BackgroundColor3 = Color3.new(0,0,0)
        header.BackgroundTransparency = 0.6
        header.BorderSizePixel = 0
        header.Font = Enum.Font.GothamBold
        header.TextSize = 10
        header.TextColor3 = color or Color3.fromRGB(160, 200, 255)
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Text = "  " .. title
        header.Parent = parent
        Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)
        return header
    end

    local normalTabRowsRef = {}
    local droneTabRowsRef  = {}
    local gyroTabRowsRef   = {}

    ---- NORMAL TAB ----
    do
        local tf = settingTabFrames.Normal
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = tf
        local lpad = Instance.new("UIPadding")
        lpad.PaddingLeft = UDim.new(0,6)
        lpad.PaddingRight = UDim.new(0,6)
        lpad.PaddingTop = UDim.new(0,6)
        lpad.PaddingBottom = UDim.new(0,6)
        lpad.Parent = tf

        local accent = Color3.fromRGB(78, 155, 255)
        makeTabSection(tf, "Movement", accent)
        local normalTabRows = {}

        normalTabRows.speed = createSliderRow(tf, "Speed", CONFIG.minSpeed, CONFIG.maxSpeed,
            function() return speed end, setSpeedValue,
            function(v) return string.format("%.0f", v) end, accent)
        normalTabRows.sens = createSliderRow(tf, "Sensitivity", 0.02, 1.5,
            function() return sensitivity end, setSensitivityValue,
            function(v) return string.format("%.2f", v) end, accent)
        normalTabRows.boost = createSliderRow(tf, "Boost ×", 1, 8,
            function() return boostMultiplier end, setBoostMultiplierValue,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(255, 180, 60))
        normalTabRows.slow = createSliderRow(tf, "Slow ×", 0.05, 1,
            function() return slowMultiplier end, setSlowMultiplierValue,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(100, 200, 130))

        makeTabSection(tf, "Camera", Color3.fromRGB(160, 200, 255))
        normalTabRows.fov = createSliderRow(tf, "FOV", CONFIG.minFov, CONFIG.maxFov,
            function() return targetFov end, setFovValue,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(255, 140, 80))
        normalTabRows.fovSmooth = createSliderRow(tf, "FOV Smooth", 1, 40,
            function() return fovSmooth end, setFovSmoothValue,
            function(v) return string.format("%.1f", v) end, accent)
        normalTabRows.zoomStep = createSliderRow(tf, "Zoom Step", 0.2, 20,
            function() return zoomStep end, setZoomStepValue,
            function(v) return string.format("%.2f", v) end, accent)
        normalTabRows.pitchClamp = createSliderRow(tf, "Pitch Clamp°", 30, 89,
            function() return math.deg(pitchClamp) end, setPitchClampDeg,
            function(v) return string.format("%.0f", v) end, accent)

        makeTabSection(tf, "Smoothing", Color3.fromRGB(160, 200, 255))
        normalTabRows.posSmooth = createSliderRow(tf, "Pos Smooth", 1, 40,
            function() return posSmooth end, setPosSmoothValue,
            function(v) return string.format("%.1f", v) end, accent)
        normalTabRows.rotSmooth = createSliderRow(tf, "Rot Smooth", 1, 40,
            function() return rotSmooth end, setRotSmoothValue,
            function(v) return string.format("%.1f", v) end, accent)

        makeTabSection(tf, "Roll", Color3.fromRGB(200, 160, 255))
        normalTabRows.rollSpeed = createSliderRow(tf, "Roll Speed°/s", math.deg(CONFIG.minRollSpeed), math.deg(CONFIG.maxRollSpeed),
            function() return math.deg(rollSpeed) end, setRollSpeedDeg,
            function(v) return string.format("%.0f", v) end, Color3.fromRGB(180, 100, 255))

        makeTabSection(tf, "Depth of Field", Color3.fromRGB(100, 200, 220))
        normalTabRows.dofNear = createSliderRow(tf, "DOF Near", 0, 1,
            function() return dofNearIntensity end, setDofNearIntensity,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(80, 200, 200))
        normalTabRows.dofFar = createSliderRow(tf, "DOF Far", 0, 1,
            function() return dofFarIntensity end, setDofFarIntensity,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(80, 200, 200))
        normalTabRows.dofFocus = createSliderRow(tf, "DOF Focus", CONFIG.dofMinDistance, CONFIG.dofMaxDistance,
            function() return dofFocusDistance end, setDofFocusDistance,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(80, 200, 200))
        normalTabRows.dofRadius = createSliderRow(tf, "DOF Radius", 0, CONFIG.dofMaxDistance,
            function() return dofInFocusRadius end, setDofInFocusRadius,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(80, 200, 200))

        normalTabRowsRef = normalTabRows
    end

    ---- DRONE TAB ----
    do
        local tf = settingTabFrames.Drone
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = tf
        local lpad = Instance.new("UIPadding")
        lpad.PaddingLeft = UDim.new(0,6)
        lpad.PaddingRight = UDim.new(0,6)
        lpad.PaddingTop = UDim.new(0,6)
        lpad.PaddingBottom = UDim.new(0,6)
        lpad.Parent = tf

        local accent = Color3.fromRGB(60, 200, 130)

        local droneInfo = Instance.new("TextLabel")
        droneInfo.Size = UDim2.new(1, -12, 0, 32)
        droneInfo.BackgroundColor3 = Color3.fromRGB(30, 50, 40)
        droneInfo.BorderSizePixel = 0
        droneInfo.Font = Enum.Font.Code
        droneInfo.TextSize = 10
        droneInfo.TextColor3 = Color3.fromRGB(130, 220, 160)
        droneInfo.TextXAlignment = Enum.TextXAlignment.Left
        droneInfo.TextYAlignment = Enum.TextYAlignment.Center
        droneInfo.Text = "  DRONE FPV  -  LS = Roll/Throttle | RS = Pitch/Yaw\n  Full rotation + physics (TWR, gravity, drag, inertia)"
        droneInfo.Parent = tf
        Instance.new("UICorner", droneInfo).CornerRadius = UDim.new(0, 7)

        -- ---- DRONE FLIGHT MODE SELECTOR ----
        local flightModeLabel = Instance.new("TextLabel")
        flightModeLabel.Size = UDim2.new(1, -12, 0, 22)
        flightModeLabel.BackgroundColor3 = Color3.new(0,0,0)
        flightModeLabel.BackgroundTransparency = 0.6
        flightModeLabel.BorderSizePixel = 0
        flightModeLabel.Font = Enum.Font.GothamBold
        flightModeLabel.TextSize = 10
        flightModeLabel.TextColor3 = accent
        flightModeLabel.TextXAlignment = Enum.TextXAlignment.Left
        flightModeLabel.Text = "  FLIGHT MODE"
        flightModeLabel.Parent = tf
        Instance.new("UICorner", flightModeLabel).CornerRadius = UDim.new(0, 6)

        local flightModeRow = Instance.new("Frame")
        flightModeRow.Size = UDim2.new(1, -12, 0, 40)
        flightModeRow.BackgroundColor3 = Color3.fromRGB(22, 36, 30)
        flightModeRow.BorderSizePixel = 0
        flightModeRow.Parent = tf
        Instance.new("UICorner", flightModeRow).CornerRadius = UDim.new(0, 9)
        local fmStroke = Instance.new("UIStroke")
        fmStroke.Thickness = 1
        fmStroke.Color = accent
        fmStroke.Transparency = 0.6
        fmStroke.Parent = flightModeRow

        local fmRowLayout = Instance.new("UIListLayout")
        fmRowLayout.FillDirection = Enum.FillDirection.Horizontal
        fmRowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        fmRowLayout.Padding = UDim.new(0, 4)
        fmRowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        fmRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        fmRowLayout.Parent = flightModeRow

        local fmPad = Instance.new("UIPadding")
        fmPad.PaddingLeft  = UDim.new(0, 4)
        fmPad.PaddingRight = UDim.new(0, 4)
        fmPad.PaddingTop   = UDim.new(0, 5)
        fmPad.PaddingBottom = UDim.new(0, 5)
        fmPad.Parent = flightModeRow

        -- Flight mode definitions: name, description color, tooltip
        local flightModes = {
            { name = "Acro",  icon = "⚡", color = Color3.fromRGB(60, 200, 130),  desc = "Full manual, no auto-level" },
            { name = "Angle", icon = "⊿", color = Color3.fromRGB(255, 200, 60),   desc = "Auto-level, tilt limit" },
            { name = "3D",    icon = "∞", color = Color3.fromRGB(255, 100, 130),   desc = "Inverted flight, reverse thrust" },
        }
        local droneFlightModeBtns = {}

        local function updateFlightModeBtns()
            for _, fm in ipairs(flightModes) do
                local btn = droneFlightModeBtns[fm.name]
                if btn then
                    if droneFlightMode == fm.name then
                        btn.BackgroundColor3 = fm.color
                        btn.TextColor3 = Color3.fromRGB(15, 15, 15)
                    else
                        btn.BackgroundColor3 = Color3.fromRGB(28, 36, 32)
                        btn.TextColor3 = Color3.fromRGB(170, 190, 180)
                    end
                end
            end
        end

        for i, fm in ipairs(flightModes) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.333, -4, 1, 0)
            btn.AutoButtonColor = false
            btn.BackgroundColor3 = Color3.fromRGB(28, 36, 32)
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 11
            btn.TextColor3 = Color3.fromRGB(170, 190, 180)
            btn.Text = fm.icon .. " " .. fm.name
            btn.LayoutOrder = i
            btn.Parent = flightModeRow
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            local bStroke2 = Instance.new("UIStroke")
            bStroke2.Thickness = 1
            bStroke2.Color = fm.color
            bStroke2.Transparency = 0.55
            bStroke2.Parent = btn
            droneFlightModeBtns[fm.name] = btn
            table.insert(connections, btn.MouseButton1Click:Connect(function()
                if scriptKilled then return end
                setDroneFlightMode(fm.name)
                updateFlightModeBtns()
                -- Show/hide angle-mode settings
                if uiRefs.droneAngleSection then
                    uiRefs.droneAngleSection.Visible = (droneFlightMode == "Angle")
                end
                refreshUiText()
            end))
        end

        -- Flight mode description label
        local fmDescLabel = Instance.new("TextLabel")
        fmDescLabel.Size = UDim2.new(1, -12, 0, 18)
        fmDescLabel.BackgroundTransparency = 1
        fmDescLabel.Font = Enum.Font.Code
        fmDescLabel.TextSize = 10
        fmDescLabel.TextColor3 = Color3.fromRGB(140, 200, 165)
        fmDescLabel.TextXAlignment = Enum.TextXAlignment.Center
        fmDescLabel.Text = "⚡ Acro: manual penuh  |  ⊿ Angle: auto-level  |  ∞ 3D: thrust terbalik"
        fmDescLabel.Parent = tf

        -- Angle mode specific settings (visible only when Angle is selected)
        local angleSectionFrame = Instance.new("Frame")
        angleSectionFrame.Size = UDim2.new(1, 0, 0, 0)
        angleSectionFrame.BackgroundTransparency = 1
        angleSectionFrame.AutomaticSize = Enum.AutomaticSize.Y
        angleSectionFrame.BorderSizePixel = 0
        angleSectionFrame.Visible = (droneFlightMode == "Angle")
        angleSectionFrame.Parent = tf

        local angleSectionLayout = Instance.new("UIListLayout")
        angleSectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        angleSectionLayout.Padding = UDim.new(0, 2)
        angleSectionLayout.Parent = angleSectionFrame

        local angleAccent = Color3.fromRGB(255, 200, 60)
        makeTabSection(angleSectionFrame, "Angle Mode Settings", angleAccent)
        local angleTabRows = {}
        angleTabRows.angleMaxTilt = createSliderRow(angleSectionFrame, "Max Tilt°", 5, 85,
            function() return droneAngleMaxTilt end, setDroneAngleMaxTilt,
            function(v) return string.format("%.0f", v) end, angleAccent)
        angleTabRows.angleLevelStrength = createSliderRow(angleSectionFrame, "Level Strength", 0.5, 20,
            function() return droneAngleLevelStrength end, setDroneAngleLevelStrength,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(255, 120, 100))
        angleTabRows.angleYawCoord = createSliderRow(angleSectionFrame, "Coord Turn", 0, 1,
            function() return droneAngleYawCoord end, setDroneAngleYawCoord,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(255, 120, 100))

        local droneTabRows = {}

        makeTabSection(tf, "Rates (deg/s)", accent)
        droneTabRows.rollRate = createSliderRow(tf, "Roll Rate", 50, 1200,
            function() return droneRollRate end, setDroneRollRate,
            function(v) return string.format("%.0f", v) end, accent)
        droneTabRows.pitchRate = createSliderRow(tf, "Pitch Rate", 50, 1200,
            function() return dronePitchRate end, setDronePitchRate,
            function(v) return string.format("%.0f", v) end, accent)
        droneTabRows.yawRate = createSliderRow(tf, "Yaw Rate", 50, 1200,
            function() return droneYawRate end, setDroneYawRate,
            function(v) return string.format("%.0f", v) end, accent)

        makeTabSection(tf, "Expo", accent)
        droneTabRows.rollExpo = createSliderRow(tf, "Roll Expo", 0, 1,
            function() return droneRollExpo end, setDroneRollExpo,
            function(v) return string.format("%.2f", v) end, accent)
        droneTabRows.pitchExpo = createSliderRow(tf, "Pitch Expo", 0, 1,
            function() return dronePitchExpo end, setDronePitchExpo,
            function(v) return string.format("%.2f", v) end, accent)
        droneTabRows.yawExpo = createSliderRow(tf, "Yaw Expo", 0, 1,
            function() return droneYawExpo end, setDroneYawExpo,
            function(v) return string.format("%.2f", v) end, accent)

        makeTabSection(tf, "Super Rate", accent)
        droneTabRows.rollSuper = createSliderRow(tf, "Roll Super", 0, 1,
            function() return droneRollSuper end, setDroneRollSuper,
            function(v) return string.format("%.2f", v) end, accent)
        droneTabRows.pitchSuper = createSliderRow(tf, "Pitch Super", 0, 1,
            function() return dronePitchSuper end, setDronePitchSuper,
            function(v) return string.format("%.2f", v) end, accent)
        droneTabRows.yawSuper = createSliderRow(tf, "Yaw Super", 0, 1,
            function() return droneYawSuper end, setDroneYawSuper,
            function(v) return string.format("%.2f", v) end, accent)

        makeTabSection(tf, "Dynamics", accent)
        droneTabRows.rateResp = createSliderRow(tf, "Rate Resp", 1, 25,
            function() return droneRateResponse end, setDroneRateResponse,
            function(v) return string.format("%.1f", v) end, accent)
        droneTabRows.angDamp = createSliderRow(tf, "Ang Damping", 0, 5,
            function() return droneAngularDamping end, setDroneAngularDamping,
            function(v) return string.format("%.2f", v) end, accent)

        makeTabSection(tf, "Moment of Inertia", Color3.fromRGB(180, 160, 255))
        droneTabRows.moiPitch = createSliderRow(tf, "MOI Pitch", 0.2, 5,
            function() return droneMoiPitch end, setDroneMoiPitch,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(180, 160, 255))
        droneTabRows.moiRoll = createSliderRow(tf, "MOI Roll", 0.2, 5,
            function() return droneMoiRoll end, setDroneMoiRoll,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(180, 160, 255))
        droneTabRows.moiYaw = createSliderRow(tf, "MOI Yaw", 0.2, 5,
            function() return droneMoiYaw end, setDroneMoiYaw,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(180, 160, 255))

        makeTabSection(tf, "Throttle", accent)
        droneTabRows.speed = createSliderRow(tf, "TWR (Max)", 1, 12,
            function() return modeSettings.Drone.speed end, setDroneTwr,
            function(v) return string.format("%.2f", v) end, accent)
        droneTabRows.thrustMult = createSliderRow(tf, "Thrust x", 0.1, 3,
            function() return droneVertMult end, setDroneVertMult,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(80, 220, 150))
        droneTabRows.hoverThrottle = createSliderRow(tf, "Hover Throttle", 0.05, 0.95,
            function() return droneHoverThrottle end, setDroneHoverThrottle,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(140, 220, 180))
        droneTabRows.throttleMid = createSliderRow(tf, "Throttle Mid", 0.05, 0.95,
            function() return droneThrottleMid end, setDroneThrottleMid,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(255, 180, 60))
        droneTabRows.throttleExpo = createSliderRow(tf, "Throttle Expo", 0, 1,
            function() return droneThrottleExpo end, setDroneThrottleExpo,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(255, 180, 60))
        droneTabRows.throttlePower = createSliderRow(tf, "Throttle Power", 1, 3,
            function() return droneThrottlePower end, setDroneThrottlePower,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(255, 180, 60))
        droneTabRows.thrustResponse = createSliderRow(tf, "Motor Resp", 1, 25,
            function() return droneThrustResponse end, setDroneThrustResponse,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(120, 210, 160))
        droneTabRows.motorSpinUp = createSliderRow(tf, "Motor Spool Up", 1, 30,
            function() return droneMotorSpinUp end, setDroneMotorSpinUp,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(120, 210, 160))
        droneTabRows.motorSpinDown = createSliderRow(tf, "Motor Spool Dn", 1, 30,
            function() return droneMotorSpinDown end, setDroneMotorSpinDown,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(120, 210, 160))

        makeTabSection(tf, "Input", accent)
        droneTabRows.deadzone = createSliderRow(tf, "Stick Deadzone", 0, 0.3,
            function() return droneDeadzone end, setDroneDeadzone,
            function(v) return string.format("%.2f", v) end, accent)

        makeTabSection(tf, "Physics", accent)
        droneTabRows.gravity = createSliderRow(tf, "Gravity", 0, 400,
            function() return droneGravity end, setDroneGravity,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(160, 200, 255))
        droneTabRows.drag = createSliderRow(tf, "Air Drag", 0, 3,
            function() return droneDrag end, setDroneDrag,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(160, 200, 255))
        droneTabRows.quadDrag = createSliderRow(tf, "Quad Drag", 0, 0.2,
            function() return droneQuadDrag end, setDroneQuadDrag,
            function(v) return string.format("%.3f", v) end, Color3.fromRGB(160, 200, 255))
        droneTabRows.inertia = createSliderRow(tf, "Inertia", 0, 1,
            function() return droneInertia end, setDroneInertia,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(160, 200, 255))
        droneTabRows.mass = createSliderRow(tf, "Mass", 0.2, 8,
            function() return droneMass end, setDroneMass,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(160, 200, 255))

        makeTabSection(tf, "Airflow Dynamics", Color3.fromRGB(200, 230, 255))
        droneTabRows.dragForward = createSliderRow(tf, "Drag Fwd", 0, 3,
            function() return droneDragForward end, setDroneDragForward,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(200, 230, 255))
        droneTabRows.dragSideways = createSliderRow(tf, "Drag Side", 0, 3,
            function() return droneDragSideways end, setDroneDragSideways,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(200, 230, 255))
        droneTabRows.dragVertical = createSliderRow(tf, "Drag Vert", 0, 3,
            function() return droneDragVertical end, setDroneDragVertical,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(200, 230, 255))
        droneTabRows.propwashStrength = createSliderRow(tf, "Propwash", 0, 1,
            function() return dronePropwashStrength end, setDronePropwashStrength,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(200, 230, 255))
        droneTabRows.propwashZone = createSliderRow(tf, "PW Zone", 0, 1,
            function() return dronePropwashZone end, setDronePropwashZone,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(200, 230, 255))
        droneTabRows.groundEffectHeight = createSliderRow(tf, "G-Eff Ht", 0, 20,
            function() return droneGroundEffectHeight end, setDroneGroundEffectHeight,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(200, 230, 255))
        droneTabRows.groundEffectStrength = createSliderRow(tf, "G-Eff Str", 0, 0.5,
            function() return droneGroundEffectStrength end, setDroneGroundEffectStrength,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(200, 230, 255))

        makeTabSection(tf, "Camera", accent)
        droneTabRows.fov = createSliderRow(tf, "FOV", CONFIG.minFov, CONFIG.maxFov,
            function() return targetFov end, setFovValue,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(255, 140, 80))
        droneTabRows.fovSmooth = createSliderRow(tf, "FOV Smooth", 1, 40,
            function() return fovSmooth end, setFovSmoothValue,
            function(v) return string.format("%.1f", v) end, accent)
        droneTabRows.zoomStep = createSliderRow(tf, "Zoom Step", 0.2, 20,
            function() return zoomStep end, setZoomStepValue,
            function(v) return string.format("%.2f", v) end, accent)
        droneTabRows.cameraTilt = createSliderRow(tf, "Camera Tilt°", 0, 60,
            function() return droneCameraTilt end, setDroneCameraTilt,
            function(v) return string.format("%.0f", v) end, accent)
        droneTabRows.pitchClamp = createSliderRow(tf, "Pitch Clamp", 30, 89,
            function() return math.deg(pitchClamp) end, setPitchClampDeg,
            function(v) return string.format("%.0f", v) end, accent)

        makeTabSection(tf, "Smoothing", accent)
        droneTabRows.posSmooth = createSliderRow(tf, "Pos Smooth", 1, 40,
            function() return posSmooth end, setPosSmoothValue,
            function(v) return string.format("%.1f", v) end, accent)
        droneTabRows.rotSmooth = createSliderRow(tf, "Rot Smooth", 1, 40,
            function() return rotSmooth end, setRotSmoothValue,
            function(v) return string.format("%.1f", v) end, accent)

        droneTabRowsRef = droneTabRows
        droneTabRowsRef._angleTabRows        = angleTabRows
        droneTabRowsRef._angleSectionFrame   = angleSectionFrame
        droneTabRowsRef._flightModeBtns      = droneFlightModeBtns
        droneTabRowsRef._flightModes         = flightModes
        droneTabRowsRef._updateFlightModeBtns = updateFlightModeBtns
    end

    ---- GYRO TAB ----
    do
        local tf = settingTabFrames.Gyro
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 2)
        listLayout.Parent = tf
        local lpad = Instance.new("UIPadding")
        lpad.PaddingLeft = UDim.new(0,6)
        lpad.PaddingRight = UDim.new(0,6)
        lpad.PaddingTop = UDim.new(0,6)
        lpad.PaddingBottom = UDim.new(0,6)
        lpad.Parent = tf

        local accent = Color3.fromRGB(190, 110, 255)

        local gyroInfo = Instance.new("TextLabel")
        gyroInfo.Size = UDim2.new(1, -12, 0, 32)
        gyroInfo.BackgroundColor3 = Color3.fromRGB(40, 28, 55)
        gyroInfo.BorderSizePixel = 0
        gyroInfo.Font = Enum.Font.Code
        gyroInfo.TextSize = 10
        gyroInfo.TextColor3 = Color3.fromRGB(200, 150, 255)
        gyroInfo.TextXAlignment = Enum.TextXAlignment.Left
        gyroInfo.TextYAlignment = Enum.TextYAlignment.Center
        gyroInfo.Text = "  ⟳ GYRO MODE  — Gerakan 6DOF penuh\n  Roll otomatis kembali ke 0 (seperti gyroscope)"
        gyroInfo.Parent = tf
        Instance.new("UICorner", gyroInfo).CornerRadius = UDim.new(0, 7)

        local gyroTabRows = {}

        makeTabSection(tf, "Movement", accent)
        gyroTabRows.speed = createSliderRow(tf, "Speed", CONFIG.minSpeed, CONFIG.maxSpeed,
            function() return speed end, setSpeedValue,
            function(v) return string.format("%.0f", v) end, accent)
        gyroTabRows.sens = createSliderRow(tf, "Sensitivity", 0.02, 1.5,
            function() return sensitivity end, setSensitivityValue,
            function(v) return string.format("%.2f", v) end, accent)
        gyroTabRows.boost = createSliderRow(tf, "Boost ×", 1, 8,
            function() return boostMultiplier end, setBoostMultiplierValue,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(255, 180, 60))
        gyroTabRows.slow = createSliderRow(tf, "Slow ×", 0.05, 1,
            function() return slowMultiplier end, setSlowMultiplierValue,
            function(v) return string.format("%.2f", v) end, Color3.fromRGB(100, 200, 130))

        makeTabSection(tf, "Gyro Stabilizer", accent)
        gyroTabRows.gyroStrength = createSliderRow(tf, "Gyro Strength", 0.5, 20,
            function() return gyroStrength end, setGyroStrength,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(230, 130, 255))

        makeTabSection(tf, "Camera", accent)
        gyroTabRows.fov = createSliderRow(tf, "FOV", CONFIG.minFov, CONFIG.maxFov,
            function() return targetFov end, setFovValue,
            function(v) return string.format("%.1f", v) end, Color3.fromRGB(255, 140, 80))
        gyroTabRows.fovSmooth = createSliderRow(tf, "FOV Smooth", 1, 40,
            function() return fovSmooth end, setFovSmoothValue,
            function(v) return string.format("%.1f", v) end, accent)
        gyroTabRows.zoomStep = createSliderRow(tf, "Zoom Step", 0.2, 20,
            function() return zoomStep end, setZoomStepValue,
            function(v) return string.format("%.2f", v) end, accent)

        makeTabSection(tf, "Roll & Smoothing", accent)
        gyroTabRows.rollSpeed = createSliderRow(tf, "Roll Speed°/s", math.deg(CONFIG.minRollSpeed), math.deg(CONFIG.maxRollSpeed),
            function() return math.deg(rollSpeed) end, setRollSpeedDeg,
            function(v) return string.format("%.0f", v) end, accent)
        gyroTabRows.posSmooth = createSliderRow(tf, "Pos Smooth", 1, 40,
            function() return posSmooth end, setPosSmoothValue,
            function(v) return string.format("%.1f", v) end, accent)
        gyroTabRows.rotSmooth = createSliderRow(tf, "Rot Smooth", 1, 40,
            function() return rotSmooth end, setRotSmoothValue,
            function(v) return string.format("%.1f", v) end, accent)

        gyroTabRowsRef = gyroTabRows
    end

    ---- KEYBINDS SECTION ----
    local keybindsSectionLabel = Instance.new("TextLabel")
    keybindsSectionLabel.Size = UDim2.new(1, 0, 0, 14)
    keybindsSectionLabel.LayoutOrder = 10
    keybindsSectionLabel.BackgroundTransparency = 1
    keybindsSectionLabel.Font = Enum.Font.GothamSemibold
    keybindsSectionLabel.TextSize = 10
    keybindsSectionLabel.TextColor3 = Color3.fromRGB(130, 145, 165)
    keybindsSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    keybindsSectionLabel.Text = "  KEYBINDS"
    keybindsSectionLabel.Parent = content

    local keyList = Instance.new("TextLabel")
    keyList.Size = UDim2.new(1, 0, 0, 155)
    keyList.LayoutOrder = 11
    keyList.BackgroundColor3 = Color3.fromRGB(25, 29, 36)
    keyList.BorderSizePixel = 0
    keyList.Font = Enum.Font.Code
    keyList.TextSize = 11
    keyList.TextColor3 = Color3.fromRGB(167, 178, 195)
    keyList.TextXAlignment = Enum.TextXAlignment.Left
    keyList.TextYAlignment = Enum.TextYAlignment.Top
    keyList.Text = table.concat({
        "Toggle: Shift+F | Panel: P | Controls Lock: K",
        "Move: W/A/S/D + Q/E | Boost: LShift | Slow: LCtrl",
        "Roll: Z/C | Roll Reset: X | Portrait +90: R",
        "Cursor: M | Hide UI: U | Stick Overlay: I",
        "FOV Zoom: Mouse Wheel",
        "Orbit: O toggle | T pick | G self | Y clear",
        "Speed/TWR: +/- keys | Reset: 0",
        "Gamepad: Select = toggle | Y = flight mode",
        "Drone FPV: LS roll/throttle | RS pitch/yaw",
        "Gyro: Roll auto-levels back to 0",
    }, "\n")
    keyList.Parent = content
    Instance.new("UICorner", keyList).CornerRadius = UDim.new(0, 9)
    do
        local kp = Instance.new("UIPadding")
        kp.PaddingLeft = UDim.new(0, 8)
        kp.PaddingTop = UDim.new(0, 7)
        kp.PaddingRight = UDim.new(0, 4)
        kp.Parent = keyList
    end

    ---- DRAG / RESIZE ----
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
            panel.Position = UDim2.fromOffset(
                panelStart.X.Offset + delta.X,
                panelStart.Y.Offset + delta.Y
            )
            clampPanelToViewport()
        elseif resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            setPanelSizeInternal(
                resizeStartSize.X + delta.X,
                resizeStartSize.Y + delta.Y
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
            resizeHandle.Visible = false
            resizing = false
        else
            content.Visible = true
            panel.Size = normalSize
            minimizeBtn.Text = "Min"
            resizeHandle.Visible = true
        end
        clampPanelToViewport()
    end))

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

    uiRefs = {
        panel            = panel,
        clampPanel       = clampPanelToViewport,
        status           = status,
        stats            = stats,
        freecamBtn       = freecamBtn,
        cursorBtn        = cursorBtn,
        uiBtn            = uiBtn,
        controlsBtn      = controlsBtn,
        orbitToggleBtn   = orbitToggleBtn,
        dofToggleBtn     = dofToggleBtn,
        stickOverlayBtn  = stickOverlayBtn,
        modeBtns         = modeBtns,
        modeColors       = modeColors,
        settingTabBtns   = settingTabBtns,
        activeSettingsTab = activeSettingsTab,
        normalTabRows    = normalTabRowsRef,
        droneTabRows     = droneTabRowsRef,
        gyroTabRows      = gyroTabRowsRef,
        droneAngleSection      = droneTabRowsRef._angleSectionFrame,
        updateFlightModeBtns   = droneTabRowsRef._updateFlightModeBtns,
        stickOverlay     = stickOverlay,
        leftStickDot     = leftDot,
        rightStickDot    = rightDot,
    }

    -- Patch activeSettingsTab reference for refreshUiText
    local origSetSettingsTab = setSettingsTab
    setSettingsTab = function(name)
        uiRefs.activeSettingsTab = name
        origSetSettingsTab(name)

    end

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

    if input.KeyCode == CONFIG.stickOverlayToggleKey then
        setStickOverlayVisible(not stickOverlayVisible)
        refreshUiText()
        return
    end

    if not freecam then return end

    if input.KeyCode == CONFIG.orbitToggleKey then
        setOrbitEnabled(not orbitEnabled)
        refreshUiText()
        return
    end

    if input.KeyCode == CONFIG.orbitPickKey then
        pickOrbitTarget()
        refreshUiText()
        return
    end

    if input.KeyCode == CONFIG.orbitSelfKey then
        setOrbitTargetSelf()
        refreshUiText()
        return
    end

    if input.KeyCode == CONFIG.orbitClearKey then
        clearOrbitTarget()
        refreshUiText()
        return
    end

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

--// GAMEPAD SHORTCUTS
table.insert(connections, UserInputService.InputBegan:Connect(function(input)
    if scriptKilled then return end
    if input.UserInputType ~= Enum.UserInputType.Gamepad1 then return end

    if input.KeyCode == CONFIG.gamepadToggleKey then
        toggleFreecam()
        refreshUiText()
        return
    end

    if input.KeyCode == CONFIG.gamepadFlightModeKey then
        if currentMode == "Drone" then
            cycleDroneFlightMode(1)
            refreshUiText()
        end
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

local MAX_STEP = 1 / 60
local UI_UPDATE_DT = 1 / 20
local uiUpdateAccum = 0

local function wrapAngle(a)
    local twoPi = math.pi * 2
    a = (a + math.pi) % twoPi
    return a - math.pi
end

local function applyDeadzone(v, dz)
    local av = math.abs(v)
    if av <= dz then
        return 0
    end
    local scaled = (av - dz) / math.max(1e-4, (1 - dz))
    return (v < 0 and -scaled or scaled)
end

local function applyExpo(v, expo)
    return v * (1 - expo) + (v * v * v) * expo
end

local function applySuperRate(v, superRate)
    if superRate <= 0 then
        return v
    end
    local av = math.abs(v)
    local denom = math.max(1e-3, 1 - av * superRate)
    return v / denom
end

local function applyRates(v, expo, superRate)
    local out = applyExpo(v, expo)
    out = applySuperRate(out, superRate)
    return math.clamp(out, -1, 1)
end

local function applyThrottleCurve(x, mid, expo)
    x = math.clamp(x, 0, 1)
    mid = math.clamp(mid, 0.05, 0.95)
    expo = math.clamp(expo, 0, 1)
    if x < mid then
        local t = x / mid
        local curved = t * (1 - expo) + (t * t) * expo
        return curved * mid
    else
        local t = (x - mid) / (1 - mid)
        local curved = t * (1 - expo) + (t * t) * expo
        return mid + curved * (1 - mid)
    end
end

local function getGamepadSticks()
    local lx, ly, rx, ry = 0, 0, 0, 0
    local state = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
    for _, input in ipairs(state) do
        if input.KeyCode == Enum.KeyCode.Thumbstick1 then
            lx, ly = input.Position.X, input.Position.Y
        elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
            rx, ry = input.Position.X, input.Position.Y
        end
    end
    return lx, ly, rx, ry
end

local function gamepadConnected()
    local pads = UserInputService:GetConnectedGamepads()
    return pads and #pads > 0
end

local function updateStickOverlay(lx, ly, rx, ry)
    if not stickOverlayVisible then return end
    if not uiRefs.leftStickDot or not uiRefs.rightStickDot then return end
    local function setDot(dot, x, y)
        x = math.clamp(x, -1, 1)
        y = math.clamp(y, -1, 1)
        dot.Position = UDim2.new(0.5 + x * 0.5, 0, 0.5 - y * 0.5, 0)
    end
    setDot(uiRefs.leftStickDot, lx, ly)
    setDot(uiRefs.rightStickDot, rx, ry)
end

table.insert(connections, RunService.RenderStepped:Connect(function(dt)
    if scriptKilled then return end

    local lx, ly, rx, ry = 0, 0, 0, 0
    local padActive = UserInputService.GamepadEnabled and gamepadConnected()
    if padActive then
        lx, ly, rx, ry = getGamepadSticks()
    end
    updateStickOverlay(lx, ly, rx, ry)

    if not freecam then return end

    local isDrone = currentMode == "Drone"
    local usingGamepad = isDrone and controlsEnabled and padActive
    local droneYawInput, dronePitchInput, droneRollInput, droneThrottleInput = 0, 0, 0, 0
    if usingGamepad then
        droneRollInput = -applyDeadzone(rx, droneDeadzone)
        droneThrottleInput = applyDeadzone(ly, droneDeadzone)
        droneYawInput = -applyDeadzone(lx, droneDeadzone)
        dronePitchInput = applyDeadzone(-ry, droneDeadzone)

        droneYawInput = applyRates(droneYawInput, droneYawExpo, droneYawSuper)
        dronePitchInput = applyRates(dronePitchInput, dronePitchExpo, dronePitchSuper)
        droneRollInput = applyRates(droneRollInput, droneRollExpo, droneRollSuper)
    end

    local boostDown = controlsEnabled and UserInputService:IsKeyDown(CONFIG.boostKey)
    local slowDown = controlsEnabled and UserInputService:IsKeyDown(CONFIG.slowKey)

    local inputVec = Vector3.zero
    if controlsEnabled and not usingGamepad then
        inputVec = Vector3.new(
            (moveState[Enum.KeyCode.D] and 1 or 0) - (moveState[Enum.KeyCode.A] and 1 or 0),
            (moveState[Enum.KeyCode.E] and 1 or 0) - (moveState[Enum.KeyCode.Q] and 1 or 0),
            (moveState[Enum.KeyCode.S] and 1 or 0) - (moveState[Enum.KeyCode.W] and 1 or 0)
        )
    end
    local inputMag = inputVec.Magnitude
    local inputUnit = inputVec
    if inputMag > 0 then
        inputUnit = inputVec.Unit
    end

    local orbitPos
    local orbitActive = false
    if orbitEnabled and orbitTarget then
        if not orbitTarget.Parent then
            clearOrbitTarget()
        else
            orbitPos = getOrbitTargetPosition(orbitTarget)
            if orbitPos then
                orbitActive = true
            elseif not orbitTarget:IsA("Player") then
                clearOrbitTarget()
            end
        end
    end

    local yawRateRad, pitchRateRad, rollRateRad, maxTiltRad
    local droneMassNow, droneGNow, droneTwr, dronePower, hoverCurveBase
    -- MOI scaling (lower = snappier response)
    local moiPitchNow, moiRollNow, moiYawNow
    if usingGamepad then
        yawRateRad = math.rad(droneYawRate)
        pitchRateRad = math.rad(dronePitchRate)
        rollRateRad = math.rad(droneRollRate)
        if droneFlightMode == "Angle" then
            maxTiltRad = math.rad(droneAngleMaxTilt)
        end
        droneMassNow = math.max(0.1, droneMass)
        droneGNow = math.max(0, droneGravity)
        droneTwr = math.clamp(speed, 1, 20)
        dronePower = math.clamp(droneThrottlePower, 1, 3)
        moiPitchNow = math.max(0.2, droneMoiPitch)
        moiRollNow = math.max(0.2, droneMoiRoll)
        moiYawNow = math.max(0.2, droneMoiYaw)
        if droneFlightMode ~= "3D" then
            local hoverInput = math.clamp(droneHoverThrottle, 0.05, 0.95)
            hoverCurveBase = applyThrottleCurve(hoverInput, droneThrottleMid, droneThrottleExpo)
            hoverCurveBase = math.pow(hoverCurveBase, dronePower)
        end
    end

    local steps = math.max(1, math.ceil(dt / MAX_STEP))
    local stepDt = dt / steps
    local mouseStepX, mouseStepY = 0, 0
    if controlsEnabled and not usingGamepad then
        local mouseDelta = UserInputService:GetMouseDelta()
        mouseStepX = mouseDelta.X / steps
        mouseStepY = mouseDelta.Y / steps
    end
    local rotAlphaStep = smooth(rotSmooth, stepDt)
    local posAlphaStep = smooth(posSmooth, stepDt)
    local fovAlphaStep = smooth(fovSmooth, stepDt)
    local angleLevelAlphaStep
    local rateResponseAlphaStep
    if usingGamepad then
        rateResponseAlphaStep = smooth(droneRateResponse, stepDt)
        if droneFlightMode == "Angle" then
            angleLevelAlphaStep = smooth(droneAngleLevelStrength, stepDt)
        end
    end

    for i = 1, steps do
        local dt = stepDt

        -- Look input
        if not usingGamepad and controlsEnabled then
            yawTarget   -= mouseStepX * sensitivity * 0.01
            pitchTarget -= mouseStepY * sensitivity * 0.01
            pitchTarget = math.clamp(pitchTarget, -pitchClamp, pitchClamp)
        end

        local rot
        if usingGamepad then
            if droneFlightMode == "Angle" then
                -- === ANGLE MODE with coordinated turns ===
                local targetPitch = math.clamp(dronePitchInput, -1, 1) * maxTiltRad
                local targetRoll = math.clamp(droneRollInput, -1, 1) * maxTiltRad
                local levelAlpha = angleLevelAlphaStep or smooth(droneAngleLevelStrength, dt)
                droneAngVel = Vector3.zero

                pitch += (targetPitch - pitch) * levelAlpha
                roll += (targetRoll - roll) * levelAlpha

                -- Yaw: stick yaw + coordinated turn yaw from roll angle
                local coordYaw = math.sin(roll) * droneAngleYawCoord * yawRateRad * dt
                yaw = wrapAngle(yaw + yawRateRad * droneYawInput * dt + coordYaw)

                rot = CFrame.Angles(0, yaw, 0) *
                    CFrame.Angles(pitch, 0, 0) *
                    CFrame.Angles(0, 0, roll)
                droneOrient = rot
            else
                -- === ACRO / 3D MODE with MOI tensor ===
                if not droneOrient then
                    droneOrient = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.Angles(0, 0, roll)
                end

                -- Target angular rates (deg/s converted to rad/s already)
                local targetRates = Vector3.new(
                    pitchRateRad * dronePitchInput,
                    yawRateRad * droneYawInput,
                    rollRateRad * droneRollInput
                )

                -- Apply MOI: higher MOI = slower angular acceleration
                -- Angular acceleration = torque / MOI, we model this as rate of rate-change scaled by 1/MOI
                local rateAlphaBase = rateResponseAlphaStep or smooth(droneRateResponse, dt)
                local pitchRateAlpha = math.clamp(rateAlphaBase / moiPitchNow, 0, 1)
                local rollRateAlpha = math.clamp(rateAlphaBase / moiRollNow, 0, 1)
                local yawRateAlpha = math.clamp(rateAlphaBase / moiYawNow, 0, 1)

                droneAngVel = Vector3.new(
                    droneAngVel.X + (targetRates.X - droneAngVel.X) * pitchRateAlpha,
                    droneAngVel.Y + (targetRates.Y - droneAngVel.Y) * yawRateAlpha,
                    droneAngVel.Z + (targetRates.Z - droneAngVel.Z) * rollRateAlpha
                )

                -- Angular damping
                local damp = math.clamp(droneAngularDamping, 0, 5)
                if damp > 0 then
                    local dampFactor = math.max(0, 1 - damp * dt)
                    droneAngVel = droneAngVel * dampFactor
                end

                -- === PROPWASH OSCILLATION ===
                -- Detect if drone is descending into its own propwash
                if dronePropwashStrength > 0 then
                    local bodyUp = droneOrient:VectorToWorldSpace(Vector3.new(0, 1, 0))
                    local velMag = droneVelocity.Magnitude
                    if velMag > 1 then
                        local velDir = droneVelocity / velMag
                        -- Dot product: how much velocity is aligned opposite to body-up (descending into prop stream)
                        local propwashDot = -bodyUp:Dot(velDir)
                        -- Only trigger when descending roughly along body-up axis
                        local propwashZoneFactor = math.clamp(propwashDot - (1 - dronePropwashZone), 0, dronePropwashZone)
                        if propwashZoneFactor > 0 then
                            local pwIntensity = (propwashZoneFactor / math.max(0.01, dronePropwashZone))
                                * dronePropwashStrength
                                * math.clamp(velMag / 30, 0, 1)
                            -- Pseudo-random perturbation using os.clock for high-frequency oscillation
                            local t = os.clock() * 47.3
                            local pwPitch = math.sin(t * 7.1 + 1.3) * pwIntensity * pitchRateRad * 0.15
                            local pwRoll = math.sin(t * 11.7 + 3.7) * pwIntensity * rollRateRad * 0.12
                            local pwYaw = math.sin(t * 5.3 + 5.1) * pwIntensity * yawRateRad * 0.08
                            droneAngVel = droneAngVel + Vector3.new(pwPitch, pwYaw, pwRoll)
                        end
                    end
                end

                droneOrient = droneOrient * CFrame.Angles(
                    droneAngVel.X * dt,
                    droneAngVel.Y * dt,
                    droneAngVel.Z * dt
                )
                local rx, ry, rz = droneOrient:ToOrientation()
                pitch, yaw, roll = rx, ry, rz
                rot = droneOrient
            end
        else
            yaw += (yawTarget - yaw) * rotAlphaStep
            pitch += (pitchTarget - pitch) * rotAlphaStep

            -- Roll per mode
            if isDrone then
                roll = 0
            elseif currentMode == "Gyro" then
                -- Auto-return to level + allow manual override (gyro fights back)
                local rollDir = controlsEnabled and ((rollState[CONFIG.rollRightKey] and 1 or 0) - (rollState[CONFIG.rollLeftKey] and 1 or 0)) or 0
                roll += rollDir * rollSpeed * dt
                roll = roll * math.max(0, 1 - gyroStrength * dt)
            else
                -- Normal manual roll
                local rollDir = controlsEnabled and ((rollState[CONFIG.rollRightKey] and 1 or 0) - (rollState[CONFIG.rollLeftKey] and 1 or 0)) or 0
                roll += rollDir * rollSpeed * dt
            end

            rot =
                CFrame.Angles(0, yaw, 0) *
                CFrame.Angles(pitch, 0, 0) *
                CFrame.Angles(0, 0, roll)
        end

        local camRot = rot
        if isDrone then
            camRot = rot * CFrame.Angles(math.rad(droneCameraTilt), 0, 0)
        end

        if orbitActive then
            local orbitRot = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
            local offset = orbitRot:VectorToWorldSpace(Vector3.new(0, 0, orbitRadius))
            local desiredPos = orbitPos + offset
            targetCFrame = CFrame.new(desiredPos, orbitPos) * CFrame.Angles(0, 0, roll)
        else
            local move = Vector3.zero
            if not orbitEnabled and controlsEnabled then
                if usingGamepad then
                    -- === THROTTLE / THRUST COMPUTATION ===
                    local thrustMag
                    local targetMotor

                    if droneFlightMode == "3D" then
                        -- 3D mode: stick center = 0 thrust, up = +thrust, down = -thrust (symmetric)
                        local signed = math.clamp(droneThrottleInput, -1, 1)
                        droneThrottleState += (signed - droneThrottleState) * smooth(droneThrustResponse, dt)
                        droneThrottleState = math.clamp(droneThrottleState, -1, 1)
                        local absVal = math.abs(droneThrottleState)
                        local curved = math.pow(absVal, dronePower)
                        local signedCurve = (droneThrottleState < 0 and -curved or curved)
                        -- Symmetric: no penalty for reverse thrust in 3D mode
                        targetMotor = math.abs(signedCurve)
                        thrustMag = signedCurve * droneTwr * droneMassNow * droneGNow * droneVertMult
                    else
                        -- Acro / Angle: stick low = 0 thrust, stick high = max
                        local throttleRaw = (droneThrottleInput + 1) * 0.5
                        droneThrottleState += (throttleRaw - droneThrottleState) * smooth(droneThrustResponse, dt)
                        droneThrottleState = math.clamp(droneThrottleState, 0, 1)

                        local throttleCurve = applyThrottleCurve(droneThrottleState, droneThrottleMid, droneThrottleExpo)
                        throttleCurve = math.pow(throttleCurve, dronePower)

                        local ratio2
                        if throttleCurve >= hoverCurveBase then
                            ratio2 = 1 + (throttleCurve - hoverCurveBase) / math.max(1e-3, (1 - hoverCurveBase)) * (droneTwr - 1)
                        else
                            ratio2 = throttleCurve / math.max(1e-3, hoverCurveBase)
                        end
                        ratio2 = math.max(0, ratio2)
                        targetMotor = ratio2 / math.max(0.1, droneTwr)
                        thrustMag = ratio2 * droneMassNow * droneGNow * droneVertMult
                    end

                    -- === ASYMMETRIC MOTOR RESPONSE ===
                    -- Motors spin up faster than they spin down
                    targetMotor = math.clamp(targetMotor, 0, 1)
                    local motorDelta = targetMotor - droneMotorOutput
                    local motorRate
                    if motorDelta > 0 then
                        motorRate = smooth(droneMotorSpinUp, dt)
                    else
                        motorRate = smooth(droneMotorSpinDown, dt)
                    end
                    droneMotorOutput = droneMotorOutput + motorDelta * motorRate
                    droneMotorOutput = math.clamp(droneMotorOutput, 0, 1)

                    -- Scale thrust by motor output to get the actual effective thrust
                    -- The motor output smooths the transition, creating lag on spin-down
                    local motorRatio = 1
                    if targetMotor > 0.01 then
                        motorRatio = droneMotorOutput / targetMotor
                    elseif droneMotorOutput > 0.01 then
                        motorRatio = droneMotorOutput
                    end
                    local effectiveThrust = thrustMag * math.clamp(motorRatio, 0, 1.5)

                    -- Thrust direction (always body-local up)
                    local thrustDir = rot:VectorToWorldSpace(Vector3.new(0, 1, 0))
                    local thrustForce = thrustDir * effectiveThrust

                    -- Gravity
                    local gravityForce = Vector3.new(0, -droneGNow * droneMassNow, 0)

                    -- === ANISOTROPIC DRAG ===
                    -- Decompose velocity into body-local components
                    local bodyForward = rot:VectorToWorldSpace(Vector3.new(0, 0, -1))
                    local bodyRight = rot:VectorToWorldSpace(Vector3.new(1, 0, 0))
                    local bodyUp = rot:VectorToWorldSpace(Vector3.new(0, 1, 0))

                    local velForward = droneVelocity:Dot(bodyForward)
                    local velRight = droneVelocity:Dot(bodyRight)
                    local velUp = droneVelocity:Dot(bodyUp)

                    -- Apply different drag coefficients per axis
                    local dragFwd = droneDragForward
                    local dragSide = droneDragSideways
                    local dragVert = droneDragVertical

                    -- Linear drag per axis
                    local dragForce = -(bodyForward * velForward * dragFwd
                        + bodyRight * velRight * dragSide
                        + bodyUp * velUp * dragVert)

                    -- Quadratic drag (uses total velocity for high-speed regime)
                    local velMag = droneVelocity.Magnitude
                    local quadDragForce = Vector3.zero
                    if velMag > 0.1 then
                        quadDragForce = -droneVelocity * velMag * droneQuadDrag
                    end

                    -- === GROUND EFFECT ===
                    local groundEffectForce = Vector3.zero
                    if droneGroundEffectHeight > 0 and droneGroundEffectStrength > 0 then
                        local dronePos = targetCFrame.Position
                        local rayParams = RaycastParams.new()
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        local exclude = {}
                        if player.Character then
                            table.insert(exclude, player.Character)
                        end
                        rayParams.FilterDescendantsInstances = exclude
                        rayParams.IgnoreWater = true
                        local rayResult = workspace:Raycast(dronePos, Vector3.new(0, -droneGroundEffectHeight, 0), rayParams)
                        if rayResult then
                            local heightAboveGround = (dronePos - rayResult.Position).Magnitude
                            local geFactor = 1 - (heightAboveGround / droneGroundEffectHeight)
                            geFactor = math.clamp(geFactor, 0, 1)
                            -- Ground effect is stronger with more motor output
                            local geStrength = geFactor * geFactor * droneGroundEffectStrength
                                * droneMotorOutput * droneMassNow * droneGNow
                            groundEffectForce = Vector3.new(0, geStrength, 0)
                        end
                    end

                    -- === TOTAL ACCELERATION ===
                    local totalForce = thrustForce + gravityForce + dragForce + quadDragForce + groundEffectForce
                    local accel = totalForce / droneMassNow

                    local velTarget = droneVelocity + accel * dt
                    local inertia = math.clamp(droneInertia, 0, 1)
                    local velAlpha = math.clamp(1 - inertia, 0.02, 1)
                    droneVelocity = droneVelocity:Lerp(velTarget, velAlpha)
                    move = droneVelocity * dt
                else
                    if isDrone then
                        droneVelocity = Vector3.zero
                        droneThrottleState = 0
                        droneMotorOutput = 0
                    end
                    if inputMag > 0 then
                        local speedNow = speed
                        if boostDown then
                            speedNow *= boostMultiplier
                        elseif slowDown then
                            speedNow *= slowMultiplier
                        end

                        if isDrone then
                            -- Horizontal movement only: W/S on XZ plane, Q/E vertical
                            local sinY = math.sin(yaw)
                            local cosY = math.cos(yaw)
                            local fwd   = Vector3.new(-sinY, 0, -cosY)
                            local right = Vector3.new( cosY, 0, -sinY)
                            local up    = Vector3.new(0, 1, 0)
                            move = (right * inputVec.X + (up * inputVec.Y * droneVertMult) + fwd * inputVec.Z) * speedNow * dt
                        else
                            -- Normal / Gyro: full 3D movement
                            move = rot:VectorToWorldSpace(inputUnit) * speedNow * dt
                        end
                    end
                end
            else
                if isDrone then
                    droneVelocity = Vector3.zero
                    droneThrottleState = 0
                    droneMotorOutput = 0
                end
            end

            targetCFrame = CFrame.new(targetCFrame.Position + move) * camRot
        end

        currentCFrame = currentCFrame:Lerp(targetCFrame, posAlphaStep)
        cam.CFrame = currentCFrame
        cam.FieldOfView += (targetFov - cam.FieldOfView) * fovAlphaStep
        uiUpdateAccum += dt
        if i == steps then
            if uiUpdateAccum >= UI_UPDATE_DT then
                refreshUiText()
                uiUpdateAccum = 0
            end
        end
    end
end))

print("Hi!")
