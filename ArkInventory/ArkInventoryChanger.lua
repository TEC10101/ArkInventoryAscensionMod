function ArkInventory.Frame_Changer_Update( loc_id )

	if loc_id == ArkInventory.Const.Location.Bag then

		for bag_id in ipairs( ArkInventory.Global.Location[loc_id].Bags ) do

			local frame = _G[ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Changer.Name .. "WindowBag" .. bag_id]

			if bag_id == 1 then
				ArkInventory.Frame_Changer_Primary_Update( frame )
			else
				ArkInventory.Frame_Changer_Secondary_Update( frame )
			end

		end

	elseif loc_id == ArkInventory.Const.Location.Bank then

		ArkInventory.Frame_Changer_Update_Bank( )

	elseif loc_id == ArkInventory.Const.Location.Vault or loc_id == ArkInventory.Const.Location.PersonalBank or loc_id == ArkInventory.Const.Location.RealmBank then

		ArkInventory.Frame_Changer_Update_Vault( loc_id )

	end


	local frame = _G[ArkInventory.Const.Frame.Main.Name .. loc_id]
	ArkInventory.Frame_Status_Update( frame )

end

function ArkInventory.Frame_Changer_Primary_OnLoad( frame )

	-- bag & bank

	local framename = frame:GetName( )
	local loc_id, bag_id = strmatch( framename, "^" .. ArkInventory.Const.Frame.Main.Name .. "(%d+).-(%d+)$" )

	loc_id = tonumber( loc_id )
	bag_id = tonumber( bag_id )

	frame.ARK_Data = {
		["loc_id"] = tonumber( loc_id ),
		["bag_id"] = tonumber( bag_id ),
	}

	frame:RegisterForClicks( "LeftButtonUp", "RightButtonUp" )

	ArkInventory.SetItemButtonTexture( frame, ArkInventory.Global.Location[loc_id].Texture )

	local obj = _G[framename .. "Count"]
	if obj ~= nil then
		obj:SetPoint( "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 2 )
		obj:SetPoint( "LEFT", frame, "LEFT", 0, 0 )
	end

	local obj = _G[framename .. "Stock"]
	if obj ~= nil then
		obj:SetPoint( "TOPLEFT", frame, "TOPLEFT", 0, -2 )
		obj:SetPoint( "RIGHT", frame, "RIGHT", 0, 0 )
	end

	frame.ignoreTexture:Hide( )

end

function ArkInventory.Frame_Changer_Primary_Update( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local bag_id = frame.ARK_Data.bag_id
	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )

	ArkInventory.Frame_Item_Update_Fade( frame )

	ArkInventory.Frame_Item_Update_Border( frame )

	if ArkInventory.db.realm.player.data[cp.info.player_id].display[loc_id].bag[bag_id] == false then
		SetItemButtonTextureVertexColor( frame, 1.0, 0.1, 0.1 )
	else
		SetItemButtonTextureVertexColor( frame, 1.0, 1.0, 1.0 )
	end

	local bag = cp.location[loc_id].bag[bag_id]

	SetItemButtonCount( frame, bag.count )

	if bag.status == ArkInventory.Const.Bag.Status.Active then
		ArkInventory.SetItemButtonStock( frame, bag.empty )
	else
		ArkInventory.SetItemButtonStock( frame, nil, bag.status )
	end

end

function ArkInventory.Frame_Changer_Primary_OnClick( frame, button )

	local loc_id = frame.ARK_Data.loc_id

	--ArkInventory.Output( "primary frame=[", frame:GetName( ), "], button=[", button, "]" )


	if loc_id == ArkInventory.Const.Location.Bag then

		if button == nil then
			-- drag receive
			if not ArkInventory.Global.Location[loc_id].isOffline then
				PutItemInBackpack( )
			end
		elseif button == "RightButton" then
			ArkInventory.MenuBagOpen( frame )
		elseif button == "LeftButton" then
			if not ArkInventory.Global.Location[loc_id].isOffline and CursorHasItem( ) then
				PutItemInBackpack( )
			end
		end

	elseif loc_id == ArkInventory.Const.Location.Bank then

		if button == nil then
			if not ArkInventory.Global.Location[loc_id].isOffline then
				ArkInventory.PutItemInBank( )
			end
		elseif button == "RightButton" then
			ArkInventory.MenuBagOpen( frame )
		elseif button == "LeftButton" then
			if not ArkInventory.Global.Location[loc_id].isOffline and CursorHasItem( ) then
				ArkInventory.PutItemInBank( )
			end
		end

	end

end

function ArkInventory.Frame_Changer_Primary_OnEnter( frame )

	local loc_id = frame.ARK_Data.loc_id

	local tooltip_text = nil

	if loc_id == ArkInventory.Const.Location.Bag then
		tooltip_text = BACKPACK_TOOLTIP
	elseif loc_id == ArkInventory.Const.Location.Bank then
		tooltip_text = ArkInventory.Localise["LOCATION_BANK"]
	end


	if tooltip_text ~= nil then

		if ArkInventory.db.global.option.tooltip.show then
			ArkInventory.GameTooltipSetText( frame, tooltip_text, nil, nil, nil, true )
		end

		ArkInventory.BagHighlight( frame, true )

	end

end


function ArkInventory.Frame_Changer_Update_Bank( )

	local loc_id = ArkInventory.Const.Location.Bank

	local parent = _G[ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Changer.Name .. "Window"]

	if not parent:IsVisible( ) then
		return
	end

	for x = 1, ArkInventory.Global.Location[loc_id].bagCount do

		local frame = _G[ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Changer.Name .. "WindowBag" .. x]

		if x == 1 then
			ArkInventory.Frame_Changer_Primary_Update( frame )
		else
			ArkInventory.Frame_Changer_Secondary_Update( frame )
		end

	end

	local purchaseFrame = _G[parent:GetName( ) .. "PurchaseInfo"]

	if ArkInventory.Global.Location[loc_id].isOffline then
		purchaseFrame:Hide( )
		return
	end


	-- update blizzards frame as well because the static dialog box uses the data in it
	UpdateBagSlotStatus( )

	-- now mimic that frame
	local moneyFrame = purchaseFrame:GetName( ) .. "DetailMoneyFrame"
	local purchaseButton = _G[purchaseFrame:GetName( ) .. "PurchaseButton"]

	local numSlots, full = GetNumBankSlots( )

	-- pass in # of current slots, returns cost of next slot
	local cost = GetBankSlotCost( numSlots )

	purchaseFrame.nextSlotCost = cost
	if GetMoney( ) >= cost then
		SetMoneyFrameColor( moneyFrame, 1.0, 1.0, 1.0 )
		purchaseButton:Enable( )
	else
		SetMoneyFrameColor( moneyFrame, 1.0, 0.1, 0.1 )
		purchaseButton:Disable( )
	end
	MoneyFrame_Update( moneyFrame, cost )

	if full then
		purchaseFrame:Hide( )
	else
		purchaseFrame:Show( )
	end

end

function ArkInventory.Frame_Changer_Vault_Tab_OnEnter( frame )

	if not frame then return end

	local loc_id = frame.ARK_Data.loc_id
	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )
	local bag_id = frame.ARK_Data.bag_id

	if ArkInventory.db.global.option.tooltip.show then

		ArkInventory.GameTooltipSetPosition( frame, true )

		local bag = cp.location[loc_id].bag[bag_id]

		if bag and bag.name then
			GameTooltip:SetText( string.format( ArkInventory.Localise["VAULT_TAB_NAME"], bag_id, bag.name ) )
			GameTooltip:AddLine( string.format( ArkInventory.Localise["VAULT_TAB_ACCESS"], bag.access ) )
			if bag.withdraw then
				GameTooltip:AddLine( string.format( ArkInventory.Localise["VAULT_TAB_REMAINING_WITHDRAWALS"], bag.withdraw ) )
			end
			GameTooltip:Show( )
		else
			GameTooltip:Hide( )
		end

		CursorUpdate( frame )

	end

	--ArkInventory.BagHighlight( frame, true )

