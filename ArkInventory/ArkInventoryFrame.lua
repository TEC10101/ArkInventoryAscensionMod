function ArkInventory.Frame_Main_DrawStatus( loc_id, level )

	if level == nil then
		level = ArkInventory.Const.Window.Draw.None
	end

	if ArkInventory.Global.Location[loc_id] and ArkInventory.Global.Location[loc_id].canView then
		if level < ArkInventory.Global.Location[loc_id].drawState then
			ArkInventory.Global.Location[loc_id].drawState = level
		end
	end
end

function ArkInventory.Frame_Main_Generate( location, drawstatus )

	for loc_id in pairs( ArkInventory.Global.Location ) do

		if not location or loc_id == location then
			ArkInventory.Frame_Main_DrawStatus( loc_id, drawstatus )
			ArkInventory.Frame_Main_DrawLocation( loc_id )
		end

	end

end

function ArkInventory.Frame_Main_DrawLocation( loc_id )
	local frame = ArkInventory.Frame_Main_Get( loc_id )
	ArkInventory.Frame_Main_Draw( frame )
end



function ArkInventory.PutItemInBank( )

	if CursorHasItem( ) then

		for x = 1, GetContainerNumSlots( BANK_CONTAINER ) do
			h = GetContainerItemLink( BANK_CONTAINER, x )
			if not h then
				if not PickupContainerItem( BANK_CONTAINER, x ) then
					ClearCursor( )
				end
				return
			end
		end

		UIErrorsFrame:AddMessage( ERR_BAG_FULL, 1.0, 0.1, 0.1, 1.0 )
		ClearCursor( )

	end

end

function ArkInventory.PutItemInGuildBank( tab_id )

	if CursorHasItem( ) then

		local loc_id = ArkInventory.Const.Location.Vault
		local _, _, _, canDeposit = GetGuildBankTabInfo( tab_id )

		if canDeposit then

			ArkInventory.OutputDebug( "PutItemInGuildBank( ", tab_id, " )" )

			local ctab = GetCurrentGuildBankTab( )

			if tab_id ~= ctab then
				SetCurrentGuildBankTab( tab_id )
				ArkInventory.QueryVault( tab_id )
			end

			for x = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
				h = GetGuildBankItemLink( tab_id, x )
				if not h then
					if not PickupGuildBankItem( tab_id, x ) then --AutoStoreGuildBankItem
						ClearCursor( )
					end
					return
				end
			end

			UIErrorsFrame:AddMessage( ERR_BAG_FULL, 1.0, 0.1, 0.1, 1.0 )
			ClearCursor( )

		end

	end

end

function ArkInventory.SetItemButtonStock( frame, count, status )

	if not frame then
		return
	end

	local obj = _G[frame:GetName( ) .. "Stock"]
	if not obj then
		return
	end

	obj:SetText( "" )
	obj.numInStock = 0

	local loc_id = frame.ARK_Data.loc_id

	if ArkInventory.LocationOptionGet( loc_id, { "changer", "freespace", "show" } ) then

		if status then

			if status == ArkInventory.Const.Bag.Status.Purchase then
				obj:SetText( ArkInventory.Localise["STATUS_PURCHASE"] )
			elseif status == ArkInventory.Const.Bag.Status.Unknown then
				obj:SetText( ArkInventory.Localise["STATUS_NO_DATA"] )
			elseif status == ArkInventory.Const.Bag.Status.NoAccess then
				obj:SetText( ArkInventory.Localise["VAULT_TAB_ACCESS_NONE"] )
			end

		else

			if count > 0 then
				obj:SetText( count )
				obj.numInStock = count
			else
				obj:SetText( ArkInventory.Localise["STATUS_FULL"] )
			end

		end

		local colour = ArkInventory.LocationOptionGet( loc_id, { "changer", "freespace", "colour" } )
		obj:SetTextColor( colour.r, colour.g, colour.b )

		obj:Show( )

	else

		obj:Hide( )

	end

end

function ArkInventory.ValidFrame( frame, visible, db )

	if frame and frame.ARK_Data and frame.ARK_Data.loc_id then

		local res1 = true
		if db then
			local i = ArkInventory.Frame_Item_GetDB( frame )
			if i == nil then
				res1 = false
			end
		end

		local res2 = true
		if visible and not frame:IsVisible( ) then
			res2 = false
		end

		return res1 and res2

	end

	return false

end

function ArkInventory.Frame_Main_Get( loc_id )

	local framename = ArkInventory.Const.Frame.Main.Name .. loc_id
	local frame = _G[framename]
	assert( frame, "xml element '" .. framename .. "' could not be found" )

	return frame

end

