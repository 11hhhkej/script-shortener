local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Guo61/Cat-/refs/heads/main/main.lua"))()

local Confirmed = false

WindUI:Popup({
    Title = "CatV1.1",
    Icon = "rbxassetid://129260712070622",
    IconThemed = true,
    Content = "By:Ccat\nQQ群:1061490197 欢迎使用99夜",
    Buttons = {
        {
            Title = "启动",
            Icon = "arrow-right",
            Callback = function() Confirmed = true end,
            Variant = "Primary",
        }
    }
})

repeat wait() until Confirmed

-- 修复后的代码将所有功能整合到一个统一的 WindUI 窗口中
local Window = WindUI:CreateWindow({
    Title = "Cat Hub",
    Icon = "rbxassetid://129260712070622",
    IconThemed = true,
    Author = "感谢游玩",
    Folder = "CatHub",
    Size = UDim2.fromOffset(580, 340),
    Transparent = true,
    Theme = "Dark",
    User = { Enabled = true },
    SideBarWidth = 200,
    ScrollBarEnabled = true,
})

Window:Tag({
        Title = "v1.10",
        Color = Color3.fromHex("#30ff6a")
    })
    Window:Tag({
        Title = "99夜", 
        Color = Color3.fromHex("#315dff")
    })
    local TimeTag = Window:Tag({
        Title = "没有更多",
        Color = Color3.fromHex("#000000")
    })

-- 创建指定的大类（作为标签页）
local Tabs = {
    Home = Window:Tab({ Title = "主页", Icon = "crown" }),
    Main = Window:Tab({ Title = "主要", Icon = "zap" }),
    Ninja = Window:Tab({ Title = "传送", Icon = "user" }),
    ESP = Window:Tab({ Title = "透视", Icon = "dumbbell" }),
    Misc = Window:Tab({ Title = "其他", Icon = "settings" }),
}

Window:SelectTab(1)

-- 全局服务引用
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")

-- 本地玩家引用
local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()

-- 功能状态
local Features = {
    KillAura = false,
    AutoChop = false,
    AutoEat = false,
    ChildESP = false,
    ChestESP = false,
    InstantInteract = false
}

-- 黑名单
local Blacklist = {}

-- 客户端模块
local ClientModule
local EatRemote
local function GetClientModule()
    if not ClientModule then
        ClientModule = require(LP:WaitForChild("PlayerScripts"):WaitForChild("Client"))
        EatRemote = ClientModule and ClientModule.Events and ClientModule.Events.RequestConsumeItem
    end
    return ClientModule, EatRemote
end

-- 修复后的ESP功能管理
local espData = {}
local function createESP(target, name)
    local rootPart = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    if not rootPart or espData[target] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 100, 0, 100)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = rootPart
    billboard.Enabled = true

    local label = Instance.new("TextLabel")
    label.Text = name .. "\n" .. "0m"
    label.Size = UDim2.new(1, 0, 0, 40)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = billboard

    if name:match("Chest") then
        local image = Instance.new("ImageLabel")
        image.Position = UDim2.new(0, 20, 0, 40)
        image.Size = UDim2.new(0, 60, 0, 60)
        image.Image = "rbxassetid://18660563116"
        image.BackgroundTransparency = 1
        image.Parent = billboard
    end

    espData[target] = {gui = billboard, label = label, image = image}
end

local function update99NightESP()
    local playerChar = LP.Character
    if not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return end
    local playerPos = playerChar.HumanoidRootPart.Position

    -- Clean up removed objects and update existing ones
    for target, data in pairs(espData) do
        if not target.Parent or not target:IsDescendantOf(workspace) then
            data.gui:Destroy()
            espData[target] = nil
        else
            local rootPart = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
            if rootPart then
                local dist = (playerPos - rootPart.Position).Magnitude
                data.label.Text = data.label.Text:match("^(.-)%.-\n") .. "\n" .. math.floor(dist) .. "m"
            end
        end
    end

    -- Create new ESP
    if Features.ChestESP then
        for _, chest in next, Workspace.Items:GetChildren() do
            if chest.Name:match("Chest") and chest:IsA("Model") and not table.find(Blacklist, chest) and chest:FindFirstChild("Main") and not espData[chest] then
                createESP(chest, "宝箱")
            end
        end
    end

    if Features.ChildESP then
        for _, child in next, Workspace.Characters:GetChildren() do
            if table.find({"Lost Child", "Lost Child1", "Lost Child2", "Lost Child3", "Dino Kid", "kraken kid", "Squid kid", "Koala Kid", "koala"}, child.Name) and child:FindFirstChild("HumanoidRootPart") and not table.find(Blacklist, child) and not espData[child] then
                createESP(child, "孩子")
            end
        end
    end
end

local function toggle99NightESP(enabled)
    Features.ChestESP = enabled
    Features.ChildESP = enabled

    if enabled then
        -- Initial creation and start of the update loop
        update99NightESP()
        WindUI:Notify({Title = "提示", Content = "已开启99夜透视", Duration = 2})
    else
        -- Clean up and stop the update loop
        for _, data in pairs(espData) do
            data.gui:Destroy()
        end
        espData = {}
        WindUI:Notify({Title = "提示", Content = "已关闭99夜透视", Duration = 2})
    end
end

