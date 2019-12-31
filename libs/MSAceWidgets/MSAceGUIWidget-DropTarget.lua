--[[-----------------------------------------------------------------------------
MSDropTarget Widget
Adapted from several AceGUI widgets by MSaint
Last Modified: 2011-02-23T00:52:53Z
Purpose: A drag-drop target button compatible with the 'type = "input"'
   interface of AceConfig.
   
   Set and get always give / expect either a valid itemString for an item or
   spell ("spell:16039" or "item:16846:0:0:0:0:0:0:0:0:0"), or else a macro
   index given in the form "macro:nn".  Note that for items, only the type and
   itemId are mandatory for get (e.g. "item:16846" is valid).  Set will always
   pass a full itemString.
   
   Example:
      ...
      droptarget = {
         order = 1,
         type = "input",
         dialogControl = "MSDropTarget",
         width = full,
         desc = "#ItemTooltip#"
         name = function ()
               local itemName = currentItem and GetItemInfo(currentItem) or
                  "Drag item onto button to add to trash list."
               return itemName
            end,
         validate = function (info, value)
               local _, _, type = string.find(value, "(%a+)")
               return type == "item" and true or "Not an item."
            end,
         get = function () return currentItem end,
         set = function (info, value) currentItem = value end,
      },  
      ...   
   
   The above example creates an empty button with text to the right.  When an
   item is dropped on the button, the icon and text are changed to the icon
   and name of the item. The validate function will only allow items to be
   dropped on this button.  Setting desc to "#ItemTooltip#" tells the widget
   to replace tooltips with the item tooltip if there is a valid item set.  Any
   other value will leave the tooltip to be managed by AceConfig.      
          
-------------------------------------------------------------------------------]]

-- ********TO DO : If we break this out into its own library, add real version checks!
local OUR_VERSION = 10 -- would change to (at)project-version(at)

local Type = "MSDropTarget"
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= OUR_VERSION then return end

local DEBUG = nil
local Debug = DEBUG and function(s) DEFAULT_CHAT_FRAME:AddMessage(s, 1, 0, 0) end or function() return end  


-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent
local GetCursorInfo, ClearCursor, GetItemInfo, GetSpellInfo, GetMacroInfo =
   GetCursorInfo, ClearCursor, GetItemInfo, GetSpellInfo, GetMacroInfo  

-- Default values
local button_size = 42
local bottom_spacing = 4

--[[-----------------------------------------------------------------------------
Utility functions
-------------------------------------------------------------------------------]]

local function itemValidate(itemstring)
   return (string.find(itemstring, "item:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+:%-?%d+") and true)
end

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

local function UpdateButtonAnchor(self)
	if self.resizing then return end
	local frame = self.frame
	local width = frame.width or frame:GetWidth() or 0
	local button = self.button
	local label = self.label
	local height

	label:ClearAllPoints()
	button:ClearAllPoints()

	
	local buttonwidth = button:GetWidth()
	
	if (label:GetText() or "") == "" then
      -- There is no text, button goes on the left but control keeps its size 
      button:SetPoint("TOPLEFT")
      height = button:GetHeight() + bottom_spacing
   elseif (width - buttonwidth) < 200 then
		-- button goes on top centered when less than 200 width for the text
		button:SetPoint("TOP")
		label:SetPoint("TOP", button, "BOTTOM")
		label:SetPoint("LEFT")
		label:SetJustifyH("CENTER")
		label:SetJustifyV("TOP")
      label:SetWidth(width)
		height = button:GetHeight() + label:GetHeight()
	else
		-- button on the left, text on the right
		button:SetPoint("TOPLEFT")
		label:SetPoint("LEFT", button, "RIGHT", 4, 0)
		label:SetJustifyH("LEFT")
		label:SetJustifyV("TOP")
      label:SetWidth(width - buttonwidth - 4)
		height = max(button:GetHeight(), label:GetHeight()) + bottom_spacing
	end
	
	self.resizing = true
	frame:SetHeight(height)
	frame.height = height
	self.resizing = nil
end



--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	local self = frame.obj
   self:Fire("OnEnter")
   if (GameTooltipTextLeft1 and GameTooltipTextLeft2) then
   	self.showtooltips = self.useItemTooltips or (GameTooltipTextLeft2:GetText() == "#ItemToolTip#")
      if (self.showtooltips) then
         if (self.itemstring) then
   	     GameTooltip:SetHyperlink(self.itemstring)
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
end

