#include <sourcemod>

public Plugin myinfo =
{
	name		= "插件重载",
	author		= "Owwkmmidraem",
	description = "允许管理员重载所有插件并重启地图",
	version		= "1.0",


}

public void
	OnPluginStart()
{
	RegAdminCmd("sm_reload", Command_Reload, ADMFLAG_GENERIC, "重新加载所有插件并重新启动地图");
}

public Action Command_Reload(int client, int args)
{
	ServerCommand("sm plugins unload_all");
	ServerCommand("sm plugins refresh");

	CreateTimer(5.0, Timer_ChangeLevel, _, TIMER_FLAG_NO_MAPCHANGE);
	PrintToChatAll("插件重载完成，5秒后重启地图");

	return Plugin_Handled;
}

public Action Timer_ChangeLevel(Handle timer)
{
	char map[64];
	GetCurrentMap(map, sizeof(map));
	ServerCommand("changelevel %s", map);

	return Plugin_Handled;
}