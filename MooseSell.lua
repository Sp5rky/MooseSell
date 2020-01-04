local OUR_NAME = "MooseSell"
OUR_VERSION = 1021
local DEBUG = nil
local Debug = DEBUG and function(s) DEFAULT_CHAT_FRAME:AddMessage(s, 1, 0, 0) end or function() return end  

-- Magic Numbers
local MIN_DESTROY_INTERVAL = 1

-- Our Addon Object
if (MooseSell and MooseSell.Version and MooseSell.Version > OUR_VERSION) then return end
MooseSell = MooseSell or {}
local ms = MooseSell
ms.AddonName = OUR_NAME
ms.Version = OUR_VERSION
ms.OptionsName = OUR_NAME
ms.TrashlistOptionsName = OUR_NAME .. "-Trashlist"
ms.currentItem = nil
ms.Events = ms.Events or {}

-- Set up for future localization
local L = LibStub("AceLocale-3.0"):GetLocale("MooseSell")
setmetatable( L, { __index = function(t, text) return text end })

-- Make library calls local
local type, tostring, tonumber, next, pairs, ipairs, setmetatable = type, tostring, tonumber, next, pairs, ipairs, setmetatable 
local math, string, table, tinsert = math, string, table, tinsert 

-- Make api calls local
local GetItemInfo = GetItemInfo
local GetContainerNumSlots = GetContainerNumSlots 
local GetContainerNumFreeSlots = GetContainerNumFreeSlots
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemID = GetContainerItemID
local PickupContainerItem = PickupContainerItem 
local CursorHasItem = CursorHasItem
local GetCursorInfo = GetCursorInfo
local DeleteCursorItem = DeleteCursorItem

-- Default Settings
defaultDB = {
   Version = OUR_VERSION,
   Minimap = true,
   MinimapPos = -42,
   Enabled = true,
   DellTrashList = true,
   Sell = false,
   Silent = false,
   useMaxVal = true,
   MaxVal = 500,
   useMinFree = true,
   MinFree = off,
   TrashList = {["Cracked Pottery"] = "9334",
		["Troll Sweat"] = "1520",
		["Moonberry Juice"] = "1645",
		["Broken Obsidian Club"] = "9335",
		["Crusted Bandages"] = "9332",
		["Tarnished Silver Necklace"] = "9333",},
   Count = 0,
   Value = 0,
   SoldCount = 0,
   SoldValue = 0,
   SellValue = 0,
   SellCount = 0,
}
local msDB = defaultDB


-- Locals
local msPrefix = "|cFFF88017MS :|r "
local events = ms.Events

-- Local functions
local function checkVersion()
	local db = MooseSellDB
	if (db and (not db.Version or db.Version < OUR_VERSION)) then
		db.Version = OUR_VERSION
		-- This is an old DB, so update it.
		-- (so far, all we changed is handling of MinFree and MaxVal)
		if (db.useMinFree == nil) then
			db.useMinFree = db.MinFree and true or false
		end
		if (db.useMaxVal == nil) then
			db.useMaxVal = db.MaxVal and true or false
		end
		if (db.Minimap == nil) then
			db.Minimap = true
		end
		if (db.MinimapPos == nil) then
			db.MinimapPos = 45
		end
	end
end

local function chatMsg(s, force, r, g, b)
   if (force and type(force) ~= "boolean") then
      r, g, b, force = force, r, g, nil
   end 
   if (not msDB.Silent or force) then
      DEFAULT_CHAT_FRAME:AddMessage(s, r, g, b)
   end
end


local function getFreeBagSlots()
   local freeslots = 0
   for i = 0, NUM_BAG_SLOTS do
      local free, btype = GetContainerNumFreeSlots(i) 
      if (btype == 0) then
         freeslots = freeslots + free
      end
   end
   return freeslots
end

local function pricecomp(a, b)
   if (a and a.value and b and b.value) then
      return (a.value < b.value)
   end
end

