public PlVers:__version =
{
	version = 5,
	filevers = "1.4.6",
	date = "09/21/2017",
	time = "20:24:45"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
public Extension:__ext_sdkhooks =
{
	name = "sdkhooks",
	file = "sdkhooks.ext",
	autoload = 1,
	required = 1,
};
public Extension:__ext_sdktools =
{
	name = "SDKTools",
	file = "sdktools.ext",
	autoload = 1,
	required = 1,
};
new g_iVelocity;
new Handle:l4d_tank_throw_junk;
new Handle:Kill_junk_time;
new rock[66];
new tank;
new L4D2Version;
public Plugin:myinfo =
{
	name = "tank's throw junk",
	description = "tank's throw junk",
	author = "End Of The World 2012",
	version = "1.0",
	url = "https://www.facebook.com/groups/left4deadVN/"
};
new bool:gamestart;
public __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	VerifyCoreVersion();
	return 0;
}

Float:operator*(Float:,_:)(Float:oper1, oper2)
{
	return oper1 * float(oper2);
}

bool:operator>(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) > 0;
}

bool:operator<(Float:,Float:)(Float:oper1, Float:oper2)
{
	return FloatCompare(oper1, oper2) < 0;
}

ScaleVector(Float:vec[3], Float:scale)
{
	new var1 = vec;
	var1[0] = var1[0] * scale;
	vec[1] *= scale;
	vec[2] *= scale;
	return 0;
}

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

public OnPluginStart()
{
	l4d_tank_throw_junk = CreateConVar("l4d_tank_throw_junk", "100.0", "tank throws junk[0.0, 100.0]", 262144, false, 0.0, false, 0.0);
	Kill_junk_time = CreateConVar("kill_junk_time", "60", "time remove junk", 262144, false, 0.0, false, 0.0);
	HookEvent("round_end", RoundEnd, EventHookMode:1);
	HookEvent("finale_win", RoundEnd, EventHookMode:1);
	HookEvent("mission_lost", RoundEnd, EventHookMode:1);
	HookEvent("map_transition", RoundEnd, EventHookMode:1);
	HookEvent("tank_spawn", RoundStart, EventHookMode:1);
	HookEvent("ability_use", ability_use, EventHookMode:1);
	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	decl String:GameName[16];
	GetGameFolderName(GameName, 16);
	if (StrEqual(GameName, "left4dead2", false))
	{
		L4D2Version = 1;
	}
	else
	{
		L4D2Version = 0;
	}
	gamestart = true;
	return 0;
}

public OnMapStart()
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
	return 0;
}

public Action:RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	gamestart = true;
	tank = 0;
	return Action:0;
}

public Action:RoundEnd(Handle:event, String:name[], bool:dontBroadcast)
{
	gamestart = false;
	return Action:0;
}

public Action:ability_use(Handle:event, String:name[], bool:dontBroadcast)
{
	decl String:s[32];
	GetEventString(event, "ability", s, 32);
	if (StrEqual(s, "ability_throw", true))
	{
		tank = GetClientOfUserId(GetEventInt(event, "userid"));
	}
	return Action:0;
}

public OnEntityCreated(entity, String:classname[])
{
	if (!gamestart)
	{
		return 0;
	}
	new var1;
	if (tank > 0 && IsValidEdict(entity) && StrEqual(classname, "tank_rock", true) && GetEntProp(entity, PropType:0, "m_iTeamNum", 4, 0) >= 0)
	{
		rock[tank] = entity;
		if (GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_tank_throw_junk))
		{
			CreateTimer(0.01, TraceRock, tank, 1);
		}
		tank = 0;
	}
	return 0;
}

public Action:KillJunk(Handle:timer, any:junk)
{
	RemoveEdict(junk);
	return Action:0;
}

public Action:TraceRock(Handle:timer, any:thetank)
{
	new Float:velocity[3] = 0.0;
	new ent = rock[thetank];
	new var1;
	if (gamestart && IsValidEdict(ent))
	{
		GetEntDataVector(ent, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity, false);
		if (v > 500.0)
		{
			new Float:pos[3] = 0.0;
			new Float:ang[3] = 0.0;
			ang[0] = GetRandomFloat(-50.0, 60.0);
			ang[1] = GetRandomFloat(-50.0, 50.0);
			ang[2] = GetRandomFloat(-50.0, 60.0);
			GetEntPropVector(ent, PropType:0, "m_vecOrigin", pos, 0);
			if (StuckCheck(ent, pos))
			{
				new junk = CreateEntityByName("prop_physics", -1);
				new si = CreateSI(thetank);
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
					default:
					{
					}
				}
				DispatchSpawn(junk);
				CreateTimer(GetConVarFloat(Kill_junk_time), KillJunk, junk, 0);
				RemoveEdict(ent);
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed * 1);
				TeleportEntity(junk, pos, NULL_VECTOR, velocity);
				if (L4D2Version)
				{
					ShowParticle(pos, "electrical_arc_01_system", 3.0);
				}
			}
			return Action:4;
		}
		return Action:0;
	}
	return Action:4;
}

CreateSI(thetank)
{
	decl bool:IsPalyerSI[66];
	new selected;
	new i = 1;
	while (i <= MaxClients)
	{
		IsPalyerSI[i] = false;
		new var1;
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (GetClientTeam(i) == 3)
			{
				IsPalyerSI[i] = true;
			}
		}
		i++;
	}
	selected = thetank;
	if (!selected)
	{
		decl andidate[66];
		new index;
		new i = 1;
		while (i <= MaxClients)
		{
			new var2;
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
			{
				if (!IsPalyerSI[i])
				{
					selected = i;
					new var3;
					if (selected && index > 0)
					{
						selected = andidate[GetRandomInt(0, index + -1)];
					}
				}
				index++;
				andidate[index] = i;
			}
			i++;
		}
		new var3;
		if (selected && index > 0)
		{
			selected = andidate[GetRandomInt(0, index + -1)];
		}
	}
	return selected;
}

bool:StuckCheck(ent, Float:pos[3])
{
	new Float:vAngles[3] = 0.0;
	new Float:vOrigin[3] = 0.0;
	vAngles[2] = 1.0;
	GetVectorAngles(vAngles, vAngles);
	new Handle:trace = TR_TraceRayFilterEx(pos, vAngles, 33570827, RayType:1, TraceRayDontHitSelf, ent);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(vOrigin, trace);
		new Float:dis = GetVectorDistance(vOrigin, pos, false);
		if (dis > 100.0)
		{
			return true;
		}
	}
	return false;
}

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system", -1);
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		CreateTimer(time, DeleteParticles, particle, 2);
	}
	return 0;
}

public PrecacheParticle(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system", -1);
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		CreateTimer(0.01, DeleteParticles, particle, 2);
	}
	return 0;
}

public Action:DeleteParticles(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		decl String:classname[64];
		GetEdictClassname(particle, classname, 64);
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop", -1, -1, 0);
			AcceptEntityInput(particle, "kill", -1, -1, 0);
			RemoveEdict(particle);
		}
	}
	return Action:0;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if (data == entity)
	{
		return false;
	}
	return true;
}