function ArkInventory.Frame_Main_Scale( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id

	local old_scale = frame:GetScale( )
	local new_scale = ArkInventory.LocationOptionGet( loc_id, { "window", "scale" } )
	local rescale

	if old_scale ~= new_scale then
		--rescale = old_scale / new_scale
		frame:SetScale( new_scale )
	end

	ArkInventory.Frame_Main_Anchor_Set( loc_id, rescale )

end

function ArkInventory.Frame_Main_Scale_All( )
	for loc_id in ipairs( ArkInventory.Global.Location ) do
		frame = ArkInventory.Frame_Main_Get( loc_id )
		ArkInventory.Frame_Main_Scale( frame )
	end
end

function ArkInventory.Frame_Main_Offline( frame )

	local loc_id = frame.ARK_Data.loc_id

	--ArkInventory.Output( "loc_playerid=[", ArkInventory.Global.Location[loc_id].player_id, "] player_id=[", ArkInventory.Global.Me.info.player_id, "] guild_id=[", ArkInventory.Global.Me.info.guild_id, "]" )

	local current_player_id = ArkInventory.Global.Location[loc_id].player_id
	local is_current_player = current_player_id == ArkInventory.Global.Me.info.player_id
		or current_player_id == ArkInventory.Global.Me.info.guild_id
		or current_player_id == ArkInventory.Global.Me.info.realmbank_id

	-- if we're actively at a personal/realm vault, force online and exit early
	-- to avoid any subsequent checks toggling it back to offline during early
	-- login initialisation
	if ArkInventory.Global.Mode.Vault then
		if loc_id == ArkInventory.Const.Location.PersonalBank and ArkInventory.Global.Mode.VaultContext == "personal" then
			ArkInventory.Global.Location[loc_id].isOffline = false
			return
		elseif loc_id == ArkInventory.Const.Location.RealmBank and ArkInventory.Global.Mode.VaultContext == "realm" then
			ArkInventory.Global.Location[loc_id].isOffline = false
			return
		end
	end

	if is_current_player then
	--if ArkInventory.Global.Location[loc_id].player_id == ArkInventory.Global.Me.info.player_id or ArkInventory.Global.Location[loc_id].player_id == ArkInventory.Global.Me.info.guild_id then

		ArkInventory.Global.Location[loc_id].isOffline = false

		if loc_id == ArkInventory.Const.Location.Bank and ArkInventory.Global.Mode.Bank == false then
			ArkInventory.Global.Location[loc_id].isOffline = true
		end

		if ( loc_id == ArkInventory.Const.Location.Vault or loc_id == ArkInventory.Const.Location.PersonalBank or loc_id == ArkInventory.Const.Location.RealmBank ) and ArkInventory.Global.Mode.Vault == false then
			ArkInventory.Global.Location[loc_id].isOffline = true
		end

		if loc_id == ArkInventory.Const.Location.Mail and ArkInventory.Global.Mode.Mail == false then
			ArkInventory.Global.Location[loc_id].isOffline = true
		end

	else

		ArkInventory.Global.Location[loc_id].isOffline = true

	end

end

function ArkInventory.Frame_Main_Anchor_Set( loc_id, rescale )

	local frame = ArkInventory.Frame_Main_Get( loc_id )

	-- If the window is being dragged, do not re-anchor it. The window is
	-- frequently refreshed (Frame_Main_Update -> Frame_Main_Scale -> Anchor_Set),
	-- and re-anchoring while the frame is moving causes snap-back / cursor offset
	-- issues and can be very expensive when other UI panels are open.
	if frame and frame.ARK_Data and frame.ARK_Data.dragging then
		if ArkInventory.Trace and ArkInventory.Trace.enabled and ArkInventory.Trace.active then
			ArkInventory.Trace.anchorSuppressed = (ArkInventory.Trace.anchorSuppressed or 0) + 1
			if ArkInventory.Trace.anchorSuppressed == 1 then
				ArkInventory.TraceEvent( "ANCHOR_SET_SUPPRESSED", { loc_id = loc_id } )
			end
		end
		return
	end
	if frame and frame.IsMoving and frame:IsMoving( ) then
		return
	end
	local anchor = ArkInventory.LocationOptionGet( loc_id, { "anchor", loc_id, "point" } )

	local t = ArkInventory.LocationOptionGet( loc_id, { "anchor", loc_id, "t" } ) * ( rescale or 1 )
	local b = ArkInventory.LocationOptionGet( loc_id, { "anchor", loc_id, "b" } ) * ( rescale or 1 )
	local l = ArkInventory.LocationOptionGet( loc_id, { "anchor", loc_id, "l" } ) * ( rescale or 1 )
	local r = ArkInventory.LocationOptionGet( loc_id, { "anchor", loc_id, "r" } ) * ( rescale or 1 )

	local f1 = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Title.Name]
	local f2 = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Search.Name]
	local f3 = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Container.Name]
	local f4 = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Changer.Name]
	local f5 = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Status.Name]

	frame:ClearAllPoints( )
	f1:ClearAllPoints( )
	f2:ClearAllPoints( )
	f3:ClearAllPoints( )
	f4:ClearAllPoints( )
	f5:ClearAllPoints( )

	if anchor == ArkInventory.Const.Anchor.BottomRight then

		frame:SetPoint( "BOTTOMRIGHT", nil, "BOTTOMLEFT", r, b )

		f5:SetPoint( "BOTTOMRIGHT", frame )
		f5:SetPoint( "LEFT", frame )

		f4:SetPoint( "BOTTOMRIGHT", f5, "TOPRIGHT", 0, -3 )
		f4:SetPoint( "LEFT", frame )

		f3:SetPoint( "BOTTOMRIGHT", f4, "TOPRIGHT", 0, -3 )
		f3:SetPoint( "LEFT", frame )

		f2:SetPoint( "BOTTOMRIGHT", f3, "TOPRIGHT", 0, -4 )
		f2:SetPoint( "LEFT", frame )

		f1:SetPoint( "BOTTOMRIGHT", f2, "TOPRIGHT", 0, -3 )
		f1:SetPoint( "LEFT", frame )

	elseif anchor == ArkInventory.Const.Anchor.BottomLeft then

		frame:SetPoint( "BOTTOMLEFT", nil, "BOTTOMLEFT", l, b )

		f5:SetPoint( "BOTTOMLEFT", frame )
		f5:SetPoint( "RIGHT", frame )

		f4:SetPoint( "BOTTOMLEFT", f5, "TOPLEFT", 0, -3 )
		f4:SetPoint( "RIGHT", frame )

		f3:SetPoint( "BOTTOMLEFT", f4, "TOPLEFT", 0, -3 )
		f3:SetPoint( "RIGHT", frame )

		f2:SetPoint( "BOTTOMLEFT", f3, "TOPLEFT", 0, -4 )
		f2:SetPoint( "RIGHT", frame )

		f1:SetPoint( "BOTTOMLEFT", f2, "TOPLEFT", 0, -3 )
		f1:SetPoint( "RIGHT", frame )

	elseif anchor == ArkInventory.Const.Anchor.TopLeft then

		frame:SetPoint( "TOPLEFT", nil, "BOTTOMLEFT", l, t )

		f1:SetPoint( "TOPLEFT", frame )
		f1:SetPoint( "RIGHT", frame )

		f2:SetPoint( "TOPLEFT", f1, "BOTTOMLEFT", 0, 3 )
		f2:SetPoint( "RIGHT", frame )

		f3:SetPoint( "TOPLEFT", f2, "BOTTOMLEFT", 0, 4 )
		f3:SetPoint( "RIGHT", frame )

		f4:SetPoint( "TOPLEFT", f3, "BOTTOMLEFT", 0, 3 )
		f4:SetPoint( "RIGHT", frame )

		f5:SetPoint( "TOPLEFT", f4, "BOTTOMLEFT", 0, 3 )
		f5:SetPoint( "RIGHT", frame )

	else -- anchor == ArkInventory.Const.Anchor.TopRight then

		frame:SetPoint( "TOPRIGHT", nil, "BOTTOMLEFT", r, t )

		f1:SetPoint( "TOPRIGHT", frame )
		f1:SetPoint( "LEFT", frame )

		f2:SetPoint( "TOPRIGHT", f1, "BOTTOMRIGHT", 0, 3 )
		f2:SetPoint( "LEFT", frame )

		f3:SetPoint( "TOPRIGHT", f2, "BOTTOMRIGHT", 0, 4 )
		f3:SetPoint( "LEFT", frame )

		f4:SetPoint( "TOPRIGHT", f3, "BOTTOMRIGHT", 0, 3 )
		f4:SetPoint( "LEFT", frame )

		f5:SetPoint( "TOPRIGHT", f4, "BOTTOMRIGHT", 0, 3 )
		f5:SetPoint( "LEFT", frame )

	end

	-- Dragging is handled via OnMouseDown/OnMouseUp (see Frame_Main_OnLoad) to
	-- avoid Blizzard's drag threshold and to prevent double-triggering.
	-- The locked setting is enforced inside Frame_Main_OnDragStart.

	if rescale then
		ArkInventory.Frame_Main_Anchor_Save( frame )
	end

end

