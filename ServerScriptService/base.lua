local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")


local base = {}

base.__index= base
function base.new(map)
	local building = map.base
	local self = setmetatable({
		map = map,
		model = building,

		maxHealth = 200,
		health = 200

	},base)
	
	local gui = ReplicatedStorage.templates.healthGui:Clone()
	gui.TextLabel.Text = `{self.maxHealth}/{self.maxHealth}`
	gui.Parent = building
	gui.Adornee = building
	--billboard gui stuff
	return self
end


function base:TakeDamage(dmg)
	self.health -= dmg
	if self.health < 0 then self.health = 0 end
	self.model.healthGui.healthBar.Size = UDim2.new(self.health/self.maxHealth,0,1,0)
	self.model.healthGui.TextLabel.Text = `{self.health}/{self.maxHealth}`
	if self.health == 0 then
		print("Died!")
	end
end


return base