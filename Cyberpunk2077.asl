/*

Load & pause remover and autosplit script for Cyberpunk 2077
Written by Zoluu. Inspired by Meta and Radioactive03's autosplit.

Only version 2.31 and 2.01 are supported (2.01 is highly recommanded for Phantom Liberty)

Download version 2.01 : 
1. win+r and type "steam://open/console"
2. In the Steam Console type "download_depot 1091500 1091501 6970577188312667484" to download the main game
3. In the Steam Console type "download_depot 2138330 2138330 1990018461669282288" to download the dlc
4. Navigate to the folder in which you downloaded the depot (by default it should be 'C:\Program Files (x86)\Steam\steamapps\content\')
5. Drag and drop the content of 'app_2138330\depot_2138330' into 'app_1091500\depot_1091501'

You can either keep it in this folder and you will have 2 versions of Cyberpunk Installed or you can copy the folder into 'C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077' but you will need to play in offline mode, otherwise Steam will ask you to update to most recent patch
This will download the english version of the game with no other language settings, if you want to change the language go to 'https://steamdb.info/app/1091500/depots/', find the language you want, download and drag & drop to the game folder.


If you would like to add support to others patches:

1. Download Cheat Engine(CE for short) and attach cyberpunk to CE
2. Scan for the respective values you are looking for (example: q000_street_kid for the mission pointer, 1 if you paused the game)
3. Change the value by changing the current mission or unpausing the game and rescan with the new value
4. Repeat step 3 until only a few addresses are left
5. The pointer scan needs the START of the object that contains the value, not the value itself.
	To find it: right click the address > "Find out what accesses this address" (or "writes to"), then trigger the change in game.
	Look for an instruction like "mov byte ptr [rcx+758],01"
	the register (rcx) is the start of the object, the number (758) is the offset of your value inside the object.
6. Check that you found the right object: add (value address - offset) as "8 Bytes", Hexadecimal.
	It should look like 00007FF7xxxxxxxx, Note the object address.
7. Right click the object > "Generate pointermap" and save the file. Keep the object address.
8. Close the game, start it again, load the same save and find the object again (steps 2 to 6).
9. Right click the new object > "Pointer scan for this address", with:
- "Only find paths with a static address" checked
- "Compare results with other saved pointermap(s)": add your file, and enter the object address you had in the first session, no filter on the final offsets, max level 4 (you can add more level if the scan find no path)
10. Keep the paths that start with "Cyberpunk2077.exe"+ the shortest first.
11. Write it in the script: base, then the offsets in the same order as in CE.
	The last offset is the last offset of the scan + the offset of your value inside the object.
	Example: path "Cyberpunk2077.exe"+048C6DE0 -> B8 -> 20, value at 0xE0 inside the object:
	string50 mission : 0x048C6DE0, 0xB8, 0x100; (0x20 + 0xE0 = 0x100)
12. Pointers change with every game version: add one "state" block per supported version.
*/


state ("Cyberpunk2077","2.31") // pointers for version 2.31
{ 
	string50 mission       : 0x048C6DE0, 0xB8, 0x100;       // For length < ~20
	string50 missionLong   : 0x048C6DE0, 0xB8, 0x100, 0x0;  // For length > ~20      Not sure of the exact length, 19 is still considered short

	string50 objective     : 0x048C6DE0, 0x158, 0x118;      // useless for now, will add support later
	string50 objectiveLong : 0x048C6DE0, 0x158, 0x118, 0x0;

	byte paused            : 0x03430690, 0x30, 0x0, 0x758; // paused = 1;   !paused = 0;
}

state ("Cyberpunk2077","2.01") // pointers for version 2.01
{
	string50 mission       : 0x046B7F90, 0xB8, 0x100;
	string50 missionLong   : 0x046B7F90, 0xB8, 0x100, 0x0;

	string50 objective     : 0x046B7F90, 0x158, 0x118;
	string50 objectiveLong : 0x046B7F90, 0x158, 0x118, 0x0;

	byte paused            : 0x03E03BF8, 0x1A8;
}

