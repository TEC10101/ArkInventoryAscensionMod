function ArkInventory.PT_ItemInSets( item, setnames )

	if not item or not setnames then return false end

	for setname in string.gmatch( setnames, "[^,]+" ) do

		local r = ArkInventory.Lib.PeriodicTable:ItemInSet( item, strtrim( setname ) )
		if r then
			return true
		end

	end

	return false

end

function ArkInventory.LocationPlayerInfoGet( loc_id )

	if loc_id == nil then return end

	if ArkInventory.Global.Location[loc_id].player_id == nil then
		ArkInventory.Global.Location[loc_id].player_id = ArkInventory.Global.Me.info.player_id
	end

	local base_player_id = ArkInventory.Global.Location[loc_id].player_id
	local cp = ArkInventory.PlayerInfoGet( base_player_id )

	if cp == nil then
		ArkInventory.Output( "invalid player id (", base_player_id, ") at location (", loc_id, ")" )
		assert( false, "code error" )
	end

	if loc_id == ArkInventory.Const.Location.Vault then
		-- vault location (4) is always stored under the guild owner,
		-- never under the character directly. Personal banks use
		-- their own location id (PersonalBank) instead.
		local guild_id = cp.info.guild_id
		if guild_id then
			cp = ArkInventory.PlayerInfoGet( guild_id )
			if cp == nil then
				ArkInventory.Output( "player id (", player_id, ") has an invalid guild id (", guild_id, ") at location (", loc_id, ")" )
				assert( false, "code error" )
			end
    end
  elseif loc_id == ArkInventory.Const.Location.RealmBank then
    -- realm bank is stored under the realm-wide pseudo-player
    local realm_id = cp.info.realmbank_id
    if realm_id then
      local realm_cp = ArkInventory.PlayerInfoGet( realm_id )
      if realm_cp then
        cp = realm_cp
      end
    end
	end

	return cp

end

function ArkInventory.OnProfileChanged( )

    -- this is called every time your profile changes

	ArkInventory.Lib.DewDrop:Close( )
	ArkInventory.Frame_Main_Hide( )
	ArkInventory.Frame_Rules_Hide( )

	ArkInventory.ConvertOldOptions( )
	ArkInventory.ItemCacheClear( )
	ArkInventory.PlayerInfoSet( )

	ArkInventory.ItemCategoryClear( )

	ArkInventory.Frame_Main_Generate( nil, ArkInventory.Const.Window.Draw.Init )

end

function ArkInventory.ObjectLockChanged( loc_id, bag_id, slot_id )

	if slot_id == nil then

		ArkInventory.Frame_Changer_Secondary_Update_Lock( loc_id, bag_id )

	else

		local framename = ArkInventory.ContainerItemNameGet( loc_id, bag_id, slot_id )
		if framename then
			local frame = _G[framename]
			ArkInventory.Frame_Item_Update_Lock( frame )
		end

	end

end

function ArkInventory.ItemSortKeyClear( loc_id )

	-- clear sort keys

	local Layout = ArkInventory.Global.Location[loc_id].Layout

	if not Layout.bar then return end

	for _, bar in pairs( Layout.bar ) do
		for _, item in pairs( bar.item ) do
			item.sortkey = nil
			item.cat = nil
		end
	end

end

function ArkInventory.ItemSortKeyGenerate( i, bar_id )

	if not i then return nil end

	local sid = ArkInventory.LocationOptionGet( i.loc_id, { "sort", "default" } ) or 9999

	if bar_id then
		sid = ArkInventory.LocationOptionGet( i.loc_id, { "bar", "data", bar_id, "sortorder" } ) or sid
	end

	local sorting = ArkInventory.db.global.option.sort.data[sid]

	local s = { }
	local sx = ""

	s["!bagslot"] = string.format( "%04i %04i", i.bag_id, i.slot_id )

	if sorting.used and not sorting.bagslot then

		local t
		local class, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11 = ArkInventory.ObjectInfo( i.h )

		-- slot type (system)
		t = 0
		if not i.h then
			t = ArkInventory.BagType( i.bag_id )
		end
		s["!slottype"] = string.format( "%04i", t )


		-- item count (system)
		s["!count"] = string.format( "%04i", i.count )


		-- item name
		t = "!"
		if i.h and sorting.active.name then

			t = v2 or "!"

			if sorting.reversed then
				t = ArkInventory.ReverseName( t )
			end

		end
		s["name"] = t


		-- item quality
		t = 0
		if i.q and sorting.active.quality then
			t = i.q
		end
		s["quality"] = string.format( "%02i", t )


		-- location
		t = "!"
		if i.h and class == "item" and sorting.active.location then

			if not v10 or v10 == "" then
				t = "!"
			else
				t = _G[v10]
			end

		end
		s["location"] = t


		-- item type / subtype
		local item_type = "!"
		local item_subtype = "!"

		if i.h and class == "item" and sorting.active.itemtype then

			item_type = v7
			if not item_type or item_type == "" then
				item_type = "!"
			end

			item_subtype = v8
			if not item_subtype or item_subtype == "" then
				item_subtype = "!"
			end

		end
		s["itemtype"] = string.format( "%s %s", item_type, item_subtype )


		-- item (use) level
		t = 0
		if i.h and sorting.active.itemuselevel then
			t = v6
		end
		s["itemuselevel"] = string.format( "%04i", t or 0 )


		-- item (use) level
		t = 0
		if i.h and sorting.active.itemage then
			t = i.age
		end
		s["itemage"] = string.format( "%10i", t or 0 )


		-- item (stat) level
		t = 0
		if i.h and sorting.active.itemstatlevel then
			t = v5
		end
		s["itemstatlevel"] = string.format( "%04i", t or 0 )


		-- vendor price
		t = 0
		if i.h and sorting.active.vendorprice then
			t = v11 * ( i.count or 1 )
		end
		s["vendorprice"] = string.format( "%08i", t or 0 )


		-- category
		local cat_type = 0
		local cat_code = 0
		local cat_order = 0

		if i.h and sorting.active.category then

			local cat_id = i.cat or ArkInventory.ItemCategoryGet( i )

			cat_type, cat_code = ArkInventory.CategoryCodeSplit( cat_id )

			if cat_type == ArkInventory.Const.Category.Type.Rule then
				local cat = ArkInventory.db.global.option.category[cat_type].data[cat_code]
				if cat.used then
					cat_order = cat.order
				end
			end

		end

		s["category"] = string.format( "%02i %04i %04i", cat_type, cat_order, cat_code )


		-- build key
		for k, v in ipairs( sorting.order ) do
			if s[v] then
				sx = string.format( "%s %s", sx, s[v] )
			end
		end

		sx = string.format( "%s%s", sx, s["!slottype"] )
		sx = string.format( "%s%s", sx, s["!count"] )
		sx = string.format( "%s%s", sx, s["!bagslot"] )

	else

		sx = s["!bagslot"]

	end

	return sx