end

function ArkInventory.Frame_Changer_Vault_Tab_OnLoad( frame )
	ArkInventory.Frame_Changer_Secondary_OnLoad( frame )
	frame.UpdateTooltip = ArkInventory.Frame_Changer_Vault_Tab_OnEnter
end

function ArkInventory.Frame_Changer_Vault_Tab_OnClick( frame, button, mode )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local mode = mode or GuildBankFrame.mode

	local loc_id = frame.ARK_Data.loc_id
	local bag_id = frame.ARK_Data.bag_id

	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )
	local tab = cp.location[loc_id].bag[bag_id]
	local isPersonal = ( loc_id == ArkInventory.Const.Location.PersonalBank )
	local isRealm = ( loc_id == ArkInventory.Const.Location.RealmBank )

	if tab.name == nil then
		return
	end

	ArkInventory.Frame_Changer_Update( loc_id )

	if tab.status ~= ArkInventory.Const.Bag.Status.Purchase then

		if button == nil then

			-- drag'n'drop (drop)

			if not ArkInventory.Global.Location[loc_id].isOffline then
				--ArkInventory.PutItemInGuildBank( tab_id )
			end

		elseif button == "RightButton" then

			ArkInventory.MenuVaultTabOpen( frame )

		elseif button == "LeftButton" then

			-- Personal / Realm banks: drive purely from saved variables.
			-- When a tab is clicked, switch the active tab index and
			-- regenerate the window from cp.location[loc_id].bag[bag_id]
			-- without relying on live guild bank queries.
			if isPersonal or isRealm then

				ArkInventory.Global.Location[loc_id].current_tab = bag_id
				-- ensure Blizzard's current tab follows so deposits target the
				-- selected tab when right-clicking bag items
				SetCurrentGuildBankTab( bag_id )
				-- request fresh item data for this tab; Blizzard will fire
				-- GUILDBANKBAGSLOTS_CHANGED which triggers ScanVault and
				-- a redraw with up-to-date slot contents
				QueryGuildBankTab( bag_id )

				-- update changer highlight and then redraw the main window
				ArkInventory.Frame_Changer_Update( loc_id )
				-- need a full layout recalculation so that the new
				-- active tab's bag visibility (display[loc_id].bag)
				-- takes effect in Frame_Container_CalculateBars
				ArkInventory.Frame_Main_Generate( loc_id, ArkInventory.Const.Window.Draw.Recalculate )

				return
			end

			-- for the real guild vault we can safely skip redundant work
			-- when clicking the already active tab. personal / realm
			-- banks use the saved-variables path above instead.
			if loc_id == ArkInventory.Const.Location.Vault then
				if mode == GuildBankFrame.mode and bag_id == GetCurrentGuildBankTab( ) then
					return
				end
			end

			GuildBankFrame.mode = mode
			SetCurrentGuildBankTab( bag_id )

			if ArkInventory.Global.Location[loc_id].isOffline then
				ArkInventory.Frame_Main_Generate( loc_id, ArkInventory.Const.Window.Draw.Refresh )
				return
			end

			if tab.status == ArkInventory.Const.Bag.Status.NoAccess then
				ArkInventory.Frame_Main_Generate( loc_id, ArkInventory.Const.Window.Draw.Refresh )
				return
			end

			if GuildBankFrame.mode == "bank" then

				QueryGuildBankTab( bag_id ) -- fires GUILDBANKBAGSLOTS_CHANGED when data is available

			elseif GuildBankFrame.mode == "log" then

				QueryGuildBankLog( bag_id ) -- fires GUILDBANKLOG_UPDATE when data is available

			elseif GuildBankFrame.mode == "moneylog" then

				QueryGuildBankLog( MAX_GUILDBANK_TABS + 1 ) -- fires GUILDBANKLOG_UPDATE when data is available

			elseif GuildBankFrame.mode == "tabinfo" then

				QueryGuildBankText( bag_id ) -- fires GUILDBANK_UPDATE_TEXT when data is available

			end

		end

	end