function ArkInventory.Frame_Main_OnDragStart( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	if ArkInventory.LocationOptionGet( loc_id, { "anchor", loc_id, "locked" } ) then
		return
	end

	frame.ARK_Data.dragging = true

	-- Mitigation: when the auction UI is open, force Ark to a higher strata while dragging.
	-- This avoids some heavy/slow re-layering behavior where Ark starts below AH and then
	-- jumps above after a multi-second stall.
	local ah = ArkInventory.TraceGetAuctionFrame and ArkInventory.TraceGetAuctionFrame( ) or nil
	if ah and ah.IsShown and ah:IsShown( ) and frame.SetFrameStrata and frame.GetFrameStrata then
		if not frame.ARK_Data.dragOrigStrata then
			frame.ARK_Data.dragOrigStrata = frame:GetFrameStrata( )
			frame.ARK_Data.dragOrigTop = (frame.IsToplevel and frame:IsToplevel( )) or nil
		end
		pcall( function( ) frame:SetFrameStrata( "DIALOG" ) end )
		if frame.SetToplevel then
			pcall( function( ) frame:SetToplevel( true ) end )
		end
		if ArkInventory.Trace and ArkInventory.Trace.enabled then
			ArkInventory.TraceEvent( "DRAG_RAISE", { from = frame.ARK_Data.dragOrigStrata, to = "DIALOG" } )
		end
	end

	if ArkInventory.Trace and ArkInventory.Trace.enabled then
		ArkInventory.TraceDragStart( frame )
	end

	-- Show a temporary mouse-capture shield while dragging.
	-- This prevents rapid OnEnter/OnLeave churn on underlying UI (Auction House)
	-- and on our own item buttons while the window moves.
	if frame.ARK_Data.dragShield then
		frame.ARK_Data.dragShield:Show( )
	end

	-- Avoid excessive tooltip churn while moving the window.
	if GameTooltip and GameTooltip:IsShown( ) then
		GameTooltip:Hide( )
	end

	if frame.StartMoving and ( not ( frame.IsMoving and frame:IsMoving( ) ) ) then
		frame:StartMoving( )
	end

end

function ArkInventory.Frame_Main_OnDragStop( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	frame.ARK_Data.dragging = nil

	if ArkInventory.Trace and ArkInventory.Trace.enabled then
		ArkInventory.TraceDragStop( frame )
	end

	if frame.ARK_Data.dragShield then
		frame.ARK_Data.dragShield:Hide( )
	end

	if frame.StopMovingOrSizing then
		frame:StopMovingOrSizing( )
	end

	-- Restore temporary strata changes made during drag.
	if frame.ARK_Data.dragOrigStrata and frame.SetFrameStrata then
		pcall( function( ) frame:SetFrameStrata( frame.ARK_Data.dragOrigStrata ) end )
		frame.ARK_Data.dragOrigStrata = nil
	end
	if frame.ARK_Data.dragOrigTop ~= nil and frame.SetToplevel then
		pcall( function( ) frame:SetToplevel( frame.ARK_Data.dragOrigTop and true or false ) end )
		frame.ARK_Data.dragOrigTop = nil
	end

	ArkInventory.Frame_Main_Anchor_Save( frame )

	-- Re-apply anchor rules so the frame doesn't remain with temporary drag points.
	local loc_id = frame.ARK_Data.loc_id
	ArkInventory.Frame_Main_Anchor_Set( loc_id )

end

function ArkInventory.Frame_Main_Paint( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id

	for _, z in pairs( { frame:GetChildren( ) } ) do

		local framename = z:GetName( )
		if framename then -- only process objects with a name (other addons can add frames without names, we don't want to deal with them)

			-- background
			local obj = _G[framename .. "Background"]
			if obj then
				local style = ArkInventory.LocationOptionGet( loc_id, { "window", "background", "style" } ) or ArkInventory.Const.Texture.BackgroundDefault
				if style == ArkInventory.Const.Texture.BackgroundDefault then
					local colour = ArkInventory.LocationOptionGet( loc_id, { "window", "background", "colour" } )
					obj:SetTexture( colour.r, colour.g, colour.b, colour.a )
				else
					local file = ArkInventory.Lib.SharedMedia:Fetch( ArkInventory.Lib.SharedMedia.MediaType.BACKGROUND, style )
					obj:SetTexture( file )
				end
			end

			-- border
			local obj = _G[framename .. "ArkBorder"]
			if obj then

				if ArkInventory.LocationOptionGet( loc_id, { "window", "border", "style" } ) ~= ArkInventory.Const.Texture.BorderNone then

					local style = ArkInventory.LocationOptionGet( loc_id, { "window", "border", "style" } ) or ArkInventory.Const.Texture.BorderDefault
					local file = ArkInventory.Lib.SharedMedia:Fetch( ArkInventory.Lib.SharedMedia.MediaType.BORDER, style )
					local size = ArkInventory.LocationOptionGet( loc_id, { "window", "border", "size" } ) or ArkInventory.Const.Texture.Border[ArkInventory.Const.Texture.BorderDefault].size
					local offset = ArkInventory.LocationOptionGet( loc_id, { "window", "border", "offset" } ) or ArkInventory.Const.Texture.Border[ArkInventory.Const.Texture.BorderDefault].offset
					local scale = ArkInventory.LocationOptionGet( loc_id, { "window", "border", "scale" } ) or 1
					local colour = ArkInventory.LocationOptionGet( loc_id, { "window", "border", "colour" } )
					ArkInventory.Frame_Border_Paint( obj, false, file, size, offset, scale, colour.r, colour.g, colour.b, 1 )

					obj:Show( )

				else

					obj:Hide( )

				end

			end

		end

	end

end

function ArkInventory.Frame_Main_Paint_All( )

	for loc_id, loc_data in ipairs( ArkInventory.Global.Location ) do
		frame = ArkInventory.Frame_Main_Get( loc_id )
		ArkInventory.Frame_Main_Paint( frame )
	end

end

function ArkInventory.Frame_Border_Paint( border, slot, file, size, offset, scale, r, g, b, a )

	local otheroffset = 3
	if slot then otheroffset = 0 end

	local parentname = border:GetParent( ):GetName( )

	local offset = offset * scale

	border:SetBackdrop( { edgeFile = file, edgeSize = size * scale } )
	border:SetBackdropBorderColor( r or 0, g or 0, b or 0, a or 1 )

	border:ClearAllPoints( )
	border:SetPoint( "TOPLEFT", parentname, 0 - offset + otheroffset, offset - otheroffset )
	border:SetPoint( "BOTTOMRIGHT", parentname, offset - otheroffset, 0 - offset + otheroffset )

end

function ArkInventory.Frame_Main_Update( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id

	ArkInventory.Frame_Status_Update( frame )

	-- set the size of the window
	local h = 0
	h = h + _G[frame:GetName( ) .. ArkInventory.Const.Frame.Title.Name]:GetHeight( )
	h = h + _G[frame:GetName( ) .. ArkInventory.Const.Frame.Container.Name]:GetHeight( )
	h = h + _G[frame:GetName( ) .. ArkInventory.Const.Frame.Changer.Name]:GetHeight( )
	h = h + _G[frame:GetName( ) .. ArkInventory.Const.Frame.Status.Name]:GetHeight( )
	frame:SetHeight( h )

	frame:SetWidth( ArkInventory.Global.Location[loc_id].Layout.container.width )

	ArkInventory.Frame_Main_Scale( frame )

end

function ArkInventory.Frame_Main_Draw( frame )

	if not frame:IsVisible( ) then
		return
	end

	local loc_id = frame.ARK_Data.loc_id

	--ArkInventory.Output( "Frame_Main_Draw( ", frame:GetName( ), " ) drawstate[", ArkInventory.Global.Location[loc_id].drawState, "], framelevel[", frame:GetFrameLevel( ), "]" )

	if not ArkInventory.Global.Location[loc_id].canView then
		-- not a controllable window (for scanning only)
		-- shouldnt ever get here, but just in case
		frame:Hide( )
		return
	end

	-- is the window online or offline?
	ArkInventory.Frame_Main_Offline( frame )

	-- set the window title
	local obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Title.Name .. "Who"]

	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )

	-- ensure guild vault metadata always uses the guild owner when online
	if loc_id == ArkInventory.Const.Location.Vault and ArkInventory.Global.Mode.Vault and ArkInventory.Global.Mode.VaultContext == "guild" then
		local guild_id = ArkInventory.Global.Me and ArkInventory.Global.Me.info and ArkInventory.Global.Me.info.guild_id
		if guild_id then
			local gcp = ArkInventory.PlayerInfoGet( guild_id )
			if gcp then
				cp = gcp
			end
		end
	end

	local t = ""
	if ArkInventory.LocationOptionGet( loc_id, { "title", "size" } ) == ArkInventory.Const.Window.Title.SizeThin then
		t = ArkInventory.DisplayName5( cp.info )
	else
		t = ArkInventory.DisplayName1( cp.info )
	end

	if ArkInventory.Global.Location[loc_id].isOffline then
		obj:SetTextColor( 1, 0, 0 )
		t = string.format( "%s [%s]", t, ArkInventory.Localise["STATUS_OFFLINE"] )
	else
		obj:SetTextColor( 0, 1, 0 )
	end

	obj:SetText( t )





	-- changer frame
	local obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Changer.Name]

	-- shrink and hide the changer frame if it can't be used
	if not ArkInventory.Global.Location[loc_id].hasChanger or ArkInventory.LocationOptionGet( loc_id, { "changer", "hide" } ) then

		obj:SetHeight( 3 )
		obj:Hide( )

	else

		obj:SetHeight( ArkInventory.Const.Frame.Changer.Height )
		obj:Show( )

		ArkInventory.Frame_Changer_Update( loc_id )

	end



	if loc_id == ArkInventory.Const.Location.Vault then

		-- vault tab changed
		if ArkInventory.Global.Location[loc_id].current_tab ~= GetCurrentGuildBankTab( ) then
			ArkInventory.Global.Location[loc_id].current_tab = GetCurrentGuildBankTab( )
			ArkInventory.Frame_Main_DrawStatus( loc_id, ArkInventory.Const.Window.Draw.Recalculate )
		end

		-- force vault back to item display when offline
		if ArkInventory.Global.Location[loc_id].isOffline then
			GuildBankFrame.mode = "bank"
		end

		obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Container.Name]
		obj:Hide( )

		obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Info.Name]
		obj:Hide( )

		obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Log.Name]
		obj:Hide( )


		if GuildBankFrame.mode == "log" or GuildBankFrame.mode == "moneylog" then
			obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Log.Name]
			obj:Show( )
		elseif GuildBankFrame.mode == "tabinfo" then
			obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Info.Name]
			obj:Show( )
		elseif GuildBankFrame.mode == "bank" then
			obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Container.Name]
			obj:Show( )
		end

	end


	-- bag data has changed
	if ArkInventory.Global.Location[loc_id].changed then

		ArkInventory.Frame_Main_DrawStatus( loc_id, ArkInventory.Const.Window.Draw.Refresh )

		ArkInventory.ItemCategoryClear( nil, loc_id )

		-- instant sort
		if ArkInventory.LocationOptionGet( loc_id, { "sort", "instant" } ) then
			ArkInventory.Frame_Main_DrawStatus( loc_id, ArkInventory.Const.Window.Draw.Recalculate )
		end

		ArkInventory.Global.Location[loc_id].changed = false

	end


	-- rebuild category and sort values
	if ArkInventory.Global.Location[loc_id].resort then

		ArkInventory.ItemSortKeyClear( loc_id )

		ArkInventory.Global.Location[loc_id].resort = false

		ArkInventory.Frame_Main_DrawStatus( loc_id, ArkInventory.Const.Window.Draw.Refresh )

	end


	-- do we still need to draw the window?
	if ArkInventory.Global.Location[loc_id].drawState == ArkInventory.Const.Window.Draw.None then
		return
	end

	if ArkInventory.Global.Location[loc_id].drawState <= ArkInventory.Const.Window.Draw.Init then
		ArkInventory.Frame_Main_Paint( frame )
	end

	if ArkInventory.Global.Location[loc_id].drawState <= ArkInventory.Const.Window.Draw.Refresh then

		-- hide the title window if it's not needed
		local obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Title.Name]
		if ArkInventory.LocationOptionGet( loc_id, { "title", "hide" } ) then

			obj:Hide( )
			obj:SetHeight( 3 )

		else

			if ArkInventory.LocationOptionGet( loc_id, { "title", "size" } ) == ArkInventory.Const.Window.Title.SizeThin then

				-- thin size

				local z = _G[obj:GetName( ) .. "Location0"]
				z:SetWidth( 20 )
				z:SetHeight( 20 )

				z = _G[obj:GetName( ) .. "ActionButton21"]
				z:ClearAllPoints( )
				z:SetPoint( "RIGHT", _G[obj:GetName( ) .. "ActionButton14"], "LEFT", -3, 0 )

				obj:SetHeight( ArkInventory.Const.Frame.Title.Height2 )
				obj:Show( )

			else

				-- normal size

				local z = _G[obj:GetName( ) .. "Location0"]
				z:SetWidth( 42 )
				z:SetHeight( 42 )

				z = _G[obj:GetName( ) .. "ActionButton21"]
				z:ClearAllPoints( )
				z:SetPoint( "TOP", _G[obj:GetName( ) .. "ActionButton11"], "BOTTOM", 0, -2 )

				obj:SetHeight( ArkInventory.Const.Frame.Title.Height )
				obj:Show( )

			end

		end

		-- hide the search window if it's not needed
		local obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Search.Name]
		if ArkInventory.LocationOptionGet( loc_id, { "search", "hide" } ) then

			obj:Hide( )
			obj:SetHeight( 3 )

			obj = _G[obj:GetName( ) .. "Filter"]:SetText( "" )

		else

			obj:SetHeight( ArkInventory.Const.Frame.Search.Height )
			obj:Show( )

		end

	end

	obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Container.Name]
	ArkInventory.Frame_Container_Draw( obj )

	if ArkInventory.Global.Location[loc_id].drawState <= ArkInventory.Const.Window.Draw.Refresh then
		ArkInventory.Frame_Main_Update( frame )
	end

	if ArkInventory.Global.Location[loc_id].drawState <= ArkInventory.Const.Window.Draw.Init then
		ArkInventory.MediaSetFontFrame( frame )
	end

	ArkInventory.Global.Location[loc_id].drawState = ArkInventory.Const.Window.Draw.None


	-- bug fix for framelevel issue
	if ArkInventory.db.global.option.bugfix.framelevel.enable and frame:GetFrameLevel( ) > 126 then

		local level_old = frame:GetFrameLevel( )
		local level_new = 2

		ArkInventory.ResetFrameLevel( frame, level_new )

		if ArkInventory.db.global.option.bugfix.framelevel.alert == 1 then
			-- short
			--ArkInventory.OutputWarning( ArkInventory.Localise["MISC_ALERT"], FONT_COLOR_CODE_CLOSE, " ", ArkInventory.Localise["MISC_ALERT_FRAMELEVEL_1"] )
		elseif ArkInventory.db.global.option.bugfix.framelevel.alert == 2 then
			-- long
			--ArkInventory.OutputWarning( ArkInventory.Localise["MISC_ALERT"], FONT_COLOR_CODE_CLOSE, " ", ArkInventory.Localise["MISC_ALERT_FRAMELEVEL_1"], "  ", string.format( ArkInventory.Localise["MISC_ALERT_FRAMELEVEL_2"], ArkInventory.Global.Location[loc_id].Name, level_old, level_new ) )
		else
			-- disabled
		end

	end

