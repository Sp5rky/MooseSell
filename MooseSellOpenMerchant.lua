local DEBUG = nil
local Debug = DEBUG and function(s) DEFAULT_CHAT_FRAME:AddMessage(s, 1, 0, 0) end or function() return end  

-- Magic Numbers
local SELL_INTERVAL = 0.15
local MAX_SELLS_ACTIVE = 5

-- Create the addon and module objects if needed (note: only MooseSell.lua should actually set the version!)
if (MooseSell and MooseSell.Version and MooseSell.Version > OUR_VERSION) then return end
MooseSell = MooseSell or {}
local ms = MooseSell
ms.Merchant = ms.Merchant or {}
ms.Events = ms.Events or {}

-- Set up for future localization
local L = LibStub("AceLocale-3.0"):GetLocale("MooseSell")
setmetatable( L, { __index = function(t, text) return text end })

-- Make library calls local
local type, tostring = type, tostring  
local string, table, tinsert, tremove, wipe = string, table, tinsert, tremove, wipe

-- Make api calls local  ---***** Update when done with this file
local UseContainerItem = UseContainerItem
local GetItemInfo = GetItemInfo
local GetContainerNumSlots = GetContainerNumSlots 
local GetContainerNumFreeSlots = GetContainerNumFreeSlots
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemID = GetContainerItemID
local PickupContainerItem = PickupContainerItem 
local GetCursorInfo = GetCursorInfo
local DeleteCursorItem = DeleteCursorItem


-- Libraries
local cfg = LibStub("AceConfig-3.0")
local gui = LibStub("AceConfigDialog-3.0") 
-- local registry = LibStub("AceConfigRegistry-3.0")
ms.GuiUpdate = LibStub("AceConfigRegistry-3.0").NotifyChange

-- Locals
local msPrefix = "|cFFF88017MS|r : "
local msDB = defaultDB
local events = ms.Events
local merchant = ms.Merchant
local selltable = {}
local timeSinceLastSell = 0
local numSellsActive = 0
local merchIsOpen = nil
local sellHandle

-- Local functions
local function chatMsg(s, force, r, g, b)
   if (force and type(force) ~= "boolean") then
      r, g, b, force = force, r, g, nil
   end 
   if (not msDB.Silent or force) then
      DEFAULT_CHAT_FRAME:AddMessage(s, r, g, b)
   end
end

local function checkContinueSelling(elapsed)
   timeSinceLastSell = timeSinceLastSell + elapsed 
   if ((msDB.Sell and numSellsActive <= MAX_SELLS_ACTIVE) and
         (timeSinceLastSell > SELL_INTERVAL)) then
      timeSinceLastSell = 0
      return true
   end
end

local function fillSellTable()
   local itemId, name, link, quality, value, icount
   local item = {}
   selltable = {}
   for bag = 0,4 do
      for slot = 1, GetContainerNumSlots(bag) do
         itemId = GetContainerItemID(bag, slot)
    		if (itemId) then
            _, icount = GetContainerItemInfo(bag, slot)
    		   name, link, quality, _, _, _, _, _, _, _, value = GetItemInfo(itemId)
    			value = value * icount
            if (quality == 0 or msDB.TrashList[name]) then
               item = {id = itemId, link = link, value = value, bag = bag, slot = slot, count = icount}
               tinsert(selltable, item)
    		   end
    	   end
   	end
   end
end

local sell
do
   local retrytable = {}
   sell = function ()
      if (not msDB.Sell) then return end
      if ((not selltable or #selltable < 1) and (retrytable and #retrytable > 0)) then
         selltable = retrytable
         retrytable = nil
      end
      if (selltable and #selltable > 0) then
         local item = selltable[#selltable]
         local name = GetItemInfo(item.id)
         local locked, id
         repeat
            item = selltable[#selltable]
            -- Double check that bag items haven't changed
            if (item.id and item.id == GetContainerItemID(item.bag, item.slot)) then
               _, _, locked = GetContainerItemInfo(item.bag, item.slot)
               if locked then -- we'll give it another chance at the end
                  if retrytable then tinsert(retrytable, item) end 
                  tremove(selltable)                  
               else
                  -- sell the item
                  numSellsActive = numSellsActive + 1
                  UseContainerItem(item.bag, item.slot)
                  msDB.SoldValue = msDB.SoldValue + item.value
                  msDB.SoldCount = msDB.SoldCount + item.count
				  msDB.SellCount = msDB.SellCount + 1
				  msDB.SellValue = msDB.SellValue + item.value
				  local itemval = parseCopper(item.value)
                  chatMsg(msPrefix.."|cFF00FF00".. L["Sold: "] .. "|r" .. item.link .. " |cFF00FF00x" .. tostring(item.count) .. L[". for"] .. "|r : " .. itemval)
				 
               end
            else -- The item has changed.  We need to rebuild the table
               retrytable = {}
               fillSellTable()
               locked = true -- force the loop to continue on the new table
            end
         until (not locked or #selltable < 1)
         tremove(selltable)
		 
      else   
         events:CancelTriggeredCallback(sellHandle)
         events:UnregisterEvent("MERCHANT_UPDATE")
         retrytable = {}
         ms:GuiUpdate(ms.OptionsName)
      end
	  
   end
end

-- Events
function events:MERCHANT_SHOW(...)
   if (msDB.Sell and not merchIsOpen) then
      -- Set a flag so we don't do this again if there are multiple calls
      merchIsOpen = true
      fillSellTable()
      events:RegisterEvent("MERCHANT_CLOSED")
      events:RegisterEvent("MERCHANT_UPDATE")
      -- Schedule selling
      numSellsActive = 0
      events:CancelTriggeredCallback(sellHandle)
      sellHandle = events:SetTriggeredCallback("Sell", checkContinueSelling, sell, nil, true)
   end
end

function events:MERCHANT_CLOSED(...)
   wipe(selltable)
   merchIsOpen = false
   numSellsActive = 0
   events:CancelTriggeredCallback(sellHandle)
   events:UnregisterEvent("MERCHANT_UPDATE")
	if (msDB.SellValue > 0 and msDB.SellCount > 1) then
		local totalitemsell = parseCopper(msDB.SellValue)
		chatMsg("|cFFF88017MooseSell " .. L["Sold for a total of "] .. "|r: " .. totalitemsell)
	end
		msDB.SellCount = 0
		msDB.SellValue = 0
end

function events:MERCHANT_UPDATE(...)
   -- This is imperfect, but more or less true unless player does transactions at the same time
   if (numSellsActive > 0) then
      numSellsActive = numSellsActive - 1
   end
end

-- Methods
function merchant:OnAddonLoaded()
   -- This MUST be called after the db is loaded
   msDB = MooseSellDB
   -- ***There will probably be more init stuff to do here
   if (msDB.Sell) then -- not checking msDB.Enabled : can sell but not destroy
      events:RegisterEvent("MERCHANT_SHOW")
   end
end

function merchant:SellEnable(enable)
   if enable then
      msDB.Sell = true
      events:RegisterEvent("MERCHANT_SHOW")
   else
      msDB.Sell = false
      events:UnregisterEvent("MERCHANT_SHOW")
   end
end
