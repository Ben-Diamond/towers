local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Tweens = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer


local utils = require(ReplicatedStorage.utils)

local camera = workspace.CurrentCamera
local gui = player.PlayerGui:WaitForChild("ScreenGui")
local towerPlacedInfo = gui.towerPlacedInfo
local ghost = nil
local canPlace = false
local rangeCylinder = nil
local placedRangeCylinder = nil --This is the range cylinder of the PLACED tower we are currentl hovering. neeeded so we can make it transparent
local towerImageHover = nil
local towerHighlight = ReplicatedStorage.templates.towerHighlight:Clone()
towerHighlight.Parent = workspace
towerHighlight.Parent = nil
local enemyHealthBar = ReplicatedStorage.templates.healthBar:Clone()
enemyHealthBar.Parent = gui
local towerName = ReplicatedStorage.templates.towerName:Clone()
towerName.Parent = gui

local map = workspace.forest
local coins = player:WaitForChild("stats"):WaitForChild("coins")





--FUNCTIONS


local function castMouse(objects,filterType)
	local mousePosition = UserInputService:GetMouseLocation()
	local mouseRay = camera:ViewportPointToRay(mousePosition.X,mousePosition.Y)
	local params = RaycastParams.new() params.FilterType = filterType
	params.FilterDescendantsInstances = objects

	local cast = workspace:Raycast(mouseRay.Origin,mouseRay.Direction * 200,params)
	return cast
end

local function colourGhost(colour)
	ghost.cylinder.Color = colour
end

local function removeGhost()
	if ghost then ghost:Destroy() ghost = nil rangeCylinder:Destroy() rangeCylinder = nil gui.towers.cancel.Transparency=1 gui.towers.cancel.TextLabel.TextTransparency=1 gui.towers.cancel.UIStroke.Transparency=1 end
end

local function rangeCylinderDisappear(cylinder)
	Tweens:Create(cylinder,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=Vector3.new(3,0,0)}):Play()
end


local function addGhost(name)
	removeGhost()
	if towerPlacedInfo.tower.Value then --close it
		towerPlacedInfo.Visible = false
		rangeCylinderDisappear(towerPlacedInfo.tower.Value.rangeCylinder.Value) --lol
		towerPlacedInfo.tower.Value = nil

	end
	if ReplicatedStorage.Towers[name] then
		gui.towers.cancel.Transparency=0 gui.towers.cancel.TextLabel.TextTransparency=0 gui.towers.cancel.UIStroke.Transparency=0
		ghost = ReplicatedStorage.Towers[name]:Clone()
		for _, part in ghost:GetDescendants() do
			if part:IsA("BasePart") then
				part.CollisionGroup = "None"
				part.Material = "ForceField"
			end
		end
		canPlace = false
		utils.setCollisionGroup(ghost,"Towers")
		--holy moly none of this makes sense
		rangeCylinder = ReplicatedStorage.rangeCylinder:Clone()
		rangeCylinder.Size = Vector3.new(3,ghost.info.range.Value * 2,ghost.info.range.Value * 2)
		local offset = CFrame.new(0,-ghost.Humanoid.HipHeight - ghost.PrimaryPart.Size.Y/2,0)

		rangeCylinder.CFrame = ghost.PrimaryPart.CFrame *offset*  CFrame.Angles(0,0,math.pi/2)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rangeCylinder weld.Part1 = ghost.PrimaryPart weld.Parent = rangeCylinder rangeCylinder.Parent = ghost

		ghost.Parent = workspace
	end
end
--FUNCTIONS





