// SourcePawn

/*			Changelog
 *	29/08/2014 Version 1.0 – Released.
 *	28/12/2016 Version 1.1 – Changed syntax.
 *	22/10/2017 Version 1.2 – Fixed jump after vomitjar-boost and after "TakeOverBot" event.
 *	08/11/2018 Version 1.2.1 – Fixed incorrect flags initializing; some changes in syntax.
 *	25/04/2019 Version 1.2.2 – Command "sm_autobhop" has fixed for localplayer in order to work properly in console.
 *	16/11/2019 Version 1.3.2 – At the moment CBasePlayer specific flags (or rather FL_ONGROUND bit) aren't longer fixed, by reason
 *							player's jump animation during boost is incorrect (it's must be ACT_RUN_CROUCH_* sequence always!);
 *							removed 'm_nWaterLevel' check (we cannot swim in this game anyway) to avoid problems with jumping
 *							on some deep water maps.
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VER "1.3.2"

Handle g_AutoBhop = null;

public Plugin myinfo =
{
	name		= "Auto Bunnyhop",
	author		= "noa1mbot",
	description = "Allows jump easier.",
	version		= PLUGIN_VER,
	url			= "https://steamcommunity.com/groups/noa1mbot"


}

//============================================================
//============================================================

public void
	OnPluginStart()
{
	g_AutoBhop = CreateKeyValues("AutoBhop");

	RegConsoleCmd("sm_bhop", Cmd_Autobhop, "启动bhop");
}

public Action Cmd_Autobhop(int client, int args)
{
	if (client == 0)
	{
		if (!IsDedicatedServer())
			client = 1;
		else
			return Plugin_Handled;
	}

	if (!bCheckClientAccess(client) || !IsClientInGame(client))
	{
		PrintToChat(client, "\x05[失败] \x04你无权使用指令");
		return Plugin_Handled;
	}

	char steamId[64];
	GetClientAuthId(client, AuthId_Steam3, steamId, sizeof(steamId));

	// bool autoBhop = KvGetNum(g_AutoBhop, steamId, 0) != 0;
	// autoBhop = !autoBhop;
	// KvSetNum(g_AutoBhop, steamId, autoBhop ? 1 : 0);

	bool autoBhop = KvGetNum(g_AutoBhop, steamId, 0);
	autoBhop	  = !autoBhop;
	KvSetNum(g_AutoBhop, steamId, autoBhop);

	if (autoBhop)
		PrintToChat(client, "[SM] AutoBhop ON");
	else
		PrintToChat(client, "[SM] AutoBhop OFF");

	return Plugin_Handled;
}

bool bCheckClientAccess(int client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		return true;
	return false;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	char steamId[64];
	GetClientAuthId(client, AuthId_Steam3, steamId, sizeof(steamId));

	bool autoBhop = KvGetNum(g_AutoBhop, steamId, 0);

	if (autoBhop && IsPlayerAlive(client))
	{
		if (buttons & IN_JUMP)
		{
			if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
			{
				if (GetEntityMoveType(client) != MOVETYPE_LADDER)
				{
					buttons &= ~IN_JUMP;
				}
			}
		}
	}
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client) || !bCheckClientAccess(client))
		return;

	char steamId[64];
	GetClientAuthId(client, AuthId_Steam3, steamId, sizeof(steamId));
	KvSetNum(g_AutoBhop, steamId, 1);

	PrintToChat(client, "\x05[SM] \x04AutoBhop ON");
}