// Get called when the script is ready, when you load it in LiveSplit
startup
{
	vars.SupportedVersions = new HashSet<string> { "2.31", "2.01" }; //list of supported version(s).
	vars.versionWarned = false;

	vars.lastSignature = "";

	vars.previous = null; // last mission that is in the splits dictionary

	vars.TimerStart = (EventHandler)((s, e) => {
		timer.IsGameTimePaused = true;
		vars.splitIndex = 0;
		vars.splitted.Clear();
		vars.previous = null;
	});

	timer.OnStart += vars.TimerStart;

	// isPaused: curr.paused == 1; !isPaused: curr.paused == 0;
	vars.isPaused = (Func<dynamic, bool>) ((curr) => {
		return curr != null && curr.paused == 1;
	});

	// If a string is a valid mission/objective id (only char, digit or '_')
	vars.IsValid = (Func<string, bool>)(s => !string.IsNullOrEmpty(s) && s.Length > 3 && s.All(c => char.IsLower(c) || char.IsDigit(c) || c == '_'));

	// Pick the valid mission string between the long and the short one
	vars.GetMission = (Func<dynamic, string>)(st => {
		string a = st.mission;
		string b = st.missionLong;
		if (vars.IsValid(a)) return a;
		if (vars.IsValid(b)) return b;
		return null;
	});

	// Pick the valid objective string between the long and the short one
	vars.GetObjective = (Func<dynamic, string>)(st => {
		string a = st.objective;
		string b = st.objectiveLong;
		if (vars.IsValid(a)) return a;
		if (vars.IsValid(b)) return b;
		return null;
	});
	
	// Asks user to change to game time if LiveSplit is currently set to Real Time. (by Meta and Radioactive03)
	if (timer.CurrentTimingMethod == TimingMethod.RealTime)
	{
		var timingMessage = MessageBox.Show (
			"This game uses Time without Loads (Game Time) as the main timing method.\n"+
			"LiveSplit is currently set to show Real Time (RTA).\n"+
			"Would you like to set the timing method to Game Time?",
			"LiveSplit | Cyberpunk 2077",
			MessageBoxButtons.YesNo,MessageBoxIcon.Question
		);
		
		if (timingMessage == DialogResult.Yes) timer.CurrentTimingMethod = TimingMethod.GameTime;
	}

	// Creates a text component at the bottom of the users LiveSplit layout displaying the current objective, current mission or if the game is paused. (by Meta and Radioactive03)
	// To disable a text component you need to uncheck it in the autosplit' settings and remove it in the layout editor by selecting it and clicking the "-" button.
	vars.SetTextComponent = (Action<string, string>)((id, text) =>
	{
		var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
		var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == id);
		if (textSetting == null)
		{
		var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
		var textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
		timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));

		textSetting = textComponent.GetType().GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public).GetValue(textComponent, null);
		textSetting.GetType().GetProperty("Text1").SetValue(textSetting, id);
		}

		if (textSetting != null)
		textSetting.GetType().GetProperty("Text2").SetValue(textSetting, text ?? "");
	});

	// Contains the missions IDs & names, missions tree for better UI and settings (display mission, objective, paused and autosplit creation)
	// { "id", "Label", "parent", default_value (checked/unchecked) }
	dynamic[,] splitSettings = {
		{ "—separator_0", "—————————————————————————————————————————————————————",        null, false },
		{ "—info_1",      "————————————Cyberpunk 2077 - Main Game Splits—————————————",   null, false },
		{ "—separator_1", "—————————————————————————————————————————————————————",        null, false },

		// Main Game
		{ "—main_game",                                    "Main Game",                                    null,                    true },
			// Prologue - From the beginning to when V meets Jackie
			{ "—prologue",                                     "Prologue (Life Path)",                         "—main_game",             true  },

				{ "q000_corpo",                                   "The Corpo",                                    "—prologue",              false },
				{ "q000_nomad",                                   "The Nomad",                                    "—prologue",              false },
				{ "q000_street_kid",                              "The Streetkid",                                "—prologue",              true  },
			
			// Act 1 - From the first mission with Jackie to the Title Screen when Dex kills V
			{ "—act_1",                                        "Act 1 (Title Screen)",                         "—main_game",             true  },

				{ "q000_tutorial",                                "Practice Makes Perfect [optional]",            "—act_1",                 false },
				{ "q001_intro",                                   "The Rescue",                                   "—act_1",                 true  },
				{ "q001_01_victor",                               "The Ripperdoc",                                "—act_1",                 true  },
				{ "q001_02_dex",                                  "The Ride",                                     "—act_1",                 true  },
				{ "q003_maelstrom",                               "The Pickup",                                   "—act_1",                 true  },
				{ "q004_braindance",                              "The Information",                              "—act_1",                 true  },
				{ "q005_heist",                                   "The Heist",                                    "—act_1",                 true  },
			
			// Interlude - Jhonny Silverhand's assault on the Arasaka Tower
			{ "—interlude",                                    "Interlude (Jhonny Silverhand)",                "—main_game",             true  },

				{ "q101_01_firestorm",                            "Love Like Fire",                               "—interlude",             true  },
			
			// Act 2 - From when V wake up in the junkyard to when V has to meet Hanako at the Embers
			{ "—act_2",                                        "Act 2",                                        "—main_game",             true  },

				{ "q101_resurrection",                            "Playing for Time",                             "—act_2",                 true  },

				{ "—evelyn_parker_path",                           "Evelyn Parker",                                "—act_2",                 true  },

					{ "q105_dollhouse",                               "Automatic Love",                               "—evelyn_parker_path",    true  },
					{ "q105_02_jigjig",                               "The Space in Between",                         "—evelyn_parker_path",    true  },
					{ "q105_03_braindance_studio",                    "Disasterpiece",                                "—evelyn_parker_path",    true  },
					{ "q105_04_judys",                                "Double Life",                                  "—evelyn_parker_path",    true  },
				
				{ "—anders_hellman_path",                          "Anders Hellman",                               "—act_2",                 true  },

					{ "q103_warhead",                                 "Ghost Town",                                   "—anders_hellman_path",   true  },
					{ "q104_01_sabotage",                             "Lightning Breaks",                             "—anders_hellman_path",   true  },
					{ "q104_02_av_chase",                             "Life During Wartime",                          "—anders_hellman_path",   true  },
				
				{ "—goro_takemura_path",                           "Goro Takemura",                                "—act_2",                 true  },

					{ "q112_01_old_friend",                           "Down on the Street",                           "—goro_takemura_path",    true  },
					{ "q112_02_industrial_park",                      "Gimme Danger",                                 "—goro_takemura_path",    true  },
					{ "q112_03_dashi_parade",                         "Play It Safe",                                 "—goro_takemura_path",    true  },
					{ "q112_04_hideout",                              "Search and Destroy",                           "—goro_takemura_path",    true  },

				{ "—alt_cunningham_path",                          "Alt Cunningham",                               "—act_2",                 true  },

					{ "q110_01_voodoo_boys",                          "M'ap Tann Pèlen",                              "—alt_cunningham_path",   true  },
					{ "q110_voodoo",                                  "I Walk the Line",                              "—alt_cunningham_path",   true  },
					{ "q110_03_cyberspace",                           "Transmission",                                 "—alt_cunningham_path",   true  },
					{ "q108_johnny",                                  "Never Fade Away",                              "—alt_cunningham_path",   true  },
				
				{ "sq032_tapeworm",                               "Tapeworm",                                     "—act_2",                 true  },
				
			// Act 3 - Point of no return
			{ "—act_3",                                        "Act 3",                              "—main_game",             true  },

				{ "02_sickness",                                  "Nocturne Op55N1",                              "—act_3",                true  },

				{ "—arasaka_ending",                              "Arasaka",                                      "—act_3",                false },

					{ "—hanako_ending",                               "Hanako Arasaka",                               "—arasaka_ending",       false },

						{ "q113_rescuing_hanako",                         "Last Caress",                                  "—hanako_ending",        true  },
						{ "q113_corpo",                                   "Totalimmortal",                                "—hanako_ending",        true  },
				
				{ "—mikoshi_ending",                               "Mikoshi",                                      "—act_3",                false },

					{ "—panam_ending",                                "Aldecaldos",                                   "—mikoshi_ending",       false },

						{ "q114_01_nomad_initiation",                     "We Gotta Live Together",                       "—panam_ending",         true  },
						{ "q114_02_maglev_line_assault",                  "Forward to Death",                             "—panam_ending",         true  },
						{ "q114_03_attack_on_arasaka_tower",              "Belly of the Beast",                           "—panam_ending",         true  },
						
					
					{ "—rogue_ending",                                "The Afterlife",                                "—mikoshi_ending",        false },

						{ "q115_afterlife",                               "For Whom the Bell Tolls",                      "—rogue_ending",         true  },
						{ "q115_rogues_last_flight",                      "Knockin' on Heaven's Door",                    "—rogue_ending",         true  },

					{ "—jhonny_ending",                               "Secret Ending",                                "—mikoshi_ending",       false },

						{ "09_solo",                                      "(Don't Fear) The Reaper",                      "—jhonny_ending",        true  },

				{ "q116_cyberspace",                              "Changes",                                      "—act_3",                 false },
			
			// Epilogue - After Arasaka Tower assault and ending cinematics
			{ "—epilogue",                                     "Epilogue",                                     "—main_game",             false },

				{ "q201_heir",                                    "Where is My Mind?",                            "—epilogue",              false },

				{ "q202_nomads",                                  "All Along the Watchtower",                     "—epilogue",              false },

				{ "q203_legend",                                  "Path of Glory",                                "—epilogue",              false },
				
				{ "q204_reborn",                                  "New Dawn Fades",                               "—epilogue",              false },

		{ "—separator_2", "—————————————————————————————————————————————————————",        null, false },
		{ "—info_2",      "———————————Cyberpunk 2077 - Phantom Liberty Splits——————————", null, false },
		{ "—separator_3", "—————————————————————————————————————————————————————",        null, false },

		// Phantom Liberty DLC
		{ "—phantom_liberty",                          "Phantom Liberty",                          null,                    false },

			{ "q301_crash",                                "Dog Eat Dog",                               "—phantom_liberty",      true  },
			{ "q301_finding_myers",                        "Hole in the Sky",                           "—phantom_liberty",      true  },
			{ "q301_q302_rescue_myers",                    "Spider and the Fly",                        "—phantom_liberty",      true  },
			{ "q302_reed",                                 "Lucretia My Reflection",                    "—phantom_liberty",      true  },
			{ "q303_baron",                                "The Damned",                                "—phantom_liberty",      true  },
			{ "q303_hands",                                "Get It Together",                           "—phantom_liberty",      true  },
			{ "q303_songbird",                             "You Know My Name",                          "—phantom_liberty",      true  },
			{ "q304_stadium",                              "Birds with Broken Wings",                   "—phantom_liberty",      true  },
			{ "q304_netrunners",                           "I've Seen That Face Before",                "—phantom_liberty",      true  },
			{ "q304_deal",                                 "Firestarter",                               "—phantom_liberty",      true  },

			// If you decide to betray Songbird during Firestarter
			{ "—solomon_reed_path",                        "Betray Songbird",                           "—phantom_liberty",      false },

				{ "q305_prison_convoy",                        "Black Steel In The Hour of Chaos",          "—solomon_reed_path",    true  },
				{ "q305_bunker",                               "Somewhat Damaged",                          "—solomon_reed_path",    true  },
				{ "q305_border_crossing",                      "Leave in Silence",                          "—solomon_reed_path",    true  },
				{ "q305_reed_epilogue",                        "Four Score and Seven",                      "—solomon_reed_path",    true  },
				{ "q305_postcontent",                          "This Corrosion",                            "—solomon_reed_path",    true  },

			// If you decide to betray Reed during Firestarter
			{ "—songbird_path",                            "Betray Reed",                               "—phantom_liberty",      true  },

				{ "q306_devils_bargain",                       "The Killing Moon",                          "—songbird_path",        true  },

				// If V surrenders Songbird to Reed
				{ "—surrend_songbird",                         "Surrend Songbird",                          "—songbird_path",        false },

					{ "q306_reed_epilogue",                        "Through Pain to Heaven",                    "—surrend_songbird",     true  },

				// If V helps Songbird to escape
				{ "—help_songbird",                            "Help Songbird",                             "—songbird_path",        false  },

					{ "q306_somi_epilogue",                        "Unfinished Sympathy",                       "—help_songbird",        true },
					{ "q306_postcontent",                          "From Her to Eternity",                      "—help_songbird",        true },




		{ "—separator_4", "—————————————————————————————————————————————————————",          null, false },
		{ "—info_3",      "————————————DEBUG INFORMATIONS SETTINGS———————————",             null, false },
		{ "—separator_5", "—————————————————————————————————————————————————————",          null, false },

		{ "—quest_state",   "Current Objective", null, false },
		{ "—mission_state", "Current Mission",   null, false },
		{ "—is_paused",      "Is game paused",   null, false },

		{ "—separator_6", "—————————————————————————————————————————————————————",          null, false },
		{ "—info_4",      "—————WARNING: Save Splits after using the setting bellow——————", null, false },
		{ "—separator_7", "—————————————————————————————————————————————————————",          null, false },

		{ "—auto_split_name", "Automatically create splits based on the checked missions",  null, false },
	};

	vars.splits = new Dictionary<string, (string label, int index)>();
	// adds missions label and settings to the Scriptable Autosplit configuration settings.
	for ( int index = 0; index < splitSettings.GetLength(0); index++ ) {
		settings.Add(splitSettings[index, 0], splitSettings[index, 3], splitSettings[index, 1], splitSettings[index, 2]);
		
		// starting with '—' means it is not a split and shoul not be added in the splits list.
		if ( !splitSettings[index, 0].StartsWith("—") )
			vars.splits[splitSettings[index, 0]] = (splitSettings[index, 1], index);
	};

	vars.splitted = new HashSet<string>();
}

