--[[
	Queue the specified unit for production
]]
function OnQueue(keys)
	local caster = keys.caster;

	if caster._unitQueue == nil then
		caster._unitQueue = {}
		caster._isProcessing = false;

		caster.ProcessQueue = function()
			local queue = caster._unitQueue;

			if Count(queue) > 0 then
				caster._isProcessing = true;

				local currentOrder;
				for k,v in pairs(queue) do
					currentOrder = v;
					table.remove(queue, k);
					break;
				end
				caster._uqUnitName 	= currentOrder['UNIT_NAME'];
				caster._uqUnitCount = currentOrder['UNIT_COUNT'];
				caster._uqBuildTime = currentOrder['BUILD_TIME'];

				-- add and use channeling ability as an indicator of build time
				caster:AddAbility("ability_unit_channel_timer");
				local ability = caster:FindAbilityByName("ability_unit_channel_timer");
				ability:SetLevel(caster._uqBuildTime);

				Timers:CreateTimer({
					endTime = 0.03,
					callback = function() 
						caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID());
					end
				});	
				
			else
				caster._isProcessing = false;
			end
		end
	end

	-- queue unit build order
	local order = {
		UNIT_NAME 	= keys.UnitName,
		UNIT_COUNT 	= keys.UnitCount,
		BUILD_TIME 	= keys.BuildTime
	};
	table.insert(caster._unitQueue, order);

	-- begin processing queue if not doing so already
	if caster._isProcessing == false then
		caster.ProcessQueue();
	end

end