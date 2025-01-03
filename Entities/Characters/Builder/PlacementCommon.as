#include "CustomTiles.as"
#include "canGrow.as"
#include "Zombie_TechnologyCommon.as"

const f32 MAX_BUILD_LENGTH = 4.0f;

shared class BlockCursor
{
	Vec2f tileAimPos;
	bool cursorClose;
	bool buildable;
	bool supported;
	bool hasReqs;
	// for gui
	bool rayBlocked;
	bool buildableAtPos;
	Vec2f rayBlockedPos;
	bool blockActive;
	bool blobActive;
	bool sameTileOnBack;
	CBitStream missing;

	BlockCursor()
	{
		blobActive = blockActive = buildableAtPos = rayBlocked = hasReqs = supported = buildable = cursorClose = sameTileOnBack = false;
	}
};

void AddCursor(CBlob@ this)
{
	if (!this.exists("blockCursor"))
	{
		BlockCursor bc;
		this.set("blockCursor", bc);
	}
}

bool canPlaceNextTo(CMap@ map, const Tile &in tile)
{
	return tile.support > 0;
}

bool canPlaceOnTile(CMap@ map, Vec2f p, CBlob@ blob, TileType buildTile, Tile backTile)
{
	if (buildTile == CMap::tile_ground) //dirt can only be placed on existing dirt areas
	{
		const bool damaged_dirt = isTileBetween(backTile.type, CMap::tile_ground_d1, CMap::tile_ground_d0);
		return map.isTileGroundBack(backTile.type) || damaged_dirt;
	}

	const bool solidbacktile = map.isTileSolid(backTile);
	const bool solidbuildtile = isTileSolid(map, buildTile);
	if (!solidbuildtile && solidbacktile)
		return false;
	if ((solidbuildtile || blob !is null) && !solidbacktile)
		return true;
		
	const u8 buildtiletier = solidbuildtile ? getTileTierSolid(buildTile) : getTileTierBackground(buildTile);
	const u8 backtiletier = solidbacktile ? getTileTierSolid(backTile.type) : getTileTierBackground(backTile.type);
	return buildtiletier > backtiletier;
}

