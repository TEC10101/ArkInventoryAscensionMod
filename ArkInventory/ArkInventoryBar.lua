function ArkInventory.Frame_Bar_Paint_All( )

	--ArkInventory.Output( "Frame_Bar_Paint_All( )" )

	for loc_id, loc_data in ipairs( ArkInventory.Global.Location ) do

		c = _G[ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Container.Name]

		if c and c:IsVisible( ) then

			for bar_id = 1, loc_data.maxBar do

				obj = _G[c:GetName( ) .. "Bar" .. bar_id]

				if obj then
					ArkInventory.Frame_Bar_Paint( obj )
				end

			end

		end

	end

end

function ArkInventory.Frame_Bar_Paint( frame )

	if not frame then
		return
	end

	local loc_id = frame.ARK_Data.loc_id

	-- border
	local obj = _G[frame:GetName( ) .. "ArkBorder"]
	if obj then

		if ArkInventory.LocationOptionGet( loc_id, { "bar", "border", "style" } ) ~= ArkInventory.Const.Texture.BorderNone then

			local style = ArkInventory.LocationOptionGet( loc_id, { "bar", "border", "style" } ) or ArkInventory.Const.Texture.BorderDefault
			local file = ArkInventory.Lib.SharedMedia:Fetch( ArkInventory.Lib.SharedMedia.MediaType.BORDER, style )
			local size = ArkInventory.LocationOptionGet( loc_id, { "bar", "border", "size" } ) or ArkInventory.Const.Texture.Border[ArkInventory.Const.Texture.BorderDefault].size
			local offset = ArkInventory.LocationOptionGet( loc_id, { "bar", "border", "offset" } ) or ArkInventory.Const.Texture.Border[ArkInventory.Const.Texture.BorderDefault].offset
			local scale = ArkInventory.LocationOptionGet( loc_id, { "bar", "border", "scale" } ) or 1
			local colour = ArkInventory.LocationOptionGet( loc_id, { "bar", "border", "colour" } )
			ArkInventory.Frame_Border_Paint( obj, false, file, size, offset, scale, colour.r, colour.g, colour.b, 1 )

			obj:Show( )

		else

			obj:Hide( )

		end

	end

	-- background colour
	if ArkInventory.Global.Mode.Edit then

		frame:SetBackdropBorderColor( 1, 0, 0, 1 )
		_G[frame:GetName( ) .. "Background"]:SetTexture( 1, 0, 0, 0.1 )

		local obj = _G[frame:GetName( ) .. "Edit"]

		local pad_bar = ArkInventory.LocationOptionGet( loc_id, { "bar", "pad", "internal" } )
		local pad_label = ( ArkInventory.LocationOptionGet( loc_id, { "bar", "name", "show" } ) and ArkInventory.LocationOptionGet( loc_id, { "bar", "name", "height" } ) ) or 0
		local anchor = ArkInventory.LocationOptionGet( loc_id, { "slot", "anchor" } )

		obj:ClearAllPoints( )

		-- anchor to the opposite corner that items are
		if anchor == ArkInventory.Const.Anchor.BottomLeft then
			obj:SetPoint( "TOPRIGHT", 0 - pad_bar, 0 - pad_bar - pad_label ) -- OK
		elseif anchor == ArkInventory.Const.Anchor.TopLeft then
			obj:SetPoint( "BOTTOMRIGHT", 0 - pad_bar, pad_bar + pad_label )
		elseif anchor == ArkInventory.Const.Anchor.TopRight then
			obj:SetPoint( "BOTTOMLEFT", pad_bar, pad_bar + pad_label )
		else -- anchor == ArkInventory.Const.Anchor.BottomRight then
			obj:SetPoint( "TOPLEFT", pad_bar, 0 - pad_bar - pad_label ) -- OK
		end

		obj:SetWidth( ArkInventory.Global.BAG_SLOT_SIZE )
		obj:SetHeight( ArkInventory.Global.BAG_SLOT_SIZE )
		obj:Show( )

	else

		local colour
		local bar_id = frame.ARK_Data.bar_id
		if bar_id then
			local bg_id = ArkInventory.LocationOptionGet( loc_id, { "bar", "data", bar_id, "backgroundid" } )
			if bg_id then
				local bg = ArkInventory.BackgroundColourGet( bg_id )
				if bg and bg.colour then
					colour = bg.colour
				end
			end
		end

		if not colour then
			colour = ArkInventory.LocationOptionGet( loc_id, { "bar", "background", "colour" } )
		end

		_G[frame:GetName( ) .. "Background"]:SetTexture( colour.r, colour.g, colour.b, colour.a )
		_G[frame:GetName( ) .. "Edit"]:Hide( )

	end

	-- label
	ArkInventory.Frame_Bar_Label( frame )

