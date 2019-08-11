function OnNextSet(keys)
	local caster = keys.caster;
	local player = caster:GetOwner();

	-- clear items in inventory
	for i=0, 6 do
		local item = caster:GetItemInSlot(i);
		caster:RemoveItem(item);
	end

	-- add next set of build items
	local items = {
		CreateItem("item_build_tree_of_life", player, player),
		CreateItem("item_build_library", player, player),
		CreateItem("item_build_invisible_tree", player, player),
		CreateItem("item_build_infernal_killer", player, player),
		CreateItem("", player, player),
		CreateItem("item_prev_menu_set", player, player),
	}

	for k,item in pairs(items) do
		caster:AddItem(item);
	end
end

function OnPrevSet(keys)
	local caster = keys.caster;
	local player = caster:GetOwner();

	-- clear items in inventory
	for i=0, 6 do
		local item = caster:GetItemInSlot(i);
		caster:RemoveItem(item);
	end

	-- add next set of build items
	local items = {
		CreateItem("item_build_resource_structure", player, player),
		CreateItem("item_build_sentry_tower", player, player);
		CreateItem("item_build_basic_tree", player, player),
		CreateItem("item_build_armored_tree", player, player),
		CreateItem("item_build_barracks", player, player),
		CreateItem("item_next_menu_set", player, player),
	}

	for k,item in pairs(items) do
		caster:AddItem(item);
	end
end