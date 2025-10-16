--[[ An Addon for Loot Council and tracking.
TODO:		
		- Make it edit EP/GP too.
		
		- Learn from rollfor to display an actual link and texture for the item in the frame. make it smaller and sleaker.
			- only 2 buttons? 1 for #1 and then another for opening list?
		
		- class colors for messages and buttons maybe?

NOTES:	
			Turning off messages:
		- 	/run HKSLootCouncilOptions.LCItemReceivedMsg = false
		-	/run HKSLootCouncilOptions.LCNoteOnDrop = false
]]

----------------[		DECLARE VARIABLES		]----------------
-- queue system
local LCQueue = {}  -- holds items still to process.
local LCIndex = 1   -- current index in queue.
local LCCount = 0	-- to display how many entires in table.

-- options table.
if not HKSLootCouncilOptions then
	HKSLootCouncilOptions = {
		LCItemReceivedMsg = true,
		LCNoteOnDrop = false,
		DiscordMSG = true,
	}
end

-- bosses table. to seperate bosses who can drop neck and those who cant.
local K40Bosses = {
	["Keeper Gnarlmoon"] = false,
	["Ley-Watcher Incantagos"] = false,
	["Anomalus"] = false,
	["Echo of Medivh"] = false,
	["King"] = true,
	["Sanv Tas'Dal"] = true,
	["Rupturan the Broken"] = true,
	["Kruul"] = true,
	["Mephistroth"] = true,
}

local trackedRecipes = {
	["Formula: Enchant Gloves - Arcane Power"] = true,
	["Formula: Enchant Gloves - Fire Power"] = true,
	["Formula: Enchant Gloves - Frost Power"] = true,
	["Formula: Enchant Gloves - Healing Power"] = true,
	["Formula: Enchant Gloves - Holy Power"] = true,
	["Formula: Enchant Gloves - Nature Power"] = true,
	["Formula: Enchant Gloves - Shadow Power"] = true,
	["Formula: Enchant Gloves - Superior Agility"] = true,
	["Formula: Enchant Gloves - Threat"] = true,
	["Formula: Enchant Cloak - Stealth"] = true,
	["Formula: Enchant Cloak - Dodge"] = true,
	["Formula: Enchant Weapon - Healing Power"] = true,
	["Formula: Enchant Weapon - Spell Power"] = true,
	["Plans: Elemental Sharpening Stone"] = true,
	["Pattern: Core Felcloth Bag"] = true,
	["Pattern: Core Armor Kit"] = true,
	["Pattern: Flarecore Wraps"] = true,
	["Schematic: Biznicks 247x128 Accurascope"] = true,
	["Schematic: Force Reactive Disk"] = true,
	["Schematic: Core Marksman Rifle"] = true,
	["Formula: Eternal Dreamstone Shard"] = true,
	["Pattern: Dreamthread Mantle"] = true,
	["Pattern: Dreamhide Mantle"] = true,
	["Plans: Dreamsteel Mantle"] = true,
	["Recipe: Elixir of Greater Nature Power"] = true,
	["Formula: Enchant Chest - Mighty Mana"] = true,
}


-- for the ML ui stuff. 
local BUTTON_WIDTH   = 85
local BUTTON_HEIGHT  = 32
local BUTTON_COUNT   = 5
local BUTTON_PADDING = 10
local CLASS_COLORS = {
	["WARRIOR"] = "|cFFC79C6E",
	["PALADIN"] = "|cFFF58CBA",
	["DRUID"] = "|cFFFF7D0A",
	["PRIEST"] = "|cFFFFFFFF",
	["SHAMAN"] = "|cFF0070DE",
	["MAGE"] = "|cFF69CCF0",
	["WARLOCK"] = "|cFF9482C9",
	["HUNTER"] = "|cFFABD473", 
	["ROGUE"] = "|cFFFFF569"
}

