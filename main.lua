
--[[
    BABA HUB V2 | MM2
    By LLaliLLama_2 (AliBaba)

    Features:
    - FPS, ping, clock and session timer
    - Draggable HUD
    - Player highlights and tool-based role estimates
    - Player names and distance labels
    - WalkSpeed and jump controls
    - FOV and camera zoom
    - Lighting presets
    - Low graphics mode
    - Reset and cleanup
]]

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Prevent duplicate instances
if getgenv().BabaHubCleanup then
    pcall(getgenv().BabaHubCleanup)
end

local Rayfield = loadstring(
    game:HttpGet("https://sirius.menu/gen2")
)()

local Window = Rayfield:CreateWindow({
    name = "Baba Hub V2 | MM2",
    subtitle = "By LLaliLLama_2",
    sidebarLayout = true,
})

-- CONFIG
local Config = {
    ESP = false,
    ESPNames = true,
    ESPDistance = true,
    ESPTransparency = 0.5,

    WalkSpeed = 16,
    JumpPower = 50,

    FPS = true,
    Ping = false,
    Clock = false,
    Session = false,

    FOV = 70,
    Zoom = 20,
    LowGraphics = false,
}

local Running = true
local StartedAt = os.clock()

local Connections = {}
local Highlights = {}
local Labels = {}
local SavedGraphics = {}
local SavedLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
}

local Original = {
    WalkSpeed = 16,
    JumpPower = 50,
    FOV = workspace.CurrentCamera
        and workspace.CurrentCamera.FieldOfView or 70,
    Zoom = LocalPlayer.CameraMaxZoomDistance,
    CameraMode = LocalPlayer.CameraMode,
}

local Colors = {
    Murderer = Color3.fromRGB(255, 65, 65),
    Sheriff = Color3.fromRGB(60, 140, 255),
    Unknown = Color3.fromRGB(65, 255, 125),
}

-- HELPERS
local function Track(Connection)
    table.insert(Connections, Connection)
    return Connection
end

local function Notify(Title, Message)
    Window:Notify({
        title = Title,
        content = Message,
        duration = 4,
    })
end

local function Humanoid()
    local Character = LocalPlayer.Character
    return Character and
        Character:FindFirstChildOfClass("Humanoid")
end

local function ApplyMovement()
    local H = Humanoid()
    if not H then return end

    H.WalkSpeed = Config.WalkSpeed
    H.UseJumpPower = true
    H.JumpPower = Config.JumpPower
end

local function ApplyCamera()
    local Camera = workspace.CurrentCamera
    if Camera then
        Camera.FieldOfView = Config.FOV
    end

    LocalPlayer.CameraMaxZoomDistance = Config.Zoom
end

local function FormatTime(Seconds)
    Seconds = math.floor(Seconds)
    return string.format(
        "%02d:%02d",
        math.floor(Seconds / 60),
        Seconds % 60
    )
end

-- ROLE ESTIMATION
local function GetRole(Player)
    local function Check(Container)
        if not Container then return nil end

        for _, Item in ipairs(Container:GetChildren()) do
            if Item:IsA("Tool") then
                local Name = Item.Name:lower()

                if Name:find("knife", 1, true) then
                    return "Murderer"
                elseif Name:find("gun", 1, true)
                    or Name:find("revolver", 1, true) then
                    return "Sheriff"
                end
            end
        end

        return nil
    end

    return Check(Player.Character)
        or Check(Player:FindFirstChildOfClass("Backpack"))
        or "Unknown"
end

-- ESP
local function RemoveESP(Player)
    if Highlights[Player] then
        Highlights[Player]:Destroy()
        Highlights[Player] = nil
    end

    if Labels[Player] then
        Labels[Player]:Destroy()
        Labels[Player] = nil
    end
end

