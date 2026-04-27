-- ------------------------------------------------------------------------------------------------------------
-- Trace / instrumentation (opt-in)
-- ------------------------------------------------------------------------------------------------------------

ArkInventory.Trace = ArkInventory.Trace or {
	enabled = false,
	active = false,
	loc_id = nil,
	frame = nil,
	startMS = 0,
	lastUpdateMS = 0,
	lastSampleMS = 0,
	sampleIntervalMS = 50,
	stallThresholdMS = 500,
	maxEvents = 250,
	cursor = 0,
	events = { },
	anchorSuppressed = 0,
	lastState = nil,
	objHooked = nil,
	stackMode = "top", -- off | top | full
}

function ArkInventory.TraceNowMS( )
	if debugprofilestop then
		return debugprofilestop( )
	end
	if GetTime then
		return GetTime( ) * 1000
	end
	return 0
end

local ARKINV_TRACE_STRATA_RANK = {
	["BACKGROUND"] = 1,
	["LOW"] = 2,
	["MEDIUM"] = 3,
	["HIGH"] = 4,
	["DIALOG"] = 5,
	["FULLSCREEN"] = 6,
	["FULLSCREEN_DIALOG"] = 7,
	["TOOLTIP"] = 8,
}

local function ArkInventory_TraceSafeName( f )
	if not f then return "nil" end
	if f.GetName then
		return f:GetName( ) or "<unnamed>"
	end
	return tostring( f )
end

local function ArkInventory_TraceFrameStrata( f )
	if not f or not f.GetFrameStrata then return "?" end
	local ok, v = pcall( f.GetFrameStrata, f )
	if ok and v then return v end
	return "?"
end

local function ArkInventory_TraceFrameLevel( f )
	if not f or not f.GetFrameLevel then return -1 end
	local ok, v = pcall( f.GetFrameLevel, f )
	if ok and v then return v end
	return -1
end

local function ArkInventory_TraceFrameRect( f )
	if not f or not f.GetLeft then return nil end
	local l = f:GetLeft( )
	local r = f:GetRight( )
	local t = f:GetTop( )
	local b = f:GetBottom( )
	if not l or not r or not t or not b then
		return nil
	end
	return l, r, t, b
end

local function ArkInventory_TraceShallowCopy( src )
	if type( src ) ~= "table" then
		return src
	end
	local dst = { }
	for k, v in pairs( src ) do
		if type( v ) ~= "table" then
			dst[k] = v
		end
	end
	return dst
end

local function ArkInventory_TraceStack( )
	if debugstack then
		-- 2 = skip this function + hook wrapper
		return debugstack( 2, 12, 12 )
	end
	return nil
end

local function ArkInventory_TraceStackOneLine( stack )
	if type( stack ) ~= "string" then
		return nil
	end
	local out = { }
	for line in stack:gmatch( "[^\n]+" ) do
		line = strtrim( line or "" )
		if line ~= "" then
			table.insert( out, line )
			if #out >= 3 then
				break
			end
		end
	end
	if #out == 0 then
		return nil
	end
	return table.concat( out, " | " )
end

local function ArkInventory_TraceMaybeStack( )
	local t = ArkInventory.Trace
	local mode = t and t.stackMode or "top"
	if mode == "off" then
		return nil
	end
	local stack = ArkInventory_TraceStack( )
	if mode == "full" then
		return stack
	end
	return ArkInventory_TraceStackOneLine( stack )
end

local function ArkInventory_TraceIsWatchedFrame( self )
	local t = ArkInventory.Trace
	if not t or not t.enabled then
		return false
	end
	if t.watch and t.watch[self] then
		return true
	end
	if self == t.frame then
		return true
	end
	local ah = ArkInventory.TraceGetAuctionFrame( )
	if ah and self == ah then
		return true
	end
	return false
end

local function ArkInventory_TraceWatchReset( )
	local t = ArkInventory.Trace
	if not t then
		return
	end
	t.watch = setmetatable( { }, { __mode = "k" } )
	t.watchCount = 0
end

local function ArkInventory_TraceWatchAdd( f )
	local t = ArkInventory.Trace
	if not t or not f then
		return
	end
	t.watch = t.watch or setmetatable( { }, { __mode = "k" } )
	if not t.watch[f] then
		t.watch[f] = true
		t.watchCount = (t.watchCount or 0) + 1
	end
