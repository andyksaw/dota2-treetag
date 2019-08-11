--[[
	TREE TAG
	Based on the original WC3 mod

	@creator	Andy <http://steamcommunity.com/profiles/76561197976666257/>

	@created 	23rd August, 2014
	@updated	19th of July, 2015
]]


DEBUG = false;
PARTICLES = {};

if TreeTag == nil then
	TreeTag = class({});
end

function TreeTag:InitGameMode(particles)
	TreeTag.PARTICLES = particles;

	TreeTag.Treants = {};
	TreeTag.Infernals = {};
	TreeTag.TreantsAlive = 0;
	TreeTag.Jail = Entities:FindByName(nil, "treant_jail");
	TreeTag.CutTrees = {};

	TreeTag.cfgBaseIncome = 1;
	TreeTag.cfgGoldTick = 5;
	TreeTag.cfgStartGold = 40;
	TreeTag.cfgEndTime = 30;
	TreeTag.cfgFriendlyFire = false;

	TreeTag:SetGameRules();
	TreeTag:SubscribeListeners();
	TreeTag:RegisterCommands();
end

function TreeTag:SetGameRules()
	Mode = GameRules:GetGameModeEntity();

	Mode:SetThink( "OnThink", self, 1 );

	Mode:SetTopBarTeamValuesOverride( true );
	Mode:SetTopBarTeamValuesVisible( false );
	Mode:SetLoseGoldOnDeath( false );
	Mode:SetCameraDistanceOverride( 1650 );
	Mode:SetFogOfWarDisabled( false );

	GameRules:SetGoldPerTick( 0 );
	GameRules:SetHeroSelectionTime( 0.0 );
	GameRules:SetCustomGameEndDelay( 0 );
	GameRules:SetCustomVictoryMessageDuration( 10 );
	GameRules:SetHideKillMessageHeaders( false );
	GameRules:SetUseUniversalShopMode( false );
	GameRules:SetHeroRespawnEnabled( false );

	Mode:SetBuybackEnabled( false );
	Mode:SetCustomHeroMaxLevel( 50 );

	local xp_table = require('xp');
	Mode:SetCustomXPRequiredToReachNextLevel( xp_table );
	GameRules:SetUseCustomHeroXPValues( true );
	Mode:SetUseCustomHeroLevels(true);

	GameRules:SetTreeRegrowTime(540);
	GameRules:SetPreGameTime( 30 );
end

function TreeTag:SubscribeListeners()
	ListenToGameEvent("game_rules_state_change", 	Dynamic_Wrap( TreeTag, 'OnGameRulesStateChange' ), self);
	ListenToGameEvent('entity_hurt', 				Dynamic_Wrap( TreeTag, 'OnEntityHurt'), self);
	ListenToGameEvent('entity_killed', 				Dynamic_Wrap( TreeTag, 'OnEntityKilled'), self);

	-- script filters
	Mode:SetExecuteOrderFilter( Dynamic_Wrap( TreeTag, "ExecuteOrderFilter" ), self );
end

function TreeTag:RegisterCommands()
	Convars:RegisterCommand("dev_spawn", function(c, team)
	    local player = PlayerResource:GetPlayer(0);
		if team == nil or team == 2 then
	    	local unit = CreateUnitByName("npc_dota_hero_doom_bringer", player:GetAssignedHero():GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS);
	    	unit:SetControllableByPlayer(player:GetPlayerID(), true);
		else
			local unit = CreateUnitByName("npc_dota_hero_treant", player:GetAssignedHero():GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS);
		end
	end, "Create enemy next to player", 0);

	Convars:RegisterCommand("dev_shake", function()
		ScreenShake(Vector(0,0,0), 10, 10, 3, 150, 0, true);
	end, "Shake the screen", 0);

	Convars:RegisterCommand("dev_blocked", function()
		libBuild:DrawAllCells();
	end, "Draw blocked cells", 0);

	Convars:RegisterCommand("dev_grid", function()
		libBuild:DrawGrid();
	end, "Draw all cells", 0);
end

function TreeTag:CheckInfernalVictory()
	if DEBUG then
		return;
	end

	if TreeTag.TreantsAlive <= 0 then
		GameRules:SetSafeToLeave(true);
		GameRules:SetGameWinner( DOTA_TEAM_BADGUYS );
	end

	-- extra check just in case
	local any_alive = false;
	for _,treant in pairs(TreeTag.Treants) do
		if treant.ALIVE then
			any_alive = true;
			break;
		end
	end

	if any_alive == false then
		GameRules:SetSafeToLeave(true);
		GameRules:SetGameWinner( DOTA_TEAM_BADGUYS );
	end
end

function TreeTag:TreantVictory()
	GameRules:SetSafeToLeave(true);
	GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS );
end

function TreeTag:ModifyIncome(playerID, building, subtractGold)
	TreeTag.Treants[playerID]['INCOME'] = TreeTag.Treants[playerID]['INCOME'] - building._farmIncome;
end

--[[
	Setup tables for every connected player based on team
]]
function TreeTag:SetupAllPlayers()
	for id=0, DOTA_MAX_TEAM_PLAYERS do
		local player = PlayerResource:GetPlayer(id);
		if player ~= nil then
			local team = player:GetTeam();
			local hero = player:GetAssignedHero();

			-- treants
			if team == DOTA_TEAM_GOODGUYS then
				TreeTag.Treants[id] = {
					ALIVE = true,
					INCOME = 0,
					BUILDINGS = {}
				};
				TreeTag.TreantsAlive = TreeTag.TreantsAlive + 1;
				PlayerResource:SetGold(id, TreeTag.cfgStartGold, false);
				CreateFlyingDummy(TreeTag.Jail:GetAbsOrigin(), player, 850, 675);
				TreeTag:GiveBuildMenu(player:GetAssignedHero());
				hero:NotifyWearablesOfModelChange(true);
				hero:RemoveNoDraw();
				hero:SetAbilityPoints(0);
				for i=0, hero:GetAbilityCount()-1 do
			        local ability = hero:GetAbilityByIndex(i);
			        if ability ~= nil then
			        	ability:SetLevel(1);
			        end
			    end

			-- infernals
			elseif team == DOTA_TEAM_BADGUYS then
				TreeTag.Infernals[id] = {
					ALIVE = true
				};
				Timers:CreateTimer({
				    endTime = 25,
				    callback = function()
				    	CreateFlyingDummy(TreeTag.Jail:GetAbsOrigin(), player, 1200, 950);
				    end
				});
				hero:AddAbility("ability_unselectable_hero");
				hero:NotifyWearablesOfModelChange(false);
				hero:AddNoDraw();
				local item = CreateItem("item_infernal_wards", hero:GetOwner(), hero:GetOwner());
				hero:AddItem(item);
				hero:SetAbilityPoints(1);
				hero:FindAbilityByName("ability_infernal_smash_trees"):SetLevel(1);
				hero:FindAbilityByName("ability_unselectable_hero"):SetLevel(1);
			end

		    -- set music
		    --player:SetMusicStatus(DOTA_MUSIC_STATUS_BATTLE, 1);
		end

	end
end

function TreeTag:GiveBuildMenu(hero)
	local player = hero:GetOwner();

	local items = {
		CreateItem("item_build_resource_structure", player, player),
		CreateItem("item_build_sentry_tower", player, player);
		CreateItem("item_build_basic_tree", player, player),
		CreateItem("item_build_armored_tree", player, player),
		CreateItem("item_build_barracks", player, player),
		CreateItem("item_next_menu_set", player, player),
	}

	for k,item in pairs(items) do
		hero:AddItem(item);
	end
end