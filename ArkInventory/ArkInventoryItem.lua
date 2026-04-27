function ArkInventory.Frame_Bag_OnLoad( frame )

	assert( frame, "frame is nil" )

	local framename = frame:GetName( )
	local loc_id, bag_id = strmatch( framename, "^.-(%d+)ContainerBag(%d+)" )

	assert( loc_id, string.format( "xml element '%s' is not an %s frame", framename, ArkInventory.Const.Program.Name ) )
	assert( bag_id, string.format( "xml element '%s' is not an %s frame", framename, ArkInventory.Const.Program.Name ) )

	loc_id = tonumber( loc_id )
	bag_id = tonumber( bag_id )
	--local inv_id = ArkInventory.InventoryIDGet( loc_id, bag_id )

	frame.ARK_Data = {
		["loc_id"] = loc_id,
		["bag_id"] = bag_id,
		--["inv_id"] = inv_id,
	}

	local bliz_id = ArkInventory.BagID_Blizzard( loc_id, bag_id )
	frame:SetID( bliz_id )

	ArkInventory.MediaSetFontFrame( frame )

end

function ArkInventory.Frame_Bag_Create( loc_id, bag_id )



end

function ArkInventory.Frame_Item_GetDB( frame )

	--ArkInventory.Output( "frame=[", frame:GetName( ), "]" )
	local loc_id = frame.ARK_Data.loc_id
	local bag_id = frame.ARK_Data.bag_id
	local slot_id = frame.ARK_Data.slot_id

	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )

	--ArkInventory.Output( "name=[", cp.info.name, "], loc=[", loc_id, "], bag=[", bag_id, "], slot=[", slot_id, "]" )

	if slot_id == nil then
		return cp.location[loc_id].bag[bag_id]
	else
		return cp.location[loc_id].bag[bag_id].slot[slot_id]
	end

end