end

function ArkInventory.ResetFrameLevel( frame, level )

	if type( frame ) == "string" then
		frame = _G[frame]
	end

	if frame == nil then
		return
	end

	if frame:GetFrameLevel( ) ~= level then
		--ArkInventory.Output( "ResetFrameLevel( ", frame:GetName( ), " ) ", frame:GetFrameLevel( ), " -> ", level )
		frame:SetFrameLevel( level )
	end

	for _, z in pairs( { frame:GetChildren( ) } ) do
		ArkInventory.ResetFrameLevel( z, level + 1 )
	end

end

-- Trace hook: attribute internal framelevel resets.
if hooksecurefunc and not ArkInventory.TraceResetHooked then
	ArkInventory.TraceResetHooked = true
	hooksecurefunc( ArkInventory, "ResetFrameLevel", function( _, f, lvl )
		if not (ArkInventory.Trace and ArkInventory.Trace.enabled and ArkInventory.Trace.active) then
			return
		end
		if not f then
			return
		end
		if ArkInventory_TraceIsWatchedFrame and not ArkInventory_TraceIsWatchedFrame( f ) then
			return
		end
		ArkInventory.TraceEvent( "HOOK_RESETFRAMELEVEL", {
			frame = ArkInventory_TraceSafeName and ArkInventory_TraceSafeName( f ) or (f.GetName and f:GetName( ) or tostring( f )),
			to = lvl,
			now = f.GetFrameLevel and f:GetFrameLevel( ) or -1,
			stack = ArkInventory_TraceMaybeStack and ArkInventory_TraceMaybeStack( ) or nil,
		} )
	end )
end

function ArkInventory.Frame_Main_Toggle( loc_id )

	local frame = ArkInventory.Frame_Main_Get( loc_id )

	if frame then
		if frame:IsVisible( ) then
			ArkInventory.Frame_Main_Hide( loc_id )
		else
			ArkInventory.Frame_Main_Show( loc_id )
		end
	end

end

function ArkInventory.Frame_Main_Show( loc_id, player_id )

	assert( loc_id, "invalid location: nil" )

	local frame = ArkInventory.Frame_Main_Get( loc_id )

	if player_id == nil then
		if loc_id == ArkInventory.Const.Location.Vault then
			if ArkInventory.Global.Mode.VaultContext == "personal" then
				player_id = ArkInventory.Global.Me.info.player_id
			else
				player_id = ArkInventory.Global.Me.info.guild_id
			end
		elseif loc_id == ArkInventory.Const.Location.RealmBank then
			player_id = ArkInventory.Global.Me.info.realmbank_id
		elseif loc_id == ArkInventory.Const.Location.PersonalBank then
			player_id = ArkInventory.Global.Me.info.player_id
		else
			player_id = ArkInventory.Global.Me.info.player_id
		end
	end

	if player_id ~= ArkInventory.Global.Location[loc_id].player_id then
		-- showing a different player than whats already being displayed so init
		ArkInventory.Frame_Main_DrawStatus( loc_id, ArkInventory.Const.Window.Draw.Init )
	else
		-- same player, leave as is, display code will sort it out, unless user wants it to sort
		if ArkInventory.LocationOptionGet( loc_id, { "sort", "open" } ) then
			ArkInventory.Frame_Main_DrawStatus( loc_id, ArkInventory.Const.Window.Draw.Resort )
		end


	-- ensure online state for first-open personal/realm vault sessions before
	-- showing to avoid a brief/offline title caused by early initialisation
	if ArkInventory.Global.Mode.Vault then
		if loc_id == ArkInventory.Const.Location.PersonalBank and ArkInventory.Global.Mode.VaultContext == "personal" then
			ArkInventory.Global.Location[loc_id].isOffline = false
		elseif loc_id == ArkInventory.Const.Location.RealmBank and ArkInventory.Global.Mode.VaultContext == "realm" then
			ArkInventory.Global.Location[loc_id].isOffline = false
		end
	end
	end

	ArkInventory.LocationSetValue( loc_id, "player_id", player_id )

	frame:Show( )
	ArkInventory.Frame_Main_Generate( loc_id )

end

function ArkInventory.Frame_Main_OnShow( frame )

	local loc_id = frame.ARK_Data.loc_id

	if loc_id == ArkInventory.Const.Location.Key then
		PlaySound( "KeyRingOpen" )
	elseif loc_id == ArkInventory.Const.Location.Bank then
		PlaySound( "igCharacterInfoOpen" )
	elseif loc_id == ArkInventory.Const.Location.Bag then
		PlaySound( "igBackPackOpen" )
	if loc_id == ArkInventory.Const.Location.Vault then
		-- vault location (4) is always stored under the guild owner,
		-- never under the character directly. Personal banks use
		-- their own location id (PersonalBank) instead.
		local guild_id = cp.info.guild_id
		if guild_id then
			cp = ArkInventory.PlayerInfoGet( guild_id )
			if cp == nil then
				ArkInventory.Output( "invalid guild id (", guild_id, ") at location (", loc_id, ")" )
				assert( false, "code error" )
			end
		end
	elseif loc_id == ArkInventory.Const.Location.PersonalBank then
		-- personal bank is stored under the character record
		local owner_id = cp.info.player_id
		cp = ArkInventory.PlayerInfoGet( owner_id ) or cp
	elseif loc_id == ArkInventory.Const.Location.RealmBank then
		-- realm bank is stored under the realm-wide pseudo-player
		local realm_id = cp.info.realmbank_id
		if realm_id then
			cp = ArkInventory.PlayerInfoGet( realm_id ) or cp
		end
	end
	end

end

function ArkInventory.Frame_Main_Search( frame )

	if not frame then
		frame = this:GetParent( ):GetParent( ):GetName( )
	end

	local loc_id = _G[frame].ARK_Data.loc_id
	local search = frame .. "Search"
	local filter = _G[search .. "Filter"]:GetText( )

	local txt = strtrim( filter or "" )
	ArkInventory.Global.Location[loc_id].filter = txt
	ArkInventory.Global.Location[loc_id].filter_rule_expr = nil
	ArkInventory.Global.Location[loc_id].filter_rule_func = nil

	if ArkInventory.SearchIsRuleMode and ArkInventory.SearchIsRuleMode( ) and txt ~= "" and ArkInventory.SearchRuleGetExpression then
		local expr = ArkInventory.SearchRuleGetExpression( txt )
		if expr then
			local func, em = loadstring( string.format( "return( %s )", expr ) )
			if func then
				ArkInventory.Global.Location[loc_id].filter_rule_expr = expr
				ArkInventory.Global.Location[loc_id].filter_rule_func = func
			else
				if ArkInventory.OutputError then
					ArkInventory.OutputError( string.format( "search rule compile error: %s", tostring( em ) ) )
				end
			end
		end
	end
	ArkInventory.Frame_Main_Generate( loc_id, ArkInventory.Const.Window.Draw.Refresh )