end

function ArkInventory.Frame_Bar_DrawItems( frame )

	--ArkInventory.Output( "Frame_Bar_DrawItems( ", frame:GetName( ), " )" )

	local loc_id = frame.ARK_Data.loc_id

	if ArkInventory.Global.Location[loc_id].drawState > ArkInventory.Const.Window.Draw.Refresh then
		return
	end

	local bar_id = frame.ARK_Data.bar_id
	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )

	local bar = ArkInventory.Global.Location[loc_id].Layout.bar[bar_id]
	assert( bar, "bar id has not been set on frame" )

	-- debug flag for layout issues (limits spam to bag location, bar 1)
	local debugLayout = ArkInventory.Const.Debug and loc_id == ArkInventory.Const.Location.Bag and bar_id == 1

	if bar.count == 0 or bar.ghost then
		return
	end

	-- sort the items in the bar
	for j = 1, bar.count do
		local bag_id = bar.item[j].bag
		local slot_id = bar.item[j].slot

		local i = cp.location[loc_id].bag[bag_id].slot[slot_id]

		-- track emptiness so empty slots can be kept at the end regardless of sort direction
		bar.item[j].empty = not i.h

		if bar.item[j].sortkey == nil then
			bar.item[j].sortkey = ArkInventory.ItemSortKeyGenerate( i, bar_id ) or "!"
		end

	end

	local sid_def = ArkInventory.LocationOptionGet( loc_id, { "sort", "default" } ) or 9999
	local sid = ArkInventory.LocationOptionGet( loc_id, { "bar", "data", bar_id, "sortorder" } ) or sid_def

	if not ArkInventory.db.global.option.sort.data[sid].used then
		--ArkInventory.OutputWarning( "bar ", bar_id, " in location ", loc_id, " is using an invalid sort method.  resetting it to default" )
		ArkInventory.LocationOptionSet( loc_id, { "bar", "data", bar_id, "sortorder" }, nil )
		sid = sid_def
	end

	local sortAscending = ArkInventory.db.global.option.sort.data[sid].ascending

	-- keep empty bag slots grouped at the end so the bar fill edge stays consistent
	sort( bar.item, function( a, b )
		if a.empty ~= b.empty then
			return not a.empty
		end
		if sortAscending then
			return a.sortkey > b.sortkey
		else
			return a.sortkey < b.sortkey
		end
	end )


	local pad_slot = ArkInventory.LocationOptionGet( loc_id, { "slot", "pad" } )
	local pad_bar = ArkInventory.LocationOptionGet( loc_id, { "bar", "pad", "internal" } )
	local col = bar.width
	local axis = ArkInventory.LocationOptionGet( loc_id, { "bar", "data", bar_id, "sortaxis" } ) or "HORIZONTAL"
	if axis ~= "HORIZONTAL" and axis ~= "VERTICAL" then
		axis = "HORIZONTAL"
	end

	if debugLayout then
		local ascending = sortAscending and "asc" or "desc"
		local emptyCount = 0
		for j = 1, bar.count do
			if bar.item[j].empty then
				emptyCount = emptyCount + 1
			end
		end
		ArkInventory.OutputDebug( "Bar layout before axis remap - loc=", loc_id, ", bar=", bar_id, ", sortid=", sid, " (", ascending, ")", ", axis=", axis, ", width=", bar.width, ", height=", bar.height, ", count=", bar.count, ", empty=", emptyCount )
	end

	-- for vertical (column) axis, remap the sorted item list so that
	-- the existing row-major anchoring code lays items out column-major
	if axis == "VERTICAL" and bar.count > 1 and col > 0 then
		local h = bar.height
		if h <= 0 then
			h = ceil( bar.count / col )
		end
		local n = bar.count
		local sorted = bar.item
		local layout = { }
		local s = 1
		for c = 1, col do
			for r = 1, h do
				if s > n then
					break
				end
				local j = ( r - 1 ) * col + c
				if j > n then
					break
				end
				layout[j] = sorted[s]
				s = s + 1
			end
		end
		bar.item = layout

		if debugLayout then
			ArkInventory.OutputDebug( "Bar layout after VERTICAL remap - loc=", loc_id, ", bar=", bar_id, ", width=", bar.width, ", height=", bar.height, ", count=", bar.count )
		end
	end

	-- cycle through the items in the bar
	for j = 1, bar.count do

		local i = cp.location[loc_id].bag[bar.item[j].bag].slot[bar.item[j].slot]
		local framename = ArkInventory.ContainerItemNameGet( loc_id, bar.item[j].bag, bar.item[j].slot )
		local obj = _G[framename]
		assert( obj, "xml element '" .. framename .. "' does not exist" )

		if debugLayout then
			local row = ceil( j / col )
			local column = ( ( j - 1 ) % col ) + 1
		end

		if ArkInventory.Global.Location[loc_id].drawState <= ArkInventory.Const.Window.Draw.Recalculate then

			-- anchor first item to bar frame - WARNING - item anchor point can only be bottom right, nothing else, so be relative

			local anchor = ArkInventory.LocationOptionGet( loc_id, { "slot", "anchor" } )
			local item_size = obj:GetWidth( )

			if j == 1 then

				local pad_name = 0

				if ArkInventory.LocationOptionGet( loc_id, { "bar", "name", "show" } ) then

					local name_anchor = ArkInventory.LocationOptionGet( loc_id, { "bar", "name", "anchor" } )

					if name_anchor ~= ArkInventory.Const.Anchor.Automatic then

						local slot_anchor = ArkInventory.Const.Anchor.Top
						if anchor == ArkInventory.Const.Anchor.BottomLeft or anchor == ArkInventory.Const.Anchor.BottomRight then
							slot_anchor = ArkInventory.Const.Anchor.Bottom
						end

						if name_anchor == slot_anchor then
							pad_name = ArkInventory.LocationOptionGet( loc_id, { "bar", "name", "height" } ) or 0
						end

					end

				end


				if anchor == ArkInventory.Const.Anchor.BottomLeft then
					obj:SetPoint( "BOTTOMRIGHT", frame, "BOTTOMLEFT", pad_bar + item_size, pad_bar + pad_name ) -- OK
				elseif anchor == ArkInventory.Const.Anchor.TopLeft then
					obj:SetPoint( "BOTTOMRIGHT", frame, "TOPLEFT", pad_bar + item_size, 0 - pad_bar - pad_name - item_size ) -- OK
				elseif anchor == ArkInventory.Const.Anchor.TopRight then
					obj:SetPoint( "BOTTOMRIGHT", frame, "TOPRIGHT", 0 - pad_bar, 0 - pad_bar - pad_name - item_size ) -- OK
				else -- anchor == ArkInventory.Const.Anchor.BottomRight then
					obj:SetPoint( "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0 - pad_bar, pad_bar + pad_name ) -- OK
				end

			else

					if mod( ( j - 1 ), col ) == 0 then

						-- next row, anchor to first item in previous row
						local anchorframe = ArkInventory.ContainerItemNameGet( loc_id, bar.item[j-col].bag, bar.item[j-col].slot )

						if anchor == ArkInventory.Const.Anchor.BottomLeft then
							obj:SetPoint( "BOTTOMRIGHT", anchorframe, 0, pad_slot + item_size ) -- OK
						elseif anchor == ArkInventory.Const.Anchor.TopLeft then
							obj:SetPoint( "BOTTOMRIGHT", anchorframe, 0, 0 - pad_slot - item_size ) -- OK
						elseif anchor == ArkInventory.Const.Anchor.TopRight then
							obj:SetPoint( "BOTTOMRIGHT", anchorframe, 0, 0 - pad_slot - item_size ) -- OK
						else -- if anchor == ArkInventory.Const.Anchor.BottomRight then
							obj:SetPoint( "BOTTOMRIGHT", anchorframe, 0, pad_slot + item_size ) -- OK
						end

					else

						-- anchor to last item

						local anchorframe = ArkInventory.ContainerItemNameGet( loc_id, bar.item[j-1].bag, bar.item[j-1].slot )

						if anchor == ArkInventory.Const.Anchor.BottomLeft then
							obj:SetPoint( "BOTTOMRIGHT", anchorframe, pad_slot + item_size, 0 )
						elseif anchor == ArkInventory.Const.Anchor.TopLeft then
							obj:SetPoint( "BOTTOMRIGHT", anchorframe, pad_slot + item_size, 0 )
						elseif anchor == ArkInventory.Const.Anchor.TopRight then
							obj:SetPoint( "BOTTOMRIGHT", anchorframe, 0 - pad_slot - item_size, 0 )
						else -- if anchor == ArkInventory.Const.Anchor.BottomRight then
							obj:SetPoint( "BOTTOMRIGHT", anchorframe, 0 - pad_slot - item_size, 0 )
						end

					end

			end

		end

		obj:Show( )

		if ArkInventory.Global.Location[loc_id].drawState <= ArkInventory.Const.Window.Draw.Refresh then
			ArkInventory.Frame_Item_Update_Border( obj )
			ArkInventory.Frame_Item_Update_Fade( obj )
			ArkInventory.Frame_Item_Update_Count( obj )
			ArkInventory.Frame_Item_Update_Texture( obj )
			ArkInventory.Frame_Item_Update_Quest( obj )
			ArkInventory.Frame_Item_Update_Cooldown( obj )
			ArkInventory.Frame_Item_Update_Lock( obj )
		end

	end

end

function ArkInventory.Frame_Bar_Label( frame )

	local loc_id = frame.ARK_Data.loc_id
	local bar_id = frame.ARK_Data.bar_id

	local obj = _G[frame:GetName( ) .. "Label"]
	local hit = _G[frame:GetName( ) .. "LabelHit"]

	if obj then

		local txt = ArkInventory.LocationOptionGet( loc_id, { "bar", "data", bar_id, "label" } )
		local showname = ArkInventory.LocationOptionGet( loc_id, { "bar", "name", "show" } )

		if txt and txt ~= "" and showname then

			local anchor = ArkInventory.LocationOptionGet( loc_id, { "bar", "name", "anchor" } )
			if anchor == ArkInventory.Const.Anchor.Automatic then
				anchor = ArkInventory.LocationOptionGet( loc_id, { "slot", "anchor" } )
				if anchor == ArkInventory.Const.Anchor.TopLeft or anchor == ArkInventory.Const.Anchor.TopRight then
					anchor = ArkInventory.Const.Anchor.Bottom
				else
					anchor = ArkInventory.Const.Anchor.Top
				end
			end
			obj:ClearAllPoints( )

			if anchor == ArkInventory.Const.Anchor.Top then
				obj:SetPoint( "TOPLEFT", frame:GetName( ), 4, -4 )
			else
				obj:SetPoint( "BOTTOMLEFT", frame:GetName( ), 4, 4 )
			end
			obj:SetPoint( "RIGHT", frame:GetName( ) )

			obj:SetText( txt )

			local colour = ArkInventory.LocationOptionGet( loc_id, { "bar", "name", "colour" } )
			obj:SetTextColor( colour.r, colour.g, colour.b )

			obj:Show( )
			if hit then
				hit:Show( )
			end

		else

			obj:Hide( )
			if hit then
				hit:Hide( )
			end

		end

	end

end

function ArkInventory.Frame_Bar_Insert( loc_id, bar_id )

	-- move bar data: insert a new empty bar at bar_id and
	-- shift all existing bar configurations at or above bar_id up by one
	local bar = ArkInventory.LocationOptionGet( loc_id, { "bar", "data" } ) or { }
	local maxbar = 0
	for k in pairs( bar ) do
		if type( k ) == "number" and k > maxbar then
			maxbar = k
		end
	end

	for k = maxbar, bar_id, -1 do
		local v = bar[k]
		if v ~= nil then
			ArkInventory.LocationOptionSet( loc_id, { "bar", "data", k + 1 }, v )
		end
	end

	-- initialise the new bar with an empty configuration table
	ArkInventory.LocationOptionSet( loc_id, { "bar", "data", bar_id }, { } )


	-- move category data (bar numbers can be negative)
	for cat, bar in pairs( ArkInventory.LocationOptionGet( loc_id, { "category" } ) ) do
		if abs( bar ) >= bar_id then
			if bar > 0 then
				ArkInventory.CategoryLocationSet( loc_id, cat, bar + 1 )
			else
				ArkInventory.CategoryLocationSet( loc_id, cat, bar - 1 )
			end
		end
	end

end

function ArkInventory.Frame_Bar_Remove( loc_id, bar_id )

	-- move bar data: remove bar_id and shift higher bars down
	local bar = ArkInventory.LocationOptionGet( loc_id, { "bar", "data" } ) or { }
	local maxbar = 0
	for k in pairs( bar ) do
		if type( k ) == "number" and k > maxbar then
			maxbar = k
		end
	end

	if maxbar > 0 and bar_id <= maxbar then
		for k = bar_id + 1, maxbar do
			local v = bar[k]
			ArkInventory.LocationOptionSet( loc_id, { "bar", "data", k - 1 }, v )
		end
		-- clear the highest bar configuration which has now moved down
		ArkInventory.LocationOptionSet( loc_id, { "bar", "data", maxbar }, nil )
	end


	-- move category data (bar numbers can be negative)
	local cat_def = ArkInventory.CategoryGetSystemID( "SYSTEM_DEFAULT" )

	for cat, bar in pairs( ArkInventory.LocationOptionGet( loc_id, { "category" } ) ) do

		if abs( bar ) > bar_id then

			if bar > 0 then
				ArkInventory.CategoryLocationSet( loc_id, cat, bar - 1 )
			else
				ArkInventory.CategoryLocationSet( loc_id, cat, bar + 1 )
			end

		elseif abs( bar ) == bar_id then

			if cat == cat_def then
				-- if the DEFAULT category was on the bar then move it to bar 1
				ArkInventory.CategoryLocationSet( loc_id, cat, 1 )
			else
				-- erase the location, setting it back to the same as DEFAULT
				ArkInventory.CategoryLocationSet( loc_id, cat, nil )
			end

		end

	end

end

function ArkInventory.Frame_Bar_Move( loc_id, bar1, bar2 )

	--ArkInventory.Output( "loc [", loc_id, "], bar1 [", bar1, "], bar2 [", bar2, "]" )

	if not bar1 or not bar2 or bar1 == bar2 or bar1 < 1 or bar2 < 1 then return end

	local step = 1
	if bar2 < bar1 then
		step = -1
	end

	-- move bar data
	local t = { }

	for k, v in pairs( ArkInventory.LocationOptionGet( loc_id, { "bar", "data" } ) ) do
		if k == bar1 then
			t[bar2] = v
		elseif ( ( step == 1 ) and ( k > bar1 and k <= bar2 ) ) or ( ( step == -1 ) and ( k >= bar2 and k < bar1 ) ) then
			t[k - step] = v
		end
	end

	for k, v in pairs( t ) do
		ArkInventory.LocationOptionSet( loc_id, { "bar", "data", k }, v )
	end


	-- move category data (bar numbers can be negative)
	for cat, bar in pairs( ArkInventory.LocationOptionGet( loc_id, { "category" } ) ) do
		local z = abs( bar )
		if z == bar1 then
			ArkInventory.CategoryLocationSet( loc_id, cat, bar2 )
		elseif ( ( step == 1 ) and ( z > bar1 and z <= bar2 ) ) or ( ( step == -1 ) and ( z >= bar2 and z < bar1 ) ) then
			if bar > 0 then
				ArkInventory.CategoryLocationSet( loc_id, cat, bar - step )
			else
				ArkInventory.CategoryLocationSet( loc_id, cat, bar + step )
			end
		end
	end

end

function ArkInventory.Frame_Bar_Clear( loc_id, bar_id )

	-- clear bar data
	table.wipe( ArkInventory.LocationOptionGet( loc_id, { "bar", "data", bar_id } ) )


	-- clear category
	for k, v in pairs( ArkInventory.LocationOptionGet( loc_id, { "category" } ) ) do
		if v == bar_id then
			local cat_def = ArkInventory.CategoryGetSystemID( "SYSTEM_DEFAULT" )
			if k ~= cat_def then
				-- erase the location, setting it back to the same as DEFAULT
				ArkInventory.CategoryLocationSet( loc_id, k, nil )
			end
		end
	end

end

function ArkInventory.Frame_Bar_OnLoad( frame )

	assert( frame, "frame is nil" )

	local framename = frame:GetName( )
	local loc_id, bar_id = strmatch( framename, "^.-(%d+)ContainerBar(%d+)" )

	assert( loc_id, string.format( "xml element '%s' is not an %s frame", framename, ArkInventory.Const.Program.Name ) )
	assert( bar_id, string.format( "xml element '%s' is not an %s frame", framename, ArkInventory.Const.Program.Name ) )

	frame.ARK_Data = {
		["loc_id"] = tonumber( loc_id ),
		["bar_id"] = tonumber( bar_id ),
	}

	frame:SetID( bar_id )

	ArkInventory.MediaSetFontFrame( frame )

end


function ArkInventory.Frame_Bar_OnEnter( frame )

	if not frame or not frame.ARK_Data then
		return
	end

	local loc_id = frame.ARK_Data.loc_id
	local bar_id = frame.ARK_Data.bar_id

	local text = string.format( ArkInventory.Localise["MENU_BAR_TITLE"], bar_id )
	local label = ArkInventory.LocationOptionGet( loc_id, { "bar", "data", bar_id, "label" } )

	if label and label ~= "" then
		text = string.format( "%s %s", text, label )
	end

	ArkInventory.GameTooltipSetText( frame, text )

end