local function UpdateESP(Player)
    if Player == LocalPlayer then return end

    local Character = Player.Character
    local Root = Character and
        Character:FindFirstChild("HumanoidRootPart")

    if not Config.ESP or not Character or not Root then
        RemoveESP(Player)
        return
    end

    local Highlight = Highlights[Player]

    if Highlight and Highlight.Adornee ~= Character then
        RemoveESP(Player)
        Highlight = nil
    end

    if not Highlight then
        Highlight = Instance.new("Highlight")
        Highlight.Name = "BabaHighlight"
        Highlight.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop
        Highlight.Adornee = Character
        Highlight.Parent = Character
        Highlights[Player] = Highlight
    end

    local Role = GetRole(Player)
    local Color = Colors[Role] or Colors.Unknown

    Highlight.FillColor = Color
    Highlight.OutlineColor = Color
    Highlight.FillTransparency = Config.ESPTransparency
    Highlight.OutlineTransparency = 0

    local Billboard = Labels[Player]

    if Billboard and Billboard.Adornee ~= Root then
        Billboard:Destroy()
        Labels[Player] = nil
        Billboard = nil
    end

    if not Billboard then
        Billboard = Instance.new("BillboardGui")
        Billboard.Name = "BabaPlayerLabel"
        Billboard.Size = UDim2.fromOffset(220, 55)
        Billboard.StudsOffset = Vector3.new(0, 3, 0)
        Billboard.AlwaysOnTop = true
        Billboard.Adornee = Root
        Billboard.Parent = Root

        local Text = Instance.new("TextLabel")
        Text.Name = "Info"
        Text.Size = UDim2.fromScale(1, 1)
        Text.BackgroundTransparency = 1
        Text.TextColor3 = Color3.new(1, 1, 1)
        Text.TextStrokeTransparency = 0.25
        Text.Font = Enum.Font.GothamBold
        Text.TextSize = 13
        Text.Parent = Billboard

        Labels[Player] = Billboard
    end

    Billboard.Enabled =
        Config.ESPNames or Config.ESPDistance

    local Parts = {}

    if Config.ESPNames then
        table.insert(Parts, Player.DisplayName)
        table.insert(Parts, "[" .. Role .. "?]")
    end

    if Config.ESPDistance then
        local MyRoot = LocalPlayer.Character and
            LocalPlayer.Character:FindFirstChild(
                "HumanoidRootPart"
            )

        if MyRoot then
            local Distance = (MyRoot.Position - Root.Position).Magnitude
            table.insert(
                Parts,
                math.floor(Distance) .. " studs"
            )
        end
    end

    local Text = Billboard:FindFirstChild("Info")
    if Text then
        Text.Text = table.concat(Parts, "\n")
        Text.TextColor3 = Color
    end
end

local function RefreshESP()
    for _, Player in ipairs(Players:GetPlayers()) do
        UpdateESP(Player)
    end
end

local function ClearESP()
    for Player in pairs(Highlights) do
        RemoveESP(Player)
    end

    for Player in pairs(Labels) do
        RemoveESP(Player)
    end
end

-- DRAGGABLE HUD
local GUI = Instance.new("ScreenGui")
GUI.Name = "BabaHubHUD"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

local HUD = Instance.new("Frame")
HUD.Name = "StatsHUD"
HUD.Size = UDim2.fromOffset(180, 120)
HUD.Position = UDim2.new(1, -195, 0, 85)
HUD.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
HUD.BackgroundTransparency = 0.12
HUD.BorderSizePixel = 0
HUD.Active = true
HUD.Parent = GUI

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = HUD

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(95, 105, 255)
Stroke.Thickness = 1
Stroke.Transparency = 0.3
Stroke.Parent = HUD

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 3)
Layout.HorizontalAlignment =
    Enum.HorizontalAlignment.Center
Layout.Parent = HUD

local function NewHUDLabel(Name, Color)
    local Label = Instance.new("TextLabel")
    Label.Name = Name
    Label.Size = UDim2.new(1, -12, 0, 21)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 13
    Label.TextColor3 = Color
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Text = Name
    Label.Parent = HUD
    return Label
end

local Header = NewHUDLabel(
    "  BABA HUB V2",
    Color3.fromRGB(155, 165, 255)
)

local FPSLabel = NewHUDLabel(
    "FPS: --",
    Color3.fromRGB(100, 255, 150)
)

local PingLabel = NewHUDLabel(
    "Ping: --",
    Color3.fromRGB(255, 220, 100)
)

local ClockLabel = NewHUDLabel(
    "Time: --",
    Color3.fromRGB(200, 200, 255)
)

local SessionLabel = NewHUDLabel(
    "Session: --",
    Color3.fromRGB(200, 200, 255)
)

-- DRAG HANDLING
local Dragging = false
local DragStart
local StartPosition

Track(HUD.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = Input.Position
        StartPosition = HUD.Position
    end
end))

Track(UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch then
        Dragging = false
    end
end))