local playerName = UnitName("player")
local _, playerClass = UnitClass("player")  -- second return is the english class token
local color = CLASS_COLORS[playerClass] or "|cFFFFFFFF"  -- fallback white
local playerClassColorName = color .. playerName .. "|r"

----------------[		FUNCTIONS		]----------------
function HKSPrint(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cffF24827[HKSLootHelper]: |r" .. msg)
end

local function GetColoredPlayerName(playerName)
    -- Try raid first
    for i = 1, 40 do
        local unit = "raid"..i
        if UnitName(unit) == playerName then
            local _, class = UnitClass(unit)
            local color = CLASS_COLORS[class]
            if color then
                return color..playerName.."|r"
            end
            return playerName
        end
    end
    -- Fallback: just return name
    return "|cffFF0000" .. playerName .. "|r"
end

function HKSLootCouncil_PrintAllLoot()
    -- 1) Boss loot
    if HKSBossLCData then
        for bossName, bossTable in pairs(HKSBossLCData) do
            HKSPrint(bossName .. ":")
            local items = {}
            for itemName in pairs(bossTable) do
                table.insert(items, itemName)
            end
            table.sort(items)
            for _, itemName in ipairs(items) do
                local players = bossTable[itemName]
                local numbered = {}
                local count = table.getn(players)
                for i = 1, math.min(5, count) do
                    table.insert(numbered, i..": "..players[i])
                end
                local list = table.concat(numbered, ", ")
                DEFAULT_CHAT_FRAME:AddMessage("   |cFFE2725B["..itemName.."]|r → "..list)
            end
        end
    else
        HKSPrint("No HKSBossLCData found.")
    end

    -- 2) Tier Neck loot
    if HKSTierNeckLCData then
        HKSPrint("Tier Neck (shared drops):")
        local items = {}
        for itemName in pairs(HKSTierNeckLCData) do
            table.insert(items, itemName)
        end
        table.sort(items)
        for _, itemName in ipairs(items) do
            local players = HKSTierNeckLCData[itemName]
            local numbered = {}
            local count = table.getn(players)
            for i = 1, math.min(5, count) do
                table.insert(numbered, i..": "..players[i])
            end
            local list = table.concat(numbered, ", ")
            DEFAULT_CHAT_FRAME:AddMessage("   |cFFE2725B["..itemName.."]|r → "..list)
        end
    else
        HKSPrint("No HKSTierNeckLCData found.")
    end

    -- 3) Trash Loot
    if HKSTrashLootLCData then
        HKSPrint("Trash Loot:")
        local items = {}
        for itemName in pairs(HKSTrashLootLCData) do
            table.insert(items, itemName)
        end
        table.sort(items)
        for _, itemName in ipairs(items) do
            local players = HKSTrashLootLCData[itemName]
            local numbered = {}
            local count = table.getn(players)
            for i = 1, math.min(5, count) do
                table.insert(numbered, i..": "..players[i])
            end
            local list = table.concat(numbered, ", ")
            DEFAULT_CHAT_FRAME:AddMessage("   |cFFE2725B["..itemName.."]|r → "..list)
        end
    else
        HKSPrint("No HKSTrashLootLCData found.")
    end
end

function HKSLootCouncil_PrintBossLoot(bossName)
    if not HKSBossLCData then
        HKSPrint("HardKnocksSocietyLCData is empty or missing.")
        return
    end

    local bossTable = HKSBossLCData[bossName]
    if not bossTable then
        -- not in our data
        return
    end

    HKSPrint(bossName .. ":")

    -- Collect and sort items
    local items = {}
    for itemName in pairs(bossTable) do
        table.insert(items, itemName)
    end
    table.sort(items)

    for _, itemName in ipairs(items) do
        local players = bossTable[itemName]
        local numbered = {}

        local count = table.getn(players)
        for i = 1, math.min(5, count) do
            table.insert(numbered, i..": "..players[i])
        end

        local list = table.concat(numbered, ", ")
        DEFAULT_CHAT_FRAME:AddMessage("   |cFFE2725B["..itemName.."]|r → "..list)
    end