end

function ArkInventory.SortKeyMoveDown( id, s )

	local p = false
	local t = ArkInventory.db.global.option.sort.data[id].order

	for k, v in ipairs( t ) do
		if s == v then
			p = k
			break
		end
	end

	if not p then
		return
	end

	if not t[p+1] then
		-- already at the bottom
		return
	end

	local x, y = t[p + 1], t[p]
	t[p], t[p + 1] = x, y

end

function ArkInventory.SortKeyMoveUp( id, s )

	local p = false
	local t = ArkInventory.db.global.option.sort.data[id].order

	for k, v in ipairs( t ) do
		if s == v then
			p = k
			break
		end
	end

	if not p or p == 1 then
		return
	end

	local x, y = t[p - 1], t[p]
	t[p], t[p - 1] = x, y

end

function ArkInventory.SortKeyCheck( )

	for sid, data in pairs( ArkInventory.db.global.option.sort.data ) do

		if data.used then

			-- add mising keys
			for s in pairs( ArkInventory.Const.SortKeys ) do

				local ok = false

				for _, v in ipairs( data.order ) do

					if s == v then
						ok = true
						break
					end

				end

				if not ok then
					tinsert( data.order, s )
				end

			end

			-- remove old keys from order
			for k, v in ipairs( data.order ) do
				if not ArkInventory.Const.SortKeys[v] then
					tremove( data.order, k )
				end
			end

			-- check active table
			if not data.active or type( data.active ) ~= "table" then
				data.active = { }
			end

			-- remove old keys from active table
			for k in pairs( data.active ) do
				if not ArkInventory.Const.SortKeys[k] then
					data.active[k] = nil
				end
			end

		else

			--ArkInventory.Table.Clean( data )

		end

	end

end

function ArkInventory.SortKeyCustomAdd( name )

	local v = ArkInventory.db.global.option.sort

	local n = ArkInventory.CategoryGetNext( v )

	if n == -1 then
		ArkInventory.OutputError( "sort method limit reached" )
		return
	end

	if n == -2 then
		ArkInventory.OutputError( "your data was recently upgraded, a ui reload is required before you can add a sort method" )
		return
	end

	v.data[v.next] = {
		used = true,
		name = strtrim( name ),
		bagslot = false,
		ascending = true,
		active = { },
		order = { },
	}

	ArkInventory.SortKeyCheck( )

	--ArkInventory.Output( GREEN_FONT_COLOR_CODE, "Added sortkey: ", name, " at ", ArkInventory.db.global.option.sort.next )
	ArkInventory.ConfigInternalSorting( )

end

function ArkInventory.SortKeyCustomDelete( id, confirm )

	if confirm == "DELETE" then

		ArkInventory.db.global.option.sort.data[id].used = false

		ArkInventory.ConfigInternalSorting( )
		ArkInventory.Lib.DewDrop:Close( )

	else

		ArkInventory.OutputError( "Delete sort failed, confirmation not valid" )

	end

end


function ArkInventory.NewItemIndicator( loc_id )
--[[
	c = _G[ArkInventory.Const.Frame.Main.Name .. loc_id .. ArkInventory.Const.Frame.Container.Name]
	if c and c:IsVisible( ) then

		local cp = ArkInventory.LocationPlayerInfoGet( loc_id )
		for _, bag_id in pairs( ArkInventory.Global.Location[loc_id].Bags ) do

			for slot_id in pairs( cp.location[loc_id].bag[bag_id].slot ) do
				s = _G[c:GetName( ) .. "Bag" .. bag_id .. "Item" .. slot_id]
				if s and s:IsVisible( ) then
					ArkInventory.Frame_Item_Update_NewIndicator( s )
				end
			end

		end

	end
]]--
end

function ArkInventory.NewItemReset( loc_id )
--[[
	-- reset new item text

	local cp = ArkInventory.LocationPlayerInfoGet( loc_id )

	for bag_id, bag in pairs( cp.location[loc_id].bag ) do
		for slot_id, slot in pairs( bag.slot ) do
			slot.new = ArkInventory.Const.Slot.New.No --~~~~ check this still works
		end
	end
]]--
end

function ArkInventory.LocationSetValue( l, k, v )
	for loc_id in pairs( ArkInventory.Global.Location ) do
		if l == nil or l == loc_id then
			if ArkInventory.Global.Location[loc_id] then
				ArkInventory.Global.Location[loc_id][k] = v
			end
		end
	end
end


function ArkInventory.CategoryBarGet( loc_id, cat_id, raw_vault )

	local cat_def = ArkInventory.CategoryGetSystemID( "SYSTEM_DEFAULT" )

	if cat_id == nil then
		cat_id = cat_def
	end

	-- when physically at a vault-style container, make sure category
	-- lookups for the generic vault location are redirected to the
	-- actual active vault location (guild vault vs personal/realm bank),
	-- unless the caller explicitly requests the raw vault mapping.
	local effective_loc_id = loc_id
	if not raw_vault and loc_id == ArkInventory.Const.Location.Vault and ArkInventory.Global.Mode.Vault and ArkInventory.Global.Mode.VaultLocation then
		effective_loc_id = ArkInventory.Global.Mode.VaultLocation
	end

	local bar = ArkInventory.LocationOptionGet( effective_loc_id, { "category", cat_id } )

	-- if it's the default category and the default is not on a bar then put it on bar 1
	if bar == nil and cat_id == cat_def then
		bar = 1
	end

	return bar