// Get called when you boot up the game
init
{
	string detected = modules.First().FileVersionInfo.ProductVersion;
	version = detected;

	// Show a Message Box if the game's version detected is not supported by the autosplitter
	var supported = (HashSet<string>)vars.SupportedVersions;
	if (!supported.Contains(detected) && !vars.versionWarned)
	{
		vars.versionWarned = true;
		using (var overlay = new Form
		{
			FormBorderStyle = FormBorderStyle.None,
			StartPosition = FormStartPosition.Manual,
			Bounds = SystemInformation.VirtualScreen, // prevent the user from clicking outside of the MessageBox
			TopMost = true,
			ShowInTaskbar = false,
			BackColor = System.Drawing.Color.Black,
			Opacity = 0.35
		})
		{
			overlay.Show();
			MessageBox.Show(
				overlay,
				"Game version " + detected + " unsuported.\n" +
				"Autosplitter may not work properly.\n\n" +
				"Supported version(s) : " + string.Join(", ", supported),
				"LiveSplit | Cyberpunk 2077",
				MessageBoxButtons.OK, MessageBoxIcon.Warning
			);
		}
	}

	// Loading detection made by Meta and Radioactive03.
	vars.loading    = false;
	vars.LoadingPtr = IntPtr.Zero;
	var module      = modules.First();
	var scanner     = new SignatureScanner(game, module.BaseAddress, module.ModuleMemorySize);

	vars.LoadingPtr = scanner.Scan(new SigScanTarget(2, "89??????????F0????????????????48FF??33??4889??????????E8????????4584") { 
		OnFound = (process, scanners, addr) => addr + 0x4 + process.ReadValue<int>(addr)
	});

	if (vars.LoadingPtr == IntPtr.Zero)
		throw new Exception("Game engine not initialized - retrying");

	vars.loadingWatcher = new MemoryWatcher<int>(vars.LoadingPtr);
}

