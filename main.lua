--[[
    BABA HUB V3 | MM2
    By LLaliLLama_2 (AliBaba)

    Single-file Rayfield Gen2 utility hub.
    Features: live FPS/ping HUD, ESP, player teleport, Shift-click
    teleport, camera/movement tools, local graphics, session info,
    client audio player with searchable library/favorites, dance IDs,
    and server hopping.

    Audio/animations must be accessible Roblox asset IDs.
    Movement, local visuals, and teleport behavior depend on game rules.
    Some games may override them.
]]

-- SERVICES + SAFE RELOAD
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end
local Shared = (type(getgenv) == "function" and getgenv()) or _G
if type(Shared.BabaHubV3Unload) == "function" then
    pcall(Shared.BabaHubV3Unload)
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
local Window = Rayfield:CreateWindow({
    name = "Baba Hub V3 | MM2",
    subtitle = "By LLaliLLama_2",
    sidebarLayout = true,
})

local Alive = true
local Connections = {}
local Highlights = {}
local Nametags = {}
local StartedAt = os.clock()
local Settings = {
    esp = false, espNames = true, espDistance = true, espAlpha = 0.55,
    fps = true, ping = false, clock = false, timer = false,
    speed = 16, jump = 50, fov = 70, zoom = 20,
    shiftClick = false, lowGraphics = false,
    volume = 0.5, loop = false, autoNext = true, danceSpeed = 1,
    danceLoop = true,
}
local Original = {
    zoom = LocalPlayer.CameraMaxZoomDistance,
    cameraMode = LocalPlayer.CameraMode,
    fov = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,
    lighting = {
        Brightness = Lighting.Brightness,
        ClockTime = Lighting.ClockTime,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
    }
}
Settings.fov = Original.fov
local OriginalHumanoid = nil
local MaterialBackup = {}
local SelectedPlayerText = ""
local FPS = 0

local function Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end
local function Notify(title, content)
    if not Alive then return end
    pcall(function()
        Window:Notify({title = tostring(title), content = tostring(content), duration = 4})
    end)
end
local function Humanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function Root(player)
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function Seconds(v)
    v = math.floor(math.max(0, v))
    return string.format("%02d:%02d", math.floor(v / 60), v % 60)
end
local function AssetID(str)
    local s = tostring(str or "")
    local id = s:match("^(%d+)$") or s:match("rbxassetid://(%d+)")
    if id and #id <= 20 then return id end
    return nil
end
local function ApplyMovement()
    local h = Humanoid()
    if h then
        h.WalkSpeed = Settings.speed
        h.UseJumpPower = true
        h.JumpPower = Settings.jump
    end
end
local function ApplyCamera()
    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = Settings.fov
    end
    LocalPlayer.CameraMaxZoomDistance = Settings.zoom
end
local function RestoreLighting()
    for property, value in pairs(Original.lighting) do
        pcall(function() Lighting[property] = value end)
    end
end

-- PLAYER HIGHLIGHTS
local ESPColor = Color3.fromRGB(154, 112, 255)
local function RemoveESP(player)
    if Highlights[player] then Highlights[player]:Destroy() end
    if Nametags[player] then Nametags[player]:Destroy() end
    Highlights[player], Nametags[player] = nil, nil
end
local function ClearESP()
    for player in pairs(Highlights) do RemoveESP(player) end
    for player in pairs(Nametags) do RemoveESP(player) end
end
local function UpdateESP(player)
    if player == LocalPlayer then return end
    local char, root = player.Character, Root(player)
    if not Settings.esp or not char or not root then
        RemoveESP(player)
        return
    end
    local mark = Highlights[player]
    if mark and mark.Adornee ~= char then
        RemoveESP(player)
        mark = nil
    end
    if not mark then
        mark = Instance.new("Highlight")
        mark.Name = "BabaHubPlayerOutline"
        mark.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        mark.Adornee = char
        mark.Parent = char
        Highlights[player] = mark
    end
    mark.FillColor = ESPColor
    mark.OutlineColor = ESPColor
    mark.FillTransparency = Settings.espAlpha
    mark.OutlineTransparency = 0

    local tag = Nametags[player]
    if tag and tag.Adornee ~= root then
        tag:Destroy()
        tag = nil
    end
    if not tag then
        tag = Instance.new("BillboardGui")
        tag.Name = "BabaHubNameTag"
        tag.Adornee = root
        tag.Size = UDim2.fromOffset(230, 48)
        tag.StudsOffset = Vector3.new(0, 3.2, 0)
        tag.AlwaysOnTop = true
        tag.Parent = root
        local label = Instance.new("TextLabel")
        label.Name = "Text"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextColor3 = ESPColor
        label.TextStrokeTransparency = 0.2
        label.TextSize = 13
        label.Parent = tag
        Nametags[player] = tag
    end
    tag.Enabled = Settings.espNames or Settings.espDistance
    local chunks = {}
    if Settings.espNames then table.insert(chunks, player.DisplayName) end
    if Settings.espDistance then
        local myRoot = Root(LocalPlayer)
        if myRoot then
            table.insert(chunks, tostring(math.floor((myRoot.Position - root.Position).Magnitude)) .. " studs")
        end
    end
    local tagText = tag:FindFirstChild("Text")
    if tagText then tagText.Text = table.concat(chunks, " | ") end