-- 从99night.lua移植的自动进食功能
local function TryEatFood(food)
    local _, remote = GetClientModule()
    if not remote then 
        WindUI:Notify({Title = "错误", Content = "无法获取进食远程函数", Duration = 5})
        return 
    end

    if not ReplicatedStorage:FindFirstChild("TempStorage") then
        WindUI:Notify({Title = "错误", Content = "找不到临时存储", Duration = 5})
        return
    end

    WindUI:Notify({Title = "AlienX", Content = "➡️ 正在尝试吃下" .. food.Name, Duration = 5})
    food.Parent = ReplicatedStorage.TempStorage
    local success, result = pcall(function()
        return remote:InvokeServer(food)
    end)

    if success and result and result.Success then
        WindUI:Notify({Title = "AlienX", Content = "✅成功吃下 " .. food.Name, Duration = 5})
    else
        WindUI:Notify({Title = "AlienX", Content = "❌️进食失败", Duration = 5})
    end
end

-- 物品配置
local itemConfig = {
    {name = "Log", display = "木头", espColor = Color3.fromRGB(139, 69, 19)},
    {name = "Carrot", display = "胡萝卜", espColor = Color3.fromRGB(255, 165, 0)},
    {name = "Berry", display = "浆果", espColor = Color3.fromRGB(255, 0, 0)},
    {name = "Bolt", display = "螺栓", espColor = Color3.fromRGB(255, 255, 0)},
    {name = "Broken Fan", display = "风扇", espColor = Color3.fromRGB(100, 100, 100)},
    {name = "Coal", display = "煤炭", espColor = Color3.fromRGB(0, 0, 0)},
    {name = "Coin Stack", display = "钱堆", espColor = Color3.fromRGB(255, 215, 0)},
    {name = "Fuel Canister", display = "燃料罐", espColor = Color3.fromRGB(255, 50, 50)},
    {name = "Item Chest", display = "宝箱", espColor = Color3.fromRGB(210, 180, 140)},
    {name = "Old Flashlight", display = "手电筒", espColor = Color3.fromRGB(200, 200, 200)},
    {name = "Old Radio", display = "收音机", espColor = Color3.fromRGB(150, 150, 150)},
    {name = "Rifle Ammo", display = "步枪子弹", espColor = Color3.fromRGB(150, 75, 0)},
    {name = "Revolver Ammo", display = "左轮子弹", espColor = Color3.fromRGB(150, 75, 0)},
    {name = "Sheet Metal", display = "金属板", espColor = Color3.fromRGB(192, 192, 192)},
    {name = "Revolver", display = "左轮", espColor = Color3.fromRGB(75, 75, 75)},
    {name = "Rifle", display = "步枪", espColor = Color3.fromRGB(75, 75, 75)},
    {name = "Bandage", display = "绷带", espColor = Color3.fromRGB(255, 240, 245)},
    {name = "Crossbow Cultist", display = "敌人", espColor = Color3.fromRGB(255, 0, 0)},
    {name = "Bear", display = "熊", espColor = Color3.fromRGB(139, 69, 19)},
    {name = "Alpha Wolf", display = "阿尔法狼", espColor = Color3.fromRGB(128, 128, 128)},
    {name = "Wolf", display = "狼", espColor = Color3.fromRGB(192, 192, 192)},
    {name = "Chair", display = "椅子", espColor = Color3.fromRGB(160, 82, 45)},
    {name = "Tyre", display = "轮胎", espColor = Color3.fromRGB(20, 20, 20)},
    {name = "Alien Chest", display = "外星宝箱", espColor = Color3.fromRGB(0, 255, 0)},
    {name = "Chest", display = "宝箱", espColor = Color3.fromRGB(210, 180, 140)},
    {name = "Lost Child", display = "走失的孩子", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Lost Child1", display = "走失的孩子1", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Lost Child2", display = "走失的孩子2", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Lost Child3", display = "走失的孩子3", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Dino Kid", display = "恐龙孩子", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "kraken kid", display = "海怪孩子", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Squid kid", display = "鱿鱼孩子", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Koala Kid", display = "考拉孩子", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "koala", display = "考拉", espColor = Color3.fromRGB(0, 255, 255)}
}

local BONFIRE_POSITION = Vector3.new(0.189, 7.831, -0.341)

local function findItems(itemName)
    local found = {}
    local folders = {"ltems", "Items", "MapItems", "WorldItems"}
    
    for _, folderName in ipairs(folders) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, item in ipairs(folder:GetDescendants()) do
                if item.Name == itemName and item:IsA("Model") then
                    local primaryPart = item.PrimaryPart or item:FindFirstChild("HumanoidRootPart")
                    if primaryPart then
                        table.insert(found, {model = item, part = primaryPart})
                    end
                end
            end
        end
    end
    
    return found
end

local function teleportToItem(itemName, displayName)
    local character = Character
    if not character then return end
    
    local items = findItems(itemName)
    if #items == 0 then
        WindUI:Notify({Title = "提示", Content = "未找到"..displayName, Duration = 2})
        return
    end
    
    local closest = nil
    local minDist = math.huge
    local charPos = character.PrimaryPart.Position
    
    for _, item in ipairs(items) do
        local dist = (item.part.Position - charPos).Magnitude
        if dist < minDist then
            minDist = dist
            closest = item.part
        end
    end
    
    if closest then
        character:MoveTo(closest.Position + Vector3.new(0, 3, 0))
        WindUI:Notify({Title = "成功", Content = "已传送到"..displayName, Duration = 2})
    end
end

