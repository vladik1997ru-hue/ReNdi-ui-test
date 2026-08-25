--[[
    ReNdi UI - Murder Mystery 2
    Управление: Shift + X (открыть/закрыть меню)
    Версия: 2.0
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local TweenService = game:GetService("TweenService")

-- Настройки
local settings = {
    aimbot = true,
    esp = true,
    fov = 200,
    smooth = 0.15,
    language = "RUS",
    theme = "DARK",
    silent = false,
    visible = true
}

-- Языки
local languages = {
    RUS = {
        title = "🔪 ReNdi PRO",
        aimbot = "🎯 АИМБОТ",
        esp = "👁 ESP",
        fov = "📐 ОБЗОР",
        smooth = "⚡ ПЛАВНОСТЬ",
        silent = "🔇 ТИХИЙ АИМ",
        murderer = "🔪 УБИЙЦА",
        sheriff = "🔫 ШЕРИФ",
        innocent = "👤 НЕВИННЫЙ",
        off = "ВЫКЛ",
        on = "ВКЛ",
        all_off = "🛑 ВЫКЛ ВСЁ",
        exit = "🚪 ВЫХОД",
        theme = "🎨 ТЕМА",
        language = "🌍 ЯЗЫК",
        settings = "⚙ НАСТРОЙКИ"
    },
    ENG = {
        title = "🔪 ReNdi PRO",
        aimbot = "🎯 AIMBOT",
        esp = "👁 ESP",
        fov = "📐 FOV",
        smooth = "⚡ SMOOTH",
        silent = "🔇 SILENT AIM",
        murderer = "🔪 MURDERER",
        sheriff = "🔫 SHERIFF",
        innocent = "👤 INNOCENT",
        off = "OFF",
        on = "ON",
        all_off = "🛑 ALL OFF",
        exit = "🚪 EXIT",
        theme = "🎨 THEME",
        language = "🌍 LANGUAGE",
        settings = "⚙ SETTINGS"
    }
}

local currentLang = languages[settings.language]

-- Функция получения роли
local function getRole(player)
    if not player then return "Innocent" end
    for _, v in pairs(game.ReplicatedStorage:GetChildren()) do
        if v:IsA("StringValue") and v.Name == player.Name then
            return v.Value
        end
    end
    if player:FindFirstChild("leaderstats") then
        local role = player.leaderstats:FindFirstChild("Role")
        if role then return role.Value end
    end
    if player:GetAttribute("Role") then
        return player:GetAttribute("Role")
    end
    if player:FindFirstChild("Role") then
        return player.Role.Value
    end
    return "Innocent"
end

local function getRoleColor(role)
    if role == "Murderer" then return Color3.new(1, 0.05, 0.05)
    elseif role == "Sheriff" then return Color3.new(0.1, 0.5, 1)
    else return Color3.new(0.2, 0.9, 0.2) end
end

local function getAlivePlayers()
    local list = {}
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            table.insert(list, v)
        end
    end
    return list
end

local function worldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

-- ESP
local espObjects = {}
local function createESP()
    clearESP(espObjects)
    espObjects = {}
    for _, player in pairs(getAlivePlayers()) do
        local char = player.Character
        if char and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") then
            local role = getRole(player)
            local color = getRoleColor(role)
            local icon = role == "Murderer" and "🔪 " or role == "Sheriff" and "🔫 " or "👤 "
            
            local box = Drawing.new("Box")
            box.Thickness = 2
            box.Color = color
            box.Transparency = 0.5
            box.Filled = false
            box.Visible = true
            
            local text = Drawing.new("Text")
            text.Text = icon .. player.Name .. " | " .. role
            text.Size = 15
            text.Color = Color3.new(1, 1, 1)
            text.Center = true
            text.Outline = true
            text.OutlineColor = Color3.new(0, 0, 0)
            text.Visible = true
            
            local healthBar = Drawing.new("Line")
            healthBar.Thickness = 3
            healthBar.Color = Color3.new(0, 1, 0)
            healthBar.Visible = true
            
            local tracer = Drawing.new("Line")
            tracer.Thickness = 1.5
            tracer.Color = color
            tracer.Transparency = 0.6
            tracer.Visible = true
            
            table.insert(espObjects, {box = box, text = text, tracer = tracer, healthBar = healthBar, player = player, role = role})
        end
    end
end

local function updateESP()
    local viewportSize = Camera.ViewportSize
    local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    for _, obj in pairs(espObjects) do
        local char = obj.player.Character
        if char and char:FindFirstChild("Head") and char:FindFirstChild("HumanoidRootPart") then
            local headPos = char.Head.Position
            local rootPos = char.HumanoidRootPart.Position
            local screenHead, headOnScreen = worldToScreen(headPos)
            local screenRoot, rootOnScreen = worldToScreen(rootPos)
            
            local newRole = getRole(obj.player)
            if newRole ~= obj.role then
                obj.role = newRole
                local icon = newRole == "Murderer" and "🔪 " or newRole == "Sheriff" and "🔫 " or "👤 "
                obj.text.Text = icon .. obj.player.Name .. " | " .. newRole
                local color = getRoleColor(newRole)
                obj.box.Color = color
                obj.tracer.Color = color
            end
            
            if headOnScreen and rootOnScreen then
                local height = (screenRoot.Y - screenHead.Y)
                local width = height * 0.5
                obj.box.Position = Vector2.new(screenHead.X - width / 2, screenHead.Y - 10)
                obj.box.Size = Vector2.new(width, height + 20)
                obj.box.Visible = true
                
                obj.text.Position = Vector2.new(screenHead.X, screenHead.Y - 30)
                obj.text.Visible = true
                
                local health = char.Humanoid.Health / char.Humanoid.MaxHealth
                local barWidth = 30
                obj.healthBar.From = Vector2.new(screenHead.X - barWidth/2, screenHead.Y + height + 10)
                obj.healthBar.To = Vector2.new(screenHead.X - barWidth/2 + barWidth * health, screenHead.Y + height + 10)
                obj.healthBar.Color = Color3.new(1 - health, health, 0)
                obj.healthBar.Visible = true
                
                obj.tracer.From = Vector2.new(center.X, viewportSize.Y)
                obj.tracer.To = Vector2.new(screenRoot.X, screenRoot.Y)
                obj.tracer.Visible = true
            else
                obj.box.Visible = false
                obj.text.Visible = false
                obj.healthBar.Visible = false
                obj.tracer.Visible = false
            end
        else
            obj.box.Visible = false
            obj.text.Visible = false
            obj.healthBar.Visible = false
            obj.tracer.Visible = false
        end
    end
end

local function clearESP(objects)
    for _, obj in pairs(objects) do
        if obj.box then obj.box:Remove() end
        if obj.text then obj.text:Remove() end
        if obj.tracer then obj.tracer:Remove() end
        if obj.healthBar then obj.healthBar:Remove() end
    end
end

-- Аимбот
local function aimbot(targetPos)
    if not targetPos or not settings.aimbot then return end
    local currentCF = Camera.CFrame
    local lookAt = (targetPos - currentCF.Position).unit
    local yaw = math.atan2(lookAt.X, lookAt.Z)
    local pitch = math.asin(math.clamp(lookAt.Y, -1, 1))
    local newCF = CFrame.new(currentCF.Position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
    Camera.CFrame = currentCF:lerp(newCF, settings.smooth)
end

local function findMurderer()
    local target = nil
    local minDist = 9999
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in pairs(getAlivePlayers()) do
        if getRole(player) == "Murderer" then
            local char = player.Character
            if char and char:FindFirstChild("Head") then
                local headPos = char.Head.Position
                local screenPos, onScreen = worldToScreen(headPos)
                if onScreen then
                    local dist = (screenPos - center).Magnitude
                    if dist < settings.fov and dist < minDist then
                        minDist = dist
                        target = headPos
                    end
                end
            end
        end
    end
    return target
end

-- GUI
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ReNdiUI"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    mainFrame.Visible = false

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0.1, 0.05, 0.15)),
        ColorSequenceKeypoint.new(1, Color3.new(0.05, 0.05, 0.1))
    })
    gradient.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = mainFrame

    local shadow = Instance.new("UIShadow")
    shadow.Parent = mainFrame

    local function getText(key)
        return currentLang[key] or key
    end

    local function updateLanguage()
        currentLang = languages[settings.language]
        title.Text = getText("title")
        aimBtn.Text = getText("aimbot") .. " [" .. (settings.aimbot and getText("on") or getText("off")) .. "]"
        espBtn.Text = getText("esp") .. " [" .. (settings.esp and getText("on") or getText("off")) .. "]"
        silentBtn.Text = getText("silent") .. " [" .. (settings.silent and getText("on") or getText("off")) .. "]"
        fovLabel.Text = getText("fov") .. ": " .. settings.fov
        smoothLabel.Text = getText("smooth") .. ": " .. math.round(settings.smooth * 100) .. "%"
        themeBtn.Text = getText("theme") .. ": " .. settings.theme
        langBtn.Text = getText("language") .. ": " .. settings.language
        allOffBtn.Text = getText("all_off")
        exitBtn.Text = getText("exit")
    end

    -- Заголовок
    local titleFrame = Instance.new("Frame")
    titleFrame.Size = UDim2.new(1, 0, 0, 35)
    titleFrame.Position = UDim2.new(0, 0, 0, 0)
    titleFrame.BackgroundColor3 = Color3.new(0.15, 0.05, 0.2)
    titleFrame.BackgroundTransparency = 0.3
    titleFrame.BorderSizePixel = 0
    titleFrame.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 16)
    titleCorner.Parent = titleFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.8, 0, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = getText("title")
    title.TextColor3 = Color3.new(1, 0.2, 0.2)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleFrame

    -- Кнопка скрыть (минимизировать)
    local toggleMenuBtn = Instance.new("TextButton")
    toggleMenuBtn.Size = UDim2.new(0, 30, 0, 30)
    toggleMenuBtn.Position = UDim2.new(1, -70, 0, 2)
    toggleMenuBtn.BackgroundColor3 = Color3.new(0.2, 0.05, 0.05)
    toggleMenuBtn.BackgroundTransparency = 0.5
    toggleMenuBtn.Text = "➖"
    toggleMenuBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleMenuBtn.TextScaled = true
    toggleMenuBtn.Font = Enum.Font.GothamBold
    toggleMenuBtn.BorderSizePixel = 0
    toggleMenuBtn.Parent = titleFrame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleMenuBtn

    toggleMenuBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        miniBtn.Visible = true
    end)

    -- Кнопка закрыть GUI
    local closeGuiBtn = Instance.new("TextButton")
    closeGuiBtn.Size = UDim2.new(0, 30, 0, 30)
    closeGuiBtn.Position = UDim2.new(1, -35, 0, 2)
    closeGuiBtn.BackgroundColor3 = Color3.new(0.3, 0.05, 0.05)
    closeGuiBtn.BackgroundTransparency = 0.5
    closeGuiBtn.Text = "✕"
    closeGuiBtn.TextColor3 = Color3.new(1, 1, 1)
    closeGuiBtn.TextScaled = true
    closeGuiBtn.Font = Enum.Font.GothamBold
    closeGuiBtn.BorderSizePixel = 0
    closeGuiBtn.Parent = titleFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeGuiBtn

    closeGuiBtn.MouseButton1Click:Connect(function()
        clearESP(espObjects)
        screenGui:Destroy()
    end)

    -- Мини-кнопка (показать GUI)
    local miniBtn = Instance.new("TextButton")
    miniBtn.Size = UDim2.new(0, 50, 0, 50)
    miniBtn.Position = UDim2.new(0.02, 0, 0.02, 0)
    miniBtn.BackgroundColor3 = Color3.new(0.15, 0.05, 0.2)
    miniBtn.BackgroundTransparency = 0.3
    miniBtn.Text = "🔪"
    miniBtn.TextColor3 = Color3.new(1, 0.2, 0.2)
    miniBtn.TextScaled = true
    miniBtn.Font = Enum.Font.GothamBold
    miniBtn.BorderSizePixel = 0
    miniBtn.Visible = true
    miniBtn.Parent = screenGui

    local miniCorner = Instance.new("UICorner")
    miniCorner.CornerRadius = UDim.new(0, 12)
    miniCorner.Parent = miniBtn

    miniBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        miniBtn.Visible = false
    end)

    -- Линия
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.85, 0, 0, 1)
    line.Position = UDim2.new(0.075, 0, 0.10, 0)
    line.BackgroundColor3 = Color3.new(0.3, 0.3, 0.5)
    line.BorderSizePixel = 0
    line.Parent = mainFrame

    -- Функция создания кнопки
    local function createButton(text, posY, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.85, 0, 0, 30)
        btn.Position = UDim2.new(0.075, 0, posY, 0)
        btn.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
        btn.BackgroundTransparency = 0.2
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextScaled = true
        btn.Font = Enum.Font.Gotham
        btn.BorderSizePixel = 0
        btn.Parent = mainFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        btn.MouseEnter:Connect(function()
            btn.BackgroundTransparency = 0
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundTransparency = 0.2
        end)

        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Кнопки функций
    local aimBtn = createButton(getText("aimbot") .. " [" .. (settings.aimbot and getText("on") or getText("off")) .. "]", 0.14, function()
        settings.aimbot = not settings.aimbot
        aimBtn.Text = getText("aimbot") .. " [" .. (settings.aimbot and getText("on") or getText("off")) .. "]"
        aimBtn.BackgroundColor3 = settings.aimbot and Color3.new(0.1, 0.1, 0.15) or Color3.new(0.25, 0.08, 0.08)
    end)

    local espBtn = createButton(getText("esp") .. " [" .. (settings.esp and getText("on") or getText("off")) .. "]", 0.22, function()
        settings.esp = not settings.esp
        espBtn.Text = getText("esp") .. " [" .. (settings.esp and getText("on") or getText("off")) .. "]"
        espBtn.BackgroundColor3 = settings.esp and Color3.new(0.1, 0.1, 0.15) or Color3.new(0.25, 0.08, 0.08)
        if settings.esp then createESP() else clearESP(espObjects) end
    end)

    local silentBtn = createButton(getText("silent") .. " [" .. (settings.silent and getText("on") or getText("off")) .. "]", 0.30, function()
        settings.silent = not settings.silent
        silentBtn.Text = getText("silent") .. " [" .. (settings.silent and getText("on") or getText("off")) .. "]"
        silentBtn.BackgroundColor3 = settings.silent and Color3.new(0.1, 0.1, 0.15) or Color3.new(0.25, 0.08, 0.08)
    end)

    -- FOV
    local fovLabel = Instance.new("TextLabel")
    fovLabel.Size = UDim2.new(0.35, 0, 0, 20)
    fovLabel.Position = UDim2.new(0.075, 0, 0.38, 0)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Text = getText("fov") .. ": " .. settings.fov
    fovLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    fovLabel.TextScaled = true
    fovLabel.Font = Enum.Font.Gotham
    fovLabel.TextXAlignment = Enum.TextXAlignment.Left
    fovLabel.Parent = mainFrame

    local fovSlider = Instance.new("UISlider")
    fovSlider.Size = UDim2.new(0.5, 0, 0, 20)
    fovSlider.Position = UDim2.new(0.42, 0, 0.38, 0)
    fovSlider.MinValue = 30
    fovSlider.MaxValue = 400
    fovSlider.Value = settings.fov
    fovSlider.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
    fovSlider.Parent = mainFrame

    local fovSliderCorner = Instance.new("UICorner")
    fovSliderCorner.CornerRadius = UDim.new(0, 4)
    fovSliderCorner.Parent = fovSlider

    fovSlider.Changed:Connect(function()
        settings.fov = math.round(fovSlider.Value)
        fovLabel.Text = getText("fov") .. ": " .. settings.fov
    end)

    -- Smooth
    local smoothLabel = Instance.new("TextLabel")
    smoothLabel.Size = UDim2.new(0.35, 0, 0, 20)
    smoothLabel.Position = UDim2.new(0.075, 0, 0.46, 0)
    smoothLabel.BackgroundTransparency = 1
    smoothLabel.Text = getText("smooth") .. ": " .. math.round(settings.smooth * 100) .. "%"
    smoothLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    smoothLabel.TextScaled = true
    smoothLabel.Font = Enum.Font.Gotham
    smoothLabel.TextXAlignment = Enum.TextXAlignment.Left
    smoothLabel.Parent = mainFrame

    local smoothSlider = Instance.new("UISlider")
    smoothSlider.Size = UDim2.new(0.5, 0, 0, 20)
    smoothSlider.Position = UDim2.new(0.42, 0, 0.46, 0)
    smoothSlider.MinValue = 1
    smoothSlider.MaxValue = 50
    smoothSlider.Value = settings.smooth * 100
    smoothSlider.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
    smoothSlider.Parent = mainFrame

    local smoothSliderCorner = Instance.new("UICorner")
    smoothSliderCorner.CornerRadius = UDim.new(0, 4)
    smoothSliderCorner.Parent = smoothSlider

    smoothSlider.Changed:Connect(function()
        settings.smooth = smoothSlider.Value / 100
        smoothLabel.Text = getText("smooth") .. ": " .. math.round(settings.smooth * 100) .. "%"
    end)

    -- Кнопки настроек
    local themeBtn = createButton(getText("theme") .. ": " .. settings.theme, 0.54, function()
        local themes = {"DARK", "LIGHT", "NEON", "MATRIX"}
        local currentIndex = table.find(themes, settings.theme) or 1
        settings.theme = themes[currentIndex % #themes + 1]
        themeBtn.Text = getText("theme") .. ": " .. settings.theme
        -- Меняем цвета в зависимости от темы
        local colors = {
            DARK = {bg = Color3.new(0.05, 0.05, 0.1), title = Color3.new(0.15, 0.05, 0.2)},
            LIGHT = {bg = Color3.new(0.9, 0.9, 0.95), title = Color3.new(0.8, 0.7, 0.9)},
            NEON = {bg = Color3.new(0.05, 0.0, 0.1), title = Color3.new(0.2, 0.0, 0.3)},
            MATRIX = {bg = Color3.new(0.0, 0.05, 0.0), title = Color3.new(0.0, 0.15, 0.0)}
        }
        local c = colors[settings.theme] or colors.DARK
        mainFrame.BackgroundColor3 = c.bg
        titleFrame.BackgroundColor3 = c.title
    end)

    local langBtn = createButton(getText("language") .. ": " .. settings.language, 0.62, function()
        local langs = {"RUS", "ENG"}
        local currentIndex = table.find(langs, settings.language) or 1
        settings.language = langs[currentIndex % #langs + 1]
        langBtn.Text = getText("language") .. ": " .. settings.language
        updateLanguage()
    end)

    -- Кнопка все выключить
    local allOffBtn = createButton(getText("all_off"), 0.72, function()
        settings.aimbot = false
        settings.esp = false
        settings.silent = false
        aimBtn.Text = getText("aimbot") .. " [" .. getText("off") .. "]"
        aimBtn.BackgroundColor3 = Color3.new(0.25, 0.08, 0.08)
        espBtn.Text = getText("esp") .. " [" .. getText("off") .. "]"
        espBtn.BackgroundColor3 = Color3.new(0.25, 0.08, 0.08)
        silentBtn.Text = getText("silent") .. " [" .. getText("off") .. "]"
        silentBtn.BackgroundColor3 = Color3.new(0.25, 0.08, 0.08)
        clearESP(espObjects)
    end)

    -- Кнопка выхода
    local exitBtn = createButton(getText("exit"), 0.82, function()
        clearESP(espObjects)
        screenGui:Destroy()
    end)

    -- Drag
    local dragging = false
    local dragStart, startPos
    titleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    titleFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    titleFrame.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    return screenGui, mainFrame, miniBtn
end

-- Основной цикл
local function main()
    local screenGui, mainFrame, miniBtn = createGUI()
    createESP()

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.X and input.UserInputType == Enum.UserInputType.Keyboard then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                if mainFrame.Visible then
                    mainFrame.Visible = false
                    miniBtn.Visible = true
                else
                    mainFrame.Visible = true
                    miniBtn.Visible = false
                end
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if settings.esp then
            if #espObjects == 0 then createESP() else updateESP() end
        end
        if settings.aimbot then
            local target = findMurderer()
            if target then aimbot(target) end
        end
    end)

    Players.PlayerAdded:Connect(function()
        task.wait(0.5)
        if settings.esp then createESP() end
    end)
    Players.PlayerRemoving:Connect(function()
        task.wait(0.3)
        if settings.esp then createESP() end
    end)
end

pcall(main)