end
local function RefreshESP()
    for _, p in ipairs(Players:GetPlayers()) do UpdateESP(p) end
end

-- TELEPORT UTILITIES
local function FindPlayer(query)
    query = tostring(query or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if query == "" then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Name:lower() == query then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Name:lower():sub(1, #query) == query then return p end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.DisplayName:lower():sub(1, #query) == query then return p end
    end
    return nil
end
local function TeleportNearPlayer(query)
    local target = FindPlayer(query)
    local mine = Root(LocalPlayer)
    local theirs = target and Root(target)
    if not mine or not theirs then
        Notify("Teleport", "Player not found or character unavailable.")
        return
    end
    mine.CFrame = theirs.CFrame * CFrame.new(3, 0, 3)
    Notify("Teleport", "Moved near " .. target.Name)
end
local function TeleportAt(worldPos)
    local mine = Root(LocalPlayer)
    if not mine then return end
    mine.CFrame = CFrame.new(worldPos + Vector3.new(0, 3, 0))
end

-- MUSIC LIBRARY (ROBLOX AUDIO ASSET IDS)
local Music = Instance.new("Sound")
Music.Name = "BabaHubClientMusic"
Music.Volume = Settings.volume
Music.Looped = Settings.loop
Music.Parent = SoundService

local Library = {}
local CurrentSong = nil
local AudioInput = ""
local SongNameInput = ""
local FilterFavorites = false
local FileName = "BabaHubV3_music.json"
local MusicListWindow = nil
local SongRows = nil
local MusicStatus = nil
local LibraryStatus = nil

local function SaveLibrary()
    if type(writefile) ~= "function" then return end
    local ok, json = pcall(function()
        return HttpService:JSONEncode({songs = Library, volume = Settings.volume, loop = Settings.loop, autoNext = Settings.autoNext})
    end)
    if ok then pcall(writefile, FileName, json) end
end
local function LoadLibrary()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    local exists, yes = pcall(isfile, FileName)
    if not exists or not yes then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(FileName))
    end)
    if not ok or type(data) ~= "table" then return end
    if type(data.songs) == "table" then
        for _, entry in ipairs(data.songs) do
            if type(entry) == "table" and AssetID(entry.id) and #Library < 200 then
                table.insert(Library, {
                    id = AssetID(entry.id),
                    name = tostring(entry.name or entry.id):sub(1, 60),
                    favorite = entry.favorite == true,
                })
            end
        end
    end
    if type(data.volume) == "number" then
        Settings.volume = math.clamp(data.volume, 0, 1)
    end
    if type(data.loop) == "boolean" then Settings.loop = data.loop end
    if type(data.autoNext) == "boolean" then Settings.autoNext = data.autoNext end
    Music.Volume = Settings.volume
    Music.Looped = Settings.loop
end
LoadLibrary()

local function MusicInfo()
    local item = CurrentSong and Library[CurrentSong]
    if not item then return "Nothing selected" end
    return item.name .. " | " .. item.id .. (item.favorite and "  [FAV]" or "")