--GUI
local function fillTowerHoverInfo(name)
	
	local box = gui.towerHoverInfo
	if not box.Visible then Tweens:Create(box,TweenInfo.new(0.2),{Visible=true, BackgroundTransparency = 0.45}):Play() end

	--if name == "" then box.Visible = false return end
	box.price.number.TextColor3 = if coins.Value >= tonumber(string.sub(box.price.number.Text,2)) then Color3.fromRGB(250, 200, 48) else Color3.fromRGB(255, 110, 84)

	if box.name.Value == name and box.Visible then return end
	local info = ReplicatedStorage.Towers[name].info
	box.name.Value = name

	box.range.number.Text = info.range.Value
	box.damage.number.Text = info.damage.Value
	box.reload.number.Text = info.reload.Value / 10
	box.DPS.number.Text = math.round(10*10*info.damage.Value/info.reload.Value)/10
	box.price.number.Text = `${info.price.Value}`
	--box.Visible = true
end
local tabl = {

	range=function(val)return val end,
	damage=function(val)return val end,
	reload=function(val)return val/10 end,	

	prongs=function(val)return `{val} targets, ` end,
	flying=function(val) return `Targets air, `end,
	splash=function(val)return `Splash radius: {val}, ` end,
	slowDown=function(val)return `Target speed x{val}, ` end,

}
local function stringMessage(name,val,append)

	if tabl[name] then return append..tabl[name](val) end
	return append	
end


