function ArkInventory.MyHook(...)
	if not ArkInventory:IsHooked(...) then
		ArkInventory:RawHook(...)
	end
end

function ArkInventory.MyUnhook(...)
	if ArkInventory:IsHooked(...) then
		ArkInventory:Unhook(...)
	end
end

function ArkInventory.MySecureHook(...)
	if not ArkInventory:IsHooked(...) then
		ArkInventory:SecureHook(...)
	end
end

--[[
function ArkInventory.BlizzardAPIHooks_OLD( disable )


	-- bag hooks
	if ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Bag ) and not disable then

		ArkInventory.MyHook( "OpenBackpack", "HookOpenBackpack", true )
		ArkInventory.MyHook( "ToggleBackpack", "HookToggleBackpack", true )
		ArkInventory.MyHook( "OpenBag", "HookOpenBag", true )
		ArkInventory.MyHook( "ToggleBag", "HookToggleBag", true )
		ArkInventory.MyHook( "OpenAllBags", "HookOpenAllBags", true )

		ArkInventory.MySecureHook( "BackpackTokenFrame_Update", ArkInventory.Frame_Status_Update_Tracking )

		CloseBackpack( )
		for i = 1, NUM_CONTAINER_FRAMES do
			CloseBag( i )
		end

	else

		ArkInventory.MyUnhook( "OpenBackpack" )
		ArkInventory.MyUnhook( "ToggleBackpack" )
		ArkInventory.MyUnhook( "OpenBag" )
		ArkInventory.MyUnhook( "ToggleBag" )
		ArkInventory.MyUnhook( "OpenAllBags" )

		ArkInventory.MyUnhook( "BackpackTokenFrame_Update" )

		ArkInventory.Frame_Main_Hide( ArkInventory.Const.Location.Bag )

	end

	-- keyring hooks
	if ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Key ) and not disable then
		ArkInventory.MyHook( "ToggleKeyRing", "HookToggleKeyRing", true )
	else
		ArkInventory.MyUnhook( "ToggleKeyRing" )
		ArkInventory.Frame_Main_Hide( ArkInventory.Const.Location.Key )
	end

	-- bank hooks
	if not BankFrame then

		ArkInventory.OutputError( "BankFrame is missing, cannot control bank" )

	else

		if ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Bank ) and not disable then
			BankFrame:Hide( )
			BankFrame:UnregisterEvent( "BANKFRAME_OPENED" )
			--BankFrame:UnregisterEvent( "BANKFRAME_CLOSED" )
		else
			BankFrame:RegisterEvent( "BANKFRAME_OPENED" )
			--BankFrame:RegisterEvent( "BANKFRAME_CLOSED" )
			ArkInventory.Frame_Main_Hide( ArkInventory.Const.Location.Bank )
		end

	end

	-- mailbox
	if not disable then
		MailFrame:UnregisterEvent( "MAIL_SHOW" )
	else
		MailFrame:RegisterEvent( "MAIL_SHOW" )
	end

	-- merchant
	if not disable then
		MerchantFrame:UnregisterEvent( "MERCHANT_SHOW" )
	else
		MerchantFrame:RegisterEvent( "MERCHANT_SHOW" )
	end

	-- guild bank hooks
	if not GuildBankFrame or not GuildBankPopupFrame then

		ArkInventory.OutputError( "GuildBankFrame or GuildBankPopupFrame are missing, cannot control vault" )

	else

		if ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Vault ) and not disable then

			UIParent:UnregisterEvent( "GUILDBANKFRAME_OPENED" )

			GuildBankFrame:UnregisterEvent( "GUILDBANKBAGSLOTS_CHANGED" )
			GuildBankFrame:UnregisterEvent( "GUILDBANK_ITEM_LOCK_CHANGED" )
			GuildBankFrame:UnregisterEvent( "GUILDBANK_UPDATE_TABS" )
			GuildBankFrame:UnregisterEvent( "GUILDBANK_UPDATE_MONEY" )
			GuildBankFrame:UnregisterEvent( "GUILD_ROSTER_UPDATE" )
			GuildBankFrame:UnregisterEvent( "GUILDBANKLOG_UPDATE" )
			GuildBankFrame:UnregisterEvent( "GUILDTABARD_UPDATE" )

			GuildBankFrame:Hide( )

			local frame = _G[ArkInventory.Const.Frame.Main.Name .. ArkInventory.Const.Location.Vault]
			if frame then
				GuildBankPopupFrame:Hide( )
				GuildBankPopupFrame:ClearAllPoints( )
				GuildBankPopupFrame:SetPoint( "TOPLEFT", frame, "TOPRIGHT", -4, -30 )
			end

		else

			UIParent:RegisterEvent( "GUILDBANKFRAME_OPENED" )

			GuildBankFrame:RegisterEvent( "GUILDBANKBAGSLOTS_CHANGED" )
			GuildBankFrame:RegisterEvent( "GUILDBANK_ITEM_LOCK_CHANGED" )
			GuildBankFrame:RegisterEvent( "GUILDBANK_UPDATE_TABS" )
			GuildBankFrame:RegisterEvent( "GUILDBANK_UPDATE_MONEY" )
			GuildBankFrame:RegisterEvent( "GUILD_ROSTER_UPDATE" )
			GuildBankFrame:RegisterEvent( "GUILDBANKLOG_UPDATE" )
			GuildBankFrame:RegisterEvent( "GUILDTABARD_UPDATE" )

			local frame = _G["GuildBankFrame"]
			if frame then
				GuildBankPopupFrame:ClearAllPoints( )
				GuildBankPopupFrame:SetPoint( "TOPLEFT", frame, "TOPRIGHT", -4, -30 )
			end

			ArkInventory.Frame_Main_Hide( ArkInventory.Const.Location.Vault )

		end

	end


	-- tooltips

	local tooltip_frames = { GameTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3, ItemRefTooltip, ItemRefShoppingTooltip1, ItemRefShoppingTooltip2, ItemRefShoppingTooltip3 }

	local tooltip_functions = {
		"SetAuctionItem", "SetAuctionSellItem", "SetAuctionCompareItem", "SetBagItem", "SetBuybackItem", "SetCraftItem", "SetCraftSpell", "SetGuildBankItem", "SetHyperlink",
		"SetHyperlinkCompareItem", "SetInboxItem", "SetInventoryItem", "SetLootItem", "SetLootRollItem", "SetMerchantCompareItem", "SetMerchantItem", "SetQuestItem",
		"SetQuestLogItem", "SetSendMailItem", "SetTradePlayerItem", "SetTradeSkillItem", "SetTradeTargetItem", "SetCurrencyToken", "SetBackpackToken", "SetMerchantCostItem"
	}

	if ArkInventory.db.global.option.tooltip.show and not disable then

		for _, obj in pairs( ArkInventory.Global.Tooltip.WOW ) do
			for _, func in pairs( tooltip_functions ) do
				if obj and obj[func] then
					ArkInventory.MySecureHook( obj, func, ArkInventory.TooltipAdd )
				end
				if ArkInventory.db.global.option.tooltip.scale.enabled then
					obj:SetScale( ArkInventory.db.global.option.tooltip.scale.amount or 1 )
				end
			end
		end

	else

		for _, obj in pairs( tooltip_frames ) do
			for _, func in pairs( tooltip_functions ) do
				if obj and obj[func] then
					ArkInventory.MyUnhook( obj, func, ArkInventory.TooltipAdd )
				end
			end
		end

	end

