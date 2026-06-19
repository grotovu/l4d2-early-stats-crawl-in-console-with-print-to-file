/*
*	Match Stats (For console use and print to file)
*/

#define PLUGIN_VERSION		"1.0.0"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY

#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define ZC_SMOKER			1
#define ZC_BOOMER			2
#define ZC_HUNTER			3
#define ZC_SPITTER			4
#define ZC_JOCKEY			5
#define ZC_CHARGER			6
#define ZC_TANK				8

// ====================================================================================================
//					STRUCTS
// ====================================================================================================
enum struct MatchStats
{
	int ciKills;
	int siKills;
	int tankDmg;
	
	int deaths;
	int incaps;
	int damageTaken;
	int friendlyFire;
	
	int medkitsUsed;
	int pillsUsed;
	int adrenalineUsed;
	int defibsUsed;
	
	int heals;       
	int revives;
	int protections; 
	
	int pipeBombs;
	int molotovs;
	int bileJars;
	
	int meleeKills;
	int bulletsFired;
	int bulletHits;
	int headshots;
	
	int hunters;
	int smokers;
	int boomers;
	int chargers;
	int spitters;
	int jockeys;
	int tanksKilled;
	
	int witchDmg;
	int witchDisturbs;
	int witchesKilled;

	void Reset()
	{
		this.ciKills = 0;
		this.siKills = 0;
		this.tankDmg = 0;
		this.deaths = 0;
		this.incaps = 0;
		this.damageTaken = 0;
		this.friendlyFire = 0;
		this.medkitsUsed = 0;
		this.pillsUsed = 0;
		this.adrenalineUsed = 0;
		this.defibsUsed = 0;
		this.heals = 0;
		this.revives = 0;
		this.protections = 0;
		this.pipeBombs = 0;
		this.molotovs = 0;
		this.bileJars = 0;
		this.meleeKills = 0;
		this.bulletsFired = 0;
		this.bulletHits = 0;
		this.headshots = 0;
		this.hunters = 0;
		this.smokers = 0;
		this.boomers = 0;
		this.chargers = 0;
		this.spitters = 0;
		this.jockeys = 0;
		this.tanksKilled = 0;
		this.witchDmg = 0;
		this.witchDisturbs = 0;
		this.witchesKilled = 0;
	}
}

enum struct TankData
{
	bool bAlive;

	void Reset()
	{
		this.bAlive = false;
	}
}

// ====================================================================================================
//					GLOBALS
// ====================================================================================================
ConVar g_hCvarAllow, g_hCvarDifficulty;
ConVar g_hCvarNames[8];

bool   g_bLateLoad;
int    g_iMapNum, g_iTotalMaps;
int    g_iCampaignTime;
int    g_iRestarts;

bool g_bIsTransitionOrRestart = false;

Handle g_hCampaignTimer;
MatchStats g_Stats[MAXPLAYERS + 1];

TankData g_TankData[MAXPLAYERS + 1];
int g_iTankLastHealth[MAXPLAYERS + 1];

MatchStats g_SavedBotStats[8];
// Shotgun & Accuracy Fix Trackers
int g_iLastHitTick[MAXPLAYERS + 1];
int g_iLastHeadshotTick[MAXPLAYERS + 1];

// Pending Witch Damage
int g_iWitchDmgTrack[2048][MAXPLAYERS + 1];
int g_iWitchDamageAwarded[2048];

ConVar g_hCvarLog, g_hCvarLogMode;

float g_fLastGameTime;

// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name        = "[L4D2] Match Stats",
	author      = "EagleRaviOrange",
	description = "Detailed Campaign Stats tracker in console with automatic print to file after end of chapter or finale.",
	version     = PLUGIN_VERSION
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow = CreateConVar("l4d2_match_stats_allow", "1", "0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarDifficulty = FindConVar("z_difficulty");
	
	// Custom Name Overrides
	g_hCvarNames[0] = CreateConVar("l4d2_match_stats_name_nick", "", "Custom name for Nick", CVAR_FLAGS);
	g_hCvarNames[1] = CreateConVar("l4d2_match_stats_name_rochelle", "", "Custom name for Rochelle", CVAR_FLAGS);
	g_hCvarNames[2] = CreateConVar("l4d2_match_stats_name_coach", "", "Custom name for Coach", CVAR_FLAGS);
	g_hCvarNames[3] = CreateConVar("l4d2_match_stats_name_ellis", "", "Custom name for Ellis", CVAR_FLAGS);
	g_hCvarNames[4] = CreateConVar("l4d2_match_stats_name_bill", "", "Custom name for Bill", CVAR_FLAGS);
	g_hCvarNames[5] = CreateConVar("l4d2_match_stats_name_zoey", "", "Custom name for Zoey", CVAR_FLAGS);
	g_hCvarNames[6] = CreateConVar("l4d2_match_stats_name_francis", "", "Custom name for Francis", CVAR_FLAGS);
	g_hCvarNames[7] = CreateConVar("l4d2_match_stats_name_louis", "", "Custom name for Louis", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d2_match_stats");

	RegAdminCmd("sm_resetstats",      CmdResetStats, ADMFLAG_ROOT, "Reset all match stats.");
	RegConsoleCmd("sm_reportstats",   CmdReportStats,              "Print summary match stats to console.");
	RegConsoleCmd("sm_detailedstats", CmdDetailedStats,            "Print detailed personal stats and Team MVPs.");
	RegConsoleCmd("sm_earlystatscrawl", CmdEarlyStatsCrawl,        "Print the end-of-campaign stats crawl to console.");
	RegAdminCmd("sm_resettankstats",  CmdResetTankStats, ADMFLAG_ROOT, "Reset only Tank damage stats.");
	RegAdminCmd("sm_resetwitchstats", CmdResetWitchStats, ADMFLAG_ROOT, "Reset only Witch damage stats.");
	
	g_hCvarLog = CreateConVar("l4d2_match_stats_log", "0", "Log stats to file? 0=No, 1=Yes", CVAR_FLAGS);
	g_hCvarLogMode = CreateConVar("l4d2_match_stats_log_mode", "0", "Logging frequency: 0=Every Transition, 1=Finale Only", CVAR_FLAGS);
	RegAdminCmd("sm_reportstatstofile", CmdReportStatsToFile, ADMFLAG_ROOT, "Force write current stats to a text file for testing.");

	if (g_hCvarAllow.BoolValue)
	{
		HookEvents();
	}
}

// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents()
{
	HookEvent("round_start",          Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("mission_lost",         Event_MissionLost, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);
	HookEvent("finale_win", Event_FinaleWin, EventHookMode_Pre);
	HookEvent("player_death",         Event_PlayerDeath);
	HookEvent("player_hurt",          Event_PlayerHurt);
	HookEvent("infected_hurt",        Event_InfectedHurt);
	HookEvent("weapon_fire",          Event_WeaponFire);
	
	HookEvent("player_incapacitated", Event_Incapped);
	HookEvent("heal_success",         Event_HealSuccess);
	HookEvent("pills_used",           Event_PillsUsed);
	HookEvent("adrenaline_used",      Event_AdrenalineUsed);
	HookEvent("defibrillator_used",   Event_DefibUsed);
	HookEvent("revive_success",       Event_ReviveSuccess);
	HookEvent("award_earned",         Event_AwardEarned);
	HookEvent("witch_harasser_set",   Event_WitchHarasser);
	
	HookEvent("tank_spawn",           Event_TankSpawn);
	HookEvent("player_spawn",         Event_PlayerSpawn);
	HookEvent("player_bot_replace",   Event_BotReplacedPlayer);
	HookEvent("bot_player_replace",   Event_PlayerReplacedBot);
}

public void OnMapStart()
{
	RequestFrame(OnFrame_GetMapInfo);

	if (g_hCampaignTimer != null)
	{
		KillTimer(g_hCampaignTimer);
		g_hCampaignTimer = null;
	}
	
	g_hCampaignTimer = CreateTimer(1.0, Timer_CampaignTime, _, TIMER_REPEAT);
	g_fLastGameTime = 0.0;
}

public void OnMapEnd()
{
	if (g_hCampaignTimer != null)
	{
		KillTimer(g_hCampaignTimer);
		g_hCampaignTimer = null;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "witch"))
	{
		if (entity < 2048)
			g_iWitchDamageAwarded[entity] = 0; 
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bIsTransitionOrRestart && L4D_IsFirstMapInScenario())
	{
		ResetAllStats();
		g_iCampaignTime = 0;
		g_iRestarts = 0;
		for (int i = 0; i < 8; i++) g_SavedBotStats[i].Reset();
	}

	g_bIsTransitionOrRestart = false;

	for (int i = 1; i <= MaxClients; i++)
	{
		g_Stats[i].tankDmg = 0;
		g_Stats[i].witchDmg = 0;
	}

	for (int i = 0; i < 8; i++)
	{
		g_SavedBotStats[i].tankDmg = 0;
		g_SavedBotStats[i].witchDmg = 0;
	}

	for (int i = 0; i <= MaxClients; i++) {
		g_TankData[i].Reset();
		g_iTankLastHealth[i] = 0;
	}
	for (int w = 0; w < 2048; w++) g_iWitchDamageAwarded[w] = 0;
}

void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsTransitionOrRestart = true;
	g_iRestarts++;
}

void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	g_bIsTransitionOrRestart = true;

	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVOR) {
			int charID = GetEntProp(i, Prop_Send, "m_survivorCharacter");
			if (charID >= 0 && charID <= 7) g_SavedBotStats[charID] = g_Stats[i];
		}
	}
	
	if (g_hCvarLogMode.IntValue == 0) WriteStatsToFile();
}

void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast) {
	g_bIsTransitionOrRestart = true;
	WriteStatsToFile();
}

