local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local enemies = {}

function enemies.spawn(name,map,quantity,wave)
	
	for i=1,quantity do
		local info = ReplicatedStorage.Enemies[name].info
		local model = ReplicatedStorage.Enemies[name]:Clone()

		model.Humanoid.MaxHealth = info.health.Value
		model.Humanoid.Health = info.health.Value
		model.Humanoid.WalkSpeed = info.speed.Value
		model:PivotTo(CFrame.new(map.waypoints[0][1].Position) * CFrame.Angles(0,math.pi,0))

		local w = Instance.new("IntValue") w.Name="waypoint" w.Value=0 w.Parent=model.info --the most recent waypoint they have passed
		local wa = Instance.new("IntValue") wa.Name="wave" wa.Value=wave wa.Parent=model.info --for progress bar on skipped waves
		
		model.Parent = map.enemies
		model.HumanoidRootPart:SetNetworkOwner(nil) --stop weird movement near players

		model.Humanoid.Died:Connect(function()
			ServerStorage.bindables.enemyMoney:Fire(map,model)
			task.wait(0.5)
			model:Destroy()
		end)
		
		ReplicatedStorage.events.animate:FireAllClients(model,"Walk")
		coroutine.wrap(enemies.Move)(model,map)
		task.wait(0.15 * info.speed.Value) --so the spread between enemies is somewhat equal
	end
end


function enemies.Move(enemy,map)
	local waypoints = map.waypoints
	for i = 1, #waypoints:GetChildren()-1 do 
		--waypoints starts at 0 so last one is at # -1
		enemy.info.waypoint.Value = i - 1
		for _,w in waypoints[i]:GetChildren() do
			--each one is duplicated because of the 8 second timeout
			enemy.Humanoid:MoveTo(w.Position)
			enemy.Humanoid.MoveToFinished:Wait()
		end
	end
	ServerStorage.bindables.baseDamage:Fire(map,enemy)
	enemy:Destroy()
end



return enemies