end
local function UpdateMusicInfo()
    if MusicStatus then MusicStatus:Set(MusicInfo()) end
    if LibraryStatus then LibraryStatus:Set(#Library .. " saved tracks") end
end
local function PlayIndex(index)
    local item = Library[index]
    if not item then
        Notify("Music", "Select a song from your library first.")
        return
    end
    CurrentSong = index
    Music:Stop()
    Music.SoundId = "rbxassetid://" .. item.id
    Music.TimePosition = 0
    Music:Play()
    UpdateMusicInfo()
end
local function SongExists(id)
    for i, song in ipairs(Library) do
        if song.id == id then return i end
    end
    return nil
end
local function AddSong(id, name)
    id = AssetID(id)
    if not id then
        Notify("Music", "Enter a numeric Roblox audio asset ID.")
        return
    end
    local exists = SongExists(id)
    if exists then
        CurrentSong = exists
        Notify("Library", "Song already saved; selected existing entry.")
    else
        if #Library >= 200 then
            Notify("Library", "Library limit: 200 songs.")
            return
        end
        table.insert(Library, {
            id = id,
            name = (tostring(name or ""):match("%S") and tostring(name):sub(1, 60)) or ("Audio " .. id),
            favorite = false,
        })
        CurrentSong = #Library
    end
    SaveLibrary()
    UpdateMusicInfo()
end
local function PlayAdjacent(direction)
    if #Library == 0 then
        Notify("Music", "Your library is empty.")
        return
    end
    local nextIndex = ((CurrentSong or (direction == 1 and 0 or 1)) - 1 + direction) % #Library + 1
    PlayIndex(nextIndex)
end

Connect(Music.Ended, function()
    if Alive and Settings.autoNext and not Music.Looped and #Library > 0 then
        PlayAdjacent(1)
    end
end)

-- CUSTOM MUSIC LIBRARY BROWSER
local function UI(class, fields, parent)
    local obj = Instance.new(class)
    for k, v in pairs(fields or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local ScreenGui = UI("ScreenGui", {
    Name = "BabaHubV3Overlays", ResetOnSpawn = false,
    IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, LocalPlayer:WaitForChild("PlayerGui"))

local function MakeRounded(frame, radius)
    UI("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, frame)
end
local function RenderSongRows()
    if not SongRows then return end
    for _, child in ipairs(SongRows:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    local y = 0
    for i, song in ipairs(Library) do
        if not FilterFavorites or song.favorite then
            local index = i
            local label = (song.favorite and "★ " or "") .. song.name .. "  [" .. song.id .. "]"
            local button = UI("TextButton", {
                Name = "Track" .. i,
                Size = UDim2.new(1, -8, 0, 36),
                Position = UDim2.fromOffset(4, y),
                BackgroundColor3 = i == CurrentSong and Color3.fromRGB(74, 48, 135) or Color3.fromRGB(35, 35, 52),
                TextColor3 = Color3.fromRGB(240, 240, 250),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = "  " .. label,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, SongRows)
            MakeRounded(button, 7)
            button.MouseButton1Click:Connect(function()
                PlayIndex(index)
                RenderSongRows()
            end)
            y = y + 40
        end
    end
    SongRows.CanvasSize = UDim2.fromOffset(0, y)
end
local function ShowMusicLibrary()
    if MusicListWindow then
        MusicListWindow.Visible = not MusicListWindow.Visible
        RenderSongRows()
        return
    end
    local panel = UI("Frame", {
        Name = "MusicLibrary", Size = UDim2.fromOffset(350, 375),
        Position = UDim2.new(0.5, -175, 0.5, -187),
        BackgroundColor3 = Color3.fromRGB(19, 19, 30),
        Active = true, Visible = true,
    }, ScreenGui)
    MakeRounded(panel, 13)
    UI("UIStroke", {Color = Color3.fromRGB(130, 85, 255), Thickness = 1.5}, panel)
    UI("TextLabel", {
        Size = UDim2.new(1, -55, 0, 46), Position = UDim2.fromOffset(14, 0),
        BackgroundTransparency = 1, Text = "BABA HUB  •  MUSIC LIBRARY",
        Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = Color3.fromRGB(225, 210, 255), TextXAlignment = Enum.TextXAlignment.Left,
    }, panel)
    local close = UI("TextButton", {
        Size = UDim2.fromOffset(32, 30), Position = UDim2.new(1, -43, 0, 8),
        BackgroundColor3 = Color3.fromRGB(90, 50, 130),
        Text = "X", Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1),
    }, panel)
    MakeRounded(close, 7)
    Connect(close.MouseButton1Click, function() panel.Visible = false end)
    SongRows = UI("ScrollingFrame", {
        Name = "Tracks", Position = UDim2.fromOffset(12, 50),
        Size = UDim2.new(1, -24, 1, -110),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4, CanvasSize = UDim2.fromOffset(0, 0),
    }, panel)
    local fav = UI("TextButton", {
        Size = UDim2.new(0.5, -16, 0, 36), Position = UDim2.new(0, 12, 1, -46),
        BackgroundColor3 = Color3.fromRGB(70, 42, 115),
        Text = "Toggle Favorites", TextSize = 12,
        Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1),
    }, panel)
    MakeRounded(fav, 8)
    Connect(fav.MouseButton1Click, function()
        FilterFavorites = not FilterFavorites
        fav.Text = FilterFavorites and "Showing Favorites" or "Toggle Favorites"
        RenderSongRows()
    end)
    local favoriteCurrent = UI("TextButton", {
        Size = UDim2.new(0.5, -16, 0, 36), Position = UDim2.new(0.5, 4, 1, -46),
        BackgroundColor3 = Color3.fromRGB(70, 42, 115),
        Text = "★ Favorite Selected", TextSize = 12,
        Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1),
    }, panel)
    MakeRounded(favoriteCurrent, 8)
    Connect(favoriteCurrent.MouseButton1Click, function()
        local item = CurrentSong and Library[CurrentSong]
        if item then
            item.favorite = not item.favorite
            SaveLibrary()
            RenderSongRows()
            UpdateMusicInfo()
        end
    end)
    -- Drag panel by title area
    local dragging, dragInput, startInput, startPos = false, nil, nil, nil
    Connect(panel.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Position.Y <= panel.AbsolutePosition.Y + 44 then
                dragging, startInput, startPos = true, input.Position, panel.Position
                dragInput = input
            end
        end
    end)
    Connect(UserInputService.InputChanged, function(input)
        if dragging and startInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput) then
            local delta = input.Position - startInput
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input == dragInput then
            dragging, dragInput = false, nil
        end
    end)
    MusicListWindow = panel
    RenderSongRows()
end

-- HUD
local HUD = UI("Frame", {
    Name = "DraggableStatsHUD", Position = UDim2.new(1, -190, 0, 85),
    Size = UDim2.fromOffset(175, 55), BackgroundColor3 = Color3.fromRGB(18, 18, 32),
    BackgroundTransparency = 0.12, Active = true,
}, ScreenGui)
MakeRounded(HUD, 10)
UI("UIStroke", {Color = Color3.fromRGB(120, 75, 230), Thickness = 1}, HUD)
UI("TextLabel", {
    Size = UDim2.new(1, -10, 0, 24), Position = UDim2.fromOffset(8, 3),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
    TextColor3 = Color3.fromRGB(190, 160, 255), TextXAlignment = Enum.TextXAlignment.Left,
    Text = "BABA HUB V3",
}, HUD)
local HUDLines = {}
for _, name in ipairs({"fps", "ping", "clock", "timer"}) do
    HUDLines[name] = UI("TextLabel", {
        Name = name, Size = UDim2.new(1, -14, 0, 21),
        BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(235, 235, 245),
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium, TextSize = 12,
        Text = name .. ": --", Visible = false,
    }, HUD)
end
local function UpdateHUD()
    local count = 0
    for _, name in ipairs({"fps", "ping", "clock", "timer"}) do
        local label = HUDLines[name]
        label.Visible = Settings[name]
        if Settings[name] then
            label.Position = UDim2.fromOffset(12, 27 + 21 * count)
            count = count + 1
        end
    end
    HUD.Visible = count > 0
    HUD.Size = UDim2.fromOffset(175, 36 + 21 * count)
    HUDLines.fps.Text = "FPS: " .. tostring(FPS)
    if Settings.ping then
        local ping = "N/A"
        pcall(function() ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString() end)
        HUDLines.ping.Text = "Ping: " .. ping
    end
    HUDLines.clock.Text = "Time: " .. os.date("%H:%M:%S")
    HUDLines.timer.Text = "Session: " .. Seconds(os.clock() - StartedAt)
end
local HUDDrag, HUDStart, HUDPos, HUDInput = false, nil, nil, nil
Connect(HUD.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        HUDDrag, HUDStart, HUDPos, HUDInput = true, input.Position, HUD.Position, input
    end
end)
Connect(UserInputService.InputChanged, function(input)
    if HUDDrag and HUDStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input == HUDInput) then
        local delta = input.Position - HUDStart
        HUD.Position = UDim2.new(HUDPos.X.Scale, HUDPos.X.Offset + delta.X,
            HUDPos.Y.Scale, HUDPos.Y.Offset + delta.Y)
    end
end)
Connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input == HUDInput then
        HUDDrag, HUDInput = false, nil
    end
end)