end

local function ArkInventory_TraceWatchAddChildren( root, maxDepth, maxNodes )
	if not root or not root.GetChildren then
		return
	end
	maxDepth = tonumber( maxDepth ) or 1
	maxNodes = tonumber( maxNodes ) or 40
	if maxDepth < 0 or maxNodes < 1 then
		return
	end

	local t = ArkInventory.Trace
	local added = 0

	local function walk( node, depth )
		if not node or added >= maxNodes then
			return
		end
		ArkInventory_TraceWatchAdd( node )
		added = added + 1
		if depth <= 0 then
			return
		end
		local kids = { node:GetChildren( ) }
		for _, child in ipairs( kids ) do
			if added >= maxNodes then
				break
			end
			walk( child, depth - 1 )
		end
	end

	walk( root, maxDepth )

	if t and t.enabled and t.active then
		ArkInventory.TraceEvent( "WATCH", { root = ArkInventory_TraceSafeName( root ), depth = maxDepth, nodes = added, total = t.watchCount or 0 } )
	end
end

function ArkInventory:TraceHook_SetFrameLevel( obj, level )
	if not (ArkInventory.Trace and ArkInventory.Trace.enabled and ArkInventory.Trace.active) then
		return
	end
	if not ArkInventory_TraceIsWatchedFrame( obj ) then
		return
	end
	ArkInventory.TraceEvent( "HOOK_SET_LEVEL", {
		frame = ArkInventory_TraceSafeName( obj ),
		to = level,
		now = ArkInventory_TraceFrameLevel( obj ),
		stack = ArkInventory_TraceMaybeStack( ),
	} )
end

function ArkInventory:TraceHook_SetFrameStrata( obj, strata )
	if not (ArkInventory.Trace and ArkInventory.Trace.enabled and ArkInventory.Trace.active) then
		return
	end
	if not ArkInventory_TraceIsWatchedFrame( obj ) then
		return
	end
	ArkInventory.TraceEvent( "HOOK_SET_STRATA", {
		frame = ArkInventory_TraceSafeName( obj ),
		to = strata,
		now = ArkInventory_TraceFrameStrata( obj ),
		stack = ArkInventory_TraceMaybeStack( ),
	} )
end

function ArkInventory:TraceHook_SetToplevel( obj, isTop )
	if not (ArkInventory.Trace and ArkInventory.Trace.enabled and ArkInventory.Trace.active) then
		return
	end
	if not ArkInventory_TraceIsWatchedFrame( obj ) then
		return
	end
	ArkInventory.TraceEvent( "HOOK_SET_TOPLEVEL", {
		frame = ArkInventory_TraceSafeName( obj ),
		to = isTop and true or false,
		stack = ArkInventory_TraceMaybeStack( ),
	} )
end

function ArkInventory:TraceHook_SetParent( obj, parent )
	if not (ArkInventory.Trace and ArkInventory.Trace.enabled and ArkInventory.Trace.active) then
		return
	end
	if not ArkInventory_TraceIsWatchedFrame( obj ) then
		return
	end
	local now = obj and obj.GetParent and obj:GetParent( ) or nil
	ArkInventory.TraceEvent( "HOOK_SET_PARENT", {
		frame = ArkInventory_TraceSafeName( obj ),
		to = ArkInventory_TraceSafeName( parent ),
		now = ArkInventory_TraceSafeName( now ),
		stack = ArkInventory_TraceMaybeStack( ),
	} )
end

local function ArkInventory_TraceEnsureObjectHooks( frame )
	if not frame then
		return
	end

	local t = ArkInventory.Trace
	t.objHooked = t.objHooked or setmetatable( { }, { __mode = "k" } )
	if not t.objHooked[frame] then
		t.objHooked[frame] = { }
	end

	local function install( method, handler )
		if t.objHooked[frame][method] then
			return
		end

		local ok = false
		if hooksecurefunc and frame[method] then
			ok = pcall( hooksecurefunc, frame, method, handler )
		end

		t.objHooked[frame][method] = ok and true or "failed"
		if not ok and ArkInventory.Trace and ArkInventory.Trace.enabled then
			ArkInventory.TraceEvent( "HOOK_INSTALL_FAIL", { frame = ArkInventory_TraceSafeName( frame ), method = method } )
		end
	end

	install( "SetFrameLevel", function( self, level ) ArkInventory:TraceHook_SetFrameLevel( self, level ) end )
	install( "SetFrameStrata", function( self, strata ) ArkInventory:TraceHook_SetFrameStrata( self, strata ) end )
	install( "SetToplevel", function( self, isTop ) ArkInventory:TraceHook_SetToplevel( self, isTop ) end )
	install( "SetParent", function( self, parent ) ArkInventory:TraceHook_SetParent( self, parent ) end )