end
]]--

function ArkInventory.BlizzardAPIHooks( disable )

	if disable or not ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Bag ) then

		-- unhook the backpack functions

		ArkInventory.MyUnhook( "OpenBackpack" )
		ArkInventory.MyUnhook( "ToggleBackpack" )

		ArkInventory.Frame_Main_Hide( ArkInventory.Const.Location.Bag )

	else

		-- hook the backpack functions

		ArkInventory.MyHook( "OpenBackpack", "HookOpenBackpack", true )
		ArkInventory.MyHook( "ToggleBackpack", "HookToggleBackpack", true )

		ArkInventory.MySecureHook( "BackpackTokenFrame_Update", ArkInventory.Frame_Status_Update_Tracking )

	end


	if disable or not ( ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Bag ) or ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Bank ) ) then

		-- unhook the bag functions

		ArkInventory.MyUnhook( "OpenBag" )
		ArkInventory.MyUnhook( "ToggleBag" )
		ArkInventory.MyUnhook( "OpenAllBags" )

	else

		-- hook the bag functions

		ArkInventory.MyHook( "OpenBag", "HookOpenBag", true )
		ArkInventory.MyHook( "ToggleBag", "HookToggleBag", true )
		ArkInventory.MyHook( "OpenAllBags", "HookOpenAllBags", true )

	end


	if disable or not ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Key ) then

		-- unhook the keyring functions

		ArkInventory.MyUnhook( "ToggleKeyRing" )

		ArkInventory.Frame_Main_Hide( ArkInventory.Const.Location.Key )

	else

		-- hook the keyring functions

		ArkInventory.MyHook( "ToggleKeyRing", "HookToggleKeyRing", true )

	end


	-- bank hooks
	if not BankFrame then

		ArkInventory.OutputError( "BankFrame is missing, cannot control bank" )

	else

		if disable or not ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Bank ) then

			-- unhook the bank funtions

			BankFrame:RegisterEvent( "BANKFRAME_OPENED" )
			--BankFrame:RegisterEvent( "BANKFRAME_CLOSED" )

			ArkInventory.Frame_Main_Hide( ArkInventory.Const.Location.Bank )

		else

			BankFrame:Hide( )
			BankFrame:UnregisterEvent( "BANKFRAME_OPENED" )
			--BankFrame:UnregisterEvent( "BANKFRAME_CLOSED" )

		end

	end


	-- mailbox
	if disable then
		MailFrame:RegisterEvent( "MAIL_SHOW" )
	else
		MailFrame:UnregisterEvent( "MAIL_SHOW" )
	end


	-- merchant
	if disable then
		MerchantFrame:RegisterEvent( "MERCHANT_SHOW" )
	else
		MerchantFrame:UnregisterEvent( "MERCHANT_SHOW" )
	end


	-- guild bank hooks
	if not GuildBankFrame or not GuildBankPopupFrame then

		ArkInventory.OutputError( "GuildBankFrame or GuildBankPopupFrame are missing, cannot control vault" )

	else

		-- Always restore guild bank functions at init. ArkInventory now unhooks
		-- dynamically inside LISTEN_VAULT_ENTER for personal/realm sessions.
		-- This ensures that after a /reload the guild bank opens normally on
		-- first interaction.
		UIParent:RegisterEvent( "GUILDBANKFRAME_OPENED" )

		GuildBankFrame:RegisterEvent( "GUILDBANKBAGSLOTS_CHANGED" )
		GuildBankFrame:RegisterEvent( "GUILDBANK_ITEM_LOCK_CHANGED" )
		GuildBankFrame:RegisterEvent( "GUILDBANK_UPDATE_TABS" )
		GuildBankFrame:RegisterEvent( "GUILDBANK_UPDATE_MONEY" )
		GuildBankFrame:RegisterEvent( "GUILDBANK_UPDATE_TEXT" )
		GuildBankFrame:RegisterEvent( "GUILD_ROSTER_UPDATE" )
		GuildBankFrame:RegisterEvent( "GUILDBANKLOG_UPDATE" )
		GuildBankFrame:RegisterEvent( "GUILDTABARD_UPDATE" )

		-- anchor popup to blizzard frame
		local frame = _G["GuildBankFrame"]
		if frame then
			GuildBankPopupFrame:ClearAllPoints( )
			GuildBankPopupFrame:SetPoint( "TOPLEFT", frame, "TOPRIGHT", -4, -30 )
		end

		ArkInventory.Frame_Main_Hide( ArkInventory.Const.Location.Vault )

	end


	-- tooltips

	local tooltip_frames = { GameTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3, ItemRefTooltip, ItemRefShoppingTooltip1, ItemRefShoppingTooltip2, ItemRefShoppingTooltip3 }

	local tooltip_functions = {
		"SetAuctionItem", "SetAuctionSellItem", "SetAuctionCompareItem", "SetBagItem", "SetBuybackItem", "SetCraftItem", "SetCraftSpell", "SetGuildBankItem", "SetHyperlink",
		"SetHyperlinkCompareItem", "SetInboxItem", "SetInventoryItem", "SetLootItem", "SetLootRollItem", "SetMerchantCompareItem", "SetMerchantItem", "SetQuestItem",
		"SetQuestLogItem", "SetSendMailItem", "SetTradePlayerItem", "SetTradeSkillItem", "SetTradeTargetItem", "SetCurrencyToken", "SetBackpackToken", "SetMerchantCostItem"
	}

	if disable or not ArkInventory.db.global.option.tooltip.show then

		for _, obj in pairs( tooltip_frames ) do
			for _, func in pairs( tooltip_functions ) do
				if obj and obj[func] then
					ArkInventory.MyUnhook( obj, func, ArkInventory.TooltipAdd )
				end
			end
		end

	else

		for _, obj in pairs( ArkInventory.Global.Tooltip.WOW ) do
			for _, func in pairs( tooltip_functions ) do
				if obj and obj[func] then
					ArkInventory.MySecureHook( obj, func, ArkInventory.TooltipAdd )
				end
				if ArkInventory.db.global.option.tooltip.scale.enabled then
					obj:SetScale( ArkInventory.db.global.option.tooltip.scale.amount or 1 )
				end
			end
		end

	end

