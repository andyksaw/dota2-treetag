function TreeTag:OnThink()
	if GameRules:IsGamePaused() == true then
        return 1
    end
end

function TreeTag:OnGameRulesStateChange()
	local newState = GameRules:State_Get()

	if newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		TreeTag:OnSetupVotingPhase();

	elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
		TreeTag:OnSetupPreGamePhase();		
	
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		TreeTag:OnSetupStartPhase();
	end
end

function TreeTag:OnSetupVotingPhase()
	GameRules:SetCustomGameSetupRemainingTime( 10000 );

	GameRules:SetCustomGameTeamMaxPlayers(2, 6); -- RADIANCE
	GameRules:SetCustomGameTeamMaxPlayers(3, 2); -- DIRE
	
	libBuild:NewGrid();

	for i=4, 13 do
		GameRules:SetCustomGameTeamMaxPlayers(i, 0);
	end

	-- spawn a WISP hero for every connected player
	Timers:CreateTimer({
	    endTime = 1,
	    callback = function()
	    	for id=0, DOTA_MAX_TEAM_PLAYERS do
	    		local player = PlayerResource:GetPlayer(id);
	    		if player ~= nil then
	    			local hero = CreateHeroForPlayer("npc_dota_hero_wisp", player);
				  	hero:SetControllableByPlayer(id, true);
					hero:SetPlayerID(id);
					hero:AddNoDraw();
	    		end
	    	end
		end
	})
end

function TreeTag:OnSetupPreGamePhase()
	-- swap out all wisps for a proper hero based on team choice
	for k,hero in pairs( Entities:FindAllByClassname( "npc_dota_hero_wisp" )) do
        local id = hero:GetPlayerOwner():GetPlayerID();
        local team = PlayerResource:GetPlayer(id):GetTeam();

        if team == DOTA_TEAM_GOODGUYS then
        	PlayerResource:ReplaceHeroWith(id, "npc_dota_hero_treant", 0, 0);
        elseif team == DOTA_TEAM_BADGUYS then
			PlayerResource:ReplaceHeroWith(id, "npc_dota_hero_doom_bringer", 0, 0);
        end
    end 

    -- setup quest timer
    CreateQuest("InfernalSpawnTimer", 30);

    BroadcastMessage("Infernals arrive in 30 seconds", 10);

	ShowGenericPopup( 
		"#popup_title", 
		"#popup_desc",
		"", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN
	);

    TreeTag:SetupAllPlayers();

    -- gold tick timer
    Timers:CreateTimer(function()
	   	TreeTag:OnGoldTick();
	   	return TreeTag.cfgGoldTick;
	end);
end

function TreeTag:OnSetupStartPhase()
    BroadcastMessage("Infernals have arrived!", 3);

    CreateQuest("GameTimer", TreeTag.cfgEndTime * 60);
    
	-- make infernals spawn
	local infernal;
	for k,hero in pairs( Entities:FindAllByClassname( "npc_dota_hero_doom_bringer" )) do
        hero:RemoveAbility("ability_unselectable_hero");
        hero:RemoveModifierByName("modifier_unselectable_hero");
        hero:RemoveNoDraw();

        infernal = hero;
    	BasicParticle("particles/units/heroes/hero_warlock/warlock_rain_of_chaos.vpcf", infernal, infernal:GetAbsOrigin(), 8, false);
    end 

    -- create infernal spawn particle
    if infernal ~= nil then
	    BasicParticle("particles/units/heroes/hero_warlock/warlock_rain_of_chaos_start.vpcf", infernal, TreeTag.Jail:GetAbsOrigin(), 8, false);
	    EmitSoundOn("Hero_Warlock.RainOfChaos_buildup", infernal);
	    EmitSoundOn("Hero_Warlock.RainOfChaos", infernal);
	end

	-- treant win timer
	Timers:CreateTimer({
	    endTime = TreeTag.cfgEndTime * 60,
	    callback = function()
	    	TreeTag:TreantVictory();
	    end
	})
end

function TreeTag:OnEntityHurt(keys)
	local victim = EntIndexToHScript(keys.entindex_killed);

	if keys.entindex_attacker == nil then
		return;
	end
	local attacker = EntIndexToHScript(keys.entindex_attacker);

	-- kill treant on damage
	--if victim:GetUnitName() == "npc_dota_hero_treant" then
	--	victim:Kill(nil, attacker);

	-- kill dead treant on damage
	if victim:GetUnitName() == "npc_dota_hero_wisp" then
		victim:Kill(nil, nil);
	end
end

function TreeTag:OnEntityKilled(keys)
	local killed = EntIndexToHScript(keys.entindex_killed);

	if killed.OnDeath ~= nil then
		killed.OnDeath();
	end

	if killed._dummyUnit ~= nil then
		killed._dummyUnit:ForceKill(false);
	end

	if keys.entindex_attacker == nil then
		return;
	end
	local attacker = EntIndexToHScript(keys.entindex_attacker);

	-- change treant into dead ent 
	if killed:GetUnitName() == "npc_dota_hero_treant" then
		local playerID = killed:GetPlayerOwnerID();
		killed:SetAbsOrigin( TreeTag.Jail:GetAbsOrigin() );

		-- destroy all buildings belonging to this treant
		local buildings = TreeTag.Treants[playerID]['BUILDINGS'];
		if buildings ~= nil then
			for k,building in pairs(buildings) do
				building.Kill(building);
			end
		end
		TreeTag.Treants[playerID]['BUILDINGS'] = {};
		TreeTag.Treants[playerID]['INCOME'] = 0;
		TreeTag.Treants[playerID]['ALIVE'] = false;

		local gold = PlayerResource:GetGold(playerID);
		PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_wisp", gold, 0);

		Timers:CreateTimer(function()
			local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero();
			for i=0, 3 do
				local ability = hero:GetAbilityByIndex(i);
				if ability ~= nil then
					ability:SetLevel(1);
				end
			end
			hero:NotifyWearablesOfModelChange(false);
		end);

		TreeTag.TreantsAlive = TreeTag.TreantsAlive - 1;
		TreeTag:CheckInfernalVictory();

	-- bring dead treant back to life
	elseif killed:GetUnitName() == "npc_dota_hero_wisp" then
		local playerID = killed:GetPlayerOwnerID();
		local gold = PlayerResource:GetGold(playerID);
		PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_treant", gold, 0);

		Timers:CreateTimer(function()
			local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero();
			for i=0, 3 do
				local ability = hero:GetAbilityByIndex(i);
				if ability ~= nil then
					ability:SetLevel(1);
				end
			end
			TreeTag:GiveBuildMenu(hero);
		end);

		TreeTag.Treants[playerID]['ALIVE'] = true;
		TreeTag.TreantsAlive = TreeTag.TreantsAlive + 1;
	end