end

local function ArkInventory_TraceFramesOverlap( a, b )
	local al, ar, at, ab = ArkInventory_TraceFrameRect( a )
	local bl, br, bt, bb = ArkInventory_TraceFrameRect( b )
	if not al or not bl then
		return false
	end
	if ar < bl or br < al then return false end
	if at < bb or bt < ab then return false end
	return true
end

local function ArkInventory_TraceAbove( aStrata, aLevel, bStrata, bLevel )
	local ar = ARKINV_TRACE_STRATA_RANK[aStrata] or 0
	local br = ARKINV_TRACE_STRATA_RANK[bStrata] or 0
	if ar ~= br then
		return ar > br
	end
	return (aLevel or 0) > (bLevel or 0)
end

function ArkInventory.TraceEvent( tag, detail )
	local t = ArkInventory.Trace
	if not t or not t.enabled then
		return
	end

	t.cursor = (t.cursor or 0) + 1
	local idx = ((t.cursor - 1) % (t.maxEvents or 250)) + 1

	t.events[idx] = {
		ms = ArkInventory.TraceNowMS( ),
		tag = tag,
		detail = detail,
	}
end

function ArkInventory.TraceClear( )
	local t = ArkInventory.Trace
	t.cursor = 0
	t.events = { }
	t.anchorSuppressed = 0
	t.lastState = nil
end

function ArkInventory.TraceGetAuctionFrame( )
	if AuctionFrame and AuctionFrame.IsShown and AuctionFrame:IsShown( ) then
		return AuctionFrame
	end
	if AuctionHouseFrame and AuctionHouseFrame.IsShown and AuctionHouseFrame:IsShown( ) then
		return AuctionHouseFrame
	end
	return AuctionFrame or AuctionHouseFrame
end

