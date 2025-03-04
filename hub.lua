-- Основные переменные
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

-- Флаги и настройки
local autoDigEnabled, autoSellEnabled, teleportEnabled = false, false, false
local digRadius, sellRadius = 10, 30
local currentTool = nil

-- Создание интерфейса для мобильного устройства
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.Name = "DigItHub"
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 250)
Frame.Position = UDim2.new(0.5, -100, 0.5, -125)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true -- Поддержка касания для мобильных устройств

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
Title.Text = "Dig It Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Parent = Frame

local function createButton(name, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Parent = Frame
    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.Text = name .. (active and ": ON" or ": OFF")
        btn.BackgroundColor3 = active and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
        callback(active)
    end)
    return btn
end

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 180, 0, 50)
StatusLabel.Position = UDim2.new(0, 10, 0, 190)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Idle\nTool: None"
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true
StatusLabel.Parent = Frame

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 180, 0, 30)
CloseButton.Position = UDim2.new(0, 10, 0, 250)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseButton.Text = "Close"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
CloseButton.Parent = Frame
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    autoDigEnabled, autoSellEnabled, teleportEnabled = false, false, false
end)

-- Функции
local function updateTool()
    local newTool = character:FindFirstChildWhichIsA("Tool") or player.Backpack:FindFirstChildWhichIsA("Tool")
    if newTool and newTool.Name:lower():match("shovel") and newTool ~= currentTool then
        currentTool = newTool
        humanoid:EquipTool(currentTool)
        StatusLabel.Text = "Status: Equipped " .. currentTool.Name .. "\nTool: " .. currentTool.Name
    elseif not newTool then
        currentTool = nil
        StatusLabel.Text = "Status: No shovel!\nTool: None"
    end
    return currentTool
end

local function autoDig(active)
    autoDigEnabled = active
    if not active then return end
    updateTool()
    if not currentTool then
        StatusLabel.Text = "Status: No shovel!\nTool: None"
        autoDigEnabled = false
        AutoDigButton.Text = "Auto Dig: OFF"
        AutoDigButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        return
    end

    spawn(function()
        while autoDigEnabled do
            StatusLabel.Text = "Status: Digging with " .. currentTool.Name .. "\nTool: " .. currentTool.Name
            humanoid.WalkSpeed = 0
            local digSuccess = false
            local digEvent = replicatedStorage:FindFirstChild("Digging") or replicatedStorage:FindFirstChild("DigEvent")
            if digEvent and digEvent:IsA("RemoteEvent") then
                for i = 1, 20 do
                    digEvent:FireServer(rootPart.Position, currentTool)
                    wait(0.05)
                end
                digSuccess = true
                wait(2) -- Дать серверу время обработать копание
            else
                for _, event in pairs(replicatedStorage:GetChildren()) do
                    if event:IsA("RemoteEvent") and event.Name:lower():match("dig") then
                        for i = 1, 20 do
                            event:FireServer(rootPart.Position, currentTool)
                            wait(0.05)
                        end
                        digSuccess = true
                        wait(2)
                        break
                    end
                end
            end
            if not digSuccess then
                pcall(function() currentTool:Activate() end)
                local toolHandle = currentTool:FindFirstChild("Handle")
                if toolHandle then
                    firetouchinterest(rootPart, toolHandle, 0)
                    wait(0.1)
                    firetouchinterest(rootPart, toolHandle, 1)
                end
                wait(2)
            end
            humanoid.WalkSpeed = 50
            humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-digRadius, digRadius), 0, math.random(-digRadius, digRadius)))
            wait(2) -- Увеличенная задержка перед новым копанием
        end
        StatusLabel.Text = "Status: Idle\nTool: " .. (currentTool and currentTool.Name or "None")
    end)
end

local function autoSell(active)
    autoSellEnabled = active
    if not active then return end
    spawn(function()
        while autoSellEnabled do
            local sellPoint = nil
            for _, obj in pairs(game.Workspace:GetChildren()) do
                if obj:IsA("BasePart") then
                    local keywords = {"sell", "shop", "vendor", "market", "trade", "portal", "npc", "sellpoint", "shoparea"}
                    for _, keyword in pairs(keywords) do
                        if obj.Name:lower():match(keyword) then
                            sellPoint = obj
                            break
                        end
                    end
                    if sellPoint then break end
                end
            end

            if sellPoint then
                StatusLabel.Text = "Status: Moving to " .. sellPoint.Name .. "\nTool: " .. (currentTool and currentTool.Name or "None")
                if (rootPart.Position - sellPoint.Position).Magnitude > 10 then
                    rootPart.CFrame = CFrame.new(sellPoint.Position + Vector3.new(0, 3, 0))
                    wait(0.1)
                else
                    humanoid.WalkSpeed = 50
                    humanoid:MoveTo(sellPoint.Position)
                    wait(0.5)
                end

                local sellSuccess = false
                for _, event in pairs(replicatedStorage:GetChildren()) do
                    if event:IsA("RemoteEvent") and event.Name:lower():match("sell") then
                        StatusLabel.Text = "Status: Selling with " .. event.Name .. "\nTool: " .. (currentTool and currentTool.Name or "None")
                        for i = 1, 100 do
                            event:FireServer()
                            wait(0.01)
                        end
                        sellSuccess = true
                        break
                    end
                end
                if not sellSuccess then
                    StatusLabel.Text = "Status: Simulating sell...\nTool: " .. (currentTool and currentTool.Name or "None")
                    firetouchinterest(rootPart, sellPoint, 0)
                    wait(0.1)
                    firetouchinterest(rootPart, sellPoint, 1)
                    print("Sell failed! Events:")
                    for _, event in pairs(replicatedStorage:GetChildren()) do
                        if event:IsA("RemoteEvent") then print(event.Name) end
                    end
                end
            else
                StatusLabel.Text = "Status: No sell point!\nTool: " .. (currentTool and currentTool.Name or "None")
                print("No sell point found! Check names.")
                wait(2)
            end
            wait(2)
        end
        StatusLabel.Text = "Status: Idle\nTool: " .. (currentTool and currentTool.Name or "None")
    end)
end

local function teleportToSell(active)
    teleportEnabled = active
    if not active then return end
    spawn(function()
        while teleportEnabled do
            local sellPoint = nil
            for _, obj in pairs(game.Workspace:GetChildren()) do
                if obj:IsA("BasePart") then
                    local keywords = {"sell", "shop", "vendor", "market", "trade", "portal", "npc", "sellpoint", "shoparea"}
                    for _, keyword in pairs(keywords) do
                        if obj.Name:lower():match(keyword) then
                            sellPoint = obj
                            break
                        end
                    end
                    if sellPoint then break end
                end
            end

            if sellPoint then
                StatusLabel.Text = "Status: Teleporting to " .. sellPoint.Name .. "\nTool: " .. (currentTool and currentTool.Name or "None")
                rootPart.CFrame = CFrame.new(sellPoint.Position + Vector3.new(0, 3, 0))
            else
                StatusLabel.Text = "Status: No sell point!\nTool: " .. (currentTool and currentTool.Name or "None")
                wait(2)
            end
            wait(5)
        end
    end)
end

-- Создание кнопок
local AutoDigButton = createButton("Auto Dig", 35, autoDig)
local AutoSellButton = createButton("Auto Sell", 80, autoSell)
local TeleportButton = createButton("Teleport", 125, teleportToSell)

-- Обновление персонажа
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    updateTool()
end)

runService.Heartbeat:Connect(function()
    if autoDigEnabled or autoSellEnabled or teleportEnabled then
        updateTool()
    end
end)

print("Dig It Hub запущен для мобильных устройств!")