end

function ArkInventory.CategoryLocationSet( loc_id, cat_id, bar_id )

	assert( cat_id ~= nil , "category is nil" )

	local cat_def = ArkInventory.CategoryGetSystemID( "SYSTEM_DEFAULT" )

	if cat_id ~= cat_def or bar_id ~= nil then
		-- ensure that bar assignments made while at a vault-style
		-- container are stored against the active vault location
		-- (guild vault or personal bank) instead of always using
		-- the generic vault location id
		if loc_id == ArkInventory.Const.Location.Vault and ArkInventory.Global.Mode.Vault and ArkInventory.Global.Mode.VaultLocation then
			loc_id = ArkInventory.Global.Mode.VaultLocation
		end
		ArkInventory.LocationOptionSet( loc_id, { "category", cat_id }, bar_id )
	end

	-- for rule categories, keep the per-profile enabled flag
	-- in sync with whether the rule is actually assigned to
	-- any bar in this profile
	local cat_type, cat_code = ArkInventory.CategoryCodeSplit( cat_id )
	if cat_type == ArkInventory.Const.Category.Type.Rule then
		if bar_id ~= nil then
			-- assigning the rule to a bar (including hidden bars)
			-- enables it for the current profile
			local rp = ArkInventory.db.profile.option.rule[cat_code]
			if type( rp ) ~= "table" then
				rp = { enabled = true, usable = true }
			else
				rp.enabled = true
				if rp.usable == nil then
					rp.usable = true
				end
			end
			ArkInventory.db.profile.option.rule[cat_code] = rp
		else
			-- removing the rule from this bar; if it is no longer
			-- assigned to any bar in any location for this profile,
			-- then disable it for this profile
			local still_used = false
			local function ScanLocationRootForCategory( root )
				if still_used then
					return
				end
				if type( root ) ~= "table" then
					return
				end
				for _, locOpt in pairs( root ) do
					if type( locOpt ) == "table" then
						local cats = locOpt.category
						if type( cats ) == "table" and cats[cat_id] ~= nil then
							still_used = true
							return
						end
					end
				end
			end

			-- Profile-scoped locations (includes synthetic per-tab ids)
			ScanLocationRootForCategory( ArkInventory.db.profile.option.location )
			-- Realm-bank shared locations (also includes synthetic per-tab ids)
			if not still_used then
				local gb = ArkInventory.db.global and ArkInventory.db.global.realmbank
				if gb and gb.option and gb.option.location then
					ScanLocationRootForCategory( gb.option.location )
				end
			end

			if not still_used then
				local rp = ArkInventory.db.profile.option.rule[cat_code]
				if type( rp ) ~= "table" then
					rp = { enabled = false, usable = true }
				else
					rp.enabled = false
					if rp.usable == nil then
						rp.usable = true
					end
				end
				ArkInventory.db.profile.option.rule[cat_code] = rp
			end
		end

		-- changing where a rule is assigned can change which
		-- items match that rule in each location. clear the
		-- rule category cache so items no longer report stale
		-- rule assignments after bar changes.
		ArkInventory.ItemCacheClear( )
	end

end

function ArkInventory.CategoryLocationGet( loc_id, cat_id, raw_vault )

	-- maps category id's to the bars they are assigned to

	if cat_id == nil then
		cat_id = ArkInventory.CategoryGetSystemID( "SYSTEM_UNKNOWN" )
	end

	-- when at a vault-style container, redirect the generic
	-- vault location id to the currently active vault location
	-- so that guild vault and personal bank each honour their
	-- own bar layouts and category mappings.
	local effective_loc_id = loc_id
	if not raw_vault and loc_id == ArkInventory.Const.Location.Vault and ArkInventory.Global.Mode.Vault and ArkInventory.Global.Mode.VaultLocation then
		effective_loc_id = ArkInventory.Global.Mode.VaultLocation
	end

	local bar = ArkInventory.CategoryBarGet( effective_loc_id, cat_id, raw_vault )
	--ArkInventory.Output( "loc=[", loc_id, "], cat=[", cat_id, "], bar=[", bar, "]" )

	if not bar then
		-- if this category hasn't been assigned to a bar then return the bar that DEFAULT is using
		local cat_def = ArkInventory.CategoryGetSystemID( "SYSTEM_DEFAULT" )
		return ArkInventory.CategoryBarGet( effective_loc_id, cat_def, raw_vault ), true
	else
		return bar, false
	end

end

function ArkInventory.CategoryHiddenCheck( loc_id, cat_id )

	-- hidden categories have a negative bar number

	local bar = ArkInventory.CategoryBarGet( loc_id, cat_id )

	if bar ~= nil and bar < 0 then
		return true
	else
		return false
	end

end

function ArkInventory.CategoryHiddenToggle( loc_id, cat_id )
	ArkInventory.CategoryLocationSet( loc_id, cat_id, 0 - ArkInventory.CategoryLocationGet( loc_id, cat_id ) )
end

