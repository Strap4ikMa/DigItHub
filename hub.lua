local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local autoDigEnabled, autoSellEnabled, teleportEnabled = false, false, false
local digRadius, sellRadius = 10, 30
local currentTool = nil

-- Создание красивого интерфейса
local ScreenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "DigItHub"
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 300)
Frame.Position = UDim2.new(0.5, -125, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10) -- Скругленные углы
Instance.new("UIStroke", Frame).Color = Color3.fromRGB(100, 100, 100) -- Обводка

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Dig It Hub"
Title.TextColor3 = Color3.fromRGB(255, 215, 0) -- Золотой заголовок
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextStrokeTransparency = 0.8

-- Функция создания кнопки
local function createButton(name, posY, callback)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(0, 220, 0, 40)
    btn.Position = UDim2.new(0, 15, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 16
    btn.Font = Enum.Font.Gotham
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local gradient = Instance.new("UIGradient", btn)
    gradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 70, 70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))}

    local active = false
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.Text = name .. (active and ": ON" or ": OFF")
        btn.BackgroundColor3 = active and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(50, 50, 50)
        callback(active)
    end)
    return btn
end

-- Статус
local StatusLabel = Instance.new("TextLabel", Frame)
StatusLabel.Size = UDim2.new(0, 220, 0, 60)
StatusLabel.Position = UDim2.new(0, 15, 0, 230)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Idle\nTool: None"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 14
StatusLabel.TextWrapped = true
StatusLabel.Font = Enum.Font.Gotham

-- Функции
local function updateTool()
    local newTool = character:FindFirstChildWhichIsA("Tool") or player.Backpack:FindFirstChildWhichIsA("Tool")
    if newTool and newTool ~= currentTool then
        currentTool = newTool
        pcall(function() humanoid:EquipTool(currentTool) end) -- Обработка ошибок
        StatusLabel.Text = "Status: Equipped " .. currentTool.Name .. "\nTool: " .. currentTool.Name
    elseif not newTool then
        currentTool = nil
        StatusLabel.Text = "Status: No tool!\nTool: None"
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
            for _, event in pairs(replicatedStorage:GetChildren()) do
                if event:IsA("RemoteEvent") and event.Name:lower():match("dig") then
                    pcall(function() -- Обработка ошибок при вызове события
                        for i = 1, 20 do
                            event:FireServer(rootPart.Position, currentTool)
                            wait(0.05)
                        end
                    end)
                    digSuccess = true
                    break
                end
            end
            if not digSuccess then
                pcall(function() currentTool:Activate() end)
                wait(0.5)
            end
            humanoid.WalkSpeed = 50
            humanoid:MoveTo(rootPart.Position + Vector3.new(math.random(-digRadius, digRadius), 0, math.random(-digRadius, digRadius)))
            wait(1.5)
            print("Digging...")
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
                if obj:IsA("BasePart") and obj.Name:lower():match("sell") then
                    sellPoint = obj
                    break
                end
            end
            if sellPoint then
                StatusLabel.Text = "Status: Selling at " .. sellPoint.Name .. "\nTool: " .. (currentTool and currentTool.Name or "None")
                if (rootPart.Position - sellPoint.Position).Magnitude > 10 then
                    rootPart.CFrame = CFrame.new(sellPoint.Position + Vector3.new(0, 3, 0))
                else
                    humanoid.WalkSpeed = 50
                    humanoid:MoveTo(sellPoint.Position)
                end
                wait(0.3)
                local sellSuccess = false
                for _, event in pairs(replicatedStorage:GetChildren()) do
                    if event:IsA("RemoteEvent") and event.Name:lower():match("sell") then
                        pcall(function() -- Обработка ошибок при вызове события
                            for i = 1, 50 do
                                event:FireServer()
                                wait(0.02)
                            end
                        end)
                        sellSuccess = true
                        break
                    end
                end
                if not sellSuccess then 
                    pcall(function() firetouchinterest(rootPart, sellPoint, 0) end)
                    wait(0.1)
                    pcall(function() firetouchinterest(rootPart, sellPoint, 1) end)
                end
                print("Selling...")
            else
                StatusLabel.Text = "Status: No sell point!\nTool: " .. (currentTool and currentTool.Name or "None")
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
                if obj:IsA("BasePart") and obj.Name:lower():match("sell") then
                    sellPoint = obj
                    break
                end
            end
            if sellPoint then
                StatusLabel.Text = "Status: Teleporting to " .. sellPoint.Name .. "\nTool: " .. (currentTool and currentTool.Name or "None")
                rootPart.CFrame = CFrame.new(sellPoint.Position + Vector3.new(0, 3, 0))
            end
            wait(5)
        end
    end)
end

-- Кнопки
local AutoDigButton = createButton("Auto Dig", 40, autoDig)
local AutoSellButton = createButton("Auto Sell", 90, autoSell)
local TeleportButton = createButton("Teleport", 140, teleportToSell)

local CloseButton = Instance.new("TextButton", Frame)
CloseButton.Size = UDim2.new(0, 220, 0, 30)
CloseButton.Position = UDim2.new(0, 15, 0, 190)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseButton.Text = "Close"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.Gotham
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 8)
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
    autoDigEnabled, autoSellEnabled, teleportEnabled = false, false, false
    AutoDigButton.Text, AutoSellButton.Text, TeleportButton.Text = "Auto Dig: OFF", "Auto Sell: OFF", "Teleport: OFF"
    AutoDigButton.BackgroundColor3, AutoSellButton.BackgroundColor3, TeleportButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50), Color3.fromRGB(50, 50, 50), Color3.fromRGB(50, 50, 50)
    StatusLabel.Text = "Status: Closed\nTool: " .. (currentTool and currentTool.Name or "None")
end)

-- Обновление персонажа
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    updateTool()
end)

runService.Heartbeat:Connect(function()
    if autoDigEnabled or autoSellEnabled or teleportEnabled then updateTool() end
end)

print("Красивый хаб для Dig It запущен!")
