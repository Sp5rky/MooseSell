local DEBUG = nil
local Debug = DEBUG and function(s) DEFAULT_CHAT_FRAME:AddMessage(s, 1, 0, 0) end or function() return end  

if (MooseSell and MooseSell.Version and MooseSell.Version > OUR_VERSION) then return end
MooseSell = MooseSell or {}
local ms, msDB = MooseSell, nil
local msPrefix = "|cFFF88017MS|r : "

local L = LibStub("AceLocale-3.0"):GetLocale("MooseSell")
setmetatable( L, { __index = function(t, text) return text end })

-- Make library calls local
local type, tostring, next, pairs, ipairs = type, tostring, next, pairs, ipairs  
local string, table, tinsert = string, table, tinsert

-- Make api calls local
local GetItemInfo = GetItemInfo

-- Libraries
local cfg = LibStub("AceConfig-3.0")
local gui = LibStub("AceConfigDialog-3.0")
ms.GuiUpdate = LibStub("AceConfigRegistry-3.0").NotifyChange

-- Static Dialogs 
StaticPopupDialogs["CONFIRM_REMOVE_TRASHLIST_ITEM"] = {
	text = L["Are you sure you want to remove %s from the MooseSell list ?"],
	button1 = YES,
	button2 = NO,
	OnAccept = function (self, data)
         if (data and type(data) == "string") then
            msDB.TrashList[data] = nil
            ms:GuiMakeTrashlist()
            if (not msDB.Silent) then
               DEFAULT_CHAT_FRAME:AddMessage(msPrefix .. "[" .. data .."]|cFF00FF00" .. L[" removed from MooseSell list !"] .. "|r", true)
            end
         end
      end,
	OnCancel = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
}

StaticPopupDialogs["CANNOT_REMOVE_TRASHLIST_ITEM"] = {
	text = "%s",
	button1 = YES,
	OnAccept = function (self) end,
	hideOnEscape = 1,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
}