function ArkInventory.CategoryGenerate( )

	local categories = {
		["SYSTEM"] = ArkInventory.Const.Category.Code.System,
		["CONSUMABLE"] = ArkInventory.Const.Category.Code.Consumable,
		["TRADE_GOODS"] = ArkInventory.Const.Category.Code.Trade,
		["SKILL"] = ArkInventory.Const.Category.Code.Skill,
		["CLASS"] = ArkInventory.Const.Category.Code.Class,
		["EMPTY"] = ArkInventory.Const.Category.Code.Empty,
		["OTHER"] = ArkInventory.Const.Category.Code.Other,
		["RULE"] = ArkInventory.db.global.option.category[ArkInventory.Const.Category.Type.Rule].data,
		["CUSTOM"] = ArkInventory.db.global.option.category[ArkInventory.Const.Category.Type.Custom].data,
	}

	ArkInventory.Global.Category = { }

	for tn, d in pairs( categories ) do

		for k, v in pairs( d ) do

			--ArkInventory.Output( k, " - ", v )

			local system, order, name, cat_id, cat_type, cat_code

			if tn == "RULE" then

				if v.used then

					cat_type = ArkInventory.Const.Category.Type.Rule
					cat_code = k

					system = nil
					order = ( v.order or 99999 ) + ( k / 10000 )
					name = string.format( "%s. %s", k, v.name )

				end

			elseif tn == "CUSTOM" then

				if v.used then

					cat_type = ArkInventory.Const.Category.Type.Custom
					cat_code = k

					system = nil
					order = 0
					name = v.name

				end

			else

				cat_type = ArkInventory.Const.Category.Type.System
				cat_code = k

				system = string.upper( v.id )
				order = 0
				name = v.text or system

			end

			if name then

				cat_id = ArkInventory.CategoryCodeJoin( cat_type, cat_code )

				assert( not ArkInventory.Global.Category[cat_id], string.format( "duplicate category: %s [%s] ", tn, cat_id ) )

				ArkInventory.Global.Category[cat_id] = {
					["id"] = cat_id,
					["system"] = system,
					["name"] = name or string.format( "%s %s %s", tn, k, "<no name>"  ),
					["fullname"] = string.format( "%s > %s", ArkInventory.Localise["CATEGORY_" .. tn], name ),
					["order"] = order,
					["type_code"] = tn,
					["type"] = ArkInventory.Localise["CATEGORY_" .. tn],
				}

			end

		end

	end

end

function ArkInventory.CategoryCodeSplit( id )
	local cat_type, cat_code = strmatch( id, "(%d+)!(%d+)" )
	return tonumber( cat_type ), tonumber( cat_code )
end

function ArkInventory.CategoryCodeJoin( cat_type, cat_code )
	return string.format( "%i!%i", cat_type, cat_code )
end

function ArkInventory.CategoryGetNext( v )

	if not v.next then
		v.next = 1
	else
		if v.next < 1 then
			v.next = 1
		end
	end

	local c = 0

	while true do

		v.next = v.next + 1

		if v.next > ArkInventory.Const.Category.Max then
			c = c + 1
			v.next = 1
		end

		if c > 1 then
			return -1
		end

		if not v.data[v.next] then
			return -2
		end

		if not v.data[v.next].used then
			return v.next
		end

	end

end

function ArkInventory.BackgroundColourGetNext( v )

	if not v.next then
		v.next = 1
	else
		if v.next < 1 then
			v.next = 1
		end
	end

	local max = ArkInventory.Const.Category.Max
	local c = 0

	while true do

		v.next = v.next + 1

		if v.next > max then
			c = c + 1
			v.next = 1
		end

		if c > 1 then
			return -1
		end

		if not v.data[v.next] then
			v.data[v.next] = { }
		end

		if not v.data[v.next].used then
			return v.next
		end

	end

end

function ArkInventory.BackgroundColourCustomAdd( name )

	local v = ArkInventory.db.global.option.background

	local n = ArkInventory.BackgroundColourGetNext( v )

	if n == -1 then
		ArkInventory.OutputError( "background colour limit reached" )
		return
	end

	v.data[v.next].used = true
	v.data[v.next].name = strtrim( name )

end

function ArkInventory.BackgroundColourCustomDelete( id )

	local bg = ArkInventory.db.global.option.background.data
	if bg and bg[id] then
		bg[id].used = false
		bg[id].name = ""
	end

end

function ArkInventory.BackgroundColourCustomRename( id, name )

	local bg = ArkInventory.db.global.option.background.data
	if bg and bg[id] then
		bg[id].name = strtrim( name )
	end

end

function ArkInventory.BackgroundColourGet( id )

	if not id then
		return
	end

	local bg = ArkInventory.db.global.option.background.data
	if not bg or not bg[id] or not bg[id].used then
		return
	end

	return bg[id]

end

function ArkInventory.CategoryCustomAdd( name )

	local t = ArkInventory.Const.Category.Type.Custom
	local v = ArkInventory.db.global.option.category[t]

	local n = ArkInventory.CategoryGetNext( v )

	if n == -1 then
		ArkInventory.OutputError( "custom categories limit reached" )
		return
	end

	if n == -2 then
		ArkInventory.OutputError( "your data was recently upgraded, a ui reload is required before you can add a custom category" )
		return
	end

	v.data[v.next].used = true
	v.data[v.next].name = strtrim( name )

	ArkInventory.CategoryGenerate( )

end

function ArkInventory.CategoryCustomDelete( id, confirm )

	if confirm == "DELETE" then

		ArkInventory.db.global.option.category[ArkInventory.Const.Category.Type.Custom].data[id].used = false

		ArkInventory.CategoryGenerate( )
		ArkInventory.Lib.DewDrop:Close( )

	else
		ArkInventory.OutputError( "Delete category failed, confirmation not valid" )
	end

end

function ArkInventory.CategoryCustomRename( id, name )

	ArkInventory.db.global.option.category[ArkInventory.Const.Category.Type.Custom].data[id].name = strtrim( name )

	ArkInventory.CategoryGenerate( )

end

function ArkInventory.CategoryCustomRestore( id )

	local cat = ArkInventory.db.global.option.category[ArkInventory.Const.Category.Type.Custom].data

	cat[id].used = true
	if cat[id].name == "" then
		cat[id].name = string.format( "custom %s (restored)", id )
	end

	ArkInventory.CategoryGenerate( )

end