end

function ArkInventory.HookOpenBackpack( self )

	--ArkInventory.Output( "HookOpenBackpack( )" )

	local loc_id = ArkInventory.Const.Location.Bag

	if ArkInventory.LocationIsControlled( loc_id ) then
		local BACKPACK_WAS_OPEN = ArkInventory.Frame_Main_Get( loc_id ):IsVisible( )
		ArkInventory.Frame_Main_Show( loc_id )
		return BACKPACK_WAS_OPEN
	end

	ArkInventory.OutputError( "Code failure: HookOpenBackpack( ), you should never have got here" )

end

function ArkInventory.HookToggleBackpack( self )

	--ArkInventory.Output( "HookToggleBackpack( )" )

	local loc_id = ArkInventory.Const.Location.Bag

	if ArkInventory.LocationIsControlled( loc_id ) then
		ArkInventory.Frame_Main_Toggle( loc_id )
		return
	end

	ArkInventory.OutputError( "Code failure: HookToggleBackpack( ), you should never have got here" )

end

function ArkInventory.HookToggleKeyRing( self )

	--ArkInventory.Output( "HookToggleKeyRing( )" )

	local loc_id = ArkInventory.Const.Location.Key

	if ArkInventory.LocationIsControlled( loc_id ) then
		ArkInventory.Frame_Main_Toggle( loc_id )
		return
	end

	ArkInventory.OutputError( "Code failure: HookToggleKeyRing( ), you should never have got here" )