Track(UserInputService.InputChanged:Connect(function(Input)
    if not Dragging then return end

    if Input.UserInputType ~= Enum.UserInputType.MouseMovement
        and Input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local Delta = Input.Position - DragStart

    HUD.Position = UDim2.new(
        StartPosition.X.Scale,
        StartPosition.X.Offset + Delta.X,
        StartPosition.Y.Scale,
        StartPosition.Y.Offset + Delta.Y
    )
end))

-- FPS TRACKING
local FrameCount = 0
local FPS = 0
local FrameElapsed = 0
local UpdateElapsed = 0
local ESPElapsed = 0

local function UpdateHUD()
    FPSLabel.Visible = Config.FPS
    PingLabel.Visible = Config.Ping
    ClockLabel.Visible = Config.Clock
    SessionLabel.Visible = Config.Session

    local Count = 0
    for _, Enabled in ipairs({
        Config.FPS,
        Config.Ping,
        Config.Clock,
        Config.Session
    }) do
        if Enabled then
            Count += 1
        end
    end

    HUD.Visible = Count > 0
    HUD.Size = UDim2.fromOffset(180, 30 + Count * 24)

    FPSLabel.Text = "  FPS: " .. tostring(FPS)

    local Ping = "--"
    pcall(function()
        Ping = Stats.Network.ServerStatsItem[
            "Data Ping"
        ]:GetValueString()
    end)

    PingLabel.Text = "  Ping: " .. Ping
    ClockLabel.Text = "  Time: " .. os.date("%H:%M:%S")
    SessionLabel.Text = "  Session: " ..
        FormatTime(os.clock() - StartedAt)
end

Track(RunService.RenderStepped:Connect(function(Delta)
    if not Running then return end

    FrameCount += 1
    FrameElapsed += Delta
    UpdateElapsed += Delta
    ESPElapsed += Delta

    if FrameElapsed >= 0.5 then
        FPS = math.floor(
            FrameCount / FrameElapsed + 0.5
        )
        FrameCount = 0
        FrameElapsed = 0
    end

    if UpdateElapsed >= 0.5 then
        UpdateElapsed = 0
        UpdateHUD()
    end

    if ESPElapsed >= 0.5 then
        ESPElapsed = 0
        if Config.ESP then
            RefreshESP()
        end
    end
end))

-- GRAPHICS
local function SetLowGraphics(Enabled)
    if Enabled then
        table.clear(SavedGraphics)

        for _, Object in ipairs(workspace:GetDescendants()) do
            if Object:IsA("BasePart") then
                SavedGraphics[Object] = {
                    Material = Object.Material,
                    Reflectance = Object.Reflectance,
                }

                Object.Material = Enum.Material.SmoothPlastic
                Object.Reflectance = 0
            end
        end

        Lighting.GlobalShadows = false
    else
        for Object, Values in pairs(SavedGraphics) do
            if Object and Object.Parent then
                Object.Material = Values.Material
                Object.Reflectance = Values.Reflectance
            end
        end

        table.clear(SavedGraphics)
        Lighting.GlobalShadows =
            SavedLighting.GlobalShadows
    end
end

local function RestoreLighting()
    for Property, Value in pairs(SavedLighting) do
        Lighting[Property] = Value
    end
end

-- TABS
local Home = Window:CreateTab({
    name = "Home",
    icon = "house",
})

local Visuals = Window:CreateTab({
    name = "Visuals",
    icon = "eye",
})

local HUDTab = Window:CreateTab({
    name = "HUD",
    icon = "monitor",
})

local Movement = Window:CreateTab({
    name = "Movement",
    icon = "zap",
})

local CameraTab = Window:CreateTab({
    name = "Camera",
    icon = "camera",
})

local Performance = Window:CreateTab({
    name = "Performance",
    icon = "cpu",
})

local World = Window:CreateTab({
    name = "World",
    icon = "sun",
})

local Settings = Window:CreateTab({
    name = "Settings",
    icon = "settings",
})

-- HOME
Home:CreateSection("Baba Hub V2")

Home:CreateButton({
    name = "Welcome",
    callback = function()
        Notify(
            "Baba Hub V2",
            "Welcome, " .. LocalPlayer.DisplayName .. "!"
        )
    end,
})

Home:CreateButton({
    name = "Show Player Information",
    callback = function()
        Notify(
            "Player Information",
            "Username: " .. LocalPlayer.Name ..
            " | User ID: " .. LocalPlayer.UserId
        )
    end,
})

