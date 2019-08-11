require('libs/timers');
require('libs/building');
require('libs/utility');
require('libs/floating_text');
require('tree_tag');
require('events');

PARTICLES = {
	gold_tick 			= "particles/units/heroes/hero_alchemist/alchemist_lasthit_coins.vpcf",
	ability_tree_area 	= "particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf",
	ability_tree_regrow = "particles/units/heroes/hero_pugna/pugna_netherblast.vpcf",
	ability_blink		= "particles/units/heroes/hero_antimage/antimage_blink_start.vpcf",
	ability_nuke_slam	= "particles/neutral_fx/roshan_slam.vpcf",
	ability_nuke_end	= "particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf",
	ability_fire_breath = "particles/hw_fx/hw_rosh_fire_blast.vpcf",
	ability_entangle	= "particles/econ/items/lone_druid/lone_druid_cauldron/lone_druid_bear_entangle_body_cauldron.vpcf",
	build_complete		= "particles/neutral_fx/roshan_death.vpcf",
	build_complete2		= "particles/neutral_fx/roshan_spawn.vpcf",
	build_death			= "particles/econ/items/effigies/status_fx_effigies/base_statue_destruction_gold_dire.vpcf",
	build_upgrade		= "particles/econ/items/tinker/boots_of_travel/teleport_end_bots.vpcf",
	build_construct		= "particles/econ/events/league_teleport_2014/teleport_start_league_silver.vpcf",
	build_sell			= "particles/econ/courier/courier_mechjaw/mechjaw_death_coins.vpcf",
	unit_queue			= "particles/items2_fx/teleport_end_tube.vpcf",
	unit_created		= "particles/econ/items/meepo/meepo_diggers_divining_rod/meepo_divining_rod_poof_end.vpcf",
	unit_set_rally		= "particles/units/heroes/hero_kunkka/kunkka_spell_x_spot.vpcf",
	item_telescope		= "particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf",
	infernal_spawn		= "particles/units/heroes/hero_warlock/warlock_rain_of_chaos.vpcf",
	infernal_spawn_rock = "particles/units/heroes/hero_warlock/warlock_rain_of_chaos_start.vpcf",
	infernal_spirit 	= "particles/units/heroes/hero_invoker/invoker_forge_spirit_ambient.vpcf",
	jail_relocate		= "particles/units/heroes/hero_wisp/wisp_relocate_teleport.vpcf",
};

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]

	PrecacheUnitByNameSync("npc_dota_hero_treant", context);	-- alive treant
	PrecacheUnitByNameSync("npc_dota_hero_wisp", context);	-- no team picked/dead treant
	PrecacheUnitByNameSync("npc_dota_hero_doom_bringer", context);	-- infernal

	PrecacheUnitByNameSync("npc_dota_hero_naga_siren", context); -- ##### quick hack until I track down Naga siren's ensnare particle

	PrecacheUnitByNameSync("npc_dota_creature_morph", context);
	PrecacheUnitByNameSync("npc_dota_creature_fighter", context);
	PrecacheUnitByNameSync("npc_dota_creature_builder", context);
	PrecacheUnitByNameSync("npc_dota_creature_infernal_spirit", context);
	PrecacheUnitByNameSync("npc_observer_ward", context);

	PrecacheUnitByNameSync("npc_building_resource_structure", context);
	PrecacheUnitByNameSync("npc_building_sentry_tower", context);
	PrecacheUnitByNameSync("npc_building_basic_tree", context);
	PrecacheUnitByNameSync("npc_building_armored_tree", context);
	PrecacheUnitByNameSync("npc_building_barracks", context);
	PrecacheUnitByNameSync("npc_building_tree_of_life", context);
	PrecacheUnitByNameSync("npc_building_library", context);
	PrecacheUnitByNameSync("npc_building_invisible_tree", context);
	PrecacheUnitByNameSync("npc_building_infernal_killer", context);
	PrecacheUnitByNameSync("npc_building_mine", context);

	PrecacheItemByNameSync("item_infernal_wards", context);
	PrecacheItemByNameSync("item_gem", context);
	PrecacheItemByNameSync("item_infernal_boots_of_force", context);
	PrecacheItemByNameSync("item_infernal_boots_of_phase", context);
	PrecacheItemByNameSync("item_telescope", context);

	local x = 0;
	for _,particle in pairs(PARTICLES) do
		PrecacheResource("particle", particle, context); 
		x = x + 1;
	end
	print("Precached " .. x .. " particles");

	--PrecacheResource("particle", "particles/units/heroes/hero_pugna/pugna_life_give.vpcf", context); -- building to treant, build tether

	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_lina.vsndevts", context);
	PrecacheResource("soundfile", "sounds/weapons/hero/furion/wrath_damage.vsnd", context);
	PrecacheResource("soundfile", "DOTA_Item.SentryWard.Activate", context);
	PrecacheResource("soundfile", "DOTA_Item.ForceStaff.Activate", context);
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_warlock.vsndevts", context);
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_phoenix.vsndevts", context);
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts", context);
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_doombringer.vsndevts", context);
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = TreeTag();
	GameRules.AddonTemplate:InitGameMode(PARTICLES);
end