end

function HKSLootCouncil_PrintDroppedLoot(bossName, lootType)
    local numLoot = GetNumLootItems()
    if numLoot == 0 then return end

    if lootType == "bossWithNecklace" or lootType == "bossWithoutNecklace" then
        if not HKSBossLCData then
            HKSPrint("HardKnocksSocietyLCData is empty or missing.")
            return
        end

        local bossTable = HKSBossLCData[bossName]
        if not bossTable then return end

        HKSPrint(bossName .. " (LC Items):")

        for slot = 1, numLoot do
            local _, itemName = GetLootSlotInfo(slot)

            -- check boss-specific loot
            if itemName and bossTable[itemName] then
                local players = bossTable[itemName]
                local numbered = {}
				local count = table.getn(players)
                for i = 1, math.min(5, count) do
					local colored = GetColoredPlayerName(players[i])
					table.insert(numbered, i..": "..colored)
                    --table.insert(numbered, i..": "..players[i])
                end
                local list = table.concat(numbered, ", ")
                DEFAULT_CHAT_FRAME:AddMessage("   |cFFE2725B["..itemName.."]|r → "..list)
            end

            -- extra check for neck table if this boss drops it
            if lootType == "bossWithNecklace" and HKSTierNeckLCData and HKSTierNeckLCData[itemName] then
                local players = HKSTierNeckLCData[itemName]
                local numbered = {}
				local count = table.getn(players)
                for i = 1, math.min(5, count) do
					local colored = GetColoredPlayerName(players[i])
					table.insert(numbered, i..": "..colored)
                    --table.insert(numbered, i..": "..players[i])
                end
                local list = table.concat(numbered, ", ")
                DEFAULT_CHAT_FRAME:AddMessage("   |cFFE2725B["..itemName.."]|r → "..list)
            end
        end

    elseif lootType == "trashLoot" then
        if not HKSTrashLootLCData then return end

		local foundAny = false
        for slot = 1, numLoot do
            local _, itemName = GetLootSlotInfo(slot)
            if itemName and HKSTrashLootLCData[itemName] then
				if not foundAny then
					HKSPrint("Trash Loot (LC Items):")
					foundAny = true
				end
                local players = HKSTrashLootLCData[itemName]
                local numbered = {}
				local count = table.getn(players)
                for i = 1, math.min(5, count) do
					local colored = GetColoredPlayerName(players[i])
					table.insert(numbered, i..": "..colored)
                    --table.insert(numbered, i..": "..players[i])
                end
                local list = table.concat(numbered, ", ")
                DEFAULT_CHAT_FRAME:AddMessage("   |cFFE2725B["..itemName.."]|r → "..list)
            end
        end
    end
end

function HKS_LootDateAndTime()
	local ts = time()
	local now = date("%Y-%m-%d %H:%M:%S", ts)

	HKSPrint("Loot recorded at: " .. now)
end

local function giveItemToName(item, name, itemIndex)
	for raidID = 1, 40 do
		if name == GetMasterLootCandidate(raidID) then -- !!!!! GetMasterLootCandidate(id) DOES NOT corresponds with for example UnitName(id). e.g: raid1 and MasterLootCandidate1 is not the same player.
			GiveMasterLoot(itemIndex, raidID)
			--HKSPrint("Giving "..item.." to " .. name)
			return
		end
	end
	HKSPrint("|cffFF0000ERROR:|r Couldn't give ".. item .. " to '" .. name .. "'. Check spelling, if player is missing or offline or not eligible for loot.")
end

local function isItemInLCTables(itemName)
    if not itemName then return false end

    -- Check HKSBossLCData (boss → items)
    for _, bossTable in pairs(HKSBossLCData) do
        if bossTable[itemName] then
            return true
        end
    end

    -- Check HKSTierNeckLCData (flat table)
    if HKSTierNeckLCData[itemName] then
        return true
    end

    -- Check HKSTrashLootLCData (flat table)
    if HKSTrashLootLCData[itemName] then
        return true
    end

    return false