-- LOW GRAPHICS (LOCAL MATERIALS)
local function SetLowGraphics(enabled)
    if enabled then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not MaterialBackup[obj] then
                MaterialBackup[obj] = {obj.Material, obj.Reflectance}
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            end
        end
        Lighting.GlobalShadows = false
    else
        for obj, old in pairs(MaterialBackup) do
            if obj.Parent then
                pcall(function()
                    obj.Material, obj.Reflectance = old[1], old[2]
                end)
            end
        end
        table.clear(MaterialBackup)
        Lighting.GlobalShadows = Original.lighting.GlobalShadows
    end
end

-- DANCE SYSTEM
local DanceInput = ""
local DanceTrack = nil
local DanceAnimation = nil
local function StopDance()
    if DanceTrack then
        pcall(function() DanceTrack:Stop(0.15) end)
        DanceTrack = nil
    end
    if DanceAnimation then DanceAnimation:Destroy(); DanceAnimation = nil end
end
local function PlayDanceId(raw)
    local id = AssetID(raw)
    if not id then Notify("Dances", "Enter a numeric Roblox animation ID."); return end
    local h = Humanoid()
    local animator = h and h:FindFirstChildOfClass("Animator")
    if not animator then Notify("Dances", "Character animator unavailable."); return end
    StopDance()
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. id
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if ok and track then
        DanceAnimation = anim
        DanceTrack = track
        track.Looped = Settings.danceLoop
        track:Play(0.15, 1, Settings.danceSpeed)
        Notify("Dances", "Animation requested: " .. id)
    else
        anim:Destroy()
        Notify("Dances", "Animation couldn't be loaded or isn't accessible.")
    end
