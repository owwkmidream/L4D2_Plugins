#include <sourcemod>
#include <sdkhooks>
#include <dhooks>
#pragma newdecls required

Handle			 l4dTankThrowJunk, killJunkTime;
int				 g_iVelocity, rock[MAXPLAYERS + 1], tank;
bool			 isGameStarted, L4D2Version;

#define TEAM_INFECTED  3
#define PLUGIN_VERSION "1.0.1"

public Plugin pluginInfo = {
	name		= "坦克丢铁",
	description = "tank's throw junk",
	author		= "Owwkmidram",
	version		= PLUGIN_VERSION,
	url			= "N/A"
};

public void OnPluginStart()
{
	CreateConVar("l4d_tankjunk_version", PLUGIN_VERSION, "坦克丢铁的版本.", FCVAR_NOTIFY | FCVAR_SPONLY | FCVAR_REPLICATED);
	SetConVarString(FindConVar("l4d_multislots_version"), PLUGIN_VERSION);

	l4dTankThrowJunk = CreateConVar("l4d_tank_throw_junk", "33.0", "丢铁的概率[0.0, 100.0]", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	killJunkTime	 = CreateConVar("kill_junk_time", "60", "铁移除时间", FCVAR_NOTIFY, true, 0.0, false, 0.0);

	HookEvent("round_end", OnRoundEnd);
	HookEvent("finale_win", OnRoundEnd);
	HookEvent("mission_lost", OnRoundEnd);
	HookEvent("map_transition", OnRoundEnd);
	HookEvent("tank_spawn", OnRoundStart);
	HookEvent("ability_use", OnAbilityUse);

	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");

	char gameName[16];
	GetGameFolderName(gameName, 16);
	L4D2Version = StrEqual(gameName, "left4dead2", false);
	
	isGameStarted = true;

	AutoExecConfig(true, "l4d_tankjunk");
}

public void OnMapStart()
{
	PrecacheModel("models/props_vehicles/cara_82hatchback.mdl", false);
	PrecacheModel("models/props_junk/dumpster_2.mdl", false);
	PrecacheModel("models/props/cs_assault/forklift.mdl", false);
	PrecacheModel("models/props_vehicles/police_car_rural.mdl", false);
	PrecacheModel("models/props_foliage/tree_trunk_fallen.mdl", false);
	PrecacheModel("models/props_vehicles/cara_84sedan.mdl", false);
	PrecacheModel("models/props_fairgrounds/bumpercar.mdl", false);
	PrecacheModel("models/props_unique/airport/atlas_break_ball.mdl", false);
	PrecacheModel("models/props_vehicles/utility_truck.mdl", false);
	if (L4D2Version)
	{
		PrecacheParticle("electrical_arc_01_system");
	}
	return;
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	isGameStarted = true;
	tank		  = 0;
	return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	isGameStarted = false;
	return Plugin_Continue;
}

public Action OnAbilityUse(Handle event, const char[] name, bool dontBroadcast)
{
	char ability[32];
	GetEventString(event, "ability", ability, sizeof ability);
	if (StrEqual(ability, "ability_throw", true))
	{
		tank = GetClientOfUserId(GetEventInt(event, "userid"));
	}
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!isGameStarted)
	{
		return;
	}
	if (tank > 0 && IsValidEdict(entity) && StrEqual(classname, "tank_rock", true) && GetEntProp(entity, Prop_Send, "m_iTeamNum") >= 0)
	{
		rock[tank] = entity;
		if (GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4dTankThrowJunk))
		{
			CreateTimer(0.01, traceRock, tank, TIMER_REPEAT);
		}
		tank = 0;
	}
	return;
}

public Action killJunk(Handle timer, any junk)
{
	RemoveEdict(junk);
	return Plugin_Continue;
}

