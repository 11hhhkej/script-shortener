-- 将此脚本放在 StarterPlayerScripts 中
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- 配置变量
local displayMode = "both" -- "both", "displayName", "userName"
local teleportOffset = 1 -- 默认传送距离
local teleportHeight = 0 -- 默认高度偏移

-- GUI创建函数
local function createGUI()
    -- 检查是否已存在GUI，避免重复创建
    local existingGui = player.PlayerGui:FindFirstChild("TeleportGUI")
    if existingGui then
        existingGui:Destroy()
    end

    -- 创建GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TeleportGUI"
    screenGui.ResetOnSpawn = false -- 重要：防止重生时重置
    screenGui.Parent = player.PlayerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 320) -- 增加高度以容纳新控件
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true -- 重要：确保折叠时内容被裁剪
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    -- 标题栏（可点击折叠和拖动）
    local titleBar = Instance.new("TextButton")
    titleBar.Size = UDim2.new(1, -60, 0, 30) -- 为切换按钮和关闭按钮留出空间
    titleBar.Position = UDim2.new(0, 30, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleBar.Text = "玩家传送器 ▼"
    titleBar.Font = Enum.Font.GothamBold
    titleBar.TextSize = 14
    titleBar.AutoButtonColor = false
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar

    -- 名称显示模式切换按钮（左上角）
    local nameToggleButton = Instance.new("TextButton")
    nameToggleButton.Size = UDim2.new(0, 25, 0, 25)
    nameToggleButton.Position = UDim2.new(0, 3, 0, 3)
    nameToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
    nameToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameToggleButton.Text = "名"
    nameToggleButton.Font = Enum.Font.GothamBold
    nameToggleButton.TextSize = 12
    nameToggleButton.Parent = mainFrame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 4)
    toggleCorner.Parent = nameToggleButton

    -- 切换按钮悬停效果
    nameToggleButton.MouseEnter:Connect(function()
        nameToggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 220)
    end)

    nameToggleButton.MouseLeave:Connect(function()
        nameToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
    end)

    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Position = UDim2.new(1, -27, 0, 3)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "×"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    closeButton.Parent = mainFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton

    -- 关闭按钮悬停效果
    closeButton.MouseEnter:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    end)

    closeButton.MouseLeave:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    end)

    -- 内容区域
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 0, 290)
    contentFrame.Position = UDim2.new(0, 0, 0, 30)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    local playersList = Instance.new("ScrollingFrame")
    playersList.Size = UDim2.new(1, -10, 0, 150)
    playersList.Position = UDim2.new(0, 5, 0, 5)
    playersList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    playersList.ScrollBarThickness = 5
    playersList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playersList.CanvasSize = UDim2.new(0, 0, 0, 0)
    playersList.Parent = contentFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = playersList

    -- 监听列表布局变化，自动调整画布大小
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        playersList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)

    -- 传送位置设置区域
    local settingsFrame = Instance.new("Frame")
    settingsFrame.Size = UDim2.new(1, -10, 0, 60)
    settingsFrame.Position = UDim2.new(0, 5, 0, 160)
    settingsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    settingsFrame.Parent = contentFrame

    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 5)
    settingsCorner.Parent = settingsFrame

    -- 距离设置标签
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(0.4, 0, 0, 20)
    distanceLabel.Position = UDim2.new(0, 5, 0, 5)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.Text = "传送距离:"
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextSize = 12
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    distanceLabel.Parent = settingsFrame

    -- 距离输入框
    local distanceTextBox = Instance.new("TextBox")
    distanceTextBox.Size = UDim2.new(0.5, -10, 0, 20)
    distanceTextBox.Position = UDim2.new(0.4, 5, 0, 5)
    distanceTextBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    distanceTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceTextBox.Text = tostring(teleportOffset)
    distanceTextBox.Font = Enum.Font.Gotham
    distanceTextBox.TextSize = 12
    distanceTextBox.PlaceholderText = "距离"
    distanceTextBox.Parent = settingsFrame

    local distanceCorner = Instance.new("UICorner")
    distanceCorner.CornerRadius = UDim.new(0, 3)
    distanceCorner.Parent = distanceTextBox

    -- 高度设置标签
    local heightLabel = Instance.new("TextLabel")
    heightLabel.Size = UDim2.new(0.4, 0, 0, 20)
    heightLabel.Position = UDim2.new(0, 5, 0, 30)
    heightLabel.BackgroundTransparency = 1
    heightLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    heightLabel.Text = "高度偏移:"
    heightLabel.Font = Enum.Font.Gotham
    heightLabel.TextSize = 12
    heightLabel.TextXAlignment = Enum.TextXAlignment.Left
    heightLabel.Parent = settingsFrame

    -- 高度输入框
    local heightTextBox = Instance.new("TextBox")
    heightTextBox.Size = UDim2.new(0.5, -10, 0, 20)
    heightTextBox.Position = UDim2.new(0.4, 5, 0, 30)
    heightTextBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    heightTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    heightTextBox.Text = tostring(teleportHeight)
    heightTextBox.Font = Enum.Font.Gotham
    heightTextBox.TextSize = 12
    heightTextBox.PlaceholderText = "高度"
    heightTextBox.Parent = settingsFrame

    local heightCorner = Instance.new("UICorner")
    heightCorner.CornerRadius = UDim.new(0, 3)
    heightCorner.Parent = heightTextBox

    local teleportButton = Instance.new("TextButton")
    teleportButton.Size = UDim2.new(1, -10, 0, 30)
    teleportButton.Position = UDim2.new(0, 5, 0, 225)
    teleportButton.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
    teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportButton.Text = "开始传送"
    teleportButton.Font = Enum.Font.Gotham
    teleportButton.TextSize = 14
    teleportButton.Parent = contentFrame

    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 5)
    corner2.Parent = teleportButton

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 20)
    statusLabel.Position = UDim2.new(0, 5, 0, 260)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.Text = "未选择玩家"
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.Parent = contentFrame

    return screenGui, mainFrame, titleBar, nameToggleButton, closeButton, playersList, teleportButton, statusLabel, distanceTextBox, heightTextBox