function ArkInventory.TraceStateSample( frame )
	local t = ArkInventory.Trace
	local ah = ArkInventory.TraceGetAuctionFrame( )
	local function parentName( f )
		if f and f.GetParent then
			return ArkInventory_TraceSafeName( f:GetParent( ) )
		end
		return "nil"
	end
	local function effectiveStrata( f )
		if f and f.GetEffectiveFrameStrata then
			local ok, v = pcall( f.GetEffectiveFrameStrata, f )
			if ok and v then
				return v
			end
		end
		return "?"
	end
	local function isTop( f )
		if f and f.IsToplevel then
			local ok, v = pcall( f.IsToplevel, f )
			if ok then
				return v and true or false
			end
		end
		return false
	end

	local arkStrata = ArkInventory_TraceFrameStrata( frame )
	local arkLevel = ArkInventory_TraceFrameLevel( frame )
	local ahStrata = ArkInventory_TraceFrameStrata( ah )
	local ahLevel = ArkInventory_TraceFrameLevel( ah )
	local overlap = (frame and ah and ArkInventory_TraceFramesOverlap( frame, ah )) and true or false
	local arkAboveAh = ArkInventory_TraceAbove( arkStrata, arkLevel, ahStrata, ahLevel )

	local focus = GetMouseFocus and GetMouseFocus( ) or nil
	local focusName = ArkInventory_TraceSafeName( focus )
	local focusStrata = ArkInventory_TraceFrameStrata( focus )
	local focusLevel = ArkInventory_TraceFrameLevel( focus )

	local state = {
		arkStrata = arkStrata,
		arkEffStrata = effectiveStrata( frame ),
		arkLevel = arkLevel,
		arkParent = parentName( frame ),
		arkTop = isTop( frame ),
		ahName = ArkInventory_TraceSafeName( ah ),
		ahShown = (ah and ah.IsShown and ah:IsShown( )) and true or false,
		ahStrata = ahStrata,
		ahEffStrata = effectiveStrata( ah ),
		ahLevel = ahLevel,
		ahParent = parentName( ah ),
		ahTop = isTop( ah ),
		overlap = overlap,
		arkAboveAh = arkAboveAh,
		focusName = focusName,
		focusStrata = focusStrata,
		focusLevel = focusLevel,
	}

	local prev = t.lastState
	t.lastState = state

	if not prev then
		ArkInventory.TraceEvent( "START_STATE", state )
		return
	end

	if prev.overlap ~= state.overlap then
		ArkInventory.TraceEvent( "OVERLAP", { overlap = state.overlap, ah = state.ahName } )
	end
	if prev.arkStrata ~= state.arkStrata then
		ArkInventory.TraceEvent( "ARK_STRATA", { from = prev.arkStrata, to = state.arkStrata } )
	end
	if prev.arkEffStrata ~= state.arkEffStrata then
		ArkInventory.TraceEvent( "ARK_EFF_STRATA", { from = prev.arkEffStrata, to = state.arkEffStrata } )
	end
	if prev.arkLevel ~= state.arkLevel then
		ArkInventory.TraceEvent( "ARK_LEVEL", { from = prev.arkLevel, to = state.arkLevel } )
	end
	if prev.arkParent ~= state.arkParent then
		ArkInventory.TraceEvent( "ARK_PARENT", { from = prev.arkParent, to = state.arkParent } )
	end
	if prev.arkTop ~= state.arkTop then
		ArkInventory.TraceEvent( "ARK_TOP", { from = prev.arkTop, to = state.arkTop } )
	end
	if prev.ahStrata ~= state.ahStrata then
		ArkInventory.TraceEvent( "AH_STRATA", { from = prev.ahStrata, to = state.ahStrata, ah = state.ahName } )
	end
	if prev.ahEffStrata ~= state.ahEffStrata then
		ArkInventory.TraceEvent( "AH_EFF_STRATA", { from = prev.ahEffStrata, to = state.ahEffStrata, ah = state.ahName } )
	end
	if prev.ahLevel ~= state.ahLevel then
		ArkInventory.TraceEvent( "AH_LEVEL", { from = prev.ahLevel, to = state.ahLevel, ah = state.ahName } )
	end
	if prev.ahParent ~= state.ahParent then
		ArkInventory.TraceEvent( "AH_PARENT", { from = prev.ahParent, to = state.ahParent, ah = state.ahName } )
	end
	if prev.ahTop ~= state.ahTop then
		ArkInventory.TraceEvent( "AH_TOP", { from = prev.ahTop, to = state.ahTop, ah = state.ahName } )
	end
	if prev.arkAboveAh ~= state.arkAboveAh then
		ArkInventory.TraceEvent( "ABOVE", { arkAboveAh = state.arkAboveAh } )
	end
	if prev.focusName ~= state.focusName then
		ArkInventory.TraceEvent( "FOCUS", { focus = state.focusName, strata = state.focusStrata, level = state.focusLevel } )
	end
end