// Get called every frame in LiveSplit, you can change the refresh in LS settings
update
{
	vars.loadingWatcher.Update(game);

	// if enabled, displays the current objective
	if (settings["—quest_state"]) 
		vars.SetTextComponent("Cur. Objective", string.IsNullOrEmpty(vars.GetObjective(current)) ? "-" : vars.GetObjective(current)); 

	// if enabled, displays the current mission
	if (settings["—mission_state"])
		vars.SetTextComponent("Cur. Mission", string.IsNullOrEmpty(vars.GetMission(current)) ? "-" : vars.GetMission(current));

	// if enabled, displays if the game is paused
	if (settings["—is_paused"])
		vars.SetTextComponent("Is paused", current.paused == 1 ? "Yes" : "No");

	// Automatically update the splits layout. The game needs to be open and timer not running
	if (settings["—auto_split_name"] && timer.CurrentPhase == TimerPhase.NotRunning && vars.splits.Count > 0)
	{
		var splits_names = new List<string>();

		foreach (var entry in (Dictionary<string, (string label, int index)>)vars.splits)
		{
			// add only if the segment is checked in settings
			if (settings[entry.Key])
				splits_names.Add(entry.Value.label);
		}

		// check if the selected splits are different
		string signature = string.Join("|", splits_names);
		if (vars.splits.Count > 0 && signature != vars.lastSignature)
		{
			vars.lastSignature = signature;

			int oldCount = timer.Run.Count;
			foreach (string split in splits_names)
				timer.Run.Add(new LiveSplit.Model.Segment(split));   // adds the new splits
			
			for (int i = 0; i < oldCount; i++)
				timer.Run.RemoveAt(0);                              // removes the old splits

			timer.Run.HasChanged = true;
		}
	}

	// if (current.mission != old.mission) print("[CP2077] mission: " + vars.GetMission(old) + " -> " + vars.GetMission(current));
}