local function teleportToBonfire()
    local character = Character
    if not character then return end
    
    character:MoveTo(BONFIRE_POSITION)
    WindUI:Notify({Title = "成功", Content = "已传送回篝火", Duration = 2})
end

local function teleportItemsToPlayer(itemName, displayName)
    local character = Character
    if not character then 
        WindUI:Notify({Title = "错误", Content = "无法获取角色", Duration = 2})
        return 
    end
    
    local items = findItems(itemName)
    if #items == 0 then
        WindUI:Notify({Title = "提示", Content = "未找到"..displayName, Duration = 2})
        return
    end
    
    local charPos = character.PrimaryPart.Position
    local radius = 5
    local angleStep = (2 * math.pi) / #items
    
    for i, item in ipairs(items) do
        local angle = angleStep * i
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local targetPos = charPos + Vector3.new(x, 0, z)
        
        if item.model:FindFirstChild("Handle") then
            item.model.Handle.CFrame = CFrame.new(targetPos)
        elseif item.part then
            item.part.CFrame = CFrame.new(targetPos)
        end
        
        -- 开始拖动物品
        local startArgs = { [1] = item.model }
        game:GetService("ReplicatedStorage").RemoteEvents.RequestStartDraggingItem:FireServer(unpack(startArgs))
        
        -- 短暂延迟后停止拖动（模拟拖动过程）
        task.wait(0.1)
        local stopArgs = { [1] = item.model }
        game:GetService("ReplicatedStorage").RemoteEvents.StopDraggingItem:FireServer(unpack(stopArgs))
    end
    
    WindUI:Notify({
        Title = "成功", 
        Content = "已将"..#items.."个"..displayName.."传送到旁边并进行拖动", 
        Duration = 2
    })
end

local function toggleESP(itemName, displayName, color)
    if _G["ESP_"..itemName] then
        for _, gui in ipairs(_G["ESP_"..itemName].guis) do
            gui:Destroy()
        end
        _G["ESP_"..itemName].conn:Disconnect()
        _G["ESP_"..itemName] = nil
        WindUI:Notify({Title = "提示", Content = "已关闭"..displayName.."透视", Duration = 2})
        return
    end
    
    local items = findItems(itemName)
    _G["ESP_"..itemName] = {guis = {}}
    
    local function createESP(itemPart)
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = itemPart
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 300
        
        local text = Instance.new("TextLabel")
        text.Text = displayName
        text.Size = UDim2.new(1, 0, 1, 0)
        text.Font = Enum.Font.SourceSansBold
        text.TextSize = 18
        text.TextColor3 = color
        text.BackgroundTransparency = 1
        text.TextStrokeTransparency = 0.5
        text.TextStrokeColor3 = Color3.new(0, 0, 0)
        text.Parent = billboard
        
        billboard.Parent = itemPart
        table.insert(_G["ESP_"..itemName].guis, billboard)
    end
    
    for _, item in ipairs(items) do
        createESP(item.part)
    end
    
    _G["ESP_"..itemName].conn = workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == itemName and descendant:IsA("Model") then
            local primaryPart = descendant.PrimaryPart or descendant:FindFirstChild("HumanoidRootPart")
            if primaryPart then
                createESP(primaryPart)
            end
        end
    end)
    
    WindUI:Notify({
        Title = "提示", 
        Content = "已开启"..displayName.."透视 ("..#items.."个)", 
        Duration = 2
    })
end


-- 自动功能主循环 (从99night.lua移植)
local lastKillAura, lastAutoChop, lastAutoEat = 0, 0, 0
local instantInteractConn
RunService.Heartbeat:Connect(function()
    local now = tick()
    
    -- 瞬间互动
    if Features.InstantInteract then
        if not instantInteractConn then
            instantInteractConn = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
                prompt.HoldDuration = 0
            end)
        end
    else
        if instantInteractConn then
            instantInteractConn:Disconnect()
            instantInteractConn = nil
        end
    end

    -- 杀戮光环
    if Features.KillAura and now - lastKillAura >= 0.7 then
        lastKillAura = now
        if Character and Character:FindFirstChild("ToolHandle") then
            local tool = Character.ToolHandle.OriginalItem.Value
            if tool and ({["Old Axe"] = true, ["Good Axe"] = true, ["Spear"] = true, ["Hatchet"] = true, ["Bone Club"] = true})[tool.Name] then
                for _, target in next, Workspace.Characters:GetChildren() do
                    if target:IsA("Model") and target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("HitRegisters") then
                        if (Character.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude <= 100 then
                            ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(target, tool, true, Character.HumanoidRootPart.CFrame)
                        end
                    end
                end
            end
        end
    end

    -- 自动砍树
    if Features.AutoChop and now - lastAutoChop >= 0.7 then
        lastAutoChop = now
        if Character and Character:FindFirstChild("ToolHandle") then
            local tool = Character.ToolHandle.OriginalItem.Value
            if tool and ({["Old Axe"] = true, ["Stone Axe"] = true, ["Iron Axe"] = true})[tool.Name] then
                local function ChopTree(path)
                    for _, tree in next, path:GetChildren() do
                        task.wait(.1)
                        if tree:IsA("Model") and ({["Small Tree"] = true, ["TreeBig1"] = true, ["TreeBig2"] = true, ["TreeBig3"] = true})[tree.Name] and tree:FindFirstChild("HitRegisters") then
                            local trunk = tree:FindFirstChild("Trunk") or tree:FindFirstChild("HumanoidRootPart") or tree.PrimaryPart
                            if trunk and (Character.HumanoidRootPart.Position - trunk.Position).Magnitude <= 100 then
                                ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(tree, tool, true, Character.HumanoidRootPart.CFrame)
                            end
                        end
                    end
                end
                ChopTree(Workspace.Map.Foliage)
                ChopTree(Workspace.Map.Landmarks)
            end
        end
    end

    -- 自动进食
    if Features.AutoEat and now - lastAutoEat >= 10 then
        lastAutoEat = now
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            local eatCount = 0
            for _, obj in pairs(Workspace.Items:GetChildren()) do
                if eatCount >= 2 then break end
                if obj:IsA("Model") and ({["Carrot"] = true, ["Berry"] = true, ["Morsel"] = false, ["Cooked Morsel"] = true, ["Steak"] = false, ["Cooked Steak"] = true})[obj.Name] then
                    local mainPart = obj:FindFirstChild("Handle") or obj.PrimaryPart
                    if mainPart and (mainPart.Position - Character.HumanoidRootPart.Position).Magnitude < 25 then
                        TryEatFood(obj)
                        eatCount = eatCount + 1
                    end
                end
            end
            if eatCount == 0 then
                WindUI:Notify({Title = "AlienX", Content = "🔍25米范围内无食物", Duration = 5})
            end
        else
            WindUI:Notify({Title = "AlienX", Content = "⏳等待玩家加载", Duration = 5})
        end
    end

    -- 99夜ESP更新
    if Features.ChestESP or Features.ChildESP then
        update99NightESP()
    end
end)