Action Timer_CampaignTime(Handle timer)
{
	float fCurrentTime = GetGameTime();

	if (fCurrentTime == g_fLastGameTime)
		return Plugin_Continue;

	g_fLastGameTime = fCurrentTime;

	if (!L4D_HasAnySurvivorLeftSafeArea())
		return Plugin_Continue;

	g_iCampaignTime++;
	return Plugin_Continue;
}

// ====================================================================================================
//					TRACKING LOGIC
// ====================================================================================================
void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim   = GetClientOfUserId(event.GetInt("userid"));
	bool isMelee = false;
	
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	if (StrContains(weapon, "melee") != -1 || StrContains(weapon, "chainsaw") != -1)
		isMelee = true;

	if (IsValidSurvivor(victim))
	{
		g_Stats[victim].deaths++;
		return;
	}

	if (victim == 0)
	{
		if (IsValidSurvivor(attacker))
		{
			int entityid = event.GetInt("entityid");
			if (entityid > 0 && IsValidEntity(entityid))
			{
				char cls[32];
				GetEntityClassname(entityid, cls, sizeof(cls));
				
				if (strcmp(cls, "witch") == 0) 
				{
					g_Stats[attacker].siKills++;
					g_Stats[attacker].witchesKilled++;
					if (isMelee) g_Stats[attacker].meleeKills++;
					
					if (entityid < 2048) {
						for (int i = 1; i <= MaxClients; i++) {
							g_Stats[i].witchDmg += g_iWitchDmgTrack[entityid][i];
							g_iWitchDmgTrack[entityid][i] = 0; 
						}
					}
				}
				else 
				{
					g_Stats[attacker].ciKills++;
					if (isMelee) g_Stats[attacker].meleeKills++;
				}
			}
		}
		return;
	}

	if (IsValidClient(victim) && GetClientTeam(victim) == TEAM_INFECTED && IsValidSurvivor(attacker))
	{
		int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
		g_Stats[attacker].siKills++;
		if (isMelee) g_Stats[attacker].meleeKills++;
		
		switch (zClass)
		{
			case ZC_SMOKER:  g_Stats[attacker].smokers++;
			case ZC_BOOMER:  g_Stats[attacker].boomers++;
			case ZC_HUNTER:  g_Stats[attacker].hunters++;
			case ZC_SPITTER: g_Stats[attacker].spitters++;
			case ZC_JOCKEY:  g_Stats[attacker].jockeys++;
			case ZC_CHARGER: g_Stats[attacker].chargers++;
			case ZC_TANK:
			{
				g_Stats[attacker].tanksKilled++;
				g_TankData[victim].Reset();
			}
		}
	}
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int dmg = event.GetInt("dmg_health");
	
	if (IsValidSurvivor(victim))
	{
		g_Stats[victim].damageTaken += dmg;
		if (IsValidSurvivor(attacker) && victim != attacker) g_Stats[attacker].friendlyFire++;
	}
	else if (IsValidClient(victim) && GetClientTeam(victim) == TEAM_INFECTED && IsValidSurvivor(attacker))
	{
		if (GetEntProp(victim, Prop_Send, "m_zombieClass") == ZC_TANK)
		{
			if (g_TankData[victim].bAlive)
			{
				int currentHealth = GetClientHealth(victim);
				if (currentHealth < 0) currentHealth = 0;

				int actualDmg = g_iTankLastHealth[victim] - currentHealth;
				
				if (actualDmg > 0) 
				{
					g_Stats[attacker].tankDmg += actualDmg;
					g_iTankLastHealth[victim] = currentHealth;
				}
			}
		}

		char weapon[64];
		event.GetString("weapon", weapon, sizeof(weapon));
		
		if (IsGun(weapon))
		{
			int tick = GetGameTickCount();
			if (g_iLastHitTick[attacker] != tick) {
				g_Stats[attacker].bulletHits++;
				g_iLastHitTick[attacker] = tick;
			}
			if (event.GetInt("hitgroup") == 1) { 
				if (g_iLastHeadshotTick[attacker] != tick) {
					g_Stats[attacker].headshots++;
					g_iLastHeadshotTick[attacker] = tick;
				}
			}
		}
	}
}

void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(attacker)) return;
	
	int victim = event.GetInt("entityid");
	if (victim > 0 && IsValidEntity(victim))
	{
		char cls[32];
		GetEntityClassname(victim, cls, sizeof(cls));
		if (strcmp(cls, "witch") == 0)
		{
			if (victim < 2048)
			{
				int maxHealth = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
				if (maxHealth <= 0) maxHealth = 1000; 

				int alreadyAwarded = g_iWitchDamageAwarded[victim];

				if (alreadyAwarded < maxHealth)
				{
					int amount = event.GetInt("amount");
					int toAward = amount;

					if (alreadyAwarded + toAward > maxHealth)
						toAward = maxHealth - alreadyAwarded;

					g_Stats[attacker].witchDmg += toAward;
					g_iWitchDamageAwarded[victim] += toAward;
				}
			}
		}
	}

	int type = event.GetInt("type");
	if (type & 2) 
	{
		int tick = GetGameTickCount();
		if (g_iLastHitTick[attacker] != tick) {
			g_Stats[attacker].bulletHits++;
			g_iLastHitTick[attacker] = tick;
		}
		if (event.GetInt("hitgroup") == 1) {
			if (g_iLastHeadshotTick[attacker] != tick) {
				g_Stats[attacker].headshots++;
				g_iLastHeadshotTick[attacker] = tick;
			}
		}
	}
}