function ArkInventory.Frame_Item_Update_Texture( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local i = ArkInventory.Frame_Item_GetDB( frame )

	if i and i.h then

		-- frame has an item
		frame.hasItem = 1

		-- item is readable?
		if loc_id ~= ArkInventory.Const.Location.Vault then
			if ArkInventory.Global.Location[loc_id].isOffline == false then
				frame.readable = i.readable
			end
		else
			frame.readable = nil
		end

		-- item texture
		local t = i.texture or ArkInventory.ObjectInfoTexture( i.h )
		local r, g, b = GetItemQualityColor( 0 )
		ArkInventory.SetItemButtonTexture( frame, t, r, g, b )

	else

		frame.hasItem = nil
		frame.readable = nil

		ArkInventory.Frame_Item_Update_Empty( frame )

	end

	-- new item indicator
	ArkInventory.Frame_Item_Update_NewIndicator( frame )

end

function ArkInventory.Frame_Item_Update_Quest( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local questTexture = _G[frame:GetName( ) .. "IconQuestTexture"]
	questTexture:Hide( )

	local loc_id = frame.ARK_Data.loc_id
	if ArkInventory.Global.Location[loc_id].isOffline then
		return
	end

	if not ( loc_id == ArkInventory.Const.Location.Bag or loc_id == ArkInventory.Const.Location.Bank ) then
		return
	end

	local i = ArkInventory.Frame_Item_GetDB( frame )

	if i and i.h then

		local bliz_id = ArkInventory.BagID_Blizzard( loc_id, i.bag_id )
		local isQuestItem, questId, isActive = GetContainerItemQuestInfo( bliz_id, i.slot_id )

		if questId and not isActive then
			questTexture:SetTexture( TEXTURE_ITEM_QUEST_BANG )
			questTexture:Show( )
		elseif questId or isQuestItem then
			questTexture:SetTexture( TEXTURE_ITEM_QUEST_BORDER )
			questTexture:Show( )
		end

	end

end

function ArkInventory.SetItemButtonTexture( frame, texture, r, g, b )

	if not frame then
		return
	end

	local obj = _G[frame:GetName( ) .. "IconTexture"]

	if not obj then
		return
	end

	if texture then
		obj:Show( )
	else
		obj:Hide( )
	end

	obj:SetTexture( texture or ArkInventory.Const.Texture.Missing )
	obj:SetTexCoord( 0.070, 0.935, 0.070, 0.935 )

	if r and g and b then
		obj:SetVertexColor( r, g, b )
	end

end

function ArkInventory.SetItemButtonDesaturate( frame, desaturate, r, g, b )

	if not frame then
		return
	end

	local obj = _G[frame:GetName( ) .. "IconTexture"]

	if not obj then
		return
	end

	local shaderSupported = obj:SetDesaturated( desaturate )

	if desaturate then

		if shaderSupported then
			return
		end

		if not r or not g or not b then
			r = 0.5
			g = 0.5
			b = 0.5
		end

	else

		if not r or not g or not b then
			r = 1.0
			g = 1.0
			b = 1.0
		end

	end

	obj:SetVertexColor( r, g, b )

end

function ArkInventory.Frame_Item_Update_Count( frame )

	local i = ArkInventory.Frame_Item_GetDB( frame )

	if i then
		SetItemButtonCount( frame, i.count )
		--SetItemButtonStock( frame, i.slot_id ) -- display slot number for debugging purposes
	end

end

function ArkInventory.Frame_Item_Update_Fade( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local action = false
	local fade = 1

	if ArkInventory.Global.Location[loc_id].isOffline and ArkInventory.LocationOptionGet( loc_id, { "slot", "offline", "fade" } ) then

		fade = 0.6

	else

		if loc_id == ArkInventory.Const.Location.Vault then

			local bag_id = frame.ARK_Data.bag_id
			local canDeposit, numWithdrawals = select( 4, GetGuildBankTabInfo( bag_id ) )
			if not canDeposit and numWithdrawals == 0 then
				fade = 0.6
			end

		end

	end

	local loc = ArkInventory.Global.Location[loc_id]
	local f = string.lower( strtrim( loc.filter or "" ) )
	local rule_mode = ArkInventory.SearchIsRuleMode and ArkInventory.SearchIsRuleMode( )
	if f ~= "" then
		local i = ArkInventory.Frame_Item_GetDB( frame ) or { }
		if rule_mode then
			-- in rule mode we only apply filtering once a compiled
			-- rule function exists; otherwise we treat the filter as
			-- empty so that typing just the rule keyword (eg "tt")
			-- does not trigger a name search
			if loc.filter_rule_func and i and i.h and ArkInventory.RuleEvaluate then
				local matched = ArkInventory.RuleEvaluate( loc.filter_rule_func, i.h, i.count, i.q ) and true or false
				if not matched then
					fade = 0.2
				end
			end
		else
			if ArkInventory.SearchItemMatchesFilter then
				if not ArkInventory.SearchItemMatchesFilter( i.h, i.count, i.q, f ) then
					-- drop fade to 0.2 for all non matching items
					fade = 0.2
				end
			else
				-- legacy behaviour: plain text only matches against the item name
				local n = string.lower( select( 3, ArkInventory.ObjectInfo( i.h ) ) or "" )
				if not string.find( n, strtrim( f ) ) then
					fade = 0.2
				end
			end
		end
	end

	frame:SetAlpha( fade )

end

function ArkInventory.Frame_Item_Update_Border( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id

	local obj = _G[frame:GetName( ) .. "ArkBorder"]
	if obj then

		if ArkInventory.LocationOptionGet( loc_id, { "slot", "border", "style" } ) ~= ArkInventory.Const.Texture.BorderNone then

			local style = ArkInventory.LocationOptionGet( loc_id, { "slot", "border", "style" } ) or ArkInventory.Const.Texture.BorderDefault
			local file = ArkInventory.Lib.SharedMedia:Fetch( ArkInventory.Lib.SharedMedia.MediaType.BORDER, style )
			local size = ArkInventory.LocationOptionGet( loc_id, { "slot", "border", "size" } ) or ArkInventory.Const.Texture.Border[ArkInventory.Const.Texture.BorderDefault].size
			local offset = ArkInventory.LocationOptionGet( loc_id, { "slot", "border", "offset" } ) or ArkInventory.Const.Texture.Border[ArkInventory.Const.Texture.BorderDefault].offset
			local scale = ArkInventory.LocationOptionGet( loc_id, { "slot", "border", "scale" } ) or 1

			-- border colour
			local i = ArkInventory.Frame_Item_GetDB( frame )

			local r, g, b = GetItemQualityColor( 0 )
			local a = 0.6

			if i and i.h then

















				if ArkInventory.LocationOptionGet( loc_id, { "slot", "border", "rarity" } ) then
					if ( i.q or 0 ) >= ( ArkInventory.LocationOptionGet( loc_id, { "slot", "border", "raritycutoff" } ) or 0 ) then
						r, g, b = GetItemQualityColor( i.q or 0 )
						a = 1
					end
				end

			else

				if ArkInventory.LocationOptionGet( loc_id, { "slot", "empty", "border" } ) then

					-- slot colour
					local cp = ArkInventory.LocationPlayerInfoGet( loc_id )
					local bag_id = frame.ARK_Data.bag_id
					local bt = cp.location[loc_id].bag[bag_id].type
					local c = ArkInventory.LocationOptionGet( loc_id, { "slot", "data", bt, "colour" } )
					r, g, b = c.r, c.g, c.b

				end

			end

			ArkInventory.Frame_Border_Paint( obj, true, file, size, offset, scale, r, g, b, a )

			obj:Show( )

		else

			obj:Hide( )

		end

	end

end

function ArkInventory.Frame_Item_Update_NewIndicator( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local framename = frame:GetName( )

	local obj_name = "ArkNewText"
	local obj = _G[framename .. obj_name]
	assert( obj, string.format( "xml element '%s' is missing the sub element %s", framename, obj_name ) )

	local loc_id = frame.ARK_Data.loc_id
	local i = ArkInventory.Frame_Item_GetDB( frame )

	if i and i.h and ArkInventory.LocationOptionGet( loc_id, { "slot", "new", "show" } ) then

		--[[
		if i.new == ArkInventory.Const.Slot.New.No then
			obj:Hide( )
		elseif i.new == ArkInventory.Const.Slot.New.Yes then
			obj:SetText( ArkInventory.Localise["NEW"] )
			obj:Show( )
		elseif i.new == ArkInventory.Const.Slot.New.Inc then
			obj:SetText( ArkInventory.Localise["NEW_ITEM_INCREASE"] )
			obj:Show( )
		elseif i.new == ArkInventory.Const.Slot.New.Dec then
			obj:SetText( ArkInventory.Localise["NEW_ITEM_DECREASE"] )
			obj:Show( )
		end
		]]--

		local cutoff = ArkInventory.LocationOptionGet( loc_id, { "slot", "new", "cutoff" } )
		local age, age_text = ArkInventory.ItemAgeGet( i.age )

		if age and ( cutoff == 0 or age <= cutoff * 60 ) then
			local colour = ArkInventory.LocationOptionGet( loc_id, { "slot", "new", "colour" } )
			obj:SetText( age_text )
			obj:SetTextColor( colour.r, colour.g, colour.b )
			obj:Show( )
		else
			obj:Hide( )
		end

	else
		obj:Hide( )
	end

end

function ArkInventory.Frame_Item_Update_Empty( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )
	local bag_id = frame.ARK_Data.bag_id
	local i = ArkInventory.Frame_Item_GetDB( frame )

	if i and not i.h then

		local bt = cp.location[loc_id].bag[bag_id].type

		-- slot background
		if ArkInventory.LocationOptionGet( loc_id, { "slot", "empty", "icon" } ) then

			-- icon
			local texture = ArkInventory.Const.Slot.Data[bt].texture or ArkInventory.Const.Texture.Empty.Item

			-- wearing empty slot icons
			if loc_id == ArkInventory.Const.Location.Wearing then
				local a, b = GetInventorySlotInfo( ArkInventory.Const.InventorySlotName[i.slot_id] )
				--ArkInventory.Output( "id=[", i.slot_id, "], name=[", ArkInventory.Const.InventorySlotName[i.slot_id], "], texture=[", b, "]" )
				texture = b
			end

			ArkInventory.SetItemButtonTexture( frame, texture, 1.0, 1.0, 1.0 )

		else

			-- solid colour
			local colour = ArkInventory.LocationOptionGet( loc_id, { "slot", "data", bt, "colour" } )
			--ArkInventory.SetItemButtonTexture( frame, [[Interface\Buttons\WHITE8X8]], colour.r * 0.25, colour.g * 0.25, colour.b * 0.25 )
			ArkInventory.SetItemButtonTexture( frame, [[Interface\Buttons\WHITE8X8]], colour.r, colour.g, colour.b )

		end

	end

end

function ArkInventory.Frame_Item_Empty_Paint_All( )

	for loc_id, loc_data in ipairs( ArkInventory.Global.Location ) do

		for bag_id in pairs( loc_data.Bags ) do

			for slot_id = 1, ArkInventory.Global.Location[loc_id].maxSlot[bag_id] or 0 do

				local s = _G[ArkInventory.ContainerItemNameGet( loc_id, bag_id, slot_id )]
				if s then
					ArkInventory.Frame_Item_Update_Empty( s )
					ArkInventory.Frame_Item_Update_Border( s )
				end

			end

		end

	end

end

function ArkInventory.Frame_Item_OnEnter( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	if not ArkInventory.db.global.option.tooltip.show then
		return
	end

	-- When the container window is being dragged, avoid rebuilding tooltips.
	-- Auction-related tooltip integrations (eg. pricing addons) can be expensive
	-- and rapid tooltip rebuilds during movement can cause noticeable freezes.
	local main = ArkInventory.Frame_Main_Get( frame.ARK_Data.loc_id )
	if main and main.ARK_Data and main.ARK_Data.dragging then
		return
	end
	if main and main.IsMoving and main:IsMoving( ) then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local bag_id = frame.ARK_Data.bag_id
	local bliz_id = ArkInventory.BagID_Blizzard( loc_id, bag_id )
	local i = ArkInventory.Frame_Item_GetDB( frame )


	--ArkInventory.Output( "item=[", i.h, "]" )
	local usedmycode = false

	-- Use ArkInventory's own tooltip path for special locations and
	-- offline/edit viewing, but let bag items (loc_id == Bag) always
	-- go through the default ContainerFrameItemButton_OnEnter path so
	-- Ascension's container tooltip hooks apply consistently in both
	-- normal and edit modes.
if ( ArkInventory.Global.Mode.Edit and loc_id ~= ArkInventory.Const.Location.Bag ) or ArkInventory.Global.Location[loc_id].isOffline or bliz_id == BANK_CONTAINER or bliz_id == KEYRING_CONTAINER or loc_id == ArkInventory.Const.Location.Vault or loc_id == ArkInventory.Const.Location.PersonalBank or loc_id == ArkInventory.Const.Location.RealmBank or loc_id == ArkInventory.Const.Location.Wearing or loc_id == ArkInventory.Const.Location.Mail or loc_id == ArkInventory.Const.Location.Pet or loc_id == ArkInventory.Const.Location.Mount or loc_id == ArkInventory.Const.Location.Token then

		usedmycode = true -- edit mode, offline, bank, keyring, vault, mail, pet, token

		-- if the cached hyperlink is missing but we're online, try to
		-- recover it from the live API for this specific slot so the
		-- tooltip can still be shown and future categorisation sees the
		-- real item link.
		if i and not i.h and not ArkInventory.Global.Location[loc_id].isOffline then
			if loc_id == ArkInventory.Const.Location.Bank then
				local link
				if bliz_id == BANK_CONTAINER then
					link = GetContainerItemLink( BANK_CONTAINER, i.slot_id )
				else
					link = GetContainerItemLink( bliz_id, i.slot_id )
				end
				if link then
					i.h = link
					ArkInventory.ItemCacheClear( )
				end
			elseif loc_id == ArkInventory.Const.Location.Vault or loc_id == ArkInventory.Const.Location.PersonalBank then
				local link = GetGuildBankItemLink( i.bag_id, i.slot_id )
				if link then
					i.h = link
					ArkInventory.ItemCacheClear( )
				end
			end
		end

		if i and i.h then

			ArkInventory.GameTooltipSetPosition( frame )

			if loc_id == ArkInventory.Const.Location.Mail then

				GameTooltip:SetHyperlink( i.h )

				local daysLeft = 0
				if i.dl then

					GameTooltip:AddLine( dl, 0, 1, 0 )

--[[					if i.dl >= 1 then
						daysLeft = TIME_REMAINING .. " " .. floor(i.dl) .. " " .. GetText("DAYS_ABBR", nil, floor(i.dl))
						GameTooltip:AddLine( daysLeft, 0, 1, 0 )
					else
						daysLeft = TIME_REMAINING .. " " .. SecondsToTime(floor(i.dl * 24 * 60 * 60))
						GameTooltip:AddLine( daysLeft, 1, 0, 0 )
					end
	]]--
				end

			elseif loc_id == ArkInventory.Const.Location.Pet or loc_id == ArkInventory.Const.Location.Mount then

				GameTooltip:SetHyperlink( i.h )

			elseif loc_id == ArkInventory.Const.Location.Token then

				ArkInventory.GameTooltipSetToken( frame, i.h, i.count )

			elseif loc_id == ArkInventory.Const.Location.Wearing then

				GameTooltip:SetHyperlink( i.h )

			elseif ArkInventory.Global.Mode.Edit or ArkInventory.Global.Location[loc_id].isOffline then

				GameTooltip:SetHyperlink( i.h )


	-- online options

			elseif bliz_id == BANK_CONTAINER then

				GameTooltip:SetInventoryItem( "player", BankButtonIDToInvSlotID( i.slot_id ) )

			elseif bliz_id == KEYRING_CONTAINER then

				GameTooltip:SetInventoryItem( "player", KeyRingButtonIDToInvSlotID( i.slot_id ) )

			elseif loc_id == ArkInventory.Const.Location.Vault or loc_id == ArkInventory.Const.Location.PersonalBank or loc_id == ArkInventory.Const.Location.RealmBank then

				local tab_id = i.bag_id

				local _, _, isViewable = GetGuildBankTabInfo( tab_id )

				if isViewable then
					GameTooltip:SetGuildBankItem( tab_id, i.slot_id )
				else
					GameTooltip:SetHyperlink( i.h )
				end

			else

				-- fallback: just show the hyperlink if we somehow reach here
				GameTooltip:SetHyperlink( i.h )

			end


			-- when in edit mode we override the default cursor behaviour
			-- so always show the normal cursor and skip CursorUpdate (which
			-- would otherwise change to the vendor sell icon, etc.)
			if ArkInventory.Global.Mode.Edit then
				ResetCursor( )
			else
				if IsModifiedClick( "CHATLINK" ) then
					GameTooltip_ShowCompareItem( )
				elseif IsModifiedClick( "DRESSUP" ) then
					ShowInspectCursor( )
				elseif frame.readable then
					ShowInspectCursor( )
				else
					ResetCursor( )
				end

				CursorUpdate( frame )
			end

		end

	end

	if not usedmycode then
		ContainerFrameItemButton_OnEnter( frame )
		-- for live bag items we normally delegate to the default
		-- ContainerFrame tooltip behaviour so any server-specific
		-- hooks still run; however in edit mode we want the cursor
		-- to remain the normal arrow instead of the vendor sell icon
		-- or other special cursors, so force a reset after Blizzard
		-- has done its updates.
		if ArkInventory.Global.Mode.Edit then
			ResetCursor( )
		end
	end

end

function ArkInventory.Frame_Item_OnDrag( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local usedmycode = false



	if SpellIsTargeting( ) or ArkInventory.Global.Location[loc_id].isOffline or ArkInventory.Global.Mode.Edit then

		usedmycode = true
		-- do not drag / drag disabled

	end

	if not usedmycode then
		ContainerFrameItemButton_OnClick( frame, "LeftButton" )
	end

end

function ArkInventory.Frame_Item_OnMouseUp( frame, button )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local i = ArkInventory.Frame_Item_GetDB( frame )

	-- When a spell is targeting (eg. Disenchant), let Blizzard's secure
	-- ContainerFrameItemButtonTemplate handling run without ArkInventory
	-- re-invoking protected click handlers. Calling those handlers from
	-- addon code can trigger an ADDON_ACTION_BLOCKED popup.
	if loc_id == ArkInventory.Const.Location.Bag then
		local hasSpell = false
		if CursorHasSpell then
			hasSpell = CursorHasSpell( )
		end
		if SpellIsTargeting( ) or hasSpell then
			return
		end
	end

	-- Alt+RightClick shortcut: open the item edit menu even when
	-- not in edit mode. This uses the same Dewdrop menu as edit
	-- mode but does not toggle the global edit state.
	if not ArkInventory.Global.Mode.Edit and button == "RightButton" and IsAltKeyDown( ) then
		if i and i.h then
			ArkInventory.MenuItemOpen( frame, true )
		end
		return
	end

	if ArkInventory.Global.Location[loc_id].isOffline or ArkInventory.Global.Mode.Edit then

		if IsModifierKeyDown( ) then

			if i and i.h then
				HandleModifiedItemClick( i.h )
			end

		else

			if ArkInventory.Global.Mode.Edit then

				if button == "RightButton" then
					ArkInventory.MenuItemOpen( frame )
				elseif button == "LeftButton" then
					if ArkInventory.Lib and ArkInventory.Lib.DewDrop and ArkInventory.Lib.DewDrop:IsOpen( ) then
						ArkInventory.Lib.DewDrop:Close( )
					end
				end

			end

		end

	end

	-- live clicks: handle personal/realm vault deposit on first/open sessions
	if not ArkInventory.Global.Location[loc_id].isOffline and not ArkInventory.Global.Mode.Edit then

		local i = ArkInventory.Frame_Item_GetDB( frame )
		if ArkInventory.Global.Mode.Vault and ( ArkInventory.Global.Mode.VaultContext == "personal" or ArkInventory.Global.Mode.VaultContext == "realm" ) and loc_id == ArkInventory.Const.Location.Bag then

			-- respect modified clicks (chat link, dress up)
			if i and i.h and HandleModifiedItemClick( i.h ) then
				if ArkInventory.OutputDebug then
					ArkInventory.OutputDebug( "Vault clicks: bag OnMouseUp handled modified click; exiting" )
				end
				return
			end

			if button == "RightButton" and not IsModifierKeyDown( ) then
				-- If Blizzard's GuildBankFrame is actually open (even if invisible),
				-- let the default Blizzard click handler do the deposit. This avoids
				-- the double "move" sound caused by our manual Pickup+Place logic.
				if GuildBankFrame and GuildBankFrame.IsShown and GuildBankFrame:IsShown( ) then
					ContainerFrameItemButton_OnClick( frame, button )
					return
				end

				local bliz_bag = ArkInventory.BagID_Blizzard( loc_id, i.bag_id )
				-- determine the logical target tab: for personal/realm banks use the
				-- location-specific current_tab first, falling back to Blizzard's
				-- current guild bank tab if needed
				local target_tab = GetCurrentGuildBankTab( ) or 1
				local vault_loc = ArkInventory.Global.Mode.VaultLocation or ArkInventory.Const.Location.Vault
				if ArkInventory.Global.Mode.VaultContext == "personal" or ArkInventory.Global.Mode.VaultContext == "realm" then
					local loc = ArkInventory.Global.Location[vault_loc]
					if loc and loc.current_tab then
						target_tab = loc.current_tab
					end
				end

				if ArkInventory.OutputDebug then
					ArkInventory.OutputDebug( "Vault clicks: bag OnMouseUp deposit path: bag_id=", i and i.bag_id, ", slot_id=", i and i.slot_id, ", target_tab=", target_tab )
				end
				PickupContainerItem( bliz_bag, i.slot_id )
				ArkInventory.PutItemInGuildBank( target_tab )
				-- In personal/realm bank mode, immediately request a vault rescan so
				-- any race or missed Blizzard events can't leave stale icons in the
				-- previous tab view.
				if ArkInventory.Global.Mode.VaultContext == "personal" or ArkInventory.Global.Mode.VaultContext == "realm" then
					ArkInventory:SendMessage( "LISTEN_VAULT_UPDATE_BUCKET", 1 )
				end
				if ArkInventory.OutputDebug then
					ArkInventory.OutputDebug( "Vault clicks: bag OnMouseUp deposit attempted via PutItemInGuildBank" )
				end
				return
			end

			-- default behaviour for other buttons/modifiers
			ContainerFrameItemButton_OnClick( frame, button )
			if ArkInventory.OutputDebug then
				ArkInventory.OutputDebug( "Vault clicks: bag OnMouseUp default ContainerFrameItemButton_OnClick" )
			end
			return
		end

		-- not in vault override context, use default behaviour
		-- For normal bag usage, the inherited ContainerFrameItemButtonTemplate
		-- already runs the Blizzard OnClick handler. Calling it again here can
		-- trigger protected-action popups (even though the item still uses).
		if loc_id == ArkInventory.Const.Location.Bag then
			return
		end

		ContainerFrameItemButton_OnClick( frame, button )
		return
	end

end

-- Override bag item clicks while in personal/realm vault so right-click deposits
-- instead of using consumables. This compensates for Blizzard deposit logic that
-- normally requires GuildBankFrame to be shown.

function ArkInventory.Frame_Item_Update_Cooldown( frame, arg1 )

	-- triggered when a cooldown is first started
	-- used to hide/show the cooldown frame when offline and tint unuseable items

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local i = ArkInventory.Frame_Item_GetDB( frame )

	if i and ( arg1 == nil or arg1 == i.bag_id ) then

		local framename = frame:GetName( )
		local obj_name = "Cooldown"
		local obj = _G[framename .. obj_name]
		assert( obj, string.format( "xml element '%s' is missing the sub element %s", framename, obj_name ) )

		if ArkInventory.Global.Location[loc_id].isOffline then
			SetItemButtonTextureVertexColor( frame, 1, 1, 1 )
			obj:Hide( )
			return
		end

		if not ArkInventory.LocationOptionGet( loc_id, { "slot", "cooldown", "show" } ) then
			obj:Hide( )
			return
		end

		if i.h then

			local bliz_id = ArkInventory.BagID_Blizzard( loc_id, i.bag_id )
			ContainerFrame_UpdateCooldown( bliz_id, frame )

		else

			obj:Hide( )

		end

	end

end

function ArkInventory.Frame_Item_Update_Lock( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	if ArkInventory.Global.Location[loc_id].isOffline then
		return
	end

	local i = ArkInventory.Frame_Item_GetDB( frame )

	if i and i.h then

		local locked = false
		local readable = false
		local quality = nil

		if loc_id == ArkInventory.Const.Location.Vault then
			locked = select( 3, GetGuildBankItemInfo( i.bag_id, i.slot_id ) )
		else
			local bliz_id = ArkInventory.BagID_Blizzard( loc_id, i.bag_id )
			locked, quality, readable = select( 3, GetContainerItemInfo( bliz_id, i.slot_id ) )
		end


		local use = true

		if ArkInventory.LocationOptionGet( loc_id, { "slot", "unusable", "tint" } ) then
			ArkInventory.TooltipSetHyperlink( ArkInventory.Global.Tooltip.Vendor, i.h )
			use = ArkInventory.TooltipCanUse( ArkInventory.Global.Tooltip.Vendor )
		end

		--ArkInventory.Output( "slot[", i.slot_id, "] locked[", locked or 0, "], use[", use or false, "]" )

		if use then
			ArkInventory.SetItemButtonDesaturate( frame, locked )
		else
			ArkInventory.SetItemButtonDesaturate( frame, locked, 1.0, 0.1, 0.1 )
		end


		frame.locked = locked
		frame.readable = readable

	else

		frame.locked = false
		frame.readable = false

	end

end

function ArkInventory.Frame_Item_Update_Clickable( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id

	local disableClicks = false
	local disableDrag = false

	if ArkInventory.Global.Mode.Edit
	or ArkInventory.Global.Location[loc_id].isOffline
	or loc_id == ArkInventory.Const.Location.Wearing
	or loc_id == ArkInventory.Const.Location.Mail
	or loc_id == ArkInventory.Const.Location.Token then
		disableClicks = true
		disableDrag = true

	else

		if frame.ARK_Data.loc_id == ArkInventory.Const.Location.Vault then

			local bag_id = frame.ARK_Data.bag_id
			local _, _, _, canDeposit, numWithdrawals = GetGuildBankTabInfo( bag_id )
			if not canDeposit and numWithdrawals == 0 then
				disableClicks = true
				disableDrag = true
			end

		end

	end

	-- While in personal/realm vault mode, ArkInventory handles bag-slot clicks
	-- via Frame_Item_OnMouseUp to support deposit overrides. Prevent the inherited
	-- Blizzard OnClick from also firing (double handling) by unregistering clicks.
	if not disableClicks
	and loc_id == ArkInventory.Const.Location.Bag
	and ArkInventory.Global.Mode.Vault
	and ( ArkInventory.Global.Mode.VaultContext == "personal" or ArkInventory.Global.Mode.VaultContext == "realm" ) then
		disableClicks = true
		-- keep drag enabled
	end


	if disableClicks then
		frame:RegisterForClicks( )
	else
		frame:RegisterForClicks( "LeftButtonUp", "RightButtonUp" )
	end

	if disableDrag then
		frame:RegisterForDrag( )
	else
		frame:RegisterForDrag( "LeftButton" )
	end

end

function ArkInventory.Frame_Item_Update_Clickable_All( )

	-- Refresh click/drag registration for all visible item buttons so
	-- changes to edit/offline/view-only state take effect without
	-- requiring a full layout recalculate.

	for loc_id, loc_data in ipairs( ArkInventory.Global.Location ) do

		local frame = _G[ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Container.Name]
		if frame and frame:IsVisible( ) then

			if loc_data.Bags and loc_data.maxSlot then
				for bag_id in pairs( loc_data.Bags ) do
					local maxSlot = loc_data.maxSlot[bag_id] or 0
					for slot_id = 1, maxSlot do
						local itemframename = ArkInventory.ContainerItemNameGet( loc_id, bag_id, slot_id )
						local itemframe = _G[itemframename]
						if itemframe then
							ArkInventory.Frame_Item_Update_Clickable( itemframe )
						end
					end
				end
			end

		end

	end

end

function ArkInventory.Frame_Item_OnLoad( frame )

	local framename = frame:GetName( )
	--ArkInventory.Output( "OnLoad( ", framename, " ]" )

	local loc_id, bag_id, slot_id = strmatch( framename, "^.-(%d+)ContainerBag(%d+)Item(%d+)" )

	assert( loc_id, string.format( "xml element '%s' is not an %s frame", framename, ArkInventory.Const.Program.Name ) )
	assert( bag_id, string.format( "xml element '%s' is not an %s frame", framename, ArkInventory.Const.Program.Name ) )
	assert( slot_id, string.format( "xml element '%s' is not an %s frame", framename, ArkInventory.Const.Program.Name ) )

	loc_id = tonumber( loc_id )
	bag_id = tonumber( bag_id )
	slot_id = tonumber( slot_id )

	frame:SetID( slot_id )

	--local bag_id = ArkInventory.BagID_Blizzard( loc_id, bag_id )
	--ArkInventory.Output( "loc=[", loc_id, "], int=[", bag_id, "], slot=[", slot_id, "], bag=[", bag_id, "]" )

	frame.ARK_Data = {
		["loc_id"] = loc_id,
		["bag_id"] = bag_id,
		["slot_id"] = slot_id,
	}

	ContainerFrameItemButton_OnLoad( frame )

	local obj = _G[framename .. "Count"]
	if obj ~= nil then
		obj:SetPoint( "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 2 )
		obj:SetPoint( "LEFT", frame, "LEFT", 0, 0 )
	end

	frame.UpdateTooltip = ArkInventory.Frame_Item_OnEnter

	frame.locked = false

	-- Replace the stack split handler for any guild-style bank
	-- location (standard guild vault, personal bank, realm bank)
	-- so that the StackSplitFrame "OK" button actually performs
	-- a SplitGuildBankItem on the correct tab/slot.
	if loc_id == ArkInventory.Const.Location.Vault or loc_id == ArkInventory.Const.Location.PersonalBank or loc_id == ArkInventory.Const.Location.RealmBank then

		frame.SplitStack = function( button, split )
			local tab_id = frame.ARK_Data.bag_id
			local slot_id = frame.ARK_Data.slot_id
			SplitGuildBankItem( tab_id, slot_id, split )
		end

	end

	ArkInventory.MediaSetFontFrame( frame )

end

function ArkInventory.Frame_Pet_Item_OnClick( frame, button )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local i = ArkInventory.Frame_Item_GetDB( frame )

	if IsModifiedClick( "CHATLINK" ) then

		ChatEdit_InsertLink( i.h )

	else

		if not ArkInventory.Global.Location[loc_id].isOffline or not ArkInventory.Global.Mode.Edit then

			local creatureID, creatureName, spellID, icon, active = GetCompanionInfo( i.type, i.slot_id )

			if active then
				DismissCompanion( i.type )
				PlaySound( "igMainMenuOptionCheckBoxOn" )
			else
				CallCompanion( i.type, i.slot_id )
				PlaySound( "igMainMenuOptionCheckBoxOff" )
			end

		end

	end

end

function ArkInventory.Frame_Pet_Item_OnDrag( frame )

	if ArkInventory.Global.Mode.Edit then
		return
	end

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local i = ArkInventory.Frame_Item_GetDB( frame )

	if not ArkInventory.Global.Location[loc_id].isOffline then
		PickupCompanion( i.type, i.slot_id )
	end

end

function ArkInventory.Frame_Item_Update( loc_id, bag_id, slot_id )

	local framename = ArkInventory.ContainerItemNameGet( loc_id, bag_id, slot_id )
	local frame = _G[framename]

	if frame and not ArkInventory.Global.Location[loc_id].isOffline then
		ArkInventory.Frame_Item_Update_Border( frame )
		ArkInventory.Frame_Item_Update_Fade( frame )
		ArkInventory.Frame_Item_Update_Count( frame )
		ArkInventory.Frame_Item_Update_Texture( frame )
		ArkInventory.Frame_Item_Update_Quest( frame )
		ArkInventory.Frame_Item_Update_Cooldown( frame )
		ArkInventory.Frame_Item_Update_Lock( frame )
	end

end

function ArkInventory.Frame_Status_Update( frame )

	local loc_id = frame.ARK_Data.loc_id
	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )

	-- hide the status window if it's not needed
	local obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Status.Name]
	if ArkInventory.LocationOptionGet( loc_id, { "status", "hide" } ) then
		obj:Hide( )
		obj:SetHeight( 3 )
		return
	else
		obj:SetHeight( ArkInventory.Const.Frame.Status.Height )
		obj:Show( )
	end


	-- update money
	local moneyFrameName = obj:GetName( ) .. "Gold"
	local moneyFrame = _G[moneyFrameName]
	assert( moneyFrame, "moneyframe is nil" )

	if ArkInventory.Global.Location[loc_id].isOffline then
		ArkInventory.MoneyFrame_SetType( moneyFrame, "STATIC" )
		MoneyFrame_Update( moneyFrameName, cp.info.money or 0 )
		SetMoneyFrameColor( moneyFrameName, 0.75, 0.75, 0.75 )
	else
		SetMoneyFrameColor( moneyFrameName, 1, 1, 1 )
		if loc_id == ArkInventory.Const.Location.Vault or loc_id == ArkInventory.Const.Location.PersonalBank or loc_id == ArkInventory.Const.Location.RealmBank then
			ArkInventory.MoneyFrame_SetType( moneyFrame, "GUILDBANK" )
		else
			ArkInventory.MoneyFrame_SetType( moneyFrame, "PLAYER" )
		end
	end


	-- update the empty slot count
	local obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Status.Name .. "EmptyText"]
	if obj then
		if ArkInventory.LocationOptionGetReal( loc_id, { "status", "emptytext", "show" } ) then
			local y = ArkInventory.Frame_Status_Update_Empty( loc_id, cp )
			obj:SetText( y )
		else
			obj:SetText( "" )
		end
	end


	-- update currency tracking
	ArkInventory.Frame_Status_Update_Tracking( loc_id )

end

function ArkInventory.Frame_Status_Update_Empty( loc_id, cp, ldb )

	-- build the empty slot count status string

	local empty = { }
	local bags = cp.location[loc_id].bag

	for k, bag in pairs( bags ) do

		if not empty[bag.type] then
			empty[bag.type] = { ["count"] = 0, ["empty"] = 0, ["type"] = bag.type }
		end

		if bag.status == ArkInventory.Const.Bag.Status.Active then
			empty[bag.type].count = empty[bag.type].count + bag.count
			empty[bag.type].empty = empty[bag.type].empty + bag.empty
			--ArkInventory.Output( "k=[", k, "] t=[", bag.type, "] c=[", bag.count, "]" )
		end

	end

	local ee = ArkInventory.Table.Sum( empty, function( a ) return a.empty end )
	local ts = cp.location[loc_id].slot_count

	local y = { }

	if ts == 0 then

		table.insert( y, RED_FONT_COLOR_CODE .. ArkInventory.Localise["STATUS_NO_DATA"] )

	else

		for t, e in ArkInventory.spairs( empty, function(a,b) return empty[a].type < empty[b].type end ) do

			local c = "|cffffffff"
			local n = " " .. ArkInventory.Const.Slot.Data[t].name

			if ldb then

				if ArkInventory.db.char.option.ldb.bags.colour then
					c = ArkInventory.LocationOptionGet( loc_id, { "slot", "data", t, "colour" } )
					c = ArkInventory.ColourRGBtoCode( c.r, c.g, c.b )
				end

				if not ArkInventory.db.char.option.ldb.bags.includetype then
					n = ""
				end

				if ArkInventory.db.char.option.ldb.bags.full then
					table.insert( y, string.format( "%s%i/%i%s%s", c, e.count - e.empty, e.count, n, FONT_COLOR_CODE_CLOSE ) )
				else
					table.insert( y, string.format( "%s%i%s%s", c, e.empty, n, FONT_COLOR_CODE_CLOSE ) )
				end

			else

				if ArkInventory.LocationOptionGet( loc_id, { "status", "emptytext", "colour" } ) then
					c = ArkInventory.LocationOptionGet( loc_id, { "slot", "data", t, "colour" } )
					c = ArkInventory.ColourRGBtoCode( c.r, c.g, c.b )
				end

				if not ArkInventory.LocationOptionGet( loc_id, { "status", "emptytext", "includetype" } ) then
					n = ""
				end

				if ArkInventory.LocationOptionGet( loc_id, { "status", "emptytext", "full" } ) then
					table.insert( y, string.format( "%s%i/%i%s%s", c, e.count - e.empty, e.count, n, FONT_COLOR_CODE_CLOSE ) )
				else
					table.insert( y, string.format( "%s%i%s%s", c, e.empty, n, FONT_COLOR_CODE_CLOSE ) )
				end

			end

		end

	end

	return "|cfff9f9f9" .. table.concat( y, ", " )

end

function ArkInventory.Frame_Status_Update_Tracking( loc_id )

	if loc_id and loc_id  ~= ArkInventory.Const.Location.Bag then
		return
	end

	local frame = ArkInventory.Frame_Main_Get( ArkInventory.Const.Location.Bag )
	frame = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Status.Name]

	if not frame:IsVisible( ) then return end

	for i = 1, MAX_WATCHED_TOKENS do

		local t = _G[frame:GetName( ) .. "TrackingIcon" .. i]
		local c = _G[frame:GetName( ) .. "TrackingCount" .. i]
		local d = _G[frame:GetName( ) .. "TrackingData" .. i]

		local name, count, currencyType, icon, item = GetBackpackCurrencyInfo( i )

		if name then

			if currencyType == 1 then
				icon = [[Interface\PVPFrame\PVP-ArenaPoints-Icon]]
			elseif currencyType == 2 then
				local factionGroup = UnitFactionGroup( "player" )
				if factionGroup then
					icon = [[Interface\PVPFrame\PVP-Currency-]] .. factionGroup
				end
			end

			t:SetTexture( icon )
			t:Show( )

			c:SetText( string.format( "%s", count ) )
			c:Show( )

			d.item = select( 2, GetItemInfo( item ) )
			d:Show( )
			--ArkInventory.Output( i, " = ", d.item, " ", type( d.item ) )

		else

			t:Hide( )

			c:Hide( )

			d.item = nil
			d:Hide( )

		end

	end

end

function ArkInventory.Frame_Vault_Item_OnClick( frame, arg1 )

	--ArkInventory.Output( "OnClick( ", frame:GetName( ), ", ", arg1, " )" )

	if frame.ARK_Data.loc_id == ArkInventory.Const.Location.Vault or frame.ARK_Data.loc_id == ArkInventory.Const.Location.PersonalBank or frame.ARK_Data.loc_id == ArkInventory.Const.Location.RealmBank then

		local loc_id = frame.ARK_Data.loc_id
		local tab_id = frame.ARK_Data.bag_id
		local slot_id = frame.ARK_Data.slot_id

		-- When Alt+RightClicking a personal/realm bank slot, the
		-- edit menu has already been opened via Frame_Item_OnMouseUp.
		-- Suppress the normal guild bank click behaviour here so the
		-- item is not also moved between bank and bags.
		if not ArkInventory.Global.Mode.Edit
		and ( loc_id == ArkInventory.Const.Location.PersonalBank or loc_id == ArkInventory.Const.Location.RealmBank )
		and arg1 == "RightButton"
		and IsAltKeyDown( ) then
			return
		end

		if HandleModifiedItemClick( GetGuildBankItemLink( tab_id, slot_id ) ) then
			return
		end

		if IsModifiedClick( "SPLITSTACK" ) then
			if not frame.locked then
				OpenStackSplitFrame( frame.count, frame, "BOTTOMLEFT", "TOPLEFT")
			end
			return
		end

		local infoType, info1, info2 = GetCursorInfo( )
		if infoType == "money" then
			DepositGuildBankMoney( info1 )
			ClearCursor( )
		elseif infoType == "guildbankmoney" then
			DropCursorMoney( )
			ClearCursor( )
		else
			if arg1 == "RightButton" then
				AutoStoreGuildBankItem( tab_id, slot_id )
			else
				PickupGuildBankItem( tab_id, slot_id )
			end
		end

	end

end