Home:CreateButton({
    name = "Show Server Player Count",
    callback = function()
        Notify(
            "Server",
            tostring(#Players:GetPlayers()) ..
            " players connected."
        )
    end,
})

Home:CreateButton({
    name = "Show Session Duration",
    callback = function()
        Notify(
            "Session",
            FormatTime(os.clock() - StartedAt)
        )
    end,
})

-- VISUALS
Visuals:CreateSection("Player Highlights")

Visuals:CreateToggle({
    name = "Role ESP",
    current = false,
    flag = "BabaESP",
    callback = function(Value)
        Config.ESP = Value

        if Value then
            RefreshESP()
        else
            ClearESP()
        end
    end,
})

Visuals:CreateToggle({
    name = "Show Player Names",
    current = true,
    flag = "BabaNames",
    callback = function(Value)
        Config.ESPNames = Value
        RefreshESP()
    end,
})

Visuals:CreateToggle({
    name = "Show Player Distance",
    current = true,
    flag = "BabaDistance",
    callback = function(Value)
        Config.ESPDistance = Value
        RefreshESP()
    end,
})

Visuals:CreateSlider({
    name = "Highlight Transparency",
    current = 50,
    range = {0, 100},
    increment = 5,
    suffix = "%",
    flag = "BabaESPAlpha",
    callback = function(Value)
        Config.ESPTransparency = Value / 100
        RefreshESP()
    end,
})

Visuals:CreateButton({
    name = "Refresh All Highlights",
    callback = function()
        RefreshESP()
        Notify("ESP", "Highlights refreshed.")
    end,
})

Visuals:CreateSection("Color Information")

Visuals:CreateButton({
    name = "Show ESP Color Legend",
    callback = function()
        Notify(
            "Role Estimates",
            "Red: Knife | Blue: Gun | Green: Unknown"
        )
    end,
})

-- HUD
HUDTab:CreateSection("Performance Overlay")

HUDTab:CreateToggle({
    name = "Show FPS Counter",
    current = true,
    flag = "BabaFPS",
    callback = function(Value)
        Config.FPS = Value
        UpdateHUD()
    end,
})

HUDTab:CreateToggle({
    name = "Show Ping",
    current = false,
    flag = "BabaPing",
    callback = function(Value)
        Config.Ping = Value
        UpdateHUD()
    end,
})

HUDTab:CreateToggle({
    name = "Show Clock",
    current = false,
    flag = "BabaClock",
    callback = function(Value)
        Config.Clock = Value
        UpdateHUD()
    end,
})

HUDTab:CreateToggle({
    name = "Show Session Timer",
    current = false,
    flag = "BabaSession",
    callback = function(Value)
        Config.Session = Value
        UpdateHUD()
    end,
})

HUDTab:CreateSection("HUD Customization")

HUDTab:CreateSlider({
    name = "HUD Transparency",
    current = 12,
    range = {0, 100},
    increment = 5,
    suffix = "%",
    flag = "BabaHUDAlpha",
    callback = function(Value)
        HUD.BackgroundTransparency = Value / 100
    end,
})

HUDTab:CreateButton({
    name = "Reset HUD Position",
    callback = function()
        HUD.Position = UDim2.new(1, -195, 0, 85)
    end,
})

-- MOVEMENT
Movement:CreateSection("Movement Controls")

Movement:CreateSlider({
    name = "WalkSpeed",
    current = 16,
    range = {10, 50},
    increment = 1,
    suffix = "Speed",
    flag = "BabaSpeed",
    callback = function(Value)
        Config.WalkSpeed = Value
        ApplyMovement()
    end,
})

Movement:CreateSlider({
    name = "Jump Power",
    current = 50,
    range = {25, 100},
    increment = 5,
    suffix = "Power",
    flag = "BabaJump",
    callback = function(Value)
        Config.JumpPower = Value
        ApplyMovement()
    end,
})

Movement:CreateButton({
    name = "Reset Movement",
    callback = function()
        Config.WalkSpeed = Original.WalkSpeed
        Config.JumpPower = Original.JumpPower
        ApplyMovement()
        Notify("Movement", "Movement restored.")
    end,
})

-- CAMERA
CameraTab:CreateSection("Camera Controls")

CameraTab:CreateSlider({
    name = "Field of View",
    current = 70,
    range = {40, 120},
    increment = 5,
    suffix = "FOV",
    flag = "BabaFOV",
    callback = function(Value)
        Config.FOV = Value
        ApplyCamera()
    end,
})

CameraTab:CreateSlider({
    name = "Maximum Camera Zoom",
    current = 20,
    range = {1, 100},
    increment = 1,
    suffix = "Studs",
    flag = "BabaZoom",
    callback = function(Value)
        Config.Zoom = Value
        ApplyCamera()
    end,
})

CameraTab:CreateButton({
    name = "Enable First Person",
    callback = function()
        LocalPlayer.CameraMode =
            Enum.CameraMode.LockFirstPerson
    end,
})

CameraTab:CreateButton({
    name = "Enable Third Person",
    callback = function()
        LocalPlayer.CameraMode =
            Enum.CameraMode.Classic
    end,
})

CameraTab:CreateButton({
    name = "Reset Camera",
    callback = function()
        Config.FOV = Original.FOV
        Config.Zoom = Original.Zoom
        LocalPlayer.CameraMode = Original.CameraMode
        ApplyCamera()
    end,
})

-- PERFORMANCE
Performance:CreateSection("Graphics Optimization")

Performance:CreateToggle({
    name = "Low Graphics Mode",
    current = false,
    flag = "BabaLowGraphics",
    callback = function(Value)
        if Config.LowGraphics == Value then return end
        Config.LowGraphics = Value
        SetLowGraphics(Value)
    end,
})

Performance:CreateButton({
    name = "Show Current FPS",
    callback = function()
        Notify(
            "Performance",
            "Current FPS: " .. FPS
        )
    end,
})

Performance:CreateButton({
    name = "Show Current Ping",
    callback = function()
        local Ping = "Unavailable"

        pcall(function()
            Ping = Stats.Network.ServerStatsItem[
                "Data Ping"
            ]:GetValueString()
        end)

        Notify("Network", "Ping: " .. Ping)
    end,
})

-- WORLD
World:CreateSection("Lighting Presets")

World:CreateButton({
    name = "Daylight",
    callback = function()
        Lighting.ClockTime = 12
        Lighting.Brightness = 2
    end,
})

World:CreateButton({
    name = "Night Mode",
    callback = function()
        Lighting.ClockTime = 0
        Lighting.Brightness = 1
    end,
})

World:CreateButton({
    name = "Sunset",
    callback = function()
        Lighting.ClockTime = 18
        Lighting.Brightness = 2
    end,
})

World:CreateButton({
    name = "Bright Mode",
    callback = function()
        Lighting.Brightness = 5
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient =
            Color3.fromRGB(200, 200, 200)
    end,
})

World:CreateButton({
    name = "Remove Local Fog",
    callback = function()
        Lighting.FogEnd = 100000
    end,
})

World:CreateButton({
    name = "Restore Original Lighting",
    callback = function()
        RestoreLighting()
    end,
})

-- CLEANUP
local function Cleanup()
    if not Running then return end
    Running = false

    Config.ESP = false
    ClearESP()

    if Config.LowGraphics then
        Config.LowGraphics = false
        SetLowGraphics(false)
    end

    RestoreLighting()

    Config.WalkSpeed = Original.WalkSpeed
    Config.JumpPower = Original.JumpPower
    Config.FOV = Original.FOV
    Config.Zoom = Original.Zoom

    ApplyMovement()
    ApplyCamera()

    LocalPlayer.CameraMode = Original.CameraMode

    for _, Connection in ipairs(Connections) do
        Connection:Disconnect()
    end

    table.clear(Connections)

    if GUI then
        GUI:Destroy()
    end
end

getgenv().BabaHubCleanup = Cleanup

Track(Players.PlayerRemoving:Connect(function(Player)
    RemoveESP(Player)
end))

Track(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.4)

    if Running then
        ApplyMovement()
        ApplyCamera()
    end
end))

-- SETTINGS
Settings:CreateSection("General Controls")

Settings:CreateButton({
    name = "Disable ESP",
    callback = function()
        Config.ESP = false
        ClearESP()
        Notify("Settings", "ESP disabled.")
    end,
})

Settings:CreateButton({
    name = "Restore Graphics and Lighting",
    callback = function()
        if Config.LowGraphics then
            Config.LowGraphics = false
            SetLowGraphics(false)
        end

        RestoreLighting()
        Notify("Settings", "Visual settings restored.")
    end,
})

Settings:CreateButton({
    name = "Unload Baba Hub Features",
    callback = function()
        Cleanup()
    end,
})

-- INITIALIZE
UpdateHUD()

Notify(
    "Baba Hub V2",
    "Loaded successfully! Enjoy the new features."
)

