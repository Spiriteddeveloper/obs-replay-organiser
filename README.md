# OBS Replay Organiser

A lightweight, native Lua script for OBS Studio that automatically renames and organises Replay Buffer clips based on your currently active Windows application. 

Most naming scripts use the obs game capture properties to find the game name which was an issue for me. This script uses native Windows APIs to check your active window directly which lets it work with display capture.

Runs natively in OBS using LuaJIT FFI. No external dependencies or Python required.

* **Shadowplay-Style Folders:** Automatically creates a subfolder for the active game and moves the clip into it (optional).
* **Smart Renaming:** Preserves your default OBS timestamps while prepending the game title.

## Requirements
* OBS Studio
* Windows (The script relies on the `user32` and `kernel32` Windows APIs)

## Installation
1. Download `replay_organiser.lua` from the releases page or clone the repository.
2. Open OBS Studio.
3. Click on **Tools** > **Scripts** in the top menu.
4. Click the **+** (plus) icon in the bottom left of the Scripts window.
5. Locate and select the `replay_organiser.lua` file.

## Usage & Configuration
Once added to OBS, the script runs entirely in the background. 

* **To save a clip:** Simply play your game and press your standard OBS "Save Replay" hotkey. The script will wait for the file to finish saving, then automatically rename and move it.
* **To toggle folders:** Click on the script in the OBS Scripts window. On the right side, you can check or uncheck the box to "Organize clips into Shadowplay-style subfolders".

## Note
Ensure your standard OBS Output filename formatting includes a timestamp (e.g., `%CCYY-%MM-%DD %hh-%mm-%ss`) so clips do not overwrite each other.

## Inspiration/Credits
the project I originally was trying to use that didn't work with display capture. 
https://obsproject.com/forum/resources/recording-organizer.2230/
