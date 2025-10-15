-- GUI contents
AnimButtons = {
78195344190486, "狗狗模式", 
 115417853064013, "直升机模式", 
 85588129788692, "Hit the Griddy", 
 79757971761739, "破碎", 
 83265734904502, "认输", 
 129764254213842, "江南Style", 
 114400428765989, "180°翻转", 
 128334204821841, "马桶", 
 138433137191760, "我独为至尊", 
 110146282544198, "橙色正义", 
 10714340543, "牙线舞", 
 77984841414450, "Deltarune舞蹈", 
 109873544976020, "龙圈风摧毁停车场😡", 
 90333292347820, "蠕虫舞", 
 88130117312312, "假死", 
 111251252458517, "呃呃呃",
 84623954062978, "彼得不要", 
 124756446017361, "我变成敞篷车了", 
 93014787120483, "Garry的舞蹈", 
 92618727772186, "艹人", 
 99499783161907, "光环农场",
 80177289449617, "雪天使", 
 70432904702322, "被剥皮行者附身", 
 123916423751437, "老鼠舞蹈", 
 129537633250603, "花生酱时间", 
 99158928535706, "默认舞蹈", 
 94915612757079, "坦克模式",
 130059214239749, "撒尿的狗", 
 91047682123297, "玛卡雷娜", 
 130019914905925, "严肃的Omni-Man", 
 133612047483255, "翻滚", 
 79075971527754, "你知道这意味着什么…",
 99637983789946, "这是恐怖的月份!!",
 82135680487389, "飞机", 
 88971195093161, "怪物混搭", 
 118592095684994, "无人机", 
 95894948496521, "PVZ向日葵", 
 137969542385356, "鱼", 
 132399051509976, "拉屎", 
 122583653807009, "足球杂耍",
 107355541549056, "工程师舞蹈", 
 126960077574956, "小鸡舞蹈", 
 78347793265211, "他正在掏几把!", 
 122770336163563, "加州女孩", 
 97148848007002, "俄罗斯舞蹈", 
 114687548971893, "爬行者模式",
 106389948045296, "灭霸舞蹈", 
 108313130500811, "俯卧撑", 
 106022089542174, "云端漂浮", 
 114140630538674, "椅子模式2", 
 108865839239307, "AI猫舞蹈", 
 84352128203419, "蔬菜舞蹈", 
 82293338535013, "DJ Khaled",
	}

-- General Variables
CursedMode = false
Player = game.Players.LocalPlayer
Mouse = Player:GetMouse()
HeaderSize = 25
PlayingId = 0
Red = Color3.new(0.9, 0, 0)
Green = Color3.new(0.26, 0.85, 0)
Grey = Color3.new(0.6, 0.6, 0.6)
Blue = Color3.new(0.26, 0.53, 0.95)
Yellow = Color3.new(0.95, 0.85, 0.26)

-- 界面折叠状态
local IsCollapsed = false

-- 存储动画数据的文件名
local STORAGE_FILE_NAME = "动画表.lua"