end

function ArkInventory.Frame_Changer_Update_Vault( loc_id )

	if not loc_id then loc_id = ArkInventory.Const.Location.Vault end
	local parent = ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Changer.Name .. "Window"
	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )

	if not _G[parent]:IsVisible( ) then
		return
	end

	local current_tab
	if loc_id == ArkInventory.Const.Location.Vault then
		-- real guild vault follows Blizzard's current tab selection
		current_tab = GetCurrentGuildBankTab( )
	else
		-- personal / realm banks track the active tab via our own
		-- per-location current_tab field, defaulting to 1
		current_tab = ArkInventory.Global.Location[loc_id].current_tab or 1
	end

	-- ensure current_tab points to a valid, active tab for this location
	if loc_id ~= ArkInventory.Const.Location.Vault then
		local candidate = current_tab
		local tab = cp.location[loc_id].bag[candidate]
		if not tab or tab.status ~= ArkInventory.Const.Bag.Status.Active then
			for i = 1, #ArkInventory.Global.Location[loc_id].Bags do
				local t = cp.location[loc_id].bag[i]
				if t and t.status == ArkInventory.Const.Bag.Status.Active then
					candidate = i
					break
				end
			end
			current_tab = candidate or 1
			ArkInventory.Global.Location[loc_id].current_tab = current_tab
		end
	end

	for bag_id in ipairs( ArkInventory.Global.Location[loc_id].Bags ) do

		if bag_id == current_tab then
			ArkInventory.db.realm.player.data[cp.info.player_id].display[loc_id].bag[bag_id] = true
		else
			ArkInventory.db.realm.player.data[cp.info.player_id].display[loc_id].bag[bag_id] = false
		end

		local frame = _G[parent .. "Bag" .. bag_id]
		ArkInventory.Frame_Changer_Secondary_Update( frame )

	end


	local moneyDeposit = parent .. "GoldTotal"
	local buttonDeposit = parent .. "DepositButton"
	local moneyWithdraw = parent .. "GoldAvailable"
	local buttonWithdraw = parent .. "WithdrawButton"

	-- treat Ascension-style banks (personal/realm) specially; never rely on
	-- a global context string when deciding UI for a specific location
	local isAscensionBank = ( loc_id == ArkInventory.Const.Location.PersonalBank ) or ( loc_id == ArkInventory.Const.Location.RealmBank )

	if ArkInventory.Global.Location[loc_id].isOffline or isAscensionBank then

		_G[moneyDeposit]:Hide( )
		_G[buttonDeposit]:Hide( )
		_G[moneyWithdraw]:Hide( )
		_G[buttonWithdraw]:Hide( )

	else

		-- update the guild gold total
		MoneyFrame_Update( moneyDeposit, GetGuildBankMoney( ) )
		_G[moneyDeposit]:Show( )
		_G[buttonDeposit]:Show( )
		_G[moneyWithdraw]:Show( )
		_G[buttonWithdraw]:Show( )

		-- update the guild withdrawl amount

		if CanWithdrawGuildBankMoney( ) then

			local withdrawLimit = GetGuildBankWithdrawMoney( )

			if withdrawLimit < 0 then
				-- no limit, set to full amount
				withdrawLimit = GetGuildBankMoney( )
			end

			if withdrawLimit > 0 then

				withdrawLimit = min( withdrawLimit, GetGuildBankMoney( ) )
				_G[buttonWithdraw]:Enable( )

			else

				_G[buttonWithdraw]:Disable( )

			end

			MoneyFrame_Update( moneyWithdraw, withdrawLimit )
			_G[moneyWithdraw]:Show( )

		else

			_G[moneyWithdraw]:Hide( )
			_G[buttonWithdraw]:Disable( )

		end

	end


	-- purchase frame
	local purchaseFrame = _G[parent .. "PurchaseInfo"]

	if ArkInventory.Global.Location[loc_id].isOffline or isAscensionBank or not IsGuildLeader( ) then

		purchaseFrame:Hide( )

	else

		moneyFrame = purchaseFrame:GetName( ) .. "DetailMoneyFrame"
		purchaseButton = _G[purchaseFrame:GetName( ) .. "PurchaseButton"]

		numSlots = GetNumGuildBankTabs( )
		cost = GetGuildBankTabCost( )

		if not cost then

			-- all tabs purchased
			purchaseFrame:Hide( )

		else

			if GetMoney( ) >= cost then
				SetMoneyFrameColor( moneyFrame, 1.0, 1.0, 1.0 )
				purchaseButton:Enable( )
			else
				SetMoneyFrameColor( moneyFrame, 1.0, 0.1, 0.1 )
				purchaseButton:Disable( )
			end

			MoneyFrame_Update( moneyFrame, cost )
			purchaseFrame:Show( )

		end

	end

