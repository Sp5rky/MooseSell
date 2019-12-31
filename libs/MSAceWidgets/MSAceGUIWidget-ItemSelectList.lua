-- ItemSelectList widget
-- Author: MSaint
-- Last Modified: 2011-02-23T00:52:53Z
--
-- A list of items (icons left, text right) in a scroll frame, where the
-- items are clickable and trigger the OnValueChanged callback.
--
-- item height is in fact used as both height and width for the small icons
-- on the left side of items in the list
--
-- there is a small hack in this code to increase functionality when using
-- AceConfigDialog: if the second line of the tooltip is set to "#ItemTooltip#"
-- the entire tooltip will be replaced with the current items tooltip (if there
-- is no current item, the second line will be removed, and the rest of the
-- tooltip will be left as is - this is for convenience, although the client
-- addon could easily check for itself and change the tooltip accordingly).

-- ********TO DO : If we break this out into its own library, add real version checks!
local OUR_VERSION = 10 -- would change to (at)project-version(at)

local listWidgetType = "MSItemSelectList"
local itemWidgetType = "MSItemSelectListItem"
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(listWidgetType) or 0) >= OUR_VERSION then return end

local DEBUG = nil
local Debug = DEBUG and function(s) DEFAULT_CHAT_FRAME:AddMessage(s, 1, 0, 0) end or function() return end

-- local refences to WoW api funcs
local CreateFrame, UIParent = CreateFrame, UIParent
local GetCursorInfo, ClearCursor, GetItemInfo, GetSpellInfo, GetMacroInfo =
   GetCursorInfo, ClearCursor, GetItemInfo, GetSpellInfo, GetMacroInfo

-- File scope variables
local item_height, icon_sides, inset_height = 22, 20, 10