end

function ArkInventory.Frame_Main_Hide( w )

	for loc_id in ipairs( ArkInventory.Global.Location ) do
		if not w or w == loc_id then
			local frame = ArkInventory.Frame_Main_Get( loc_id )
			frame:Hide( )
		end
	end

end

function ArkInventory.Frame_Main_OnHide( frame )

	ArkInventory.Lib.DewDrop:Close( )

	local loc_id = frame.ARK_Data.loc_id

	if loc_id == ArkInventory.Const.Location.Key then
		PlaySound( "KeyRingClose" )
	elseif loc_id == ArkInventory.Const.Location.Bank then

		PlaySound( "igCharacterInfoClose" )

		if ArkInventory.Global.Mode.Bank and ArkInventory.LocationIsControlled( ArkInventory.Const.Location.Bank ) then
			-- close blizzards bank frame if we're hiding blizzard frames, we're at the bank, and the bank window was closed
			CloseBankFrame( )
		end

	elseif loc_id == ArkInventory.Const.Location.Bag then
		PlaySound( "igBackPackClose" )
	elseif loc_id == ArkInventory.Const.Location.Vault or loc_id == ArkInventory.Const.Location.PersonalBank or loc_id == ArkInventory.Const.Location.RealmBank then

		PlaySound( "GuildVaultClose" )

		if ArkInventory.Global.Mode.Vault and ArkInventory.LocationIsControlled( loc_id ) then

			-- close blizzards vault/personal-bank frame if we're hiding blizzard frames,
			-- we're at the vault, and the vault window was closed

			GuildBankPopupFrame:Hide( )
			StaticPopup_Hide( "GUILDBANK_WITHDRAW" )
			StaticPopup_Hide( "GUILDBANK_DEPOSIT" )
			StaticPopup_Hide( "CONFIRM_BUY_GUILDBANK_TAB" )

			-- allow subsequent CLOSE event to be processed normally
			ArkInventory.Global.Mode.VaultSuppressLeave = false

			-- Restore UISpecialFrames ordering (we temporarily move Ark before
			-- GuildBankFrame for ESC-close correctness in personal/realm)
			ArkInventory.VaultUISpecialFramesOrderSet( loc_id, false )

			-- Close the underlying guild bank session. When closing via ESC, WoW can
			-- hide GuildBankFrame before hiding the Ark frame, which can make
			-- CloseGuildBankFrame a no-op on some clients if it checks IsShown.
			-- If that happens, the player remains "in" the bank session but the UI is
			-- hidden, preventing reopening. Ensure the frame is shown (but invisible)
			-- long enough for a clean CloseGuildBankFrame.
			local gb_temp_shown = false
			if GuildBankFrame and GuildBankFrame.IsShown and ( not GuildBankFrame:IsShown( ) ) then
				GuildBankFrame:SetAlpha( 0 )
				GuildBankFrame:EnableMouse( false )
				GuildBankFrame:Show( )
				gb_temp_shown = true
			end

			CloseGuildBankFrame( )

			if gb_temp_shown and GuildBankFrame and GuildBankFrame.IsShown and GuildBankFrame:IsShown( ) then
				GuildBankFrame:Hide( )
			end

			-- Restore Blizzard GuildBankFrame visuals/interactivity for the next open.
			if GuildBankFrame then
				GuildBankFrame:SetAlpha( 1 )
				ArkInventory.BlizzardFrameInteractiveSet( GuildBankFrame, true )
			end
			if GuildBankPopupFrame then
				GuildBankPopupFrame:SetAlpha( 1 )
				ArkInventory.BlizzardFrameInteractiveSet( GuildBankPopupFrame, true )
			end
			ArkInventory.Global.Mode.VaultBlizzardInteractionDisabled = false



		end

		-- safety: if a personal/realm frame was re-ordered for ESC correctness but we
		-- didn't enter the controlled branch above, still restore ordering
		ArkInventory.VaultUISpecialFramesOrderSet( loc_id, false )

		-- regardless of vault control setting, if we temporarily unhooked
		-- Blizzard events for personal/realm, restore them on hide so the
		-- next open fires correctly
		if ArkInventory.Global.Mode.VaultUIUnhooked then
			if UIParent and UIParent.RegisterEvent then
				UIParent:RegisterEvent( "GUILDBANKFRAME_OPENED" )
				if ArkInventory.OutputDebug then
					ArkInventory.OutputDebug( "Vault debug (OnHide): UIParent GUILDBANKFRAME_OPENED re-registered" )
				end
			end
			if GuildBankFrame and GuildBankFrame.RegisterEvent then
				GuildBankFrame:RegisterEvent( "GUILDBANKBAGSLOTS_CHANGED" )
				GuildBankFrame:RegisterEvent( "GUILDBANK_ITEM_LOCK_CHANGED" )
				GuildBankFrame:RegisterEvent( "GUILDBANK_UPDATE_TABS" )
				GuildBankFrame:RegisterEvent( "GUILDBANK_UPDATE_MONEY" )
				GuildBankFrame:RegisterEvent( "GUILDBANK_UPDATE_TEXT" )
				GuildBankFrame:RegisterEvent( "GUILD_ROSTER_UPDATE" )
				GuildBankFrame:RegisterEvent( "GUILDBANKLOG_UPDATE" )
				GuildBankFrame:RegisterEvent( "GUILDTABARD_UPDATE" )
				if ArkInventory.OutputDebug then
					ArkInventory.OutputDebug( "Vault debug (OnHide): GuildBankFrame events re-registered" )
				end
			end
			ArkInventory.Global.Mode.VaultUIUnhooked = false
		end

		-- always clear Ascension flags on hide to prevent stale context
		if GuildBankFrame then
			GuildBankFrame.IsPersonalBank = nil
			GuildBankFrame.IsRealmBank = nil
		end

	elseif loc_id == ArkInventory.Const.Location.Mail then
		PlaySound( "igSpellBookClose" )
	elseif loc_id == ArkInventory.Const.Location.Wearing then
		PlaySound( "igBackPackClose" )
	elseif loc_id == ArkInventory.Const.Location.Pet then
		PlaySound( "igSpellBookClose" )
	elseif loc_id == ArkInventory.Const.Location.Mount then
		PlaySound( "igSpellBookClose" )
	elseif loc_id == ArkInventory.Const.Location.Token then
		PlaySound( "igSpellBookClose" )
	end

	if ArkInventory.Global.Mode.Edit then
		-- if the edit mode is active then disable edit mode and taint so it's rebuilt when next opened
		ArkInventory.Global.Mode.Edit = false
		ArkInventory.Frame_Main_Generate( nil, ArkInventory.Const.Window.Draw.Recalculate )
	end

	-- ensure no hidden edit box keeps keyboard focus (which would swallow ESC)
	local focused = GetCurrentKeyFocus and GetCurrentKeyFocus( )
	if focused and focused.ClearFocus then
		focused:ClearFocus( )
	end

end

