ArkInventory.SearchRebuild = true
ArkInventory.SearchTable = { }

ArkInventory.Search = ArkInventory.Search or { mode = "name" }

function ArkInventory.SearchIsRuleMode( )
	return ArkInventory.Search and ArkInventory.Search.mode == "rule"
end

function ArkInventory.SearchSetMode( mode )
	ArkInventory.Search = ArkInventory.Search or { }
	if mode == "rule" then
		ArkInventory.Search.mode = "rule"
	else
		ArkInventory.Search.mode = "name"
	end
end

-- helper used when not in rule mode: perform a plain-text search
-- over multiple item attributes using OR logic, short-circuiting
-- as soon as any attribute matches.
function ArkInventory.SearchItemMatchesFilter( h, count, q, filter )

	if not h then
		return false
	end

	local filter_trim = strtrim( filter or "" )
	if filter_trim == "" then
		-- empty filter: treat as match so callers can
		-- decide whether to apply any fading / filtering
		return true
	end

	local filter_lc = string.lower( filter_trim )

	-- name( )
	local item_name = select( 3, ArkInventory.ObjectInfo( h ) ) or ""
	local name_lc = string.lower( item_name )
	if name_lc ~= "" and string.find( name_lc, filter_lc, 1, true ) then
		return true
	end

	-- basic item info (only for real items)
	local class = ArkInventory.ObjectStringDecode( h )
	local is_item = ( class == "item" )
	local itemType, itemSubType, equipLoc
	local quality = q
	if is_item then
		local _, _, q2, _, _, t, st, _, el = GetItemInfo( h )
		itemType = t
		itemSubType = st
		equipLoc = el
		if quality == nil then
			quality = q2
		end
	end

	-- type( )
	if is_item and itemType and itemType ~= "" then
		if string.lower( itemType ) == filter_lc then
			return true
		end
	end

	-- subtype( )
	if is_item and itemSubType and itemSubType ~= "" then
		if string.lower( itemSubType ) == filter_lc then
			return true
		end
	end

	-- equip( )
	if is_item and equipLoc and equipLoc ~= "" then
		local e = strtrim( equipLoc )
		if string.len( e ) > 1 then
			-- map INVTYPE_* token to its localized display string
			e = _G[e]
		end
		e = string.lower( strtrim( e or "" ) )
		if e ~= "" and e == filter_lc then
			return true
		end
	end

	-- q( ) / quality( )
	if is_item and quality ~= nil then
		local n = tonumber( filter_trim )
		if n and n == quality then
			return true
		end
		local desc = _G[string.format( "ITEM_QUALITY%d_DESC", quality )]
		if desc and string.lower( desc ) == filter_lc then
			return true
		end
		-- extra colour/alias terms per quality
		local qa = {
			[0] = { "poor", "gray", "grey", "grays", "greys" },
			[1] = { "common", "white", "whites" },
			[2] = { "uncommon", "green", "greens" },
			[3] = { "rare", "blue", "blues" },
			[4] = { "epic", "purple", "purples" },
			[5] = { "legendary", "orange", "oranges" },
		}
		local aliases = qa[quality]
		if aliases then
			for _, term in ipairs( aliases ) do
				if filter_lc == term then
					return true
				end
			end
		end
	end

	-- tooltip-based checks
	local tooltip = ArkInventory.Global and ArkInventory.Global.Tooltip and ArkInventory.Global.Tooltip.Rule
	if not tooltip or not ArkInventory.TooltipSetHyperlink then
		return false
	end

	-- build a tooltip for tt( ) / itemstat( ) style matching
	ArkInventory.TooltipSetHyperlink( tooltip, h )

	-- tt( ) alias tooltip( ): any tooltip line containing the text
	if ArkInventory.TooltipContains and ArkInventory.TooltipContains( tooltip, filter_trim ) then
		return true
	end

	-- itemstat( ): look for stats with numbers on the left side that
	-- contain the search text (case-insensitive substring)
	if ArkInventory.TooltipNumLines then
		local numLines = ArkInventory.TooltipNumLines( tooltip )
		local statName = filter_lc
		if statName ~= "" then
			for line = 2, numLines do
				local leftText = _G[tooltip:GetName( ) .. "TextLeft" .. line]
				if leftText and leftText:IsShown( ) then
					local txt = leftText:GetText( ) or ""
					if txt ~= "" and string.find( txt, "%d" ) then
						local txtLower = string.lower( txt )
						if string.find( txtLower, statName, 1, true ) then
							return true
						end
					end
				end
			end
		end
	end

	return false

