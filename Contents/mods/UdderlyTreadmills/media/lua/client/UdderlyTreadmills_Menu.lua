--[[
		Originally Developed by FC4RICA
		Working Treadmill 41.68+
		Modified by UdderlyEvelyn for 41.71 with different features
]]

UdderlyTreadmills_Menu = {};

-- Add use option to treadmill context menus
UdderlyTreadmills_Menu.doBuildMenu = function(player, context, worldobjects)

	local treadmillObject = nil
	local treadmillGroupName = nil

	for _,object in ipairs(worldobjects) do
		local square = object:getSquare()
		if not square then
			--print(do not find world object)
			return
		end
		
		for i=1,square:getObjects():size() do
			local thisObject = square:getObjects():get(i-1)
			
			if thisObject:getSprite() then

				local properties = thisObject:getSprite():getProperties()

				if properties == nil then
					--print(do not find world object properties)
					return
				end
				
				local groupName = nil
				local customName = nil
				
				if properties:Is("GroupName") or properties:Is("CustomName") then
					groupName = properties:Val("GroupName")
					customName = properties:Val("CustomName")
					--print("Sprite GroupName: " .. groupName)
					--print("Sprite CustomName: " .. customName)
				end
				
				-- For Treadmill, Custom Name = "Hamster Wheel" and the Group Name is more specific
				-- Normally can use only Group Name for treadmill but I use it to be able change object easily
				if customName == "Hamster Wheel" then
					if not ((SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier) or thisObject:getSquare():haveElectricity()) then
						getSpecificPlayer(player):Say("Doesn't work well without power.")
						return
					end
					
					treadmillObject = thisObject
					treadmillGroupName = groupName
					break
				end -- if customName == "Hamster Wheel"
			end -- if ThisObject:getSprite()
		end -- for i=1,square:getObjects...
		--if treadmillObject then break	
	end
	
	if not treadmillObject then 
		--print("this isn't treadmill")
		return 
	end
	
	local soundFile = nil
	local contextMenu = nil
	local actionType = nil
	
	if treadmillGroupName == "Human" then
		local spriteName = treadmillObject:getSprite():getName()
		--print("Sprite Name: " .. spriteName)
		
		if (spriteName == "recreational_sports_01_28") or (spriteName == "recreational_sports_01_31") or (spriteName == "recreational_sports_01_37") or (spriteName == "recreational_sports_01_38") then
			--print("Ignore running wheel side of treadmill")
			return 
		end
		
		soundFile = "UdderlyTreadmills_Run"
		soundEnd = "UdderlyTreadmills_End"
		contextMenu = "Use Treadmill"
		actionType = "TreadmillRunning"
		--print("Found usable treadmill")
	else
		return
	end
	
	context:addOption(getText(contextMenu),
					  worldobjects,
					  UdderlyTreadmills_Menu.onUseTreadmill,
					  getSpecificPlayer(player),
					  treadmillObject,
					  soundFile,
					  soundEnd,
					  actionType,
					  SandboxVars.UdderlyTreadmills.UsageTime)
	
end

UdderlyTreadmills_Menu.walkToFront = function(thisPlayer, treadmillObject)
	local frontSquare = nil
	local controllerSquare = nil
	local spriteName = treadmillObject:getSprite():getName()
	if not spriteName then
		return false
	end

	local properties = treadmillObject:getSprite():getProperties()
	
	local facing = nil
	if properties:Is("Facing") then
		facing = properties:Val("Facing")
	else
		return
	end
	
	if facing == "S" then
		frontSquare = treadmillObject:getSquare():getS()
	elseif facing == "E" then
		frontSquare = treadmillObject:getSquare():getE()
	elseif facing == "W" then
		frontSquare = treadmillObject:getSquare():getW()
	elseif facing == "N" then
		frontSquare = treadmillObject:getSquare():getN()
	end
	
	if not frontSquare then
		return false
	end
	
	if not controllerSquare then
		controllerSquare = treadmillObject:getSquare()
	end

	-- If the front of treadmill square is valid, walk to it
	if AdjacentFreeTileFinder.privTrySquare(controllerSquare, frontSquare) then
		ISTimedActionQueue.add(ISWalkToTimedAction:new(thisPlayer, frontSquare))
		return true
	end
	return false
end


-- Do when player selects option to use a treadmill (from context menu)
UdderlyTreadmills_Menu.onUseTreadmill = function(worldobjects, player, machine, soundFile, soundEnd, actionType, length)
	if UdderlyTreadmills_Menu.walkToFront(player, machine) then
	
		player:setPrimaryHandItem(nil)
		player:setSecondaryHandItem(nil)
		
		if player:getMoodles():getMoodleLevel(MoodleType.Endurance) > 2 then
			player:Say("Too exhausted to use")
			return
		end
		if player:getMoodles():getMoodleLevel(MoodleType.HeavyLoad) > 2 then
			player:Say("Too heavy to use")
			return
		end
		if player:getMoodles():getMoodleLevel(MoodleType.Pain) > 3 then
			player:Say("Too much pain to use")
			return
		end
		ISTimedActionQueue.add(UdderlyTreadmills_UseTreadmill:new(player, machine, soundFile, soundEnd, actionType, length))
	end
end

Events.OnPreFillWorldObjectContextMenu.Add(UdderlyTreadmills_Menu.doBuildMenu);