function ArkInventory.Frame_Main_OnLoad( frame )

	assert( frame, "frame is nil" )

	local framename = frame:GetName( )
	local loc_id = strmatch( framename, "^.-(%d+)" )
	assert( loc_id ~= nil, string.format( "xml element '%s' is not an %s frame", framename, ArkInventory.Const.Program.Name ) )

	frame.ARK_Data = {
		["loc_id"] = tonumber( loc_id ),
	}

	loc_id = tonumber( loc_id )

	local tex

	-- setup main icon
	local obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Title.Name .. "Location0"]
	if obj then

		tex = obj:GetNormalTexture( )
		tex:SetTexture( ArkInventory.Global.Location[loc_id].Texture )
		tex:SetTexCoord( 0.075, 0.925, 0.075, 0.925 )

		tex = obj:GetHighlightTexture( )
		tex:SetTexture( ArkInventory.Global.Location[loc_id].Texture )
		tex:SetTexCoord( 0.075, 0.925, 0.075, 0.925 )

		tex = obj:GetPushedTexture( )
		tex:SetTexture( ArkInventory.Global.Location[loc_id].Texture )
		tex:SetTexCoord( 0.075, 0.925, 0.075, 0.925 )

	end

	-- setup action buttons
	for k, v in pairs( ArkInventory.Const.Actions ) do

		local obj = _G[frame:GetName( ) .. ArkInventory.Const.Frame.Title.Name .. "ActionButton" .. k]

		if obj then

			tex = obj:GetNormalTexture( )
			tex:SetTexture( v.Texture )
			tex:SetTexCoord( 0.075, 0.925, 0.075, 0.925 )

			tex = obj:GetPushedTexture( )
			tex:SetTexture( v.Texture )
			tex:SetTexCoord( 0.075, 0.925, 0.075, 0.925 )

			tex = obj:GetHighlightTexture( )
			tex:SetTexture( v.Texture )
			tex:SetTexCoord( 0.075, 0.925, 0.075, 0.925 )

			for s, f in pairs( v.Scripts ) do
				obj:SetScript( s, f )
			end

		end
	end

	tinsert( UISpecialFrames, framename )

  -- make the main frame movable and allow dragging by the title area
  frame:SetMovable( true )
  frame:SetClampedToScreen( true )

	-- Create a mouse-capture shield used only while dragging.
	-- (Avoids mouseover storms when overlapping other complex frames like AH.)
	if not frame.ARK_Data.dragShield then
		local shield = CreateFrame( "Frame", nil, frame )
		shield:EnableMouse( true )
		shield:SetAllPoints( frame )
		shield:SetFrameStrata( frame:GetFrameStrata( ) )
		shield:SetFrameLevel( frame:GetFrameLevel( ) + 100 )
		shield:Hide( )
		shield:SetScript( "OnMouseDown", function( self, button )
			if button == "LeftButton" then
				ArkInventory.Frame_Main_OnDragStart( frame )
			end
		end )
		shield:SetScript( "OnMouseUp", function( self, button )
			if button == "LeftButton" then
				ArkInventory.Frame_Main_OnDragStop( frame )
			end
		end )
		shield:SetScript( "OnDragStart", function( self ) ArkInventory.Frame_Main_OnDragStart( frame ) end )
		shield:SetScript( "OnDragStop", function( self ) ArkInventory.Frame_Main_OnDragStop( frame ) end )
		frame.ARK_Data.dragShield = shield
	end

  local title = _G[ frame:GetName() .. ArkInventory.Const.Frame.Title.Name ]
  if title then
      title:EnableMouse( true )
		-- Do not use RegisterForDrag / OnDragStart here. Those introduce a drag
		-- threshold and can double-trigger with our mouse handlers, causing the
		-- frame to jump away from the cursor.
		title:RegisterForDrag( )
		title:SetScript( "OnDragStart", nil )
		title:SetScript( "OnDragStop", nil )
		-- Use OnMouseDown to avoid Blizzard's drag threshold (deadzone).
		title:SetScript( "OnMouseDown", function( self, button )
			if button == "LeftButton" then
				ArkInventory.Frame_Main_OnDragStart( frame )
			end
		end )
		title:SetScript( "OnMouseUp", function( self, button )
			if button == "LeftButton" then
				ArkInventory.Frame_Main_OnDragStop( frame )
			end
		end )
  end

	-- Override XML drag scripts so we can guard against refresh/anchor churn while
	-- dragging (which otherwise causes snap-back and lag). Prefer mouse down/up to
	-- start moving immediately (no drag threshold).
	frame:RegisterForDrag( )
	frame:SetScript( "OnDragStart", nil )
	frame:SetScript( "OnDragStop", nil )
	frame:SetScript( "OnMouseDown", function( self, button )
		if button == "LeftButton" then
			ArkInventory.Frame_Main_OnDragStart( self )
		end
	end )
	frame:SetScript( "OnMouseUp", function( self, button )
		if button == "LeftButton" then
			ArkInventory.Frame_Main_OnDragStop( self )
		end
	end )

end

function ArkInventory.Frame_Main_Anchor_Save( frame )

	if ArkInventory.ValidFrame( frame, true ) == false then
		return
	end

	local loc_id = frame.ARK_Data.loc_id

	ArkInventory.LocationOptionSet( loc_id, { "anchor", loc_id, "t" }, frame:GetTop( ) )
	ArkInventory.LocationOptionSet( loc_id, { "anchor", loc_id, "b" }, frame:GetBottom( ) )
	ArkInventory.LocationOptionSet( loc_id, { "anchor", loc_id, "l" }, frame:GetLeft( ) )
	ArkInventory.LocationOptionSet( loc_id, { "anchor", loc_id, "r" }, frame:GetRight( ) )

end

function ArkInventory.Frame_Container_Calculate( frame )

	--ArkInventory.Output( "Frame_Container_Calculate( ", frame:GetName( ), " )" )

	local loc_id = frame.ARK_Data.loc_id

	ArkInventory.Table.Clean( ArkInventory.Global.Location[loc_id].Layout, nil, true )

	-- break the inventory up into it's respective bars
	ArkInventory.Frame_Container_CalculateBars( frame, ArkInventory.Global.Location[loc_id].Layout )

	-- calculate what the container should look like with those bars
	ArkInventory.Frame_Container_CalculateContainer( frame, ArkInventory.Global.Location[loc_id].Layout )

end

function ArkInventory.Frame_Container_CalculateBars( frame, Layout )

	-- loads the inventory into their respective bars

	--cp.location[loc_id].Layout

	local loc_id = frame.ARK_Data.loc_id
	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )
	local firstempty = true

	--ArkInventory.Output( GREEN_FONT_COLOR_CODE, "Frame_Container_CalculateBars( ", frame:GetName( ), " ) for [", cp.name, "] start" )

	Layout.bar = { }
	Layout.bar_count = 1

	-- the basics, just stick the items into their appropriate bars
	for bag_id, bag in pairs( cp.location[loc_id].bag ) do

		for slot_id, i in pairs( bag.slot ) do

			local ignore = false

			-- for multi-tab vault-style locations, skip bags that are not
			-- the active tab entirely so they don't contribute items or
			-- ghost bars during edit mode
			if ( loc_id == ArkInventory.Const.Location.Vault
				or loc_id == ArkInventory.Const.Location.PersonalBank
				or loc_id == ArkInventory.Const.Location.RealmBank )
				and not ArkInventory.db.realm.player.data[cp.info.player_id].display[loc_id].bag[bag_id] then
				ignore = true
			end

			if not ignore then

				local cat_id = i.cat or ArkInventory.ItemCategoryGet( i )
				local bar_id = ArkInventory.CategoryLocationGet( loc_id, cat_id )

				--ArkInventory.Output( "loc=[", loc_id, "], bag=[", bag_id, "], slot=[", slot_id, "], cat=[", cat_id, "], bar_id=[", bar_id, "]" )

				local hidden = false

				local bag_hidden = not ArkInventory.db.realm.player.data[cp.info.player_id].display[loc_id].bag[bag_id]
				local category_hidden = ( bar_id < 0 )

				if bag_hidden then
					-- items in non-active tabs are always hidden
					hidden = true
				elseif category_hidden then
					-- hidden categories (negative bar numbers) normally hidden
					hidden = true
				end

				if ArkInventory.Global.Mode.Edit or ArkInventory.LocationOptionGet( loc_id, { "slot", "ignorehidden" } ) then
					-- in edit mode (or when ignoring hidden), still honour bag_hidden
					-- but unhide items solely due to hidden categories
					if not bag_hidden then
						hidden = false
					end
				end

				if not hidden then

					bar_id = abs( bar_id )

					-- create the bar
					if not Layout.bar[bar_id] then
						Layout.bar[bar_id] = { ["id"] = bar_id, ["item"] = { }, ["count"] = 0, ["width"] = 0, ["height"] = 0, ["ghost"] = false, ["frame"] = 0 }
					end

					-- add the item to the bar
					tinsert( Layout.bar[bar_id].item, { ["bag"] = bag_id, ["slot"] = slot_id } )

					-- increment the bars item count
					Layout.bar[bar_id].count = Layout.bar[bar_id].count + 1

					-- keep track of the last bar used
					if bar_id > Layout.bar_count then
						Layout.bar_count = bar_id
					end

					--ArkInventory.Output( "bag[", bag_id, "], slot[", slot_id, "], cat[", cat_id, "], bar[", bar_id, "], id=[", Layout.bar[bar_id].id, "]" )

				end

			end

		end

	end


	-- determine highest "used" bar index from categories and explicit bar data
	local used = Layout.bar_count

	local cats = ArkInventory.LocationOptionGet( loc_id, { "category" } )
	for _, bar_id in pairs( cats ) do
		bar_id = abs( bar_id )
		if bar_id > used then
			used = bar_id
		end
	end

	local bdata = ArkInventory.LocationOptionGet( loc_id, { "bar", "data" } )
	if bdata then
		for k, v in pairs( bdata ) do
			if type( k ) == "number" and type( v ) == "table" and next( v ) ~= nil and k > used then
				-- only count bars that have at least one option set (eg, name, background, sort order)
				used = k
			end
		end
	end

	local bpr = ArkInventory.LocationOptionGet( loc_id, { "bar", "per" } ) or 1

	if ArkInventory.Global.Mode.Edit then
		-- in edit mode: fill the current row with implicit bars;
		-- if that row is exactly full, add another full row of implicit bars
		if used % bpr == 0 then
			Layout.bar_count = used + bpr
		else
			Layout.bar_count = ceil( used / bpr ) * bpr
		end
	else
		-- normal mode: just round up to a full row
		Layout.bar_count = ceil( used / bpr ) * bpr
	end

	-- update the maximum number of bar frames used so far
	if Layout.bar_count > ArkInventory.Global.Location[loc_id].maxBar then
		ArkInventory.Global.Location[loc_id].maxBar = Layout.bar_count
	end

	-- if we're in edit mode then create all missing bars and add a ghost item to every bar
	-- ghost items allow for the bar menu icon
	if ArkInventory.Global.Mode.Edit or ArkInventory.LocationOptionGet( loc_id, { "bar", "showempty" } ) then

		--ArkInventory.Output( "edit mode - adding ghost bars" )
		for bar_id = 1, Layout.bar_count do

			if not Layout.bar[bar_id] then

				-- create a ghost bar
				Layout.bar[bar_id] = { ["id"] = bar_id, ["item"] = { }, ["count"] = 1, ["width"] = 0, ["height"] = 0, ["ghost"] = true, ["frame"] = 0 }

			else

				-- add a ghost item to the bar by incrementing the bars item count
				Layout.bar[bar_id].count = Layout.bar[bar_id].count + 1

			end

		end

	end


	--ArkInventory.Output( GREEN_FONT_COLOR_CODE, "Frame_Container_CalculateBars( ", frame:GetName( ), " ) end" )