end

function TreeTag:OnGoldTick()
	for id,data in pairs(TreeTag.Treants) do
		if data['ALIVE'] then
			local income = TreeTag.cfgBaseIncome + data['INCOME'];
			local gold = PlayerResource:GetGold(id);
			PlayerResource:SetGold(id, gold + income, false);

			local player = PlayerResource:GetPlayer(id);
			local hero = player:GetAssignedHero();
			local particle = ParticleManager:CreateParticleForPlayer(PARTICLES['gold_tick'],  PATTACH_OVERHEAD_FOLLOW, hero, player)
			ParticleManager:SetParticleControl(particle, 1, hero:GetAbsOrigin());
			Timers:CreateTimer({
				endTime = 3,
				callback = function()
					ParticleManager:DestroyParticle(particle, false);
				end
			});

			PopupGoldGain(hero, income);
		end
	end

	-- don't give Infernals income during pre-game
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		for id,data in pairs(TreeTag.Infernals) do
			if data['ALIVE'] then
				local income = 2;
				local gold = PlayerResource:GetGold(id);
				PlayerResource:SetGold(id, gold + income, false);

				local player = PlayerResource:GetPlayer(id);
				local hero = player:GetAssignedHero();
				local particle = ParticleManager:CreateParticleForPlayer("particles/units/heroes/hero_alchemist/alchemist_lasthit_coins.vpcf",  PATTACH_OVERHEAD_FOLLOW, hero, player)
				ParticleManager:SetParticleControl(particle, 1, hero:GetAbsOrigin());
				Timers:CreateTimer({
					endTime = 3,
					callback = function()
						ParticleManager:DestroyParticle(particle, false);
					end
				});

				PopupGoldGain(hero, income);
			end
		end
	end
end

function TreeTag:ExecuteOrderFilter( filterTable )	

	local order_type 	= filterTable['order_type'];
	local target 		= filterTable['entindex_target'];
	local playerID 		= filterTable['issuer_player_id_const'];
	local player 		= PlayerResource:GetPlayer(playerID);
	local units 		= filterTable['units'];

	-- count number of units and buildings;
	local unitsSelected = 0;
	local buildingsSelected = 0;
	local unitList = {};
	local firstUnit;

	for _,unit in pairs(units) do
		unitEnt = EntIndexToHScript(unit);
		if unitEnt._isBuilding then
			buildingsSelected = buildingsSelected + 1;
		else
			unitsSelected = unitsSelected + 1;
			table.insert(unitList, unit);
		end

		if firstUnit == nil then
			firstUnit = unitEnt;
		end
	end

	-- remove buildings from any group orders
	if unitsSelected > 0 and buildingsSelected > 0 then
		units = unitList;
	end

	-- use mine
	if target ~= nil and target ~= -1 then
		targetEnt = EntIndexToHScript(target);
		if targetEnt ~= nil and targetEnt._isMine then

			for _,unit in pairs(units) do
				unit = EntIndexToHScript(unit);
				unit:AddAbility("ability_use_mine");
				local ability = unit:FindAbilityByName("ability_use_mine");
				ability:SetLevel(1);
				ability:EndCooldown();
				unit:SetCursorCastTarget(targetEnt);
				ability:OnSpellStart();
				unit:RemoveAbility("ability_use_mine");
			end
			return true;

		end
	end

	if firstUnit then
		if firstUnit._canSetRallypoint then
			if firstUnit._isBuilt == false then
				return false;
			end

			-- prevent [Stop] and [Hold Position] cancelling unit production	
			if order_type == DOTA_UNIT_ORDER_HOLD_POSITION or order_type == DOTA_UNIT_ORDER_STOP then
				return false;
			end

			-- set rallypoint
			if order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION or order_type == DOTA_UNIT_ORDER_MOVE_TO_TARGET then
				local x = filterTable["position_x"];
				local y = filterTable["position_y"];
				local z = filterTable["position_z"];
				local pos = Vector(x, y, z);
		
				local ability = firstUnit:FindAbilityByName("ability_set_rallypoint");
				firstUnit:SetCursorPosition(pos);
				firstUnit:CastAbilityOnPosition(pos, ability, firstUnit:GetPlayerOwnerID());
				--ExecuteOrderFromTable({ UnitIndex = units["0"], OrderType = DOTA_UNIT_ORDER_CAST_POSITION, AbilityIndex = abilityIndex, Position = pos, Queue = false})

				EmitSoundOnClient("DOTA_Item.SentryWard.Activate", firstUnit:GetPlayerOwner());
				return false;
			end
		end
	end

		
	--TODO: change deadent targeted attack order into move order
	return true;
end