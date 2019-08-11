function OnSmashArea(keys)
	local point = keys.target_points[1];
	local caster = keys.caster;

	local trees = GridNav:GetAllTreesAroundPoint(point, keys.Radius - 10, true);
	for _,tree in pairs(trees) do
		TreeTag.CutTrees[tree:GetAbsOrigin()] = tree;
		tree:CutDown(caster:GetTeam());
	end

	AddFOWViewer(keys.caster:GetOwner():GetTeam(), point, keys.Radius, 3, false);

	BasicParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", keys.caster, keys.target_points[1], 3, true);
	EmitSoundOn("Ability.LightStrikeArray", keys.caster);
	EmitSoundOn("sounds/weapons/hero/furion/wrath_damage.vsnd", keys.caster);
end

function OnSmashAreaAtCaster(keys)
	local caster = keys.caster;
	local point = caster:GetAbsOrigin();

	local trees = GridNav:GetAllTreesAroundPoint(point, keys.Radius, true);
	for _,tree in pairs(trees) do
		TreeTag.CutTrees[tree:GetAbsOrigin()] = tree;
		tree:CutDown(caster:GetTeam());
	end
end

function OnRegrowArea(keys)
	local point = keys.target_points[1];
	local caster = keys.caster;

	local regrown = 0;
	for position,tree in pairs(TreeTag.CutTrees) do
		local distance = point - position;
		if distance:Length2D() <= keys.Radius then
			tree:GrowBack();
			TreeTag.CutTrees[position] = nil;
			regrown = regrown + 1;
		end
	end
	if regrown == 0 then
		keys.ability:EndCooldown();
	end

	BasicParticle(TreeTag.PARTICLES['ability_tree_regrow'], caster, point, 3, false, {0});

	AddFOWViewer(caster:GetOwner():GetTeam(), point, keys.Radius, 3, false);
end

function OnSmashSingle(keys)
	local target = keys.target;

	TreeTag.CutTrees[target:GetAbsOrigin()] = target;
	target:CutDown(keys.caster:GetTeam());
end