end

local function isItemInRecipeTables(itemName)
	-- Check recipes (not >= epic threshold)
	if trackedRecipes[itemName] then
		return true
	end
end

local function topFiveWishListForItem(itemName)
    if not itemName then return nil end

    -- small helper for top 5
    local function getTop5(list)
        local top5 = {}
        local n = table.getn(list)  -- works in WoW 1.12
        for i = 1, math.min(5, n) do
            top5[i] = list[i]
        end
        return top5
    end

    -- Check HKSBossLCData (boss → items)
    for _, bossTable in pairs(HKSBossLCData) do
        local list = bossTable[itemName]
        if list then
            return getTop5(list)
        end
    end

    -- Check HKSTierNeckLCData (flat table)
    local list = HKSTierNeckLCData[itemName]
    if list then
        return getTop5(list)
    end

    -- Check HKSTrashLootLCData (flat table)
    list = HKSTrashLootLCData[itemName]
    if list then
        return getTop5(list)
    end

    return nil
end

function HKSLC_ChannelID()
	local LCChat = "HKSLOOTCOUNCIL"
	for i = 1, 10 do -- 10 is max number of channels player can join
		local id, name = GetChannelName(i)
		if name == LCChat then
			return id
		end
	end
	JoinChannelByName("HKSLOOTCOUNCIL")
	return nil
end

local function BuildLCQueue()
    LCQueue = {}
	LCCount = 0
    for itemIndex = 1, GetNumLootItems() do
        local _, lootName = GetLootSlotInfo(itemIndex)
        local itemLink = GetLootSlotLink(itemIndex)
		local itemIcon = GetLootSlotInfo(itemIndex)
        local top5 = topFiveWishListForItem(lootName)
        if top5 then
            table.insert(LCQueue, {
                itemIndex = itemIndex,
                itemLink = itemLink,
                topPlayers = top5,
				itemTexture = itemIcon,
            })
			LCCount = LCCount + 1
        end
    end
    LCIndex = 1
    HKSLootCouncil_ShowNextItemInQueue()
end

function HKSLootCouncil_ShowNextItemInQueue()
    if LCQueue[LCIndex] then
        local entry = LCQueue[LCIndex]
        ShowMasterLooterFrame(entry.itemLink, entry.topPlayers, entry.itemIndex, entry.itemTexture)
    else
		if MasterLooterFrame and MasterLooterFrame:IsShown() then
			MasterLooterFrame:Hide()
		end
    end
end

----------------[		USER INTERFACE			]----------------

-- Close button creator
local function CreateCloseButton(frame)
  local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeButton:SetWidth(32)
  closeButton:SetHeight(32)
  closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
  closeButton:SetScript("OnClick", function()
	LCIndex = LCIndex + 1
	HKSLootCouncil_ShowNextItemInQueue()
  end)
end

