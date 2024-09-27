// Zombie Fortress generic rules

#define SERVER_ONLY

#include "ZombieSpawnPos.as";

u8 days_to_survive = 15;     //days players must survive to win, as well as the power creep of zombies
f32 game_difficulty = 2.5f;  //zombie spawnrate multiplier
u16 maximum_zombies = 400;   //maximum amount of zombies that can be on the map at once
bool infinite_days = false;  //decide if the game ends at days_to_survive

const u8 GAME_WON = 5;
const u8 nextmap_seconds = 15;
u8 seconds_till_nextmap = nextmap_seconds;

Random@ _rng = Random(XORRandom(100000));
Noise@ _spawn_noise = Noise(_rng.Next());

void onInit(CRules@ this)
{
	ConfigFile cfg;
	if (cfg.loadFile("Zombie_Vars.cfg"))
	{
		//edit these vars in Zombie_Vars.cfg
		days_to_survive = cfg.exists("days_to_survive") ? cfg.read_u8("days_to_survive")  : 15;
		game_difficulty = cfg.exists("game_difficulty") ? cfg.read_f32("game_difficulty") : 2.5f;
		maximum_zombies = cfg.exists("maximum_zombies") ? cfg.read_u16("maximum_zombies") : 400;
		infinite_days   = cfg.exists("infinite_days")   ? cfg.read_bool("infinite_days")  : false;
	}
	
	Reset(this);
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void Reset(CRules@ this)
{
	this.set_u16("day_number", 1);
	this.Sync("day_number", true);

	seconds_till_nextmap = nextmap_seconds;
	this.SetCurrentState(GAME);
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	//set new player to survivors
	player.server_setTeamNum(0);
}

void onTick(CRules@ this)
{
	CMap@ map = getMap();
	
	const u32 gameTime = getGameTime();
	const f32 day_cycle = this.daycycle_speed * 60.0f;
	const f32 dayNumber = (gameTime / getTicksASecond() / day_cycle);
	
	//spawn zombies at night-time
	const f32 ramp = 0.045f;
	const f32 amp = 1.05f;
	const f32 diff_amp = (getPlayerCount() * 0.35f + game_difficulty + 1.0f);

	const f32 difficulty = days_to_survive / (amp * diff_amp * Maths::Log((amp * Maths::Pow(dayNumber, 3) + 1.0f) * diff_amp - getPlayerCount() / 2.0f) - (2 * diff_amp - 2));
	// const f32 difficulty = days_to_survive / (dayNumber * (game_difficulty + (getPlayerCount() * 0.7f - 1)));

	const u32 spawnRate = Maths::Clamp(getTicksASecond() * difficulty * 1.05f, 1, 1000);
	
	if (dayNumber > 1 && gameTime % spawnRate == 0)
	{
		spawnZombie(this, map, dayNumber + 1.0f, difficulty);
	}
	
	if (gameTime % getTicksASecond() == 0) //once every second
	{
		checkDayChange(this, dayNumber + 1.0f);
		
		onGameEnd(this);
	}

	if (gameTime % 1000 == 0) 
	{
		print("Game Time:  \t" + gameTime + "\tDay: " + (dayNumber + 1.0f));
		print("Difficulty: \t" + difficulty);
		print("Spawn Rate: \t" + 30.0f / spawnRate 					+ "/s\t" + (60.0f * 30.0f) / spawnRate + "/m");
		print("Alternate:  \t" + _spawn_noise.Fractal(getGameTime() / 4000.0f, 0));
		print("Diff Factor:\t" + (1.0 / (0.5f + difficulty * 5.0f)) + "  \t" + (1.0 / (0.5f + difficulty * 10.0f)));
	}
}

// Spawn various zombie blobs on the map
void spawnZombie(CRules@ this, CMap@ map, const u8&in dayNumber, const f32&in difficulty)
{
	if (map.getDayTime() > 0.8f || map.getDayTime() < 0.1f)
	{
		if (maximum_zombies != 999 && this.get_u16("undead count") >= maximum_zombies) return;
		
		const f32 difficulty_factor_weight = 0.5f;
		const f32 difficulty_factor  = (1.0 / (0.5f + difficulty * 5.0f));
		const f32 difficulty_factor2 = (1.0 / (0.5f + difficulty * 10.0f));
		const f32 r  = (XORRandom(10000) / 10000.0f) * (1 - difficulty_factor_weight) + difficulty_factor * difficulty_factor_weight;
		const f32 alternate = _spawn_noise.Fractal(getGameTime() / 4000.0f, 0);

		const f32 r2 = (XORRandom(10000) / 10000.0f) * (1 - difficulty_factor_weight) + difficulty_factor2 * difficulty_factor_weight;

		u8 count = 1;
		string blobname = "skeleton";
		
		if (difficulty_factor > 0.4 && alternate > 0.7 && dayNumber > 5) {
			if 		(r2 >= 0.9875)  blobname ="sedgwick";
			else if (r2 >= 0.975)  blobname ="skelepede";
			else if (r2 >= 0.70)  blobname = "wraith";
			else if (r2 >= 0.60)  blobname = "greg";
			else if (r2 >= 0.50)  blobname = "zombieknight";
		}
		else 
		{
			if (r >= 0.995 && dayNumber > 5) 
			{
				if (XORRandom(6) == 0) 
				{
					blobname = "sedgwick";
					count = 1 + XORRandom(1);
				}
				else 
				{
					blobname ="skelepede";
				}
			}
			else if (r >= 0.95)  blobname = "greg";
			else if (r >= 0.87)  blobname = "wraith";
			else if (r >= 0.71) 
			{ 
				if (XORRandom(4) == 0) 
				{
					blobname = "zombie";
					count = 1 + XORRandom(2);
				}
				else 
				{
					blobname = "zombieknight"; 
				}
			}
			else if (r >= 0.35)  
			{
				if (XORRandom(4) == 0) 
				{
					blobname = "skeleton";
					count = 1 + XORRandom(4);
				}
				else 
				{
					blobname = "zombie"; 
				}
			} 
		}
		
		for (u8 i = 0; i < count; i++) 
		{
			server_CreateBlob(blobname, -1, getZombieSpawnPos(map));
		}
	}
}

// Protocols when the day changes
void checkDayChange(CRules@ this, const u8&in dayNumber)
{
	//has the day changed?
	if (dayNumber != this.get_u16("day_number"))
	{
		//end game if we reached the last day
		if (dayNumber >= days_to_survive && !infinite_days)
		{
			this.SetCurrentState(GAME_WON);
			setTimedGlobalMessage(this, 2, nextmap_seconds);
		}
		else
		{
			setTimedGlobalMessage(this, 0, 10);
		}
		
		this.set_u16("day_number", dayNumber);
		this.Sync("day_number", true);
	}
}

// Set a global message with a timer to remove itself
void setTimedGlobalMessage(CRules@ this, const u8&in index, const u8&in seconds)
{
	//consult Zombie_GlobalMessages.as
	this.set_u8("global_message_index", index);
	this.set_u8("global_message_timer", seconds);
	this.Sync("global_message_index", true);
	this.Sync("global_message_timer", true);
}

// Protocols for when the game ends
void onGameEnd(CRules@ this)
{
	const u8 GAME_STATE = this.getCurrentState();
	
	//timer till next map
	if (GAME_STATE == GAME_OVER || GAME_STATE == GAME_WON)
	{
		seconds_till_nextmap--;
		if (seconds_till_nextmap == 0)
		{
			LoadNextMap();
		}
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	checkGameEnded(this, player);
}

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ attacker, u8 customData)
{
	checkGameEnded(this, victim);
}

void checkGameEnded(CRules@ this, CPlayer@ player)
{
	if (this.get_u16("day_number") < 2) return;
	
	//have all players died?
	if (!isGameLost(player)) return;
	
	this.SetCurrentState(GAME_OVER);
	setTimedGlobalMessage(this, 1, nextmap_seconds);
}

// Check if we lost the game
const bool isGameLost(CPlayer@ player)
{
	bool noAlivePlayers = true;
	
	const u8 playerCount = getPlayerCount();
	for (u8 i = 0; i < playerCount; i++)
	{
		CPlayer@ ply = getPlayer(i);
		if (ply is null || ply is player) continue;
		
		CBlob@ plyBlob = ply.getBlob();
		if (plyBlob !is null && !plyBlob.hasTag("undead") && !plyBlob.hasTag("dead"))
		{
			noAlivePlayers = false;
			break;
		}
	}
	
	return noAlivePlayers;
}