end

function ArkInventory.HookOpenBag( self, bag_id )

	--ArkInventory.Output( "HookOpenBag( ", bag_id, " )" )

	if bag_id then

		local loc_id = ArkInventory.BagID_Internal( bag_id )

		if loc_id == ArkInventory.Const.Location.Bag or ( loc_id == ArkInventory.Const.Location.Bank and ArkInventory.Global.Mode.Bank ) then
			if ArkInventory.LocationIsControlled( loc_id ) then
				ArkInventory.Frame_Main_Show( loc_id )
				return
			end
		end

	end

	ArkInventory.hooks["OpenBag"]( bag_id )

end

function ArkInventory.HookToggleBag( self, bag_id )

	--ArkInventory.Output( "HookToggleBag( ", bag_id, " )" )

	if bag_id then

		local loc_id = ArkInventory.BagID_Internal( bag_id )

		if loc_id == ArkInventory.Const.Location.Bag or ( loc_id == ArkInventory.Const.Location.Bank and ArkInventory.Global.Mode.Bank ) then
			if ArkInventory.LocationIsControlled( loc_id ) then
				ArkInventory.Frame_Main_Toggle( loc_id )
				return
			end
		end

	end

	ArkInventory.hooks["ToggleBag"]( bag_id )

end

function ArkInventory.HookOpenAllBags( self, forceOpen )

	--ArkInventory.Output( "HookOpenAllBags( ", forceOpen, " )" )

	-- we control both so just toggle the bag and return
	if ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Bag ) and ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Bank ) then
		if forceOpen then
			ArkInventory.Frame_Main_Show( ArkInventory.Const.Location.Bag )
		else
			ArkInventory.Frame_Main_Toggle( ArkInventory.Const.Location.Bag )
		end
		return
	end

	-- we only control one of the bag or bank

	-- modified from blizzard containerframe.lua

	local BACKPACK_WAS_OPEN = ArkInventory.Frame_Main_Get( ArkInventory.Const.Location.Bag ):IsVisible( )
	local bagsShown = 0
	local bagsTotal = 0

	-- close all opened blizzard bag frames
	for i = 1, NUM_CONTAINER_FRAMES do

		local containerFrame = _G["ContainerFrame"..i]

		if containerFrame:IsShown( ) then
			if containerFrame:GetID() ~= KEYRING_CONTAINER then
				bagsShown = bagsShown + 1
				containerFrame:Hide( )
			end
		end

	end


	if not ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Bag ) then

		-- we dont control the bag

		-- find max number of bags
		bagsTotal = 1
		for x = 1, NUM_BAG_SLOTS do
			if GetContainerNumSlots(x) > 0 then
				bagsTotal = bagsTotal + 1
			end
		end

		-- open all bags or leave them closed
		if ( bagsShown < bagsTotal ) or forceOpen then
			OpenBackpack( )
			for x = 1, NUM_BAG_SLOTS do
				OpenBag( x )
			end
		end

		return

	end


	if not ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Bank ) then

		-- we dont control the bank

		if ArkInventory.Global.Mode.Bank then

			-- find max number of bags
			bagsTotal = 0
			for x = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
				if GetContainerNumSlots(x) > 0 then
					bagsTotal = bagsTotal + 1
				end
			end

			if ( bagsShown < bagsTotal ) or forceOpen then
				for x = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
					OpenBag( x )
				end
				ArkInventory.Frame_Main_Show( ArkInventory.Const.Location.Bag )
			else
				--ArkInventory.Frame_Main_Hide( ArkInventory.Const.Location.Bag )
			end

		else

			ArkInventory.Frame_Main_Toggle( ArkInventory.Const.Location.Bag )

		end

		return

	end

	ArkInventory.OutputError( "Code failure at OpenAllBags( ), you should never have got here." )

end

function ArkInventory.HookDoNothing( self )
	-- ArkInventory.OutputDebug( "HookDoNothing( )" )
	-- do nothing
end

function ArkInventory.HookGuildBankPopupOkayButton_OnClick( self )

	--ArkInventory.OutputDebug( "GuildBankPopupOkayButton_OnClick( )" )
	--ArkInventory.hooks["GuildBankPopupOkayButton_OnClick"]( )

	local loc_id = ArkInventory.Const.Location.Vault

	if not ArkInventory.Global.Location[loc_id].isOffline then
		ArkInventory.Frame_Main_Generate( loc_id, nil )
	end

end