bool isBuildableAtPos(CBlob@ this, Vec2f p, TileType buildTile, CBlob@ blob, bool &out sameTile)
{
	CMap@ map = getMap();
	sameTile = false;

	//check height + edge proximity
	if (p.y < 2 * map.tilesize ||
	    p.x < 2 * map.tilesize ||
	    p.x > (map.tilemapwidth - 2.0f)*map.tilesize)
	{
		return false;
	}

	// tilemap check
	const bool buildSolid = (isTileSolid(map, buildTile) || (blob !is null && blob.isCollidable()));
	Vec2f tilespace = map.getTileSpacePosition(p);
	const int offset = map.getTileOffsetFromTileSpace(tilespace);
	Tile backtile = map.getTile(offset);
	Tile left = map.getTile(offset - 1);
	Tile right = map.getTile(offset + 1);
	Tile up = map.getTile(offset - map.tilemapwidth);
	Tile down = map.getTile(offset + map.tilemapwidth);

	if (buildTile > 0 && blob is null && buildTile == backtile.type)
	{
		sameTile = true;
		return false;
	}

	if (map.isTileCollapsing(offset))
	{
		return false;
	}
	
	if (!canPlaceOnTile(map, p, blob, buildTile, backtile))
	{
		return false;
	}

	if (
		!map.isTileBackgroundNonEmpty(backtile) &&      // can put against background
		!(                                              // can put sticking next to something
			canPlaceNextTo(map, left) ||
			canPlaceNextTo(map, right) ||
			canPlaceNextTo(map, up) ||
			canPlaceNextTo(map, down)
		)
	)
	{
		return false;
	}

	// no blocking actors?
	if (blob is null || !blob.hasTag("ignore blocking actors"))
	{
		bool isLadder = false;
		bool isSpikes = false;
		bool isDoor = false;
		bool isPlatform = false;
		bool isSeed = false;

		if (blob !is null)
		{
			const string bname = blob.getName();
			isLadder = bname == "ladder";
			isSpikes = bname == "spikes";
			isDoor = bname == "wooden_door" || bname == "stone_door" || bname == "bridge";
			isPlatform = bname == "wooden_platform";
			isSeed = bname == "seed";
		}

		//repairing blobs
		CBlob@[] blobsAtPos;
		if (blob !is null && map.getBlobsAtPosition(p, @blobsAtPos) && (isDoor || isPlatform))
		{
			for (u16 i = 0; i < blobsAtPos.length; i++)
			{
				CBlob@ blobAtPos = blobsAtPos[i];
				if (blobAtPos.getName() == blob.getName() && 
					blobAtPos.getTeamNum() == blob.getTeamNum() && 
					blobAtPos.getHealth() < blobAtPos.getInitialHealth()) 
				{	
					return true;
				}
			}
		}

		if (!isSeed && !isLadder && (buildSolid || isSpikes || isDoor || isPlatform) && map.getSectorAtPosition(p, "no build") !is null)
		{
			return false;
		}

		CBlob@[] blobsInRadius;
		map.getBlobsInRadius(p, buildSolid ? map.tilesize : 0.0f, @blobsInRadius);
		for (u16 i = 0; i < blobsInRadius.length; i++)
		{
			CBlob@ b = blobsInRadius[i];
			if (b.isAttached() || b is blob) continue;

			if (blob is null && !buildSolid) continue;

			if (b is this && b.getName() == "spikes") continue;

			Vec2f bpos = b.getPosition();

			const bool cantBuild = isBlocking(b);
			const bool buildingOnTeam = isDoor && (b.getTeamNum() == this.getTeamNum() || b.getTeamNum() == 255) && !b.getShape().isStatic() && this !is b;
			const bool ladderBuild = isLadder && !b.getShape().isStatic();

			// cant place on any other blob
			if (!ladderBuild && !buildingOnTeam && cantBuild &&
				!b.hasTag("dead") && !b.hasTag("material") && !b.hasTag("projectile"))
			{
				const f32 angle_decomp = Maths::FMod(Maths::Abs(b.getAngleDegrees()), 180.0f);
				const bool rotated = angle_decomp > 45.0f && angle_decomp < 135.0f;
				const f32 width = rotated ? b.getHeight() : b.getWidth();
				const f32 height = rotated ? b.getWidth() : b.getHeight();
				if ((p.x > bpos.x - width * 0.5f) && (p.x < bpos.x + width * 0.5f)
					&& (p.y > bpos.y - height * 0.5f) && (p.y < bpos.y + height * 0.5f))
				{
					return false;
				}
			}
		}


		if (isSeed)
		{
			return canGrowOnTile(blob, p, map);
		}
	}

	return true;
}

bool isBlocking(CBlob@ blob)
{
	if (blob.hasTag("pushedByDoor") || blob.hasTag("scenary") || blob.hasTag("projectile"))
		return false;

	return blob.isCollidable() || blob.getShape().isStatic();
}

void DestroyScenary(Vec2f tl, Vec2f br)
{
	if (!isServer()) return;

	CBlob@[] overlapping;
	getMap().getBlobsInBox(tl, br, @overlapping);
	for (u16 i = 0; i < overlapping.length; i++)
	{
		CBlob@ blob = overlapping[i];
		if (blob.getName() == "bush")
		{
			blob.server_Die();
		}
	}
}