-- 存储和读取动画数据的功能
function SaveStolenAnimations()
	local animationLines = {}
	
	for _, button in StolenAnimationsFrame:GetChildren() do
		if button:IsA("TextButton") and button.Name ~= "StealButtonButton" and button.Name ~= "StealSelfButtonButton" then
			local animId = button:GetAttribute("AnimId")
			local animName = button.Text
			-- 提取纯数字ID（去掉rbxassetid://前缀）
			local cleanId = animId:gsub("rbxassetid://", "")
			table.insert(animationLines, cleanId .. ', "' .. animName .. '"')
		end
	end
	
	if #animationLines > 0 then
		local fileContent = table.concat(animationLines, ",\n")
		if writefile then
			writefile(STORAGE_FILE_NAME, fileContent)
			print("已保存 " .. #animationLines .. " 个复制的动画")
		else
			warn("writefile函数不可用，无法保存动画数据")
		end
	else
		print("没有动画可保存")
	end
end

function LoadStolenAnimations()
	if readfile and isfile and isfile(STORAGE_FILE_NAME) then
		local success, result = pcall(function()
			local fileContent = readfile(STORAGE_FILE_NAME)
			-- 清理内容，移除可能的空行和多余空格
			fileContent = fileContent:gsub("\r\n", "\n"):gsub("^\n+", ""):gsub("\n+$", "")
			
			-- 按行分割
			local lines = {}
			for line in fileContent:gmatch("[^\n]+") do
				line = line:gsub("^%s+", ""):gsub("%s+$", ""):gsub(",$", "")  -- 去除前后空格和行尾逗号
				if line ~= "" then
					table.insert(lines, line)
				end
			end
			
			local loadedCount = 0
			for _, line in ipairs(lines) do
				-- 匹配格式：数字, "名称"
				local id, name = line:match('^(%d+),%s*"([^"]*)"')
				if id and name then
					local fullId = "rbxassetid://" .. id
					if not CheckForOwnedAnimations(fullId, false) then
						CreateTextbox(UDim2.new(0.45,0,0,35), Grey, 0, name, id, StolenAnimationsFrame)
						CreateButton(UDim2.new(0.45,0,0,35), Green, name, name, fullId, StolenAnimationsFrame, TextBoxRn, false)
						loadedCount = loadedCount + 1
					end
				else
					-- 尝试匹配其他可能的格式
					id, name = line:match('^(%d+),%s*(.+)')
					if id and name then
						-- 如果名称没有引号，去除可能的逗号
						name = name:gsub(",.*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
						local fullId = "rbxassetid://" .. id
						if not CheckForOwnedAnimations(fullId, false) then
							CreateTextbox(UDim2.new(0.45,0,0,35), Grey, 0, name, id, StolenAnimationsFrame)
							CreateButton(UDim2.new(0.45,0,0,35), Green, name, name, fullId, StolenAnimationsFrame, TextBoxRn, false)
							loadedCount = loadedCount + 1
						end
					end
				end
			end
			
			print("已加载 " .. loadedCount .. " 个复制的动画")
		end)
		
		if not success then
			warn("加载动画数据失败: " .. tostring(result))
		end
	else
		print("没有找到保存的动画数据或文件函数不可用")
	end
end

-- Setting up the GUI
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MyAnimationHub"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

function CreateFrame(Name)
	local Frame = Instance.new("ScrollingFrame")
	Frame.Visible = false
	-- 缩小窗口尺寸
	Frame.Size = UDim2.new(0,180,0,250)
	Frame.BackgroundColor3 = Color3.new(0.286168, 0.286168, 0.286168)
	Frame.CanvasSize = UDim2.new(0,0,0,0)
	Frame.Name = Name
	Frame.Parent = ScreenGui
	Instance.new("UICorner", Frame)
	return Frame
end

AnimationsFrame = CreateFrame("AnimationsTabFrame")
AnimationsFrame.Visible = true
StolenAnimationsFrame = CreateFrame("StolenAnimationsTabFrame")

TabsFrame = Instance.new("Frame")
-- 调整标签页框架大小
TabsFrame.Size = UDim2.new(0,15,0,250)
TabsFrame.BackgroundTransparency = 1
TabsFrame.Position = UDim2.new(0, 180,0, 0)
TabsFrame.Parent = ScreenGui

RenameBox = Instance.new("TextBox",ScreenGui)
RenameBox.Size = UDim2.new(0.3,0,0.15,0)
RenameBox.BackgroundColor3 = Color3.new(0.286168, 0.286168, 0.286168)
RenameBox.PlaceholderText = "输入新名称"
RenameBox.AnchorPoint = Vector2.new(0.5,0.5)
RenameBox.Position = UDim2.new(0.5,0,0.5,0)
RenameBox.Text = ""
RenameBox.TextScaled = true
RenameBox.RichText = true
RenameBox.Visible = false

DragBar = Instance.new("TextButton")
DragBar.Text = ""
DragBar.AutoButtonColor = false
DragBar.Position = UDim2.new(0,AnimationsFrame.AbsolutePosition.X-7.5,0, AnimationsFrame.AbsolutePosition.Y)
-- 调整拖拽条大小
DragBar.Size = UDim2.new(0,195,0,20)
DragBar.BackgroundColor3 = Color3.new(0.133272, 0.133272, 0.133272)
Instance.new("UICorner").Parent = DragBar
DragBar.Position -= UDim2.new(0,0,0,20)
DragBar.Parent = ScreenGui

CloseButton = Instance.new("TextButton")
CloseButton.Text = "关闭"
CloseButton.Position = UDim2.new(0,AnimationsFrame.AbsolutePosition.X-7.5,0, AnimationsFrame.AbsolutePosition.Y)
-- 调整关闭按钮大小
CloseButton.Size = UDim2.new(0,20,0,20)
CloseButton.BackgroundColor3 = Red
CloseButton.TextScaled = true
Instance.new("UICorner",CloseButton)
CloseButton.Position -= UDim2.new(0,0,0,20)
CloseButton.Parent = ScreenGui

-- 修改折叠按钮为界面折叠功能
CollapseAllButton = Instance.new("TextButton")
CollapseAllButton.Text = "◎"
CollapseAllButton.Position = UDim2.new(0,AnimationsFrame.AbsolutePosition.X-7.5,0, AnimationsFrame.AbsolutePosition.Y)
-- 调整折叠按钮大小
CollapseAllButton.Size = UDim2.new(0,30,0,20)
CollapseAllButton.BackgroundColor3 = Yellow
CollapseAllButton.TextScaled = true
Instance.new("UICorner",CollapseAllButton)
CollapseAllButton.Position = CloseButton.Position + UDim2.new(0,25,0,0)
CollapseAllButton.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Position = UDim2.new(0,0,0,-100)
-- 调整标题大小
Title.Size = UDim2.new(0,180,0,40)
Title.Name = "Title"
Title.BorderSizePixel = 0
Title.BackgroundTransparency = 1
Title.TextScaled = true
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Text = "动画中心 - R15专用"
Instance.new("UIStroke").Parent = Title
Title.Position = UDim2.new(0,AnimationsFrame.AbsolutePosition.X,0, AnimationsFrame.AbsolutePosition.Y - Title.Size.Y.Offset*1.2)
Title.Parent = ScreenGui

-- Create anim instance
Anim = Instance.new("Animation", script)

-- General functions
function Layout(Frame)
	local Layout = Instance.new("UIListLayout", Frame)
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.Wraps = true
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
end

function NiceButtons(Button)
	Instance.new("UICorner").Parent = Button
	local Grad = Instance.new("UIGradient")
	Grad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
		ColorSequenceKeypoint.new(1, Color3.new(0.7,0.7,0.7)),
	}
	Grad.Parent = Button
end

function CreateInteractable(Size, Name, Text, Color, X, Button, Class, Tab)
	local Element = Instance.new(Class,Tab)
	if Button then
		Element.Name = Name.. "Button"
	else
		Element.Name = Name.. "Box"
	end
	if Button then
		Element.Text = Text
	else
		Element.Text = ""
		Element.PlaceholderText = Text
	end
	Element.Size = Size
	Element.TextScaled = true
	Element.RichText = true
	Element.BackgroundColor3 = Color
	NiceButtons(Element)
	return Element
end

function MassUnToggle(Button)
	for Num, Frame in ScreenGui:GetChildren() do
		if Frame:IsA("ScrollingFrame") then
			for Num, Butn in Frame:GetChildren() do
				if Butn:IsA("TextButton") and Butn ~= Button then
					Butn:SetAttribute("Toggled", false)
					Butn.BackgroundColor3 = Red
				end
			end
		end
	end
end

function CreateButton(Size,Color,Text, Name,ID, Frame, ConnectingBox, Toggled)
	local Button = CreateInteractable(Size, Name, Text, Color, 100, true, "TextButton", Frame)
	Button:SetAttribute("Toggled", Toggled)
	Button:SetAttribute("AnimId", ID)
	Frame.CanvasSize += UDim2.new(0,0,0,Size.Y.Offset)
	Button.MouseButton1Click:Connect(function()
		Button:SetAttribute("Toggled", not Button:GetAttribute("Toggled"))
		if Track and not CursedMode then
			Track:Stop()
		end
		if Button:GetAttribute("Toggled") then
			MassUnToggle(Button)
			PlayingId = ID
			Button.BackgroundColor3 = Green
			PlayAnimation(ID, ConnectingBox.Text)
		else
			Button.BackgroundColor3 = Red
			PlayingId = 0
		end
	end)
	Button.MouseButton2Click:Connect(function()
		RenameBox.Text = ""
		RenameBox.Visible = true
		RenameBox:CaptureFocus()
		local function Rename()
			Button.Text = RenameBox.Text
			RenameBox.Visible = false
			Rename:Disconnect()
		end
		Rename = RenameBox.FocusLost:Connect(Rename)
	end)
	if Button.Parent == StolenAnimationsFrame then
		Button.MouseEnter:Connect(function()
			HoveringButton = Button
			HoveringBox = ConnectingBox
		end)
		Button.MouseLeave:Connect(function()
			HoveringButton = nil
			HoveringBox = ConnectingBox
		end)
	end
end

function TextboxSpeedAdjust(Box,ID)
	Box.FocusLost:Connect(function()
		if not (PlayingId == ID or PlayingId == 0 or PlayingId == StealId) and not CursedMode then return end
		if tonumber(Box.Text) == nil then
			if Track then
				Track:AdjustSpeed(1)
			end
		else
			if Track then
				Track:AdjustSpeed(tonumber(Box.Text))
			end
		end
	end)
end

function CreateTextbox(Size,Color,X,Name,ID, Frame)
	local Box = CreateInteractable(Size, Name, "速度(默认1)", Color, 0, false, "TextBox", Frame)
	TextBoxRn = Box
	TextboxSpeedAdjust(Box,"rbxassetid://"..ID)
end

function CreateTab(Size, Name, Text, Frame)
	local Tab = CreateInteractable(Size, Name, Text, Grey, 0, true, "TextButton", TabsFrame)
	if Text == "动画" then
		Tab.BackgroundColor3 = Green
	end
	Tab.MouseButton1Click:Connect(function()
		for Num, Tab in TabsFrame:GetChildren() do
			if Tab:IsA("TextButton") then
				Tab.BackgroundColor3 = Grey
			end
		end
		Tab.BackgroundColor3 = Green
		for Num, Frame in ScreenGui:GetChildren() do
			if Frame:IsA("ScrollingFrame") then
				Frame.Visible = false
			end
		end
		Frame.Visible = true
	end)
end

function PlayAnimation(ID,Speed)
	local Character = game.Players.LocalPlayer.Character
	if not Character or not Character:FindFirstChild("Humanoid") then
		return
	end
	
	Anim.AnimationId = ID
	Track = Character:WaitForChild("Humanoid"):LoadAnimation(Anim)
	Track:Play()
	Track.Looped = true
	
	if tonumber(Speed) == nil then
		Track:AdjustSpeed(1)
	else
		Track:AdjustSpeed(Speed)
	end
	Track.Priority = Enum.AnimationPriority.Action
end

function CreateSearchbar(Frame)
	-- Search bar
	local Searchbar = CreateInteractable(UDim2.new(0.95,0,0,35), "Searchbar", "搜索", Grey, 0, false, "TextBox", Frame)
	Frame.CanvasSize += UDim2.new(0,0,0,Searchbar.Size.Y.Offset)
	-- Search bar functionality
	Searchbar.Changed:Connect(function()
		local Search = string.lower(Searchbar.Text)
		for _, Button in Frame:GetChildren() do
			if (Button:IsA("TextButton") or Button:IsA("TextBox")) and Button.Name ~= "SearchbarBox" then
				if string.find(string.lower(Button.Name), Search) or string.find(string.lower(Button.Text), Search) then
					Button.Visible = true
				else
					Button.Visible = false
				end
			end
		end
	end)
end

function CFOAMeat(ID)
	if Track then
		Track:Stop()
	end
	PlayAnimation(ID,1)
	MassUnToggle(nil)
	StealStage = 0
	PlayingId = "Steal"
	StealId = ID
	if StealButton then
		StealButton.BackgroundColor3 = Red
	end
end

function CheckForOwnedAnimations(ID, PlayIt)
	for Num, Frame in ScreenGui:GetChildren() do
		if Frame:IsA("ScrollingFrame") then
			for Num, Button in StolenAnimationsFrame:GetChildren() do
				if Button:IsA("TextButton") and Button:GetAttribute("AnimId") == ID then
					if PlayIt then
						CFOAMeat(ID)
						Button:SetAttribute("Toggled", true)
						Button.BackgroundColor3 = Green
						return true
					else
						return true
					end
				end
			end
		end
	end
	if PlayIt then
		CFOAMeat(ID)
	end
	return false
end

-- 界面折叠功能
function ToggleUICollapse()
	IsCollapsed = not IsCollapsed
	
	if IsCollapsed then
		-- 折叠界面：隐藏主要内容，只显示标题栏
		AnimationsFrame.Visible = false
		StolenAnimationsFrame.Visible = false
		TabsFrame.Visible = false
		Title.Visible = true
		DragBar.Visible = true
		CloseButton.Visible = true
		CollapseAllButton.Text = "⊙"
		CollapseAllButton.BackgroundColor3 = Green
		
		-- 调整标题位置
		Title.Position = UDim2.new(0,AnimationsFrame.AbsolutePosition.X,0, AnimationsFrame.AbsolutePosition.Y - 20)
	else
		-- 展开界面：显示所有内容
		AnimationsFrame.Visible = true
		TabsFrame.Visible = true
		Title.Visible = true
		DragBar.Visible = true
		CloseButton.Visible = true
		CollapseAllButton.Text = "◎"
		CollapseAllButton.BackgroundColor3 = Yellow
		
		-- 恢复标题位置
		Title.Position = UDim2.new(0,AnimationsFrame.AbsolutePosition.X,0, AnimationsFrame.AbsolutePosition.Y - Title.Size.Y.Offset*1.2)
		
		-- 确保正确的标签页显示
		for Num, Tab in TabsFrame:GetChildren() do
			if Tab:IsA("TextButton") and Tab.BackgroundColor3 == Green then
				local tabName = Tab.Text
				if tabName == "动画" then
					StolenAnimationsFrame.Visible = false
					AnimationsFrame.Visible = true
				elseif tabName == "复制动画" then
					AnimationsFrame.Visible = false
					StolenAnimationsFrame.Visible = true
				end
			end
		end
	end
end

-- Give layouts
Layout(AnimationsFrame)
Layout(StolenAnimationsFrame)
Layout(TabsFrame)

-- Create tabs
NumOfTabs = 2
CreateTab(UDim2.new(0,15,0,250/NumOfTabs), "AnimationsTab", "动画", AnimationsFrame)
CreateTab(UDim2.new(0,15,0,250/NumOfTabs), "StolenAnimationsTab", "复制动画", StolenAnimationsFrame)

-- Give search bars
CreateSearchbar(AnimationsFrame)
CreateSearchbar(StolenAnimationsFrame)

-- Drag bar functionality
DragBar.MouseButton1Down:Connect(function()
	local Offset = game.Players.LocalPlayer:GetMouse().X - AnimationsFrame.AbsolutePosition.X
	while game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
		task.wait(0.01)
		local mouse = game.Players.LocalPlayer:GetMouse()
		AnimationsFrame.Position = UDim2.new(0, mouse.X - Offset, 0, mouse.Y)
		StolenAnimationsFrame.Position = AnimationsFrame.Position
		Title.Position = UDim2.new(0,AnimationsFrame.AbsolutePosition.X,0, AnimationsFrame.AbsolutePosition.Y - (IsCollapsed and 20 or Title.Size.Y.Offset*1.2))
		TabsFrame.Position = AnimationsFrame.Position + UDim2.new(0, 180,0, 0)
		DragBar.Position = UDim2.new(0,AnimationsFrame.AbsolutePosition.X-7.5,0, AnimationsFrame.AbsolutePosition.Y-HeaderSize)
		CloseButton.Position = UDim2.new(0,AnimationsFrame.AbsolutePosition.X-7.5,0, AnimationsFrame.AbsolutePosition.Y-HeaderSize)
		CollapseAllButton.Position = CloseButton.Position + UDim2.new(0,25,0,0)
	end
end)

--Close button functionality
CloseButton.MouseButton1Click:Connect(function()
	-- 关闭前保存动画数据
	SaveStolenAnimations()
	ScreenGui:Destroy()
	script:Destroy()
end)

-- 折叠按钮功能 - 切换界面折叠状态
CollapseAllButton.MouseButton1Click:Connect(ToggleUICollapse)

-- Steal buttons frame (创建一个框架来容纳两个复制按钮)
StealButtonsFrame = Instance.new("Frame")
StealButtonsFrame.Size = UDim2.new(0.95, 0, 0, 75)
StealButtonsFrame.BackgroundTransparency = 1
StealButtonsFrame.Parent = StolenAnimationsFrame
StolenAnimationsFrame.CanvasSize += UDim2.new(0,0,0,StealButtonsFrame.Size.Y.Offset)

-- Steal button (复制其他玩家动画)
StealId = 0
StealButton = CreateInteractable(UDim2.new(0.48,0,0,35), "StealButton", "复制其他玩家", Red, 100, true, "TextButton", StealButtonsFrame)
StealButton.Position = UDim2.new(0, 0, 0, 0)

-- Steal self button (复制自身动画)
StealSelfButton = CreateInteractable(UDim2.new(0.48,0,0,35), "StealSelfButton", "复制自身动画", Blue, 100, true, "TextButton", StealButtonsFrame)
StealSelfButton.Position = UDim2.new(0.52, 0, 0, 0)

-- Steal button functionality (复制其他玩家动画)
StealStage = 0
StealButton.MouseButton1Click:Connect(function()
	if StealStage == 0 then
		StealStage = 1
		StealButton.BackgroundColor3 = Blue
		local Highlight = Instance.new("Highlight",workspace.Terrain)
		Highlight.FillColor = Blue
		while StealStage == 1 do
			task.wait(0.01)
			if Mouse.Target and Mouse.Target:FindFirstAncestorWhichIsA("Model") and Mouse.Target:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid") then
				Highlight.Adornee = Mouse.Target:FindFirstAncestorWhichIsA("Model")
			else
				Highlight.Adornee = nil
			end
		end
		Highlight:Destroy()
	elseif StealStage == 1 then
		StealStage = 0
		StealButton.BackgroundColor3 = Red
	end
end)

-- Steal self button functionality (复制自身动画)
StealSelfButton.MouseButton1Click:Connect(function()
    local Character = Player.Character
    if not Character or not Character:FindFirstChild("Humanoid") then
        warn("无法找到玩家角色或Humanoid")
        return
    end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    local playingTracks = Humanoid:GetPlayingAnimationTracks()
    
    if #playingTracks == 0 then
        warn("当前没有播放任何动画")
        return
    end
    
    -- 获取第一个正在播放的动画
    local track = playingTracks[1]
    local animId = track.Animation.AnimationId
    
    if not animId or animId == "" then
        warn("未找到有效的动画ID")
        return
    end
    
    print("复制自身动画ID: " .. animId)
    
    -- 检查是否已经拥有这个动画
    if not CheckForOwnedAnimations(animId, true) then
        local animIdNumber = animId:match("%d+")
        local animName = "自身动画"
        
        if animIdNumber then
            local success, info = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(tonumber(animIdNumber))
            end)
            if success then
                animName = info.Name
            else
                -- 如果无法获取名称，使用时间戳创建唯一名称
                animName = "自身动画_" .. os.time()
            end
        else
            warn("未找到有效的动画ID数字")
            animName = "自身动画_" .. os.time()
        end
        
        -- 创建文本框和按钮
        CreateTextbox(UDim2.new(0.45,0,0,35), Grey, 0, animName, animIdNumber, StolenAnimationsFrame)
        CreateButton(UDim2.new(0.45,0,0,35), Green, animName, animName, animId, StolenAnimationsFrame, TextBoxRn, false)
        
        -- 保存新动画
        SaveStolenAnimations()
        
        print("成功复制自身动画: " .. animName)
    else
        print("已经拥有此动画")
    end
end)