// start the timer when the mission go from "generic_sts_quest" to anything else
start
{
	return (vars.GetMission(old) == "generic_sts_quest" && vars.GetMission(current) != vars.GetMission(old));
}

// split the timer if the mission has changed, both previous and current mission are in the splits Dictionary and the current mission is lower in the tree than the previous one.
// a previous mission is registered only if it is in the splits Dictionary
split
{
	string m = vars.GetMission(current);

	if ( string.IsNullOrEmpty(m) || !vars.splits.ContainsKey(m) )
		return false;

	string previous = vars.previous;
	if ( m == previous )
		return false;

	vars.previous = m;
	if ( previous == null )
		return false;

	// to prevent multiple splits on the same mission, for exemple if you die or reload a save file
	if ( !vars.splitted.Add(previous) )
		return false;

	// splits only if a mission is lower in the tree
	if (vars.splits[m].index <= vars.splits[previous].index)
    	return false;

	return settings[previous];
}

// pause the timer if the game is loading or the pause menu is open (do not apply to game menu: Map, inventory, etc)
isLoading
{
	bool loading = (vars.loadingWatcher.Current >= 6 && vars.loadingWatcher.Current % 4 == 2);

	return loading || vars.isPaused(current);
}

exit
{
	timer.IsGameTimePaused = true;
}

shutdown
{
	timer.OnStart -= vars.TimerStart;
}