local function destroyJunk(listonly)
   listonly = (listonly == true) or false -- corrects problem when called by timed event
   if (not listonly and not msDB.Enabled) then return end
   local maxToDel = (msDB.useMinFree and not listonly) and msDB.MinFree - getFreeBagSlots()
   if (maxToDel and maxToDel < 1) then return end
   local prefix = listonly and L["Destroyable: "] or L["Destroyed: "]
   local count, icount, link, name, quality, stacksize, value, stackval, itemId = 0
   local delList = {}
   local item = {}
   for bag = 0,4 do
      for slot = 1,GetContainerNumSlots(bag) do
         itemId = GetContainerItemID(bag, slot)
         _, icount, _, _, _, _, link = GetContainerItemInfo(bag, slot)
    		if (link) then
    		   name, _, quality, _, _, _, _, stacksize, _, _, value = GetItemInfo(itemId)
    			stackval = value * stacksize
            if (quality == 0 and (not msDB.useMaxVal or stackval < msDB.MaxVal)) then
               item = {id = itemId, value = value, bag = bag, slot = slot, link = link, count = icount}
               tinsert(delList, item)
            elseif (msDB.TrashList[name] and msDB.DellTrashList == true and msDB.MaxVal >= (value * icount) ) then
               item = {id = itemId, value = value, bag = bag, slot = slot, link = link, count = icount}
               tinsert(delList, item)
    		   end
    	   end
   	end
   end
   if (#delList > 0) then
      local oType, recheckId
      local numToDel = (maxToDel and maxToDel < #delList) and maxToDel or #delList
      table.sort(delList, pricecomp)
      for i = 1, numToDel do
         item = delList[i]
         if (item and item.link) then
            if (not listonly) then
               PickupContainerItem(item.bag, item.slot)
					-- Check that the item on the cursor is the item we wanted to destroy
					oType, recheckId = GetCursorInfo()
               if (oType == "item" and recheckId == item.id) then
                  DeleteCursorItem()
                  msDB.Value = msDB.Value + item.value * item.count
                  msDB.Count = msDB.Count + item.count
				  local itemval = parseCopper(item.value * item.count)
                  chatMsg(msPrefix.."|cFFFF0000" .. prefix .. "|r" .. item.link .. " |cFFFF0000x" .. tostring(item.count) .. L [". valued at"] .. "|r: " .. itemval)
               end
            else -- for list only we don't confirm the item on the cursor
				  chatMsg(msPrefix.."|cFFFF0000" .. prefix .. "|r" .. item.link .. " |cFFFF0000x" .. tostring(item.count) .. L [". valued at"] .. "|r: " .. itemval)
                  count = count + item.count
            end
         end
      end
   end
   if (listonly) then
      local message
      if (count == 0) then
         message = L["Nothing to destroy."]
      else
         message = L["There are "] .. count .. L[" items to destroy."]
	   end
      chatMsg(msPrefix .. message)
	else
	   ms:GuiUpdate(ms.OptionsName)
	end
end

local scheduleDestroy
do
   local destroyHandle
   scheduleDestroy = function ()
      -- Make sure we wait our MIN_DESTROY_INTERVAL before trying to destroy.
      -- LOOT_CLOSED and item being in inventory are not simultaneous.
      events:CancelTimedCallback(destroyHandle)
      destroyHandle = events:SetTimedCallback(destroyJunk, MIN_DESTROY_INTERVAL)
   end
end


function parseCopper(cpval)

    local gold = math.floor(cpval / 10000);
	local silver = math.floor((cpval % 10000) / 100);
	local copper = (cpval % 10000) % 100;
    if (gold > 0 and silver > 0 and copper > 0) then
		return format(GOLD_AMOUNT_TEXTURE.." "..SILVER_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE, gold, 0, 0, silver, 0, 0, copper, 0, 0)
	elseif (gold > 0 and silver > 0 and copper == 0) then
		return format(GOLD_AMOUNT_TEXTURE.." "..SILVER_AMOUNT_TEXTURE, gold, 0, 0, silver, 0, 0)
    elseif (gold > 0 and silver == 0 and copper > 0) then
		return format(GOLD_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE, gold, 0, 0, copper, 0, 0)
	elseif (gold == 0 and silver > 0 and copper > 0) then
		return format(SILVER_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE, silver, 0, 0, copper, 0, 0)
	elseif (gold > 0 and silver == 0 and copper == 0) then
		return format(GOLD_AMOUNT_TEXTURE, gold, 0, 0)	
	elseif (gold == 0 and silver > 0 and copper == 0) then	
		return format(SILVER_AMOUNT_TEXTURE, silver, 0, 0)
	else
		return format(COPPER_AMOUNT_TEXTURE, copper, 0, 0)
	end
end

local function printStatus()
   local enabT = msDB.Enabled and L["ENABLED"] or L["DISABLED"]
   local sellEnabT = msDB.Sell and L["ENABLED"] or L["DISABLED"]
   local silentEnabT = msDB.Silent and L["ENABLED"] or L["DISABLED"]
   local threshT = msDB.useMinFree and tostring(msDB.MinFree) or L["DISABLED"]
   local maxvalT = msDB.useMaxVal and parseCopper(msDB.MaxVal) or L["DISABLED"]
   local totalvalT = parseCopper(msDB.Value)
   local totalsoldvalT = parseCopper(msDB.SoldValue)
   chatMsg(msPrefix.. L["Destroying junk is "] .. enabT, true)
   chatMsg(msPrefix.. L["Selling is "] .. sellEnabT, true)
   chatMsg(msPrefix.. L["Silent mode is "] .. silentEnabT, true)
   chatMsg(msPrefix.. L["Free bag slot threshold is "] .. threshT, true)
   chatMsg(msPrefix.. L["Max value threshold (per stack) is "] .. maxvalT, true)
   chatMsg(msPrefix.. L["The vendor value of all items ever sold by MooseSell is "] .. totalsoldvalT, true)
   chatMsg(msPrefix.. L["The vendor value of all items ever deleted by MooseSell is "] .. totalvalT, true)
end

local function freshenItemData(List)
   -- If an item is looked up for the first time since entering world,
   -- GetItemData() will return nil for info that has not yet arrived
   -- locally.  If we do this at the start, it should all be present
   -- whenever it is needed. New items won't be a problem because the
   -- data is already there when the item is added.
   for _, id in pairs(msDB.TrashList) do
      local _, link = GetItemInfo(id)
   end
end

local function fixPopup(doIt)
   local delPopup = StaticPopupDialogs["DELETE_ITEM"]
   if (doIt) then
      delPopup.text = DELETE_ITEM .. "\n\n"
	   delPopup.button3 = "MooseSell"
      delPopup.OnAlt = function (self)
         ms:AddCursorToDeleteList()
      end
   else
      delPopup.text = DELETE_ITEM
	   delPopup.button3 = nil
      delPopup.OnAlt = nil
   end
end

local function enable(doIt)
   msDB.Enabled = doIt
   if (doIt) then
      events:RegisterEvent("LOOT_CLOSED")
      ms:GuiUpdate(ms.OptionsName)
   else
      events:UnregisterEvent("LOOT_CLOSED")
      ms:GuiUpdate(ms.OptionsName)
   end
end

-- Events / Handlers

function events:LOOT_CLOSED(...)
	-- Use OnUpdate to schedule a destroyJunk
   --Debug("Received LOOT_CLOSED event")
   scheduleDestroy()
	return
end

function events:ADDON_LOADED(...)
   local addonName = ...
   if (addonName == OUR_NAME) then
      -- This only needs to happen once
      events:UnregisterEvent("ADDON_LOADED")
      -- Use default settings if saved variables (MooseSellDB) are not there
      if (MooseSellDB) then
         checkVersion()
         msDB = MooseSellDB
	   else
	      MooseSellDB = msDB
      end
	   -- Set the defaults as a metatable to the settings, in case any are not there (or new)
      setmetatable(msDB, { __index = function(l, index) return defaultDB[index] end})
      -- Make sure the client loads itemdata for everything in our TrashList
      freshenItemData(msDB.TrashList)
      -- Add Slash Commands
      -- First check if /ms is taken, as its only two letters (ok, 26^2/numAddons chance, but still ...)
      local usetc, n, cmd = true
      for addon, _ in pairs(SlashCmdList) do
         n = 1
         repeat
            cmd = _G["SLASH_"..addon..tostring(n)]
            if (cmd and cmd == "/ms") then
               usetc = nil
               break
            end
            n = n + 1
         until (not cmd)
         if (not usetc) then break end
      end
      SlashCmdList["MooseSell"] = function (...) ms:cmdParser(...) end
      SLASH_MooseSell1 = "/MooseSell"
      if usetc then
         SLASH_MooseSell2 = "/ms"
         chatMsg(msPrefix.. L["MooseSell loaded! Type '/ms' to list options."])
      else
         chatMsg(msPrefix.. L["MooseSell loaded! '/ms' is in use by another addon, use '/MooseSell' instead."], true)
      end
      -- Add options to Bliz addon config frame
      ms:LoadOptions()
      -- Start up the merchant seller module
      ms.Merchant:OnAddonLoaded()
      -- Set popup, and Enable (or not ...)
      fixPopup(true)
      enable(msDB.Enabled)
      -- We're done with this method forever
      events.ADDON_LOADED = nil
	  -- Add position button minimap
	  MooseSell_ButtonMinimap()
	  MooseSell_MinimapButton_Reposition()
   end
end

do
   --** -----Set up event handling, timers, and triggered callbacks. ----- **
   --**
   --**This code is re-usable.  A table 'events' should be defined at file
   --**scope, i.e. 'local events = {}'.  This section will add the following
   --**methods to the table:
   --**  events:RegisterEvent(eventname)
   --**  events:UnregisterEvent(eventname) -- returns handle used to cancel
   --**  events:SetTriggeredCallback(name, checkFunc, actionFunc, data, repeating)
   --**  events:CancelTriggeredCallback(handle)
   --**  events:SetTimedCallback(func, delay, data, repeating) -- returns handle used to cancel
   --**  events:CancelTimedCallback(handle)

   --**
   --**The following lines should be changed to be specific to the Add-On
   local initialLoadEvent = "ADDON_LOADED"
   local eventFrameName = "MooseSellMainFrame"
   --**

   --**There MUST be a table 'events', and it should not be global!
   if not (events and type(events) == "table" and events ~= _G[events]) then
      error("Table 'events' must be defined at the file level.")
   end

   --Create the frame if it doesn't exist, as well as the locals we need
   local eFrame = _G[eventFrameName] or CreateFrame("Frame", eventFrameName, UIParent)
   local callbacks = {}
   local timeSinceStart = 0
   
   --No need for OnUpdate until a timer / trigger is set
   eFrame:Hide()
   
   --Registered events will be redirected to events:EVENT_NAME(...)
   eFrame:SetScript("OnEvent", function(self, event, ...)
         events[event](events, ...)
      end)
   
   eFrame:RegisterEvent(initialLoadEvent)

   local function OnUpdate(self, elapsed)
      timeSinceStart = timeSinceStart + elapsed
      for handle, tEvent in pairs(callbacks) do 
         local data = tEvent.data 
         if (tEvent.check and tEvent.check(timeSinceStart - tEvent.eventStart, data)) then
            Debug("We are now trying to execute the action for " .. tEvent.name)
            tEvent.action(data)
            if (not tEvent.repeating) then
               callbacks[handle] = nil
               if not next(callbacks) then
                  eFrame:Hide()
               end
            end
         end
      end
   end
   eFrame:SetScript("OnUpdate", OnUpdate)
   
   function events:SetTriggeredCallback(eName, check, action, data, repeating)
   --This function is more generalized than needed in this addon at this time,
   --but I have it written, the cost is not high, and it could be useful later.
   --Params:
   --    eName --A name for the event/callback.  If unique, can be used to cancel the event.
   --    check --function(elapsed, data) used to check if a callback should trigger.
   --    action --function(data) will be called back if check returns true.
   --    data --arbitrary data to be passed to both check and action.
   --    repeating --If true, the event/callback will not be removed when triggered
   --          and until canceled will keep firing whenever check returns true.
   --Returns:
   --    handle --A unique identifier for this event/callback.  This should be used
   --          when canceling an event, as this is more efficient than using the
   --          event name.    
      Debug("Entered SetTriggeredCallback")
      if (type(check) ~= "function" or type(action) ~= "function") then
         return
      else
         Debug("We are setting up event : " .. eName)
         --if repeating then Debug("Event " .. eName .. " is repeating") end
         local tEvent = {
            eventStart = timeSinceStart,
            name = eName,
            check = check,
            action = action,
            data = data,
            repeating = repeating,
         }
         local handle = {}
         callbacks[handle] = tEvent
         eFrame:Show()
         return handle
      end                     
   end

   function events:SetTimedCallback(func, delay, data, repeating)
   --A more convenient way to set a simple timed callback. Can only be canceled
   --using the handle.
      local check = function(elapsed)
      	if (elapsed > delay) then
      		return true
      	end
      end
      return events:SetTriggeredCallback("generic_timer", check, func, data, repeating)  
   end
   
   function events:CancelTriggeredCallback(handle)
   --Parameter can be the handle returned when creating the triggered event,
   --or else the name given as the first parameter when creating the event.
   --It is less efficient and more dangerous to use the name, as the table of
   --callbacks must be searched, and all matching events will be canceled.
      if (type(handle) == "string") and callbacks then
         -- What, you can't be bothered to store the index?
         local eName = handle
         for h, tEvent in pairs(callbacks) do
            if (tEvent.name == eName) then
               callbacks[h] = nil
               if not next(callbacks) then
                  eFrame:Hide()
               end
            end
         end
      end
      if (callbacks and handle and callbacks[handle]) then
         --Debug("Canceling timed event : " .. callbacks[index].name)
         callbacks[handle] = nil
         if not next(callbacks) then
            eFrame:Hide()
         end
      end
   end
   events.CancelTimedCallback = events.CancelTriggeredCallback
   
   --Since the handlers are on the 'events' object, lets make registering intuitive
   function events:RegisterEvent(...)
      eFrame:RegisterEvent(...)
   end
   
   function events:UnregisterEvent(...)
      eFrame:UnregisterEvent(...)
   end 
end

-- Class methods
function ms:Enable(doIt, loud)
   enable(doIt)
   if (loud) then
      local msStatus = msDB.Enabled and L["ENABLED"] or L["DISABLED"]
      chatMsg(msPrefix.. L["MooseSell is "] .. msStatus .. ".", true)
   end
end

function ms:cmdParser(optionTxt)
	-- Really, most of this is sort of unecessary with the ui page added, will probably remove some options from help,
	-- although there is no real reason to actually remove them from the code
	if (not type(optionTxt) == "string" or optionTxt == "" or optionTxt == L["help"]) then
		chatMsg(msPrefix.. L["Options: destroy | sell | config | minfree | maxval | status | list | trashlist | remove | purge | value"], true)
		return
	end
	local listonly = false
	local option, arg2 = optionTxt:match("^(%S*)[%s,]*(.-)$")
	if (option == L["status"]) then
		printStatus()
		return
	elseif (option == L["frame"]) then
		 VendomaticFrame:Show();
		return
	elseif (option == L["config"]) then
		InterfaceOptionsFrame_OpenToCategory(ms.OptionsName) 
		return
	elseif (option == L["value"]) then
		local totalvalT = parseCopper(msDB.Value)
		chatMsg(msPrefix.. L["The vendor value of all items ever deleted by MooseSell is "] .. totalvalT, true)
		return
	elseif (option == L["list"]) then
		msDB.Silent = false
		if (next(msDB.TrashList)) then
			chatMsg(msPrefix.. L["MooseSell will always destroy these items:"], true)
			for _, id in pairs(msDB.TrashList) do
				local _, link = GetItemInfo(id)
				chatMsg(link)
			end
		else
			chatMsg(msPrefix.. L["Your MooseSell list is empty."], true)
		end
      return
   elseif (option == L["maxval"]) then
      local maxVal, maxvalT = tonumber(arg2)
      if (arg2 == L["off"]) then
         msDB.useMaxVal = false
         chatMsg(msPrefix.. L["MooseSell will delete items regardless of value."], true)
      elseif (maxVal and maxVal > 0) then
         msDB.useMaxVal = true
         msDB.MaxVal = maxVal
         maxvalT = parseCopper(maxVal)
         chatMsg(msPrefix.. L["MooseSell will only destroy items worth less than "] .. maxvalT .. L[" per stack."], true)
      else
         chatMsg(msPrefix.. L["Valid options are /ms maxval [ <value> | off ]"], true)
      end
      ms:GuiUpdate(ms.OptionsName)
      return
   elseif (option == L["threshold"] or option == L["minfree"]) then -- keeping threshold for backwards compatibility
      local numslots = tonumber(arg2)
      if (arg2 == L["off"]) then
         msDB.useMinFree = false
         chatMsg(msPrefix.. L["MooseSell will delete items immediately."], true)
      elseif (numslots and numslots > 0) then
         msDB.useMinFree = true
         msDB.MinFree = numslots
         chatMsg(msPrefix.. L["MooseSell will try to leave "] .. arg2 .. L[" slots free in you bags."], true)
      else
         chatMsg(msPrefix.. L["Valid options are /ms minfree [ <numslots> | off ]"], true)
      end
      ms:GuiUpdate(ms.OptionsName)
      return
   elseif (option == L["remove"]) then
      if (not arg2 or arg2 == "") then
         chatMsg(msPrefix.. L["Valid options are /ms remove [ <itemname> | ALL ]"], true)
      elseif (arg2 == L["ALL"]) then
         msDB.TrashList = {}
         ms:GuiMakeTrashlist()
         chatMsg(msPrefix.. L["Your MooseSell list is empty."], true)
      else
         msDB.TrashList[arg2] = nil
         ms:GuiMakeTrashlist()
         chatMsg(msPrefix .. arg2 .. L[" removed from MooseSell list!"], true)
      end
      ms:GuiUpdate(ms.TrashlistOptionsName)
      return 
   elseif (option == L["trashlist"]) then
      if (not arg2 or arg2 == "") then
         chatMsg(msPrefix.. L["Valid options are /ms trashlist [ <itemname> ]"], true)
      else
		ms:AddToDeleteList(arg2)
      end
      return
   elseif (option == L["destroy"]) then
      if (not arg2 or (arg2 ~= "on" and arg2 ~= "off")) then
         chatMsg(msPrefix.. L["Valid options are /ms destroy [ on | off ]"], true)
      elseif (arg2=="off") then
         ms.Enable(false, true)
         return
      else
         ms.Enable(true, true)
		end
--    elseif (option == L["off"]) then
-- 		MooseSell:Enable(false, true)
-- 		return
-- 	elseif (option == L["on"]) then
-- 		MooseSell:Enable(true, true)
--  --  The above has been changed to /ms destroy on|off to avoid confusion when selling is still enabled
   elseif (option == L["on"] or option == L["off"]) then
      chatMsg(msPrefix.. L["/ms on | off is no longer a valid option.  Use /ms destroy on | off ."], true)
	elseif (option == L["sell"]) then
      if (not arg2 or (arg2 ~= "on" and arg2 ~= "off")) then
         chatMsg(msPrefix.. L["Valid options are /ms sell [ on | off ]"], true)
		else
		   ms.Merchant:SellEnable(arg2=="on")
		   ms:GuiUpdate(ms.OptionsName)
		end
		return
   elseif (option == L["purge"]) then
      destroyJunk()
      return
   else
   	chatMsg(msPrefix.. L["MooseSell did not understand that option. Type '/ms help' for valid options."], true)
   	return
	end
   destroyJunk(listonly)
end

function ms:AddCursorToDeleteList()
   if (CursorHasItem()) then
      local itemType, itemId = GetCursorInfo()
      if (itemType and itemType == "item" and itemId) then
        ms:AddToDeleteList("item:" .. itemId)
		--DeleteCursorItem()	-- On supprime l'item su curseur
		ClearCursor()			-- On efface le curseur sans supprimer l'item
      end
   end
end

function ms:AddToDeleteList(itemstring)
   if itemstring then
      local _, _, itemId = string.find(itemstring, "item:(%-?%d+)")
      if itemId then
         local name, link, quality, _, _, _, _, _, _, _, value = GetItemInfo(itemId)
         if (name and type(name) == "string") then
            if (quality > 0 or (msDB.useMaxVal and value > msDB.MaxVal)) then
               msDB.TrashList[name] = itemId
               -- If the gui options list has been created, then we need to re-create it.
               ms:GuiMakeTrashlist()
               chatMsg(msPrefix .. link .. "|cFF00FF00" .. L[" added to your MooseSell list!"] .. "|r")
               ms:GuiUpdate(ms.TrashlistOptionsName)
               destroyJunk()
               return true
            else
               chatMsg(msPrefix.. L["This item would be deleted anyway."])
            end
         end
      end
   end
end

function ms:GSCString(cpval)
   -- Used by options, needs to return a simple string, so don't put it in
   -- one line, please:  parseCopper() returns three other values!!
   local gscString = parseCopper(cpval)
   return gscString
end

----------------------- Add frame ----------------------------------

local sellframestartindex = 1;

function MooseSell_FrameDragSell()
	local typeinfo, datainfo, secondaryinfo = GetCursorInfo(); -- item / itemID / link
	local itemName, itemLink, _, _, _, _, _, _, _, itemTexture, itemSellPrice = GetItemInfo(datainfo)
	-- Item out of the bag:
	if (typeinfo == "item" and itemSellPrice > 0) then
		local itemname = secondaryinfo
		local frametexture = getglobal("Vendomatic_OptionsSellFrame_DropBoxIconTexture");
		local framename = getglobal("Vendomatic_OptionsSellFrame_DropBoxText");
		frametexture:SetTexture(itemTexture);
		framename:SetWidth(230);
		framename:SetJustifyH("LEFT");
		framename:SetText(itemname);
		ClearCursor();
	else
		DEFAULT_CHAT_FRAME:AddMessage(msPrefix..itemLink.." "..L[" is not a valid item."], true)
		ClearCursor();
	end
end

function MooseSell_AddItem(itemstring)
	ms:AddToDeleteList(itemstring)
end

function MooseSell_SellFrameUpdate(index)
	MooseSell_SellFrameUpdateTexture(index)
	Vendomatic_sellstart = 1;
	if index ~= nil then
		Vendomatic_sellstart = index;
	end
	local counter = 1;
	local Vendomatic_sellend = Vendomatic_sellstart + 9;	-- nombres de bouton -1
	for i=Vendomatic_sellstart, Vendomatic_sellend do
		local button = getglobal("SellItemButton"..counter);
		local dbTrashlist = msDB.TrashList
		local list = {}   
		for name, _ in pairs(dbTrashlist) do
		tinsert(list, name)
		end
		table.sort(list)
		guiTrashlist = {}
		for i, name in ipairs(list) do
			shortItemString = name
			guiTrashlist[i] = shortItemString
		end
		local buttontext = guiTrashlist[i];
		button:SetText(buttontext);
		button:Show();
		counter = counter + 1;
	end
	for n=1, 10 do	-- nombres de bouton
		local button = getglobal("SellItemButton"..n);
		local gettext = button:GetText();
		if gettext == nil then
			button:Hide();
		end
	end
end

function MooseSell_SellFrameUpdateTexture(index)
	MooseSell_sellstart = 1;
	if index ~= nil then
		MooseSell_sellstart = index;
	end
	local counter = 1;
	local MooseSell_sellend = MooseSell_sellstart + 9;	-- nombres de bouton -1
	for i = MooseSell_sellstart, MooseSell_sellend do
		local buttonTexture = getglobal("SellItemButton_"..counter);
		local dbTrashlist = msDB.TrashList
		local list = {}   
		for name, _ in pairs(dbTrashlist) do
			itemID = tostring(dbTrashlist[name])
			tinsert(list, name)
		end
		table.sort(list)
		guiTrashlist = {}
		for i, name in ipairs(list) do
			itemID = tostring(dbTrashlist[name])
			guiTrashlist[i] = itemID
		end
		local itemIDTexture = guiTrashlist[i];
		if itemIDTexture ~= nil then
			--print(itemIDTexture)
			local _,_,_,_,_,_,_,_,_,itemtexture = GetItemInfo(itemIDTexture);
			buttonTexture:SetTexture(itemtexture);
			counter = counter + 1;
		end
	end
end

function MooseSell_HighlightFrame(name)
	VendomaticHighlightFrame:SetPoint("TOPLEFT", name, "TOPLEFT", -5, -3);
	VendomaticHighlightFrame:Show();
end

function MooseSell_Getsellrows()
	local dbTrashlist = msDB.TrashList
	Vendomatic_Exceptions_MaxRows = 0;
	for i,v in pairs(dbTrashlist) do
		Vendomatic_Exceptions_MaxRows = Vendomatic_Exceptions_MaxRows + 1;
	end
	return Vendomatic_Exceptions_MaxRows - 9;		-- nombres de bouton -1
end

function MooseSell_SellFrameMoveDown()
	local maxrows = MooseSell_Getsellrows();
	if ((sellframestartindex < maxrows) and (maxrows > 0)) then
		sellframestartindex = sellframestartindex + 10;
		MooseSell_SellFrameUpdate(sellframestartindex);
		MooseSell_SellFrameUpdateTexture(sellframestartindex);
	end
end

function MooseSell_SellFrameMoveUp()
	if (sellframestartindex > 1) then
		sellframestartindex = sellframestartindex - 10;
		MooseSell_SellFrameUpdate(sellframestartindex);
		MooseSell_SellFrameUpdateTexture(sellframestartindex);
	end
end

function MooseSell_Remove(SelectedSellItem)
	msDB.TrashList[SelectedSellItem] = nil;
	DEFAULT_CHAT_FRAME:AddMessage(msPrefix .. "[" .. SelectedSellItem .."]|cFF00FF00" .. L[" removed from MooseSell list !"] .. "|r", true)
end

function MooseSell_Remove2()
	sellframestartindex = 1;
end

--------------- Button Minimap ---------------------------------

function MooseSell_ButtonMinimap()
	if msDB.Minimap then
		VendomaticButton:Show();
	else
		VendomaticButton:Hide();
	end
end

function MooseSell_OnEnter(self)
	if (self.dragging) then
		return
	end
	GameTooltip:SetOwner(self or UIParent, "ANCHOR_LEFT")
	GameTooltip:SetText("MooseSell");
	GameTooltip:AddLine("Double-click: Show/hide options frame \n Left-click: Drag this icon", 1, 1, 1);
	GameTooltip:Show();
end

-- ** do not call from the mod's OnLoad, VARIABLES_LOADED or later is fine. **
function MooseSell_MinimapButton_Reposition()
	VendomaticButton:SetPoint("TOPLEFT","Minimap","TOPLEFT",52-(83*cos(msDB.MinimapPos)),(83*sin(msDB.MinimapPos))-52)  -- 83 = distance du centre de la minimap
end

-- Only while the button is dragged this is called every frame
function MooseSell_MinimapButton_DraggingFrame_OnUpdate()

	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin-xpos/UIParent:GetScale()+70 -- get coordinates as differences from the center of the minimap
	ypos = ypos/UIParent:GetScale()-ymin-70

	msDB.MinimapPos = math.deg(math.atan2(ypos,xpos)) -- save the degrees we are relative to the minimap center
	MooseSell_MinimapButton_Reposition() -- move the button
end