public Action traceRock(Handle timer, any theTank)
{
	float velocity[3];
	int	  ent = rock[theTank];
	if (isGameStarted && IsValidEdict(ent))
	{
		GetEntDataVector(ent, g_iVelocity, velocity);
		float v = GetVectorLength(velocity);
		if (v > 500.0)
		{
			float pos[3];
			float ang[3];
			ang[0] = GetRandomFloat(-50.0, 60.0);
			ang[1] = GetRandomFloat(-50.0, 50.0);
			ang[2] = GetRandomFloat(-50.0, 60.0);
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			if (isStuck(ent, pos))
			{
				int junk = CreateEntityByName("prop_physics");
				int si	 = CreateSpecialInfected(theTank);
				switch (GetRandomInt(1, 10))
				{
					case 1:
					{
						DispatchKeyValue(junk, "model", "models/props_vehicles/cara_82hatchback.mdl");
					}
					case 2:
					{
						DispatchKeyValue(junk, "model", "models/props_junk/dumpster_2.mdl");
					}
					case 3:
					{
						DispatchKeyValue(junk, "model", "models/props/cs_assault/forklift.mdl");
					}
					case 4:
					{
						DispatchKeyValue(junk, "model", "models/props_vehicles/police_car_rural.mdl");
					}
					case 5:
					{
						DispatchKeyValue(junk, "model", "models/props_foliage/tree_trunk_fallen.mdl");
					}
					case 6:
					{
						DispatchKeyValue(junk, "model", "models/props_vehicles/cara_84sedan.mdl");
					}
					case 7:
					{
						DispatchKeyValue(junk, "model", "models/props_fairgrounds/bumpercar.mdl");
					}
					case 8:
					{
						DispatchKeyValue(junk, "model", "models/props_unique/airport/atlas_break_ball.mdl");
					}
					case 9:
					{
						DispatchKeyValue(junk, "model", "models/props_vehicles/utility_truck.mdl");
					}
					case 10:
					{
						TeleportEntity(si, pos, NULL_VECTOR, velocity);
					}
				}
				DispatchSpawn(junk);
				CreateTimer(GetConVarFloat(killJunkTime), killJunk, junk);
				RemoveEdict(ent);
				NormalizeVector(velocity, velocity);
				float speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1);
				TeleportEntity(junk, pos, NULL_VECTOR, velocity);
				if (L4D2Version)
				{
					showParticle(pos, "electrical_arc_01_system", 3.0);
				}
			}
			return Plugin_Stop;
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

// 2. 在`createSpecialInfected`函数中，我假设如果没有选中的玩家，那么应该从候选者中随机选择一个。
// 原始代码在这里有一些冗余，我假设这并不是必要的，所以我将其简化了。

int CreateSpecialInfected(int theTank)
{
	int selected = theTank;

	if (!selected)
	{
		int candidate[MAXPLAYERS + 1], index;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == TEAM_INFECTED)
			{
				candidate[index++] = i;
			}
		}
		if (index > 0)
		{
			selected = candidate[GetRandomInt(0, index - 1)];
		}
	}
	return selected;
}

bool isStuck(int ent, float pos[3])
{
	float vAngles[3], vOrigin[3];

	vAngles[2] = 1.0;
	GetVectorAngles(vAngles, vAngles);
	Handle trace = TR_TraceRayFilterEx(pos, vAngles, MASK_SOLID, RayType_Infinite, traceRayDontHitSelf, ent);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(vOrigin, trace);
		float dis = GetVectorDistance(vOrigin, pos);
		if (dis > 100.0)
		{
			return true;
		}
	}
	return false;
}

public void showParticle(float pos[3], const char[] particleName, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particleName);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		CreateTimer(time, deleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
	return;
}

public void PrecacheParticle(const char[] particleName)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particleName);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		CreateTimer(0.01, deleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
	return;
}

public Action deleteParticles(Handle timer, any particle)
{
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof classname);
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	}
	return Plugin_Continue;
}

public bool traceRayDontHitSelf(int entity, int mask, any data)
{
	return data != entity;
}
