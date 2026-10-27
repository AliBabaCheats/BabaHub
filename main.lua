--[[
  BABA HUB V4 - CUSTOM DASHBOARD
  By AliBabaCheats
  Standalone client-side Roblox Lua UI. No Rayfield required.
  Audio uses accessible Roblox asset IDs; arbitrary SoundCloud URLs cannot play in SoundService.
  Data stored in this script's running session (not saved across restarts).
]]
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local SoundService = game:GetService('SoundService')
local Lighting = game:GetService('Lighting')
local Stats = game:GetService('Stats')
local TeleportService = game:GetService('TeleportService')
local player = Players.LocalPlayer
local playerGui = player:WaitForChild('PlayerGui')

-- Clean up previous run
local existing = playerGui:FindFirstChild('BabaHubV4')
if existing then existing:Destroy() end
local C = { bg = Color3.fromRGB(12,13,19), panel = Color3.fromRGB(22,23,32), raised = Color3.fromRGB(31,32,44), outline = Color3.fromRGB(53,53,70), accent = Color3.fromRGB(148,81,255), accent2 = Color3.fromRGB(190,147,255), white = Color3.fromRGB(244,241,255), muted = Color3.fromRGB(157,154,178), green = Color3.fromRGB(96,222,173), red = Color3.fromRGB(251,118,139) }
local alive = true
local connections = {}
local esp = {}
local liveLabels = {}
local playing = nil
local songs = {}
local favorites = {}
local selectedSong = 0
local farmEnabled = false
local farmCandidates = {}
local farmPosition = nil
local farmLastScan = 0
local farmLastMove = 0
local farmCollectedEstimate = 0
local currentDance = nil
local original = { fov = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70, brightness = Lighting.Brightness, clock = Lighting.ClockTime, fog = Lighting.FogEnd, ambient = Lighting.Ambient, shadows = Lighting.GlobalShadows, zoom = player.CameraMaxZoomDistance }
local settings = { esp = false, espNames = true, speed = 16, jump = 50, fpsHud = true, loop = false, volume = 0.5 }
local function connect(signal, fn) local c = signal:Connect(fn); table.insert(connections,c); return c end
local function make(class, props, parent)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent
    return o
end
local function round(obj,r) make('UICorner',{CornerRadius=UDim.new(0,r or 12)},obj) end
local function border(obj,col) make('UIStroke',{Color=col or C.outline,Thickness=1,Transparency=0.25},obj) end
local function pad(obj,t,r,b,l) make('UIPadding',{PaddingTop=UDim.new(0,t),PaddingRight=UDim.new(0,r),PaddingBottom=UDim.new(0,b),PaddingLeft=UDim.new(0,l)},obj) end
local function text(parent,content,size,color,bold)
    return make('TextLabel',{BackgroundTransparency=1,Text=content,TextColor3=color or C.white,TextSize=size or 14,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true},parent)
end
local gui=make('ScreenGui',{Name='BabaHubV4',ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},playerGui)
local main=make('Frame',{Name='Dashboard',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(850,540),BackgroundColor3=C.bg,BorderSizePixel=0,ClipsDescendants=true},gui)
round(main,19); border(main,C.accent)
local scale=make('UIScale',{Scale=1},main)
local function rescale()
    local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
    scale.Scale=math.clamp(math.min(view.X/910,view.Y/600),.48,1)
