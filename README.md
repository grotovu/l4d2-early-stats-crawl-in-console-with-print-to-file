# L4D2 Sourcemod Plugin: Early Stats Crawl
A sourcemod plugin for L4D2 that can print the ending stats crawl anytime during a campaign, as well as addressing the problem with melee usage skewing the overall accuracy. Can print to a file every chapter or just the finale.

Mostly vibe-coded. I was annoyed how overall accuracy is affected negatively by melee usage. Melee weapons count negatively to the accuracy regardless of whether it was a kill or miss. This plugin only calculates accuracy from shots fired from guns.

# Requirements
- left4dhooks

# Installation
- addons > sourcemod > scripting
- Compile the .sp file by dragging the .sp file on top of the 'compile.exe'.
- addons > sourcemod > scripting > compiled
- Take the newly created .smx file
- Then place the .smx in the sourcemod > plugins folder

# Usage:
Either use the chat or type in the console starting with 'say ':
- !reportstats: Quick summary (CI, SI, Tank, and Witch damage).
- !detailedstats: Personal breakdown plus a list of Team MVPs for the campaign.
- !earlystatscrawl: Full summary formatted like the ending stats crawl printed in the console.
- !resetstats: Full wipe of everything. Will not match the ending stats crawl after using this.
- !resettankstats: Wipes only Tank damage (useful for multi-tank finales). Tank stats automatically wiped after map transition.
- !resetwitchstats: Wipes only Witch damage. Witch stats automatically wiped after map transition.
- !reportstatstofile - text file appears in the logs folder in the sourcemod folder, "match_stats"

Caveats:
- If you die and restart chapter 1, the stats of this plugin are also reset, unlike the vanilla game which still track your stats even if you restart chapter 1 from a team-wipe. The final print will not match the ending stats crawl. (TO-DO: wipe stats another way other than detecting the map is the first of the campaign)

# The cvars:
```
// enables or disables the plugin
l4d2_match_stats_allow "1"

// names for each survivor if you play with skins and change their names. Leave blank for default survivor names.
l4d2_match_stats_name_nick "Reisen"
l4d2_match_stats_name_rochelle "Rei'sen II"
l4d2_match_stats_name_coach "Ringo"
l4d2_match_stats_name_ellis "Seiran"

l4d2_match_stats_name_bill "Yukari"
l4d2_match_stats_name_zoey "Maribel"
l4d2_match_stats_name_francis "Sumireko"
l4d2_match_stats_name_louis "Renko"

// enable or disable logging to file. Appears in sourcemod/logs/match_stats folder
l4d2_match_stats_log "1"

//"Logging frequency: 0=Every Transition, 1=Finale Only"
l4d2_match_stats_log_mode "0"
```

# Example of stats printed to file:
File name in the match_stats folder: Match_c1m3_mall_20260429_171054.

I was playing a mutation Two Of Us. If there were 4 of you, it will be all you 4 here.
```
========================================
          SUMMARY MATCH STATS           
========================================
 ★ CI KILLS
     839  -  Rei'sen II
     322  -  Ringo
 
 ★ SI KILLS
      54  -  Rei'sen II
      17  -  Ringo
 
 ★ TANK DAMAGE
    2635  -  Rei'sen II
    1365  -  Ringo
 
 ★ WITCH DAMAGE
    (No Stats Recorded)
 
========================================


=================================================
              DETAILED MATCH STATS               
=================================================
 Campaign Time Played: 01:13:49
 
 [ Rei'sen II ]
  CI/SI: 839/54 | Melee: 746 | Accuracy: 38.0 | Headshots: 13.4%
  Infected Breakdown: H:7 S:8 B:11 C:7 Sp:12 J:7
  Teamwork: Pro:11 Heal:4 Rev:2 | DmgTaken: 465 | Dead/Inc: 0/1
 
 [ Ringo ]
  CI/SI: 322/17 | Melee: 239 | Accuracy: 58.4 | Headshots: 28.8%
  Infected Breakdown: H:3 S:2 B:0 C:7 Sp:0 J:5
  Teamwork: Pro:12 Heal:6 Rev:0 | DmgTaken: 241 | Dead/Inc: 0/1

[ TEAM MVPs ]
  Most CI Kills       : Rei'sen II (839)
  Most SI Kills       : Rei'sen II (54)
  Most Melee Kills    : Rei'sen II (746)
  Most Tank Damage    : Rei'sen II (2635)
=================================================


=========================================================================
Total campaign time                            1 hour, 13 minutes
Difficulty                                     Expert
Number of times restarted                      0
 
Deaths                                         0 Rei'sen II
                                               0 Ringo
 
Number of times incapacitated                  1 Rei'sen II
                                               1 Ringo
 
First aid kits used                            0 Rei'sen II
                                               0 Ringo
 
Pain pills used                                2 Ringo
                                               0 Rei'sen II
 
Adrenaline shots used                          1 Rei'sen II
                                               0 Ringo
 
Defibrillators used                            0 Rei'sen II
                                               0 Ringo
 
Pipe bombs used                                2 Rei'sen II
                                               0 Ringo
 
Molotovs used                                  2 Rei'sen II
                                               0 Ringo
 
Bile jars used                                 4 Rei'sen II
                                               0 Ringo
 
Melee kills                                    746 Rei'sen II
                                               239 Ringo
 
Hunters killed                                 7 Rei'sen II
                                               3 Ringo
 
Boomers killed                                 11 Rei'sen II
                                               0 Ringo
 
Smokers killed                                 8 Rei'sen II
                                               2 Ringo
 
Chargers killed                                7 Rei'sen II
                                               7 Ringo
 
Jockeys killed                                 7 Rei'sen II
                                               5 Ringo
 
Spitters killed                                12 Rei'sen II
                                               0 Ringo
 
Tanks killed                                   2 Rei'sen II
                                               0 Ringo
 
Witches killed                                 0 Rei'sen II
                                               0 Ringo
 
Killed the most Special Infected               54 Rei'sen II
                                               17 Ringo
 
Common Infected killed                         839 Rei'sen II
                                               322 Ringo
 
Killed the most Infected                       893 Rei'sen II
                                               339 Ringo
 
Took the least amount of damage                241 Ringo
                                               465 Rei'sen II
 
Fewest friendly fire incidents                 0 Rei'sen II
                                               0 Ringo
 
Disturbed the Witch the most                   1 Rei'sen II
                                               0 Ringo
 
Revived the most teammates                     2 Rei'sen II
                                               0 Ringo
 
Protected the most teammates                   12 Ringo
                                               11 Rei'sen II
 
Healed the most teammates                      6 Ringo
                                               4 Rei'sen II
 
Overall accuracy                               58 Ringo
                                               38 Rei'sen II
 
Headshots (percentage of all hits)             28 Ringo
                                               13 Rei'sen II
 
               1232 zombies were harmed in the making of this film.
=========================================================================
```