function ArkInventory.ContainerNameGet( loc_id, bag_id )
	if loc_id ~= nil and bag_id ~= nil then
		local x = ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Container.Name .. "Bag" .. bag_id
		return x
	end
end

function ArkInventory.ContainerItemNameGet( loc_id, bag_id, slot_id )
	--if loc_id ~= nil and type( loc_id ) == "number" and bag_id ~= nil and type( bag_id ) == "number" and slot_id ~= nil and type( slot_id ) == "number" then
	if loc_id ~= nil and bag_id ~= nil and slot_id ~= nil and type( slot_id ) == "number" then
		local x = ArkInventory.ContainerNameGet( loc_id, bag_id ) .. "Item" .. slot_id
		return x
	end
end

function ArkInventory.LocationOptionGet( loc_id, opt )
	-- resolve any "use X for Y" redirections first
	local real_loc_id = ArkInventory.db.profile.option.use[loc_id] or loc_id

	-- helper: determine which option root table backs a given location id
	local function LocationOptionRoot( any_loc_id )
		local base_loc = ( type( any_loc_id ) == "number" and any_loc_id >= 100 ) and math.floor( any_loc_id / 100 ) or any_loc_id
		if base_loc == ArkInventory.Const.Location.RealmBank then
			ArkInventory.db.global.realmbank = ArkInventory.db.global.realmbank or { }
			local gb = ArkInventory.db.global.realmbank
			gb.option = gb.option or { }
			gb.option.location = gb.option.location or { }
			return gb.option.location
		end
		return ArkInventory.db.profile.option.location
	end

	-- for Personal / Realm banks, some option groups (rules and bar
	-- configuration) should be per-tab rather than per-location.
	-- map those through a synthetic loc_id that encodes the active
	-- tab so that each tab gets independent bar layout and category
	-- assignments while still sharing the base Personal/Realm settings.
	if ( real_loc_id == ArkInventory.Const.Location.PersonalBank or real_loc_id == ArkInventory.Const.Location.RealmBank ) and type( opt ) == "table" and opt[1] then
		local k = opt[1]
		if k == "category" then
			local tab = ArkInventory.Global.Location[real_loc_id].current_tab or 1
			if tab > 1 then
				-- tabs 2+ are always per-tab via synthetic loc id
				real_loc_id = real_loc_id * 100 + tab
			else
				-- tab 1: read legacy until migrated; if synthetic exists, read synthetic
				local syn = real_loc_id * 100 + 1
				local root = LocationOptionRoot( syn )
				if root and root[syn] and root[syn][k] ~= nil then
					real_loc_id = syn
				end
			end
		end
	end

	return ArkInventory.LocationOptionGetReal( real_loc_id, opt )
end

function ArkInventory.LocationOptionGetReal( loc_id, opt )

	assert( loc_id ~= nil, "location id is nil" )
	assert( type( opt ) == "table", "opt is not a table" )

	-- choose option storage root: Realm Bank uses realm-shared store
	local base_loc = ( type( loc_id ) == "number" and loc_id >= 100 ) and math.floor( loc_id / 100 ) or loc_id
	local useRealmShared = ( base_loc == ArkInventory.Const.Location.RealmBank )
	local root
	if useRealmShared then
		-- ensure global-shared structure exists
		ArkInventory.db.global.realmbank = ArkInventory.db.global.realmbank or { }
		local gb = ArkInventory.db.global.realmbank
		gb.option = gb.option or { }
		gb.option.location = gb.option.location or { }
		-- lazily seed this location from global realm-bank defaults if missing
		if not gb.option.location[loc_id] then
			local def = ArkInventory.Const.DatabaseDefaults.global.realmbank.option.location["*"]
			gb.option.location[loc_id] = ArkInventory.Table.CloneDeep( def )
		end
		root = gb.option.location
	else
		root = ArkInventory.db.profile.option.location
	end

	local p = root[loc_id]

	for k = 1, #opt do

		if p == nil then
			--ArkInventory.Output( "loc_id=[", loc_id, "], opt=[", opt, "], k=[", k, "]" )
			assert( false, "code error: encountered nil on option sub path - please reload ui to reset database" )
		end
		local v = opt[k]
		assert( v ~= nil, "code error: encountered a nil parameter at position " .. k )
--		ArkInventory.Output( "p[", v, "]=[", p[v], "]" )
		p = p[v]
	end

	return p

end

