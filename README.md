# Cyberpunk 2077 Auto Splitter for LiveSplit (PC)

An auto splitter and load remover for **Cyberpunk 2077**, written as a LiveSplit script (`.asl`).
Splits are based on **missions**: pick the ones you want in the settings, and the script automatically splits when they are finished.

## Features

- **Load removal** – pauses the Game Time during loading screens.
- **Pause menu detection** – pauses the Game Time while the pause menu is open (the map, inventory, journal, etc. do not pause it).
- **Mission splits** – splits when the game moves on to the next mission of the list.
  - Missions are grouped by act in the settings, and every mission has its own checkbox.
  - The default selection follows the any% route (as of 11/10/2026).
  - Missions that are not in the list are ignored.
- **Automatic splits creation** – recreates the segments of your LiveSplit layout from the checked missions, so you don't have to add or remove them by hand.
- **Information labels** – adds text components at the bottom of your layout showing the current objective, the current mission, and whether the game is paused.
- **Game version check** – warns you with a message box if your game version is not supported.

## Requirements

- Windows and [LiveSplit](https://livesplit.org/downloads/).
- Cyberpunk 2077 **version 2.31**.

## Installation

1. Download `Cyberpunk2077.asl` and place it somewhere you can remember.
2. In LiveSplit, right click → **Edit Layout…** → **+** → **Control** → **Scriptable Auto Splitter**.
3. Enter the script's path or click **Browse…** and choose `Cyberpunk2077.asl`.
5. Open the component settings (double click **Scriptable Auto Splitter**) and check the missions you want to split on.

## Settings

| Setting | Description |
|---|---|
| Mission checkboxes | One checkbox per mission, grouped by act. A checked mission splits when it is finished. |
| Current Objective | Shows the current objective in the layout. |
| Current Mission | Shows the current mission in the layout. |
| Is game paused | Shows whether the pause menu is open. |
| Automatically create splits based on the checked missions | Recreates your LiveSplit segments from the checked missions. |

To remove an information label, uncheck it in the settings and delete the matching component in the layout editor (select it and click **−**).

### ⚠️ Automatic splits creation

This option **replaces the segments of the loaded splits file**, including names and times. **Save your splits first.**
It only runs while the game is open and the timer is stopped. Once your segments are set, uncheck the option and save your splits file.

## How splitting works

The script reads the current mission ID from the game's memory. When the mission changes from one mission of the list to another, the mission you just left is considered finished and splits if its checkbox is checked.

- A mission that is not in the list is ignored, and is never remembered as the previous mission.
- Unchecked missions still count as passed, they just don't split.
- Your LiveSplit file must contain as many segments as the number of checked missions. LiveSplit moves to the next segment on each split, whatever the segment names are.

## Supported versions

| Game version | Status |
|---|---|
| 2.31 | Supported |
| Other | Not supported: Will be added later|


## Credits

- Load detection was by **Meta** and **Radioactive03**.