-- 99夜功能集成到UI中
-- 主要功能标签页
Tabs.Main:Toggle({
    Title = "杀戮光环",
    Description = "自动攻击附近敌人",
    Value = false,
    Callback = function(value)
        Features.KillAura = value
    end
})

Tabs.Main:Toggle({
    Title = "自动砍树",
    Description = "自动砍伐附近树木",
    Value = false,
    Callback = function(value)
        Features.AutoChop = value
    end
})

Tabs.Main:Toggle({
    Title = "自动进食",
    Description = "自动吃附近食物",
    Value = false,
    Callback = function(value)
        Features.AutoEat = value
    end
})

Tabs.Main:Toggle({
    Title = "瞬间互动",
    Description = "立即完成所有互动",
    Value = false,
    Callback = function(value)
        Features.InstantInteract = value
    end
})

-- 传送标签页
Tabs.Ninja:Button({
    Title = "传送回篝火",
    Callback = teleportToBonfire
})

-- 物品传送
for _, item in ipairs(itemConfig) do
    Tabs.Ninja:Button({
        Title = "传送到"..item.display,
        Callback = function()
            teleportToItem(item.name, item.display)
        end
    })
    Tabs.Ninja:Button({
        Title = "召唤"..item.display,
        Callback = function()
            teleportItemsToPlayer(item.name, item.display)
        end
    })
end

-- 透视功能标签页
Tabs.ESP:Toggle({
    Title = "99夜透视 (宝箱&孩子)",
    Value = false,
    Callback = toggle99NightESP
})

-- 添加物品透视按钮
for _, item in ipairs(itemConfig) do
    Tabs.ESP:Button({
        Title = item.display.."透视",
        Callback = function() 
            toggleESP(item.name, item.display, item.espColor) 
        end
    })
end

Tabs.ESP:Button({
    Title = "清除所有透视",
    Callback = function()
        for _, item in ipairs(itemConfig) do
            if _G["ESP_"..item.name] then
                for _, gui in ipairs(_G["ESP_"..item.name].guis) do
                    gui:Destroy()
                end
                _G["ESP_"..item.name].conn:Disconnect()
                _G["ESP_"..item.name] = nil
            end
        end
        -- Also clear 99 night ESP
        for _, data in pairs(espData) do
            data.gui:Destroy()
        end
        espData = {}
        Features.ChestESP = false
        Features.ChildESP = false
        WindUI:Notify({Title = "提示", Content = "已清除所有透视", Duration = 2})
    end
})

-- Cat Hub 原有功能
local autoLoops = {}

local function startLoop(name, callback, delay)
    if autoLoops[name] then return end
    autoLoops[name] = coroutine.wrap(function()
        while autoLoops[name] do
            pcall(callback)
            task.wait(delay)
        end
    end)
    task.spawn(autoLoops[name])
end

local function stopLoop(name)
    if not autoLoops[name] then return end
    autoLoops[name] = nil
end

--- 主页 Tab ---
Tabs.Home:Paragraph({
    Title = "666这么帅",
    Desc = "必须帅",
    Image = "https://raw.githubusercontent.com/Guo61/Cat-/refs/heads/main/1756468599211.png",
    ImageSize = 42,
    Thumbnail = "https://raw.githubusercontent.com/Guo61/Cat-/refs/heads/main/1756468641440.jpg",
    ThumbnailSize = 120
})

Tabs.Home:Paragraph({
    Title = "欢迎",
    Desc = "需要时开启反挂机。脚本仍在更新中... 作者: Ccat\n脚本免费, 请勿倒卖。",
})
-- 反挂机 (通过外部链接加载)
Tabs.Home:Button({
    Title = "反挂机",
    Desc = "从GitHub加载并执行反挂机",
    Callback = function()
        pcall(function()
            local response = game:HttpGet("https://raw.githubusercontent.com/Guo61/Cat-/refs/heads/main/%E5%8F%8D%E6%8C%82%E6%9C%BA.lua", true)
            if response and #response > 100 then
                loadstring(response)()
            end
        end)
    end
})