-- *** Definition of MSItemSelectList ***
-- **************************************
do 
   local widgetType = listWidgetType
   local version = OUR_VERSION
   
   -- Events: ----
   ---------------
   
   
   -- Item Callbacks: --
   ---------------------
   local function OnItemEnter(item, event, key)
      --Debug("listwidget:OnItemEnter() : Key is: " .. key)
      self = item.userdata.parent
      --Debug("listwidget:OnItemEnter() : list[key] = " .. self.list[key])
      self:Fire("OnEnter")
      self.showingItemTooltip = self.useItemTooltips or (GameTooltipTextLeft2:GetText() == "#ItemTooltip#")
      if (self.showingItemTooltip) then
         if (self.list[key]) then
   	     GameTooltip:SetHyperlink(self.list[key])
   	     GameTooltip:Show()
   	   elseif (GameTooltipTextLeft2 and GameTooltipTextLeft2:GetText() == "#ItemTooltip#") then
   	      -- Remove the second line
            for i=3, GameTooltip:NumLines() do
               _G["GameTooltipTextLeft"..tostring(i-1)]:SetText(_G["GameTooltipTextLeft"..tostring(i)]:GetText())            
            end
            GameTooltip:Show()
   	   end
   	end
   end

   local function OnItemLeave(item, event, key)
      self = item.userdata.parent
      self:Fire("OnLeave")
      if (self.showingItemTooltip and self.list[key]) then
         self.showingItemTooltip = false
         GameTooltip:Hide()
      end
   end

   local function OnItemClick(item, event, key, button)
      self = item.userdata.parent
      -- Debug("listwidget:OnItemClick() : button is: " .. button)
      -- To do: possibly different actions for different buttons?
      if (button == "LeftButton") then
         self.current = key
         self:Fire("OnValueChanged", key)
      end
   end

   -- Internal: --
   ---------------      
   local function addItem(self, index, key, value)
      -- Debug("listwidget:addItem()  : In list widget, key, value are: " .. key .. ", " .. value)
		local item = self.items[i] or AceGUI:Create(itemWidgetType)
      if (item) then      
         self:AddChild(item)
         self.items[index] = item
         item.userdata.parent = self
         item:SetValue(key, value)
         if (index == 1) then
            item.frame:SetPoint("TOP", self.frame)
         else
            item.frame:SetPoint("TOP", self.items[index - 1].frame, "BOTTOM")
         end
         item.frame:SetWidth(self.frame:GetWidth())
         item.frame:SetPoint("LEFT", self.frame, "LEFT")
   		item.frame:SetPoint("RIGHT", self.frame, "RIGHT")
   		item:SetCallback("OnItemEnter", OnItemEnter)
   		item:SetCallback("OnItemLeave", OnItemLeave)
   		item:SetCallback("OnItemClick", OnItemClick)
   	end
	end

   -- Exported: --
   ---------------
   local methods = {
      -- Nothing to do here at the moment   
   	["OnAcquire"] = function(self)
    		self.frame:SetHeight(item_height)
    		self.frame:SetWidth(200)
         self.frame:Hide()
   	end,
      
      -- If we get resized horizontally, we need to set item widths 
      ["OnWidthSet"] = function(self, width)
--          for _, item in ipairs(self.items) do
--             item:SetWidth(width)
--          end
      end,
      
      -- Disable the items so they can't be clicked
      ["SetDisabled"] = function(self, disabled)
   		self.disabled = disabled
   		local method = disabled and "Disable" or "Enable"
   		for _, item in ipairs(self.items) do
            item.frame[method](item.frame)
         end
      end,
      
      -- Sets which item is currently selected (by key)
      ["SetValue"] = function(self, key)
         if (key and self.list[key]) then
            self.current = key
         end
      end,
      
      -- Passes a table of key, value pairs
      ["SetList"] = function(self, list)
   		if (not list or #list < 1) then return end
         -- hide any existing items
         for i, item in ipairs(self.items) do
            item:Clear()
         end
         -- sort on the keys
         local sortlist = {}		
         for key, _ in pairs(list) do
            tinsert(sortlist, key)
   		end
   		table.sort(sortlist)
   		-- prepare the frame for this many items
   		self.frame:SetHeight(#sortlist * item_height)
         -- and add them
   		for i, key in ipairs(sortlist) do
   			addItem(self, i, key, list[key])
   		end
   		self.list = list
   	end,
         
      -- Sets the scrool frames title . . . or not
      ["SetLabel"] = function(self, text)
         -- The label text is not actually displayed anywhere.  It is pretty much
         -- assumed (by me) that the list will be placed in a scrollframe
         -- (probably by using an inline group in AceConfig), so the label should
         -- be placed on that.  Keep in mind that in AceConfigDialog, the name
         -- field may still be used for the tooltip.
         return
      end,
      
      -- When not using AceConfigDialog, this is the right way to do this
      ["UseItemTooltip"] = function(self, use)
         self.useItemTooltips = use   
      end,
   }

   local function constructor()
      local num = AceGUI:GetNextWidgetNum(widgetType)
      local frame = CreateFrame("Frame", "MSAceWidgetItemSelectList" .. tostring(num), UIParent)
 
      local widget = {
   		frame = frame,
   		content = frame,
         type  = widgetType,
   		disabled = false,
         items = {}, -- holds item objects
   		list = {}, -- store key, value pairs corresponding to our items
   		current = nil, -- key of currently selected item
   		useItemTooltips = false, -- can be changed with :UseItemTooltip(trueFalse)
         showingItemTooltip = false, -- will be set only when we are showing an item tooltip
   	}
      for method, func in pairs(methods) do
         widget[method] = func
      end
      
      return AceGUI:RegisterAsContainer(widget)
   end

   AceGUI:RegisterWidgetType(widgetType, constructor, version)
end


-- *** Definition of MSItemSelectListItem ***
-- ******************************************
do
   local widgetType = itemWidgetType
   local version = OUR_VERSION
   
   -- Utility: --
   ---------------      
   local function itemValidate(itemstring)
      return (string.find(itemstring, "item:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+") and true)
   end


   -- Events: ----
   ---------------
   local function Item_OnEnter(frame)
      Debug("Item_OnEnter() reached.")
      self = frame.obj
      self:Fire("OnItemEnter", self.key)
   end

   local function Item_OnLeave(frame)
      self = frame.obj
      self:Fire("OnItemLeave", self.key)
   end

   local function Item_OnClick(frame, button)
      self = frame.obj
      self:Fire("OnItemClick", self.key, button)
   end

   -- Exported: --
   ---------------
   local methods = {
      -- Nothing to do here at the moment   
   	["OnAcquire"] = function(self)
   		self:SetWidth(200)
   	end,
      
      ["Clear"] = function(self)
         self.label:SetText(nil)
         self.key = nil
         self.frame:Hide()
      end,
      
      -- Speaks for itself
      ["SetDisabled"] = function(self, disabled)
   		self.disabled = disabled
   		if disabled then
   			self.frame:Disable()
   		else
   			self.frame:Enable()
   		end
      end,
      
      -- Sets the "value" of the widget, i.e. what item it is associated with
      -- and sets the appropriate texture and label for that item.
      ["SetValue"] = function(self, key, value)
         --Debug("itemwidget:SetValue() : Key, value = " .. tostring(key) .. " , " .. value)
         local itemstring, name, texture = value
         if (key and value and value ~= "") then
            local _, _, type, id = string.find(value, "(%a+):(%-?%d+)")  
            if (type and id) then
               if (type == "item") then
                  -- in addition to texture, we want a full itemString
                  -- in case we were passed an abbreviated one ("item:nnnnn")
                  local link
                  name, link, _, _, _, _, _, _, _, texture = GetItemInfo(id)
                  if (not itemValidate(itemstring)) then
                     itemstring = string.match(link, "item[%-%d:]+")
                  end
                  --Debug("ItemString for this list item is : " .. itemstring)
               elseif (type == "spell") then
                  name, _, texture = GetSpellInfo(id)
               elseif (type == "macro") then
                  name, texture = GetMacroInfo(id)
               end
            end
         end
         if (texture) then
            self.key = key
            self:SetTexture(texture)
            self:SetLabel(name)
         else
            self:SetLabel("Invalid Item")
         end
      end,
      
      -- Puts the item icon on the left, and pushes any text to the right
      ["SetTexture"] = function(self, path)
         self.frame:SetNormalTexture(path)
         local texture = self.frame:GetNormalTexture() 
         if (texture) then
            texture:ClearAllPoints()
            texture:SetPoint("LEFT")
            texture:SetWidth(icon_sides)
            texture:SetHeight(icon_sides)
            self.highlight:SetPoint("LEFT", texture, "RIGHT", -4)
            if (self.label:GetText()) then
               self.label:ClearAllPoints()
               self.label:SetPoint("LEFT", texture, "RIGHT", 4)
   			   self.label:SetWidth(self.frame:GetWidth() - icon_sides - 4)
            end
         end
   	end,
      
      -- Sets the text and anchors it to the button, or to the right of the
      -- texture, if present
      ["SetLabel"] = function(self, text)
         if (text and type(text) == "string") then
            self.label:SetText(text)
            local texture = self.frame:GetNormalTexture()
            if (texture) then
               self.label:ClearAllPoints()
               self.label:SetPoint("LEFT", texture, "RIGHT", 4, 0)
   			   self.label:SetWidth(self.frame:GetWidth() - icon_sides - 4)
            else
               self.label:ClearAllPoints()
               self.label:SetPoint("LEFT")
               self.label:SetWidth(self.frame:GetWidth())
            end
         end
      end,
   }

   local function constructor()
      local num = AceGUI:GetNextWidgetNum(widgetType)
      local frame = CreateFrame("Button", "MSAceWidgetItemSelectListItem" .. tostring(num), UIParent)
      frame:SetHeight(item_height)
      
      local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
      label:SetJustifyH("LEFT")
      label:SetJustifyV("CENTER")
      
      local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
      highlight:SetAllPoints(frame)
      highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
      highlight:SetTexCoord(0, 1, 0, 1)
      highlight:SetBlendMode("ADD")
      
      frame:SetScript("OnEnter", Item_OnEnter)
      frame:SetScript("OnLeave", Item_OnLeave)
      frame:SetScript("OnClick", Item_OnClick)
            
      local widget = {
   		type  = widgetType,
         frame = frame,
   		label = label,
         highlight = highlight,
   		key = nil, -- The key passed by the parent, returned on select
   		userdata = userdata or {},
   	}
      for method, func in pairs(methods) do
         widget[method] = func
      end
      
      return AceGUI:RegisterAsWidget(widget)
   end

   AceGUI:RegisterWidgetType(widgetType, constructor, version)
end