function ArkInventory.LocationOptionSet( loc_id, opt, n )
	-- resolve any "use X for Y" redirections first
	local real_loc_id = ArkInventory.db.profile.option.use[loc_id] or loc_id

	-- helper: determine which option root table backs a given location id
	local function LocationOptionRoot( any_loc_id )
		local base_loc = ( type( any_loc_id ) == "number" and any_loc_id >= 100 ) and math.floor( any_loc_id / 100 ) or any_loc_id
		if base_loc == ArkInventory.Const.Location.RealmBank then
			ArkInventory.db.global.realmbank = ArkInventory.db.global.realmbank or { }
			local gb = ArkInventory.db.global.realmbank
			gb.option = gb.option or { }
			gb.option.location = gb.option.location or { }
			if not gb.option.location[any_loc_id] then
				local def = ArkInventory.Const.DatabaseDefaults.global.realmbank.option.location["*"]
				gb.option.location[any_loc_id] = ArkInventory.Table.CloneDeep( def )
			end
			return gb.option.location
		end
		return ArkInventory.db.profile.option.location
	end

	-- keep per-tab rules and bar configuration separate for Personal /
	-- Realm banks by writing those options under a synthetic location id
	-- that incorporates the active tab index.
	if ( real_loc_id == ArkInventory.Const.Location.PersonalBank or real_loc_id == ArkInventory.Const.Location.RealmBank ) and type( opt ) == "table" and opt[1] then
		local k = opt[1]
		if k == "category" then
			local tab = ArkInventory.Global.Location[real_loc_id].current_tab or 1
			local syn = ( tab > 1 ) and ( real_loc_id * 100 + tab ) or ( real_loc_id * 100 + 1 )

			local locTbl = LocationOptionRoot( syn )
			-- ensure synthetic location table exists (for migration convenience)
			if not locTbl[syn] then
				locTbl[syn] = { }
			end
			-- for tab 1, migrate legacy category/bar on first save, then clear legacy
			if tab == 1 then
				local orig = locTbl[real_loc_id] or { }
				local synTbl = locTbl[syn]
				if synTbl.category == nil and orig.category ~= nil then
					synTbl.category = ArkInventory.Table.CloneDeep( orig.category )
				end
				-- delete only legacy category now that synthetic exists
				orig.category = nil
			end

			-- ensure path root exists for the option we're writing
			if locTbl[syn][k] == nil then
				locTbl[syn][k] = { }
			end

			return ArkInventory.LocationOptionSetReal( syn, opt, n )
		end
	end

	return ArkInventory.LocationOptionSetReal( real_loc_id, opt, n )
end

function ArkInventory.LocationOptionSetReal( loc_id, opt, n )

	assert( loc_id ~= nil, "location id is nil" )
	assert( type( opt ) == "table", "opt is not a table" )

	-- choose option storage root: Realm Bank uses realm-shared store
	local base_loc = ( type( loc_id ) == "number" and loc_id >= 100 ) and math.floor( loc_id / 100 ) or loc_id
	local useRealmShared = ( base_loc == ArkInventory.Const.Location.RealmBank )
	local root
	if useRealmShared then
		ArkInventory.db.global.realmbank = ArkInventory.db.global.realmbank or { }
		local gb = ArkInventory.db.global.realmbank
		gb.option = gb.option or { }
		gb.option.location = gb.option.location or { }
		if not gb.option.location[loc_id] then
			local def = ArkInventory.Const.DatabaseDefaults.global.realmbank.option.location["*"]
			gb.option.location[loc_id] = ArkInventory.Table.CloneDeep( def )
		end
		root = gb.option.location
	else
		root = ArkInventory.db.profile.option.location
	end

	--s = "option.local." .. loc_id
	local p = { root[loc_id] }
	local c = 1

	for k = 1, #opt - 1 do
		c = k + 1
		local v = opt[k]
		p[c] = p[k][v]
		--s = s .. "." .. v
	end

	local v = opt[c]
	--ArkInventory.Output( "set ", s, "[", v, "], old=[", p[c][v], "], new=[", n, "]" )
	p[c][v] = n

end

function ArkInventory.ToggleChanger( loc_id )
	ArkInventory.LocationOptionSet( loc_id, { "changer", "hide" }, not ArkInventory.LocationOptionGet( loc_id, { "changer", "hide" } ) )
	ArkInventory.Frame_Main_Generate( nil, ArkInventory.Const.Window.Draw.Refresh )
end

function ArkInventory.ToggleEditMode( )
	ArkInventory.Global.Mode.Edit = not ArkInventory.Global.Mode.Edit

	-- if an item/bar edit menu is open via Dewdrop, close it when
	-- leaving edit mode so the UI returns to a clean non-edit state
	if not ArkInventory.Global.Mode.Edit and ArkInventory.Lib and ArkInventory.Lib.DewDrop and ArkInventory.Lib.DewDrop:IsOpen( ) then
		ArkInventory.Lib.DewDrop:Close( )
	end

	ArkInventory.Frame_Bar_Paint_All( )
	-- Switching edit mode affects bar count and ghost bars, so
	-- recalculate layout to ensure extra edit bars get their own
	-- rows instead of overlapping existing items.
	ArkInventory.Frame_Main_Generate( nil, ArkInventory.Const.Window.Draw.Recalculate )
	ArkInventory.Frame_Item_Update_Clickable_All( )
end