void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(client)) return;
	
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	
	if (StrEqual(weapon, "pipe_bomb")) g_Stats[client].pipeBombs++;
	else if (StrEqual(weapon, "molotov")) g_Stats[client].molotovs++;
	else if (StrEqual(weapon, "vomitjar")) g_Stats[client].bileJars++;
	else if (IsGun(weapon)) g_Stats[client].bulletsFired++;
}

void Event_Incapped(Event event, const char[] n, bool d)       { int c = GetClientOfUserId(event.GetInt("userid")); if (IsValidSurvivor(c)) g_Stats[c].incaps++; }
void Event_PillsUsed(Event event, const char[] n, bool d)      { int c = GetClientOfUserId(event.GetInt("userid")); if (IsValidSurvivor(c)) g_Stats[c].pillsUsed++; }
void Event_AdrenalineUsed(Event event, const char[] n, bool d) { int c = GetClientOfUserId(event.GetInt("userid")); if (IsValidSurvivor(c)) g_Stats[c].adrenalineUsed++; }
void Event_DefibUsed(Event event, const char[] n, bool d)      { int c = GetClientOfUserId(event.GetInt("userid")); if (IsValidSurvivor(c)) g_Stats[c].defibsUsed++; }
void Event_ReviveSuccess(Event event, const char[] n, bool d)  { int c = GetClientOfUserId(event.GetInt("userid")); if (IsValidSurvivor(c)) g_Stats[c].revives++; }
void Event_WitchHarasser(Event event, const char[] n, bool d)  { int c = GetClientOfUserId(event.GetInt("userid")); if (IsValidSurvivor(c)) g_Stats[c].witchDisturbs++; }

void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int healer = GetClientOfUserId(event.GetInt("userid"));
	int subject = GetClientOfUserId(event.GetInt("subject"));
	if (IsValidSurvivor(healer))
	{
		if (healer == subject) g_Stats[healer].medkitsUsed++;
		else g_Stats[healer].heals++;
	}
}

void Event_AwardEarned(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidSurvivor(client) && event.GetInt("award") == 67) g_Stats[client].protections++;
}

// ====================================================================================================
//					TANK & WITCH DAMAGE
// ====================================================================================================

void Event_TankSpawn(Event event, const char[] n, bool d) {
	int t = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(t)) { 
		g_TankData[t].Reset(); 
		g_TankData[t].bAlive = true;
		g_iTankLastHealth[t] = GetEntProp(t, Prop_Data, "m_iMaxHealth");
	}
}

void Event_PlayerSpawn(Event event, const char[] n, bool d) {
	int c = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(c)) return;

	if (GetClientTeam(c) == TEAM_INFECTED && GetEntProp(c, Prop_Send, "m_zombieClass") == ZC_TANK) {
		g_TankData[c].Reset(); 
		g_TankData[c].bAlive = true;
		g_iTankLastHealth[c] = GetEntProp(c, Prop_Data, "m_iMaxHealth");
	}
	else if (GetClientTeam(c) == TEAM_SURVIVOR && IsFakeClient(c)) {
		int charID = GetEntProp(c, Prop_Send, "m_survivorCharacter");
		if (charID >= 0 && charID <= 7 && (g_SavedBotStats[charID].ciKills > 0 || g_SavedBotStats[charID].siKills > 0)) {
			MergeBotStats(c, charID);
		}
	}
}
void Event_BotReplacedPlayer(Event event, const char[] n, bool d) {
	int p = GetClientOfUserId(event.GetInt("player")), b = GetClientOfUserId(event.GetInt("bot"));
	if (!IsValidClient(p) || !IsValidClient(b)) return;

	if (GetClientTeam(p) == TEAM_SURVIVOR && GetClientTeam(b) == TEAM_SURVIVOR) {
		MergePlayerStats(b, p);
	}
	else if (GetClientTeam(b) == TEAM_INFECTED && GetEntProp(b, Prop_Send, "m_zombieClass") == ZC_TANK) {
		g_TankData[p].Reset(); 
		g_TankData[b].bAlive = true;
	}
}

void Event_PlayerReplacedBot(Event event, const char[] n, bool d) {
	int p = GetClientOfUserId(event.GetInt("player")), b = GetClientOfUserId(event.GetInt("bot"));
	if (!IsValidClient(p) || !IsValidClient(b)) return;

	if (GetClientTeam(p) == TEAM_SURVIVOR && GetClientTeam(b) == TEAM_SURVIVOR) {
		MergePlayerStats(p, b);
	}
	else if (GetClientTeam(p) == TEAM_INFECTED && GetEntProp(p, Prop_Send, "m_zombieClass") == ZC_TANK) {
		g_TankData[b].Reset(); 
		g_TankData[p].bAlive = true;
	}
}

