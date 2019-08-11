TILE_SIZE = 64;
Z_HEIGHT = 129;

if libBuild == nil then
	libBuild = {};
	libBuild.__index = libBuild;
end

function libBuild:new(o)
	o = o or {};
	setmetatable(o, libBuild);
	return o;
end

function libBuild:Init()
	libBuild = self;
end

--[[
	Loop through the entire map's grid and generate a table of blocked Vectors
]]
function libBuild:NewGrid()
	BLOCKED_GRID = {};

	local minX = GetWorldMinX();
	local maxX = GetWorldMaxX();
	local minY = GetWorldMinY();
	local maxY = GetWorldMaxY();

	local totalCells = 0;

	for x=minX, maxX, TILE_SIZE do
		for y=minY, maxY, TILE_SIZE do

			local gridX = GridNav:WorldToGridPosX(x);
			local gridY = GridNav:WorldToGridPosY(y);
			local cell = libBuild:VectorToTile( Vector(x, y, Z_HEIGHT) );

			if GridNav:IsTraversable(cell) == false then
				libBuild:BlockTile(x, y);
				totalCells = totalCells + 1;
			end
		end
	end
	print("Generated GridNav: " .. totalCells .. " blocked cells.");
end

--[[
	Block the grid at the given X and Y
]]
function libBuild:BlockTile(x, y)
	if BLOCKED_GRID[x] == nil then
		BLOCKED_GRID[x] = {};
	end

	BLOCKED_GRID[x][y] = true;
end

--[[
	Round the given vector to the nearest tile's centre vector
]]
function libBuild:VectorToTile(vector)
	local tile = vector;
	local halfTile = (TILE_SIZE / 2);
	tile.x = (Round(vector.x / TILE_SIZE) * TILE_SIZE) - halfTile;
	tile.y = (Round(vector.y / TILE_SIZE) * TILE_SIZE) - halfTile;
	return tile;
end

--[[
	Convert vector to the nearest edge vector
]]
function libBuild:VectorToEdge(vector)
	local tile = vector;
	local halfTile = (TILE_SIZE / 2);
	tile.x = (Round(vector.x / TILE_SIZE) * TILE_SIZE);
	tile.y = (Round(vector.y / TILE_SIZE) * TILE_SIZE);
	return tile;
end

--[[
	Returns a list of all tiles within a square range (eg. a building with 128 unit size returns 4 tile vectors)
]] 
function libBuild:GetTilesInRange(vector, span)
	local tiles = {};

	-- how many tiles does the entire span use
	local spanInTiles = math.ceil(span / TILE_SIZE);
	local radius;

	-- divisible by 2? the centre is on a tile edge
	if spanInTiles % 2 == 0 then
		radius = ((spanInTiles / 2) * TILE_SIZE) - (TILE_SIZE / 2);
		vector = libBuild:VectorToEdge(vector);

	-- not divisible by 2? the centre is in the middle of a tile
	else
		radius = ((spanInTiles - 1) / 2) * TILE_SIZE;
		vector = libBuild:VectorToTile(vector);
	end

	local topLeft 	= libBuild:VectorToTile( Vector(vector.x - radius, vector.y + radius, Z_HEIGHT) );
	local topRight 	= libBuild:VectorToTile( Vector(vector.x + radius, vector.y + radius, Z_HEIGHT) );
	local botLeft 	= libBuild:VectorToTile( Vector(vector.x - radius, vector.y - radius, Z_HEIGHT) );
	local botRight 	= libBuild:VectorToTile( Vector(vector.x + radius, vector.y - radius, Z_HEIGHT) );

	for x=topLeft.x, topRight.x, TILE_SIZE do
		for y=botLeft.y, topLeft.y, TILE_SIZE do
			table.insert(tiles, Vector(x, y, Z_HEIGHT) );
		end
	end

	return {
		TILES = tiles,
		CENTRE = vector
	};
end

function libBuild:CreateBuilding(vector, player, params, callback)
	local playerID = player:GetPlayerID();
	local hero = player:GetAssignedHero();
	local team = player:GetTeam();

	local tileList = libBuild:GetTilesInRange( vector, params['HULL_RADIUS'] );
	local tiles = tileList['TILES']
	local vector = tileList['CENTRE'];

	-- block the building's span
	for _,tile in pairs(tiles) do
		libBuild:BlockTile(tile.x, tile.y);

		if DEBUG then
			libBuild:DrawCell(tile, Vector(255, 0, 0), 10);
		end
	end

	-- create the building and assign it to the player
	local building = CreateUnitByName(params['UNIT_NAME'], vector, false, hero, hero, team);
	building:SetControllableByPlayer(playerID, true);
	building:SetTeam(team);
	building:SetOwner(hero);
	building:SetHealth(1);
	building:AddAbility("passive_is_building");

	-- add building to the Treant's list of alive buildings
	local data = TreeTag.Treants[playerID];
	data['BUILDINGS'][building:GetAbsOrigin()] = building;

	-- level down all abilities
	for x=0, building:GetAbilityCount()-1 do
		local ability = building:GetAbilityByIndex(x);
		if ability ~= nil then
			ability:SetLevel(0);
		end
	end

	-- add construction passive to prevent attacking, etc
	building:AddAbility("passive_being_constructed");
	building:FindAbilityByName("passive_being_constructed"):SetLevel(1);

	building._isBuilding = true;
	building._isBuilt = false;
	building._buildTime = params['BUILD_TIME'];
	building._buildElapsed = 0;
	building._buildSize = params['HULL_RADIUS'];
	building._buildValue = params['BUILD_COST'];

	if callback ~= nil then
		building._buildCallback = callback;
	end

	--building:SetRenderColor(255, 0, 128);

	libBuild:PushAwayUnits(vector, params['HULL_RADIUS']);
	libBuild:ConstructBuilding(hero, building);

	return building;
