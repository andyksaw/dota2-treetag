function OnBuild(keys)
	local point = keys.target_points[1];
	local owner = keys.caster:GetPlayerOwner();
	local playerID = keys.caster:GetPlayerOwnerID();

	local params = {
		BUILD_TIME 	= keys.BuildTime,
		BUILD_COST	= keys.BuildCost,
		UNIT_NAME 	= keys.UnitName,
		HULL_RADIUS = keys.HullRadius
	}

	if libBuild:IsValidLocation(point, 128) then
		DestroyTreesInArea(point, keys.HullRadius, owner:GetTeam());
		local building = libBuild:CreateBuilding(point, owner, params, keys.Callback);
		building.OnDeath = function()
			local pos = building:GetAbsOrigin();
			if pos ~= nil then
				TreeTag.Treants[playerID]['BUILDINGS'][pos] = nil;

				libBuild:RemoveBuilding(building, pos);
				BasicParticle("particles/econ/items/effigies/status_fx_effigies/base_statue_destruction_gold_dire.vpcf", building, building:GetAbsOrigin(), 3, false);
			end

			if building.OnBuildingDeath ~= nil then
				building.OnBuildingDeath(building);
			end
		end

		building.Kill = function(this)
			this.OnDeath();
			this:ForceKill(false);
		end
	else
		-- refund gold
		local gold = PlayerResource:GetGold(playerID);
		PlayerResource:SetGold(playerID, gold + keys.BuildCost, false);
	end
end

function OnBuildFarm(keys)
	keys.Callback = function(building)
		local caster = keys.caster;
		local playerID = caster:GetPlayerOwnerID();

		TreeTag.Treants[playerID]['INCOME'] = TreeTag.Treants[playerID]['INCOME'] + keys.Income;
		building._farmIncome = keys.Income;

		building.OnBuildingDeath = function(building)
			if building._hasDied == nil then
				TreeTag:ModifyIncome(playerID, building, true);
				building._hasDied = true;
			end
		end
	end

	OnBuild(keys);
end

function OnBuildSentry(keys)
	keys.Callback = function(building)
		local caster = keys.caster;
		local playerID = caster:GetPlayerOwnerID();

		local dummy = CreateFlyingDummy(keys.target_points[1], caster:GetPlayerOwner(), keys.DayVision, keys.NightVision);
		building._dummyUnit = dummy;
	end

	OnBuild(keys);
end

function OnBuildBarrack(keys)
	keys.Callback = function(building)
		building._canSetRallypoint = true;
	end

	OnBuild(keys);
end

function OnBuildMine(keys)
	keys.Callback = function(building)
		building._isMine = true;
	end

	OnBuild(keys);
end