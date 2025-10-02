## Install: ##
- Download zip, rename "HKSLootCouncil-main" to "HKSLootCouncil" and place on your addons folder.


## Description: ##
- The addon uses the lua file called LCTable.lua to read entries and match name of bosses, loot tables and other items, such a trash loot drops.
- When you start looting, the addon scans all drops for matches in the table, and if it finds it, it puts the item in a frame/window, along with the top 5 people on the LC list for that item. The master looter can then click any of the player names to give the item directly.
- If for some reason, the ML can't give the player loot; like full inventory or player not eligible to receive loot, disconnects etc. The addon will display an error message in your default chat frame and give you the oppertunity to try again or select another player.
- It will also display messages for loot that is successfully distributed through the addon. Can be toggled on and off with in-game commands:
      "/run HKSLootCouncilOptions.LCItemReceivedMsg = false"	
      "/run HKSLootCouncilOptions.LCNoteOnDrop = false"
- Fully compatible with RollFor addon.
![demo HKSLC](https://github.com/user-attachments/assets/e0811328-6bce-4b4c-a8c9-7a36fa99d037)