end
local function PlayEmote(name)
    local h = Humanoid()
    if not h then return end
    StopDance()
    local ok = pcall(function() h:PlayEmote(name) end)
    if not ok then Notify("Dances", "That emote isn't available for this avatar.") end
end

-- SERVER HOP
local HopBusy = false
local function ServerHop()
    if HopBusy then return end
    HopBusy = true
    Notify("Servers", "Checking public servers...")
    task.spawn(function()
        local ok, result = pcall(function()
            local endpoint = "https://games.roblox.com/v1/games/" .. game.PlaceId
                .. "/servers/Public?sortOrder=Asc&limit=100"
            return HttpService:JSONDecode(game:HttpGet(endpoint))
        end)
        if not Alive then return end
        if not ok or type(result) ~= "table" or type(result.data) ~= "table" then
            HopBusy = false
            Notify("Servers", "Server list unavailable in this environment.")
            return
        end
        local choices = {}
        for _, entry in ipairs(result.data) do
            if type(entry) == "table" and type(entry.id) == "string"
                and entry.id ~= game.JobId and (entry.playing or 999) < (entry.maxPlayers or 0) then
                table.insert(choices, entry.id)
            end
        end
        if #choices == 0 then
            HopBusy = false
            Notify("Servers", "No different public server found on this page.")
            return
        end
        local target = choices[math.random(1, #choices)]
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, target, LocalPlayer)
        end)
        HopBusy = false
        if not success then Notify("Servers", "Could not hop: " .. tostring(err):sub(1, 100)) end
    end)
end

-- TABS
local Home = Window:CreateTab({name = "Home"})
local Visuals = Window:CreateTab({name = "Visuals"})
local HUDTab = Window:CreateTab({name = "HUD"})
local Teleports = Window:CreateTab({name = "Teleports"})
local Movement = Window:CreateTab({name = "Movement"})
local CameraTab = Window:CreateTab({name = "Camera"})
local Performance = Window:CreateTab({name = "Performance"})
local World = Window:CreateTab({name = "World"})
local MusicTab = Window:CreateTab({name = "Music"})
local Dances = Window:CreateTab({name = "Dances"})
local Servers = Window:CreateTab({name = "Servers"})
local General = Window:CreateTab({name = "Settings"})