end

function ArkInventory.Frame_Container_CalculateContainer( frame, Layout )

	-- calculate what the bars look like in the conatiner

	--ArkInventory.Output( GREEN_FONT_COLOR_CODE, "Frame_Container_Calculate( ", frame:GetName( ), " ) start" )

	local loc_id = frame.ARK_Data.loc_id

	Layout.container = { ["row"] = { } }

	local bpr = ArkInventory.LocationOptionGet( loc_id, { "bar", "per" } )
	local rownum = 0
	local bf = 1 -- bar frame, allocated to each bar as it's calculated (uses less frames this way)

	--ArkInventory.Output( "container ", loc_id, " has ", Layout.bar_count, " bars" )
	--ArkInventory.Output( "container ", loc_id, " set for ", bpr, " bars per row" )


	if ArkInventory.Global.Mode.Edit == false and ArkInventory.LocationOptionGet( loc_id, { "bar", "compact" } ) then

		--ArkInventory.Output( "compact bars enabled" )

		local bc = 0  -- number of bars currently in this row
		local vr = { }  -- virtual row - holds a list of bars for this row

		for j = 1, Layout.bar_count do

			--ArkInventory.Output( "bar [", j, "]" )

			if Layout.bar[j] then
				if Layout.bar[j].count > 0 then
					--ArkInventory.Output( "assignment: bar [", j, "] to frame [", bf, "]" )
					Layout.bar[j]["frame"] = bf
					bf = bf + 1
					bc = bc + 1
					--tinsert( vr, Layout.bar[j] )
					tinsert( vr, j )
				else
					--ArkInventory.Output( "bar [", j, "] has no items" )
				end
			else
				--ArkInventory.Output( "bar [", j, "] has no items (does not exist)" )
			end

			if bc > 0 and ( bc == bpr or j == Layout.bar_count ) then

				rownum = rownum + 1
				if not Layout.container.row[rownum] then
					Layout.container.row[rownum] = { }
				end

				--ArkInventory.Output( "row [", rownum, "] allocated [", bc, "] bars" )

				Layout.container.row[rownum].bar = vr

				--ArkInventory.Output( "row [", rownum, "] created" )

				bc = 0
				vr = { }

			end

		end

	else

		for j = 1, Layout.bar_count, bpr do

			local bc = 0  -- number of bars currently in this row
			local vr = { }  -- virtual row - holds a list of bars for this row

			for b = 1, bpr do
				if Layout.bar[j+b-1] then
					if Layout.bar[j+b-1].count > 0 then
						--ArkInventory.Output( "assignment: bar [", j+b-1, "] to frame [", bf, "]" )
						Layout.bar[j+b-1]["frame"] = bf
						bf = bf + 1
						bc = bc + 1
						--tinsert( vr, Layout.bar[j+b-1] )
						tinsert( vr, j+b-1 )
					else
						--ArkInventory.Output( "bar [", j+b-1, "] has no items" )
					end
				else
					--ArkInventory.Output( "bar [", j+b-1, "] has no items (does not exist)" )
				end
			end

			if bc > 0 then

				rownum = rownum + 1
				if not Layout.container.row[rownum] then
					Layout.container.row[rownum] = { }
				end

				--ArkInventory.Output( "row [", rownum, "] allocated [", bc, "] bars" )

				Layout.container.row[rownum].bar = vr

			end

		end

	end


	-- fit the bars into the row

	local rmw = ArkInventory.LocationOptionGet( loc_id, { "window", "width" } )  -- row max width
	local rcw = 0 -- row current width
	local rch = 1 -- row current height
	local rmh = 0 -- row max height

	local bar = Layout.bar

	--ArkInventory.Output( "bars per row=[", bpr, "], max columns=[", rmw, "], columns per bar=[", floor( rmw / bpr ), "]" )

	for rownum, row in ipairs( Layout.container.row ) do

		for k, bar_id in ipairs( row.bar ) do

			bar[bar_id].width = 1
			if bar[bar_id].width < 1 then
				bar[bar_id].width = 1
			end

			bar[bar_id].height = ceil( bar[bar_id].count / bar[bar_id].width )

			if bar[bar_id].height > rmh then
				rmh = bar[bar_id].height
			end

			--ArkInventory.Output( "row=[", rownum, "], index=[", k, "], bar=[", bar_id, "], width=[", bar[bar_id].width, "], height=[", bar[bar_id].height, "]" )

		end



		if rmh > 1 then

			repeat

				rmh = 1
				local rmb = 0

				-- find bar with highest height
				for _, bar_id in ipairs( row.bar ) do
					if bar[bar_id].height > rmh then
						rmh = bar[bar_id].height
						rmb = bar_id
					end
				end

				if rmh > 1 then

					-- increase that bars width by one
					bar[rmb].width = bar[rmb].width + 1

					-- and recalcualte it's new height
					bar[rmb].height = ceil( bar[rmb].count / ( bar[rmb].width or 1 ) )

					-- and see if that all fits
					rcw = 0
					rmh = 0
					for _, bar_id in ipairs( row.bar ) do

						rcw = rcw + bar[bar_id].width

						if bar[bar_id].height > rmh then
							rmh = bar[bar_id].height
						end

					end

				end

				-- exit if the width fits or the max height is 1
			until rcw >= rmw or rmh == 1

		end

		--ArkInventory.Output( "maximum height for row [", rownum, "] was [", rmh, "]" )

		for k, bar_id in ipairs( row.bar ) do

			--ArkInventory.Output( "setting max height for row [", rownum, "] bar [", bar_id, "] to [", rmh, "]" )

			-- set height of all bars in the row to the maximum height used (looks better)
			bar[bar_id].height = rmh

			if bar[bar_id].ghost or ArkInventory.Global.Mode.Edit or ArkInventory.LocationOptionGet( loc_id, { "bar", "showempty" } ) then
				-- remove the ghost item from the count (it was only needed to calculate properly)
				bar[bar_id].count = bar[bar_id].count - 1
			end
		end

	end


	--ArkInventory.Output( GREEN_FONT_COLOR_CODE, "Frame_Container_Calculate( ", frame:GetName( ), " ) end" )

end

