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

	this.getCurrentScript().removeIfTag	= "dead";
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
}

void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();

	u8 delay = blob.get_u8(delay_property);
	delay--;

	if (delay == 0)
	{
		delay = 5 + XORRandom(10);

		// do we have a target?
		CBlob@ target = this.getTarget();
		if (target !is null)
		{
			CBlob@ carriedBlob = blob.getCarriedBlob();
			if (carriedBlob !is null && carriedBlob is target)
			{
				if (carriedBlob.hasTag("undead"))
				{
					// take 'em where they need to go
					CBlob@ taxiTarget = carriedBlob.getBrain().getTarget();
					if (taxiTarget !is null)
					{
						const Vec2f mypos = blob.getPosition();
						const Vec2f targetPos = taxiTarget.getPosition();

						if (getXBetween(targetPos, mypos) < 64.0f)
						{
							DetachTarget(this, blob);
						}
						else
						{
							CMap@ map = getMap();
							
							// aim at the destination
							blob.setAimPos(targetPos);

							// fly to our destination
							FlyTo(blob, Vec2f(targetPos.x, getFlyHeight(targetPos.x, map)));

							// stay away from anything any nearby obstructions such as a tower
							DetectForwardObstructions(blob, map);

							// stay above the ground
							StayAboveGroundLevel(blob, map);
						}
					}

					// nope
					else
					{
						DetachTarget(this, blob);
					}
				}
				else
				{
					Vec2f pos = blob.getPosition();
					if (pos.y < 30)
					{
						// bye bye!
						DetachTarget(this, blob);
					}
					else
					{
						FlyTo(blob, Vec2f(blob.getPosition().x, 10));
					}
				}
			}

			// need to pick the target up
			else
			{
				if (ShouldLoseTarget(blob, target))
				{
					DetachTarget(this, blob);
					return;
				}
				
				CMap@ map = getMap();
				
				// chase target
				FlyTo(blob, target.getPosition());

				// aim at the target
				blob.setAimPos(target.getPosition());

				// stay away from anything any nearby obstructions such as a tower
				DetectForwardObstructions(blob, map);
			}
		}
		else
		{
			FlyAround(this, blob); // just fly around looking for a target
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
	if (target.hasTag("dead") || target.isAttached())
		return true;
		
	if ((target.getPosition() - blob.getPosition()).Length() > blob.get_f32(target_searchrad_property))
		return true;
	
	return !isTargetVisible(blob, target);
}

void FlyAround(CBrain@ this, CBlob@ blob)
{
	CMap@ map = getMap();
	
	// look for a target along the way :)
	FindTarget(this, blob, blob.get_f32(target_searchrad_property), map);

	// get our destination
	Vec2f destination = blob.get_Vec2f(destination_property);
	if (destination == Vec2f_zero || (destination - blob.getPosition()).Length() < 128 || XORRandom(30) == 0)
	{
		NewDestination(blob, map);
		return;
	}

	// aim at the destination
	blob.setAimPos(destination);

	// fly to our destination
	FlyTo(blob, destination);

	// stay away from anything any nearby obstructions such as a tower
	DetectForwardObstructions(blob, map);

	// stay above the ground
	StayAboveGroundLevel(blob, map);
}

void FindTarget(CBrain@ this, CBlob@ blob, const f32&in radius, CMap@ map)
{
	Vec2f pos = blob.getPosition();
	
	CBlob@[] nearBlobs;
	map.getBlobsInRadius(pos, radius, @nearBlobs);

	CBlob@ bestCandidate;
	f32 closest_dist = 999999.9f;
	
	const u16 blobsLength = nearBlobs.length;
	for (u16 i = 0; i < blobsLength; ++i)
	{
		CBlob@ candidate = nearBlobs[i];

		const f32 dist = (candidate.getPosition() - pos).Length();
		if (dist < closest_dist && !candidate.isAttached() && !candidate.hasTag("dead") && candidate.hasTag("player") && !candidate.hasTag("winged"))
		{
			if (candidate.hasTag("undead"))
			{
				if (isFriendlyInNeedOfService(candidate, map))
					@bestCandidate = candidate;
			}
			else if (isTargetVisible(blob, candidate)) //players override all undead taxi service
			{
				@bestCandidate = candidate;
				closest_dist = dist;
				break;
			}
		}
	}
	
	if (bestCandidate !is null)
	{
		this.SetTarget(bestCandidate);
	}
}

const bool isFriendlyInNeedOfService(CBlob@ friendly, CMap@ map)
{
	CBlob@ target = friendly.getBrain().getTarget();
	if (target is null) return false;
	
	return getXBetween(target.getPosition(), friendly.getPosition()) > 256 ||
			map.rayCastSolid(friendly.getPosition(), target.getPosition());
}

void FlyTo(CBlob@ blob, Vec2f&in destination)
{
	Vec2f mypos = blob.getPosition();
	const f32 radius = blob.getRadius();

	blob.setKeyPressed(destination.x < mypos.x ? key_left : key_right, true);

	if (destination.y < mypos.y)
		blob.setKeyPressed(key_up, true);
	else if ((blob.isKeyPressed(key_right) && (getMap().isTileSolid(mypos + Vec2f(1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)) ||
		     (blob.isKeyPressed(key_left)  && (getMap().isTileSolid(mypos + Vec2f(-1.3f * radius, radius) * 1.0f) || blob.getShape().vellen < 0.1f)))
		blob.setKeyPressed(key_up, true);
}

void DetectForwardObstructions(CBlob@ blob, CMap@ map)
{
	Vec2f mypos = blob.getPosition();

	const bool obstructed = map.rayCastSolid(mypos, Vec2f(blob.isKeyPressed(key_right) ? mypos.x + 256.0f :
		                                                                                 mypos.x - 256.0f, mypos.y));
	if (obstructed)
	{
		blob.setKeyPressed(key_up, true);
	}
}

void StayAboveGroundLevel(CBlob@ blob, CMap@ map)
{
	if (getFlyHeight(blob.getPosition().x, map) < blob.getPosition().y)
	{
		blob.setKeyPressed(key_up, true);
	}
}

void NewDestination(CBlob@ blob, CMap@ map)
{
	const Vec2f dim = map.getMapDimensions();
	
	s32 x = XORRandom(2) == 0 ? (dim.x / 2 + XORRandom(dim.x / 2)) :
								(dim.x / 2 - XORRandom(dim.x / 2));
	
	x = Maths::Clamp(x, 32, dim.x - 32); //stay within map boundaries

	// set destination
	blob.set_Vec2f(destination_property, Vec2f(x, getFlyHeight(x, map)));
}

const f32 getFlyHeight(const s32&in x, CMap@ map)
{
	return Maths::Max(0.0f, map.getLandYAtX(x / map.tilesize) * map.tilesize - 128.0f);
}

const f32 getXBetween(Vec2f&in point1, Vec2f&in point2)
{
	return Maths::Abs(point1.x - point2.x);
}

void DetachTarget(CBrain@ this, CBlob@ blob)
{
	CBlob@ carried = blob.getCarriedBlob();
	if (carried !is null && carried is this.getTarget())
		carried.server_DetachFrom(blob);

	// remove target
	this.SetTarget(null);
}