function ArkInventory.GameTooltipSetPosition( frame, bottom )

	-- Anchor the tooltip directly to the item frame so that all
	-- ArkInventory locations (bank, vault, mail, etc.) show the
	-- tooltip at the slot you are hovering over, instead of the
	-- default screen corner. Use TOPLEFT/BOTTOMLEFT so the tooltip
	-- hugs the left edge of the item.
	GameTooltip:SetOwner( frame, bottom and "ANCHOR_BOTTOMLEFT" or "ANCHOR_TOPLEFT" )

end

function ArkInventory.GameTooltipSetText( frame, txt, r, g, b, bottom )
	ArkInventory.GameTooltipSetPosition( frame, bottom )
	GameTooltip:SetText( txt or "missing text", r or 1, g or 1, b or 1 )
	GameTooltip:Show( )
end

function ArkInventory.GameTooltipSetHyperlink( frame, h )

	local class = ArkInventory.ObjectStringDecode( h )

	ArkInventory.GameTooltipSetPosition( frame )

	if class == "token" then
		ArkInventory.GameTooltipSetToken( frame, h )
	else
		GameTooltip:SetHyperlink( h )
	end
	--GameTooltip:Show( )
end

function ArkInventory.GameTooltipSetToken( frame, h, count )

	local class, link, name, texture, quality, type, id = ArkInventory.ObjectInfo( h )

	if class ~= "token" then
		ArkInventory.GameTooltipSetHyperlink( frame, h )
		return
	end

	ArkInventory.GameTooltipSetPosition( frame )

	GameTooltip:ClearLines( )

	local description = ""

	if type == 0 then
		--ArkInventory.TooltipSetHyperlink( ArkInventory.Global.Tooltip.Vendor, string.format( "|Hitem:%s|h", id ) )
		ArkInventory.TooltipSetHyperlink( ArkInventory.Global.Tooltip.Vendor, h )
		description = ArkInventory.TooltipGetLine( ArkInventory.Global.Tooltip.Vendor, 3 )
	elseif type == 1 then
		description = TOOLTIP_ARENA_POINTS
	elseif type == 2 then
		description = TOOLTIP_HONOR_POINTS
	end

	local r, g, b = GetItemQualityColor( quality or 0 )
	if count and count > 0 then
		GameTooltip:AddDoubleLine( name, tostring( count ), r, g, b, r, g, b )
	else
		GameTooltip:AddLine( name, r, g, b )
	end

	if description then
		GameTooltip:AddLine( description, nil, nil, nil, 1 )
	end

	ArkInventory.TooltipAdd( GameTooltip, h )

	GameTooltip:Show( )

end

function ArkInventory.GameTooltipHide( )
	GameTooltip:Hide( )
end

function ArkInventory.PTItemSearch( item )

	-- taken from pt3.0 because someone decided that it didnt belong in pt3.1

	local item = ArkInventory.ObjectStringDecodeItem( item )

	if item <= 0 then
		return nil
	end

	local matches = { }
	for k, v in pairs( ArkInventory.Lib.PeriodicTable.sets ) do
		local _, set = ArkInventory.Lib.PeriodicTable:ItemInSet( item, k )
		if set then
			local have
			for _, v in ipairs( matches ) do
				if v == set then
					have = true
				end
			end
			if not have then
				table.insert( matches, set )
			end
		end
	end

	if #matches > 0 then
		table.sort( matches )
		return matches
	end

end

function ArkInventory.LocationControlToggle( loc_id )
	ArkInventory.LocationControlSet( loc_id, not ArkInventory.db.realm.player.data[player_id].control[loc_id] )
end

function ArkInventory.LocationControlSet( loc_id, control )

	local player_id = ArkInventory.Global.Me.info.player_id

	if control then

		-- enabling ai for location - hide open blizzard frame

		if loc_id == ArkInventory.Const.Location.Bag then
			CloseAllBags( )
		elseif loc_id == ArkInventory.Const.Location.Keyring then

		elseif loc_id == ArkInventory.Const.Location.Bank and ArkInventory.Global.Mode.Bank then
			CloseBankFrame( )
		elseif loc_id == ArkInventory.Const.Location.Vault and ArkInventory.Global.Mode.Vault then
			CloseGuildBankFrame( )
		end

	else

		-- disabling ai for location - hide ai frame

		ArkInventory.Frame_Main_Hide( loc_id )

	end

	ArkInventory.db.realm.player.data[player_id].control[loc_id] = control
	ArkInventory.BlizzardAPIHooks( )

end