function ArkInventory.TraceOnUpdate( frame )
	local t = ArkInventory.Trace
	if not t.enabled or not t.active then
		return
	end

	local now = ArkInventory.TraceNowMS( )
	if t.lastUpdateMS and t.lastUpdateMS > 0 then
		local delta = now - t.lastUpdateMS
		if delta >= (t.stallThresholdMS or 500) then
			-- Record the last known state at the moment we detected the stall.
			-- (Copy it so future samples don't mutate the stored snapshot.)
			ArkInventory.TraceEvent( "STALL", { ms = delta, last = ArkInventory_TraceShallowCopy( t.lastState ) } )
			ArkInventory.OutputWarning( "aitrace: stall ", string.format( "%.0f", delta ), "ms (type /aitrace dump)" )
		end
	end
	t.lastUpdateMS = now

	if not t.lastSampleMS or (now - t.lastSampleMS) >= (t.sampleIntervalMS or 50) then
		t.lastSampleMS = now
		ArkInventory.TraceStateSample( frame )
	end
end

function ArkInventory.TraceDragStart( frame )
	local t = ArkInventory.Trace
	if not t.enabled then
		return
	end

	-- Do not auto-clear the ring buffer here.
	-- If a stall happens and the user starts another drag before dumping,
	-- auto-clearing would erase the evidence. Use /aitrace clear to reset.
	-- Reset per-drag counters/state instead.
	t.anchorSuppressed = 0
	t.lastState = nil
	t.lastStateMS = nil

	t.active = true
	t.frame = frame
	t.loc_id = frame and frame.ARK_Data and frame.ARK_Data.loc_id or nil
	t.startMS = ArkInventory.TraceNowMS( )
	t.lastUpdateMS = t.startMS
	t.lastSampleMS = 0
	t.sessionId = (t.sessionId or 0) + 1
	ArkInventory_TraceWatchReset( )
	ArkInventory_TraceWatchAdd( frame )

	ArkInventory.TraceEvent( "SESSION", { id = t.sessionId, loc_id = t.loc_id, frame = ArkInventory_TraceSafeName( frame ) } )

	ArkInventory.TraceEvent( "DRAG_START", { loc_id = t.loc_id, frame = ArkInventory_TraceSafeName( frame ) } )
	ArkInventory.TraceStateSample( frame )

	-- Hook SetFrameLevel/Strata/Toplevel on the relevant objects so we can see who changes layering.
	ArkInventory_TraceEnsureObjectHooks( frame )
	local ah = ArkInventory.TraceGetAuctionFrame( )
	ArkInventory_TraceWatchAdd( ah )
	ArkInventory_TraceEnsureObjectHooks( ah )

	-- Also watch a limited set of child frames; layering changes are often applied to subframes.
	ArkInventory_TraceWatchAddChildren( frame, 2, 40 )
	ArkInventory_TraceWatchAddChildren( ah, 2, 40 )

	-- Sanity check: issue no-op calls so we can confirm hooks are actually firing in real runs.
	pcall( function( ) if frame and frame.SetFrameLevel then frame:SetFrameLevel( frame:GetFrameLevel( ) ) end end )
	pcall( function( ) if frame and frame.SetFrameStrata then frame:SetFrameStrata( frame:GetFrameStrata( ) ) end end )
	pcall( function( ) if frame and frame.SetToplevel and frame.IsToplevel then frame:SetToplevel( frame:IsToplevel( ) ) end end )
	if ah then
		pcall( function( ) if ah.SetFrameLevel then ah:SetFrameLevel( ah:GetFrameLevel( ) ) end end )
		pcall( function( ) if ah.SetFrameStrata then ah:SetFrameStrata( ah:GetFrameStrata( ) ) end end )
		pcall( function( ) if ah.SetToplevel and ah.IsToplevel then ah:SetToplevel( ah:IsToplevel( ) ) end end )
	end

	if frame and frame.ARK_Data and frame.ARK_Data.dragShield and frame.ARK_Data.dragShield.SetScript then
		local shield = frame.ARK_Data.dragShield
		shield:SetScript( "OnUpdate", function( self, elapsed )
			ArkInventory.TraceOnUpdate( frame )
		end )
	end
end

function ArkInventory.TraceDragStop( frame )
	local t = ArkInventory.Trace
	if not t.enabled then
		return
	end

	ArkInventory.TraceEvent( "DRAG_STOP", { loc_id = t.loc_id, anchorSuppressed = t.anchorSuppressed } )
	ArkInventory.TraceStateSample( frame )

	if frame and frame.ARK_Data and frame.ARK_Data.dragShield and frame.ARK_Data.dragShield.SetScript then
		frame.ARK_Data.dragShield:SetScript( "OnUpdate", nil )
	end

	t.active = false
	t.frame = nil
	t.loc_id = nil
end

function ArkInventory.TraceDump( n )
	local t = ArkInventory.Trace
	n = tonumber( n ) or 25
	if n < 1 then n = 1 end
	if n > (t.maxEvents or 250) then n = (t.maxEvents or 250) end

	local total = math.min( t.cursor or 0, t.maxEvents or 250 )
	ArkInventory.Output( "aitrace: enabled=", t.enabled and "true" or "false", ", events=", total, ", anchorSuppressed=", t.anchorSuppressed or 0 )
	if total == 0 then
		return
	end

	local start = total - n + 1
	if start < 1 then start = 1 end

	for i = start, total do
		local idx = ((t.cursor - total + i - 1) % (t.maxEvents or 250)) + 1
		local e = t.events[idx]
		if e then
			ArkInventory.Output( "aitrace:", string.format( "%.0f", e.ms or 0 ), " ", e.tag or "?", " ", ArkInventory.OutputSerialize( e.detail ) )
		end
	end
end

function ArkInventory.TraceEnabledSet( value )
	local t = ArkInventory.Trace
	value = value and true or false
	t.enabled = value
	ArkInventory.Output( "aitrace is now ", value and "enabled" or "disabled" )
	if not value then
		ArkInventory.TraceClear( )
	end
end

function ArkInventory:ChatCommandTrace( input )
	input = (input and strtrim( input )) or ""
	local cmd, rest = input:match( "^(%S+)%s*(.-)%s*$" )
	cmd = (cmd and cmd:lower( )) or ""

	if cmd == "" or cmd == "help" then
		ArkInventory.Output( "aitrace commands: on | off | toggle | status | dump [n] | clear | test | stack off|top|full" )
		return
	end

	if cmd == "on" then
		ArkInventory.TraceEnabledSet( true )
		return
	elseif cmd == "off" then
		ArkInventory.TraceEnabledSet( false )
		return
	elseif cmd == "toggle" then
		ArkInventory.TraceEnabledSet( not ArkInventory.Trace.enabled )
		return
	elseif cmd == "status" then
		ArkInventory.Output( "aitrace: enabled=", ArkInventory.Trace.enabled and "true" or "false", ", active=", ArkInventory.Trace.active and "true" or "false" )
		return
	elseif cmd == "clear" then
		ArkInventory.TraceClear( )
		ArkInventory.Output( "aitrace cleared" )
		return
	elseif cmd == "dump" then
		ArkInventory.TraceDump( rest )
		return
	elseif cmd == "test" then
		local f = _G["ARKINV_Frame1"]
		local ah = ArkInventory.TraceGetAuctionFrame( )
		ArkInventory.Output( "aitrace test: ark=", ArkInventory.OutputSerialize( ArkInventory_TraceSafeName( f ) ), ", ah=", ArkInventory.OutputSerialize( ArkInventory_TraceSafeName( ah ) ) )
		if not f then
			ArkInventory.OutputWarning( "aitrace test: ARKINV_Frame1 not found/visible" )
			return
		end
		ArkInventory.TraceEnabledSet( true )
		ArkInventory.TraceClear( )
		ArkInventory.Trace.active = true
		ArkInventory.Trace.frame = f
		ArkInventory_TraceEnsureObjectHooks( f )
		if ah then
			ArkInventory_TraceEnsureObjectHooks( ah )
		end
		-- Trigger no-op calls that should still invoke our hook.
		pcall( function( ) if f.SetFrameLevel then f:SetFrameLevel( f:GetFrameLevel( ) ) end end )
		pcall( function( ) if f.SetFrameStrata then f:SetFrameStrata( f:GetFrameStrata( ) ) end end )
		pcall( function( ) if f.SetToplevel and f.IsToplevel then f:SetToplevel( f:IsToplevel( ) ) end end )
		if ah then
			pcall( function( ) if ah.SetFrameLevel then ah:SetFrameLevel( ah:GetFrameLevel( ) ) end end )
			pcall( function( ) if ah.SetFrameStrata then ah:SetFrameStrata( ah:GetFrameStrata( ) ) end end )
			pcall( function( ) if ah.SetToplevel and ah.IsToplevel then ah:SetToplevel( ah:IsToplevel( ) ) end end )
		end
		ArkInventory.Trace.active = false
		ArkInventory.Output( "aitrace test complete - run /aitrace dump 50 and look for HOOK_SET_* or HOOK_INSTALL_FAIL" )
		return
	elseif cmd == "stack" then
		rest = (rest and rest:lower( )) or ""
		if rest == "off" or rest == "top" or rest == "full" then
			ArkInventory.Trace.stackMode = rest
			ArkInventory.Output( "aitrace stack mode is now ", rest )
		else
			ArkInventory.Output( "aitrace stack mode is ", ArkInventory.Trace.stackMode or "top", " (use: /aitrace stack off|top|full)" )
		end
		return
	end

	ArkInventory.Output( "aitrace: unknown command '", cmd, "' (try /aitrace help)" )
end

-- Fallback slash command registration (in case AceConsole registration fails)
SLASH_ARKINVENTORY_AITRACE1 = "/aitrace"
SLASH_ARKINVENTORY_AITRACE2 = "/airtrace"
SlashCmdList["ARKINVENTORY_AITRACE"] = function( msg )
	if ArkInventory and ArkInventory.ChatCommandTrace then
		ArkInventory:ChatCommandTrace( msg )
	elseif DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage( "ArkInventory: trace command not ready" )
	end
end