// ====================================================================================================
//					COMMANDS
// ====================================================================================================
Action CmdResetStats(int client, int args)
{
	ResetAllStats();
	g_iCampaignTime = 0;
	g_iRestarts = 0;
	if (client && IsClientInGame(client)) PrintToChat(client, "\x04[Stats] \x01All match stats have been reset.");
	return Plugin_Handled;
}

// --- SUMMARY REPORT ---
Action CmdReportStats(int client, int args) {
	if (client > 0) {
		InternalReportStats(client, null);
		PrintToChat(client, "\x04[Stats] \x01Check your console for the summary!");
	}
	return Plugin_Handled;
}

void InternalReportStats(int client, File hFile) {
	Out(client, hFile, "\n========================================\n          SUMMARY MATCH STATS           \n========================================");
	PrintStatCategory(client, hFile, "CI KILLS", 0); 
	PrintStatCategory(client, hFile, "SI KILLS", 1); 
	PrintStatCategory(client, hFile, "TANK DAMAGE", 2); 
	PrintStatCategory(client, hFile, "WITCH DAMAGE", 3);
	Out(client, hFile, "========================================\n");
}

Action CmdDetailedStats(int client, int args) {
	if (client > 0) {
		InternalDetailedStats(client, null);
		PrintToChat(client, "\x04[Stats] \x01Check your console for details!");
	}
	return Plugin_Handled;
}

void InternalDetailedStats(int client, File hFile) {
	int h = g_iCampaignTime / 3600, m = (g_iCampaignTime % 3600) / 60, s = g_iCampaignTime % 60;
	Out(client, hFile, "\n=================================================\n              DETAILED MATCH STATS               \n=================================================\n Campaign Time Played: %02d:%02d:%02d", h, m, s);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidSurvivor(i)) continue;
		float acc = 0.0, hs = 0.0; char n[32]; GetCustomClientName(i, n, sizeof(n));
		if (g_Stats[i].bulletsFired > 0) acc = (float(g_Stats[i].bulletHits) / float(g_Stats[i].bulletsFired)) * 100.0;
		if (g_Stats[i].bulletHits > 0) hs = (float(g_Stats[i].headshots) / float(g_Stats[i].bulletHits)) * 100.0;
		Out(client, hFile, " \n [ %s ]\n  CI/SI: %d/%d | Melee: %d | Accuracy: %.1f%% | Headshots: %.1f%%", n, g_Stats[i].ciKills, g_Stats[i].siKills, g_Stats[i].meleeKills, acc, hs);
		Out(client, hFile, "  Infected Breakdown: H:%d S:%d B:%d C:%d Sp:%d J:%d", g_Stats[i].hunters, g_Stats[i].smokers, g_Stats[i].boomers, g_Stats[i].chargers, g_Stats[i].spitters, g_Stats[i].jockeys);
		Out(client, hFile, "  Teamwork: Pro:%d Heal:%d Rev:%d | DmgTaken: %d | Dead/Inc: %d/%d", g_Stats[i].protections, g_Stats[i].heals, g_Stats[i].revives, g_Stats[i].damageTaken, g_Stats[i].deaths, g_Stats[i].incaps);
	}
	Out(client, hFile, "\n[ TEAM MVPs ]");
	PrintMVP(client, hFile, "Most CI Kills", 0);
	PrintMVP(client, hFile, "Most SI Kills", 1);
	PrintMVP(client, hFile, "Most Melee Kills", 2);
	PrintMVP(client, hFile, "Most Tank Damage", 3);
	PrintMVP(client, hFile, "Most Witch Damage", 4);
	PrintMVP_Accuracy(client, hFile);
	Out(client, hFile, "=================================================\n");
}

// --- EARLY STATS CRAWL ---
Action CmdEarlyStatsCrawl(int client, int args) {
	if (client > 0) {
		InternalEarlyCrawl(client, null);
		PrintToChat(client, "\x04[Stats] \x01Check your console for the crawl!");
	}
	return Plugin_Handled;
}