-- HOME
Home:CreateSection({name = "Welcome"})
Home:CreateText({name = "Baba Hub V3", text = "MM2 utility hub by LLaliLLama_2. Features are client-side and may be overridden by the game."})
Home:CreateButton({name = "My Profile", callback = function()
    Notify("Profile", LocalPlayer.Name .. " | UserId " .. LocalPlayer.UserId)
end})
Home:CreateButton({name = "Session Duration", callback = function()
    Notify("Session", Seconds(os.clock() - StartedAt))
end})
Home:CreateButton({name = "Players in Server", callback = function()
    Notify("Players", #Players:GetPlayers() .. " / " .. Players.MaxPlayers)
end})

-- VISUALS
Visuals:CreateSection({name = "Player ESP"})
Visuals:CreateToggle({name = "Enable Highlights", value = false, flag = "B3ESP", callback = function(v)
    Settings.esp = v
    if v then RefreshESP() else ClearESP() end
end})
Visuals:CreateToggle({name = "Names", value = true, flag = "B3Names", callback = function(v)
    Settings.espNames = v; RefreshESP()
end})
Visuals:CreateToggle({name = "Distance", value = true, flag = "B3Distance", callback = function(v)
    Settings.espDistance = v; RefreshESP()
end})
Visuals:CreateSlider({name = "Fill Transparency", range = {0, 100}, increment = 5,
    value = 55, suffix = "%", flag = "B3ESPAlpha", callback = function(v)
        Settings.espAlpha = v / 100; RefreshESP()
    end})
Visuals:CreateButton({name = "Refresh Players", callback = RefreshESP})
Visuals:CreateButton({name = "Clear Highlights", callback = function()
    Settings.esp = false; ClearESP()
    Notify("ESP", "Highlights cleared. Toggle may need switching off in the menu.")
end})

-- HUD
HUDTab:CreateSection({name = "Draggable Performance Overlay"})
for _, spec in ipairs({
    {"FPS Counter", "fps"}, {"Ping", "ping"}, {"Clock", "clock"}, {"Session Timer", "timer"},
}) do
    local label, key = spec[1], spec[2]
    HUDTab:CreateToggle({name = "Show " .. label, value = Settings[key],
        flag = "B3HUD" .. key, callback = function(v)
            Settings[key] = v; UpdateHUD()
        end})
end
HUDTab:CreateSlider({name = "HUD Transparency", range = {0, 90}, increment = 5,
    value = 10, suffix = "%", flag = "B3HUDAlpha", callback = function(v)
        HUD.BackgroundTransparency = v / 100
    end})
HUDTab:CreateButton({name = "Reset HUD Position", callback = function()
    HUD.Position = UDim2.new(1, -190, 0, 85)
end})

-- TELEPORTS
Teleports:CreateSection({name = "Teleport to Player"})
Teleports:CreateInput({name = "Player Username / Display Name", placeholder = "Enter player name",
    flag = "B3Target", callback = function(v) SelectedPlayerText = tostring(v) end})
Teleports:CreateButton({name = "Teleport Near Player", callback = function()
    TeleportNearPlayer(SelectedPlayerText)
end})
Teleports:CreateButton({name = "List Player Names", callback = function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    Notify("Players", (#list > 0 and table.concat(list, ", ") or "Nobody else here"):sub(1, 250))
end})
Teleports:CreateSection({name = "Click Teleport"})
Teleports:CreateToggle({name = "Shift + Click Teleport", value = false,
    flag = "B3ShiftClick", callback = function(v) Settings.shiftClick = v end})
Teleports:CreateText({text = "Hold Left Shift and left-click the world to move to that point. Disable before using normal controls if needed."})

-- MOVEMENT
Movement:CreateSection({name = "Character Settings"})
Movement:CreateSlider({name = "WalkSpeed", range = {10, 50}, increment = 1,
    value = 16, flag = "B3Walk", callback = function(v) Settings.speed = v; ApplyMovement() end})
Movement:CreateSlider({name = "Jump Power", range = {25, 100}, increment = 5,
    value = 50, flag = "B3Jump", callback = function(v) Settings.jump = v; ApplyMovement() end})
Movement:CreateButton({name = "Reset Movement", callback = function()
    Settings.speed, Settings.jump = 16, 50
    ApplyMovement(); Notify("Movement", "Speed and jump reset; sliders may retain their previous display.")
end})

-- CAMERA
CameraTab:CreateSection({name = "View Settings"})
CameraTab:CreateSlider({name = "Field of View", range = {40, 120}, increment = 2,
    value = Original.fov, flag = "B3FOV", callback = function(v) Settings.fov = v; ApplyCamera() end})
CameraTab:CreateSlider({name = "Maximum Zoom", range = {5, 100}, increment = 1,
    value = 20, flag = "B3Zoom", callback = function(v) Settings.zoom = v; ApplyCamera() end})
CameraTab:CreateButton({name = "First Person", callback = function()
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
end})
CameraTab:CreateButton({name = "Third Person", callback = function()
    LocalPlayer.CameraMode = Enum.CameraMode.Classic
end})
CameraTab:CreateButton({name = "Reset Camera", callback = function()
    Settings.fov, Settings.zoom = Original.fov, Original.zoom
    LocalPlayer.CameraMode = Original.cameraMode
    ApplyCamera()
end})

-- PERFORMANCE
Performance:CreateSection({name = "Local Graphics"})
Performance:CreateToggle({name = "Low Graphics Mode", value = false,
    flag = "B3LowGraphics", callback = function(v)
        Settings.lowGraphics = v; SetLowGraphics(v)
    end})
Performance:CreateButton({name = "Check FPS", callback = function()
    Notify("FPS", tostring(FPS))
end})
Performance:CreateButton({name = "Restore Graphics", callback = function()
    Settings.lowGraphics = false; SetLowGraphics(false)
    Notify("Graphics", "Available materials restored.")
end})

-- WORLD
World:CreateSection({name = "Local Lighting Presets"})
World:CreateButton({name = "Daylight", callback = function()
    Lighting.ClockTime, Lighting.Brightness = 12, 2
end})
World:CreateButton({name = "Sunset", callback = function()
    Lighting.ClockTime, Lighting.Brightness = 18, 2
end})
World:CreateButton({name = "Night", callback = function()
    Lighting.ClockTime, Lighting.Brightness = 0, 1
end})
World:CreateButton({name = "Bright Ambient", callback = function()
    Lighting.Ambient = Color3.fromRGB(195, 195, 195)
    Lighting.OutdoorAmbient = Color3.fromRGB(195, 195, 195)
    Lighting.Brightness = 4
end})
World:CreateButton({name = "Remove Local Fog", callback = function()
    Lighting.FogEnd = 100000
end})
World:CreateButton({name = "Restore Lighting", callback = RestoreLighting})

-- MUSIC
MusicTab:CreateSection({name = "Now Playing"})
MusicStatus = MusicTab:CreateText({name = "Selected Song", text = "Nothing selected"})
MusicTab:CreateButton({name = "Play Selected", callback = function()
    PlayIndex(CurrentSong)
end})
MusicTab:CreateButton({name = "Pause", callback = function() Music:Pause() end})
MusicTab:CreateButton({name = "Resume", callback = function() Music:Resume() end})
MusicTab:CreateButton({name = "Stop", callback = function() Music:Stop() end})
MusicTab:CreateButton({name = "Previous", callback = function() PlayAdjacent(-1) end})
MusicTab:CreateButton({name = "Next", callback = function() PlayAdjacent(1) end})
MusicTab:CreateSlider({name = "Volume", range = {0, 100}, increment = 5,
    value = math.floor(Settings.volume * 100 + 0.5), suffix = "%",
    flag = "B3MusicVolume", callback = function(v)
        Settings.volume = v / 100; Music.Volume = Settings.volume; SaveLibrary()
    end})
MusicTab:CreateToggle({name = "Loop Song", value = Settings.loop,
    flag = "B3MusicLoop", callback = function(v)
        Settings.loop = v; Music.Looped = v; SaveLibrary()
    end})
MusicTab:CreateToggle({name = "Auto-play Next Track", value = Settings.autoNext,
    flag = "B3MusicAutoNext", callback = function(v)
        Settings.autoNext = v; SaveLibrary()
    end})
MusicTab:CreateSection({name = "My Library"})
MusicTab:CreateInput({name = "Roblox Audio ID", placeholder = "Numbers only",
    flag = "B3AudioID", callback = function(v) AudioInput = tostring(v) end})
MusicTab:CreateInput({name = "Track Name", placeholder = "A name for this track",
    flag = "B3AudioName", callback = function(v) SongNameInput = tostring(v) end})
MusicTab:CreateButton({name = "Add Track to Library", callback = function()
    AddSong(AudioInput, SongNameInput)
    RenderSongRows()
end})
MusicTab:CreateButton({name = "Open / Close Library Browser", callback = ShowMusicLibrary})
MusicTab:CreateButton({name = "Toggle Favorite on Selected", callback = function()
    local entry = CurrentSong and Library[CurrentSong]
    if not entry then Notify("Music", "Select a track first."); return end
    entry.favorite = not entry.favorite
    SaveLibrary(); UpdateMusicInfo(); RenderSongRows()
end})
MusicTab:CreateButton({name = "Remove Selected Track", callback = function()
    if not CurrentSong or not Library[CurrentSong] then return end
    Music:Stop()
    table.remove(Library, CurrentSong)
    CurrentSong = #Library > 0 and math.min(CurrentSong, #Library) or nil
    SaveLibrary(); UpdateMusicInfo(); RenderSongRows()
end})
LibraryStatus = MusicTab:CreateText({name = "Saved Songs", text = tostring(#Library) .. " saved tracks"})
MusicTab:CreateText({text = "Roblox audio assets must be accessible to the experience. Arbitrary SoundCloud links cannot be played as Roblox SoundIds. Music is client-side; saving requires readfile/writefile support."})

-- DANCES
Dances:CreateSection({name = "Avatar Emotes"})
for _, emote in ipairs({"dance", "dance2", "dance3", "wave", "cheer", "point"}) do
    local name = emote
    Dances:CreateButton({name = "Play " .. name, callback = function()
        PlayEmote(name)
    end})
end
Dances:CreateSection({name = "Custom Roblox Animation"})
Dances:CreateInput({name = "Animation Asset ID", placeholder = "Numeric animation ID",
    flag = "B3DanceID", callback = function(v) DanceInput = tostring(v) end})
Dances:CreateButton({name = "Play Custom Animation", callback = function()
    PlayDanceId(DanceInput)
end})
Dances:CreateButton({name = "Stop Custom Animation", callback = StopDance})
Dances:CreateSlider({name = "Dance Speed", range = {25, 200}, increment = 5,
    value = 100, suffix = "%", flag = "B3DanceSpeed", callback = function(v)
        Settings.danceSpeed = v / 100
        if DanceTrack then DanceTrack:AdjustSpeed(Settings.danceSpeed) end
    end})
Dances:CreateToggle({name = "Loop Dance", value = true, flag = "B3DanceLoop",
    callback = function(v)
        Settings.danceLoop = v
        if DanceTrack then DanceTrack.Looped = v end
    end})
Dances:CreateText({text = "Custom animations must be available to the avatar/experience. Some emotes may not be playable in MM2."})

-- SERVERS
Servers:CreateSection({name = "Server Management"})
Servers:CreateText({name = "Current Job ID", text = game.JobId})
Servers:CreateButton({name = "Copy Server ID", callback = function()
    if type(setclipboard) == "function" then
        setclipboard(game.JobId)
        Notify("Servers", "Copied server ID.")
    else
        Notify("Servers", "Clipboard access unavailable.")
    end
end})
Servers:CreateButton({name = "Find a Different Public Server", callback = ServerHop})
Servers:CreateButton({name = "Rejoin This Place", callback = function()
    local ok, err = pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
    if not ok then Notify("Servers", "Rejoin failed: " .. tostring(err)) end
end})
Servers:CreateText({text = "Server hopping requires access to Roblox public-server listings and working teleport permissions. It does not guarantee an empty or low-latency server."})

-- SETTINGS + CLEANUP
local function Unload()
    if not Alive then return end
    Alive = false
    ClearESP()
    StopDance()
    Music:Stop()
    Music:Destroy()
    Settings.shiftClick = false
    if Settings.lowGraphics then SetLowGraphics(false) end
    RestoreLighting()
    if OriginalHumanoid and OriginalHumanoid.Parent then
        pcall(function()
            OriginalHumanoid.h.WalkSpeed = OriginalHumanoid.speed
            OriginalHumanoid.h.UseJumpPower = OriginalHumanoid.useJumpPower
            OriginalHumanoid.h.JumpPower = OriginalHumanoid.jump
        end)
    end
    Settings.fov, Settings.zoom = Original.fov, Original.zoom
    ApplyCamera()
    LocalPlayer.CameraMode = Original.cameraMode
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)
    ScreenGui:Destroy()
    if Shared.BabaHubV3Unload == Unload then Shared.BabaHubV3Unload = nil end
    -- Close Rayfield if the installed Gen2 version exposes a destroy method.
    pcall(function() if type(Window.Destroy) == "function" then Window:Destroy() end end)
end
Shared.BabaHubV3Unload = Unload
General:CreateSection({name = "Baba Hub Controls"})
General:CreateButton({name = "Stop All Music and Dances", callback = function()
    Music:Stop(); StopDance(); Notify("Settings", "Playback stopped.")
end})
General:CreateButton({name = "Restore Default Movement and Camera", callback = function()
    Settings.speed, Settings.jump = 16, 50
    Settings.fov, Settings.zoom = Original.fov, Original.zoom
    ApplyMovement(); ApplyCamera()
    Notify("Settings", "Movement and camera restored.")
end})
General:CreateButton({name = "Unload Baba Hub V3", callback = Unload})
General:CreateText({text = "Your music library is stored locally where file APIs exist. The other controls reset when the script reloads. The menu may remain if your Rayfield build lacks Window:Destroy()."})

-- RUNTIME CONNECTIONS
Connect(Players.PlayerRemoving, function(p) RemoveESP(p) end)
Connect(LocalPlayer.CharacterAdded, function(character)
    StopDance()
    task.wait(0.5)
    if Alive then
        local h = character:FindFirstChildOfClass("Humanoid")
        if h then
            OriginalHumanoid = {
                h = h, speed = h.WalkSpeed, jump = h.JumpPower, useJumpPower = h.UseJumpPower,
            }
        end
        ApplyMovement()
        ApplyCamera()
    end
end)

-- Capture original humanoid settings before our first modification.
do
    local h = Humanoid()
    if h then
        OriginalHumanoid = {
            h = h, speed = h.WalkSpeed, jump = h.JumpPower, useJumpPower = h.UseJumpPower,
        }
    end
end

Connect(UserInputService.InputBegan, function(input, processed)
    if not Alive or processed or not Settings.shiftClick then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then return end
    local mouse = LocalPlayer:GetMouse()
    if mouse and mouse.Target then
        TeleportAt(mouse.Hit.Position)
    end
end)

local frames, frameElapsed, HUDTick, ESPTick = 0, 0, 0, 0
Connect(RunService.RenderStepped, function(dt)
    if not Alive then return end
    frames = frames + 1
    frameElapsed = frameElapsed + dt
    HUDTick = HUDTick + dt
    ESPTick = ESPTick + dt
    if frameElapsed >= 0.5 then
        FPS = math.floor(frames / frameElapsed + 0.5)
        frames, frameElapsed = 0, 0
    end
    if HUDTick >= 0.5 then
        HUDTick = 0
        UpdateHUD()
    end
    if ESPTick >= 0.5 then
        ESPTick = 0
        if Settings.esp then RefreshESP() end
    end
end)

UpdateHUD()
UpdateMusicInfo()
Notify("Baba Hub V3", "Loaded: HUD, visuals, teleport, music, dances, and more.")
