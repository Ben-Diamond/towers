local Tweens = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local utils = {}



function utils.setCollisionGroup(model:Model,groupName:StringValue)
	for _,v in pairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CollisionGroup = groupName 
		end
	end
end

function utils.getNextTargetMethod(method,flying)
	local linkedList = {
		First="Last",
		Last="Strongest",
		Strongest="Weakest",
		Weakest="Closest",
		Closest="Random",
		["Random"]="First", --cause Random turns red
		Flying="Last"
	}
	if flying and method=="First" then return "Flying" end
	return linkedList[method]
end

local speedTables={
	["Zombie"]= 0.7,
	["Conehead Zombie"]= 0.7,
	["Buckethead Zombie"]= 0.7,
	["Slow Zombie"]= 0.5,
	["Imp"]= 1.2,
	["Balloon Zombie"]= 0.4,
	["Football Zombie"]= 1
}
function utils.animate(object,animation)
	local humanoid = object:WaitForChild("Humanoid")
	local animations = object:WaitForChild("Animations")
	if humanoid and animations then
		local anim = animations:WaitForChild(animation)
		if anim then
			local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator",humanoid)

			for _,i in animator:GetPlayingAnimationTracks() do 
				if i.Name == animation then
					i:Play() return
				end 
			end
			

			local a = animator:LoadAnimation(anim)
			a:Play()
			if animation == "Walk" then a:AdjustSpeed(speedTables[object.Name]) --can use this for ice effect
			elseif animation == "Attack" and object.info.reload.Value < 5 then a:AdjustSpeed(1.5) end
			


		end
	else warn(`something's up with {object.Name}`) end
end


function utils.sortDelays(particleHolder: Part) --returns a { delayTime: {emitter1,emitter2}, delayTime2: {emitter3,emitter4}}
	local delays = {}
	--for _, emitter in attachment:GetChildren() do
	for _, emitter in particleHolder:GetDescendants() do
		if emitter:IsA("ParticleEmitter") then
			local emitDelay = emitter:GetAttribute("EmitDelay") or 0
			if not delays[emitDelay] then 
				delays[emitDelay] = {}
			end
			table.insert(delays[emitDelay],emitter)
		end
	end
	table.sort(delays)
	return delays
end

function utils.getXZDistance(o1,o2)
	return Vector2.new(o1.Position.X-o2.Position.X,o1.Position.Z-o2.Position.Z).Magnitude
end

function utils.projectile(tower,enemy) --CLIENT
	local p = Instance.new("Part")
	p.Size = Vector3.new(0.5,0.5,0.5)
	if tower:FindFirstChild("RightHand") then
	p.CFrame = tower.RightHand.CFrame
	else
		p.CFrame = tower["Right Arm"].CFrame
	end
	p.Anchored = true
	p.CanCollide = false p.CanQuery = false
	p.Transparency = 0.5
	p.Parent = workspace
	
	local f = Instance.new("Fire")
	f.Size=1 f.Heat=0.1 f.Color=tower.Head.Color f.Parent=p
	
	Tweens:Create(p,TweenInfo.new(0.2),{Position=enemy.HumanoidRootPart.Position}):Play()
	Debris:AddItem(p,0.2)


	--coroutine.wrap(function(e)task.wait(0.13)utils.animate(e,"Hit") end)(enemy)

end

function utils.createSplash(tower,enemy) --SERVER (towers)
	local radius = tower.abilities.splash.Value
		

	local f = Instance.new("Fire")
	f.Size=radius*2 f.Heat=10 f.Color=tower.Head.Color f.Parent=enemy.HumanoidRootPart
	Debris:AddItem(f,0.3)
	
	for _,e in tower.Parent.Parent.enemies:GetChildren() do
		if utils.getXZDistance(f.Parent,e.HumanoidRootPart) <= radius and e ~= enemy and e.Name~="Balloon Zombie" then
			e.Humanoid.Health -= tower.info.damage.Value
		end
	end
	
end


return utils