function ArkInventory.CategoryBarHasEntries( loc_id, bar_id, cat_type )

	for _, cat in ArkInventory.spairs( ArkInventory.Global.Category ) do

		local t = cat.type_code
		local cat_bar, def_bar = ArkInventory.CategoryLocationGet( loc_id, cat.id )

		if abs( cat_bar ) == bar_id and not def_bar then

			if t == "RULE" and cat_type == t then
				local _, cat_code = ArkInventory.CategoryCodeSplit( cat.id )
				local rp = ArkInventory.db.profile.option.rule[cat_code]
				local enabled = false
				if type( rp ) == "table" then
					enabled = rp.enabled and true or false
				else
					enabled = rp and true or false
				end
				if not enabled then
					t = "DO_NOT_USE" -- don't display disabled rules
				end
			end

			if cat_type == t then
				--ArkInventory.Output( "true" )
				return true
			end

		end

	end

	--ArkInventory.Output( "false" )

end


function ArkInventory.CategoryGetSystemID( cat_name )

	-- internal system category names only, if it doesnt exist you'll get the default instead

	--ArkInventory.Output( "search=[", cat_name, "]" )

	local cay_name = string.upper( cat_name )
	local cat_def

	for _, v in pairs( ArkInventory.Global.Category ) do

		--ArkInventory.Output( "checking=[", v.system, "]" )

		if cat_name == v.system then
			--ArkInventory.Output( "found=[", cat_name, " = ", v.name, "] = [", v.id, "]" )
			return v.id

		elseif v.system == "SYSTEM_DEFAULT" then
			--ArkInventory.Output( "default found=[", v.name, "] = [", v.id, "]" )
			cat_def = v.id
		end

	end

	--ArkInventory.Output( "not found=[", cat_name, "] = using default[", cat_def, "]" )
	return cat_def

end