end

-- 初始化GUI
local screenGui, mainFrame, titleBar, nameToggleButton, closeButton, playersList, teleportButton, statusLabel, distanceTextBox, heightTextBox = createGUI()

-- 变量
local selectedPlayer = nil
local isTeleporting = false
local teleportConnection = nil
local isExpanded = true -- 初始状态为展开

-- 拖动功能变量
local dragging = false
local dragInput
local dragStart
local startPos

-- 拖动功能函数
local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

-- 标题栏拖动事件
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        -- 改变标题栏颜色表示正在拖动
        titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                -- 恢复标题栏颜色
                titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        update(input)
    end
end)

-- 关闭GUI函数
local function closeGUI()
    screenGui.Enabled = false
    statusLabel.Text = "GUI已关闭 - 按H重新打开"
end

-- 打开GUI函数
local function openGUI()
    screenGui.Enabled = true
    statusLabel.Text = "未选择玩家"
end

-- 关闭按钮点击事件
closeButton.MouseButton1Click:Connect(function()
    closeGUI()
end)

-- 折叠/展开函数
local function toggleExpand()
    isExpanded = not isExpanded
    
    if isExpanded then
        -- 展开
        mainFrame.Size = UDim2.new(0, 250, 0, 320)
        titleBar.Text = "玩家传送器 ▼"
    else
        -- 折叠
        mainFrame.Size = UDim2.new(0, 250, 0, 30)
        titleBar.Text = "玩家传送器 ▶"
    end
end

-- 点击标题栏折叠/展开（只在非拖动时）
titleBar.MouseButton1Click:Connect(function()
    -- 如果拖动距离很小，则认为是点击而不是拖动
    if not dragging or (dragStart and (mouse.X - dragStart.X) < 5 and (mouse.Y - dragStart.Y) < 5) then
        toggleExpand()
    end
end)

-- 更新传送位置设置
local function updateTeleportSettings()
    -- 更新距离设置
    local newDistance = tonumber(distanceTextBox.Text)
    if newDistance and newDistance >= -10 and newDistance <= 50 then
        teleportOffset = newDistance
        distanceTextBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    else
        distanceTextBox.BackgroundColor3 = Color3.fromRGB(120, 70, 70)
        statusLabel.Text = "距离值无效(-10～50)"
    end
    
    -- 更新高度设置
    local newHeight = tonumber(heightTextBox.Text)
    if newHeight and newHeight >= -10 and newHeight <= 20 then
        teleportHeight = newHeight
        heightTextBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    else
        heightTextBox.BackgroundColor3 = Color3.fromRGB(120, 70, 70)
        statusLabel.Text = "高度值无效 (-10-20)"
    end
