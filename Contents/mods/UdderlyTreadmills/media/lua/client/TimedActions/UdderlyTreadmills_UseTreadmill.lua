--[[
		Originally Developed by FC4RICA
		Working Treadmill 41.68+
		Modified by UdderlyEvelyn for 41.71 with different features
]]

require "TimedActions/ISBaseTimedAction"

UdderlyTreadmills_UseTreadmill = ISBaseTimedAction:derive("UdderlyTreadmills_UseTreadmill")

function UdderlyTreadmills_UseTreadmill:isValid()
	return true;
end

local passiveXPLevelThresholds = { 1500, 3000, 6000, 9000, 18000, 30000, 60000, 90000, 120000, 150000 }
local sprintingXPLevelThresholds = { 75, 150, 300, 750, 1500, 3000, 4500, 6000, 7500, 9000 }

local function addXP(currentDelta)
	local player = getPlayer()
	local xp = player:getXp()

	--Rewrote all of this function below this... -UdderlyEvelyn 7/31/22
	
	if SandboxVars.UdderlyTreadmills.GivesFitnessLevel then
		local currentLevel = player:getPerkLevel(Perks.Fitness)
		local targetLevel = currentLevel + 1
		if targetLevel == 11 then --No funny business. -UdderlyEvelyn 7/31/22
			targetLevel = 10
		end
		xp:AddXP(Perks.Fitness, passiveXPLevelThresholds[targetLevel] * currentDelta)
	end
	if SandboxVars.UdderlyTreadmills.GivesStrengthLevel then
		local currentLevel = player:getPerkLevel(Perks.Strength)
		local targetLevel = currentLevel + 1
		if targetLevel == 11 then --No funny business. -UdderlyEvelyn 7/31/22
			targetLevel = 10
		end
		xp:AddXP(Perks.Strength, passiveXPLevelThresholds[targetLevel] * currentDelta)
	end
	if SandboxVars.UdderlyTreadmills.GivesSprintingLevel then
		local currentLevel = player:getPerkLevel(Perks.Sprinting)
		local targetLevel = currentLevel + 1
		if targetLevel == 11 then --No funny business. -UdderlyEvelyn 7/31/22
			targetLevel = 10
		end
		xp:AddXP(Perks.Sprinting, sprintingXPLevelThresholds[targetLevel] * currentDelta)
	end
end

local function adjustStats(stats, currentDelta, enduranceReduction, fatigueIncrease, bodyDamage, temperatureIncrease)
	--reduce player endurance stat
	local enduranceChange = currentDelta * enduranceReduction
	stats:setEndurance(initialEndurance - enduranceChange)

	--add player fatigue stat
	local fatigueChange = currentDelta * fatigueIncrease
	stats:setFatigue(initialFatigue + fatigueChange)
	
	--add player temperature stat
	local temperatureChange = currentDelta * temperatureIncrease
	bodyDamage:setTemperature(initialTemperature + temperatureChange)
end

function UdderlyTreadmills_UseTreadmill:waitToStart()
	self.character:faceThisObject(self.machine);
	return self.character:shouldBeTurning();
end

-- call every frame while using treadmill
function UdderlyTreadmills_UseTreadmill:update()

	local isPlaying = self.gameSound
		and self.gameSound ~= 0
		and self.character:getEmitter():isPlaying(self.gameSound)

	if not isPlaying then
		-- Some examples of radius and volume found in PZ code:
		-- Fishing (20,1)
		-- Remove Grass (10,5)
		-- Remove Glass (20,1)
		-- Destroy Stuff (20,10)
		-- Remove Bush (20,10)
		-- Move Sprite (10,5)
		local soundRadius = 13
		local volume = 4

		-- Use the emitter because it emits sound in the world (zombies can hear)
		self.gameSound = self.character:getEmitter():playSound(self.soundFile);
		
		addSound(self.character,
				 self.character:getX(),
				 self.character:getY(),
				 self.character:getZ(),
				 soundRadius,
				 volume)
	end

	local currentDelta = self:getJobDelta()
	local deltaIncrease = currentDelta - self.deltaTabulated
	
	-- Update at every 0.05 delta milestone
	if deltaIncrease > 0.05 then
		adjustStats(self.character:getStats(), currentDelta, 0.85, 0.07, self.character:getBodyDamage(), 0.8)
		
		self.deltaTabulated = currentDelta
	end
	
	self.character:faceThisObject(self.machine);
end

-- call when start using treadmill
function UdderlyTreadmills_UseTreadmill:start()

	local actionType = self.actionType

	self:setActionAnim(actionType)
	-- Loot is used as a backup action, so keep this
	self.character:SetVariable("LootPosition", "Mid")
	
	local bodyDamage = self.character:getBodyDamage()
	initialEndurance = self.character:getStats():getEndurance()
	initialFatigue = self.character:getStats():getFatigue()
	initialTemperature = bodyDamage:getTemperature()
	print(initialTemperature)
	
	self:setOverrideHandModels(nil, nil)
end

--call when cancle using treadmill
function UdderlyTreadmills_UseTreadmill:stop()

	-- Make sure game sound has stopped
	if self.gameSound and
		self.gameSound ~= 0 and
		self.character:getEmitter():isPlaying(self.gameSound) then
		self.character:getEmitter():stopSound(self.gameSound);
	end

	local soundRadius = 13
	local volume = 4

	-- Use the emitter because it emits sound in the world (zombies can hear)
	self.gameSound = self.character:getEmitter():playSound(self.soundEnd);
		
	addSound(self.character,
			 self.character:getX(),
			 self.character:getY(),
			 self.character:getZ(),
			 soundRadius,
			 volume)
	
	-- Based on the Delta and piece level
	-- calculate Boredom/Unhappiness/Stress changes	
	local currentDelta = self:getJobDelta()
	local deltaIncrease = currentDelta - self.deltaTabulated
	
	--print("FC4WT: Adjusting stats for STOP")
	adjustStats(self.character:getStats(), currentDelta, 0.85, 0.07, self.character:getBodyDamage(), 0.8)
	addXP(currentDelta)
	
	self.deltaTabulated = currentDelta

	-- needed to remove from queue / start next.
	ISBaseTimedAction.stop(self);
end

--call when finish using treadmill
function UdderlyTreadmills_UseTreadmill:perform()

	-- Make sure game sound has stopped
	if self.gameSound and
		self.gameSound ~= 0 and
		self.character:getEmitter():isPlaying(self.gameSound) then
		self.character:getEmitter():stopSound(self.gameSound);
	end

	local soundRadius = 13
	local volume = 4

	-- Use the emitter because it emits sound in the world (zombies can hear)
	self.gameSound = self.character:getEmitter():playSound(self.soundEnd);
		
	addSound(self.character,
			 self.character:getX(),
			 self.character:getY(),
			 self.character:getZ(),
			 soundRadius,
			 volume)

	-- Based on the Delta and piece level
	-- calculate Boredom/Unhappiness/Stress changes	
	local currentDelta = self:getJobDelta()
	local deltaIncrease = currentDelta - self.deltaTabulated
	
	--print("FC4WT: Adjusting stats for PERFORM")
	adjustStats(self.character:getStats(), currentDelta, 0.85, 0.07, self.character:getBodyDamage(), 0.8)
	addXP(currentDelta)

	self.deltaTabulated = currentDelta

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function UdderlyTreadmills_UseTreadmill:new(character, machine, sound, soundEnd, actionType, length)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.machine = machine
	o.soundFile = sound
	o.soundEnd = soundEnd
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = length
	o.gameSound = 0
	o.actionType = actionType
	o.deltaTabulated = 0
	return o;
end