end

-- shared helper: derive the longest syntactically valid rule expression
-- from the raw search text, used by both the dedicated Search window and
-- the main bag search when in rule mode.
function ArkInventory.SearchRuleGetExpression( filter )

	if not filter then
		return nil
	end

	local txt = strtrim( filter )
	if txt == "" then
		return nil
	end

	-- only treat the search as a rule expression if it at least
	-- looks like one (identifier followed by an opening parenthesis
	-- at the start of the text, eg: tt("foo"), id(6948), type("armor")
	if not string.match( txt, "^%s*[%a_][%w_]*%s*%(" ) then
		return nil
	end

	-- simple heuristic: if the text starts with something like
	--   fn("partial
	-- assume a missing closing quote and parenthesis so that
	-- users can type tt("foo without immediately breaking parsing.
	--
	-- however, do NOT treat a bare opening string like tt(" as a
	-- usable expression; we only start searching once at least one
	-- character has been typed inside the quotes (eg tt("a ).
	local fname, arg = string.match( txt, '^%s*([%a_][%w_]*)%s*%(%s*"(.*)$' )
	if fname and arg and arg ~= "" and not string.match( arg, "^%s*$" ) and not string.find( arg, '"', 1, true ) then
		local candidate = string.format( '%s("%s")', fname, arg )
		local ok = loadstring( "return( " .. candidate .. " )" )
		if ok then
			return candidate
		end
	end

	local function canCompile( s )
		if not s or s == "" then
			return false
		end
		local ok = loadstring( "return( " .. s .. " )" )
		return ok and true or false
	end

	-- try the string as-is first
	if canCompile( txt ) then
		return txt
	end

	-- otherwise, trim from the end until we find the longest
	-- syntactically valid prefix (or give up). this allows
	-- partially-typed compound expressions like
	--   type("armor") and subtype("leather
	-- to fall back to the last valid prefix.
	local s = txt
	while string.len( s ) > 0 do
		s = string.sub( s, 1, string.len( s ) - 1 )
		s = strtrim( s )
		if s == "" then
			break
		end
		if canCompile( s ) then
			return s
		end
	end

	return nil

end

function ArkInventory.Frame_Search_Hide( )
	ARKINV_Search:Hide( )
end

function ArkInventory.Frame_Search_Show( )
	ARKINV_Search:Show( )
end

function ArkInventory.Frame_Search_Toggle( )

	if ARKINV_Search:IsVisible( ) then
		ArkInventory.Frame_Search_Hide( )
	else
		ArkInventory.Frame_Search_Show( )
	end

end


function ArkInventory.Frame_Search_Paint( )

	local frame = ARKINV_Search

	-- title
	obj = _G[frame:GetName( ) .. "TitleWho"]
	if obj then
		t = string.format( "%s: %s %s", ArkInventory.Localise["CONFIG_SEARCH"], ArkInventory.Const.Program.Name, ArkInventory.Global.Version )
		obj:SetText( t )
	end

	-- font
	ArkInventory.MediaSetFontFrame( frame )

	-- scale
	frame:SetScale( ArkInventory.db.profile.option.ui.search.scale or 1 )

	local style, file, size, offset, scale, colour

	for _, z in pairs( { frame:GetChildren( ) } ) do

		-- background
		local obj = _G[z:GetName( ) .. "Background"]
		if obj then
			style = ArkInventory.db.profile.option.ui.search.background.style or ArkInventory.Const.Texture.BackgroundDefault
			if style == ArkInventory.Const.Texture.BackgroundDefault then
				colour = ArkInventory.db.profile.option.ui.search.background.colour
				obj:SetTexture( colour.r, colour.g, colour.b, colour.a )
			else
				file = ArkInventory.Lib.SharedMedia:Fetch( ArkInventory.Lib.SharedMedia.MediaType.BACKGROUND, style )
				obj:SetTexture( file )
			end
		end

		-- border
		style = ArkInventory.db.profile.option.ui.search.border.style or ArkInventory.Const.Texture.BorderDefault
		file = ArkInventory.Lib.SharedMedia:Fetch( ArkInventory.Lib.SharedMedia.MediaType.BORDER, style )
		size = ArkInventory.db.profile.option.ui.search.border.size or ArkInventory.Const.Texture.Border[ArkInventory.Const.Texture.BorderDefault].size
		offset = ArkInventory.db.profile.option.ui.search.border.offset or ArkInventory.Const.Texture.Border[ArkInventory.Const.Texture.BorderDefault].offset
		scale = ArkInventory.db.profile.option.ui.search.border.scale or 1
		colour = ArkInventory.db.profile.option.ui.search.border.colour or { }

		local obj = _G[z:GetName( ) .. "ArkBorder"]
		if obj then
			if ArkInventory.db.profile.option.ui.search.border.style ~= ArkInventory.Const.Texture.BorderNone then
				ArkInventory.Frame_Border_Paint( obj, false, file, size, offset, scale, colour.r, colour.g, colour.b, 1 )
				obj:Show( )
			else
				obj:Hide( )
			end
		end

		for _, c1 in pairs( { z:GetChildren( ) } ) do
			if c1:GetName( ) then
				for _, c2 in pairs( { c1:GetChildren( ) } ) do
					if c2:GetName( ) then
						local obj = _G[c2:GetName( ) .. "ArkBorder"]
						if obj then
							if ArkInventory.db.profile.option.ui.search.border.style ~= ArkInventory.Const.Texture.BorderNone then
								ArkInventory.Frame_Border_Paint( obj, false, file, size, offset, scale, colour.r, colour.g, colour.b, 1 )
								obj:Show( )
							else
								obj:Hide( )
							end
						end
					end
				end
			end
		end

	end

end

function ArkInventory.Frame_Search_Table_Row_Draw( )

	local f = this:GetName( )

	local x
	local sz = 18

	-- item icon
	x = _G[f .. "T1"]
	x:ClearAllPoints( )
	x:SetWidth( sz )
	x:SetHeight( sz )
	x:SetPoint( "LEFT", 17, 0 )
	x:Show( )

	-- item name
	x = _G[f .. "C1"]
	x:ClearAllPoints( )
	x:SetWidth( 250 )
	x:SetPoint( "LEFT", f .. "T1", "RIGHT", 12, 0 )
	x:SetPoint( "TOP", 0, 0 )
	x:SetPoint( "BOTTOM", 0, 0 )
	x:SetPoint( "RIGHT", -5, 0 )
	x:SetTextColor( 1, 1, 1, 1 )
	x:SetJustifyH( "LEFT", 0, 0 )
	x:Show( )


--[[
	-- location icon
	x = _G[f .. "T2"]
	x:ClearAllPoints( )
	x:SetWidth( sz )
	x:SetHeight( sz )
	x:SetPoint( "RIGHT", f, "RIGHT", -5, 0 )
	x:Show( )

	-- count
	x = _G[f .. "C3"]
	x:ClearAllPoints( )
	x:SetWidth( 75 )
	x:SetPoint( "RIGHT", f .. "T2", "LEFT", -12, 0 )
	x:SetPoint( "TOP", 0, 0 )
	x:SetPoint( "BOTTOM", 0, 0 )
	x:SetJustifyH( "RIGHT", 0, 0 )
	x:Show( )

	-- who
	x = _G[f .. "C2"]
	x:ClearAllPoints( )
	x:SetPoint( "LEFT", f .. "C1", "RIGHT", 5, 0 )
	x:SetPoint( "TOP", 0, 0 )
	x:SetPoint( "BOTTOM", 0, 0 )
	x:SetPoint( "RIGHT", f .. "C3", "LEFT", -5, 0 )
	x:SetTextColor( 1, 1, 1, 1 )
	x:SetJustifyH( "LEFT", 0, 0 )
	x:Show( )
]]--

end

function ArkInventory.Frame_Search_Table_Draw( f )

	if not f or type( f ) ~= "string" then f = this:GetName( ) end

	local p = _G[f]
	if not p then
		ArkInventory.OutputError( "OOPS: Invalid value at ArkInventory.Frame_Search_Table_Draw( [", f, "] )" )
		return
	end

	local maxrows = tonumber( _G[f .. "MaxRows"]:GetText( ) )
	local rows = maxrows
	local height = 24

	if rows > maxrows then rows = maxrows end
	_G[f .. "NumRows"]:SetText( rows )

	if height == 0 then
		height = tonumber( _G[f .. "RowHeight"]:GetText( ) )
	end
	_G[f .. "RowHeight"]:SetText( height )

	-- stretch scrollbar to bottom row
	_G[f .. "Scroll"]:SetPoint( "BOTTOM", f .. "Row" .. rows, "BOTTOM", 0, 0 )

	-- set frame height to correct size
	_G[f]:SetHeight( height * rows + 20 )

end

function ArkInventory.Frame_Search_Table_Row_OnClick( frame )

	h = _G[this:GetName( ) .. "Id"]:GetText( )
	if HandleModifiedItemClick( h ) then
		return
	end

end

function ArkInventory.Frame_Search_Table_Reset( f )

	if not f or type( f ) ~= "string" then f = this:GetName( ) end
	-- hide and reset all rows

	local t = f .. "Table"

	local h = tonumber( _G[t .. "RowHeight"]:GetText( ) )
	local r = tonumber( _G[t .. "NumRows"]:GetText( ) )

	_G[t .. "SelectedRow"]:SetText( "-1" )
	for x = 1, r do
		_G[t .. "Row" .. x .. "Selected"]:Hide( )
		_G[t .. "Row" .. x .. "Id"]:SetText( "-1" )
		_G[t .. "Row" .. x]:Hide( )
		_G[t .. "Row" .. x]:SetHeight( h )
	end

end

function ArkInventory.Frame_Search_Table_Refresh_old( f )

	if not f then
		f = this:GetParent( ):GetParent( ):GetParent( ):GetName( )
	end

	-- ArkInventory.Print( "Frame_Search_Table_Refresh( " .. ArkInventory.nilStringText( f ) .. " ), " .. this:GetName( ) )

	local p = _G[f]
	if not p then
		ArkInventory.OutputError( "OOPS: Invalid widget name at Frame_Search_Table_Refresh( ", f, " )" )
		return
	end

	f = f .. "View"

	local ft = f .. "Table"
	local fs = f .. "Search"

	local height = tonumber( _G[ft .. "RowHeight"]:GetText( ) )
	local rows = tonumber( _G[ft .. "NumRows"]:GetText( ) )

	local line
	local lineplusoffset

	ArkInventory.Frame_Search_Table_Reset( f )

	-- collect all valid items
	local filter = _G[fs .. "Filter"]:GetText( )
	--ArkInventory.Print( "filter = [" .. filter .. "]" )

	local inv = { }

	local realm = GetRealmName( )
	local faction = UnitFactionGroup( "player" )

	local apd = ArkInventory.db.realm.player.data

	for _, pd in ArkInventory.spairs( apd ) do

		--if pd.info.realm == realm and pd.info.faction == faction then
		if pd.info.realm == realm then

			local pl = ArkInventory.db.global.cache.realm[pd.info.realm].faction[pd.info.faction].character[pd.info.name]

			if pl and pl.location then

				local me = false
				if pd.info.player_id == ArkInventory.Global.Me.info.player_id then
					me = true
				end

				for l, ld in pairs( pl.location ) do

					if ld.active then
						for b, bd in pairs( ld.bag ) do
							for s, sd in pairs( bd.slot ) do

								if sd.h then

									local item_name = string.match( sd.h, "%[(.+)%]" )
									local ignore = false

									if filter ~= "" then
										if not string.find( string.lower( item_name or "" ), string.lower( filter ) ) then
											ignore = true
										end
									end

									if not ignore then

										local id = ArkInventory.ObjectIDTooltip( sd.h )

										if not inv[id] then
											inv[id] = { ["sorted"]=item_name, ["h"]=sd.h }
--										else
--											inv[id].count = inv[id].count + sd.count
										end

									end

								end
							end
						end
					end

				end

			end

		end

	end



	local t = { }
	local tc = 0

	for i in pairs( inv ) do
		tc = tc + 1
		t[tc] = inv[i]
	end


	--table.insert( t, { ["sorted"]=format( "%s!%s!%04i", pd.info.player_id, item_name, l ), ["h"]=sd.h, ["who"]=pd.info.name, ["loc_id"]=l, ["item_name"]=item_name, ["item_texture"]=item_texture, ["item_count"]=sd.count } )
	--tc = tc + 1


	if tc == 0 then
		return
	end

	-- sort them by name
	table.sort( t, function( a, b ) return a.sorted < b.sorted end )

	FauxScrollFrame_Update( _G[ft .. "Scroll"], tc, rows, height )

	local linename, c, r

	for line = 1, rows do

		linename = ft .. "Row" .. line

		lineplusoffset = line + FauxScrollFrame_GetOffset( _G[ft .. "Scroll"] )

		if lineplusoffset <= tc then

			c = ""
			r = t[lineplusoffset]

			_G[linename .. "Id"]:SetText( r.h )

			_G[linename .. "T1"]:SetTexture( ArkInventory.ObjectInfoTexture( r.h ) )

			--_G[linename .. "T2"]:SetTexture( ArkInventory.Global.Location[r.loc_id].Texture )

			_G[linename .. "C1"]:SetText( r.h )

			--_G[linename .. "C2"]:SetText( r.who )

			--c = string.format( r.count )
			--_G[linename .. "C3"]:SetText( c )

			_G[linename]:Show( )

		else

			_G[linename .. "Id"]:SetText( "" )
			_G[linename]:Hide( )

		end
	end

	-- ~~~~ clean table t

end

function ArkInventory.Frame_Search_Table_Refresh( frame )

	local f = frame

	if not f then
		f = this:GetParent( ):GetParent( ):GetParent( ):GetName( )
	end

	--ArkInventory.Output( "Frame_Search_Table_Refresh( ", f, " ), ", this:GetName( ) )

	local p = _G[f]
	if not p then
		ArkInventory.OutputError( "OOPS: Invalid widget name at Frame_Search_Table_Refresh( ", f, " )" )
		return
	end

	f = f .. "View"

	ArkInventory.Frame_Search_Table_Reset( f )

	local filter = _G[f .. "SearchFilter"]:GetText( )
	local filter_lc = string.lower( filter or "" )
	--ArkInventory.Print( "filter = [" .. filter .. "]" )

	local rule_expr
	local rule_func
	local rule_mode = ArkInventory.SearchIsRuleMode and ArkInventory.SearchIsRuleMode( )

	if rule_mode and ArkInventory.SearchRuleGetExpression then
		rule_expr = ArkInventory.SearchRuleGetExpression( filter )
		if rule_expr then
			local func, em = loadstring( string.format( "return( %s )", rule_expr ) )
			if func then
				rule_func = func
			else
				-- invalid expression, emit an error so the user knows the
				-- rule failed to compile but do not fall back to name search
				if ArkInventory and ArkInventory.OutputError then
					ArkInventory.OutputError( string.format( "search rule compile error: %s", tostring( em ) ) )
				end
				rule_expr = nil
			end
		end
		-- in rule mode, if we don't have a usable rule function then
		-- treat the filter as empty so we do not perform name-based
		-- searching while the user is still typing the rule keyword
		if not rule_func then
			filter_lc = ""
		end
	end

	local tt = { }
	ArkInventory.SearchRebuild = false

	local cp = ArkInventory.Global.Me

	for p, pd in ArkInventory.spairs( ArkInventory.db.realm.player.data ) do

		for l, ld in pairs( pd.location ) do

			for b, bd in pairs( ld.bag ) do

				for s, sd in pairs( bd.slot ) do

					if sd.h then

						local item_name = select( 3, ArkInventory.ObjectInfo( sd.h ) ) or ""

						if item_name == "" then
							ArkInventory.SearchRebuild = true
						end

						local ignore = false

						if rule_func then
							local matched, err = ArkInventory.RuleEvaluate( rule_func, sd.h, sd.count, sd.q )
							if not matched then
								ignore = true
							end
						else
							if ArkInventory.SearchItemMatchesFilter then
								if not ArkInventory.SearchItemMatchesFilter( sd.h, sd.count, sd.q, filter ) then
									ignore = true
								end
							else
								-- fallback: plain text only matches against the item name
								if filter_lc ~= "" and item_name ~= "" then
									if not string.find( string.lower( item_name or "" ), filter_lc, 1, true ) then
										ignore = true
									end
								end
							end
						end

						if not ignore then

							local id = ArkInventory.ObjectIDTooltip( sd.h )

							if not tt[id] then
								local t = select( 4, ArkInventory.ObjectInfo( sd.h ) )
								tt[id] = { id = id, sorted = item_name, name = item_name, h = sd.h, q = sd.q, t = t }
							end

						end

					end

				end

			end

		end

	end

	ArkInventory.SearchTable = { }

	for _, v in pairs( tt ) do
		table.insert( ArkInventory.SearchTable, v )
	end

	if #ArkInventory.SearchTable > 0 then
		table.sort( ArkInventory.SearchTable, function( a, b ) return a.sorted < b.sorted end )
		ArkInventory.Frame_Search_Table_Scroll( frame )
	end

end

function ArkInventory.Frame_Search_Table_Scroll( frame )

	local f = frame

	if not f then
		f = this:GetParent( ):GetParent( ):GetParent( ):GetName( )
	end

	local p = _G[f]
	if not p then
		ArkInventory.OutputError( "OOPS: Invalid widget name at Frame_Search_Table_Refresh( ", f, " )" )
		return
	end

	f = f .. "View"

	local ft = f .. "Table"
	local fs = f .. "Search"

	local height = tonumber( _G[ft .. "RowHeight"]:GetText( ) )
	local rows = tonumber( _G[ft .. "NumRows"]:GetText( ) )

	local line
	local lineplusoffset

	ArkInventory.Frame_Search_Table_Reset( f )

	local tc = #ArkInventory.SearchTable

	FauxScrollFrame_Update( _G[ft .. "Scroll"], tc, rows, height )

	local linename, c, r

	for line = 1, rows do

		linename = ft .. "Row" .. line

		lineplusoffset = line + FauxScrollFrame_GetOffset( _G[ft .. "Scroll"] )

		if lineplusoffset <= tc then

			c = ""
			r = ArkInventory.SearchTable[lineplusoffset]

			_G[linename .. "Id"]:SetText( r.h )

			_G[linename .. "T1"]:SetTexture( r.t )

			local cr, cg, cb = GetItemQualityColor( r.q )
			local cc = ArkInventory.ColourRGBtoCode( cr, cg, cb )
			_G[linename .. "C1"]:SetText( string.format( "%s%s", cc, r.name ) )

			_G[linename]:Show( )

		else

			_G[linename .. "Id"]:SetText( "" )
			_G[linename]:Hide( )

		end

	end

end

function ArkInventory_Frame_Search_Table_Refresh( )
	ArkInventory.Frame_Search_Table_Refresh( )
end

function ArkInventory_Frame_Search_Table_Scroll( )
	ArkInventory.Frame_Search_Table_Scroll( )
end
