local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Tweens = game:GetService("TweenService")

local utils = require(ReplicatedStorage.utils)

local towers = {}

function towers.new(player,name,map,cf)
	--first place it to see
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = map:GetDescendants()
	
	local clone = ReplicatedStorage.Towers[name]:Clone()
	
	clone:PivotTo(cf)
	clone.Parent = workspace

	local parts = workspace:GetPartsInPart(clone.cylinder, overlapParams)
	
	if #parts ~= 1 or parts[1] ~= map.floor then clone:Destroy() return end --sad!
	
	if player.stats.coins.Value < clone.info.price.Value then
		print("you cannot afford ford ford ford my diamond sword sword sword sword")
		clone:Destroy() return
	end
	
	player.stats.coins.Value -= clone.info.price.Value
	
	local l = Instance.new("IntValue") l.Name = "level" l.Value = 1 l.Parent = clone.info
	local t = Instance.new("StringValue") t.Name = "targetMethod" t.Value = "First" t.Parent = clone.info
	
	clone.Parent = map.towers
	local rangeCylinder = ReplicatedStorage.rangeCylinder:Clone()
	rangeCylinder.Size = Vector3.new(3,clone.info.range.Value * 2,clone.info.range.Value * 2)
	local offset = CFrame.new(0,- 2 - clone.PrimaryPart.Size.Y/2,0)
	rangeCylinder.TopSurface = Enum.SurfaceType.Smooth 		rangeCylinder.BottomSurface = Enum.SurfaceType.Smooth

	rangeCylinder.CFrame = clone.PrimaryPart.CFrame *offset*  CFrame.Angles(0,0,math.pi/2)
	rangeCylinder.Transparency = 1
	
	local t = Instance.new("ObjectValue") t.Name = "rangeCylinder" t.Value = rangeCylinder t.Parent = clone
	--we put a reference to the cylinder inside the tower
	
	rangeCylinder.Parent = map.rangeCylinders
	ReplicatedStorage.events.placeTower:FireClient(player,clone)
	

	towers.Attack(clone)	
end

local flying = {["Balloon Zombie"]=true}

function towers.FindTarget(tower,ignore: {Model})
	local targetMethod = tower.info.targetMethod.Value
	local target = nil
	
	local ignore2 = {}
	if targetMethod == "Flying" then local noFly = true
		for _,enemy in  tower.Parent.Parent.enemies:GetChildren() do
			if not flying[enemy.Name]
				or ignore[enemy] or utils.getXZDistance(enemy.HumanoidRootPart,tower.HumanoidRootPart) > tower.info.range.Value or enemy.Humanoid.Health <= 0 
			then ignore2[enemy] = true else noFly = false end 
		end
		if noFly then ignore2 = {} end
	end
	
	
	if targetMethod == "Closest" then
	local closest = tower.info.range.Value
		for _,enemy in tower.Parent.Parent.enemies:GetChildren() do
			if (flying[enemy.Name] and not tower.abilities:FindFirstChild("flying")) or ignore[enemy]   then continue end
			local distance = utils.getXZDistance(enemy.HumanoidRootPart,tower.HumanoidRootPart)
			if distance <= closest and enemy.Humanoid.Health > 0 then
				target = enemy closest = distance
			end
		end
	elseif targetMethod == "First" or targetMethod == "Flying" then
		local wp = -1 local dist = 0
		for _,enemy in tower.Parent.Parent.enemies:GetChildren() do
			if (flying[enemy.Name] and not tower.abilities:FindFirstChild("flying")) or ignore[enemy] or ignore2[enemy] or utils.getXZDistance(enemy.HumanoidRootPart,tower.HumanoidRootPart) > tower.info.range.Value or enemy.Humanoid.Health <= 0   then continue end
			local block = tower.Parent.Parent.waypoints[enemy.info.waypoint.Value]["1"]
			if enemy.info.waypoint.Value > wp then
				wp = enemy.info.waypoint.Value
				dist = utils.getXZDistance(enemy.HumanoidRootPart,block)
				target = enemy
			elseif enemy.info.waypoint.Value == wp then
				local temp = utils.getXZDistance(enemy.HumanoidRootPart,block)
				if temp > dist then
					target = enemy dist = temp
				end
			end
		end
	elseif targetMethod == "Last" then
		local wp = 10e7 local dist = 10e7
		for _,enemy in tower.Parent.Parent.enemies:GetChildren() do
			if (flying[enemy.Name] and not tower.abilities:FindFirstChild("flying")) or ignore[enemy] or utils.getXZDistance(enemy.HumanoidRootPart,tower.HumanoidRootPart) > tower.info.range.Value or enemy.Humanoid.Health <= 0   then continue end
			local block = tower.Parent.Parent.waypoints[enemy.info.waypoint.Value]["1"]
			if enemy.info.waypoint.Value < wp then
				wp = enemy.info.waypoint.Value
				dist = utils.getXZDistance(enemy.HumanoidRootPart,block)
				target = enemy
			elseif enemy.info.waypoint.Value == wp then
				local temp = utils.getXZDistance(enemy.HumanoidRootPart,block)
				if temp < dist then
					target = enemy dist = temp
				end
			end
		end
	elseif targetMethod == "Strongest" then --secondary priority for ties? (but first is the most complex so not yet)
		local hp = 0
		for _,enemy in tower.Parent.Parent.enemies:GetChildren() do
			if (not flying[enemy.Name] or tower.abilities:FindFirstChild("flying")) and not ignore[enemy] and utils.getXZDistance(enemy.HumanoidRootPart,tower.HumanoidRootPart) <= tower.info.range.Value  
			and enemy.Humanoid.Health > hp then
			target = enemy hp = enemy.Humanoid.Health
			end
		end
	elseif targetMethod == "Weakest" then --secondary priority for ties? (but first is the most complex so not yet)
		local hp = 10e7
		for _,enemy in tower.Parent.Parent.enemies:GetChildren() do
			if  (not flying[enemy.Name] or tower.abilities:FindFirstChild("flying")) and not ignore[enemy] and utils.getXZDistance(enemy.HumanoidRootPart,tower.HumanoidRootPart) <= tower.info.range.Value and enemy.Humanoid.Health > 0   
				and enemy.Humanoid.Health < hp then
				target = enemy hp = enemy.Humanoid.Health
			end
		end
	elseif targetMethod == "Random" then
		local valids = {}
		for _,enemy in tower.Parent.Parent.enemies:GetChildren() do
			if (not flying[enemy.Name] or tower.abilities:FindFirstChild("flying")) and not ignore[enemy] and utils.getXZDistance(enemy.HumanoidRootPart,tower.HumanoidRootPart) <= tower.info.range.Value and enemy.Humanoid.Health > 0   then
				table.insert(valids,enemy)
			end
			if #valids >0 then target = valids[math.random(#valids)] end
		end
	end
	return target