function ArkInventory.ItemCategoryGetDefaultActual( i )

	-- local debuginfo = { ["m"]=gcinfo( ), ["t"]=GetTime( ) }

	-- pets
	if i.loc_id == ArkInventory.Const.Location.Pet then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_PET" )
	end

	-- mounts
	if i.loc_id == ArkInventory.Const.Location.Mount then
		return ArkInventory.CategoryGetSystemID( "SKILL_RIDING" )
	end

	-- tokens
	if i.loc_id == ArkInventory.Const.Location.Token then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_TOKEN" )
	end

	-- everything else
	local class, _, itemName, _, itemRarity, _, _, itemType, itemSubType, _, itemEquipLoc = ArkInventory.ObjectInfo( i.h )

	-- items only
	if class ~= "item" then
		return
	end

	local cp = ArkInventory.Global.Me

	--ArkInventory.Output( "bag[", i.bag_id, "], slot[", i.slot_id, "] = ", itemType )

	-- no item info
	if itemName == nil then
		return nil
	end

	-- trash
	if itemRarity == 0 then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_TRASH" )
	end

	-- setup tooltip for scanning
	local bliz_id = ArkInventory.BagID_Blizzard( i.loc_id, i.bag_id )
	ArkInventory.TooltipSetItem( ArkInventory.Global.Tooltip.Scan, bliz_id, i.slot_id )

	-- quest items (via type)
	if itemType == ArkInventory.Localise["WOW_ITEM_TYPE_QUEST"] then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_QUEST" )
	end

	-- projectiles
	if itemEquipLoc == "INVTYPE_AMMO" or itemType == ArkInventory.Localise["WOW_ITEM_TYPE_PROJECTILE"] then

		if itemSubType == ArkInventory.Localise["WOW_ITEM_TYPE_PROJECTILE_BULLET"] then
			return ArkInventory.CategoryGetSystemID( "SYSTEM_PROJECTILE_BULLET" )
		end

		if itemSubType == ArkInventory.Localise["WOW_ITEM_TYPE_PROJECTILE_ARROW"] then
			return ArkInventory.CategoryGetSystemID( "SYSTEM_PROJECTILE_ARROW" )
		end

		return ArkInventory.CategoryGetSystemID( "SYSTEM_PROJECTILE" )

	end

	-- bags / containers
	if itemEquipLoc == "INVTYPE_BAG" or ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise["PT_CATEGORY_CONTAINER"] ) then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_CONTAINER" )
	end

	-- equipment (armour, weapons, trinkets, tabards, etc, etc)
	if itemEquipLoc ~= "" then
		if i.sb then
			return ArkInventory.CategoryGetSystemID( "SYSTEM_EQUIPMENT_SOULBOUND" )
		else
			return ArkInventory.CategoryGetSystemID( "SYSTEM_EQUIPMENT" )
		end
	end

	-- soul shards
	if ArkInventory.ObjectStringDecodeItem( i.h ) == 6265 or ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise["PT_CATEGORY_SOULSHARD"] ) then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_SOULSHARD" )
	end

	-- keys
	if itemType == ArkInventory.Localise["WOW_ITEM_TYPE_KEY"] or ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise["PT_CATEGORY_KEY"] ) then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_KEY" )
	end

	-- glyphs
	if itemType == ArkInventory.Localise["WOW_ITEM_TYPE_GLYPH"] then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_GLYPH" )
	end

	-- class requirement via tooltip
	local ctext = "^" .. string.gsub( ITEM_CLASSES_ALLOWED, "%%s", "(.+)", 1 )
	local _, _, req = ArkInventory.TooltipFind( ArkInventory.Global.Tooltip.Scan, ctext, false, true, true )
	if req then
		for w in pairs( RAID_CLASS_COLORS ) do
			local key = string.format( "WOW_CLASS_%s", w )
			if strfind( req, ArkInventory.Localise[key] or key ) then
				return ArkInventory.CategoryGetSystemID( "CLASS_" .. w )
			end
		end
	end

	-- gems
	if itemType == ArkInventory.Localise["WOW_ITEM_TYPE_GEM"] then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_GEM" )
	end

	if itemType == ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE"] then

		if itemSubType == ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_FOOD_AND_DRINK"] then

			if ArkInventory.TooltipContains( ArkInventory.Global.Tooltip.Scan, ArkInventory.Localise["WOW_ITEM_TOOLTIP_FOOD"] ) then
				return ArkInventory.CategoryGetSystemID( "CONSUMABLE_FOOD" )
			end

			if ArkInventory.TooltipContains( ArkInventory.Global.Tooltip.Scan, ArkInventory.Localise["WOW_ITEM_TOOLTIP_DRINK"] ) then
				return ArkInventory.CategoryGetSystemID( "CONSUMABLE_DRINK" )
			end

			if ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise["PT_CATEGORY_CONSUMABLE_FOOD"] ) then
				return ArkInventory.CategoryGetSystemID( "CONSUMABLE_FOOD" )
			end

			if ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise["PT_CATEGORY_CONSUMABLE_DRINK"] ) then
				return ArkInventory.CategoryGetSystemID( "CONSUMABLE_DRINK" )
			end

			return ArkInventory.CategoryGetSystemID( "CONSUMABLE_FOOD_AND_DRINK" )

		end

		if itemSubType == ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_POTION"] then

			if ArkInventory.TooltipContains( ArkInventory.Global.Tooltip.Scan, ArkInventory.Localise["WOW_ITEM_TOOLTIP_POTION_HEAL"] ) or ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise["PT_CATEGORY_POTION_HEAL"] ) then
				return ArkInventory.CategoryGetSystemID( "CONSUMABLE_POTION_HEAL" )
			end

			if ArkInventory.TooltipContains( ArkInventory.Global.Tooltip.Scan, ArkInventory.Localise["WOW_ITEM_TOOLTIP_POTION_MANA"] ) or ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise["PT_CATEGORY_POTION_MANA"] ) then
				return ArkInventory.CategoryGetSystemID( "CONSUMABLE_POTION_MANA" )
			end

			return ArkInventory.CategoryGetSystemID( "CONSUMABLE_POTION" )

		end

		if itemSubType == ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_ELIXIR"] then

			if ArkInventory.TooltipContains( ArkInventory.Global.Tooltip.Scan, ArkInventory.Localise["WOW_ITEM_TOOLTIP_ELIXIR_BATTLE"] ) then
				return ArkInventory.CategoryGetSystemID( "CONSUMABLE_ELIXIR_BATTLE" )
			end

			if ArkInventory.TooltipContains( ArkInventory.Global.Tooltip.Scan, ArkInventory.Localise["WOW_ITEM_TOOLTIP_ELIXIR_GUARDIAN"] ) then
				return ArkInventory.CategoryGetSystemID( "CONSUMABLE_ELIXIR_GUARDIAN" )
			end

			return ArkInventory.CategoryGetSystemID( "CONSUMABLE_ELIXIR" )

		end

		if itemSubType == ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_FLASK"] then
			return ArkInventory.CategoryGetSystemID( "CONSUMABLE_FLASK" )
		end

		if itemSubType == ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_BANDAGE"] then
			return ArkInventory.CategoryGetSystemID( "CONSUMABLE_BANDAGE" )
		end

		if itemSubType == ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_SCROLL"] then
			return ArkInventory.CategoryGetSystemID( "CONSUMABLE_SCROLL" )
		end

	end

	if itemType == ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS"] then

		if itemSubType == ArkInventory.Localise["WOW_SKILL_ENCHANTING"] then
			return ArkInventory.CategoryGetSystemID( "SKILL_ENCHANTING" )
		end

		if itemSubType == ArkInventory.Localise["WOW_SKILL_JEWELCRAFTING"] then
			return ArkInventory.CategoryGetSystemID( "SKILL_JEWELCRAFTING" )
		end

		local t = "DEVICES,EXPLOSIVES,PARTS,HERB,CLOTH,ELEMENTAL,LEATHER,MEAT,METAL_AND_STONE,MATERIALS,ENCHANTMENT_ARMOR,ENCHANTMENT_WEAPON"

		for w in string.gmatch( t, "[^,]+" ) do
			local key = string.format( "WOW_ITEM_TYPE_TRADE_GOODS_%s", w )
			if itemSubType == ( ArkInventory.Localise[key] or key ) then
				return ArkInventory.CategoryGetSystemID( "TRADE_GOODS_" .. w )
			end
		end

	end

	if itemType == ArkInventory.Localise["WOW_ITEM_TYPE_RECIPE"] then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_RECIPE" )
	end

	-- quest items (via tooltip)
	if ArkInventory.TooltipContains( ArkInventory.Global.Tooltip.Scan, ITEM_BIND_QUEST, false, true, true ) then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_QUEST" )
	end

	-- skill requirement (via tooltip)
	-- ITEM_MIN_SKILL = "Requires %1$s (%2$d)"; -- Required skill rank to use the item
	local ctext = string.gsub( ITEM_MIN_SKILL, "1%$", "", 1 )
	local ctext = string.gsub( ctext, "2%$", "", 1 )
	local ctext = string.gsub( ctext, "%%s", "(.+)", 1 )
	local ctext = "^" .. string.gsub( ctext, "%(%%d%)", "%%(%%d+%%)", 1 )
	--ArkInventory.Output( ctext )
	--local _, _, req = ArkInventory.TooltipFind( ArkInventory.Global.Tooltip.Scan, ArkInventory.Localise["WOW_TOOLTIP_REQUIRES"], false, false, true )
	local _, _, req = ArkInventory.TooltipFind( ArkInventory.Global.Tooltip.Scan, ctext, false, true, true )
	if req then
		for w in string.gmatch( ArkInventory.Const.Skills, "[^,]+" ) do
			local key = string.format( "WOW_SKILL_%s", w )
			if strfind( req, ArkInventory.Localise[key] or key ) then
				return ArkInventory.CategoryGetSystemID( "SKILL_" .. w )
			end
		end
	end

	if itemType == ArkInventory.Localise["WOW_ITEM_TYPE_MISC"] then

		if itemSubType == ArkInventory.Localise["WOW_ITEM_TYPE_MISC_REAGENT"] then
			return ArkInventory.CategoryGetSystemID( "SYSTEM_REAGENT" )
		end

		if itemSubType == ArkInventory.Localise["WOW_ITEM_TYPE_MISC_PET"] or ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise["PT_CATEGORY_VANITYPET"] ) then
			return ArkInventory.CategoryGetSystemID( "SYSTEM_PET" )
		end

		-- mounts
		if itemSubType == ArkInventory.Localise["WOW_ITEM_TYPE_MISC_MOUNT"] or ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise["PT_CATEGORY_MOUNT"] ) then
			return ArkInventory.CategoryGetSystemID( "SKILL_RIDING" )
		end

	end


	-- class via periodictable (check this characters class first)
	local key = string.format( "PT_CLASS_%s", cp.info.class )
	if ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise[key] or key ) then
		return ArkInventory.CategoryGetSystemID( "CLASS_" .. cp.info.class )
	end

	-- class via periodictable (check all classes)
	for w in pairs( RAID_CLASS_COLORS ) do
		local key = string.format( "PT_CLASS_%s", w )
		if ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise[key] or key ) then
			return ArkInventory.CategoryGetSystemID( "CLASS_" .. w )
		end
	end


	-- skill requirement - cycle through the users skills and allocate items to those profressions first
	if cp.info.skills then
		for k, w in ipairs( cp.info.skills ) do
			local key = string.format( "PT_SKILL_%s", w )
			if ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise[key] or key ) then
				return ArkInventory.CategoryGetSystemID( "SKILL_" .. w )
			end
		end
	end

	-- skill requirement - do the rest
	for w in string.gmatch( ArkInventory.Const.Skills, "[^,]+" ) do
		local key = string.format( "PT_SKILL_%s", w )
		if ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise[key] or key ) then
			return ArkInventory.CategoryGetSystemID( "SKILL_" .. w )
		end
	end

	-- reputation hand-ins
	if ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise["PT_CATEGORY_REPUTATION"] ) then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_REPUTATION" )
	end

	-- quest items (via PT)
	if ArkInventory.PT_ItemInSets( i.h, ArkInventory.Localise["PT_CATEGORY_QUEST"] ) then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_QUEST" )
	end

	if itemType == ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS"] then
		return ArkInventory.CategoryGetSystemID( "TRADE_GOODS" )
	end

	if itemType == ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE"] then
		return ArkInventory.CategoryGetSystemID( "CONSUMABLE" )
	end

	-- soulbound items
	if i.sb then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_SOULBOUND" )
	end

	if itemType == ArkInventory.Localise["WOW_ITEM_TYPE_MISC"] then
		return ArkInventory.CategoryGetSystemID( "SYSTEM_MISC" )
	end

	return ArkInventory.CategoryGetSystemID( "SYSTEM_DEFAULT" )