-- Action button creator (for players)
local function CreatePlayerButton(frame, playerName, itemName, index, onClickAction)
  local panelWidth = frame:GetWidth()
  local spacing = (panelWidth - (BUTTON_COUNT * BUTTON_WIDTH)) / (BUTTON_COUNT + 1)

  local button = CreateFrame("Button", nil, frame, UIParent)
  button:SetWidth(BUTTON_WIDTH)
  button:SetHeight(BUTTON_HEIGHT)
  button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", index*spacing + (index-1)*BUTTON_WIDTH, BUTTON_PADDING)

  -- Set button text (player name)
  button:SetText(index.. ". " ..GetColoredPlayerName(playerName))
  local font = button:GetFontString()
  font:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

  -- Dark background
  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(button)
  bg:SetTexture(1, 1, 1, 1)
  bg:SetVertexColor(0.2, 0.2, 0.2, 1)

  -- Press/hover effects
  button:SetScript("OnMouseDown", function() bg:SetVertexColor(0.6, 0.6, 0.6, 1) end)
  button:SetScript("OnMouseUp",   function() bg:SetVertexColor(0.4, 0.4, 0.4, 1) end)
  button:SetScript("OnEnter", function()
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText("|cffFFFFFFGive "..GetColoredPlayerName(playerName).."|cffFFFFFF: |cffa335ee"..itemName, nil, nil, nil, nil, true)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1)
      GameTooltip:Show()
  end)
  button:SetScript("OnLeave", function()
      bg:SetVertexColor(0.2, 0.2, 0.2, 1)
      GameTooltip:Hide()
  end)

  -- Functionality
  button:SetScript("OnClick", function()
      if onClickAction then
          onClickAction(playerName, itemName)
      end
  end)

  return button
end

-- Main frame creator
local function CreateMLootFrame()
  local frame = CreateFrame("Frame", "MasterLooterFrame", UIParent)
  frame:SetWidth(500) -- adjust to fit 5 buttons
  frame:SetHeight(120)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropColor(0, 0, 0, 1)

  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function () frame:StartMoving() end)
  frame:SetScript("OnDragStop", function () frame:StopMovingOrSizing() end)

  CreateCloseButton(frame)
  frame.buttons = {}
  frame:Hide()
  
  -- addon title at the top
  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.title:SetPoint("TOP", frame, "TOP", 0, -10)  -- adjust offset
  frame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
  frame.title:SetText("|cffF24827HKS Loot Helper:|r")
  
  -- item index and table index at top left
  frame.index = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.index:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)  -- adjust offset
  frame.index:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
  frame.index:SetText("|cffFFFFFFItem: " .. LCIndex .. "/" .. LCCount .. "|r")
  
  
  -- attach the item label to the frame itself
  frame.itemLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.itemLabel:SetPoint("TOP", frame, "TOP", 0, -45)
  frame.itemLabel:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
  frame.itemLabel:SetText("")
  
  -- create an icon texture to the left of the item label
  frame.itemIcon = frame:CreateTexture(nil, "ARTWORK")
  frame.itemIcon:SetWidth(20)
  frame.itemIcon:SetHeight(20)
  frame.itemIcon:SetPoint("RIGHT", frame.itemLabel, "LEFT", -5, 0)
  frame.itemIcon:Hide()

  return frame
end
local masterLooterFrame = CreateMLootFrame()

-- Public API: show frame with top5 players + item name
function ShowMasterLooterFrame(itemName, topPlayers, itemIndex, itemTexture)
  for _, b in ipairs(masterLooterFrame.buttons) do b:Hide() end
  masterLooterFrame.buttons = {}

  for i, player in ipairs(topPlayers) do
	if i > BUTTON_COUNT then break end
	local btn = CreatePlayerButton(masterLooterFrame, player, itemName, i, function(name, item)
		giveItemToName(item, name, itemIndex)
	end)
	table.insert(masterLooterFrame.buttons, btn)
  end
  
  if itemTexture then
	masterLooterFrame.itemIcon:SetTexture(itemTexture)
	masterLooterFrame.itemIcon:Show()
  else
	masterLooterFrame.itemIcon:Hide()
  end
  
  masterLooterFrame.title:SetText("|cffF24827HKS Loot Helper:|r")
  masterLooterFrame.index:SetText("|cffFFFFFFItem: " .. LCIndex .. "/" .. LCCount .. "|r")
  masterLooterFrame.itemLabel:SetText(itemName)

  masterLooterFrame:Show()
end