-- FPS 显示
Tabs.Home:Toggle({
    Title = "显示FPS",
    Desc = "在屏幕上显示当前FPS",
    Callback = function(state)
        local FpsGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("FPSGui")
        if state then
            if not FpsGui then
                FpsGui = Instance.new("ScreenGui")
                local FpsXS = Instance.new("TextLabel")
                FpsGui.Name = "FPSGui"
                FpsGui.ResetOnSpawn = false
                FpsXS.Name = "FpsXS"
                FpsXS.Size = UDim2.new(0, 100, 0, 50)
                FpsXS.Position = UDim2.new(0, 10, 0, 10)
                FpsXS.BackgroundTransparency = 1
                FpsXS.Font = Enum.Font.SourceSansBold
                FpsXS.Text = "FPS: 0"
                FpsXS.TextSize = 20
                FpsXS.TextColor3 = Color3.new(1, 1, 1)
                FpsXS.Parent = FpsGui
                FpsGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
                
                game:GetService("RunService").Heartbeat:Connect(function()
                    local fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
                    FpsXS.Text = "FPS: " .. fps
                end)
            end
            FpsGui.Enabled = true
        else
            if FpsGui then
                FpsGui.Enabled = false
            end
        end
    end
})

-- 范围显示
Tabs.Home:Toggle({
    Title = "显示范围",
    Desc = "显示玩家范围",
    Callback = function(state)
        local HeadSize = 20
        local highlight = Instance.new("Highlight")
        highlight.Adornee = nil
        highlight.OutlineTransparency = 0
        highlight.FillTransparency = 0.7
        highlight.FillColor = Color3.fromHex("#0000FF")

        local function applyHighlight(character)
            if not character:FindFirstChild("WindUI_RangeHighlight") then
                local clone = highlight:Clone()
                clone.Adornee = character
                clone.Name = "WindUI_RangeHighlight"
                clone.Parent = character
            end
        end

        local function removeHighlight(character)
            local h = character:FindFirstChild("WindUI_RangeHighlight")
            if h then
                h:Destroy()
            end
        end

        if state then
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Name ~= game.Players.LocalPlayer.Name and player.Character then
                    applyHighlight(player.Character)
                end
            end
            game.Players.PlayerAdded:Connect(function(player)
                player.CharacterAdded:Connect(function(character)
                    task.wait(1)
                    applyHighlight(character)
                end)
            end)
            game.Players.PlayerRemoving:Connect(function(player)
                if player.Character then
                    removeHighlight(player.Character)
                end
            end)
        else
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character then
                    removeHighlight(player.Character)
                end
            end
        end
    end
})

-- 半隐身, 玩家入退提示, 甩飞
Tabs.Home:Button({
    Title = "半隐身",
    Desc = "从GitHub加载并执行隐身脚本",
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Invisible-35376"))() end)
    end
})
Tabs.Home:Button({
    Title = "玩家入退提示",
    Desc = "从GitHub加载并执行提示脚本",
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/boyscp/scriscriptsc/main/bbn.lua"))() end)
    end
})

-- 修复后的甩飞玩家功能
Tabs.Home:Button({
    Title = "甩飞玩家",
    Desc = "将选中的玩家甩飞",
    Callback = function()
        local selectedPlayerName = playersDropdown.Value
        if not selectedPlayerName then
            WindUI:Notify({Title = "错误", Content = "未选择玩家", Duration = 3})
            return
        end
        
        local targetPlayer = game.Players:FindFirstChild(selectedPlayerName)
        if not targetPlayer or not targetPlayer.Character then
            WindUI:Notify({Title = "错误", Content = "未找到玩家或玩家角色", Duration = 3})
            return
        end
        
        local character = targetPlayer.Character
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            WindUI:Notify({Title = "错误", Content = "玩家角色缺少HumanoidRootPart", Duration = 3})
            return
        end
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 50, 0) + (humanoidRootPart.CFrame.lookVector * 10)
        bodyVelocity.P = 1000
        bodyVelocity.Parent = humanoidRootPart
        
        -- 施加力一段时间后移除
        task.delay(1, function()
            bodyVelocity:Destroy()
            WindUI:Notify({Title = "成功", Content = "已甩飞玩家 " .. selectedPlayerName, Duration = 3})
        end)
    end
})


-- 防甩飞 (Toggle)
local antiWalkFlingConn
Tabs.Home:Toggle({
    Title = "防甩飞",
    Desc = "不要和甩飞同时开启!",
    Callback = function(state)
        local player = game.Players.LocalPlayer
        if state then
            if antiWalkFlingConn then antiWalkFlingConn:Disconnect() end
            local lastVelocity = Vector3.new()
            antiWalkFlingConn = game:GetService("RunService").Stepped:Connect(function()
                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local currentVelocity = hrp.Velocity
                if (currentVelocity - lastVelocity).Magnitude > 100 then
                    hrp.Velocity = lastVelocity
                end
                lastVelocity = currentVelocity
            end)
        else
            if antiWalkFlingConn then antiWalkFlingConn:Disconnect() end
        end
    end
})

