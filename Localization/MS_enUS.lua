local AL3 = LibStub("AceLocale-3.0")

local debug = false
--[===[@debug@
debug = true
--@end-debug@]===]

local L = AL3:NewLocale("MooseSell", "enUS", true, debug)
if L then

--(msoptions.lua)

L["Are you sure you want to remove %s from the MooseSell list ?"] = true
L[" removed from MooseSell list !"] = true
L["Configuration"] = true
L["Destroy Junk"] = true
L["Destroy Junk trash list"] = true
L["Destroy all grays items when the conditions below are met."] = true
L["Destroy items in the trash list when the conditions below are met."] = true
L["Sell Junk"] = true
L["Sell all undestroyed grays and items in the trash list whenever you interact with a vendor.\n(If 'Destroy Junk' is set, this option will still sell junk that did not meet the below conditions and was not destroyed)"] = true
L["Silent Mode"] = true
L["Suppresses most of MooseSell's chat messages."] = true
L["Don't destroy junk unless it's worth less than a certain value"] = true
L["Destroy only items worth less than a certain amount (per stack)."] = true
L["Sell junk worth less than "] = true
L["Only items that vendor for less than "] = true
L[" will be destroyed."] = true
L["Destroy junk only when I am low on space"] = true
L["Do not destroy junk right away, wait til I am low on space."] = true
L["Slots to try to keep free"] = true
L["Number of bag slots to try to keep free by destroying junk."] = true
L["History"] = true
L["Total number of items destroyed:      "] = true
L["Total value of all items destroyed:     "] = true
L["Total number of items sold:      "] = true
L["Total value of all items sold:     "] = true
L["Clear History"] = true
L["Forget the total count and value of all items destroyed and sold to date (reset it to zero)."] = true
L["Trash List"] = true
L["Drag item onto button to add to trash list."] = true
L["Add to Trash List"] = true
L["Click below to remove an item from the trash list:"] = true
L[" was not found in the MooseSell list."] = true
L[" is not a valid item."] = true

--(msmerchant.lua)

L["Sold: "] = true
L[". for"] = true
L["Sold for a total of "] = true

--(MooseSell.lua)

L["ENABLED"] = true
L["DISABLED"] = true
L["Destroyable: "] = true
L["Destroyed: "] = true
L [". valued at"] = true
L["Nothing to destroy."] = true
L["There are "] = true
L[" items to destroy."] = true
L["Destroying junk is "] = true
L["Selling is "] = true
L["Silent mode is "] = true
L["Free bag slot threshold is "] = true
L["Max value threshold (per stack) is "] = true
L["The vendor value of all items ever deleted by MooseSell is "] = true
L["The vendor value of all items ever sold by MooseSell is "] = true
L["MooseSell loaded! Type '/ms' to list options."] = true
L["MooseSell loaded! '/ms' is in use by another addon, use '/MooseSell' instead."] = true
L["MooseSell is "] = true
L["help"] = true
L["Options: destroy | sell | config | minfree | maxval | status | list | trashlist | remove | purge | value | test"] = true
L["value"] = true
L["MooseSell will always destroy these items:"] = true
L["Your MooseSell list is empty."] = true
L["maxval"] = true
L["MooseSell will delete items regardless of value."] = true
L["MooseSell will only destroy items worth less than "] = true
L[" per stack."] = true
L["Valid options are /ms maxval [ <value> | off ]"] = true
L["minfree"] = true
L["MooseSell will delete items immediately."] = true
L["MooseSell will try to leave "] = true
L[" slots free in you bags."] = true
L["Valid options are /ms minfree [ <numslots> | off ]"] = true
L["remove"] = true
L["Valid options are /ms remove [ <itemname> | ALL ]"] = true
L["destroy"] = true
L["Valid options are /ms destroy [ on | off ]"] = true
L["/ms on | off is no longer a valid option.  Use /ms destroy on | off ."] = true
L["sell"] = true
L["Valid options are /ms sell [ on | off ]"] = true
L["MooseSell did not understand that option. Type '/ms help' for valid options."] = true
L[" added to your MooseSell list!"] = true
L["This item would be deleted anyway."] = true
L["trashlist"] = true
L["Valid options are /ms trashlist [ <itemname> ]"] = true

if GetLocale() == "enUS" or GetLocale() == "enGB" then return end
end
