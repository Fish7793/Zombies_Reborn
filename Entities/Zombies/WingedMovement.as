#include "UndeadMoveCommon.as";

const f32 turnaroundspeed = 1.3f;
const f32 normalspeed = 1.0f;
const f32 backwardsspeed = 0.8f;

void onInit(CMovement@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag	= "dead";
	
	CBlob@ blob = this.getBlob();
	blob.Tag("winged");
}

void onTick(CMovement@ this)
{
	CBlob@ blob = this.getBlob();

	UndeadMoveVars@ moveVars;
	if (!blob.get("moveVars", @moveVars)) return;
	
	UndeadMoveConsts@ consts = moveVars.consts;

	CShape@ shape = blob.getShape();

	const bool left    = blob.isKeyPressed(key_left);
	const bool right   = blob.isKeyPressed(key_right);
	const bool up      = blob.isKeyPressed(key_up);
	const bool down    = blob.isKeyPressed(key_down);

	Vec2f vel = blob.getVelocity();
	Vec2f pos = blob.getPosition();

	const bool onground = blob.isOnGround() || blob.isOnLadder();

	// gravity scale
	shape.SetGravityScale(0.3f);

	// upwards movement
	if (up)
	{
		Vec2f force = Vec2f(0, -1);
		force *= consts.flySpeed * consts.flyFactor * 10.0f;
		
		blob.AddForce(force);
	}

	// left and right movement

	bool stop = true;
	if (!onground)
	{
		if (blob.hasTag("dont stop til ground"))
			stop = false;
	}
	else
	{
		blob.Untag("dont stop til ground");
	}

	const bool facingleft = blob.isFacingLeft();
	Vec2f flyDirection;

	if (right)
	{
		if (vel.x < -0.1f)    flyDirection.x += turnaroundspeed;
		else if (facingleft)  flyDirection.x += backwardsspeed;
		else                  flyDirection.x += normalspeed;
	}

	if (left)
	{
		if (vel.x > 0.1f)     flyDirection.x -= turnaroundspeed;
		else if (!facingleft) flyDirection.x -= backwardsspeed;
		else                  flyDirection.x -= normalspeed;
	}

	f32 force = 1.0f;
	f32 lim = 0.0f;

	if (left || right)
	{
		lim = consts.flySpeed;
		lim *= consts.flyFactor * Maths::Abs(flyDirection.x);
	}

	Vec2f stop_force;

	const bool greater = vel.x > 0;
	const f32 absx = greater ? vel.x : -vel.x;

	if (absx > lim && stop) //stopping
	{
		stop_force.x -= (absx - lim) * (greater? 1 : -1);
		
		stop_force.x *= 30.0f * consts.stoppingFactor *
					(onground ? consts.stoppingForce : consts.stoppingForceAir);
		
		if (absx > 3.0f)
		{
			const f32 extra = (absx-3.0f);
			const f32 scale = (1.0f/((1+extra) * 2));
			stop_force.x *= scale;
		}
		
		blob.AddForce(stop_force);
	}

	if (absx < lim || left && greater || right && !greater)
	{
		force *= consts.flyFactor * 30.0f;
		if (Maths::Abs(force) > 0.01f)
			blob.AddForce(flyDirection*force);
	}
}