end
rescale()
connect(workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'),rescale)

local top=make('Frame',{Size=UDim2.new(1,0,0,64),BackgroundColor3=C.panel,BorderSizePixel=0},main)
local logo=make('TextLabel',{Position=UDim2.fromOffset(23,12),Size=UDim2.fromOffset(43,40),BackgroundColor3=C.accent,Text='B',TextColor3=C.white,TextSize=25,Font=Enum.Font.GothamBlack},top); round(logo,12)
local name=text(top,'BABA HUB',19,C.white,true); name.Position=UDim2.fromOffset(80,9); name.Size=UDim2.fromOffset(205,30)
local version=text(top,'V4  •  CUSTOM DASHBOARD',10,C.muted,true); version.Position=UDim2.fromOffset(80,36);version.Size=UDim2.fromOffset(250,17)
local minimize=make('TextButton',{Position=UDim2.new(1,-89,0,17),Size=UDim2.fromOffset(25,28),Text='–',TextColor3=C.muted,TextSize=24,BackgroundTransparency=1},top)
local close=make('TextButton',{Position=UDim2.new(1,-47,0,17),Size=UDim2.fromOffset(25,28),Text='×',TextColor3=C.muted,TextSize=24,BackgroundTransparency=1},top)
local sidebar=make('Frame',{Position=UDim2.fromOffset(0,64),Size=UDim2.new(0,177,1,-64),BackgroundColor3=C.panel,BorderSizePixel=0},main)
local nav=make('ScrollingFrame',{Position=UDim2.fromOffset(10,18),Size=UDim2.new(1,-20,1,-29),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},sidebar)
make('UIListLayout',{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder},nav)
local content=make('ScrollingFrame',{Position=UDim2.fromOffset(177,64),Size=UDim2.new(1,-177,1,-64),BackgroundTransparency=1,ScrollBarThickness=3,ScrollBarImageColor3=C.accent,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},main)
pad(content,18,20,25,20)
make('UIListLayout',{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder},content)

local toast=text(gui,'',13,C.white,true)
toast.Name='Toast';toast.BackgroundColor3=C.raised; toast.AnchorPoint=Vector2.new(.5,1); toast.Position=UDim2.new(.5,0,1,-26); toast.Size=UDim2.fromOffset(420,40);toast.TextXAlignment=Enum.TextXAlignment.Center;toast.Visible=false;round(toast,12);border(toast,C.accent)
local toastSerial=0
local function notify(message)
    toastSerial+=1;local n=toastSerial
    toast.Text=message;toast.Visible=true
    task.delay(3,function() if alive and n==toastSerial then toast.Visible=false end end)
end

local pages={}
local navButtons={}
local currentPage=''
local function showPage(key)
    currentPage=key
    for k,p in pairs(pages) do p.Visible=(k==key) end
    for k,b in pairs(navButtons) do b.BackgroundColor3=(k==key) and C.raised or C.panel;b.TextColor3=(k==key) and C.accent2 or C.muted end
    content.CanvasPosition=Vector2.zero
end
local function page(key,label,icon)
    local b=make('TextButton',{Size=UDim2.new(1,0,0,40),BackgroundColor3=C.panel,Text=icon..'   '..label,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=C.muted,TextSize=13,Font=Enum.Font.GothamBold,AutoButtonColor=false},nav);round(b,10);pad(b,0,10,0,12)
    navButtons[key]=b;connect(b.MouseButton1Click,function()showPage(key)end)
    local p=make('Frame',{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=false},content)
    make('UIListLayout',{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder},p)
    pages[key]=p
    return p
end
local function heading(parent,title,sub)
    local f=make('Frame',{Size=UDim2.new(1,0,0,56),BackgroundTransparency=1},parent)
    local a=text(f,title,23,C.white,true);a.Size=UDim2.new(1,0,0,31)
    local b=text(f,sub or '',12,C.muted);b.Position=UDim2.fromOffset(0,32);b.Size=UDim2.new(1,0,0,20)
end
local function card(parent,title,desc)
    local f=make('Frame',{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=C.panel,BorderSizePixel=0},parent);round(f,13);border(f);pad(f,14,14,15,14)
    make('UIListLayout',{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},f)
    local label=text(f,title,15,C.white,true);label.Size=UDim2.new(1,0,0,22)
    if desc then local d=text(f,desc,11,C.muted);d.Size=UDim2.new(1,0,0,30) end
    return f
end
local function button(parent,label,callback)
    local b=make('TextButton',{Size=UDim2.new(1,0,0,35),BackgroundColor3=C.raised,Text=label,TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=12,AutoButtonColor=true},parent);round(b,8)
    connect(b.MouseButton1Click,function()if alive then local ok,err=pcall(callback);if not ok then notify('Error: '..tostring(err):sub(1,100)) end end end)
    return b
end
local function toggle(parent,label,default,callback)
    local on=default
    local b=button(parent,'●  '..label..'   ['..(on and 'ON' or 'OFF')..']',function()
        on=not on
        callback(on)
    end)
    local function render()b.Text='●  '..label..'   ['..(on and 'ON' or 'OFF')..']';b.TextColor3=on and C.accent2 or C.muted end
    connect(b.MouseButton1Click,render);render()
    return function(v)on=v;callback(v);render()end
end
local function input(parent,placeholder)
    local box=make('TextBox',{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.raised,Text='',PlaceholderText=placeholder,PlaceholderColor3=C.muted,TextColor3=C.white,TextSize=12,Font=Enum.Font.Gotham,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},parent);round(box,8);pad(box,0,10,0,10)
    return box
end
local function slider(parent,label,min,max,initial,callback)
    local val=initial
    local b=button(parent,label..': '..tostring(initial)..'  (- / +)',function()end)
    local minus=make('TextButton',{Size=UDim2.fromOffset(38,30),Position=UDim2.new(1,-84,0,2),Text='−',TextSize=18,Font=Enum.Font.GothamBold,TextColor3=C.white,BackgroundColor3=C.panel},b);round(minus,6)
    local plus=make('TextButton',{Size=UDim2.fromOffset(38,30),Position=UDim2.new(1,-42,0,2),Text='+',TextSize=18,Font=Enum.Font.GothamBold,TextColor3=C.white,BackgroundColor3=C.panel},b);round(plus,6)
    local function update(n)val=math.clamp(n,min,max);b.Text=label..': '..string.format('%g',val)..'  (- / +)';callback(val)end
    connect(minus.MouseButton1Click,function()update(val-1)end)
    connect(plus.MouseButton1Click,function()update(val+1)end)
    return update
end
local function getHumanoid()local c=player.Character;return c and c:FindFirstChildOfClass('Humanoid') end
local function applyMovement()
    local h=getHumanoid();if h then h.WalkSpeed=settings.speed;h.UseJumpPower=true;h.JumpPower=settings.jump end
end

-- ESP: other players only; color is a visible-tool estimate, not actual hidden MM2 roles.
local function removeHighlight(p) if esp[p] then esp[p]:Destroy();esp[p]=nil end end
local function updateHighlights()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player then
            local ch=p.Character
            if settings.esp and ch then
                if esp[p] and esp[p].Adornee~=ch then removeHighlight(p) end
                if not esp[p] then
                    local h=make('Highlight',{Name='BabaV4Highlight',FillTransparency=.7,OutlineTransparency=.1,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Adornee=ch},ch)
                    esp[p]=h
                end
                local role='unknown'
                for _,obj in ipairs(ch:GetChildren()) do
                    if obj:IsA('Tool') then local n=obj.Name:lower();if n:find('knife',1,true) then role='knife' elseif n:find('gun',1,true) or n:find('revolver',1,true) then role='gun' end end
                end
                local color=role=='knife' and C.red or role=='gun' and Color3.fromRGB(87,160,255) or C.green
                esp[p].FillColor=color;esp[p].OutlineColor=color
            else removeHighlight(p) end
        end
    end
end

-- AUDIO: playable Roblox asset IDs only.
local music=make('Sound',{Name='BabaV4Music',Volume=settings.volume,Looped=false},SoundService)
local function playIndex(i)
    local song=songs[i];if not song then notify('No song selected');return end
    selectedSong=i;music:Stop();music.SoundId='rbxassetid://'..song.id;music.TimePosition=0;music:Play()
    if liveLabels.now then liveLabels.now.Text='♫ '..song.title end
    notify('Playing: '..song.title)
end
local function nextSong(step)
    if #songs==0 then return end
    playIndex(((selectedSong-1+step)%#songs)+1)
end
connect(music.Ended,function() if alive and not settings.loop and #songs>1 then nextSong(1) end end)

-- PAGES
local home=page('home','Home','⌂')
local visuals=page('visuals','Visuals','◉')
local movement=page('movement','Movement','➤')
local teleport=page('teleport','Teleport','⌖')
local farming=page('farming','Candy Farm','◇')
local camera=page('camera','Camera','▣')
local world=page('world','World','☀')
local musicPage=page('music','Music','♫')
local dances=page('dances','Dances','✧')
local servers=page('servers','Servers','◎')
local options=page('options','Settings','⚙')

heading(home,'Welcome to Baba Hub','A custom purple-and-black Roblox dashboard')
local perf=card(home,'LIVE PERFORMANCE','FPS and network measurements')
local fpsText=text(perf,'FPS: --',23,C.green,true);fpsText.Size=UDim2.new(1,0,0,35)
local pingText=text(perf,'Ping: --',13,C.muted);pingText.Size=UDim2.new(1,0,0,23)
local serverText=text(perf,'Players: --',13,C.muted);serverText.Size=UDim2.new(1,0,0,23)
local intro=card(home,'YOUR ACCOUNT')
local account=text(intro,player.DisplayName..'  (@'..player.Name..')',14,C.accent2,true);account.Size=UDim2.new(1,0,0,28)
local uid=text(intro,'User ID: '..tostring(player.UserId),12,C.muted);uid.Size=UDim2.new(1,0,0,21)
local quick=card(home,'QUICK ACTIONS')
button(quick,'Go to Music Player',function()showPage('music')end)
button(quick,'Go to Teleport',function()showPage('teleport')end)
button(quick,'Copy Job ID to Output',function() print('[Baba Hub] Job ID: '..game.JobId);notify('Job ID printed to console') end)

heading(visuals,'Visuals','Player overlays and effects')
local espCard=card(visuals,'PLAYER HIGHLIGHTS','Local visual cues; equipped tool colors are estimates.')
toggle(espCard,'Enable highlights',false,function(v)settings.esp=v;if not v then for p in pairs(esp) do removeHighlight(p) end else updateHighlights() end end)
button(espCard,'Refresh highlights',updateHighlights)

heading(movement,'Movement','Local humanoid controls; game may override them')
local moveCard=card(movement,'YOUR CHARACTER')
slider(moveCard,'Walk speed',10,50,16,function(v)settings.speed=v;applyMovement()end)
slider(moveCard,'Jump power',25,100,50,function(v)settings.jump=v;applyMovement()end)
button(moveCard,'Reset movement',function()settings.speed=16;settings.jump=50;applyMovement();notify('Movement reset')end)
connect(player.CharacterAdded,function()task.wait(.35);if alive then applyMovement() end end)

heading(teleport,'Teleport','Navigate your current server')
local tpCard=card(teleport,'TELEPORT TO PLAYER','Type a username or display name, then select Teleport.')
local tpInput=input(tpCard,'Player username / display name')
button(tpCard,'Teleport to player',function()
    local q=tpInput.Text:lower();if q=='' then notify('Enter a player name');return end
    local target
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player and (p.Name:lower():find(q,1,true)==1 or p.DisplayName:lower():find(q,1,true)==1) then target=p;break end
    end
    local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    local other=target and target.Character and target.Character:FindFirstChild('HumanoidRootPart')
    if root and other then root.CFrame=other.CFrame*CFrame.new(3,0,0);notify('Moved near '..target.Name) else notify('Player or character not available') end
end)
local clickTeleport=false
local mouse=player:GetMouse()
toggle(tpCard,'Shift + Click teleport',false,function(v)clickTeleport=v end)
connect(UserInputService.InputBegan,function(k,processed)
    if processed or not clickTeleport or not alive then return end
    if k.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    if not (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then return end
    local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    if root and mouse.Target then root.CFrame=CFrame.new(mouse.Hit.Position+Vector3.new(0,4,0)) end
end)

-- CANDY / COIN FARM
-- Object names are heuristics and can change between MM2 events.
-- Walks to nearby visible collectible candidates; server determines collection.
local farmCard
local farmStatus
local farmList
local farmDistance=120
local function collectibleName(name)
    local n=name:lower():gsub('[%s_%-]','')
    return n=='candy' or n=='candies' or n=='coin' or n=='coins'
        or n=='candycorn' or n=='candycollectible' or n=='coincollectible'
        or n:match('^candy%d+$')~=nil or n:match('^coin%d+$')~=nil
end
local function candidatePart(obj)
    if obj:IsA('BasePart') then return obj end
    if obj:IsA('Model') then
        return obj.PrimaryPart or obj:FindFirstChildWhichIsA('BasePart',true)
    end
    return nil
end
local function scanCandy()
    local found={}
    local seen={}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if collectibleName(obj.Name) then
            local part=candidatePart(obj)
            if not part and not obj:IsA('Model') and not obj:IsA('BasePart') then
                part=obj:FindFirstChildWhichIsA('BasePart',true)
            end
            if part and part:IsDescendantOf(workspace) and not seen[part] then
                seen[part]=true
                table.insert(found,{part=part,root=obj})
            end
        end
    end
    farmCandidates=found
    return #found
end
local function nearestCandy()
    local char=player.Character
    local root=char and char:FindFirstChild('HumanoidRootPart')
    if not root then return nil,nil end
    local target,best=nil,farmDistance
    for _,item in ipairs(farmCandidates) do
        if item.part and item.part.Parent and item.root and item.root.Parent then
            local distance=(root.Position-item.part.Position).Magnitude
            if distance<best and distance>2 then
                best=distance;target=item.part
            end
        end
    end
    return target,best
end
local function stopCandyFarm()
    farmEnabled=false
    farmPosition=nil
    local humanoid=getHumanoid()
    local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    if humanoid and root then humanoid:MoveTo(root.Position) end
end
heading(farming,'Candy Farm','Local candy / coin detection and walking collection')
farmCard=card(farming,'AUTO COLLECT','Scans visible Candy/Coin objects and walks to the nearest candidate.')
farmStatus=text(farmCard,'Status: OFF  •  Detected: 0',13,C.accent2,true)
farmStatus.Size=UDim2.new(1,0,0,28)
toggle(farmCard,'Auto-walk to collectibles',false,function(value)
    if value then
        farmEnabled=true
        scanCandy()
        notify('Candy collector enabled. Walking to nearby collectibles.')
    else
        stopCandyFarm()
        notify('Candy collector disabled.')
    end
end)
button(farmCard,'Scan Candy / Coins now',function()
    local count=scanCandy()
    notify('Found '..count..' collectible candidate(s)')
end)
slider(farmCard,'Search radius (studs)',20,250,120,function(value)farmDistance=value end)
button(farmCard,'Show detected object names',function()
    local names={}
    for _,item in ipairs(farmCandidates) do
        if item.root and item.root.Parent then names[item.root.Name]=true end
    end
    local list={}
    for n in pairs(names) do table.insert(list,n) end
    table.sort(list)
    notify(#list>0 and ('Detected: '..table.concat(list,', '):sub(1,90)) or 'No Candy/Coin names detected')
end)
connect(RunService.Heartbeat,function()
    if not alive or not farmEnabled then return end
    local now=os.clock()
    if now-farmLastScan>=2 then
        farmLastScan=now
        scanCandy()
    end
    if now-farmLastMove>=0.9 then
        farmLastMove=now
        local h=getHumanoid()
        local target,distance=nearestCandy()
        if h and h.Health>0 and target then
            h:MoveTo(target.Position)
            farmPosition=target.Position
            farmStatus.Text=string.format('Status: WALKING  •  Found: %d  •  Nearest: %d studs',#farmCandidates,math.floor(distance))
        else
            farmStatus.Text='Status: SEARCHING  •  Found: '..#farmCandidates
        end
    end
end)

heading(camera,'Camera','Adjust your view locally')
local camCard=card(camera,'CAMERA CONTROLS')
slider(camCard,'Field of view',40,120,70,function(v)local cam=workspace.CurrentCamera;if cam then cam.FieldOfView=v end end)
slider(camCard,'Max zoom',1,100,20,function(v)player.CameraMaxZoomDistance=v end)
button(camCard,'First-person mode',function()player.CameraMode=Enum.CameraMode.LockFirstPerson end)
button(camCard,'Third-person mode',function()player.CameraMode=Enum.CameraMode.Classic end)
button(camCard,'Restore camera',function()
    local cam=workspace.CurrentCamera;if cam then cam.FieldOfView=original.fov end
    player.CameraMaxZoomDistance=original.zoom;player.CameraMode=Enum.CameraMode.Classic
end)

heading(world,'World','Local lighting presets')
local lightCard=card(world,'LIGHTING')
button(lightCard,'Bright mode',function()Lighting.Brightness=4;Lighting.Ambient=Color3.fromRGB(210,210,210);notify('Bright mode enabled')end)
button(lightCard,'Daylight',function()Lighting.ClockTime=12;Lighting.Brightness=2 end)
button(lightCard,'Night',function()Lighting.ClockTime=0;Lighting.Brightness=1 end)
button(lightCard,'Sunset',function()Lighting.ClockTime=18;Lighting.Brightness=2 end)
button(lightCard,'Reduce fog',function()Lighting.FogEnd=100000 end)
local function restoreLighting()
    Lighting.Brightness=original.brightness;Lighting.ClockTime=original.clock;Lighting.FogEnd=original.fog;Lighting.Ambient=original.ambient;Lighting.GlobalShadows=original.shadows
end
button(lightCard,'Restore original lighting',restoreLighting)

heading(musicPage,'Music Library','Roblox audio IDs • session library • client-side')
local playerCard=card(musicPage,'NOW PLAYING','Only Roblox audio assets accessible to this experience will play.')
local now=text(playerCard,'♫  Nothing playing',15,C.accent2,true);now.Size=UDim2.new(1,0,0,31);liveLabels.now=now
button(playerCard,'▶ Play / Resume',function()if selectedSong>0 then if music.IsPaused then music:Resume() else playIndex(selectedSong) end else notify('Add or select a song') end end)
button(playerCard,'Ⅱ Pause',function()music:Pause()end)
button(playerCard,'■ Stop',function()music:Stop()end)
button(playerCard,'⏮ Previous',function()nextSong(-1)end)
button(playerCard,'⏭ Next',function()nextSong(1)end)
slider(playerCard,'Volume %',0,100,50,function(v)settings.volume=v/100;music.Volume=settings.volume end)
toggle(playerCard,'Loop current track',false,function(v)settings.loop=v;music.Looped=v end)
local libraryCard=card(musicPage,'YOUR LIBRARY','Songs and favorites remain until this script is unloaded.')
local songTitle=input(libraryCard,'Song title')
local songID=input(libraryCard,'Roblox audio asset ID')
button(libraryCard,'+ Add song',function()
    local id=songID.Text:match('^%s*(%d+)%s*$')
    if not id then notify('Enter a numeric Roblox audio ID');return end
    local title=songTitle.Text~='' and songTitle.Text or 'Track '..id
    table.insert(songs,{id=id,title=title})
    notify('Added '..title)
end)
local selected=input(libraryCard,'Song number (1, 2, 3...)')
button(libraryCard,'Play selected song',function()
    local n=tonumber(selected.Text);if n and songs[n] then playIndex(n) else notify('Choose a valid song number') end
end)
button(libraryCard,'☆ Toggle favorite for selected song',function()
    local n=tonumber(selected.Text);if not n or not songs[n] then notify('Choose a song number');return end
    favorites[songs[n].id]=not favorites[songs[n].id]
    notify(favorites[songs[n].id] and 'Added to favorites' or 'Removed from favorites')
end)
button(libraryCard,'List songs in output',function()
    for i,s in ipairs(songs) do print(string.format('[Baba Hub] %d. %s | %s %s',i,s.title,s.id,favorites[s.id] and '★' or '')) end
    notify(#songs..' song(s) listed in developer console')
end)
button(libraryCard,'Remove selected song',function()
    local n=tonumber(selected.Text);if n and songs[n] then table.remove(songs,n);selectedSong=0;music:Stop();now.Text='♫  Nothing playing';notify('Removed from library') end
end)

heading(dances,'Dances & Emotes','Play accessible Roblox animation assets')
local danceCard=card(dances,'CUSTOM DANCE')
local danceInput=input(danceCard,'Roblox animation ID')
local danceSpeed=1
slider(danceCard,'Animation speed',1,3,1,function(v)danceSpeed=v;if currentDance then currentDance:AdjustSpeed(v) end end)
button(danceCard,'▶ Play custom dance',function()
    local id=danceInput.Text:match('^%s*(%d+)%s*$');if not id then notify('Enter a numeric animation ID');return end
    local h=getHumanoid();local animator=h and h:FindFirstChildOfClass('Animator');if not animator then notify('Character animator unavailable');return end
    if currentDance then currentDance:Stop() end
    local animation=Instance.new('Animation');animation.AnimationId='rbxassetid://'..id
    local ok,track=pcall(function()return animator:LoadAnimation(animation)end)
    animation:Destroy()
    if ok and track then currentDance=track;track.Looped=true;track:Play();track:AdjustSpeed(danceSpeed) else notify('Animation unavailable or not permitted') end
end)
button(danceCard,'■ Stop dance',function()if currentDance then currentDance:Stop();currentDance=nil end end)

heading(servers,'Server Tools','Server information and navigation')
local serverCard=card(servers,'CURRENT SERVER')
local sid=text(serverCard,'Job ID: '..game.JobId,11,C.muted);sid.Size=UDim2.new(1,0,0,38)
button(serverCard,'Rejoin current server',function()
    if game.JobId~='' then TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,player) else TeleportService:Teleport(game.PlaceId,player) end
end)
button(serverCard,'Join another server',function()
    notify('Trying to join a public server...')
    TeleportService:Teleport(game.PlaceId,player)
end)

heading(options,'Settings','Dashboard preferences and cleanup')
local settingsCard=card(options,'INTERFACE')
local hudReset
toggle(settingsCard,'Show mini FPS HUD',true,function(v)settings.fpsHud=v;if hudReset then hudReset.Visible=v end end)
button(settingsCard,'Hide / show dashboard',function()main.Visible=not main.Visible end)
button(settingsCard,'Restore lighting',restoreLighting)
local function cleanup()
    if not alive then return end;stopCandyFarm();alive=false
    for p in pairs(esp) do removeHighlight(p) end
    if currentDance then pcall(function()currentDance:Stop()end) end
    music:Stop();music:Destroy()
    restoreLighting()
    for _,con in ipairs(connections) do con:Disconnect() end
    gui:Destroy()
end
button(settingsCard,'Unload Baba Hub V4',cleanup)

-- Mini counter and hide/show button
local mini=make('Frame',{Name='MiniHUD',Position=UDim2.fromOffset(15,90),Size=UDim2.fromOffset(120,53),BackgroundColor3=C.panel,BorderSizePixel=0},gui);round(mini,12);border(mini,C.accent)
local miniText=text(mini,'FPS: --\nPing: --',12,C.accent2,true);miniText.Size=UDim2.new(1,-16,1,-8);miniText.Position=UDim2.fromOffset(9,4)
hudReset=mini
local opener=make('TextButton',{Name='OpenDashboard',Position=UDim2.fromOffset(15,155),Size=UDim2.fromOffset(120,31),Text='BABA HUB  ↗',TextSize=12,TextColor3=C.white,Font=Enum.Font.GothamBold,BackgroundColor3=C.accent,BorderSizePixel=0},gui);round(opener,9)
connect(opener.MouseButton1Click,function()main.Visible=not main.Visible end)
connect(minimize.MouseButton1Click,function()main.Visible=false end)
connect(close.MouseButton1Click,cleanup)
-- Drag dashboard using its header
local dragging=false;local startPointer;local startPosition
connect(top.InputBegan,function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true;startPointer=i.Position;startPosition=main.Position end
end)
connect(UserInputService.InputEnded,function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
connect(UserInputService.InputChanged,function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-startPointer; main.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+d.X,startPosition.Y.Scale,startPosition.Y.Offset+d.Y)
    end
end)
local frames=0;local elapsed=0;local fps=0;local refresh=0
connect(RunService.RenderStepped,function(dt)
    if not alive then return end
    frames+=1;elapsed+=dt;refresh+=dt
    if elapsed>=.5 then fps=math.floor(frames/elapsed+.5);frames=0;elapsed=0 end
    if refresh>=.65 then
        refresh=0
        local ping='--'
        pcall(function()ping=Stats.Network.ServerStatsItem['Data Ping']:GetValueString()end)
        fpsText.Text='FPS  '..fps;pingText.Text='Ping  '..ping
        serverText.Text='Players  '..#Players:GetPlayers()..'/'..Players.MaxPlayers
        miniText.Text='FPS  '..fps..'\nPing  '..ping
        if settings.esp then updateHighlights() end
    end
end)
showPage('home')
notify('Baba Hub V4 loaded • custom dashboard')
