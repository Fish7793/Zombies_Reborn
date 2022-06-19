// Aphelion \\

#define SERVER_ONLY

#include "UndeadCommon.as";
#include "UndeadTargeting.as";
#include "PressOldKeys.as";

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	blob.set_u8(delay_property, 5 + XORRandom(5));

	if (!blob.exists(target_searchrad_property))
		 blob.set_f32(target_searchrad_property, 512.0f);
	
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("dead")) return;
	
	u8 delay = blob.get_u8(delay_property);
	delay--;
	
	if (delay == 0)
	{
		delay = 5 + XORRandom(10);
		
		// do we have a target?
		CBlob@ target = this.getTarget();
		if (target !is null)
		{
			// check if the target needs to be dropped
			if (ShouldLoseTarget(blob, target))
			{
				this.SetTarget(null);
				return;
			}

			// aim always at enemy
			blob.setAimPos(target.getPosition());

			// chase target
			if ((target.getPosition() - blob.getPosition()).Length() > blob.getRadius() + blob.get_f32("attack distance") / 2)
			{
				CMap@ map = getMap();
				
				PathTo(blob, target.getPosition(), map);

				// scale walls and jump over small blocks
				ScaleObstacles(blob, target.getPosition(), map);

				// destroy any attackable obstructions such as doors
				DestroyAttackableObstructions(this, blob, map);
			}
		}
		else
		{
			GoSomewhere(this, blob); // just walk around looking for a target
		}
	}
	else
	{
		PressOldKeys(blob);
	}

	blob.set_u8(delay_property, delay);
}

const bool ShouldLoseTarget(CBlob@ blob, CBlob@ target)
{
	if (target.hasTag("dead"))
		return true;
	
	if ((target.getPosition() - blob.getPosition()).Length() > blob.get_f32(target_searchrad_property))
		return true;
	
	return !isTargetVisible(blob, target) && XORRandom(30) == 0;
}

void GoSomewhere(CBrain@ this, CBlob@ blob)
{
	CMap@ map = getMap();
	
	// look for a target along the way :)
	SetBestTarget(this, blob, blob.get_f32(target_searchrad_property));

	// get our destination
	Vec2f destination = blob.get_Vec2f(destination_property);
	if (destination == Vec2f_zero || (destination - blob.getPosition()).Length() < 128 || XORRandom(30) == 0)
	{
		NewDestination(blob, map);
		return;
	}
	
	// aim at the destination
	blob.setAimPos(destination);

	// go to our destination
	PathTo(blob, destination, map);

	// scale walls and jump over small blocks
	ScaleObstacles(blob, destination, map);

	// destroy any attackable obstructions such as doors
	DestroyAttackableObstructions(this, blob, map);
}


void PathTo(CBlob@ blob, Vec2f&in destination, CMap@ map)
{
	Vec2f mypos = blob.getPosition();
	
	blob.setKeyPressed(destination.x < mypos.x ? key_left : key_right, true);

	if (destination.y + map.tilesize < mypos.y)
	{
		blob.setKeyPressed(key_up, true);
	}
}

void ScaleObstacles(CBlob@ blob, Vec2f&in destination, CMap@ map)
{
	Vec2f mypos = blob.getPosition();

	// check if touching other zombies
	bool touchingOther = !blob.isOnGround() && blob.getTouchingCount() > 0;
	if (touchingOther)
	{
		touchingOther = false;
		const u8 count = blob.getTouchingCount();
		for (u8 i = 0; i < count; ++i)
		{
			CBlob@ _blob = blob.getTouchingByIndex(i);
			if (_blob.hasTag("undead"))
			{
				touchingOther = true;
				break;
			}
		}
	}

	if (blob.isOnLadder() || blob.isInWater())
	{
		blob.setKeyPressed(destination.y < mypos.y ? key_up : key_down, true);
	}
	else if (touchingOther || blob.isOnWall())
	{
		blob.setKeyPressed(key_up, true);
	}
	else
	{
		const f32 radius = blob.getRadius();
		
		if ((blob.isKeyPressed(key_right) && (map.isTileSolid(mypos + Vec2f(1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)) ||
			(blob.isKeyPressed(key_left) && (map.isTileSolid(mypos + Vec2f(-1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)))
		{
			blob.setKeyPressed(key_up, true);
		}
	}
}

void DestroyAttackableObstructions(CBrain@ this, CBlob@ blob, CMap@ map)
{
	Vec2f col;
	if (map.rayCastSolid(blob.getPosition(), blob.getAimPos(), col))
	{
		CBlob@ obstruction = map.getBlobAtPosition(col);
		if (obstruction is null || (obstruction.hasTag("undead") || obstruction.hasTag("invincible")))
			return;
		
		this.SetTarget(obstruction);
	}
}

void NewDestination(CBlob@ blob, CMap@ map)
{
	const Vec2f dim = map.getMapDimensions();

	Vec2f destination = blob.get_Vec2f(destination_property);
	
	// go somewhere nearby
	if (destination != Vec2f_zero)
	{
		const s32 x = blob.getPosition().x + (XORRandom(dim.x/4) * (XORRandom(2) == 0 ? -1 : 1));
		
		if (x >= dim.x || x <= 0.0f) //stay within map boundaries
			destination = Vec2f_zero;
		else
			destination = Vec2f(x, map.getLandYAtX(x / map.tilesize) * map.tilesize);
	}

	// go somewhere near the center of the map
	if (destination == Vec2f_zero)
	{
		const s32 x = dim.x/4 + XORRandom((dim.x/4)*2);
		destination = Vec2f(x, map.getLandYAtX(x / map.tilesize) * map.tilesize);
	}
	
	// aim at destination
	blob.setAimPos(destination);

	// set destination
	blob.set_Vec2f(destination_property, destination);
}