end

-- 输入框焦点失去事件
distanceTextBox.FocusLost:Connect(function(enterPressed)
    updateTeleportSettings()
end)

heightTextBox.FocusLost:Connect(function(enterPressed)
    updateTeleportSettings()
end)

-- 获取玩家显示信息
local function getPlayerDisplayInfo(targetPlayer)
    local displayName = targetPlayer.DisplayName
    local userName = targetPlayer.Name
    
    if displayMode == "displayName" then
        -- 只显示真名
        return displayName
    elseif displayMode == "userName" then
        -- 只显示用户名
        return "@" .. userName
    else
        -- 显示两者（默认模式）
        if displayName == userName then
            return displayName
        else
            return displayName .. " (@" .. userName .. ")"
        end
    end
end

-- 更新玩家列表
local function updatePlayersList()
    -- 清空现有列表
    for _, child in ipairs(playersList:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    local playerCount = 0
    
    -- 添加玩家按钮
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            playerCount = playerCount + 1
            
            local playerButton = Instance.new("TextButton")
            playerButton.Name = "PlayerBtn_" .. otherPlayer.UserId
            playerButton.Size = UDim2.new(1, -5, 0, 25)
            playerButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            playerButton.Text = getPlayerDisplayInfo(otherPlayer)
            playerButton.Font = Enum.Font.Gotham
            playerButton.TextSize = 11
            playerButton.TextWrapped = true
            playerButton.AutoButtonColor = false
            playerButton.Parent = playersList
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 4)
            corner.Parent = playerButton
            
            -- 鼠标悬停效果
            playerButton.MouseEnter:Connect(function()
                if selectedPlayer ~= otherPlayer then
                    playerButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                end
            end)
            
            playerButton.MouseLeave:Connect(function()
                if selectedPlayer ~= otherPlayer then
                    playerButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end)
            
            playerButton.MouseButton1Click:Connect(function()
                selectedPlayer = otherPlayer
                statusLabel.Text = "已选择: " .. getPlayerDisplayInfo(otherPlayer)
                
                -- 更新所有按钮颜色
                for _, btn in ipairs(playersList:GetChildren()) do
                    if btn:IsA("TextButton") then
                        if btn == playerButton then
                            btn.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
                        else
                            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                        end
                    end
                end
            end)
            
            -- 如果这个玩家是已选择的玩家，设置选中颜色
            if selectedPlayer and selectedPlayer == otherPlayer then
                playerButton.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
            end
        end
    end
    
    -- 如果没有其他玩家，显示提示
    if playerCount == 0 then
        local noPlayersLabel = Instance.new("TextLabel")
        noPlayersLabel.Size = UDim2.new(1, 0, 0, 30)
        noPlayersLabel.BackgroundTransparency = 1
        noPlayersLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        noPlayersLabel.Text = "没有其他玩家在线"
        noPlayersLabel.Font = Enum.Font.Gotham
        noPlayersLabel.TextSize = 12
        noPlayersLabel.Parent = playersList
    end
end

-- 切换名称显示模式
local function toggleNameDisplay()
    if displayMode == "both" then
        displayMode = "displayName"
        nameToggleButton.Text = "真"
        nameToggleButton.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    elseif displayMode == "displayName" then
        displayMode = "userName"
        nameToggleButton.Text = "用"
        nameToggleButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    else
        displayMode = "both"
        nameToggleButton.Text = "名"
        nameToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
    end
    
    -- 立即更新玩家列表显示
    updatePlayersList()
    
    -- 更新状态标签（如果已选择玩家）
    if selectedPlayer then
        statusLabel.Text = "已选择: " .. getPlayerDisplayInfo(selectedPlayer)
    end
end

-- 名称显示模式切换按钮点击事件
nameToggleButton.MouseButton1Click:Connect(toggleNameDisplay)

