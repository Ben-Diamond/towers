local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
--[[
now
tower upgrades
more  zombies

later



tweens - the upgrade button (uigradient)
abililites

owner (easy but brainworms)

mouseover tower = display name and level and dps

]]

local monies = {
	["Zombie"]= 10,
	["Conehead Zombie"]= 15,
	["Buckethead Zombie"]= 23,
	["Slow Zombie"]= 45,
	["Imp"]= 17,
	["Balloon Zombie"]= 22,
	["Football Zombie"]= 60
}
local ready = {}

local utils = require(ReplicatedStorage.utils)
local enemies = require(script.Parent.enemy)
local towers = require(script.Parent.tower)
local bases = require(script.Parent.base)
local map = workspace:WaitForChild("forest")
local base = bases.new(map)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)utils.setCollisionGroup(char,"Players")end)
	
	local folder = Instance.new("Folder") folder.Name = "stats" folder.Parent = player
	local g = Instance.new("IntValue") g.Value = 200 g.Name = "coins" g.Parent = folder
	local t = Instance.new("StringValue") t.Value = "" t.Name = "timer" t.Parent = folder
	local w = Instance.new("IntValue") w.Value = 0 w.Name = "wave" w.Parent = folder
	local s = Instance.new("BoolValue") s.Value = false s.Name = "showSkip" s.Parent = folder
	
	ready[player.UserId] = false
end)


map.enemies.ChildAdded:Connect(function(enemy)
	utils.setCollisionGroup(enemy,"Enemies")
end)
map.towers.ChildAdded:Connect(function(tower)
	utils.setCollisionGroup(tower,"Towers")
end)

ReplicatedStorage.events.placeTower.OnServerEvent:Connect(function(player,towerName,cf)
	towers.new(player,towerName,map,cf)
end)

ReplicatedStorage.events.upgradeTower.OnServerEvent:Connect(function(player,tower)
	if tower ~= nil --and if the player owns it...
	then
		towers.Upgrade(player,tower)
	end
end)

ReplicatedStorage.events.changeTargetMethod.OnServerEvent:Connect(towers.changeTargetMethod)

ReplicatedStorage.events.skip.OnServerEvent:Connect(function(player)
	if player.stats.showSkip.Value == true then
		player.stats.showSkip.Value = false
		--local p=Instance.new("BoolValue") p.Value=false p.Name="temp" p.Parent = map.enemies
		--task.wait(.5)
		--p:Destroy()
	end
end)

ReplicatedStorage.events.freeMoney.OnServerEvent:Connect(function(player)player.stats.coins.Value+=100 end)

ReplicatedStorage.events.ready.OnServerEvent:Connect(function(player)
	ready[player.UserId] = true
	for _,val in ready do
		if not val then return end
	end
	ReplicatedStorage.events.ready:FireAllClients()
	for wave = 1,#waveZombies do
		local zombiesToSpawn = waveZombies[wave]
		local t = 0
		for _,z in zombiesToSpawn do t += z[2] end
		for _,player in Players:GetPlayers() do player.stats.wave.Value = wave end

		for t = 3,1,-1 do
			for _,player in Players:GetPlayers() do	player.stats.timer.Value = `Starting in {t}` end
			task.wait(1)
		end
		ReplicatedStorage.events.progressBar:FireAllClients(t,t)


		for _,z in zombiesToSpawn do
			enemies.spawn(z[1],map,z[2],wave)
			task.wait(0.5)
		end
		if wave < #waveZombies then  for _,player in Players:GetPlayers() do player.stats.showSkip.Value = true end end
		
		
		while #map.enemies:GetChildren() > 0 do 
			task.wait(1)
			local f=false
			for _,player in Players:GetPlayers() do
				if wave >= #waveZombies or player.stats.showSkip.Value == true then 
					f = true
				end
			end
			if not f then break end
		end
		
		
		for _,player in Players:GetPlayers() do player.stats.coins.Value += wave*80
			player.stats.showSkip.Value = false
		end

	end
	for _,player in Players:GetPlayers() do player.stats.timer.Value = "Well done you won!" end
	
	
end)


ServerStorage.bindables.baseDamage.Event:Connect(function(map,enemy)
	--base would be a variable associated 
	for _,player in Players:GetPlayers() do 
		if player.stats.wave.Value == enemy.info.wave.Value then
			ReplicatedStorage.events.progressBar:FireClient(player,-1,nil)
		end
	end
	

	base:TakeDamage(enemy.info.damage.Value)
end)
ServerStorage.bindables.enemyMoney.Event:Connect(function(map,enemy)
	--give money to players associated with the map
	--for now one player
	for _,player in Players:GetPlayers() do 
		player.stats.coins.Value += monies[enemy.Name]
		if player.stats.wave.Value == enemy.info.wave.Value then
			ReplicatedStorage.events.progressBar:FireClient(player,-1,nil)
			
		end
	end

end)


waveZombies = {
	--[1] = {{"Slow Zombie",2},{"Buckethead Zombie",1}},
	[1] = {{"Zombie",1},{"Zombie",1}},
	[2] = {{"Zombie",3},{"Conehead Zombie",1}},
	[3] = {{"Conehead Zombie",2},{"Conehead Zombie",1},{"Zombie",1},{"Buckethead Zombie",1}},
	[4] = {{"Buckethead Zombie",3},{"Conehead Zombie",1},{"Imp",5}},
	[5] = {{"Slow Zombie",3},{"Zombie",10},{"Buckethead Zombie",3}},
	[6] = {{"Buckethead Zombie",6},{"Balloon Zombie",3},{"Slow Zombie",2}},
	[7] = {{"Football Zombie",1},{"Balloon Zombie",3},{"Slow Zombie",2}}

}



