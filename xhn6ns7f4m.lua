local success, err = pcall(function()
--这下面填加载外部脚本

-- ========== 汉化引擎开始 ==========
local TRANSLATIONS_PATH = "外部汉化/汉化表.lua"

-- 确保文件夹存在
local function ensureFolderExists()
    local folderPath = "外部汉化"
    if not isfolder(folderPath) then
        makefolder(folderPath)
    end
end

-- 创建默认汉化表文件（如果不存在）
local function createDefaultTranslationsFile()
    if not isfile(TRANSLATIONS_PATH) then
        local defaultContent = [[
return {
    ["Hello"] = "你好",
    ["Play"] = "开始游戏",
    ["Settings"] = "设置",
    ["Apple Tree"] = "苹果树",
    ["Click me!"] = "点击我！",
    ["Welcome to the test UI"] = "欢迎来到测试界面",
    ["This is a text label"] = "这是一个文本标签",
    ["Enter text here"] = "在这里输入文字"
}
]]
        writefile(TRANSLATIONS_PATH, defaultContent)
    end
end

-- 加载外部汉化表并标准化
local function loadExternalTranslations()
    if isfile(TRANSLATIONS_PATH) then
        local success, result = pcall(function()
            return loadstring(readfile(TRANSLATIONS_PATH))()
        end)
        if success and type(result) == "table" then
            local normalizedTranslations = {}
            for en, cn in pairs(result) do
                if type(en) == "string" and type(cn) == "string" then
                    local normalizedKey = en:lower()
                    if not normalizedTranslations[normalizedKey] then
                        normalizedTranslations[normalizedKey] = {
                            original = en,
                            translation = cn
                        }
                    end
                end
            end
            return normalizedTranslations
        else
            warn("加载外部汉化表失败:", result)
        end
    else
        warn("汉化表文件不存在:", TRANSLATIONS_PATH)
    end
    return {}
end

-- 初始化汉化表
ensureFolderExists()
createDefaultTranslationsFile()
local NormalizedTranslations = loadExternalTranslations()

-- 创建不区分大小写且忽略空格的汉化表副本
local AdvancedTranslations = {}
for normalizedKey, data in pairs(NormalizedTranslations) do
    local en = data.original
    local cn = data.translation
    local advancedKey = en:gsub("%s+", ""):lower()
    AdvancedTranslations[advancedKey] = {
        original = en,
        translation = cn,
        pattern = advancedKey:gsub("(%W)", "%%%1")
    }
end

local function translateText(text)
    if not text or type(text) ~= "string" then return text end
    
    local lowerText = text:lower()
    local normalizedText = text:gsub("%s+", ""):lower()
    
    if AdvancedTranslations[normalizedText] then
        return AdvancedTranslations[normalizedText].translation
    end
    
    local translated = text
    local replacedPositions = {}
    
    for advancedKey, data in pairs(AdvancedTranslations) do
        local pattern = data.pattern
        local cn = data.translation
        
        local startPos = 1
        while true do
            local matchStart, matchEnd = normalizedText:find(pattern, startPos)
            if not matchStart then break end
            
            local alreadyReplaced = false
            for _, pos in ipairs(replacedPositions) do
                if matchStart >= pos.start and matchStart <= pos.finish then
                    alreadyReplaced = true
                    break
                end
            end
            
            if not alreadyReplaced then
                local originalStart = 1
                local normalizedIndex = 1
                
                for i = 1, #text do
                    if normalizedIndex == matchStart then
                        originalStart = i
                        break
                    end
                    if text:sub(i, i):match("%S") then
                        normalizedIndex = normalizedIndex + 1
                    end
                end
                
                local originalEnd = originalStart
                local charsNeeded = matchEnd - matchStart + 1
                local charsFound = 0
                
                for i = originalStart, #text do
                    if charsFound >= charsNeeded then break end
                    if text:sub(i, i):match("%S") then
                        charsFound = charsFound + 1
                    end
                    originalEnd = i
                end
                
                local before = translated:sub(1, originalStart - 1)
                local after = translated:sub(originalEnd + 1)
                translated = before .. cn .. after
                
                table.insert(replacedPositions, {
                    start = matchStart,
                    finish = matchEnd
                })
                
                normalizedText = translated:gsub("%s+", ""):lower()
            end
            
            startPos = matchEnd + 1
        end
    end
    
    return translated
end

local function setupTranslationEngine()
    local success, err = pcall(function()
        local oldIndex = getrawmetatable(game).__newindex
        setreadonly(getrawmetatable(game), false)
        
        getrawmetatable(game).__newindex = newcclosure(function(t, k, v)
            if (t:IsA("TextLabel") or t:IsA("TextButton") or t:IsA("TextBox")) and k == "Text" then
                v = translateText(tostring(v))
            end
            return oldIndex(t, k, v)
        end)
        
        setreadonly(getrawmetatable(game), true)
    end)
    
    if not success then
        warn("元表劫持失败:", err)
       
        local translated = {}
        local function scanAndTranslate()
            for _, gui in ipairs(game:GetService("CoreGui"):GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox")) and not translated[gui] then
                    pcall(function()
                        local text = gui.Text
                        if text and text ~= "" then
                            local translatedText = translateText(text)
                            if translatedText ~= text then
                                gui.Text = translatedText
                                translated[gui] = true
                            end
                        end
                    end)
                end
            end
            
            local player = game:GetService("Players").LocalPlayer
            if player and player:FindFirstChild("PlayerGui") then
                for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
                    if (gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox")) and not translated[gui] then
                        pcall(function()
                            local text = gui.Text
                            if text and text ~= "" then
                                local translatedText = translateText(text)
                                if translatedText ~= text then
                                    gui.Text = translatedText
                                    translated[gui] = true
                                end
                            end
                        end)
                    end
                end
            end
        end
        
        local function setupDescendantListener(parent)
            parent.DescendantAdded:Connect(function(descendant)
                if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                    task.wait(0.1)
                    pcall(function()
                        local text = descendant.Text
                        if text and text ~= "" then
                            local translatedText = translateText(text)
                            if translatedText ~= text then
                                descendant.Text = translatedText
                            end
                        end
                    end)
                end
            end)
        end
        
        pcall(setupDescendantListener, game:GetService("CoreGui"))
        local player = game:GetService("Players").LocalPlayer
        if player and player:FindFirstChild("PlayerGui") then
            pcall(setupDescendantListener, player.PlayerGui)
        end
        
        while true do
            scanAndTranslate()
            task.wait(3)
        end
    end
end

-- 启动汉化引擎
task.wait(1)
setupTranslationEngine()
warn("汉化引擎已启动")
-- ========== 汉化引擎结束 ==========

-- 创建汉化UI
local function createTranslationUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TranslationUI"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- 折叠/展开按钮（可拖动）
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 120, 0, 30)
    ToggleButton.Position = UDim2.new(0, 20, 0, 20)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    ToggleButton.Text = "打开脚本输入"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 12
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.ZIndex = 2
    ToggleButton.Parent = ScreenGui
    
    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 6)
    ButtonCorner.Parent = ToggleButton
    
    -- 主框架（初始隐藏）
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 350, 0, 280)
    MainFrame.Position = UDim2.new(0, 150, 0, 20)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.ZIndex = 2
    MainFrame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame
    
    -- 标题栏
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.Position = UDim2.new(0, 0, 0, 0)
    TitleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TitleBar.ZIndex = 3
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "脚本输入器 (已汉化)"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 4
    TitleLabel.Parent = TitleBar
    
    -- 关闭按钮
    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 60, 0, 20)
    CloseButton.Position = UDim2.new(1, -65, 0.5, -10)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    CloseButton.Text = "关闭"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 10
    CloseButton.Font = Enum.Font.Gotham
    CloseButton.ZIndex = 4
    CloseButton.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseButton
    
    -- 脚本输入框
    local ScriptInput = Instance.new("TextBox")
    ScriptInput.Name = "ScriptInput"
    ScriptInput.Size = UDim2.new(0.9, 0, 0, 140)
    ScriptInput.Position = UDim2.new(0.05, 0, 0, 45)
    ScriptInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ScriptInput.Text = "-- 在这里输入创建UI的脚本\n-- 例如：创建按钮、标签等\n-- 文本会自动汉化"
    ScriptInput.TextColor3 = Color3.fromRGB(200, 200, 200)
    ScriptInput.TextSize = 11
    ScriptInput.Font = Enum.Font.Code
    ScriptInput.TextWrapped = true
    ScriptInput.TextXAlignment = Enum.TextXAlignment.Left
    ScriptInput.TextYAlignment = Enum.TextYAlignment.Top
    ScriptInput.ClearTextOnFocus = false
    ScriptInput.MultiLine = true
    ScriptInput.ZIndex = 2
    ScriptInput.Parent = MainFrame
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = ScriptInput
    
    -- 按钮容器
    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Name = "ButtonContainer"
    ButtonContainer.Size = UDim2.new(0.9, 0, 0, 30)
    ButtonContainer.Position = UDim2.new(0.05, 0, 0, 200)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.ZIndex = 2
    ButtonContainer.Parent = MainFrame
    
    -- 执行按钮
    local ExecuteButton = Instance.new("TextButton")
    ExecuteButton.Name = "ExecuteButton"
    ExecuteButton.Size = UDim2.new(0.48, 0, 1, 0)
    ExecuteButton.Position = UDim2.new(0, 0, 0, 0)
    ExecuteButton.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
    ExecuteButton.Text = "执行脚本"
    ExecuteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExecuteButton.TextSize = 12
    ExecuteButton.Font = Enum.Font.GothamBold
    ExecuteButton.ZIndex = 3
    ExecuteButton.Parent = ButtonContainer
    
    local ExecuteCorner = Instance.new("UICorner")
    ExecuteCorner.CornerRadius = UDim.new(0, 6)
    ExecuteCorner.Parent = ExecuteButton
    
    -- 清空按钮
    local ClearButton = Instance.new("TextButton")
    ClearButton.Name = "ClearButton"
    ClearButton.Size = UDim2.new(0.48, 0, 1, 0)
    ClearButton.Position = UDim2.new(0.52, 0, 0, 0)
    ClearButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    ClearButton.Text = "清空"
    ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearButton.TextSize = 12
    ClearButton.Font = Enum.Font.Gotham
    ClearButton.ZIndex = 3
    ClearButton.Parent = ButtonContainer
    
    local ClearCorner = Instance.new("UICorner")
    ClearCorner.CornerRadius = UDim.new(0, 6)
    ClearCorner.Parent = ClearButton
    
    -- 状态显示
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(0.9, 0, 0, 25)
    StatusLabel.Position = UDim2.new(0.05, 0, 0, 240)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "就绪 - 创建的UI会自动汉化"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.TextSize = 11
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.ZIndex = 2
    StatusLabel.Parent = MainFrame
    
    -- 折叠/展开状态
    local isExpanded = false
    
    -- 折叠/展开功能
    local function toggleUI()
        isExpanded = not isExpanded
        MainFrame.Visible = isExpanded
        if isExpanded then
            ToggleButton.Text = "隐藏输入框"
        else
            ToggleButton.Text = "打开脚本输入"
        end
    end
    
    -- 直接绑定点击事件
    ToggleButton.MouseButton1Click:Connect(function()
        toggleUI()
    end)
    
    CloseButton.MouseButton1Click:Connect(function()
        isExpanded = false
        MainFrame.Visible = false
        ToggleButton.Text = "打开脚本输入"
    end)
    
    -- 清空按钮功能
    ClearButton.MouseButton1Click:Connect(function()
        ScriptInput.Text = ""
        StatusLabel.Text = "已清空输入框"
        StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end)
    
    -- 执行按钮功能
    ExecuteButton.MouseButton1Click:Connect(function()
        local scriptText = ScriptInput.Text
        if scriptText and scriptText ~= "" and scriptText ~= "-- 在这里输入创建UI的脚本\n-- 例如：创建按钮、标签等\n-- 文本会自动汉化" then
            StatusLabel.Text = "执行中..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            
            local executeSuccess, executeError = pcall(function()
                loadstring(scriptText)()
            end)
            
            if executeSuccess then
                StatusLabel.Text = "执行成功 - UI已自动汉化"
                StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 0)
            else
                StatusLabel.Text = "执行错误: " .. tostring(executeError)
                StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
                warn("脚本执行错误:", executeError)
            end
        else
            StatusLabel.Text = "请输入脚本内容"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 0)
        end
    end)
    
    -- 输入框获得焦点时清空默认文本
    ScriptInput.Focused:Connect(function()
        if ScriptInput.Text == "-- 在这里输入创建UI的脚本\n-- 例如：创建按钮、标签等\n-- 文本会自动汉化" then
            ScriptInput.Text = ""
            ScriptInput.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end)
    
    -- 输入框失去焦点时恢复默认文本（如果为空）
    ScriptInput.FocusLost:Connect(function()
        if ScriptInput.Text == "" then
            ScriptInput.Text = "-- 在这里输入创建UI的脚本\n-- 例如：创建按钮、标签等\n-- 文本会自动汉化"
            ScriptInput.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
    
    -- 主窗口拖动功能
    local mainDragging = false
    local mainDragStart
    local mainStartPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mainDragging = true
            mainDragStart = input.Position
            mainStartPos = MainFrame.Position
            
            -- 视觉反馈
            TitleBar.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    mainDragging = false
                    TitleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    TitleBar.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and mainDragging then
            local delta = input.Position - mainDragStart
            MainFrame.Position = UDim2.new(
                mainStartPos.X.Scale,
                mainStartPos.X.Offset + delta.X,
                mainStartPos.Y.Scale, 
                mainStartPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- ========== 完全重写的折叠按钮拖动功能 ==========
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    -- 更新位置函数
    local function update(input)
        local delta = input.Position - dragStart
        ToggleButton.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
    
    -- 触摸/鼠标按下
    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ToggleButton.Position
            
            -- 视觉反馈
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            
            -- 捕获输入变化
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    -- 记录拖动输入
    ToggleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    -- 实时更新位置（使用UserInputService确保流畅）
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
    
    -- 确保点击事件正常工作（使用防抖）
    local lastClickTime = 0
    local clickDebounce = 0.3 -- 300毫秒防抖
    
    ToggleButton.MouseButton1Click:Connect(function()
        local currentTime = tick()
        if currentTime - lastClickTime > clickDebounce then
            lastClickTime = currentTime
            toggleUI()
        end
    end)
    
    return ScreenGui
end

-- 创建UI
createTranslationUI()

warn("汉化UI已创建完成 - 点击和拖动功能都已修复")

end)

if not success then
    warn("加载失败:", err)
end