end



function towers.Attack(tower)
	local targets = {}
	local num = if tower.abilities:FindFirstChild("prongs") then tower.abilities.prongs.Value else 1
	for i=1,num do 
		local target = towers.FindTarget(tower,targets)
		if not target then break end
		
		targets[target] = true

	end
	for target in targets do  		ReplicatedStorage.events.towerAttack:FireAllClients(tower,target)
		if tower.abilities:FindFirstChild("splash") then
			coroutine.wrap(function(e,t)task.wait(0.13) utils.createSplash(t,e) end)(target,tower)
		end

		target.Humanoid.Health -= tower.info.damage.Value 
	end
	if tower.abilities:FindFirstChild("slowDown") then
		local oldTargets = {}
		for _,slow in tower.slowTargets:GetChildren() do if slow.Value then
			oldTargets[slow.Value] = true
			slow.Value = nil
		end end
		local t=0
		for target in targets do t+=1
			--give target the slow
			tower.slowTargets[t].Value = target

		end
		for old in oldTargets do
			if old and old:FindFirstChild("Humanoid") and not targets[old] then old.Head.Color = Color3.fromRGB(58, 125, 21) old.Humanoid.WalkSpeed = old.info.speed.Value end
		end
		for new in targets do
			if not oldTargets[new] then new.Head.Color = Color3.fromRGB(0, 143, 156) new.Humanoid.WalkSpeed = tower.abilities.slowDown.Value * new.info.speed.Value end
		end
	end

	
	
	task.wait(tower.info.reload.Value / 10)
	towers.Attack(tower)
end


function towers.changeTargetMethod(player,tower)
	local method = utils.getNextTargetMethod(tower.info.targetMethod.Value,tower.abilities:FindFirstChild("flying"))
	if method then
		tower.info.targetMethod.Value = method
		ReplicatedStorage.events.changeTargetMethod:FireClient(player,tower,method)
	else
		ReplicatedStorage.events.changeTargetMethod:FireClient(player,tower,nil)

	end
end

function towers.Upgrade(player,tower)
	local upgrade = ReplicatedStorage.upgrades[tower.Name]:FindFirstChild(tower.info.level.Value + 1)
	if not upgrade then return end
	if player.stats.coins.Value < upgrade.price.Value then return end --send a warning to the user
	player.stats.coins.Value -= upgrade.price.Value
	tower.info.level.Value += 1
	
	for _,stat in upgrade:GetChildren() do
		if stat.Name ~= "price" then
			if stat.Name == "abilities" then
				for _,ab in stat:GetChildren() do
				if tower.abilities:FindFirstChild(ab.Name) then
					--increase it
					tower.abilities[ab.Name].Value = ab.Value
					
				else
					local a = ab:Clone() a.Parent = tower.abilities
				end
				end
			else
			
				tower.info[stat.Name].Value = stat.Value
				if stat.Name == "range" then
					tower.rangeCylinder.Value.Size = Vector3.new(3,stat.Value * 2,stat.Value * 2)
				end
			end
		end
	end
	
	
	
	
	
	ReplicatedStorage.events.upgradeTower:FireClient(player,tower)
	
end


return towers