function ArkInventory.Frame_Container_Draw( frame )

	local loc_id = frame.ARK_Data.loc_id
	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )

	--ArkInventory.Output( "draw frame=", frame:GetName( ), ", loc=", loc_id, ", state=", ArkInventory.Global.Location[loc_id].drawState )

	if ArkInventory.Global.Location[loc_id].drawState <= ArkInventory.Const.Window.Draw.Recalculate then

		-- calculate what the container should look like
		ArkInventory.Frame_Container_Calculate( frame )

		local name

		-- create (if required) the bar frames, and hide any that are no longer required
		local placeframename = frame:GetName( ) .. "Bar"
		local placeframe = _G[placeframename]
		assert( placeframe, "xml element '" .. placeframename .. "' could not be found" )

		local baselevel = placeframe:GetFrameLevel( )

		for j = 1, ArkInventory.Global.Location[loc_id].maxBar do
			local barframename = placeframename .. j
			local barframe = _G[barframename]
			if not barframe then
				--ArkInventory.Output( "creating bar [", barframename, "]" )
				barframe = CreateFrame( "Frame", barframename, placeframe, "ARKINV_TemplateFrameBar" )
			end

			ArkInventory.Frame_Bar_Paint( barframe )
			barframe:Hide( )
		end

		-- create (if required) the bags and their item buttons, and hide any that are not currently needed
		local placeframename = frame:GetName( ) .. "Bag"
		local placeframe = _G[placeframename]
		assert( placeframe, "xml element '" .. placeframename .. "' could not be found" )

		--~~~~ need to fix this for when the cache is reset
		for bag_id in pairs( ArkInventory.Global.Location[loc_id].Bags ) do

			local bagframename = placeframename .. bag_id
			local bagframe = _G[bagframename]
			if not bagframe then
				--ArkInventory.Output( "creating bag frame [", bagframename, "]" )
				bagframe = CreateFrame( "Frame", bagframename, placeframe, "ARKINV_TemplateFrameBag" )
			end

			-- remember the maximum number of slots used for each bag
			local b = cp.location[loc_id].bag[bag_id]

			if not ArkInventory.Global.Location[loc_id].maxSlot[bag_id] then
				ArkInventory.Global.Location[loc_id].maxSlot[bag_id] = 0
			end

			if b.count > ArkInventory.Global.Location[loc_id].maxSlot[bag_id] then
				ArkInventory.Global.Location[loc_id].maxSlot[bag_id] = b.count
			end

			-- create the item frames for the bag
			for j = 1, ArkInventory.Global.Location[loc_id].maxSlot[bag_id] do

				local itemframename = ArkInventory.ContainerItemNameGet( loc_id, bag_id, j )
				local itemframe = _G[itemframename]
				if not itemframe then
					--ArkInventory.Output( "creating item frame [", itemframename, "]" )
					if loc_id == ArkInventory.Const.Location.Vault or loc_id == ArkInventory.Const.Location.PersonalBank or loc_id == ArkInventory.Const.Location.RealmBank then
						itemframe = CreateFrame( "Button", itemframename, bagframe, "ARKINV_TemplateButtonVaultItem" )
					elseif loc_id == ArkInventory.Const.Location.Pet or loc_id == ArkInventory.Const.Location.Mount then
						itemframe = CreateFrame( "Button", itemframename, bagframe, "ARKINV_TemplateButtonPetItem" )
					elseif loc_id == ArkInventory.Const.Location.Wearing or loc_id == ArkInventory.Const.Location.Mail or loc_id == ArkInventory.Const.Location.Token then
						itemframe = CreateFrame( "Button", itemframename, bagframe, "ARKINV_TemplateButtonViewOnlyItem" )
					else
						itemframe = CreateFrame( "Button", itemframename, bagframe, "ARKINV_TemplateButtonItem" )
					end
				end

				if j == 1 then
					ArkInventory.Global.BAG_SLOT_SIZE = itemframe:GetWidth( )
				end

				ArkInventory.Frame_Item_Update_Clickable( itemframe )
				itemframe:Hide( )

			end

		end

	end

	-- build the bar frames

	local name = frame:GetName( )

	local pad_slot = ArkInventory.LocationOptionGet( loc_id, { "slot", "pad" } )
	local pad_bar_int = ArkInventory.LocationOptionGet( loc_id, { "bar", "pad", "internal" } )
	local pad_bar_ext = ArkInventory.LocationOptionGet( loc_id, { "bar", "pad", "external" } )
	local pad_window = ArkInventory.LocationOptionGet( loc_id, { "window", "pad" } )
	local pad_label = ( ArkInventory.LocationOptionGet( loc_id, { "bar", "name", "show" } ) and ArkInventory.LocationOptionGet( loc_id, { "bar", "name", "height" } ) ) or 0
	local anchor = ArkInventory.LocationOptionGet( loc_id, { "bar", "anchor" } )

	--ArkInventory.Output( "Layout=[", ArkInventory.Global.Location[loc_id].Layout, "]" )

	for rownum, row in ipairs( ArkInventory.Global.Location[loc_id].Layout.container.row ) do

		row["width"] = pad_window * 2 + pad_bar_ext

		for bar_index, bar_id in ipairs( row.bar ) do

			local bar = ArkInventory.Global.Location[loc_id].Layout.bar[bar_id]

			local barframename = name .. "Bar" .. bar.frame
			local obj = _G[barframename]
			assert( obj, "xml element '" .. barframename .. "' could not be found" )

			-- assign the bar number used to the bar frame
			obj.ARK_Data.bar_id = bar_id

			if ArkInventory.Global.Location[loc_id].drawState <= ArkInventory.Const.Window.Draw.Recalculate then

				local obj_width = bar.width * ArkInventory.Global.BAG_SLOT_SIZE + ( bar.width - 1 ) * pad_slot + pad_bar_int * 2
				obj:SetWidth( obj_width )
				row.width = row.width + obj_width

				row.width = row.width + pad_bar_ext

				row["height"] = bar.height * ArkInventory.Global.BAG_SLOT_SIZE + ( bar.height - 1 ) * pad_slot + pad_bar_int * 2 + pad_label
				obj:SetHeight( row.height )

				obj:ClearAllPoints( )

				--ArkInventory.Output( "row=" .. rownum .. ", bar=" .. bar_index .. ", obj=" .. obj:GetName( ) .. ", frame=" .. bar.frame )
				-- anchor first bar to frame
				if bar.frame == 1 then

					if anchor == ArkInventory.Const.Anchor.BottomLeft then
						obj:SetPoint( "BOTTOMLEFT", frame, "BOTTOMLEFT", pad_window + pad_bar_ext, pad_window + pad_bar_ext )
					elseif anchor == ArkInventory.Const.Anchor.TopLeft then
						obj:SetPoint( "TOPLEFT", frame, "TOPLEFT", pad_window + pad_bar_ext, 0 - pad_window - pad_bar_ext )
					elseif anchor == ArkInventory.Const.Anchor.TopRight then
						obj:SetPoint( "TOPRIGHT", frame, "TOPRIGHT", 0 - pad_window - pad_bar_ext, 0 - pad_window - pad_bar_ext )
					else -- if anchor == ArkInventory.Const.Anchor.BottomRight then
						obj:SetPoint( "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0 - pad_window - pad_bar_ext, pad_window + pad_bar_ext )
					end

				else

					if bar_index == 1 then
						-- next row, place under previous row
						--ArkInventory.Output( "anchor=" .. name .. "Bar" .. ArkInventory.Global.Location[loc_id].Layout.container.row[rownum-1].bar[1].frame )

						local prev = ArkInventory.Global.Location[loc_id].Layout.container.row[rownum-1].bar[1]
						local parent = name .. "Bar" .. ArkInventory.Global.Location[loc_id].Layout.bar[prev].frame

						if anchor == ArkInventory.Const.Anchor.BottomLeft then
							obj:SetPoint( "BOTTOMLEFT", parent, "TOPLEFT", 0, pad_bar_ext )
						elseif anchor == ArkInventory.Const.Anchor.TopLeft then
							obj:SetPoint( "TOPLEFT", parent, "BOTTOMLEFT", 0, 0 - pad_bar_ext )
						elseif anchor == ArkInventory.Const.Anchor.TopRight then
							obj:SetPoint( "TOPRIGHT", parent, "BOTTOMRIGHT", 0, 0 - pad_bar_ext )
						else -- if anchor == ArkInventory.Const.Anchor.BottomRight then
							obj:SetPoint( "BOTTOMRIGHT", parent, "TOPRIGHT", 0, pad_bar_ext )
						end

					else

						-- next slot, place bar next to last one

						local parent = name .. "Bar" .. ( bar.frame - 1 )

						if anchor == ArkInventory.Const.Anchor.BottomLeft then
							obj:SetPoint( "BOTTOMLEFT", parent, "BOTTOMRIGHT", pad_bar_ext, 0 )
						elseif anchor == ArkInventory.Const.Anchor.TopLeft then
							obj:SetPoint( "TOPLEFT", parent, "TOPRIGHT", pad_bar_ext, 0 )
						elseif anchor == ArkInventory.Const.Anchor.TopRight then
							obj:SetPoint( "TOPRIGHT", parent, "TOPLEFT", 0 - pad_bar_ext, 0 )
						else -- if anchor == ArkInventory.Const.Anchor.BottomRight then
							obj:SetPoint( "BOTTOMRIGHT", parent, "BOTTOMLEFT", 0 - pad_bar_ext, 0 )
						end

					end

				end

				obj:Show( )

				-- repaint the bar now that it has the correct logical bar id
				ArkInventory.Frame_Bar_Paint( obj )

			end

			if ArkInventory.Global.Location[loc_id].drawState <= ArkInventory.Const.Window.Draw.Refresh then
				ArkInventory.Frame_Bar_Label( obj )
				ArkInventory.Frame_Bar_DrawItems( obj )
			end

		end

	end

	if ArkInventory.Global.Location[loc_id].drawState <= ArkInventory.Const.Window.Draw.Recalculate then

		-- set container height and width

		local c = ArkInventory.Global.Location[loc_id].Layout.container

		c.width = ArkInventory.Const.Window.Min.Width

		c.height = pad_window * 2 + pad_bar_ext

		for row_index, row in ipairs( c.row ) do

			if row.width > c.width then
				c.width = row.width
			end

			c.height = c.height + row.height + pad_bar_ext

		end

		if c.height < ArkInventory.Const.Window.Min.Height then
			c.height = ArkInventory.Const.Window.Min.Height
		end

		frame:SetWidth( c.width )
		frame:SetHeight( c.height )

	end

end

function ArkInventory.Frame_Container_OnLoad( frame )

	assert( frame, "frame is nil" )

	local framename = frame:GetName( )
	local loc_id = strmatch( framename, "^.-(%d+)Container" )

	assert( loc_id, string.format( "xml element '%s' is not an %s frame", framename, ArkInventory.Const.Program.Name ) )

	frame.ARK_Data = {
		["loc_id"] = tonumber( loc_id ),
	}

end