end

function ArkInventory.ItemCategoryGetDefaultEmpty( loc_id, bag_id )

	local clump = ArkInventory.LocationOptionGet( loc_id, { "slot", "empty", "clump" } )

	local bliz_id = ArkInventory.BagID_Blizzard( loc_id, bag_id )
	local bt = ArkInventory.BagType( bliz_id )

	--ArkInventory.Output( "loc[", loc_id, "] bag[", bag_id, " / ", bliz_id, "] type[", bt, "]" )

	if bt == ArkInventory.Const.Slot.Type.Bag then
		if clump then
			return ArkInventory.CategoryGetSystemID( "EMPTY" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_BAG" )
		end
	end

	if bt == ArkInventory.Const.Slot.Type.Enchanting then
		if clump then
			return ArkInventory.CategoryGetSystemID( "SKILL_ENCHANTING" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_ENCHANTING" )
		end
	end

	if bt == ArkInventory.Const.Slot.Type.Engineering then
		if clump then
			return ArkInventory.CategoryGetSystemID( "SKILL_ENGINEERING" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_ENGINEERING" )
		end
	end

	if bt == ArkInventory.Const.Slot.Type.Gem then
		if clump then
			return ArkInventory.CategoryGetSystemID( "SKILL_JEWELCRAFTING" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_GEM" )
		end
	end

	if bt == ArkInventory.Const.Slot.Type.Herb then
		if clump then
			return ArkInventory.CategoryGetSystemID( "SKILL_HERBALISM" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_HERB" )
		end
	end

	if bt == ArkInventory.Const.Slot.Type.Inscription then
		if clump then
			return ArkInventory.CategoryGetSystemID( "SKILL_INSCRIPTION" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_INSCRIPTION" )
		end
	end

	if bt == ArkInventory.Const.Slot.Type.Key then
		if clump then
			return ArkInventory.CategoryGetSystemID( "SYSTEM_KEY" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_KEY" )
		end
	end

	if bt == ArkInventory.Const.Slot.Type.Leatherworking then
		if clump then
			return ArkInventory.CategoryGetSystemID( "SKILL_LEATHERWORKING" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_LEATHERWORKING" )
		end
	end

	if bt == ArkInventory.Const.Slot.Type.Mining then
		if clump then
			return ArkInventory.CategoryGetSystemID( "SKILL_MINING" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_MINING" )
		end
	end

	if bt == ArkInventory.Const.Slot.Type.Arrow then
		if clump then
			return ArkInventory.CategoryGetSystemID( "SYSTEM_PROJECTILE_ARROW" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_PROJECTILE_ARROW" )
		end
	end

	if bt == ArkInventory.Const.Slot.Type.Bullet then
		if clump then
			return ArkInventory.CategoryGetSystemID( "SYSTEM_PROJECTILE_BULLET" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_PROJECTILE_BULLET" )
		end
	end

	if bt == ArkInventory.Const.Slot.Type.Soulshard then
		if clump then
			return ArkInventory.CategoryGetSystemID( "SYSTEM_SOULSHARD" )
		else
			return ArkInventory.CategoryGetSystemID( "EMPTY_SOULSHARD" )
		end
	end

	if clump then
		return ArkInventory.CategoryGetSystemID( "EMPTY" )
	else
		return ArkInventory.CategoryGetSystemID( "EMPTY_UNKNOWN" )
	end

	ArkInventory.Output( "code failure, should never get here" )

end

function ArkInventory.ItemCategoryGetDefault( i )

	-- items cache id
	local id = ArkInventory.ObjectIDCacheCategory( i )

	-- if the value has not been cached yet then get it and cache it
	if not ArkInventory.Global.Cache.Default[id] then
		if i.h then
			ArkInventory.Global.Cache.Default[id] = ArkInventory.ItemCategoryGetDefaultActual( i )
		else
			ArkInventory.Global.Cache.Default[id] = ArkInventory.ItemCategoryGetDefaultEmpty( i.loc_id, i.bag_id )
		end
	end

	return ArkInventory.Global.Cache.Default[id]

end


function ArkInventory.ItemCategoryGetRule( i, bt, bag_id, slot_id )

	-- local debuginfo = { ["m"]=gcinfo( ), ["t"]=GetTime( ) }

	-- ArkInventory.Output( "ItemCategoryGetRule( ) start" )

	-- check rules
	local t = ArkInventory.Const.Category.Type.Rule
	local r = ArkInventory.db.global.option.category[t].data
	for rid in ArkInventory.spairs( r, function(a,b) return ( r[a].order or 0 ) < ( r[b].order or 0 ) end ) do

		if r[rid].used then
			-- only consider this rule if it is actually assigned to
			-- some bar in the current location. this ensures that
			-- rules are effectively per-location: a rule assigned to
			-- a bag bar does not run when evaluating items in the
			-- bank (unless it is also assigned to a bank bar).
			local skip = false
			local loc_id = i.loc_id
			if loc_id then
				local cat_id = ArkInventory.CategoryCodeJoin( t, rid )
				local cat_bar, def_bar = ArkInventory.CategoryLocationGet( loc_id, cat_id )
				if not ( abs( cat_bar or 0 ) > 0 and not def_bar ) then
					-- rule is not assigned to any bar in this location
					-- so skip evaluating it for this item
					skip = true
				end
			end
			if not skip then
				local a, em = ArkInventory.RuleAppliesToItem( rid, i )

			if em == nil then

				if a == true then
					local id = ArkInventory.CategoryCodeJoin( t, rid )
					return id
				end

			else

				ArkInventory.OutputWarning( em )
				ArkInventory.OutputWarning( string.format( ArkInventory.Localise["RULE_DAMAGED"], rid ) )

				ArkInventory.db.global.option.category[t].data[rid].damaged = true

			end

			end
		end

	end

	-- ArkInventory.Output( "ItemCategoryGetRule( ) end", debuginfo )

end

function ArkInventory.ItemCategoryGetPrimary( i )

	i["cat"] = nil

	local id

	if i.h then -- only items can have a category, empty slots can oly be used by rules

		-- items category cache id
		id = ArkInventory.ObjectIDCacheCategory( i )

		-- manually assigned item to a category?
		if ArkInventory.db.profile.option.category[id] then
			i["cat"] = ArkInventory.db.profile.option.category[id]
			return
		end

	end

	-- items rule cache id
	id = ArkInventory.ObjectIDCacheRule( i )

	-- if the value has already been cached then use it
	if ArkInventory.Global.Cache.Rule[id] then
		i["cat"] = ArkInventory.Global.Cache.Rule[id]
		return
	end

	-- check for any rule that applies to the item
	local rs = ArkInventory.ItemCategoryGetRule( i )
	if rs then
		-- cache the result
		ArkInventory.Global.Cache.Rule[id] = rs
		i["cat"] = ArkInventory.Global.Cache.Rule[id]
		return
	end

end

function ArkInventory.ItemCategorySet( i, cat_id )

	-- set cat_id to nil to reset back to default

	local id = ArkInventory.ObjectIDCacheCategory( i )
	ArkInventory.db.profile.option.category[id] = cat_id

	--i["cat"] = cat_id
	ArkInventory.ItemCategoryClear( )

end

function ArkInventory.ItemCategoryGet( i )

	if not i.cat then
		ArkInventory.ItemCategoryGetPrimary( i )
	end

	local default = ArkInventory.ItemCategoryGetDefault( i )
	local unknown = ArkInventory.CategoryGetSystemID( "SYSTEM_UNKNOWN" )

	return i.cat or default or unknown, i.cat, default or unknown

end

function ArkInventory.ItemCategoryClear( player_id, loc_id, empty_only )

	-- clears the category for all items for all characters

	for p, pd in pairs( ArkInventory.db.realm.player.data ) do

		-- only process matching player id
		if ( not player_id ) or ( player_id == pd.info.player_id ) then

			for l, ld in pairs( pd.location ) do

				-- only process matching location
				if ( not loc_id ) or ( loc_id == l ) then

					for b, bd in pairs( ld.bag ) do

						for s, sd in pairs( bd.slot ) do

							-- only process empty slots
							if ( not empty_only ) or ( empty_only and sd.h == nil ) then
								sd["cat"] = nil
							end

						end

					end

				end

			end

		end

	end

end

function ArkInventory.ReverseName( n )

	if n and type( n ) == "string" then

		local s = { }

		for w in string.gmatch( n, "%S+" ) do
			tinsert( s, 1, w )
		end

		return table.concat( s, " " )

	end

end

function ArkInventory.ItemCacheClear( )

	-- clear all rule information
	ArkInventory.Table.Clean( ArkInventory.Global.Cache.Rule )
	--ArkInventory.Global.Cache.Rule = { }

	ArkInventory.Table.Clean( ArkInventory.Global.Cache.Default )
	--ArkInventory.Global.Cache.Default = { }

	ArkInventory.CategoryGenerate( ) --zzzzzzzz still need this?
	ArkInventory.LocationSetValue( nil, "resort", true )
	ArkInventory.ItemCategoryClear( )
	--ArkInventory.Frame_Main_Generate( nil, ArkInventory.Const.Window.Draw.Recalculate )

end