ms.options = {
   type = "group",
   childGroups = "tab",
   args = {
      mainCfgTab = {
         name = L["Configuration"],
         type = "group",
         order = 1,
         args = {
            sell = {
               order = 1,
               width = "full",
               name = L["Sell Junk"],
               desc = L["Sell all undestroyed grays and items in the trash list whenever you interact with a vendor.\n(If 'Destroy Junk' is set, this option will still sell junk that did not meet the below conditions and was not destroyed)"],
               type = "toggle",
               disabled = function() return msDB.Enabled and not msDB.useMaxVal and not msDB.useMinFree end,
               set = function(info, val) msDB.Sell = val end,
               get = function(info) return msDB.Sell end,
            },
            silent = {
               order = 2,
               width = "full",
               name = L["Silent Mode"],
               desc = L["Suppresses most of MooseSell's chat messages."],
               type = "toggle",
               set = function(info, val) msDB.Silent = val end,
               get = function(info) return msDB.Silent end,
            },
            separator0 = {
               order = 3,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
            enable = {
               order = 4,
               width = "full",
               name = L["Destroy Junk"],
               desc = L["Destroy all grays items when the conditions below are met."],
               type = "toggle",
               set = function(info, val) ms:Enable(val) end,
               get = function(info) return msDB.Enabled end,
            },
            dellTrashList = {
               order = 5,
			   disabled = function() return not msDB.Enabled end,
               width = "full",
               name = L["Destroy Junk trash list"],
               desc = L["Destroy items in the trash list when the conditions below are met."],
               type = "toggle",
               set = function(info, val) msDB.DellTrashList = val end,
               get = function(info) return msDB.DellTrashList end,
            },
            separator1 = {
               order = 7,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
            useMaxval = {
               order = 11,
               disabled = function() return not msDB.Enabled end,
               width = "full",
               name = L["Don't destroy junk unless it's worth less than a certain value"],
               desc = L["Destroy only items worth less than a certain amount (per stack)."],
               type = "toggle",
               set = function(info, val) msDB.useMaxVal = val end,
               get = function(info) return msDB.useMaxVal end,
            },
            maxval = {
               order = 21,
               hidden = function() return not (msDB.Enabled and msDB.useMaxVal) end,
               width = "full",
               name = function () return L["Sell junk worth less than "] .. ms:GSCString(msDB.MaxVal) end,
               desc = function () return L["Only items that vendor for less than "].. ms:GSCString(msDB.MaxVal) .. L[" will be destroyed."] end,
               type = "range",
               min = 10,
               max = 1000000,
               softMin = 10,
               softMax = 200000,
               step = 10,
               bigStep = 10,
               set = function(info, val) msDB.MaxVal = val end,
               get = function(info) return msDB.MaxVal end,      
            },
            separator2 = {
               order = 26,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
            useMinfree = {
               order = 31,
               disabled = function() return not msDB.Enabled end,
               width = "full",
               name = L["Destroy junk only when I am low on space"],
               desc = L["Do not destroy junk right away, wait til I am low on space."],
               type = "toggle",
               set = function(info, val) msDB.useMinFree = val end,
               get = function(info) return msDB.useMinFree end,
            },
            minfree = {
               order = 41,
               hidden = function() return not (msDB.Enabled and msDB.useMinFree) end,
               width = "full",
               name = L["Slots to try to keep free"],
               desc = L["Number of bag slots to try to keep free by destroying junk."],
               type = "range",
               min = 1,
               max = 300,
               softMin = 1,
               softMax = 40,
               step = 1,
               bigStep = 1,
               set = function(info, val) msDB.MinFree = val end,
               get = function(info) return msDB.MinFree end,      
            },
			separator2 = {
               order = 51,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
			minimap = {
				order = 61,
				width = "full",
				name = "Display the button on the minimap",
				type = "toggle",
				set = function(info, val) msDB.Minimap = val; MooseSell_ButtonMinimap() end,
				get = function(info) return msDB.Minimap end,
            },
         },
      },
      infoTab = {
         name = L["History"],
         type = "group",
         order = 3,
         args = {
            separator1 = {
               order = 21,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
            separator2 = {
               order = 53,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
            countToDate = {
               order = 60,
               disabled = true,
               width = "full",
               fontSize = "medium",
               name = function () return L["Total number of items destroyed:      "] .. tostring(msDB.Count) end,
               type = "description",
            },
            valueToDate = {
               order = 61,
               disabled = true,
               width = "full",
               fontSize = "medium",
               name = function () return L["Total value of all items destroyed:     "] .. ms:GSCString(msDB.Value) end,
               type = "description",
            },
            separator3 = {
               order = 66,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
			separator4 = {
               order = 67,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
			clearHistory = {
               order = 69,
			   width = "full",
               name = L["Clear History"],
               desc = L["Forget the total count and value of all items destroyed and sold to date (reset it to zero)."],
               type = "execute",
               func = function() msDB.Count, msDB.Value = 0, 0 end,
            },
            separator5 = {
               order = 73,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
			separator6 = {
               order = 74,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
            SoldCountToDate = {
               order = 81,
               disabled = true,
               width = "full",
               fontSize = "medium",
               name = function () return L["Total number of items sold:      "] .. tostring(msDB.SoldCount) end,
               type = "description",
            },
            SoldValueToDate = {
               order = 82,
               disabled = true,
               width = "full",
               fontSize = "medium",
               name = function () return L["Total value of all items sold:     "] .. ms:GSCString(msDB.SoldValue) end,
               type = "description",
            },
            separator7 = {
               order = 86,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
            separator8 = {
               order = 87,
               disabled = true,
               width = "full",
               name = "\n",
               type = "description",
            },
            SoldClearHistory = {
               order = 89,
			   width = "full",
               name = L["Clear History"],
               desc = L["Forget the total count and value of all items destroyed and sold to date (reset it to zero)."],
               type = "execute",
               func = function() msDB.SoldCount, msDB.SoldValue = 0, 0 end,
            },
         },
      },   
   },
}

local currentItem, currentSelected, guiTrashlist
-- local trashlistTab = {
   -- name = L["Trash List"], 
   -- type = "group",
   -- order = 2,
   -- args = {
      -- dropTarget = {
         -- order = 10,
         -- width = "full",
         -- type = "input",
         -- dialogControl = "MSDropTarget",
         -- name = function ()
               -- local itemName = currentItem and GetItemInfo(currentItem) or L["Drag item onto button to add to trash list."]
               -- return itemName
            -- end,
         -- desc = "#ItemToolTip#",
         -- validate = function (info, value)
               -- local _, _, type = string.find(value, "(%a+)")
               -- return type == "item" and true or L["Not an item."]
            -- end,
         -- get = function () return currentItem end,
         -- set = function (info, value) currentItem = value end,
      -- },
      -- addButton = {
         -- name = L["Add to Trash List"],
         -- order = 20,
         -- width = "full",
         -- type = "execute",
         -- func = function ()
               -- if currentItem and ms:AddToDeleteList(currentItem) then
                  -- currentItem = nil
               -- end
            -- end,
      -- },
      -- trashlist = {
         -- name = L["Click below to remove an item from the trash list:"],
         -- order = 30,
         -- type = "group",
         -- inline = true,
         -- args = {
            -- theList = {
               -- type = "select",
               -- dialogControl = "MSItemSelectList",
               -- name = "Anyname", -- This is not actually used by the widget atm
               -- desc = "#ItemTooltip#",
               -- width = "full",
               -- values = function () return guiTrashlist or ms:GuiMakeTrashlist() end,
               -- get = function () return currentSelected end,            
               -- set = function (info, key) ms:GuiRemoveFromTrashlist(key)
                  -- Debug("Selected has been set to: " .. key)
                  -- currentSelected = key end,            
            -- },
         -- },
      -- },  
   -- },                                                            
-- }
-- ms.options.args.trashlistTab = trashlistTab


function ms:GuiMakeTrashlist()
   local dbTrashlist = msDB.TrashList
   if ((not dbTrashlist) or (not next(dbTrashlist))) then
      Debug("The DB Trashlist is empty.  Returning {}.")
      guiTrashlist = {}
      ms:GuiUpdate(ms.OptionsName)
      return guiTrashlist
   end
   local list = {}   
   local shortItemString
   for name, _ in pairs(dbTrashlist) do
      --Debug("next name in dbTrashlist is: " .. name)
      tinsert(list, name)
   end
   -- give list a sensible order so user doesn't go crazy in a long list
   table.sort(list)
   guiTrashlist = {}
   for i, name in ipairs(list) do
      shortItemString = "item:" .. tostring(dbTrashlist[name])
      guiTrashlist[i] = shortItemString
      --Debug("guiTrashlist["..tostring(i).."] = "..shortItemString)
   end
   ms:GuiUpdate(ms.OptionsName)
   return guiTrashlist
end


function ms:GuiRemoveFromTrashlist(key)
   local itemstring = guiTrashlist and guiTrashlist[key] 
   if itemstring then
      local trashlist = msDB.TrashList
      local name = GetItemInfo(itemstring)
      if (name and trashlist and trashlist[name]) then
         local popup = StaticPopup_Show("CONFIRM_REMOVE_TRASHLIST_ITEM", name)
         if popup then
            popup.data = name
         end         
      elseif name then
         StaticPopup_Show("CANNOT_REMOVE_TRASHLIST_ITEM", name .. L[" was not found in the MooseSell list."])
      else
         StaticPopup_Show("CANNOT_REMOVE_TRASHLIST_ITEM", name .. L[" is not a valid item."])
      end
   end
end

function ms:LoadOptions()
   if (cfg and gui) then 
      -- Take the opportunity to make a local reference to the DB
      msDB = MooseSellDB
      -- Add options to Bliz addon config frame
      cfg:RegisterOptionsTable(ms.OptionsName, ms.options)
      gui:AddToBlizOptions(ms.OptionsName)
   end
end
