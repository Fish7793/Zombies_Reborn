// Zombie Fortress targeting for undeads on the ground

#define SERVER_ONLY;

void onInit(CRules@ this)
{
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	this.set_u16("undead count", 0);
	this.Sync("undead count", true);
	
	u16[] netids;
	this.set("target netids", netids);
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (blob.hasTag("undead"))
	{
		this.add_u16("undead count", 1);
		this.Sync("undead count", true);
	}
	else if (canTarget(blob))
	{
		//add new target
		this.push("target netids", blob.getNetworkID());
	}
}

void onBlobDie(CRules@ this, CBlob@ blob)
{
	if (blob.hasTag("undead"))
	{
		this.sub_u16("undead count", 1);
		this.Sync("undead count", true);
	}
	else if (canTarget(blob))
	{
		//remove this as target
		u16[]@ netids;
		if (!this.get("target netids", @netids)) return;
		
		const int index = netids.find(blob.getNetworkID());
		if (index > -1)
		{
			netids.erase(index);
		}
	}
}

const bool canTarget(CBlob@ blob)
{
	return blob.hasTag("player");
}