void InternalEarlyCrawl(int client, File hFile) {
	char tS[64], dS[32], oD[32];
	int h = g_iCampaignTime / 3600, m = (g_iCampaignTime % 3600) / 60;
	if (h > 0) Format(tS, sizeof(tS), "%d hour%s, %d minute%s", h, h==1?"":"s", m, m==1?"":"s");
	else Format(tS, sizeof(tS), "%d minute%s", m, m==1?"":"s");
	
	g_hCvarDifficulty.GetString(dS, sizeof(dS));
	if (StrEqual(dS, "Impossible", false)) strcopy(oD, sizeof(oD), "Expert");
	else if (StrEqual(dS, "Hard", false)) strcopy(oD, sizeof(oD), "Advanced");
	else strcopy(oD, sizeof(oD), dS);
	
	Out(client, hFile, "\n=========================================================================\n%45s  %s\n%45s  %s\n%45s  %d\n ", "Total campaign time", tS, "Difficulty", oD, "Number of times restarted", g_iRestarts);
	
	PrintCrawlCategory(client, hFile, "Deaths", 0, true, false);
	PrintCrawlCategory(client, hFile, "Number of times incapacitated", 1, true, false);
	PrintCrawlCategory(client, hFile, "First aid kits used", 2, false, false);
	PrintCrawlCategory(client, hFile, "Pain pills used", 3, false, false);
	PrintCrawlCategory(client, hFile, "Adrenaline shots used", 4, false, false);
	PrintCrawlCategory(client, hFile, "Defibrillators used", 5, false, false);
	PrintCrawlCategory(client, hFile, "Pipe bombs used", 6, false, false);
	PrintCrawlCategory(client, hFile, "Molotovs used", 7, false, false);
	PrintCrawlCategory(client, hFile, "Bile jars used", 8, false, false);
	
	PrintCrawlCategory(client, hFile, "Melee kills", 9, false, false);
	PrintCrawlCategory(client, hFile, "Hunters killed", 10, false, false);
	PrintCrawlCategory(client, hFile, "Boomers killed", 11, false, false);
	PrintCrawlCategory(client, hFile, "Smokers killed", 12, false, false);
	PrintCrawlCategory(client, hFile, "Chargers killed", 13, false, false);
	PrintCrawlCategory(client, hFile, "Jockeys killed", 14, false, false);
	PrintCrawlCategory(client, hFile, "Spitters killed", 15, false, false);
	PrintCrawlCategory(client, hFile, "Tanks killed", 16, false, false);
	PrintCrawlCategory(client, hFile, "Witches killed", 17, false, false);
	
	PrintCrawlCategory(client, hFile, "Killed the most Special Infected", 18, false, false);
	PrintCrawlCategory(client, hFile, "Common Infected killed", 19, false, false);
	PrintCrawlCategory(client, hFile, "Killed the most Infected", 20, false, false);
	
	PrintCrawlCategory(client, hFile, "Took the least amount of damage", 21, true, false);
	PrintCrawlCategory(client, hFile, "Fewest friendly fire incidents", 22, true, false);
	
	PrintCrawlCategory(client, hFile, "Disturbed the Witch the most", 23, false, false);
	PrintCrawlCategory(client, hFile, "Revived the most teammates", 24, false, false);
	PrintCrawlCategory(client, hFile, "Protected the most teammates", 25, false, false);
	PrintCrawlCategory(client, hFile, "Healed the most teammates", 26, false, false);
	
	PrintCrawlCategory(client, hFile, "Overall accuracy", 27, false, true);
	PrintCrawlCategory(client, hFile, "Headshots (percentage of all hits)", 28, false, true);

	int tZ = 0;
	for (int i = 1; i <= MaxClients; i++) if (IsValidSurvivor(i)) tZ += (g_Stats[i].ciKills + g_Stats[i].siKills);
	Out(client, hFile, "               %d zombies were harmed in the making of this film.\n=========================================================================\n ", tZ);
}

// ====================================================================================================
//					HELPERS
// ====================================================================================================
public void OnClientDisconnect(int client)
{
	g_TankData[client].Reset();
}

void ResetAllStats()
{
	for (int i = 1; i <= MaxClients; i++) g_Stats[i].Reset();
}

void OnFrame_GetMapInfo()
{
	g_iMapNum = L4D_GetCurrentChapter();
	g_iTotalMaps = L4D_GetMaxChapters();
	if (g_iMapNum < 1) g_iMapNum = 1;
	if (g_iTotalMaps < 1) g_iTotalMaps = 1;
}

bool IsGun(const char[] weapon)
{
	if (weapon[0] == '\0') return false;
	if (StrContains(weapon, "melee") != -1) return false;
	if (StrContains(weapon, "chainsaw") != -1) return false;
	if (StrContains(weapon, "pipe") != -1) return false;
	if (StrContains(weapon, "molotov") != -1) return false;
	if (StrContains(weapon, "vomit") != -1) return false;
	if (StrContains(weapon, "inferno") != -1) return false;
	if (StrContains(weapon, "flame") != -1) return false;
	if (StrContains(weapon, "claw") != -1) return false;
	if (StrContains(weapon, "spit") != -1) return false;
	return true;
}

void GetCustomClientName(int client, char[] buffer, int maxlen)
{
	GetClientName(client, buffer, maxlen);
	if (!IsClientInGame(client) || GetClientTeam(client) != TEAM_SURVIVOR) return;

	char model[128];
	GetClientModel(client, model, sizeof(model));

	int character = -1;
	if (StrContains(model, "gambler", false) != -1) character = 0;       // Nick
	else if (StrContains(model, "producer", false) != -1) character = 1; // Rochelle
	else if (StrContains(model, "coach", false) != -1) character = 2;    // Coach
	else if (StrContains(model, "mechanic", false) != -1) character = 3; // Ellis
	else if (StrContains(model, "namvet", false) != -1) character = 4;   // Bill
	else if (StrContains(model, "teenangst", false) != -1) character = 5;// Zoey
	else if (StrContains(model, "biker", false) != -1) character = 6;    // Francis
	else if (StrContains(model, "manager", false) != -1) character = 7;  // Louis
	else character = GetEntProp(client, Prop_Send, "m_survivorCharacter"); // Fallback

	if (character >= 0 && character <= 7)
	{
		char custom[32];
		g_hCvarNames[character].GetString(custom, sizeof(custom));
		if (custom[0] != '\0')
		{
			strcopy(buffer, maxlen, custom);
		}
	}
}