void SetTileAimpos(CBlob@ this, BlockCursor@ bc)
{
	// calculate tile mouse pos
	Vec2f pos = this.getPosition();
	Vec2f aimpos = this.getAimPos();
	Vec2f mouseNorm = aimpos - pos;
	f32 mouseLen = mouseNorm.Length();
	const f32 maxLen = MAX_BUILD_LENGTH;
	mouseNorm /= mouseLen;

	if (mouseLen > maxLen * getMap().tilesize)
	{
		f32 d = maxLen * getMap().tilesize;
		Vec2f p = pos + Vec2f(d * mouseNorm.x, d * mouseNorm.y);
		p = getMap().getTileSpacePosition(p);
		bc.tileAimPos = getMap().getTileWorldPosition(p);
	}
	else
	{
		bc.tileAimPos = getMap().getTileSpacePosition(aimpos);
		bc.tileAimPos = getMap().getTileWorldPosition(bc.tileAimPos);
	}

	bc.cursorClose = (mouseLen < getMaxBuildDistance(this));
}

u32 getCurrentBuildDelay(CBlob@ this)
{
	if (getRules().get_u16("day_number") < 2 || hasTech(Tech::Architecture))
		return this.get_u32("warmup build delay");
	return this.get_u32("build delay");
}

f32 getMaxBuildDistance(CBlob@ this)
{
	return (MAX_BUILD_LENGTH + 0.51f) * getMap().tilesize;
}

void SetupBuildDelay(CBlob@ this)
{
	this.set_u32("build time", 0);
	this.set_u32("build delay", 7);
	this.set_u32("warmup build delay", 4);
}

bool isBuildDelayed(CBlob@ this)
{
	return (getGameTime() <= this.get_u32("build time"));
}

void SetBuildDelay(CBlob@ this)
{
	SetBuildDelay(this, this.get_u32("build delay"));
}

void SetBuildDelay(CBlob@ this, uint time)
{
	this.set_u32("build time", getGameTime() + time);
}

bool isBuildRayBlocked(Vec2f pos, Vec2f target, Vec2f &out point)
{
	CMap@ map = getMap();

	Vec2f vector = target - pos;
	vector.Normalize();
	target -= vector * map.tilesize;

	const f32 halfsize = map.tilesize * 0.5f;

	return map.rayCastSolid(pos + Vec2f(0, halfsize), target, point) &&
		   map.rayCastSolid(pos + Vec2f(halfsize, 0), target, point) &&
		   map.rayCastSolid(pos + Vec2f(0, -halfsize), target, point) &&
		   map.rayCastSolid(pos + Vec2f(-halfsize, 0), target, point);
}

bool inNoBuildZone(CMap@ map, Vec2f here, TileType buildTile)
{
	return inNoBuildZone(null, map, here, buildTile);
}

bool inNoBuildZone(CBlob@ blob, CMap@ map, Vec2f here, TileType buildTile)
{
	bool isLadder = false;
	bool isSpikes = false;
	if (blob !is null)
	{
		const string bname = blob.getName();
		isLadder = bname == "ladder";
		isSpikes = bname == "spikes";
	}

	const bool buildSolid = (map.isTileSolid(buildTile) || (blob !is null && blob.isCollidable()));

	return (!isLadder && (buildSolid || isSpikes) && map.getSectorAtPosition(here, "no build") !is null);
}

// This has to exist due to an engine issue where CMap.hasTileSolidBlobs() returns false if the blobtile was placed in the previous tick
// and an engine issue where CMap.getBlobsFromTile() crashes the server 
// wonderful game
bool fakeHasTileSolidBlobs(Vec2f cursorPos)
{
	CMap@ map = getMap();
	CBlob@[] blobs;
	
	map.getBlobsAtPosition(cursorPos + Vec2f(1, 1), blobs);

	for (int i = 0; i < blobs.length; i++)
	{
		if (isRepairable(blobs[i])) return true;
	}

	return false;
}

bool isRepairable(CBlob@ blob)
{
	// the getHealth() check is here because apparently a blob isn't null for a tick (?) after being destroyed
	if (blob is null || blob.getHealth() <= 0) return false;

	if (blob.hasTag("door") || blob.getName() == "wooden_platform" || blob.getName() == "bridge")
	{
		return true;
	}

	return false;
}