function ArkInventory.Frame_Vault_Log_Update( )

	local numTransactions = 0
	if GuildBankFrame.mode == "log" then
		numTransactions = GetNumGuildBankTransactions( GetCurrentGuildBankTab( ) ) or 0
	elseif GuildBankFrame.mode == "moneylog" then
		numTransactions = GetNumGuildBankMoneyTransactions( ) or 0
	end

	if numTransactions == 0 then
		return
	end

	local loc_id = ArkInventory.Const.Location.Vault

	local obj = _G[ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Log.Name .. ArkInventory.Const.Frame.Scrolling.List]
	obj:SetMaxLines( numTransactions )
	obj:ScrollToTop( )

	local tab = GetCurrentGuildBankTab( )

	obj:SetInsertMode( "TOP" )
	obj:AddMessage( "-*- end of list -*-" )

	for i = 1, numTransactions do

		local msg, type, name, amount, year, month, day, hour, money

		if GuildBankFrame.mode == "log" then
			type, name, itemLink, count, tab1, tab2, year, month, day, hour = GetGuildBankTransaction( tab, i )
		elseif GuildBankFrame.mode == "moneylog" then
			type, name, amount, year, month, day, hour = GetGuildBankMoneyTransaction( i )
		end

		if not name then
			name = UNKNOWN
		end

		name = NORMAL_FONT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE

		if GuildBankFrame.mode == "log" then

			if type == "deposit" then
				msg = format( GUILDBANK_DEPOSIT_FORMAT, name, itemLink )
				if count > 1 then
					msg = msg .. format( GUILDBANK_LOG_QUANTITY, count )
				end
			elseif type == "withdraw" then
				msg = format( GUILDBANK_WITHDRAW_FORMAT, name, itemLink )
				if count > 1 then
					msg = msg .. format( GUILDBANK_LOG_QUANTITY, count )
				end
			elseif type == "move" then
				msg = format( GUILDBANK_MOVE_FORMAT, name, itemLink, count, GetGuildBankTabInfo(tab1), GetGuildBankTabInfo(tab2) )
			end

		elseif GuildBankFrame.mode == "moneylog" then

			money = GetDenominationsFromCopper( amount )

			if type == "deposit" then
				msg = format( GUILDBANK_DEPOSIT_MONEY_FORMAT, name, money )
			elseif type == "withdraw" then
				msg = format( GUILDBANK_WITHDRAW_MONEY_FORMAT, name, money )
			elseif type == "repair" then
				msg = format( GUILDBANK_REPAIR_MONEY_FORMAT, name, money )
			elseif type == "withdrawForTab" then
				msg = format( GUILDBANK_WITHDRAWFORTAB_MONEY_FORMAT, name, money )
			elseif type == "buyTab" then
				msg = format( GUILDBANK_BUYTAB_MONEY_FORMAT, name, money )
			end

		end

		if msg then
			obj:AddMessage( msg .. GUILD_BANK_LOG_TIME_PREPEND .. format( GUILD_BANK_LOG_TIME, RecentTimeDate( year, month, day, hour ) ) )
		end

	end

	ArkInventory.Frame_Main_Generate( loc_id, ArkInventory.Const.Window.Draw.Recalculate )

end

function ArkInventory.Frame_Vault_Info_Update( )

	local loc_id = ArkInventory.Const.Location.Vault
	local tab = GetCurrentGuildBankTab( )
	local obj = _G[ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Info.Name .. "ScrollInfo"]
	local text = GetGuildBankText( tab )

	if text then
		obj.text = text
		obj:SetText( text )
	else
		obj.text = ""
		obj:SetText( "" )
	end

	ArkInventory.Frame_Main_Generate( loc_id, ArkInventory.Const.Window.Draw.Recalculate )

end

function ArkInventory.Frame_Vault_Info_Changed( self )

	local tab = GetCurrentGuildBankTab( )
	local button = _G[self:GetParent( ):GetParent( ):GetName( ).."Save"]

	if tab <= GetNumGuildBankTabs( ) and CanEditGuildTabInfo( tab ) and self:GetText( ) ~= self.text then
		button:Enable( )
	else
		button:Disable( )
	end

end

function ArkInventory.ScrollingMessageFrame_Scroll( parent, name, direction )

	if not parent or not name then
		return
	end

	local obj = _G[parent:GetName( ) .. name]
	if not obj then
		return
	end

	local i = obj:GetInsertMode( )

	if i == "TOP" then

		if direction == "up" and not obj:AtBottom( ) then
			obj:ScrollDown( )
		elseif direction == "pageup" and not obj:AtBottom( ) then
			obj:PageDown( )
		elseif direction == "down" and not obj:AtTop( ) then
			obj:ScrollUp( )
		elseif direction == "pagedown" and not obj:AtTop( ) then
			obj:PageUp( )
		end

	else

		if direction == "up" and not obj:AtTop( ) then
			obj:ScrollUp( )
		elseif direction == "pageup" and not obj:AtTop( ) then
			obj:PageUp( )
		elseif direction == "down" and not obj:AtBottom( ) then
			obj:ScrollDown( )
		elseif direction == "pagedown" and not obj:AtBottom( ) then
			obj:PageDown( )
		end

	end

end

function ArkInventory.ScrollingMessageFrame_ScrollWheel( parent, name, direction )

	if direction == 1 then
		ArkInventory.ScrollingMessageFrame_Scroll( parent, name, "up" )
	else
		ArkInventory.ScrollingMessageFrame_Scroll( parent, name, "down" )
	end

end