end


function ArkInventory.Frame_Changer_Secondary_OnLoad( frame )

	local framename = frame:GetName( )

	local loc_id, bag_id = strmatch( framename, "^" .. ArkInventory.Const.Frame.Main.Name .. "(%d+).-(%d+)$" )

	loc_id = tonumber( loc_id )
	bag_id = tonumber( bag_id )
	--local inv_id = ArkInventory.InventoryIDGet( loc_id, bag_id )

	frame.ARK_Data = {
		["loc_id"] = loc_id,
		["bag_id"] = bag_id,
		--["inv_id"] = inv_id,
	}

	frame.locked = nil

	frame:RegisterForClicks( "LeftButtonUp", "RightButtonUp" )
	frame:RegisterForDrag( "LeftButton" )

	ArkInventory.SetItemButtonTexture( frame, ArkInventory.Const.Texture.Empty.Bag )

	local obj = _G[framename .. "Count"]
	if obj ~= nil then
		obj:SetPoint( "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 2 )
		obj:SetPoint( "LEFT", frame, "LEFT", 0, 0 )
	end

	local obj = _G[framename .. "Stock"]
	if obj ~= nil then
		obj:SetPoint( "TOPLEFT", frame, "TOPLEFT", 0, -2 )
		obj:SetPoint( "RIGHT", frame, "RIGHT", 0, 0 )
	end

	frame.ignoreTexture:Hide( )

end

function ArkInventory.Frame_Changer_Secondary_OnClick( frame, button )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id

	if IsModifiedClick( "CHATLINK" ) then

		local cp = ArkInventory.LocationPlayerInfoGet( loc_id )
		local bag_id = frame.ARK_Data.bag_id

		local bag = cp.location[loc_id].bag[bag_id]

		if not bag or bag.count == 0 then

			-- empty slot, do nothing for the chatlink

		else

			if bag.h then
				ChatEdit_InsertLink( bag.h )
			end

		end

	else

		if button == nil then

		elseif button == "RightButton" then

			ArkInventory.MenuBagOpen( frame )

		elseif button == "LeftButton" then

			if ArkInventory.Global.Location[loc_id].isOffline then
				return
			end

			local bag_id = frame.ARK_Data.bag_id
			local inv_id = ArkInventory.InventoryIDGet( loc_id, bag_id )

			if CursorHasItem( ) then

				if PutItemInBag( inv_id ) then
					return
				end

			else

				ArkInventory.Frame_Changer_Secondary_OnDragStart( frame )

			end

		end

	end

end

function ArkInventory.Frame_Changer_Secondary_OnDragStart( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id

	if ArkInventory.Global.Location[loc_id].isOffline then
		return
	end

	if loc_id == ArkInventory.Const.Location.Vault then
		return
	end

	local bag_id = frame.ARK_Data.bag_id
	local inv_id = ArkInventory.InventoryIDGet( loc_id, bag_id )
	PickupBagFromSlot( inv_id )
	PlaySound( "BAGMENUBUTTONPRESS" )

end

function ArkInventory.Frame_Changer_Secondary_OnReceiveDrag( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id

	if ArkInventory.Global.Location[loc_id].isOffline then
		return
	end

	ArkInventory.Frame_Changer_Secondary_OnClick( frame )

end

function ArkInventory.Frame_Changer_Secondary_OnEnter( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )
	local bag_id = frame.ARK_Data.bag_id
	local inv_id = ArkInventory.InventoryIDGet( loc_id, bag_id )

	if ArkInventory.db.global.option.tooltip.show then

		ArkInventory.GameTooltipSetPosition( frame, true )

		if ArkInventory.Global.Location[loc_id].isOffline then

			local b = cp.location[loc_id].bag[bag_id]

			if not b or b.count == 0 then
				-- empty slot, do nothing for the tooltip
			else

				if b.h then
					GameTooltip:SetHyperlink( b.h )
				else
					GameTooltip:SetText( ArkInventory.Localise["STATUS_NO_DATA"], 1.0, 1.0, 1.0 )
				end

			end

		else

			GameTooltip:SetInventoryItem( "player", inv_id )

		end

		CursorUpdate( frame )

	end

	ArkInventory.BagHighlight( frame, true )

end

function ArkInventory.Frame_Changer_Secondary_Update( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local bag_id = frame.ARK_Data.bag_id
	local slot_id = frame.ARK_Data.slot_id

	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )
	local bag = cp.location[loc_id].bag[bag_id]

	--ArkInventory.Output( "who[", cp.player.name, "].loc[", loc_id, "].bag[", bag_id, "]" )

	if bag.count > 0 then

		frame.size = bag.count or 0
		ArkInventory.SetItemButtonTexture( frame, bag.texture )
		SetItemButtonCount( frame, frame.size )

	else

		frame.size = 0
		ArkInventory.SetItemButtonTexture( frame, bag.texture or ArkInventory.Const.Texture.Empty.Bag )
		SetItemButtonCount( frame, frame.size )

	end

	if bag.status == ArkInventory.Const.Bag.Status.Active then
		ArkInventory.SetItemButtonStock( frame, bag.empty )
	else
		ArkInventory.SetItemButtonStock( frame, nil, bag.status )
	end

	ArkInventory.Frame_Item_Update_Fade( frame )

	ArkInventory.Frame_Item_Update_Border( frame )

	if ArkInventory.db.realm.player.data[cp.info.player_id].display[loc_id].bag[bag_id] == false then
		SetItemButtonTextureVertexColor( frame, 1.0, 0.1, 0.1 )
	else
		if bag.status == ArkInventory.Const.Bag.Status.Purchase then
			SetItemButtonTextureVertexColor( frame, 1.0, 0.1, 0.1 )
		else
			SetItemButtonTextureVertexColor( frame, 1.0, 1.0, 1.0 )
		end
	end

end

function ArkInventory.Frame_Changer_Secondary_Update_Lock( loc_id, bag_id )

	local frame = _G[ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Changer.Name .. "WindowBag" .. bag_id]
	if not frame then
		return
	end

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	if ArkInventory.Global.Location[loc_id].isOffline then
		return
	end

	if ArkInventory.Global.Me.location[loc_id].bag[bag_id].h then

		local inv_id = ArkInventory.InventoryIDGet( loc_id, bag_id )
		local locked = IsInventoryItemLocked( inv_id )
		ArkInventory.SetItemButtonDesaturate( frame, locked )
		frame.locked = locked

	else

		frame.locked = false

	end

end

function ArkInventory.Frame_Changer_Generic_OnLeave( frame )
	GameTooltip:Hide( )
	ResetCursor( )
	ArkInventory.BagHighlight( frame, false )
end



function ArkInventory.BagHighlight( frame, show )

	local loc_id = frame.ARK_Data.loc_id
	local bag_id = frame.ARK_Data.bag_id

	if loc_id ~=nil and bag_id ~= nil then

		local cp = ArkInventory.LocationPlayerInfoGet( loc_id )

		local b = cp.location[loc_id].bag[bag_id]
		if not b then
			return
		end

		local name = ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Container.Name .. "Bag" .. bag_id
		local frame = _G[name]
		if not frame then
			return
		end

		local enabled = ArkInventory.LocationOptionGet( loc_id, { "changer", "highlight", "show" } )
		local colour = ArkInventory.LocationOptionGet( loc_id, { "changer", "highlight", "colour" } )

		for slot_id in pairs( b.slot ) do
			local obj = _G[name .. "Item" .. slot_id .. "ArkHighlightBag"]
			if obj then
				if enabled then
					if show then
						obj:SetTexture( colour.r, colour.g, colour.b, 0.3 )
						obj:Show( )
					else
						obj:Hide( )
					end
				else
					obj:Hide( )
				end
			end
		end

	end

end