local function fillTowerPlacedInfo(tower: Model)
	local box = towerPlacedInfo
	--if name == "" then box.Visible = false return end

	if box.tower.Value == tower and box.Visible then rangeCylinderDisappear(tower.rangeCylinder.Value) box.Visible = false box.tower.Value = nil return end
	if box.tower.Value then --close it
		rangeCylinderDisappear(box.tower.Value.rangeCylinder.Value) --lol
	end
	tower:WaitForChild("rangeCylinder").Value.Size = Vector3.new(3,0,0)
	Tweens:Create(tower.rangeCylinder.Value,TweenInfo.new(0.38,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{Size = Vector3.new(3,tower.info.range.Value * 2,tower.info.range.Value * 2)}):Play()
	tower.rangeCylinder.Value.Transparency = 0.7
	
	box.tower.Value = tower
	
	local info = tower.info
	box.name.Text = tower.Name
	box.level.Text = `Level {info.level.Value}`
	box.desc.TextLabel.Text = info.desc.Value
	box.ImageLabel.Image = `rbxassetid://{ReplicatedStorage.templates.images[tower.Name].Value}`

	box.stats.range.number.Text = stringMessage("range",info.range.Value,"")
	box.stats.damage.number.Text = stringMessage("damage",info.damage.Value,"")
	box.stats.reload.number.Text = stringMessage("reload",info.reload.Value,"")
	box.stats.DPS.number.Text = math.round(10*10*info.damage.Value/info.reload.Value)/10

	local text = "No abilities"
	if #tower.abilities:GetChildren() > 0 then
		text = ""
		for _,ability in tower.abilities:GetChildren() do
			text = stringMessage(ability.Name,ability.Value,text)
			if ability.Name == "prongs" then box.stats.DPS.upgrade.Text = `{ability.Value}x {box.stats.DPS.number.Text}` end
		end
		text = string.sub(text,1,-3)
	end
	box.stats.ability.number.Text = text
	
	
	
	
	local u = ReplicatedStorage.upgrades:FindFirstChild(tower.Name)
	local upgrade = if u then u:FindFirstChild(tower.info.level.Value + 1) else nil
	if upgrade then
		box.upgrade.TextLabel.Text = "Upgrade:"
		
		--{0.383, 0},{1, 0}
		Tweens:Create(box.upgrade.price,TweenInfo.new(0.17,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,true),{Size=UDim2.new(0.4,0,1.1,0)}):Play()
		
		box.upgrade.price.Text = `${upgrade.price.Value}`
		box.upgrade.price.TextColor3 = if coins.Value >= upgrade.price.Value then Color3.fromRGB(250, 200, 48) else Color3.fromRGB(255, 110, 84)
		box.stats.DPS.upgrade.Text = math.round(10*10*(if upgrade:FindFirstChild("damage") then upgrade.damage.Value else info.damage.Value)/(if upgrade:FindFirstChild("reload") then upgrade.reload.Value else info.reload.Value))/10
		box.stats.damage.upgrade.Text = if upgrade:FindFirstChild("damage") then stringMessage("damage",upgrade.damage.Value,"") else ""
		box.stats.reload.upgrade.Text = if upgrade:FindFirstChild("reload") then stringMessage("reload",upgrade.reload.Value,"") else ""
		box.stats.range.upgrade.Text = if upgrade:FindFirstChild("range") then stringMessage("range",upgrade.range.Value,"") else ""

		
		if upgrade:FindFirstChild("abilities") then
			local child = upgrade.abilities:GetChildren()[1]
			
			box.stats.ability.upgrade.Text = string.sub(stringMessage(child.Name,child.Value,""),1,-3)

			if child.Name == "prongs" then box.stats.DPS.upgrade.Text = `{child.Value}x {box.stats.DPS.upgrade.Text}` end
		else
			box.stats.ability.upgrade.Text = ""
		end

	else
		for _,stat in box.stats:GetChildren() do if stat:FindFirstChild("upgrade") then stat.upgrade.Text = "" end end
		box.upgrade.TextLabel.Text = "Max Level" box.upgrade.price.Text = ""
	end
	
	box.target.TextLabel.Text = `Target: {info.targetMethod.Value}`

	box.Visible = true
end


for _,tower in ReplicatedStorage.Towers:GetChildren() do
	local template = ReplicatedStorage.templates.towerTemplate:Clone()
	local layoutOrder = {["Grey Tower"] = 1,["Yellow Tower"]=2,["Green Tower"]=3,["Blue Tower"]=4}
	template.LayoutOrder = layoutOrder[tower.Name]
	template.ImageLabel.Image = `rbxassetid://{ReplicatedStorage.templates.images[tower.Name].Value}`
	template.MouseEnter:Connect(function() towerImageHover = tower.Name end)
	template.MouseLeave:Connect(function()if towerImageHover == tower.Name then towerImageHover = nil end end)
	template.TextButton.MouseButton1Click:Connect(function()addGhost(tower.Name) end)
	template.Parent =gui.towers
end



towerPlacedInfo.close.TextButton.MouseButton1Click:Connect(function()
	fillTowerPlacedInfo(towerPlacedInfo.tower.Value)
end)

gui.towers.cancel.MouseButton1Click:Connect(function()removeGhost()end)

--GUI












--CONNECTIONS
UserInputService.InputBegan:Connect(function(input,processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if ghost and canPlace then
			--tower highlight...
			ReplicatedStorage.events.placeTower:FireServer(ghost.Name,ghost.WorldPivot)
			--fillTowerHoverInfo(ghost.Name)
			removeGhost()
		elseif towerHighlight.Parent and towerHighlight.Parent.Parent == map.towers then --click on tower
			fillTowerPlacedInfo(towerHighlight.Parent)
		elseif towerPlacedInfo.tower.Value then --click off
			fillTowerPlacedInfo(towerPlacedInfo.tower.Value)
		end
		
	end
end)

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Include
task.wait(1)
overlapParams.FilterDescendantsInstances = map:GetDescendants()
local yOffset = game.GuiService:GetGuiInset().Y

RunService.RenderStepped:Connect(function()
	if ghost == nil then 
		
		--first check if the mouse is above a tower image
		if towerImageHover then
			local pos = UserInputService:GetMouseLocation()
			gui.towerHoverInfo.Position =  UDim2.new(0,pos.X + 5,0,pos.Y - yOffset - 4)
			fillTowerHoverInfo(towerImageHover)
			task.wait()
			gui.towerHoverInfo.Visible = true
		else
			gui.towerHoverInfo.Visible = false gui.towerHoverInfo.Transparency = 1
		end
		local result = castMouse({},Enum.RaycastFilterType.Exclude)
		if pcall(function()if result.Instance.Parent.Parent == map.towers then return true else error() end end) then
			
			--we are mousing over a tower
			enemyHealthBar.Visible = false
			towerHighlight.Parent = result.Instance.Parent
			towerName.name.Text = result.Instance.Parent.Name towerName.level.Text =  `Level {result.Instance.Parent.info.level.Value}`
			local pos = UserInputService:GetMouseLocation()
			towerName.Position =  UDim2.new(0,pos.X + 65,0,pos.Y - yOffset - 4)
			if not towerName.Visible then
				task.wait()
				towerName.Visible = true
				Tweens:Create(towerName,TweenInfo.new(0.2),{BackgroundTransparency = 0.45}):Play()	
				
			end
		else
			--tower -> no tower
			--towerHighlight.Parent = nil
			towerName.Visible = false towerName.Transparency = 1
			--are we on a zombie?
			local enemy
			if pcall(function()if result.Instance.Parent.Parent == map.enemies then enemy=result.Instance.Parent return true elseif result.Instance.Parent.Parent.Parent == map.enemies then enemy=result.Instance.Parent.Parent return true else error() end end)then 
			--we are mousing over an enemy
				towerHighlight.Parent = enemy
				enemyHealthBar.bar.Size = UDim2.new(enemy.Humanoid.Health/enemy.Humanoid.MaxHealth,0,1,0)
				enemyHealthBar.health.Text = `{enemy.Humanoid.Health}/{enemy.Humanoid.MaxHealth}`
				enemyHealthBar.name.Text = enemy.Name
				
				local pos = UserInputService:GetMouseLocation()
				enemyHealthBar.Position =  UDim2.new(0,pos.X + 65,0,pos.Y - yOffset - 4)
				enemyHealthBar.Visible = true
				
			
			else
				enemyHealthBar.Visible = false
				towerHighlight.Parent = nil
			end
		end
		
		
	else
	--attempt to place
		gui.towerHoverInfo.Visible = false 	gui.towerHoverInfo.Transparency = 1

	towerImageHover = false
	local result = castMouse({map.floor},Enum.RaycastFilterType.Include)
	if result and result.Instance then
		if #workspace:GetPartsInPart(ghost.cylinder, overlapParams) == 1 then
			canPlace = true colourGhost(Color3.fromRGB(0,255,0)) 
			else canPlace = false colourGhost(Color3.fromRGB(255,0,0)) end
		
		local cf = CFrame.new(result.Position)
		ghost:PivotTo(cf)

		--rangeCylinder.Position = Vector3.new(result.Position.X,result.Position.Y - 0.1,result.Position.Z)
		ghost.cylinder.CFrame = cf * CFrame.Angles(0,math.pi/2,math.pi/2)
	end
	end
end)

ReplicatedStorage.events.tween.OnClientEvent:Connect(function(instance,info,properties)
	if instance then Tweens:Create(instance,TweenInfo.new(table.unpack(info)),properties):Play() end
end)
ReplicatedStorage.events.animate.OnClientEvent:Connect(utils.animate)
ReplicatedStorage.events.towerAttack.OnClientEvent:Connect(function(tower,target)
	local targetCF = CFrame.lookAt(tower.HumanoidRootPart.Position,Vector3.new(
		target.HumanoidRootPart.Position.X,tower.HumanoidRootPart.Position.Y,target.HumanoidRootPart.Position.Z))
	Tweens:Create(tower.HumanoidRootPart,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=targetCF}):Play()
	utils.animate(tower,"Attack")
	local particleHolder: Part = tower:FindFirstChild("Effects")
	
	if particleHolder then
		
		particleHolder.Position = target.HumanoidRootPart.Position --erros sometimes?
		local totalWait = 0

		local delays = utils.sortDelays(particleHolder)
		for emitDelay, emitterList in delays do

			if emitDelay > totalWait then
				task.wait(emitDelay - totalWait)
				totalWait = emitDelay
			end

			for _, emitter in emitterList do
				--some have an attribute "EmitType" = "attribute". Not sure how to use this
				emitter:Emit(emitter:GetAttribute("EmitCount"))
			end
		end
	end
	utils.projectile(tower,target)
end)

coins.Changed:Connect(function(new)
	gui.towers.coins.TextLabel.Text = `${new}`
	if towerPlacedInfo.Visible and towerPlacedInfo.upgrade.price.Text ~= "" then
		towerPlacedInfo.upgrade.price.TextColor3 = if coins.Value >=tonumber(string.sub(towerPlacedInfo.upgrade.price.Text,2)) then Color3.fromRGB(250, 200, 48) else Color3.fromRGB(255, 110, 84)
	end
end)

player.stats:WaitForChild("timer").Changed:Connect(function(new)
	gui.wave.remaining.Text = "" gui.wave.total.Text = ""
	gui.wave.TextLabel.Text = `Wave {player.stats.wave.Value}`
	gui.wave.timer.Text = new
end)

player.stats:WaitForChild("showSkip").Changed:Connect(function(new)
	gui.wave.skip.Visible = new
end)
player.PlayerGui.startGui.ready.MouseButton1Click:Connect(function()ReplicatedStorage.events.ready:FireServer() player.PlayerGui.startGui.ready.Visible = false end)
player.PlayerGui.startGui.ready.Visible = true

player.PlayerGui.startGui.openReadme.Visible = true
player.PlayerGui.startGui.openReadme.MouseButton1Click:Connect(function() if player.PlayerGui.startGui.openReadme.TextLabel.Visible then player.PlayerGui.startGui.openReadme.TextLabel.Visible = false
		player.PlayerGui.startGui.openReadme.Text = "Read me" else player.PlayerGui.startGui.openReadme.TextLabel.Visible = true player.PlayerGui.startGui.openReadme.Text = "Close" end
	end)


towerPlacedInfo.upgrade.MouseButton1Click:Connect(function()
	ReplicatedStorage.events.upgradeTower:FireServer(towerPlacedInfo.tower.Value)
end)

ReplicatedStorage.events.upgradeTower.OnClientEvent:Connect(function(tower)
	towerPlacedInfo.tower.Value = nil
	fillTowerPlacedInfo(tower)
end)

towerPlacedInfo.target.MouseButton1Click:Connect(function()
	ReplicatedStorage.events.changeTargetMethod:FireServer(towerPlacedInfo.tower.Value)
end)


gui.wave.skip.MouseButton1Click:Connect(function()
	ReplicatedStorage.events.skip:FireServer()
end)

gui.money.MouseButton1Click:Connect(function()
	ReplicatedStorage.events.freeMoney:FireServer()
end)

ReplicatedStorage.events.changeTargetMethod.OnClientEvent:Connect(function(tower,method)
	if method == nil then return end

	if tower == towerPlacedInfo.tower.Value then
		towerPlacedInfo.target.TextLabel.Text = `Target: {method}`
	end
end)

ReplicatedStorage.events.placeTower.OnClientEvent:Connect(function(tower) --select it
	task.wait()
	fillTowerPlacedInfo(tower)	
end)

ReplicatedStorage.events.progressBar.OnClientEvent:Connect(function(change,total)
	if total then gui.wave.total.Text = `\\{total} remaining`--lol
		gui.wave.remaining.Text = 0 	gui.wave.timer.Text = ""

	else total = tonumber(string.sub(gui.wave.total.Text:split(" ")[1],2,-1))
	end
	local count = tonumber(gui.wave.remaining.Text) + change
	
	gui.wave.remaining.Text = count
	Tweens:Create(gui.progressBar.bar,TweenInfo.new(0.4,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{Size=UDim2.new((total-count)/total + 0.01,0,1,0)}):Play()

end)

player.PlayerGui.startGui.loading.Visible = false

ReplicatedStorage.events.ready.OnClientEvent:Connect(function()player.PlayerGui.startGui:Destroy() gui.wave.Visible=true gui.progressBar.Visible=true gui.towers.Visible=true end)



--nice scrolling
Tweens:Create(gui.progressBar.bar.ImageLabel,TweenInfo.new(2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,false,0),{Position=UDim2.new(0,0,0.5,0)}):Play()


--CONNECTIONS

utils.animate(workspace.Rig,"barrage1")