void PrintCrawlCategory(int client, File hFile, const char[] title, int type, bool low, bool pct) {
	int cls[MAXPLAYERS+1]; float vls[MAXPLAYERS+1]; int count = 0;
	for (int i = 1; i <= MaxClients; i++) { 
		if (!IsValidSurvivor(i)) continue; 
		float val = 0.0;
		switch(type) { 
			case 0: val = float(g_Stats[i].deaths);
			case 1: val = float(g_Stats[i].incaps);
			case 2: val = float(g_Stats[i].medkitsUsed); 
			case 3: val = float(g_Stats[i].pillsUsed);
			case 4: val = float(g_Stats[i].adrenalineUsed);
			case 5: val = float(g_Stats[i].defibsUsed); 
			case 6: val = float(g_Stats[i].pipeBombs);
			case 7: val = float(g_Stats[i].molotovs);
			case 8: val = float(g_Stats[i].bileJars); 
			case 9: val = float(g_Stats[i].meleeKills);
			case 10: val = float(g_Stats[i].hunters);
			case 11: val = float(g_Stats[i].boomers); 
			case 12: val = float(g_Stats[i].smokers);
			case 13: val = float(g_Stats[i].chargers);
			case 14: val = float(g_Stats[i].jockeys); 
			case 15: val = float(g_Stats[i].spitters);
			case 16: val = float(g_Stats[i].tanksKilled);
			case 17: val = float(g_Stats[i].witchesKilled); 
			case 18: val = float(g_Stats[i].siKills);
			case 19: val = float(g_Stats[i].ciKills);
			case 20: val = float(g_Stats[i].ciKills + g_Stats[i].siKills); 
			case 21: val = float(g_Stats[i].damageTaken);
			case 22: val = float(g_Stats[i].friendlyFire);
			case 23: val = float(g_Stats[i].witchDisturbs); 
			case 24: val = float(g_Stats[i].revives);
			case 25: val = float(g_Stats[i].protections);
			case 26: val = float(g_Stats[i].heals); 
			case 27: if (g_Stats[i].bulletsFired > 0) val = (float(g_Stats[i].bulletHits) / float(g_Stats[i].bulletsFired)) * 100.0; 
			case 28: if (g_Stats[i].bulletHits > 0) val = (float(g_Stats[i].headshots) / float(g_Stats[i].bulletHits)) * 100.0; 
		}
		if (val > 100.0 && pct) val = 100.0; cls[count] = i;
		vls[count] = val; count++;
	}
	if (count == 0) return;
	for (int i = 0; i < count - 1; i++) { 
		int t = i; 
		for (int j = i + 1; j < count; j++) { if (low ? (vls[j] < vls[t]) : (vls[j] > vls[t])) t = j; } 
		if (t != i) { 
			int tc = cls[i];
			float tv = vls[i];
			cls[i] = cls[t];
			vls[i] = vls[t];
			cls[t] = tc;
			vls[t] = tv; 
		} 
	}
	for (int i = 0; i < count; i++) { 
		char name[32], valS[16];
		GetCustomClientName(cls[i], name, sizeof(name)); 
		if (pct) Format(valS, sizeof(valS), "%d%%", RoundToFloor(vls[i]));
		else Format(valS, sizeof(valS), "%d", RoundToFloor(vls[i])); 
		Out(client, hFile, "%45s  %s %s", (i==0?title:""), valS, name); 
	}
	Out(client, hFile, " ");
}