-- 传送到玩家背后的函数
local function teleportToPlayerBack()
    if not selectedPlayer then
        statusLabel.Text = "错误: 未选择玩家"
        return false
    end
    
    if not selectedPlayer.Character then
        statusLabel.Text = "错误: 玩家角色不存在"
        return false
    end
    
    local targetCharacter = selectedPlayer.Character
    local humanoidRootPart = targetCharacter:FindFirstChild("HumanoidRootPart")
    local myCharacter = player.Character
    local myRootPart = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    
    if not humanoidRootPart or not myRootPart then
        statusLabel.Text = "错误: 找不到角色根部位"
        return false
    end
    
    -- 使用设置的参数计算目标位置
    local targetCFrame = humanoidRootPart.CFrame
    local offset = targetCFrame.LookVector * -teleportOffset  -- 使用设置的传送距离
    local newPosition = targetCFrame.Position + offset + Vector3.new(0, teleportHeight, 0)  -- 使用设置的高度偏移
    
    -- 使用TweenService平滑传送
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(myRootPart, tweenInfo, {CFrame = CFrame.new(newPosition, targetCFrame.Position)})
    tween:Play()
    
    statusLabel.Text = string.format("传送到: %s (距离:%.1f)", getPlayerDisplayInfo(selectedPlayer), teleportOffset)
    return true
end

-- 停止传送的函数
local function stopTeleporting()
    if isTeleporting then
        isTeleporting = false
        teleportButton.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
        teleportButton.Text = "开始传送"
        statusLabel.Text = "已停止传送"
        
        if teleportConnection then
            teleportConnection:Disconnect()
            teleportConnection = nil
        end
    end
end

-- 开始/停止持续传送
teleportButton.MouseButton1Click:Connect(function()
    if not selectedPlayer then
        statusLabel.Text = "请先选择玩家"
        return
    end
    
    -- 在开始传送前更新设置
    updateTeleportSettings()
    
    if not isTeleporting then
        -- 开始传送
        isTeleporting = true
        teleportButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        teleportButton.Text = "停止传送"
        statusLabel.Text = string.format("正在传送到: %s (距离:%.1f)", getPlayerDisplayInfo(selectedPlayer), teleportOffset)
        
        -- 创建持续传送循环
        teleportConnection = RunService.Heartbeat:Connect(function()
            if selectedPlayer and selectedPlayer.Character and player.Character then
                local success = pcall(function()
                    teleportToPlayerBack()
                end)
                if not success then
                    statusLabel.Text = "传送出错"
                    stopTeleporting()
                end
            else
                statusLabel.Text = "错误: 角色不存在"
                stopTeleporting()
            end
        end)
    else
        -- 停止传送
        stopTeleporting()
    end
end)

-- 玩家加入/离开时更新列表
Players.PlayerAdded:Connect(function(newPlayer)
    updatePlayersList()
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if selectedPlayer == leavingPlayer then
        selectedPlayer = nil
        stopTeleporting()
        statusLabel.Text = "目标玩家已离开"
    end
    updatePlayersList()
end)

-- 角色重生时重新创建GUI并停止传送
local function onCharacterAdded(character)
    -- 停止传送
    stopTeleporting()
    
    -- 确保GUI存在
    if not player.PlayerGui:FindFirstChild("TeleportGUI") then
        screenGui, mainFrame, titleBar, nameToggleButton, closeButton, playersList, teleportButton, statusLabel, distanceTextBox, heightTextBox = createGUI()
        -- 重新绑定事件
        updatePlayersList()
        -- 重新绑定切换按钮事件
        nameToggleButton.MouseButton1Click:Connect(toggleNameDisplay)
        -- 重新绑定输入框事件
        distanceTextBox.FocusLost:Connect(function(enterPressed)
            updateTeleportSettings()
        end)
        heightTextBox.FocusLost:Connect(function(enterPressed)
            updateTeleportSettings()
        end)
    end
end

player.CharacterAdded:Connect(onCharacterAdded)

-- 快捷键支持
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.T then
        if selectedPlayer then
            updateTeleportSettings() -- 更新设置
            teleportToPlayerBack()
        end
    elseif input.KeyCode == Enum.KeyCode.Y then
        -- Y键快速折叠/展开
        toggleExpand()
    elseif input.KeyCode == Enum.KeyCode.H then
        -- H键隐藏/显示窗口
        if screenGui.Enabled then
            closeGUI()
        else
            openGUI()
        end
    elseif input.KeyCode == Enum.KeyCode.X then
        -- X键也可以关闭GUI
        closeGUI()
    elseif input.KeyCode == Enum.KeyCode.N then
        -- N键切换名称显示模式
        toggleNameDisplay()
    end
end)

-- 初始更新
updatePlayersList()

-- 自动更新玩家列表（每3秒）
while true do
    wait(3)
    if playersList and playersList.Parent and playersList.Parent.Parent and screenGui and screenGui.Enabled then
        updatePlayersList()
    end
end