local function Control_OnLeave(frame)
	local self = frame.obj
   self:Fire("OnLeave")
	if (self.showtooltips and self.itemstring) then
	   self.showtooltips = false
      GameTooltip:Hide()
	end
end

local function Button_OnReceiveDrag(frame)
	local self = frame.obj
   local itemstring
   local type, id, link = GetCursorInfo()
   if (type and (type == "spell" or type == "macro" or type == "item")) then
      itemstring = type .. ":" .. tostring(id)
	   if (type == "item") then
         itemstring = string.match(link, "item[%-%d:]+")      	
      end
   else
      ClearCursor()
      return
   end
   self:Fire("OnEnterPressed", itemstring)
	ClearCursor()
end


--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
   ["OnAcquire"] = function(self)
		-- set the flag to stop constant size updates
		self.resizing = true
		-- height is set dynamically by the text and button size
		self:SetWidth(200)
		self:SetLabel()
		self:SetTexture(nil)
      self:SetButtonSize(button_size, button_size)
 		-- reset the flag
		self.resizing = nil
		-- run the update explicitly
		UpdateButtonAnchor(self)
	end,

	["OnWidthSet"] = function(self, width)
		UpdateButtonAnchor(self)
	end,

	-- ["OnRelease"] = nil,

	["SetLabel"] = function(self, text)
		self.label:SetText(text)
		UpdateButtonAnchor(self)
	end,

   ["SetText"] = function(self, text)
      Debug("SetText received: " .. text)
      if (text and text ~= "") then
         local _, _, type, id = string.find(text, "(%a+):(%-?%d+)")  
         local itemstring, texture = type .. ":" .. id
         if (type and id) then
            if (type == "item") then
               -- in addition to texture, we want a full itemString
               -- in case we were passed an abbreviated one ("item:nnnnn")
               local link
               _, link, _, _, _, _, _, _, _, texture = GetItemInfo(id)
               if (not itemValidate(itemstring)) then
                  itemstring = string.match(link, "item[%-%d:]+")
               end
            elseif (type == "spell") then
               _, _, texture = GetSpellInfo(id)
            elseif (type == "macro") then
               _, texture = GetMacroInfo(id)
            end
            if (texture) then
               self.itemstring = itemstring
               self:SetTexture(texture)
               return
            end
         end
      end
      self.itemstring = nil
      self:SetTexture(nil)
   end,

	["SetTexture"] = function(self, path, ...)
      self.button:SetNormalTexture(path)
      if (self.button:GetNormalTexture()) then
         self.button:GetNormalTexture():SetWidth(button_size - 4)
         self.button:GetNormalTexture():SetHeight(button_size - 4)
      end
	end,

	["SetButtonSize"] = function(self, width, height)
		self.button:SetWidth(width)
		self.button:SetHeight(height)
		UpdateButtonAnchor(self)
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		-- for this control, disabled just means it can't receive drag drop 
      if disabled then
			self.button:SetScript("OnReceiveDrag", nil)
		else
			self.button:SetScript("OnReceiveDrag", Button_OnReceiveDrag)
		end
	end,
	
	-- When not using AceConfigDialog, this is the right way to do this
   ["UseItemTooltip"] = function(self, use)
      self.useItemTooltips = use   
   end,
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)


	local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
	label:SetPoint("BOTTOMLEFT")
	label:SetPoint("BOTTOMRIGHT")
	label:SetJustifyH("CENTER")
	label:SetJustifyV("TOP")
	label:SetHeight(18)

	local button = CreateFrame("Button", name, frame, "ItemButtonTemplate")
	button:SetBackdrop({
		bgFile = "Interface\\FriendsFrame\\UI-Toast-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 8,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },})
	button:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
	button:SetBackdropColor(0,0,0,1)
   button:SetWidth(button_size)
	button:SetHeight(button_size)
	button:SetPoint("TOP", 0, -5)
   button:SetScript("OnEnter", Control_OnEnter)
	button:SetScript("OnLeave", Control_OnLeave)
   button:SetScript("OnReceiveDrag", Button_OnReceiveDrag)

	local widget = {
		label = label,
		button = button,
		frame = frame,
		type  = Type,
      itemstring = nil,
      useItemTooltips = false, -- can be changed with :UseItemTooltip(trueFalse)
      showtooltips = false, -- gets set to true only when we set the tooltip		
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

   button.obj = widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, OUR_VERSION)