-- Emergency stop button
EStopButton = CreateInteractable(UDim2.new(0.95,0,0,35), "EStopButton", "停止", Grey, 100, true, "TextButton", AnimationsFrame)
AnimationsFrame.CanvasSize += UDim2.new(0,0,0,StealButton.Size.Y.Offset)

-- Emergency stop button functionality
EStopButton.MouseButton1Click:Connect(function()
	if Player.Character and Player.Character:FindFirstChild("Humanoid") then
		for Num, LocalTrack in Player.Character:WaitForChild("Humanoid"):GetPlayingAnimationTracks() do
			LocalTrack:Stop()
		end
	end
end)

game:GetService("UserInputService").InputBegan:Connect(function(Input)
	if (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and StealStage == 1 then
		local Target = Mouse.Target
		if Target and Mouse.Target:FindFirstAncestorWhichIsA("Model") and Mouse.Target:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid") then
			local Humanoid = Mouse.Target:FindFirstAncestorWhichIsA("Model"):FindFirstChildOfClass("Humanoid")
			for Num, TheirTrack in Humanoid:GetPlayingAnimationTracks() do
				local ID = TheirTrack.Animation.AnimationId
				if TheirTrack.Length ~= 0 and not CheckForOwnedAnimations(ID, true) then
					print("复制动画ID: " .. ID)
					StealStage = 0
					PlayingId = "Steal"
					StealId = ID
					StealButton.BackgroundColor3 = Red
					
					local animId = ID:match("%d+")
					local Name = "复制的动画"
					if animId then
						local success, info = pcall(function()
							return game:GetService("MarketplaceService"):GetProductInfo(tonumber(animId))
						end)
						if success then
							Name = info.Name
						end
					else
						warn("未找到有效的动画ID")
					end
					
					CreateTextbox(UDim2.new(0.45,0,0,35), Grey, 0, Name, animId, StolenAnimationsFrame)
					CreateButton(UDim2.new(0.45,0,0,35),Green, Name, Name, ID, StolenAnimationsFrame, TextBoxRn, true)
					
					-- 复制新动画后自动保存
					SaveStolenAnimations()
					break
				end
			end
		end
	end
	if Input.UserInputType == Enum.UserInputType.MouseButton3 and HoveringButton ~= nil then
		if StealId == HoveringButton:GetAttribute("AnimId") and Track ~= nil then
			Track:Stop()
		end
		StolenAnimationsFrame.CanvasSize -= UDim2.new(0,0,0,HoveringButton.Size.Y.Offset)
		if HoveringBox then
			HoveringBox:Destroy()
		end
		HoveringButton:Destroy()
		
		-- 删除动画后自动保存
		SaveStolenAnimations()
	end
end)

-- Creating buttons
Counter = 0
for i=1, #AnimButtons/2 do
	CreateTextbox(UDim2.new(0.45,0,0,35), Grey, 0, AnimButtons[Counter+2], AnimButtons[Counter+1], AnimationsFrame)
	CreateButton(UDim2.new(0.45,0,0,35),Red, AnimButtons[Counter+2], AnimButtons[Counter+2], "rbxassetid://".. AnimButtons[Counter+1], AnimationsFrame, TextBoxRn, false)
	Counter += 2
end

-- 自动加载保存的动画数据
LoadStolenAnimations()