end

function libBuild:ConstructBuilding(caster, target)
	local increment = 0.1;
	
	Timers:CreateTimer(function()
		target._buildElapsed = target._buildElapsed + increment;
		local percent = target._buildElapsed / target._buildTime;
		local hp = math.ceil(percent * target:GetMaxHealth());
		target:ModifyHealth(hp, nil, true, 0);

		if percent >= 1 then
			OnBuildComplete(caster, target);
		else
			if target._buildInterrupted then
	    		target._buildInterrupted = false;
	    	else
	    		return increment;
	    	end
		end    	
    end)

	particle = BasicParticle("particles/econ/events/league_teleport_2014/teleport_start_league_silver.vpcf", target, target:GetAbsOrigin());
	target._buildParticle = particle;
end

function OnBuildComplete(caster, target)
	if target._buildCallback ~= nil then
		target._buildCallback(target);
	end

	DestroyBuildParticle(target, false);

	target:RemoveModifierByName("modifier_being_constructed");
	target:RemoveAbility("passive_being_constructed");

	for i=0, 4 do
		local ability = target:GetAbilityByIndex(i);
		if ability ~= nil then
			ability:SetLevel(1);
		end
	end

	BasicParticle("particles/neutral_fx/roshan_death.vpcf", target, target:GetAbsOrigin(), 3, false);
	BasicParticle("particles/neutral_fx/roshan_spawn.vpcf", target, target:GetAbsOrigin(), 3, false);

	target._isBuilt = true;

	target._buildCallback = nil;
	target._buildInterrupted = nil;
	target._buildElapsed = nil;
	target._buildTime = nil;
end

function DestroyBuildParticle(target, immediate)
	if target._buildParticle ~= nil then
		ParticleManager:DestroyParticle(target._buildParticle, immediate);
		target._buildParticle = nil;
	end
end

function libBuild:RemoveBuilding(building, vector)
	local tileList = libBuild:GetTilesInRange(vector, building._buildSize);
	local tiles = tileList['TILES'];

	--print(#tiles .. " tiles in range");
	for _,tile in pairs(tiles) do
		if BLOCKED_GRID[tile.x][tile.y] ~= nil then
			--print("Removing @ " .. tile.x .. "," .. tile.y);
			BLOCKED_GRID[tile.x][tile.y] = nil;
		end
	end
end

--[[
	Checks whether the given position (and it's span) is blocked
]]
function libBuild:IsValidLocation(vector, size)
	local tiles = libBuild:GetTilesInRange(vector, size);
	tiles = tiles['TILES'];

	for _,tile in pairs(tiles) do
		if BLOCKED_GRID[tile.x][tile.y] ~= nil then
			return false;
		end
	end

	return true;
end

--[[
	Push away any units inside the given vector's radius
]]
function libBuild:PushAwayUnits(vector, radius)
	collisionUnits = FindUnitsInRadius(	
		DOTA_TEAM_GOODGUYS,
		vector, 
		nil, 
		radius, 
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false 
	);

	for _,v in pairs(collisionUnits) do
		FindClearSpaceForUnit(v, v:GetAbsOrigin(), true);
	end
end

--[[
	Draw a single square at the given Vector
]]
function libBuild:DrawCell(centre, rgb, height, duration)
	rgb = rgb or Vector(255, 0, 0);
	duration = duration or 5;
	height = height or 0;
	local z_draw = Z_HEIGHT + height;
	local HALF_TILE = TILE_SIZE / 2;

	DebugDrawLine(Vector(centre.x-HALF_TILE,centre.y+HALF_TILE,z_draw), Vector(centre.x+HALF_TILE,centre.y+HALF_TILE,z_draw), rgb.x, rgb.y, rgb.z, false, duration);
	DebugDrawLine(Vector(centre.x-HALF_TILE,centre.y+HALF_TILE,z_draw), Vector(centre.x-HALF_TILE,centre.y-HALF_TILE,z_draw), rgb.x, rgb.y, rgb.z, false, duration);
	DebugDrawLine(Vector(centre.x-HALF_TILE,centre.y-HALF_TILE,z_draw), Vector(centre.x+HALF_TILE,centre.y-HALF_TILE,z_draw), rgb.x, rgb.y, rgb.z, false, duration);
	DebugDrawLine(Vector(centre.x+HALF_TILE,centre.y-HALF_TILE,z_draw), Vector(centre.x+HALF_TILE,centre.y+HALF_TILE,z_draw), rgb.x, rgb.y, rgb.z, false, duration);
end

--[[
	Draw every blocked cell
]]
function libBuild:DrawAllCells()
	for x,yValues in pairs(BLOCKED_GRID) do
		for y,_ in pairs(yValues) do
			libBuild:DrawCell( Vector(x, y, Z_HEIGHT), Vector(255, 0, 0), 1 );
		end			
	end
end

--[[
	Draw a grid at the centre of the map
]]
function libBuild:DrawGrid()
	local minX = GetWorldMinX();
	local maxX = GetWorldMaxX();
	local minY = GetWorldMinY();
	local maxY = GetWorldMaxY();

	for x=-1000, 1000, TILE_SIZE do
		for y=-1000, 1000, TILE_SIZE do
			local gridX = GridNav:WorldToGridPosX(x);
			local gridY = GridNav:WorldToGridPosY(y);
			local cell = libBuild:VectorToTile( Vector(x, y, Z_HEIGHT) );

			libBuild:DrawCell( cell, Vector(50, 50, 50), 0, 9999 );
		end			
	end
end

libBuild:Init();