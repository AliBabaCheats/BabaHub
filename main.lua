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
    StopFarm()
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
General:CreateButton({name = "Unload Baba Hub V4", callback = Unload})
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
    if Farm.enabled then
        Farm.scanElapsed = Farm.scanElapsed + dt
        Farm.moveElapsed = Farm.moveElapsed + dt
        if Farm.scanElapsed >= Farm.scanInterval then
            Farm.scanElapsed = 0
            ScanCollectibles()
        end
        if Farm.moveElapsed >= Farm.moveInterval then
            Farm.moveElapsed = 0
            local target = NearestCollectible()
            local hum = Humanoid()
            if target and hum then hum:MoveTo(target.Position) end
        end
    end
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
Notify("Baba Hub V4", "Loaded: Rayfield UI, Candy Farm, HUD, music, dances, and more.")