void PrintStatCategory(int client, File hFile, const char[] title, int type) {
	Out(client, hFile, " ★ %s", title);
	int cls[MAXPLAYERS+1], vls[MAXPLAYERS+1], count = 0;
	for (int i = 1; i <= MaxClients; i++) { 
		if (!IsValidSurvivor(i)) continue; 
		int val = 0; 
		if (type == 0) val = g_Stats[i].ciKills; 
		else if (type == 1) val = g_Stats[i].siKills; 
		else if (type == 2) val = g_Stats[i].tankDmg; 
		else if (type == 3) val = g_Stats[i].witchDmg;
		
		if (val > 0) { cls[count] = i; vls[count] = val; count++; }
	}
	if (count == 0) { Out(client, hFile, "    (No Stats Recorded)\n "); return; }
	for (int i = 0; i < count; i++) { 
		int m = i; 
		for (int j = i + 1; j < count; j++) { if (vls[j] > vls[m]) m = j; } 
		if (m != i) {
			int tc = cls[i], tv = vls[i];
			cls[i] = cls[m];
			vls[i] = vls[m];
			cls[m] = tc;
			vls[m] = tv;
		} 
	}
	for (int i = 0; i < count; i++) { 
		char name[32];
		GetCustomClientName(cls[i], name, sizeof(name)); 
		Out(client, hFile, "    %4d  -  %s", vls[i], name); 
	}
	Out(client, hFile, " ");
}
void PrintMVP(int client, File hFile, const char[] title, int type) {
	int bC = 0, bV = 0;
	for (int i = 1; i <= MaxClients; i++) { 
		if (!IsValidSurvivor(i)) continue; 
		int v = 0; 
		switch(type) { 
			case 0: v = g_Stats[i].ciKills;
			case 1: v = g_Stats[i].siKills;
			case 2: v = g_Stats[i].meleeKills; 
			case 3: v = g_Stats[i].tankDmg;
			case 4: v = g_Stats[i].witchDmg;
			case 5: v = g_Stats[i].damageTaken; 
			case 6: v = g_Stats[i].incaps;
			case 7: v = g_Stats[i].revives;
			case 8: v = g_Stats[i].protections; 
			case 9: v = g_Stats[i].heals; 
		} 
		if (v > bV) {
			bV = v;
			bC = i;
		} 
	}
	if (bC > 0) { 
		char n[32];
		GetCustomClientName(bC, n, sizeof(n)); 
		Out(client, hFile, "  %-20s: %s (%d)", title, n, bV); 
	}
}

void PrintMVP_Accuracy(int client, File hFile)
{
	int bestClient = 0;
	float bestValue = 0.0;
	for (int i = 1; i <= MaxClients; i++) {
		// Only consider players who have fired at least 50 shots to prevent 100% luck stats
		if (!IsValidSurvivor(i) || g_Stats[i].bulletsFired < 50) continue; 
		
		float acc = (float(g_Stats[i].bulletHits) / float(g_Stats[i].bulletsFired)) * 100.0;
		if (acc > 100.0) acc = 100.0;
		if (acc > bestValue) { bestValue = acc; bestClient = i; }
	}
	
	if (bestClient > 0) {
		char name[32]; GetCustomClientName(bestClient, name, sizeof(name));
		Out(client, hFile, "  %-20s: %s (%.1f%%)", "Best Accuracy", name, bestValue);
	}
}

bool IsValidClient(int client)   { return (client >= 1 && client <= MaxClients && IsClientInGame(client)); }
bool IsValidSurvivor(int client) { return (client >= 1 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVOR); }

void MergePlayerStats(int dest, int src)
{
	g_Stats[dest] = g_Stats[src];
	g_Stats[src].Reset();
}

void MergeBotStats(int dest, int charID)
{
	g_Stats[dest] = g_SavedBotStats[charID];
	g_SavedBotStats[charID].Reset();
}

Action CmdResetTankStats(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_Stats[i].tankDmg = 0;
		g_iTankLastHealth[i] = 0;
	}

	for (int i = 0; i < 8; i++)
		g_SavedBotStats[i].tankDmg = 0;

	if (client && IsClientInGame(client)) 
		PrintToChat(client, "\x04[Stats] \x01Tank damage stats have been \x03reset\x01.");
		
	return Plugin_Handled;
}

Action CmdResetWitchStats(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
		g_Stats[i].witchDmg = 0;

	for (int i = 0; i < 8; i++)
		g_SavedBotStats[i].witchDmg = 0;

	for (int w = 0; w < 2048; w++)
		g_iWitchDamageAwarded[w] = 0;

	if (client && IsClientInGame(client)) 
		PrintToChat(client, "\x04[Stats] \x01Witch damage stats have been \x03reset\x01.");
		
	return Plugin_Handled;
}

Action CmdReportStatsToFile(int client, int args)
{
	PrintToChat(client, "\x04[Stats] \x01Manual log triggered. Writing to \x05/logs/match_stats/\x01...");
	WriteStatsToFile(true);
	PrintToChat(client, "\x04[Stats] \x01Log complete!");
	return Plugin_Handled;
}

void WriteStatsToFile(bool force = false)
{
	if (!force && !g_hCvarLog.BoolValue) return;

	char sDir[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sDir, sizeof(sDir), "logs/match_stats");
	if (!DirExists(sDir)) CreateDirectory(sDir, 511);

	char sDate[32], sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	FormatTime(sDate, sizeof(sDate), "%Y%m%d_%H%M%S");
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "logs/match_stats/Match_%s_%s.txt", sMap, sDate);
	
	File hFile = OpenFile(sPath, "a");
	if (hFile == null) 
	{
		LogError("[Match Stats] Failed to create log file at: %s", sPath);
		return;
	}

	InternalReportStats(0, hFile);
	InternalDetailedStats(0, hFile);
	InternalEarlyCrawl(0, hFile);

	delete hFile;
}

void Out(int client, File file, const char[] format, any...) {
	char buffer[256];
	VFormat(buffer, sizeof(buffer), format, 4);
	if (client > 0 && IsClientInGame(client)) PrintToConsole(client, buffer);
	if (file != null) file.WriteLine(buffer);
}