--[[ Minimap code in case we want it in the future.
function HKSLootCouncil_MinimapButton_OnClick()
	HKSPrint("Minimap button click")
end

-- Set tooltip for minimap button
function HKSLootCouncil_MinimapButton_OnEnter(self)
	if (this.dragging) then
		return
	end
	GameTooltip:SetOwner(HKSLootCouncil_MinimapButton, "ANCHOR_TOPRIGHT", -10, 0)
	HKSLootCouncil_MinimapButton_Details(GameTooltip)
end
function HKSLootCouncil_MinimapButton_Details(HKSLootCouncil, ldb)
	HKSLootCouncil:SetText("HKSLootCouncil Addon!\n|cffFFFFFFA loot Helper addon.")
end
-- Drag function for minimap button
if not HKSLootCouncil_MinimapPos then
	HKSLootCouncil_MinimapPos = 45
else
	HKSLootCouncil_MinimapPos = HKSLootCouncil_MinimapPos
end
function HKSLootCouncil_MinimapButton_DraggingFrame_OnUpdate()
	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin-xpos/UIParent:GetScale()+70
	ypos = ypos/UIParent:GetScale()-ymin-70

	HKSLootCouncil_MinimapPos = math.deg(math.atan2(ypos,xpos))
	HKSLootCouncil_MinimapButton_Reposition()
end
function HKSLootCouncil_MinimapButton_Reposition()
	HKSLootCouncil_MinimapButton:SetPoint("TOPLEFT","Minimap","TOPLEFT",52-(80*cos(HKSLootCouncil_MinimapPos)),(80*sin(HKSLootCouncil_MinimapPos))-52)
end
]]

----------------[		LOAD ADDON				]----------------
function HKSLootCouncil_OnLoad()
	this:RegisterEvent("ADDON_LOADED")
	this:RegisterEvent("PLAYER_LOGIN")
	
	SLASH_HKSLootHelper1 = "/hks"
	SlashCmdList["HKSLootHelper"] = HKSLootHelper_Command;
end

----------------[		COMMAND			]----------------
function HKSLootHelper_Command()
	if HKSLootCouncilOptions.DiscordMSG then
		HKSLootCouncilOptions.DiscordMSG = false
		HKSPrint("Will NOT post loot messages to discord!")
	else
		HKSLootCouncilOptions.DiscordMSG = true
		HKSPrint("Will post loot messages to discord!")
	end
end