local function setPlayerHealth(healthValue)
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    -- 等待角色加载
    if not character then
        character = player.CharacterAdded:Wait()
    end
    
    -- 等待 Humanoid 加载
    local humanoid = character:WaitForChild("Humanoid")
    
    -- 设置血量
    humanoid.Health = healthValue
    
    -- 显示提示
    WindUI:Notify({
        Title = "血量设置",
        Content = "血量已设置为: " .. healthValue,
        Duration = 3
    })
end

-- 血量滑块
Tabs.Home:Slider({
    Title = "设置血量",
    Desc = "调整人物血量 (0-1000)",
    Value = { Min = 0, Max = 1000, Default = 100 },
    Callback = function(val)
        setPlayerHealth(val)
    end
})

-- 快速血量按钮
Tabs.Home:Button({
    Title = "满血",
    Desc = "将血量设置为最大值",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        setPlayerHealth(humanoid.MaxHealth)
    end
})

Tabs.Home:Button({
    Title = "半血",
    Desc = "将血量设置为一半",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        setPlayerHealth(humanoid.MaxHealth / 2)
    end
})

-- 无敌模式切换
local godModeEnabled = false
local originalHealth
local godModeConnection

Tabs.Home:Toggle({
    Title = "无敌模式",
    Desc = "开启后血量不会减少",
    Default = false,
    Callback = function(state)
        godModeEnabled = state
        local player = game.Players.LocalPlayer
        local character = player.Character
        
        if not character then
            character = player.CharacterAdded:Wait()
        end
        
        local humanoid = character:WaitForChild("Humanoid")
        
        if state then
            -- 保存原始血量
            originalHealth = humanoid.Health
            
            -- 监听血量变化
            godModeConnection = humanoid.HealthChanged:Connect(function(newHealth)
                if newHealth < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
            
            -- 设置为满血
            humanoid.Health = humanoid.MaxHealth
            
            WindUI:Notify({
                Title = "无敌模式",
                Content = "无敌模式已开启",
                Duration = 3
            })
        else
            -- 关闭无敌模式
            if godModeConnection then
                godModeConnection:Disconnect()
                godModeConnection = nil
            end
            
            -- 恢复原始血量
            if originalHealth then
                humanoid.Health = originalHealth
            end
            
            WindUI:Notify({
                Title = "无敌模式",
                Content = "无敌模式已关闭",
                Duration = 3
            })
        end
    end
})
-- 速度, 重力, 跳跃
Tabs.Home:Slider({
    Title = "设置速度",
    Desc = "可输入",
    Value = { Min = 0, Max = 520, Default = 25 },
    Callback = function(val)
        local character = game.Players.LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = val
            end
        end
    end
})
Tabs.Home:Slider({
    Title = "设置个人重力",
    Desc = "默认值即为最大值",
    Value = { Min = 0, Max = 196.2, Default = 196.2, Rounding = 1 },
    Callback = function(val)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:WaitForChild("HumanoidRootPart")
        local oldGravity = rootPart:FindFirstChild("PersonalGravity")
        if oldGravity then oldGravity:Destroy() end

        if val ~= workspace.Gravity then
            local personalGravity = Instance.new("BodyForce")
            personalGravity.Name = "PersonalGravity"
            local mass = rootPart:GetMass()
            local force = Vector3.new(0, mass * (workspace.Gravity - val), 0)
            personalGravity.Force = force
            personalGravity.Parent = rootPart
        end
    end
})
Tabs.Home:Slider({
    Title = "设置跳跃高度",
    Desc = "可输入",
    Value = { Min = 0, Max = 200, Default = 50 },
    Callback = function(val)
        local character = game.Players.LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = val
            end
        end
    end
})

local function getPlayerNames()
    local names = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    return names
end

-- 创建一个函数来刷新下拉菜单
local function refreshPlayerDropdown()
    -- 增加了一个检查，确保playersDropdown存在
    if not playersDropdown then return end

    local currentValues = playersDropdown:GetValues()
    local newValues = getPlayerNames()
    local added = {}
    local removed = {}
    
    local newSet = {}
    for _, name in ipairs(newValues) do
        newSet[name] = true
    end
    
    for _, name in ipairs(currentValues) do
        if not newSet[name] then
            table.insert(removed, name)
        end
    end
    
    local currentSet = {}
    for _, name in ipairs(currentValues) do
        currentSet[name] = true
    end
    
    for _, name in ipairs(newValues) do
        if not currentSet[name] then
            table.insert(added, name)
        end
    end
    
    for _, name in ipairs(removed) do
        playersDropdown:RemoveValue(name)
    end
    
    for _, name in ipairs(added) do
        playersDropdown:AddValue(name)
    end
end

-- **将下拉菜单的创建代码保持在此处，这是原始代码中的位置**
local playersDropdown = Tabs.Home:Dropdown({
    Title = "选择要传送的玩家",
    Values = getPlayerNames(), -- 初始填充
})

Tabs.Home:Button({
    Title = "传送至玩家",
    Desc = "传送到选中的玩家",
    Callback = function()
        local selectedPlayerName = playersDropdown.Value
        if not selectedPlayerName then
            WindUI:Notify({Title = "错误", Content = "未选择玩家", Duration = 3})
            return
        end
        local targetPlayer = game.Players:FindFirstChild(selectedPlayerName)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            humanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
        end
    end
})

-- **修复：将事件连接代码移动到这里，确保playersDropdown已经创建**
game.Players.PlayerAdded:Connect(refreshPlayerDropdown)
game.Players.PlayerRemoving:Connect(refreshPlayerDropdown)

-- 修复后的部分，使用 AddValue 和 RemoveValue 方法来更新
game.Players.PlayerAdded:Connect(refreshPlayerDropdown)
game.Players.PlayerRemoving:Connect(refreshPlayerDropdown)


-- 飞行, 无限跳, 自瞄, 子弹追踪, 夜视, 穿墙
Tabs.Home:Button({
    Title = "飞行",
    Desc = "从GitHub加载并执行飞行脚本",
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Guo61/Cat-/refs/heads/main/%E9%A3%9E%E8%A1%8C%E8%84%9A%E6%9C%AC.lua"))() end)
    end
})
Tabs.Home:Button({
    Title = "无限跳",
    Desc = "开启后无法关闭",
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://pastebin.com/raw/V5PQy3y0", true))() end)
    end
})
Tabs.Home:Button({
    Title = "自瞄",
    Desc = "宙斯自瞄",
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/chillz-workshop/main/Arceus%20Aimbot.lua"))() end)
    end
})

local trackData = {}
Tabs.Home:Toggle({
    Title = "子弹追踪",
    Default = false,
    Callback = function(state)
        trackData.enabled = state
        if not state then
            if trackData.workspaceConn then trackData.workspaceConn:Disconnect() end
            for _, conn in pairs(trackData.bulletConns or {}) do conn:Disconnect() end
            trackData.bulletConns = {}
            return
        end
        local function getTarget(bulletPos)
            local nearestTarget, nearestDist = nil, math.huge
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    local char = player.Character
                    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if humanoid and humanoid.Health > 0 and root then
                        local dist = (bulletPos - root.Position).Magnitude
                        if dist <= 70 and dist < nearestDist then
                            nearestDist = dist
                            nearestTarget = root
                        end
                    end
                end
            end
            return nearestTarget
        end

        local function attachTrack(bullet)
            local bulletPart = bullet:IsA("BasePart") and bullet or bullet:FindFirstChildWhichIsA("BasePart")
            if not bulletPart then return end
            local bodyVel = bulletPart:FindFirstChildOfClass("BodyVelocity")
            if not bodyVel then
                bodyVel = Instance.new("BodyVelocity")
                bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVel.Velocity = bulletPart.Velocity
                bodyVel.Parent = bulletPart
            end

            local bulletConn = game:GetService("RunService").Heartbeat:Connect(function()
                if not bulletPart.Parent or not trackData.enabled then
                    bulletConn:Disconnect()
                    trackData.bulletConns[bulletConn] = nil
                    return
                end
                local target = getTarget(bulletPart.Position)
                if target then
                    local trackDir = (target.Position - bulletPart.Position).Unit
                    bodyVel.Velocity = trackDir * bulletPart.Velocity.Magnitude
                    bulletPart.CFrame = CFrame.new(bulletPart.Position, target.Position)
                end
            end)
            trackData.bulletConns[bulletConn] = true
        end
        trackData.workspaceConn = workspace.ChildAdded:Connect(function(child)
            local isLocalBullet = (child.Name:lower():find("bullet") or child.Name:lower():find("projectile") or child.Name:lower():find("missile")) and (child:FindFirstChild("Owner") and child.Owner.Value == game.Players.LocalPlayer)
            if isLocalBullet then
                task.wait(0.05)
                attachTrack(child)
            end
        end)
    end
})

local nightVisionData = {}
Tabs.Home:Toggle({
    Title = "夜视",
    Default = false,
    Callback = function(isEnabled)
        local lighting = game:GetService("Lighting")
        if isEnabled then
            pcall(function()
                nightVisionData.originalAmbient = lighting.Ambient
                nightVisionData.originalBrightness = lighting.Brightness
                nightVisionData.originalFogEnd = lighting.FogEnd
                lighting.Ambient = Color3.fromRGB(255, 255, 255)
                lighting.Brightness = 1
                lighting.FogEnd = 1e10
                for _, v in pairs(lighting:GetDescendants()) do
                    if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
                        v.Enabled = false
                    end
                end
                nightVisionData.changedConnection = lighting.Changed:Connect(function()
                    lighting.Ambient = Color3.fromRGB(255, 255, 255)
                    lighting.Brightness = 1
                    lighting.FogEnd = 1e10
                end)
                local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
                local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                if not humanoidRootPart:FindFirstChildWhichIsA("PointLight") then
                    local headlight = Instance.new("PointLight", humanoidRootPart)
                    headlight.Brightness = 1
                    headlight.Range = 60
                    nightVisionData.pointLight = headlight
                end
            end)
        else
            if nightVisionData.originalAmbient then lighting.Ambient = nightVisionData.originalAmbient end
            if nightVisionData.originalBrightness then lighting.Brightness = nightVisionData.originalBrightness end
            if nightVisionData.originalFogEnd then lighting.FogEnd = nightVisionData.originalFogEnd end
            if nightVisionData.changedConnection then nightVisionData.changedConnection:Disconnect() end
            if nightVisionData.pointLight and nightVisionData.pointLight.Parent then nightVisionData.pointLight:Destroy() end
        end
    end
})

local noclipConn
Tabs.Home:Toggle({
    Title = "穿墙",
    Default = false,
    Callback = function(state)
        local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
        if state then
            noclipConn = game:GetService("RunService").Stepped:Connect(function()
                if character then
                    for _, v in pairs(character:GetChildren()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end
                end
            end)
        else
            if noclipConn then noclipConn:Disconnect() end
            if character then
                for _, v in pairs(character:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = true
                    end
                end
            end
        end
    end
})

-- 人物透视 (ESP) 功能
local espEnabled = false
local espConnections = {}
local espHighlights = {}
local espNameTags = {}

local function createESP(player)
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Create Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "WindUI_ESP"
    highlight.Adornee = char
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    espHighlights[player] = highlight

    -- Create Name Tag
    local nameTag = Instance.new("BillboardGui")
    nameTag.Name = "WindUI_NameTag"
    nameTag.Adornee = humanoidRootPart
    nameTag.Size = UDim2.new(0, 150, 0, 20)
    nameTag.StudsOffset = Vector3.new(0, 2.8, 0)
    nameTag.AlwaysOnTop = true
    nameTag.Parent = humanoidRootPart
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = player.Name
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextScaled = false
    textLabel.Parent = nameTag
    espNameTags[player] = nameTag
end

local function removeESP(player)
    if espHighlights[player] and espHighlights[player].Parent then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
    if espNameTags[player] and espNameTags[player].Parent then
        espNameTags[player]:Destroy()
        espNameTags[player] = nil
    end
end

local function toggleESP(state)
    espEnabled = state
    if state then
        -- Add ESP for all current players
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                pcall(createESP, player)
            end
        end

        -- Connect events for new players
        espConnections.playerAdded = game.Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Wait()
            pcall(createESP, player)
        end)
        espConnections.playerRemoving = game.Players.PlayerRemoving:Connect(function(player)
            removeESP(player)
        end)
    else
        -- Clean up existing ESP and disconnect events
        if espConnections.playerAdded then espConnections.playerAdded:Disconnect() end
        if espConnections.playerRemoving then espConnections.playerRemoving:Disconnect() end
        for player, _ in pairs(espHighlights) do
            removeESP(player)
        end
        espHighlights = {}
        espNameTags = {}
    end
end

Tabs.Home:Toggle({
    Title = "人物透视 (ESP)",
    Desc = "显示其他玩家的透视框和名字。",
    Default = false,
    Callback = toggleESP,
})

Tabs.Home:Button({
    Title = "切换服务器",
    Desc = "切换到相同游戏的另一个服务器",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        local placeId = game.PlaceId
        
        TeleportService:Teleport(placeId, game.Players.LocalPlayer)
    end
})

Tabs.Home:Button({
    Title = "重新加入服务器",
    Desc = "尝试重新加入当前服务器",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        local placeId = game.PlaceId
        local jobId = game.JobId
        
        TeleportService:TeleportToPlaceInstance(placeId, jobId, game.Players.LocalPlayer)
    end
})

Tabs.Home:Button({
    Title = "复制服务器邀请链接",
    Desc = "复制当前服务器的邀请链接到剪贴板",
    Callback = function()
        local inviteLink = "roblox://experiences/start?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId
        setclipboard(inviteLink)
        WindUI:Notify({
            Title = "邀请链接已复制",
            Content = "链接已复制到剪贴板",
            Duration = 3
        })
    end
})

Tabs.Home:Button({
    Title = "复制服务器ID",
    Desc = "复制当前服务器的Job ID到剪贴板",
    Callback = function()
        setclipboard(game.JobId)
        WindUI:Notify({
            Title = "服务器ID已复制",
            Content = "Job ID: " .. game.JobId,
            Duration = 3
        })
    end
})


Tabs.Home:Button({
    Title = "服务器信息",
    Desc = "显示当前服务器的信息",
    Callback = function()
        local players = game.Players:GetPlayers()
        local maxPlayers = game.Players.MaxPlayers
        local placeId = game.PlaceId
        local jobId = game.JobId
        local serverType = game:GetService("RunService"):IsStudio() and "Studio" or "Live"
        
        WindUI:Notify({
            Title = "服务器信息",
            Content = string.format("玩家数量: %d/%d\nPlace ID: %d\nJob ID: %s\n服务器类型: %s", #players, maxPlayers, placeId, jobId, serverType),
            Duration = 10
        })
    end
})

Tabs.Misc:Button({
    Title = "复制作者QQ",
    Callback = function()
        setclipboard("3395858053")
        WindUI:Notify({Title = "QQ群号", Content = "群号已复制到剪贴板", Duration = 3})
    end
})

Tabs.Misc:Button({
    Title = "脚本信息",
    Desc = "显示脚本相关信息",
    Callback = function()
        WindUI:Notify({
            Title = "脚本信息",
            Content = "Cat Hub v1.15\n作者: Ccat\nQQ群: 1061490197",
            Duration = 10
        })
    end
})

Tabs.Misc:Button({
    Title = "检查更新",
    Desc = "检查脚本是否有更新",
    Callback = function()
        WindUI:Notify({
            Title = "更新检查",
            Content = "当前版本: v1.15\n已是最新版本",
            Duration = 5
        })
    end
})
-- 添加一个定时器来更新标签
spawn(function()
    while true do
        wait(5)
        local currentTime = os.date("%H:%M:%S")
        TimeTag:Set({
            Title = "当前时间: " .. currentTime,
            Color = Color3.fromHex("#ff6a30")
        })
    end
end)

Tabs.Misc:Code({
    Title = "感谢游玩",
    Code = "QQ号:3395858053"
})