----------------[		EVENT HANDLER			]----------------
function HKSLootCouncil_OnEvent(event)
	if (event == "ADDON_LOADED") and (arg1 == "HKSLootCouncil") then
		
		--Initialize functions
		HKSLC_ChannelID() -- we run it on startup because it joins the channel if we are not in it
		
	elseif event == "PLAYER_LOGIN" then
		DEFAULT_CHAT_FRAME:AddMessage("|cffF24827[HKSLootHelper]: |rAddon Loaded! type /hks for options.")
		-- Registering events.
		this:RegisterEvent("LOOT_OPENED") 		-- Create the loot queue and scan items.
		this:RegisterEvent("LOOT_CLOSED") 		-- Close any active loot windows or loot functions when you stop looting.
		this:RegisterEvent("CHAT_MSG_LOOT")		-- Verify given items and go to the next item in queue/close custom loot frame.
		this:RegisterEvent("CHAT_MSG_SYSTEM")	-- Catch messages when people trade items. For example after doing XMOG.
		
	elseif event == "LOOT_CLOSED" then
		if masterLooterFrame:IsShown() then
			masterLooterFrame:Hide()
		end
		
	elseif event == "LOOT_OPENED" then
		local zone = GetRealZoneText()
		if zone == "Tower of Karazhan" or zone == "The Rock of Desolation" then
			
			-- building the LC queue based on items in loot table matching with LC items..
			local m, p, r = GetLootMethod()
			if m == "master" and ( (p and p == 0) or (r and r == 0) ) then
				BuildLCQueue()
			end
			
			if HKSLootCouncilOptions.LCNoteOnDrop then
				-- Printing loot drops relevant to LC list in default chat frame.
				local name = UnitName("target")
				if K40Bosses[name] == true then -- true are boss keys who has Ephemeral necklace in their loot table.
					HKSLootCouncil_PrintDroppedLoot(name, "bossWithNecklace")
				elseif K40Bosses[name] == false then -- false are bosses who cannot drop neck.
					HKSLootCouncil_PrintDroppedLoot(name, "bossWithoutNecklace")
				else -- handle trash loot
					HKSLootCouncil_PrintDroppedLoot(name, "trashLoot")
				end
			end
		end
		
	elseif event == "CHAT_MSG_SYSTEM" and string.find(arg1, "trades item") then
		local zone = GetRealZoneText()
		if zone == "Tower of Karazhan" or zone == "The Rock of Desolation" or zone == "Molten Core" or zone == "Ruins of Ahn'Qiraj"
		or zone == "Temple of Ahn'Qiraj" or zone == "Blackwing Lair" or zone == "Emerald Sanctum" then
			-- Sending loot messages to custom channel. Hkschatbot reads and sends to discord channel.
			local m, p, r = GetLootMethod()
			local discord = HKSLootCouncilOptions.DiscordMSG
			if (m == "master" and ( (p and p == 0) or (r and r == 0) ) and discord)
			or (discord and itemName == "Heart of Mephistroth")
			then -- Only send msg to this channel if you are loot master yourself. (in case more ppl have addon). then -- Only send msg to this channpl have addon).
				local ch = HKSLC_ChannelID()
				if ch then
					SendChatMessage(arg1, "CHANNEL", nil, ch)
				end
			end
		end
		
	elseif event == "CHAT_MSG_LOOT" and ( string.find(arg1, "You receive loot") or string.find(arg1, "(.+) receives loot") ) then
		local zone = GetRealZoneText()
		if zone == "Tower of Karazhan" or zone == "The Rock of Desolation" then
			if string.find(arg1, "You receive loot") then
				local _, _, itemLink = string.find(arg1, "You receive loot: (.+).")
				local _, _, itemName = string.find(itemLink, "%[(.+)%]")
				if isItemInLCTables(itemName) then
				
					-- creating the LC loot frames.
					LCIndex = LCIndex + 1
					HKSLootCouncil_ShowNextItemInQueue()
					
					local arg1custom = playerClassColorName .. " receives: " .. itemLink .. "." -- Show playerName with class color in HKSPrint msg.
					local arg1custom2 = playerName .. " receives: " .. itemLink .. "." -- We dont need to send color formatted name to a channel that cant handle the formatting anyway. Just to be safe.
					
					-- Printing loot messages if options allow.
					if HKSLootCouncilOptions.LCItemReceivedMsg then
						HKSPrint(arg1custom)
					end
					
					-- Sending loot messages to custom channel. Hkschatbot reads and sends to discord channel.
					local m, p, r = GetLootMethod()
					local discord = HKSLootCouncilOptions.DiscordMSG
					if (m == "master" and ( (p and p == 0) or (r and r == 0) ) and discord)
					or (discord and itemName == "Heart of Mephistroth")
					then -- Only send msg to this channel if you are loot master yourself. (in case more ppl have addon). or if you are not, but have discord messages enabled and a specific item is looted.
						local ch = HKSLC_ChannelID()
						if ch then
							SendChatMessage(arg1custom2, "CHANNEL", nil, ch)
						end
					end
				end
			else
				local _, _, pName, itemLink = string.find(arg1, "(.+) receives loot: (.+).")
				local _, _, itemName = string.find(itemLink, "%[(.+)%]")
				if isItemInLCTables(itemName) then
				
					-- creating the LC loot frames.
					LCIndex = LCIndex + 1
					HKSLootCouncil_ShowNextItemInQueue()
					
					-- Printing loot messages if options allow.
					if HKSLootCouncilOptions.LCItemReceivedMsg then
						local colorName = GetColoredPlayerName(pName)
						HKSPrint(colorName .. " receives loot: " .. itemLink .. ".")
					end
					
					-- Sending loot messages to custom channel. Hkschatbot reads and sends to discord channel.
					local m, p, r = GetLootMethod()
					local discord = HKSLootCouncilOptions.DiscordMSG
					if (m == "master" and ( (p and p == 0) or (r and r == 0) ) and discord)
					or (discord and itemName == "Heart of Mephistroth")
					then -- Only send msg to this channel if you are loot master yourself. (in case more ppl have addon). or if you are not, but have discord messages enabled and a specific item is looted.
						local ch = HKSLC_ChannelID()
						if ch then
							SendChatMessage(arg1, "CHANNEL", nil, ch)
						end
					end
				end
			end
		------------------------------------------------- All other zones. ------------------------------------------------------------
		elseif zone == "Molten Core" or zone == "Ruins of Ahn'Qiraj" or zone == "Temple of Ahn'Qiraj" or zone == "Blackwing Lair" or zone == "Emerald Sanctum" then
			if string.find(arg1, "You receive loot") then
				local _, _, itemLink = string.find(arg1, "You receive loot: (.+).")
				local _, _, itemName = string.find(itemLink, "%[(.+)%]")			
				local arg1custom = playerClassColorName .. " receives: " .. itemLink .. "." -- Show playerName with class color in HKSPrint msg.
				local arg1custom2 = playerName .. " receives: " .. itemLink .. "." -- We dont need to send color formatted name to a channel that cant handle the formatting anyway. Just to be safe.
				local itemName2, _, itemRarity = GetItemInfo(itemLink)
				if isItemInRecipeTables(itemName) or itemRarity == 5 or itemRarity == 6 then -- Check for custom blues (recipes so far) or epic and legendary items.
				
					-- Sending loot messages to custom channel. Hkschatbot reads and sends to discord channel.
					local m, p, r = GetLootMethod()
					local discord = HKSLootCouncilOptions.DiscordMSG
					if (m == "master" and ( (p and p == 0) or (r and r == 0) ) and discord)
					or (discord and itemName == "Heart of Mephistroth")
					then -- Only send msg to this channel if you are loot master yourself. (in case more ppl have addon). or if you are not, but have discord messages enabled and a specific item is looted.
						local ch = HKSLC_ChannelID()
						if ch then
							SendChatMessage(arg1custom2 .. " → " .. zone .. ".", "CHANNEL", nil, ch)
						end
					end
					
					-- Printing loot messages if options allow.
					if HKSLootCouncilOptions.LCItemReceivedMsg then
						HKSPrint(arg1custom)
					end
				end
			else
				local _, _, pName, itemLink = string.find(arg1, "(.+) receives loot: (.+).")
				local _, _, itemName = string.find(itemLink, "%[(.+)%]")
				local itemName2, _, itemRarity = GetItemInfo(itemLink)
				if isItemInRecipeTables(itemName) or itemRarity == 5 or itemRarity == 6 then -- Check for custom blues (recipes so far) or epic and legendary items.
					
					-- Printing loot messages if options allow.
					if HKSLootCouncilOptions.LCItemReceivedMsg then
						local colorName = GetColoredPlayerName(pName)
						HKSPrint(colorName .. " receives loot: " .. itemLink .. ".")
					end
					
					-- Sending loot messages to custom channel. Hkschatbot reads and sends to discord channel.
					local m, p, r = GetLootMethod()
					local discord = HKSLootCouncilOptions.DiscordMSG
					if (m == "master" and ( (p and p == 0) or (r and r == 0) ) and discord)
					or (discord and itemName == "Heart of Mephistroth")
					then -- Only send msg to this channel if you are loot master yourself. (in case more ppl have addon).
						local ch = HKSLC_ChannelID()
						if ch then
							SendChatMessage(arg1 .. " → " .. zone .. ".", "CHANNEL", nil, ch)
						end
					end
				end
			end
		end
	end
end
