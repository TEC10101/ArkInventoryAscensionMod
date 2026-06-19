-- (c) 2009, all rights reserved.

ArkInventory = LibStub( "AceAddon-3.0" ):NewAddon( "ArkInventory", "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0", "AceBucket-3.0" )

ArkInventory.Localise = LibStub( "AceLocale-3.0" ):GetLocale( "ArkInventory" )

ArkInventory.Lib = { -- libraries live here

	DewDrop = LibStub( "Dewdrop-2.0" ),

	PeriodicTable = LibStub( "LibPeriodicTable-3.1" ),
	Config = LibStub( "AceConfig-3.0" ),
	Dialog = LibStub( "AceConfigDialog-3.0" ),

	SharedMedia = LibStub( "LibSharedMedia-3.0" ),
	DataBroker = LibStub( "LibDataBroker-1.1" ),

}

ArkInventory.db = { }

ArkInventory.Table = { } -- table functions live here, coded elsewhere

function ArkInventory.UISpecialFramesIndex( name )

	if not UISpecialFrames or not name then
		return
	end

	for i, v in ipairs( UISpecialFrames ) do
		if v == name then
			return i
		end
	end

end

function ArkInventory.UISpecialFramesRemoveAll( name )

	if not UISpecialFrames or not name then
		return
	end

	for i = #UISpecialFrames, 1, -1 do
		if UISpecialFrames[i] == name then
			tremove( UISpecialFrames, i )
		end
	end

end

function ArkInventory.UISpecialFramesInsertAt( name, idx )

	if not UISpecialFrames or not name then
		return
	end

	idx = tonumber( idx ) or ( #UISpecialFrames + 1 )
	if idx < 1 then
		idx = 1
	elseif idx > ( #UISpecialFrames + 1 ) then
		idx = #UISpecialFrames + 1
	end

	tinsert( UISpecialFrames, idx, name )

end

function ArkInventory.VaultUISpecialFramesOrderSet( loc_id, enable )

	if not UISpecialFrames then
		return
	end

	if not loc_id then
		return
	end

	local frame = ArkInventory.Frame_Main_Get and ArkInventory.Frame_Main_Get( loc_id )
	if not frame or not frame.GetName then
		return
	end

	local name = frame:GetName( )
	if not name then
		return
	end

	ArkInventory.Global.Mode.VaultSpecialFrames = ArkInventory.Global.Mode.VaultSpecialFrames or { }
	local store = ArkInventory.Global.Mode.VaultSpecialFrames

	if enable then

		local current = ArkInventory.UISpecialFramesIndex( name )
		local guild = ArkInventory.UISpecialFramesIndex( "GuildBankFrame" )
		if not current or not guild then
			return
		end

		-- If our Ark frame is after GuildBankFrame, ESC will hide GuildBankFrame first.
		-- That can leave the underlying guild bank session open (but invisible), which
		-- prevents reopening until you move away. Move Ark frame to before GuildBankFrame
		-- for the duration of personal/realm sessions.
		if current > guild then
			if not store[name] then
				store[name] = current
			end
			ArkInventory.UISpecialFramesRemoveAll( name )
			guild = ArkInventory.UISpecialFramesIndex( "GuildBankFrame" )
			ArkInventory.UISpecialFramesInsertAt( name, guild or ( #UISpecialFrames + 1 ) )
		end

	else

		local original = store[name]
		if original then
			ArkInventory.UISpecialFramesRemoveAll( name )
			ArkInventory.UISpecialFramesInsertAt( name, original )
			store[name] = nil
		end

	end

end

ArkInventory.Const = { -- constants

	TOC = select( 4, GetBuildInfo( ) ) or 0,  -- /run print( ArkInventory.Const.TOC )

	Program = {
		Name = "ArkInventory",
		Version = 3.1402,
		UIVersion = "3.14.02",
		--Beta = "Beta xx-xx",
	},

	Frame = {
		Main = {
			Name = "ARKINV_Frame",
		},
		Title = {
			Name = "Title",
			Height = 58,
			Height2 = 40,
		},
		Container = {
			Name = "Container",
		},
		Log = {
			Name = "Log",
		},
		Info = {
			Name = "Info",
		},
		Changer = {
			Name = "Changer",
			Height = 58,
		},
		Status = {
			Name = "Status",
			Height = 40,
		},
		Search = {
			Name = "Search",
			Height = 40,
		},
		Scrolling = {
			List = "List",
			ScrollBar = "ScrollBar",
		},
		Config = {
			Internal = "ArkInventory",
			Blizzard = "ArkInventoryConfigBlizzard",
		},
	},

	Debug = false,

	Profiler = false,

	Event = {
		BagUpdate = 1,
		--ObjectLock = 2,
		--PlayerMoney = 3,
		--GuildMoney = 4,
		--TabInfo = 5,
		--SkillUpdate = 6,
		--ItemUpdate = 7,
	},

	Location = {
		Bag = 1,
		Key = 2,
		Bank = 3,
		Vault = 4,
		Mail = 5,
		Wearing = 6,
		Pet = 7,
		Mount = 8,
		Token = 9,
		PersonalBank = 10,
		RealmBank = 11,
	},

	Offset = {
		Vault = 1000,
		Mail = 2000,
		Wearing = 3000,
		Pet = 4000,
		Token = 5000,
		Mount = 6000,
		PersonalBank = 7000,
		RealmBank = 8000,
	},

	Bag = {
		Status = { -- these need to be negative values,  do not use -1 (false)
			Unknown = -2,
			Active = -3,
			Empty = -4,
			Purchase = -5,
			NoAccess = -6,
		},
	},

	Slot = {

		Type = { -- slot type numbers, do not change this order, just add new ones to the end of the list
			Unknown = 0,
			Bag = 1,
			Key = 3,
			Soulshard = 5,
			Herb = 6,
			Enchanting = 7,
			Engineering = 8,
			Gem = 9,
			Mining = 10,
			Bullet = 11,
			Arrow = 12,
			Leatherworking = 13,
			Wearing = 14,
			Mail = 15,
			Inscription = 16,
			Critter = 17,
			Mount = 18,
			Token = 19,
		},

		New = {
			No = false,
			Yes = 1,
			Inc = 2,
			Dec = 3,
		},

		DefaultColour = { r = 0.3, g = 0.3, b = 0.3 },

		Data = { },

	},

	Anchor = {
		Automatic = 0,
		BottomRight = 1,
		BottomLeft = 2,
		TopLeft = 3,
		TopRight = 4,
		Top = 5,
		Bottom = 6,
		Left = 7,
		Right = 8,
	},

	Direction = {
		Horizontal = 1,
		Vertical = 2,
	},

	Window = {

		Offset = 9, -- hardcoded padding size for gap inside container

		Min = {
			Rows = 1,
			Columns = 6,
			Width = 400,
			Height = 40,
		},

		Draw = {
			Init = 0, -- first time
			Recalculate = 1, -- calculate
			Resort = 1, -- sort
			Refresh = 3, -- item changes
			None = 4, -- nothing
		},

		Title = {
			SizeNormal = 1,
			SizeThin = 2,
		},
	},

	Font = {
		Face = [[Friz Quadrata TT]],
		Size = 12,
	},

	Fade = 0.6,
	GuildTag = "+",
	RealmBankTag = "#",

	InventorySlotName = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot", "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot" },

	Category = {

		Max = 8999,

		Type = {
			System = 1,
			Custom = 2,
			Rule = 3,
		},

		Code = {
			System = { -- do NOT change the indicies - if you have to then see the ConvertOldOptions( ) function to remap it
				[401] = {
					["id"] = "SYSTEM_DEFAULT",
					["text"] = ArkInventory.Localise["CATEGORY_SYSTEM_DEFAULT"],
				},
				[402] = {
					["id"] = "SYSTEM_TRASH",
					["text"] = ArkInventory.Localise["CATEGORY_SYSTEM_TRASH"],
				},
				[403] = {
					["id"] = "SYSTEM_SOULBOUND",
					["text"] = ArkInventory.Localise["CATEGORY_SYSTEM_SOULBOUND"],
				},
				[405] = {
					["id"] = "SYSTEM_CONTAINER",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER"],
				},
				[406] = {
					["id"] = "SYSTEM_KEY",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_KEY"],
				},
				[407] = {
					["id"] = "SYSTEM_MISC",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_MISC"],
				},
				[408] = {
					["id"] = "SYSTEM_REAGENT",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_MISC_REAGENT"],
				},
				[409] = {
					["id"] = "SYSTEM_RECIPE",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_RECIPE"],
				},
				[410] = {
					["id"] = "SYSTEM_PROJECTILE",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_PROJECTILE"],
				},
				[411] = {
					["id"] = "SYSTEM_QUEST",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_QUEST"],
				},
				[413] = {
					["id"] = "SYSTEM_SOULSHARD",
					["text"] = ArkInventory.Localise["CATEGORY_SYSTEM_SOULSHARD"],
				},
				[414] = {
					["id"] = "SYSTEM_EQUIPMENT",
					["text"] = ArkInventory.Localise["CATEGORY_SYSTEM_EQUIPMENT"],
				},
--[[
				[415] = {
					["id"] = "SYSTEM_MOUNT",
					["text"] = ArkInventory.Localise["WOW_SKILL_RIDING"],
				},
]]--
				[416] = {
					["id"] = "SYSTEM_EQUIPMENT_SOULBOUND",
					["text"] = ArkInventory.Localise["CATEGORY_SYSTEM_EQUIPMENT_SOULBOUND"],
				},
				[421] = {
					["id"] = "SYSTEM_PROJECTILE_BULLET",
					["text"] = string.format( "%s (%s)", ArkInventory.Localise["WOW_ITEM_TYPE_PROJECTILE"], ArkInventory.Localise["WOW_ITEM_TYPE_PROJECTILE_BULLET"] ),
				},
				[422] = {
					["id"] = "SYSTEM_PROJECTILE_ARROW",
					["text"] = string.format( "%s (%s)", ArkInventory.Localise["WOW_ITEM_TYPE_PROJECTILE"], ArkInventory.Localise["WOW_ITEM_TYPE_PROJECTILE_ARROW"] ),
				},
				[423] = {
					["id"] = "SYSTEM_PET",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_MISC_PET"],
				},
				[428] = {
					["id"] = "SYSTEM_REPUTATION",
					["text"] = ArkInventory.Localise["CATEGORY_SYSTEM_REPUTATION"],
				},
				[429] = {
					["id"] = "SYSTEM_UNKNOWN",
					["text"] = ArkInventory.Localise["UNKNOWN"],
				},
				[434] = {
					["id"] = "SYSTEM_GEM",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_GEM"],
				},
				[438] = {
					["id"] = "SYSTEM_TOKEN",
					["text"] = ArkInventory.Localise["CATEGORY_SYSTEM_TOKEN"],
				},
				[439] = {
					["id"] = "SYSTEM_GLYPH",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_GLYPH"],
				},
			},
			Consumable = {
				[404] = {
					["id"] = "CONSUMABLE",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE"],
				},
				[417] = {
					["id"] = "CONSUMABLE_FOOD",
					["text"] = ArkInventory.Localise["CATEGORY_CONSUMABLE_FOOD"],
				},
				[418] = {
					["id"] = "CONSUMABLE_DRINK",
					["text"] = ArkInventory.Localise["CATEGORY_CONSUMABLE_DRINK"],
				},
				[419] = {
					["id"] = "CONSUMABLE_POTION_MANA",
					["text"] = ArkInventory.Localise["CATEGORY_CONSUMABLE_POTION_MANA"],
				},
				[420] = {
					["id"] = "CONSUMABLE_POTION_HEAL",
					["text"] = ArkInventory.Localise["CATEGORY_CONSUMABLE_POTION_HEAL"],
				},
				[424] = {
					["id"] = "CONSUMABLE_POTION",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_POTION"],
				},
				[430] = {
					["id"] = "CONSUMABLE_ELIXIR",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_ELIXIR"],
				},
				[431] = {
					["id"] = "CONSUMABLE_FLASK",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_FLASK"],
				},
				[432] = {
					["id"] = "CONSUMABLE_BANDAGE",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_BANDAGE"],
				},
				[433] = {
					["id"] = "CONSUMABLE_SCROLL",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_SCROLL"],
				},
				[435] = {
					["id"] = "CONSUMABLE_ELIXIR_BATTLE",
					["text"] = ArkInventory.Localise["CATEGORY_CONSUMABLE_ELIXIR_BATTLE"],
				},
				[436] = {
					["id"] = "CONSUMABLE_ELIXIR_GUARDIAN",
					["text"] = ArkInventory.Localise["CATEGORY_CONSUMABLE_ELIXIR_GUARDIAN"],
				},
				[437] = {
					["id"] = "CONSUMABLE_FOOD_AND_DRINK",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONSUMABLE_FOOD_AND_DRINK"],
				},
			},
			Trade = {
				[412] = {
					["id"] = "TRADE_GOODS",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS"],
				},
				[425] = {
					["id"] = "TRADE_GOODS_DEVICES",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_DEVICES"],
				},
				[426] = {
					["id"] = "TRADE_GOODS_EXPLOSIVES",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_EXPLOSIVES"],
				},
				[427] = {
					["id"] = "TRADE_GOODS_PARTS",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_PARTS"],
				},
				[501] = {
					["id"] = "TRADE_GOODS_HERB",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_HERB"],
				},
				[502] = {
					["id"] = "TRADE_GOODS_CLOTH",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_CLOTH"],
				},
				[503] = {
					["id"] = "TRADE_GOODS_ELEMENTAL",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_ELEMENTAL"],
				},
				[504] = {
					["id"] = "TRADE_GOODS_LEATHER",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_LEATHER"],
				},
				[505] = {
					["id"] = "TRADE_GOODS_MEAT",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_MEAT"],
				},
				[506] = {
					["id"] = "TRADE_GOODS_METAL_AND_STONE",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_METAL_AND_STONE"],
				},
				[507] = {
					["id"] = "TRADE_GOODS_MATERIALS",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_MATERIALS"],
				},
				[508] = {
					["id"] = "TRADE_GOODS_ENCHANTMENT_ARMOR",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_ENCHANTMENT_ARMOR"],
				},
				[509] = {
					["id"] = "TRADE_GOODS_ENCHANTMENT_WEAPON",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_TRADE_GOODS_ENCHANTMENT_WEAPON"],
				},
			},
			Skill = { -- do NOT change the indicies
				[101] = {
					["id"] = "SKILL_ALCHEMY",
					["text"] = ArkInventory.Localise["WOW_SKILL_ALCHEMY"],
				},
				[102] = {
					["id"] = "SKILL_BLACKSMITHING",
					["text"] = ArkInventory.Localise["WOW_SKILL_BLACKSMITHING"],
				},
				[103] = {
					["id"] = "SKILL_COOKING",
					["text"] = ArkInventory.Localise["WOW_SKILL_COOKING"],
				},
				[104] = {
					["id"] = "SKILL_ENGINEERING",
					["text"] = ArkInventory.Localise["WOW_SKILL_ENGINEERING"],
				},
				[105] = {
					["id"] = "SKILL_ENCHANTING",
					["text"] = ArkInventory.Localise["WOW_SKILL_ENCHANTING"],
				},
				[106] = {
					["id"] = "SKILL_FIRST_AID",
					["text"] = ArkInventory.Localise["WOW_SKILL_FIRST_AID"],
				},
				[107] = {
					["id"] = "SKILL_FISHING",
					["text"] = ArkInventory.Localise["WOW_SKILL_FISHING"],
				},
				[108] = {
					["id"] = "SKILL_HERBALISM",
					["text"] = ArkInventory.Localise["WOW_SKILL_HERBALISM"],
				},
				[109] = {
					["id"] = "SKILL_JEWELCRAFTING",
					["text"] = ArkInventory.Localise["WOW_SKILL_JEWELCRAFTING"],
				},
				[110] = {
					["id"] = "SKILL_LEATHERWORKING",
					["text"] = ArkInventory.Localise["WOW_SKILL_LEATHERWORKING"],
				},
				[111] = {
					["id"] = "SKILL_MINING",
					["text"] = ArkInventory.Localise["WOW_SKILL_MINING"],
				},
				[112] = {
					["id"] = "SKILL_SKINNING",
					["text"] = ArkInventory.Localise["WOW_SKILL_SKINNING"],
				},
				[113] = {
					["id"] = "SKILL_TAILORING",
					["text"] = ArkInventory.Localise["WOW_SKILL_TAILORING"],
				},
				[114] = {
					["id"] = "SKILL_RIDING",
					["text"] = ArkInventory.Localise["WOW_SKILL_RIDING"],
				},
				[115] = {
					["id"] = "SKILL_INSCRIPTION",
					["text"] = ArkInventory.Localise["WOW_SKILL_INSCRIPTION"],
				},
			},
			Class = {
				[201] = {
					["id"] = "CLASS_DRUID",
					["text"] = ArkInventory.Localise["WOW_CLASS_DRUID"],
				},
				[202] = {
					["id"] = "CLASS_HUNTER",
					["text"] = ArkInventory.Localise["WOW_CLASS_HUNTER"],
				},
				[203] = {
					["id"] = "CLASS_MAGE",
					["text"] = ArkInventory.Localise["WOW_CLASS_MAGE"],
				},
				[204] = {
					["id"] = "CLASS_PALADIN",
					["text"] = ArkInventory.Localise["WOW_CLASS_PALADIN"],
				},
				[205] = {
					["id"] = "CLASS_PRIEST",
					["text"] = ArkInventory.Localise["WOW_CLASS_PRIEST"],
				},
				[206] = {
					["id"] = "CLASS_ROGUE",
					["text"] = ArkInventory.Localise["WOW_CLASS_ROGUE"],
				},
				[207] = {
					["id"] = "CLASS_SHAMAN",
					["text"] = ArkInventory.Localise["WOW_CLASS_SHAMAN"],
				},
				[208] = {
					["id"] = "CLASS_WARLOCK",
					["text"] = ArkInventory.Localise["WOW_CLASS_WARLOCK"],
				},
				[209] = {
					["id"] = "CLASS_WARRIOR",
					["text"] = ArkInventory.Localise["WOW_CLASS_WARRIOR"],
				},
				[210] = {
					["id"] = "CLASS_DEATHKNIGHT",
					["text"] = ArkInventory.Localise["WOW_CLASS_DEATHKNIGHT"],
				},
			},
			Empty = {
				[300] = {
					["id"] = "EMPTY_UNKNOWN",
					["text"] = ArkInventory.Localise["UNKNOWN"],
				},
				[301] = {
					["id"] = "EMPTY",
					["text"] = ArkInventory.Localise["CATEGORY_EMPTY"],
				},
				[302] = {
					["id"] = "EMPTY_BAG",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_BAG"],
				},
				[303] = {
					["id"] = "EMPTY_KEY",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_KEY"],
				},
				[304] = {
					["id"] = "EMPTY_SOULSHARD",
					["text"] = ArkInventory.Localise["CATEGORY_SYSTEM_SOULSHARD"],
				},
				[305] = {
					["id"] = "EMPTY_HERB",
					["text"] = ArkInventory.Localise["WOW_SKILL_HERBALISM"],
				},
				[306] = {
					["id"] = "EMPTY_ENCHANTING",
					["text"] = ArkInventory.Localise["WOW_SKILL_ENCHANTING"],
				},
				[307] = {
					["id"] = "EMPTY_ENGINEERING",
					["text"] = ArkInventory.Localise["WOW_SKILL_ENGINEERING"],
				},
				[308] = {
					["id"] = "EMPTY_GEM",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_GEM"],
				},
				[309] = {
					["id"] = "EMPTY_MINING",
					["text"] = ArkInventory.Localise["WOW_SKILL_MINING"],
				},
				[312] = {
					["id"] = "EMPTY_LEATHERWORKING",
					["text"] = ArkInventory.Localise["WOW_SKILL_LEATHERWORKING"],
				},
				[310] = {
					["id"] = "EMPTY_PROJECTILE_BULLET",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_PROJECTILE_BULLET"],
				},
				[311] = {
					["id"] = "EMPTY_PROJECTILE_ARROW",
					["text"] = ArkInventory.Localise["WOW_ITEM_TYPE_PROJECTILE_ARROW"],
				},
				[313] = {
					["id"] = "EMPTY_INSCRIPTION",
					["text"] = ArkInventory.Localise["WOW_SKILL_INSCRIPTION"],
				},
			},
			Other = { -- do NOT change the indicies - if you have to then see the ConvertOldOptions( ) function to remap it
				[901] = {
					["id"] = "SYSTEM_CORE_MATS",
					["text"] = ArkInventory.Localise["CATEGORY_SYSTEM_CORE_MATS"],
				},
				[902] = {
					["id"] = "CONSUMABLE_FOOD_PET",
					["text"] = ArkInventory.Localise["CATEGORY_CONSUMABLE_FOOD_PET"],
				},
			},
		},

	},

	Texture = {
		Missing = [[Interface\Icons\Temp]],
		Empty = {
			Item = [[Interface\PaperDoll\UI-Backpack-EmptySlot]], -- [[Interface\PaperDoll\UI-Backpack-EmptySlot]]
			Ammo = [[Interface\paperDoll\UI-PaperDoll-Slot-Ammo]], -- [[Interface\paperDoll\UI-PaperDoll-Slot-Ammo]]
			Bag = [[Interface\PaperDoll\UI-PaperDoll-Slot-Bag]], -- [[Interface\PaperDoll\UI-PaperDoll-Slot-Bag]]
		},

		BackgroundDefault = "Solid",

		BorderDefault = "Blizzard Tooltip",
		BorderNone = "None",

		Border = {
			["Blizzard Tooltip"] = {
				["size"] = 16,
				["offset"] = 3,
				["scale"] = 1,
			},
			["Blizzard Dialog"] = {
				["size"] = 32,
				["offset"] = 9,
			},
			["Blizzard Dialog Gold"] = {
				["size"] = 32,
				["offset"] = 9,
			},
			["ArkInventory Tooltip 1"] = {
				["size"] = 16,
				["offset"] = 3,
			},
			["ArkInventory Tooltip 2"] = {
				["size"] = 16,
				["offset"] = 4,
			},
			["ArkInventory Tooltip 3"] = {
				["size"] = 16,
				["offset"] = 5,
			},
			["ArkInventory Square 1"] = {
				["size"] = 16,
				["offset"] = 3,
			},
			["ArkInventory Square 2"] = {
				["size"] = 16,
				["offset"] = 4,
			},
			["ArkInventory Square 3"] = {
				["size"] = 16,
				["offset"] = 5,
			},
		},

	},

	Actions = {
		[11] = {
			Texture = [[Interface\Icons\Trade_Engineering]],
			Name = ArkInventory.Localise["MENU_ACTION_EDITMODE"],
			LDB = true,
			Scripts = {
				OnClick = function( self )
					ArkInventory.ToggleEditMode( )
				end,
				OnEnter = function( self )
					ArkInventory.GameTooltipSetText( self, ArkInventory.Localise["MENU_ACTION_EDITMODE"] )
				end,
			},
		},
		[12] = {
			Texture = [[Interface\Icons\INV_Misc_Book_10]], --Interface\Icons\INV_Gizmo_02    INV_Misc_Note_05
			Name = ArkInventory.Localise["CONFIG_RULES"],
			LDB = true,
			Scripts = {
				OnClick = function( self )
					local loc_id
					if self.GetParent and self:GetParent( ) and self:GetParent( ):GetParent( ) then
						loc_id = self:GetParent( ):GetParent( ):GetID( )
					end
					ArkInventory.Frame_Rules_Toggle( loc_id )
				end,
				OnEnter = function( self )
					ArkInventory.GameTooltipSetText( self, ArkInventory.Localise["CONFIG_RULES"] )
				end,
			},
		},
		[13] = {
			Texture = [[Interface\Minimap\Tracking\None]], --Interface\Icons\INV_Misc_EngGizmos_20
			Name = ArkInventory.Localise["CONFIG_SEARCH"],
			LDB = true,
			Scripts = {
				OnClick = function( self, button )
					if button == "LeftButton" then
						ArkInventory.Frame_Search_Toggle( )
					elseif button == "RightButton" then
						local loc_id = self:GetParent( ):GetParent( ):GetID( )
						if ArkInventory.Global.Location[loc_id].canSearch then
							local v = not ArkInventory.LocationOptionGet( loc_id, { "search", "hide" } )
							ArkInventory.Global.Location[loc_id].filter = nil
							ArkInventory.LocationOptionSet( loc_id, { "search", "hide" }, v )
							ArkInventory.Frame_Main_Generate( nil, ArkInventory.Const.Window.Draw.Refresh )
						end
					end
				end,
				OnEnter = function( self )
					ArkInventory.GameTooltipSetText( self, ArkInventory.Localise["CONFIG_SEARCH"] )
				end,
			},
		},
		[14] = {
			Texture = [[Interface\Icons\INV_Misc_GroupLooking]],
			Name = ArkInventory.Localise["MENU_CHARACTER_SWITCH"],
			Scripts = {
				OnClick = function( self )
					ArkInventory.MenuSwitchCharacterOpen( self:GetParent( ):GetParent( ) )
				end,
				OnEnter = function( self )
					ArkInventory.GameTooltipSetText( self, ArkInventory.Localise["MENU_CHARACTER_SWITCH"] )
				end,
			},
		},
		[21] = {
			Texture = [[Interface\Icons\INV_Helmet_47]],
			Name = ArkInventory.Localise["MENU_LOCATION_SWITCH"],
			Scripts = {
				OnClick = function( self )
					ArkInventory.MenuSwitchLocationOpen( )
				end,
				OnEnter = function( self )
					ArkInventory.GameTooltipSetText( self, ArkInventory.Localise["MENU_LOCATION_SWITCH"] )
				end,
			},
		},
		[22] = {
			Texture = [[Interface\Icons\Spell_Shadow_DestructiveSoul]],
			Name = ArkInventory.Localise["RESTACK"],
			LDB = true,
			Scripts = {
				OnClick = function( self )
					ArkInventory.Restack( )
				end,
				OnEnter = function( self )
					ArkInventory.GameTooltipSetText( self, ArkInventory.Localise["RESTACK"] )
				end,
			},
		},
		[23] = {
			Texture = [[Interface\Icons\INV_Misc_EngGizmos_17]],
			Name = ArkInventory.Localise["MENU_ACTION_BAGCHANGER"],
			Scripts = {
				OnClick = function( self )
					ArkInventory.ToggleChanger( self:GetParent( ):GetParent( ):GetID( ) )
				end,
				OnEnter = function( self )
					ArkInventory.GameTooltipSetText( self, ArkInventory.Localise["MENU_ACTION_BAGCHANGER"] )
				end,
			},
		},
		[24] = {
			Texture = [[Interface\Icons\Spell_Frost_Stun]],
			Name = ArkInventory.Localise["MENU_ACTION_REFRESH"],
			Scripts = {
				OnClick = function( self )
					ArkInventory.Frame_Main_Generate( nil, ArkInventory.Const.Window.Draw.Resort )
				end,
				OnEnter = function( self )
					ArkInventory.GameTooltipSetText( self, ArkInventory.Localise["MENU_ACTION_REFRESH"] )
				end,
			},
		},
		[91] = {
			Name = ArkInventory.Localise["MENU_ACTION_REFRESH"],
			Scripts = {
				OnClick = function( self )
					-- menu
				end,
				OnEnter = function( self )
					ArkInventory.GameTooltipSetText( self, "change tracking" )
				end,
			},
		},
	},

	SortKeys = { -- true = keep, false = remove
		category = true,
		location = true,
		itemuselevel = true,
		itemstatlevel = true,
		itemtype = true,
		quality = true,
		name = true,
		vendorprice = true,
		itemage = true,
	},

	Skills = "ALCHEMY,BLACKSMITHING,ENCHANTING,ENGINEERING,JEWELCRAFTING,INSCRIPTION,LEATHERWORKING,TAILORING,HERBALISM,MINING,SKINNING,COOKING,FIRST_AID,FISHING,RIDING", -- primary craft, primary collect, secondary

	DatabaseDefaults = { },

}

ArkInventory.Const.Slot.Data = {
	[ArkInventory.Const.Slot.Type.Unknown] = {
		["name"] = ArkInventory.Localise["UNKNOWN"],
		["long"] = ArkInventory.Localise["UNKNOWN"],
		["type"] = ArkInventory.Localise["UNKNOWN"],
		["colour"] = { r = 1.0, g = 0.0, b = 0.0 }, -- red
	},
	[ArkInventory.Const.Slot.Type.Key] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_KEY"],
		["long"] = ArkInventory.Localise["WOW_ITEM_TYPE_KEY"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_KEY"],
		["colour"] = { r = 1.0, g = 1.0, b = 0.0 }, -- yellow,
		["hide"] = true,
	},
	[ArkInventory.Const.Slot.Type.Bag] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_BAG"],
		["long"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_BAG"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_BAG"],
		["colour"] = ArkInventory.Const.Slot.DefaultColour,
	},
	[ArkInventory.Const.Slot.Type.Soulshard] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_SOULSHARD"],
		["long"] = ArkInventory.Localise["CATEGORY_SYSTEM_SOULSHARD"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_SOULSHARD"],
		["colour"] = { r = 1.0, g = 0.0, b = 1.0 }, -- magenta
	},
	[ArkInventory.Const.Slot.Type.Herb] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_HERB"],
		["long"] = ArkInventory.Localise["WOW_SKILL_HERBALISM"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_HERB"],
		["colour"] = { r = 0.0, g = 1.0, b = 0.0 }, -- green
	},
	[ArkInventory.Const.Slot.Type.Enchanting] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_ENCHANTING"],
		["long"] = ArkInventory.Localise["WOW_SKILL_ENCHANTING"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_ENCHANTING"],
		["colour"] = { r = 0.0, g = 0.0, b = 1.0 }, -- blue
	},
	[ArkInventory.Const.Slot.Type.Engineering] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_ENGINEERING"],
		["long"] = ArkInventory.Localise["WOW_SKILL_ENGINEERING"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_ENGINEERING"],
		["colour"] = ArkInventory.Const.Slot.DefaultColour,
	},
	[ArkInventory.Const.Slot.Type.Gem] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_GEM"],
		["long"] = ArkInventory.Localise["WOW_ITEM_TYPE_GEM"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_GEM"],
		["colour"] = ArkInventory.Const.Slot.DefaultColour,
	},
	[ArkInventory.Const.Slot.Type.Mining] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_MINING"],
		["long"] = ArkInventory.Localise["WOW_SKILL_MINING"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_MINING"],
		["colour"] = ArkInventory.Const.Slot.DefaultColour,
	},
	[ArkInventory.Const.Slot.Type.Leatherworking] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_LEATHERWORKING"],
		["long"] = ArkInventory.Localise["WOW_SKILL_LEATHERWORKING"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_LEATHERWORKING"],
		["colour"] = ArkInventory.Const.Slot.DefaultColour,
	},
	[ArkInventory.Const.Slot.Type.Inscription] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_INSCRIPTION"],
		["long"] = ArkInventory.Localise["WOW_SKILL_INSCRIPTION"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_INSCRIPTION"],
		["colour"] = ArkInventory.Const.Slot.DefaultColour,
	},
	[ArkInventory.Const.Slot.Type.Bullet] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_PROJECTILE_BULLET"],
		["long"] = ArkInventory.Localise["WOW_ITEM_TYPE_QUIVER_BULLET"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_QUIVER_BULLET"],
		["texture"] = ArkInventory.Const.Texture.Empty.Ammo,
		["colour"] = { r = 1.0, g = 0.5, b = 0.15 }, -- orange
		["emptycolour"] = GREEN_FONT_COLOR_CODE, -- status text colour when no slots left
	},
	[ArkInventory.Const.Slot.Type.Arrow] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_PROJECTILE_ARROW"],
		["long"] = ArkInventory.Localise["WOW_ITEM_TYPE_QUIVER_ARROW"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_QUIVER_ARROW"],
		["texture"] = ArkInventory.Const.Texture.Empty.Ammo,
		["colour"] = { r = 1.0, g = 0.5, b = 0.15 }, -- orange
		["emptycolour"] = GREEN_FONT_COLOR_CODE, -- status text colour when no slots left
	},
	[ArkInventory.Const.Slot.Type.Wearing] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_GEAR"],
		["long"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_BAG"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_BAG"],
		["colour"] = ArkInventory.Const.Slot.DefaultColour,
		["emptycolour"] = GREEN_FONT_COLOR_CODE, -- status text colour when no slots left
		["hide"] = true,
	},
	[ArkInventory.Const.Slot.Type.Mail] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_MAIL"],
		["long"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_BAG"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_BAG"],
		["colour"] = ArkInventory.Const.Slot.DefaultColour,
		["emptycolour"] = GREEN_FONT_COLOR_CODE, -- status text colour when no slots left
		["hide"] = true,
	},
	[ArkInventory.Const.Slot.Type.Critter] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_CRITTER"],
		["long"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_BAG"],
		["type"] = ArkInventory.Localise["WOW_ITEM_TYPE_MISC_PET"],
		["colour"] = ArkInventory.Const.Slot.DefaultColour,
		["emptycolour"] = GREEN_FONT_COLOR_CODE, -- status text colour when no slots left
		["hide"] = true,
	},
	[ArkInventory.Const.Slot.Type.Mount] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_MOUNT"],
		["long"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_BAG"],
		["type"] = ArkInventory.Localise["WOW_SKILL_RIDING"],
		["colour"] = ArkInventory.Const.Slot.DefaultColour,
		["emptycolour"] = GREEN_FONT_COLOR_CODE, -- status text colour when no slots left
		["hide"] = true,
	},
	[ArkInventory.Const.Slot.Type.Token] = {
		["name"] = ArkInventory.Localise["STATUS_NAME_TOKEN"],
		["long"] = ArkInventory.Localise["WOW_ITEM_TYPE_CONTAINER_BAG"],
		["type"] = ArkInventory.Localise["CATEGORY_SYSTEM_TOKEN"],
		["colour"] = ArkInventory.Const.Slot.DefaultColour,
		["emptycolour"] = GREEN_FONT_COLOR_CODE, -- status text colour when no slots left
		["hide"] = true,
	},
}

ArkInventory.Global = { -- globals

	Version = "", --calculated

	Me = nil,

	Mode = {
		Bank = false,
		Vault = false,
		VaultContext = nil,
		VaultLocation = nil,
		VaultSuppressLeave = false,
		VaultUIUnhooked = false,
		Mail = false,
		Merchant = false,

		Edit = false,
		Combat = false,
	},

	-- used to trigger a resort once bag updates have been processed
	EmptyBagResortPending = false,

	Tooltip = {
		Scan = nil,
		Vendor = nil,
		Rule = nil,
		WOW = { GameTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3, ItemRefTooltip, ItemRefShoppingTooltip1, ItemRefShoppingTooltip2, ItemRefShoppingTooltip3 }
	},

	-- rules UI context (which location's bar assignments to display)
	Rules = {
		loc_id = ArkInventory.Const.Location.Bag,
	},

	Category = { }, -- see CategoryGenerate( ) for how this gets populated

	Location = {

		[ArkInventory.Const.Location.Bag] = {
			Internal = "bag",
			Name = ArkInventory.Localise["LOCATION_BAG"],
			Texture = [[Interface\Icons\INV_Misc_Bag_07_Green]],
			bagCount = 1, -- actual value set in OnInitialize
			Bags = { },
			canRestack = true,
			hasChanger = true,
			canSearch = true,

			Layout = { },
			maxBar = 0,
			maxSlot = { },

			isOffline = false,
			canView = true,
			canOverride = true,

			drawState = ArkInventory.Const.Window.Draw.Init,
		},

		[ArkInventory.Const.Location.Key] = {
			Internal = "key",
			Name = KEYRING,
			Texture = [[Interface\ContainerFrame\KeyRing-Bag-Icon]], --Interface\Icons\INV_Misc_Key_03
			bagCount = 1,
			Bags = { },
			canRestack = true,
			hasChanger = nil,
			canSearch = true,

			Layout = { },
			maxBar = 0,
			maxSlot = { },

			isOffline = false,
			canView = true,
			canOverride = true,

			drawState = ArkInventory.Const.Window.Draw.Init,
		},

		[ArkInventory.Const.Location.Bank] = {
			Internal = "bank",
			Name = ArkInventory.Localise["LOCATION_BANK"],
			Texture = [[Interface\Icons\INV_Box_02]], --Interface\Minimap\Tracking\Banker
			bagCount = 1, -- actual value set in OnInitialize
			Bags = { },
			canRestack = true,
			hasChanger = true,
			canSearch = true,

			Layout = { },
			maxBar = 0,
			maxSlot = { },

			isOffline = true,
			canView = true,
			canOverride = true,
			canPurge = true,

			drawState = ArkInventory.Const.Window.Draw.Init,
		},

		[ArkInventory.Const.Location.Vault] = {
			Internal = "vault",
			Name = GUILD_BANK,
			Texture = [[Interface\Icons\INV_Misc_Coin_02]],
			bagCount = 1, -- actual value set in OnInitialize
			Bags = { },
			canRestack = true,
			hasChanger = true,
			canSearch = true,

			Layout = { },
			maxBar = 0,
			maxSlot = { },

			isOffline = true,
			canView = true,
			canOverride = false,
			canPurge = true,

			drawState = ArkInventory.Const.Window.Draw.Init,

			current_tab = 1,

		},
		[ArkInventory.Const.Location.PersonalBank] = {
			Internal = "personalbank",
			Name = "Personal Bank",
			Texture = [[Interface\Icons\INV_Misc_Coin_02]],
			bagCount = 1, -- actual value set in OnInitialize
			Bags = { },
			canRestack = true,
			hasChanger = true,
			canSearch = true,

			Layout = { },
			maxBar = 0,
			maxSlot = { },

			isOffline = true,
			canView = true,
			canOverride = true,
			canPurge = true,

			drawState = ArkInventory.Const.Window.Draw.Init,

			current_tab = 1,
		},

		[ArkInventory.Const.Location.RealmBank] = {
			Internal = "realmbank",
			Name = "Realm Bank",
			Texture = [[Interface\Icons\INV_Misc_Coin_02]],
			bagCount = 1, -- actual value set in OnInitialize
			Bags = { },
			canRestack = true,
			hasChanger = true,
			canSearch = true,

			Layout = { },
			maxBar = 0,
			maxSlot = { },

			isOffline = true,
			canView = true,
			canOverride = true,
			canPurge = true,

			drawState = ArkInventory.Const.Window.Draw.Init,

			current_tab = 1,
		},

		[ArkInventory.Const.Location.Mail] = {
			Internal = "mail",
			Name = MAIL_LABEL,
			Texture = [[Interface\Minimap\Tracking\Mailbox]], --[[Interface\Icons\INV_Letter_01]]
			bagCount = 1,
			Bags = { },
			canRestack = nil,
			hasChanger = nil,
			canSearch = true,

			Layout = { },
			maxBar = 0,
			maxSlot = { },

			isOffline = true,
			canView = true,
			canOverride = nil,
			canPurge = true,

			drawState = ArkInventory.Const.Window.Draw.Init,
		},

		[ArkInventory.Const.Location.Wearing] = {
			Internal = "wearing",
			Name = ArkInventory.Localise["LOCATION_WEARING"],
			Texture = [[Interface\Icons\INV_Boots_05]],
			bagCount = 1,
			Bags = { },
			canRestack = nil,
			hasChanger = nil,
			canSearch = true,

			Layout = { },
			maxBar = 0,
			maxSlot = { },

			isOffline = false,
			canView = true,
			canOverride = nil,

			drawState = ArkInventory.Const.Window.Draw.Init,
		},

		[ArkInventory.Const.Location.Pet] = {
			Internal = "pet",
			Name = ArkInventory.Localise["LOCATION_PET"],
			Texture = [[Interface\Icons\INV_Jewelcrafting_GoldenOwl]],
			bagCount = 1,
			Bags = { },
			canRestack = nil,
			hasChanger = nil,
			canSearch = true,

			Layout = { },
			maxBar = 0,
			maxSlot = { },

			isOffline = false,
			canView = true,
			canOverride = nil,

			drawState = ArkInventory.Const.Window.Draw.Init,
		},

		[ArkInventory.Const.Location.Mount] = {
			Internal = "mount",
			Name = ArkInventory.Localise["LOCATION_MOUNT"],
			Texture = [[Interface\Icons\Ability_Mount_WarHippogryph]],
			bagCount = 1,
			Bags = { },
			canRestack = nil,
			hasChanger = nil,
			canSearch = true,

			Layout = { },
			maxBar = 0,
			maxSlot = { },

			isOffline = false,
			canView = true,
			canOverride = nil,

			drawState = ArkInventory.Const.Window.Draw.Init,
		},

		[ArkInventory.Const.Location.Token] = {
			Internal = "token",
			Name = ArkInventory.Localise["LOCATION_TOKEN"],
			Texture = [[Interface\TokenFrame\UI-TokenFrame-Icon]], -- Icons\Spell_Holy_ChampionsBond
			bagCount = 1,
			Bags = { },
			canRestack = nil,
			hasChanger = nil,
			canSearch = true,

			Layout = { },
			maxBar = 0,
			maxSlot = { },

			isOffline = false,
			canView = true,
			canOverride = nil,

			drawState = ArkInventory.Const.Window.Draw.Init,
		},

	},

	Cache = {
		ItemCount = { }, -- key generated via ObjectIDTooltip( h )
		Default = { }, -- key generated via ObjectIDCacheCategory( i )
		Rule = { }, -- key generated via ObjectIDCacheRule( i )
	},

	BAG_SLOT_SIZE = 32,

	Thread = {
		Restack = { },
	},

	Options = {
		Location = ArkInventory.Const.Location.Bag,
		CustomCategorySort = true,
		CustomSortKeySort = true,
		BarMoveSource = nil,
		BarMoveDestination = nil,
	},

}

ArkInventory.Config = {
	Blizzard = {
		type = "group",
		childGroups = "tree",
		name = ArkInventory.Const.Program.Name,
	},
	Internal = {
		type = "group",
		childGroups = "tree",
		name = ArkInventory.Const.Program.Name,
	},
}


-- Binding Variables
BINDING_HEADER_ARKINV = ArkInventory.Const.Program.Name
BINDING_NAME_ARKINV_TOGGLE_BAG = ArkInventory.Localise["LOCATION_BAG"]
BINDING_NAME_ARKINV_TOGGLE_BANK = ArkInventory.Localise["LOCATION_BANK"]
BINDING_NAME_ARKINV_TOGGLE_KEY = KEYRING
BINDING_NAME_ARKINV_TOGGLE_VAULT = GUILD_BANK
BINDING_NAME_ARKINV_TOGGLE_MAIL = MAIL_LABEL
BINDING_NAME_ARKINV_TOGGLE_WEARING = ArkInventory.Localise["LOCATION_WEARING"]
BINDING_NAME_ARKINV_TOGGLE_PET = ArkInventory.Localise["LOCATION_PET"]
BINDING_NAME_ARKINV_TOGGLE_MOUNT = ArkInventory.Localise["LOCATION_MOUNT"]
BINDING_NAME_ARKINV_TOGGLE_TOKEN = ArkInventory.Localise["LOCATION_TOKEN"]
BINDING_NAME_ARKINV_TOGGLE_EDIT = ArkInventory.Localise["MENU_ACTION_EDITMODE"]
BINDING_NAME_ARKINV_TOGGLE_RULES = ArkInventory.Localise["CONFIG_RULES"]
BINDING_NAME_ARKINV_TOGGLE_SEARCH = ArkInventory.Localise["CONFIG_SEARCH"]
BINDING_NAME_ARKINV_RESTACK = ArkInventory.Localise["RESTACK"]
BINDING_NAME_ARKINV_MENU = ArkInventory.Localise["MENU"]
BINDING_NAME_ARKINV_CONFIG = ArkInventory.Localise["CONFIG_TEXT"]
BINDING_NAME_ARKINV_LDB_PETS_SUMMON = ArkInventory.Localise["LDB_PETS_SUMMON"]
BINDING_NAME_ARKINV_LDB_MOUNTS_SUMMON = ArkInventory.Localise["LDB_MOUNTS_SUMMON"]


ArkInventory.Const.DatabaseDefaults.global = {
	["option"] = {
		["version"] = 0,
		["auto"] = {
			["open"] = {
				["*"] = true,
			},
			["close"] = {
				["*"] = true,
			},
		},
		["category"] = {
			["*"] = { -- type: rule or custom
				["data"] = {
					["*"] = {  -- [number] = { data }
						["used"] = false,
						["name"] = "",
					},
				},
				["next"] = 0,
			},
		},
		["background"] = {
			["data"] = {
				["*"] = {
					["used"] = false,
					["name"] = "",
					["colour"] = {
						["r"] = 0,
						["g"] = 0,
						["b"] = 0.4,
						["a"] = 0.4,
					},
				},
			},
			["next"] = 0,
		},
		["sort"] = {
			["data"] = {
				[9999] = {
					["system"] = true,
					["used"] = true,
					["name"] = "(*) "..ArkInventory.Localise["CONFIG_SORTMETHOD_STYLE_BAGSLOT"],
					["bagslot"] = true,
					["ascending"] = true,
					["reversed"] = false,
					["active"] = { },
					["order"] = { },
				},
				[9998] = {
					["system"] = true,
					["used"] = true,
					["name"] = "(*) Rarity>Category>Location>Name",
					["bagslot"] = false,
					["ascending"] = true,
					["reversed"] = false,
					["active"] = {
						["quality"] = true,
						["category"] = true,
						["location"] = true,
						["name"] = true,
					},
					["order"] = {
						[1] = "quality",
						[2] = "category",
						[3] = "location",
						[4] = "name",
					},
				},
				[9997] = {
					["system"] = true,
					["used"] = true,
					["name"] = "(*) Name",
					["bagslot"] = false,
					["ascending"] = true,
					["reversed"] = false,
					["active"] = {
						["name"] = true,
					},
					["order"] = {
						[1] = "name",
					},
				},
				["*"] = {
					["system"] = false,
					["used"] = false,
					["name"] = "",
					["bagslot"] = true,
					["ascending"] = true,
					["reversed"] = false,
					["active"] = { },
					["order"] = { },
				},
			},
			["next"] = 0,
		},
		["showdisabled"] = true,
		["bucket"] = {
			["*"] = nil
		},
		["bugfix"] = {
			["framelevel"] = {
				["enable"] = true,
				["alert"] = 2,
			},
			["zerosizebag"] = {
				["enable"] = true,
				["alert"] = true,
			},
		},
		["tooltip"] = {
			["show"] = true, -- show tooltips for items
			["scale"] = {
				["enabled"] = false,
				["amount"] = 1,
			},
			["me"] = false, -- only show my data
			["faction"] = false, -- only show my faction
			["add"] = { -- things to add to the tooltip
				["empty"] = false, -- empty line / seperator
				["count"] = true, -- item count
				["vendor"] = false, -- vendor price (deprecated)
				["ilvl"] = false, -- item level (deprecated)
				["vault"] = true,
				["tabs"] = true,
			},
			["colour"] = {
				["count"] =  {
					["r"] = 1,
					["g"] = 0.5,
					["b"] = 0.15,
				},
				["vendor"] =  {
					["r"] = 0.5,
					["g"] = 0.5,
					["b"] = 0.5,
				},
				["class"] = false,
			},
		},
	},
	["player"] = { },
	-- shared, non-profile defaults for Realm Bank options
	["realmbank"] = {
		["option"] = {
			["location"] = {
				["*"] = {
					["window"] = {
						["scale"] = 1,
						["width"] = 16,
						["border"] = {
							["style"] = ArkInventory.Const.Texture.BorderDefault,
							["size"] = nil,
							["offset"] = nil,
							["scale"] = 1,
							["colour"] = {
								["r"] = 1,
								["g"] = 1,
								["b"] = 1,
							},
						},
						["pad"] = 8,
						["background"] = {
							["style"] = ArkInventory.Const.Texture.BackgroundDefault,
							["colour"] = {
								["r"] = 0,
								["g"] = 0,
								["b"] = 0,
								["a"] = 0.75,
							},
						},
					},
					["bar"] = {
						["per"] = 5,
						["pad"] = {
							["internal"] = 8,
							["external"] = 8,
						},
						["border"] = {
							["style"] = ArkInventory.Const.Texture.BorderDefault,
							["size"] = nil,
							["offset"] = nil,
							["scale"] = 1,
							["colour"] = {
								["r"] = 0.3,
								["g"] = 0.3,
								["b"] = 0.3,
							},
						},
						["background"] = {
							["colour"] = {
								["r"] = 0,
								["g"] = 0,
								["b"] = 0.4,
								["a"] = 0.4,
							},
						},
						["showempty"] = false,
						["anchor"] = ArkInventory.Const.Anchor.BottomRight,
						["compact"] = false,
						["hide"] = false,
						["name"] = {
							["show"] = false,
							["colour"] = {
								["r"] = 1,
								["b"] = 1,
								["g"] = 1,
							},
							["height"] = 12,
							["justify"] = ArkInventory.Const.Anchor.Left,
							["anchor"] = ArkInventory.Const.Anchor.Automatic,
						},
						["data"] = {
							["*"] = {
								-- label
								-- sortorder
								-- backgroundid
							},
						},
					},
					["slot"] = {
						["empty"] = {
							["alpha"] = 0.1,
							["icon"] = true,
							["border"] = true,
							["clump"] = false,
						},
						["data"] = ArkInventory.Const.Slot.Data,
						["pad"] = 4,
						["border"] = {
							["style"] = ArkInventory.Const.Texture.BorderDefault,
							["size"] = nil,
							["offset"] = nil,
							["scale"] = 1,
							["rarity"] = true,
							["raritycutoff"] = 0,
						},
						["ignorehidden"] = false,
						["anchor"] = ArkInventory.Const.Anchor.BottomRight,
						["new"] = {
							["show"] = false,
							["colour"] = {
								["r"] = 1,
								["g"] = 1,
								["b"] = 1,
							},
							["cutoff"] = 4,
						},
						["offline"] = {
							["fade"] = true,
						},
						["unusable"] = {
							["tint"] = false,
						},
						["cooldown"] = {
							["show"] = true,
							["global"] = false,
							["combat"] = true,
						},
					},
					["sort"] = {
						["open"] = true,
						["instant"] = false,
						["default"] = 9999,
					},
					["category"] = {
						["*"] = nil,
					},
					["anchor"] = {
						["*"] = {
							["point"] = ArkInventory.Const.Anchor.TopRight,
							["locked"] = false,
							["t"] = 0,
							["b"] = 0,
							["l"] = 0,
							["r"] = 0,
						},
					},
					["notifyerase"] = true,
					["title"] = {
						["hide"] = false,
						["size"] = 1,
					},
					["search"] = {
						["hide"] = false,
					},
					["changer"] = {
						["hide"] = false,
						["highlight"] = {
							["show"] = true,
							["colour"] = {
								["r"] = 0,
								["g"] = 1,
								["b"] = 0,
							},
						},
						["freespace"] = {
							["show"] = true,
							["colour"] = {
								["r"] = 1,
								["g"] = 1,
								["b"] = 1,
							},
						},
					},
					["status"] = {
						["hide"] = false,
						["emptytext"] = {
							["show"] = true,
							["colour"] = false,
							["full"] = true,
							["includetype"] = true,
						},
					},
				},
			},
		},
	},
}

ArkInventory.Const.DatabaseDefaults.realm = {
	["player"] = {
		["version"] = 0,
		["data"] = {
			["*"] = { -- player or guild name
				["monitor"] = {
					["*"] = true,
				},
				["save"] = {
					["*"] = true,
				},
				["erasesilent"] = false,
				["control"] = { -- which locations to take control of
          ["*"] = false,
					[ArkInventory.Const.Location.Bag] = true,
					[ArkInventory.Const.Location.Bank] = true,
					--[ArkInventory.Const.Location.Key] = true,
					--[ArkInventory.Const.Location.Vault] = true,
					[ArkInventory.Const.Location.PersonalBank] = true,
					[ArkInventory.Const.Location.RealmBank] = true
				},
				["display"] = {
					["*"] = {
						["bag"] = {
							["*"] = true,
						},
					}
				},
				["info"] = { },
				["location"] = {
					["*"] = {
						["slot_count"] = 0,
						["bag"] = {
							["*"] = {
								["status"] = ArkInventory.Const.Bag.Status.Unknown,
								--["texture"] = nil,
								--["h"] = nil,
								--["q"] = nil,
								["type"] = ArkInventory.Const.Slot.Type.Unknown,
								["count"] = 0,
								["empty"] = 0,
								["slot"] = {	},
							},
						},
					},
				},
			},
		},
	},
}

ArkInventory.Const.DatabaseDefaults.char = {
	["option"] = {
		["version"] = 0,
		["personalbank"] = {
			-- case-insensitive substring used to detect Personal Bank
			["titlepattern"] = "personal bank",
			-- case-insensitive substring used to detect Realm Bank
			["titlepattern_realm"] = "realm bank",
		},
		["ldb"] = {
			["bags"] = {
				["colour"] = false,
				["full"] = true,
				["includetype"] = true,
			},
			["ammo"] = {
				["durability"] = true,
			},
			["currency"] = {
				["track"] = nil,
			},
			["pets"] = {
				["track"] = nil,
				["restrict"] = true,
			},
			["mounts"] = {
				["ground"] = {
					["track"] = nil,
					["min"] = 60,
				},
				["flying"] = {
					["dismount"] = false,
					["track"] = nil,
					["min"] = 100,
				},
			},
		},
	},
}

ArkInventory.Const.DatabaseDefaults.profile = {
	["option"] = {
		["version"] = 0,
		["category"] = { }, -- ["item id"] = category number to put the item in
		["rule"] = {
			["*"] = false,
		},
		["use"] = {	},
		["location"] = {
			["*"] = {
				["window"] = {
					["scale"] = 1,
					["width"] = 16,
					["border"] = {
						["style"] = ArkInventory.Const.Texture.BorderDefault,
						["size"] = nil,
						["offset"] = nil,
						["scale"] = 1,
						["colour"] = {
							["r"] = 1,
							["g"] = 1,
							["b"] = 1,
						},
					},
					["pad"] = 8,
					["background"] = {
						["style"] = ArkInventory.Const.Texture.BackgroundDefault,
						["colour"] = {
							["r"] = 0,
							["g"] = 0,
							["b"] = 0,
							["a"] = 0.75,
						},
					},
				},
				["bar"] = {
					["per"] = 5,
					["pad"] = {
						["internal"] = 8,
						["external"] = 8,
					},
					["border"] = {
						["style"] = ArkInventory.Const.Texture.BorderDefault,
						["size"] = nil,
						["offset"] = nil,
						["scale"] = 1,
						["colour"] = {
							["r"] = 0.3,
							["g"] = 0.3,
							["b"] = 0.3,
						},
					},
					["background"] = {
						["colour"] = {
							["r"] = 0,
							["g"] = 0,
							["b"] = 0.4,
							["a"] = 0.4,
						},
					},
					["showempty"] = false,
					["anchor"] = ArkInventory.Const.Anchor.BottomRight,
					["compact"] = false,
					["hide"] = false,
					["name"] = {
						["show"] = false,
						["colour"] = {
							["r"] = 1,
							["b"] = 1,
							["g"] = 1,
						},
						["height"] = 12,
						["justify"] = ArkInventory.Const.Anchor.Left,
						["anchor"] = ArkInventory.Const.Anchor.Automatic,
					},
					["data"] = {
						["*"] = {
							-- label
							-- sortorder
							-- backgroundid
						},
					},
				},
				["slot"] = {
					["empty"] = {
						["alpha"] = 0.1,
						["icon"] = true,
						["border"] = true,
						["clump"] = false,
					},
					["data"] = ArkInventory.Const.Slot.Data,
					["pad"] = 4,
					["border"] = {
						["style"] = ArkInventory.Const.Texture.BorderDefault,
						["size"] = nil,
						["offset"] = nil,
						["scale"] = 1,
						["rarity"] = true,
						["raritycutoff"] = 0,
					},
					["ignorehidden"] = false,
					["anchor"] = ArkInventory.Const.Anchor.BottomRight,
					["new"] = {
						["show"] = false,
						["colour"] = {
							["r"] = 1,
							["g"] = 1,
							["b"] = 1,
						},
						["cutoff"] = 4,
					},
					["offline"] = {
						["fade"] = true,
					},
					["unusable"] = {
						["tint"] = false,
					},
					["cooldown"] = {
						["show"] = true,
						["global"] = false,
						["combat"] = true,
					},
				},
				["sort"] = {
					["open"] = true,
					["instant"] = false,
					["default"] = 9999,
				},
				["category"] = {
					["*"] = nil, -- [category number] = bar number to put rule on
				},
				["anchor"] = {
					["*"] = {
						["point"] = ArkInventory.Const.Anchor.TopRight,
						["locked"] = false,
						["t"] = 0,
						["b"] = 0,
						["l"] = 0,
						["r"] = 0,
					},
				},
				["notifyerase"] = true,
				["title"] = {
					["hide"] = false,
					["size"] = 1,
				},
				["search"] = {
					["hide"] = false,
				},
				["changer"] = {
					["hide"] = false,
					["highlight"] = {
						["show"] = true,
						["colour"] = {
							["r"] = 0,
							["g"] = 1,
							["b"] = 0,
						},
					},
					["freespace"] = {
						["show"] = true,
						["colour"] = {
							["r"] = 1,
							["g"] = 1,
							["b"] = 1,
						},
					},
				},
				["status"] = {
					["hide"] = false,
					["emptytext"] = {   -- slot>empty>display
						["show"] = true,
						["colour"] = false,
						["full"] = true,
						["includetype"] = true,
					},
				},
			},
		},
		["font"] = {
			["name"] = nil,
			["size"] = 0,
		},
		["ui"] = {
			["search"] = {
				["scale"] = 1,
				["background"] = {
					["style"] = ArkInventory.Const.Texture.BackgroundDefault,
					["colour"] = {
						["r"] = 0,
						["g"] = 0,
						["b"] = 0,
						["a"] = 0.75,
					},
				},
				["border"] = {
					["style"] = ArkInventory.Const.Texture.BorderDefault,
					["size"] = nil,
					["offset"] = nil,
					["scale"] = 1,
					["colour"] = {
						["r"] = 1,
						["g"] = 1,
						["b"] = 1,
					},
				},
			},
			["rules"] = {
				["scale"] = 1,
				["background"] = {
					["style"] = ArkInventory.Const.Texture.BackgroundDefault,
					["colour"] = {
						["r"] = 0,
						["g"] = 0,
						["b"] = 0,
						["a"] = 0.75,
					},
				},
				["border"] = {
					["style"] = ArkInventory.Const.Texture.BorderDefault,
					["size"] = nil,
					["offset"] = nil,
					["scale"] = 1,
					["colour"] = {
						["r"] = 1,
						["g"] = 1,
						["b"] = 1,
					},
				},
			},
		},
	},
}

function ArkInventory.OnInitialize( )

	--ArkInventory.Output( "OnInitialize" )

	ArkInventory.Global.Version = string.format( "v%s", ArkInventory.Const.Program.UIVersion )
	if ArkInventory.Const.Program.Beta then
		ArkInventory.Global.Version = string.format( "%s %s(%s)%s", ArkInventory.Global.Version, RED_FONT_COLOR_CODE, ArkInventory.Const.Program.Beta or "unknown beta version", FONT_COLOR_CODE_CLOSE )
	end

	-- pre acedb load, its just a raw table
	ArkInventory.ConvertAceDB2ToAceDB3( )

	-- erase old factionrealm data
	if ArkInventory.Const.Program.Version >= 3.0227 then
		if ARKINVDB and ARKINVDB.factionrealm then
			ARKINVDB.factionrealm = nil
		end
	end


	-- load database, use default profile, metatables now active so dont play with it
	ArkInventory.db = LibStub( "AceDB-3.0" ):New( "ARKINVDB", ArkInventory.Const.DatabaseDefaults, true )

	ArkInventory.StartupChecks( )

	-- cofnig menu (internal)
	ArkInventory.Lib.Config:RegisterOptionsTable( ArkInventory.Const.Frame.Config.Internal, ArkInventory.Config.Internal )
	ArkInventory.Lib.Dialog:SetDefaultSize( ArkInventory.Const.Frame.Config.Internal, 1000, 600 )

	-- config menu (blizzard)
	ArkInventory.ConfigBlizzard( )
	ArkInventory.Lib.Config:RegisterOptionsTable( ArkInventory.Const.Frame.Config.Blizzard, ArkInventory.Config.Blizzard, { "arkinventory", "arkinv", "ai" } )
	ArkInventory.Lib.Dialog:AddToBlizOptions( ArkInventory.Const.Frame.Config.Blizzard, ArkInventory.Const.Program.Name )

	-- trace / instrumentation command
	if ArkInventory.RegisterChatCommand then
		ArkInventory:RegisterChatCommand( "aitrace", "ChatCommandTrace" )
		-- common typo / alternate name
		ArkInventory:RegisterChatCommand( "airtrace", "ChatCommandTrace" )
	end


	-- tooltips
	ArkInventory.Global.Tooltip.Scan = ArkInventory.TooltipInit( "ARKINV_ScanTooltip" )
	ArkInventory.Global.Tooltip.Vendor = ArkInventory.TooltipInit( "ARKINV_VendorTooltip" )
	ArkInventory.Global.Tooltip.Rule = ArkInventory.TooltipInit( "ARKINV_RuleTooltip" )

	local loc_id

	-- bags
	loc_id = ArkInventory.Const.Location.Bag
	ArkInventory.Global.Location[loc_id].bagCount = NUM_BAG_SLOTS + 1
	table.insert( ArkInventory.Global.Location[loc_id].Bags, BACKPACK_CONTAINER )
	--ArkInventory.Output( "added bag ", BACKPACK_CONTAINER, " to ", ArkInventory.Global.Location[loc_id].Name )
	for x = 1, NUM_BAG_SLOTS do
		table.insert( ArkInventory.Global.Location[loc_id].Bags, x )
		--ArkInventory.Output( "added bag ", x, " to ", ArkInventory.Global.Location[loc_id].Name )
	end

	-- keyring
	loc_id = ArkInventory.Const.Location.Key
	table.insert( ArkInventory.Global.Location[loc_id].Bags, KEYRING_CONTAINER )
	--ArkInventory.Output( "added bag ", KEYRING_CONTAINER, " to ", ArkInventory.Global.Location[loc_id].Name )

	-- bank
	loc_id = ArkInventory.Const.Location.Bank
	ArkInventory.Global.Location[loc_id].bagCount = NUM_BANKBAGSLOTS + 1
	table.insert( ArkInventory.Global.Location[loc_id].Bags, BANK_CONTAINER )
	--ArkInventory.Output( "added bag ", BANK_CONTAINER, " to ", ArkInventory.Global.Location[loc_id].Name )
	for x = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		table.insert( ArkInventory.Global.Location[loc_id].Bags, x )
		--ArkInventory.Output( "added bag ", x, " to ", ArkInventory.Global.Location[loc_id].Name )
	end

	-- vault
	loc_id = ArkInventory.Const.Location.Vault
	ArkInventory.Global.Location[loc_id].bagCount = MAX_GUILDBANK_TABS
	for x = 1, MAX_GUILDBANK_TABS do
		table.insert( ArkInventory.Global.Location[loc_id].Bags, ArkInventory.Const.Offset.Vault + x )
	end

	-- personal bank (uses guild bank APIs)
	loc_id = ArkInventory.Const.Location.PersonalBank
	ArkInventory.Global.Location[loc_id].bagCount = MAX_GUILDBANK_TABS
	for x = 1, MAX_GUILDBANK_TABS do
		table.insert( ArkInventory.Global.Location[loc_id].Bags, ArkInventory.Const.Offset.PersonalBank + x )
	end

	-- realm bank (uses guild bank APIs)
	loc_id = ArkInventory.Const.Location.RealmBank
	ArkInventory.Global.Location[loc_id].bagCount = MAX_GUILDBANK_TABS
	for x = 1, MAX_GUILDBANK_TABS do
		table.insert( ArkInventory.Global.Location[loc_id].Bags, ArkInventory.Const.Offset.RealmBank + x )
	end

	-- mail
	table.insert( ArkInventory.Global.Location[ArkInventory.Const.Location.Mail].Bags, ArkInventory.Const.Offset.Mail + 1 )

	-- wearing
	table.insert( ArkInventory.Global.Location[ArkInventory.Const.Location.Wearing].Bags, ArkInventory.Const.Offset.Wearing + 1 )

	-- pet
	table.insert( ArkInventory.Global.Location[ArkInventory.Const.Location.Pet].Bags, ArkInventory.Const.Offset.Pet + 1 )
	ArkInventory.Global.Location[ArkInventory.Const.Location.Pet].bagCount = 1

	-- mount
	table.insert( ArkInventory.Global.Location[ArkInventory.Const.Location.Mount].Bags, ArkInventory.Const.Offset.Mount + 1 )
	ArkInventory.Global.Location[ArkInventory.Const.Location.Mount].bagCount = 1

	-- token
	table.insert( ArkInventory.Global.Location[ArkInventory.Const.Location.Token].Bags, ArkInventory.Const.Offset.Token + 1 )


	-- pets and mounts
	local key = nil
	for item, spell in pairs( ArkInventory.Const.CompanionTranslationData ) do

		if type( item ) == "number" and type( spell.id ) == "number" then

			-- item to spell
			key = string.format("item:%s", item)
			if not ArkInventory.Const.CompanionTranslation[key] then
				ArkInventory.Const.CompanionTranslation[key] = { }
			end
			ArkInventory.Const.CompanionTranslation[key][string.format("spell:%s", spell.id)] = true

			-- spell to item(s)
			key = string.format("spell:%s", spell.id)
			if not ArkInventory.Const.CompanionTranslation[key] then
				ArkInventory.Const.CompanionTranslation[key] = { }
			end
			ArkInventory.Const.CompanionTranslation[key][string.format("item:%s", item)] = true

		end

		if type( spell.id ) == "number" then
			-- companion spell data
			if not ArkInventory.Const.CompanionData[spell.id] then
				ArkInventory.Const.CompanionData[spell.id] = { }
			end
			ArkInventory.Const.CompanionData[spell.id]["f"] = spell.f
			ArkInventory.Const.CompanionData[spell.id]["s"] = spell.s
			ArkInventory.Const.CompanionData[spell.id]["r"] = spell.r
		end

	end

	wipe( ArkInventory.Const.CompanionTranslationData )
	ArkInventory.Const.CompanionTranslationData = nil

	ArkInventory.PlayerInfoSet( )
	ArkInventory.MediaRegister( )

	-- 3rd party addons that require hooking for item updates

	-- scrap: http://wow.curse.com/downloads/wow-addons/details/scrap.aspx
	if IsAddOnLoaded( "Scrap" ) then
		if Scrap.OnReceiveDrag then
			ArkInventory.Output( "enabling Scrap support" )
			Scrap:HookScript( "OnReceiveDrag", ArkInventory.ItemCacheClear )
		end
	end

	-- selljunk: http://wow.curse.com/downloads/wow-addons/details/sell-junk.aspx
	if IsAddOnLoaded( "SellJunk" ) then
		if SellJunk.Add and SellJunk.Rem then
			ArkInventory.Output( "enabling SellJunk support" )
			ArkInventory.MySecureHook( SellJunk, "Add", ArkInventory.ItemCacheClear )
			ArkInventory.MySecureHook( SellJunk, "Rem", ArkInventory.ItemCacheClear )
		end
	end

	-- reagent restocker: http://wow.curse.com/downloads/wow-addons/details/reagent_restocker.aspx
	if IsAddOnLoaded( "ReagentRestocker" ) then
		if ReagentRestocker.addItemToSellingList and ReagentRestocker.deleteItem then
			ArkInventory.Output( "enabling ReagentRestocker support" )
			ArkInventory.MySecureHook( ReagentRestocker, "addItemToSellingList", ArkInventory.ItemCacheClear )
			ArkInventory.MySecureHook( ReagentRestocker, "deleteItem", ArkInventory.ItemCacheClear )
		end
	end

end

function ArkInventory.OnEnable( )

	-- Called when the addon is enabled

	--ArkInventory.Output( "OnEnable" )

	ArkInventory.ConvertOldOptions( )

	ArkInventory.PlayerInfoSet( )

	ArkInventory.CategoryGenerate( )

	ArkInventory.BlizzardAPIHooks( )

	-- tag all locations as changed
	ArkInventory.LocationSetValue( nil, "changed", true )

	-- tag all locations as needing resorting/recategorisation
	ArkInventory.LocationSetValue( nil, "resort", true )

	-- init location player_id
	ArkInventory.LocationSetValue( nil, "player_id", ArkInventory.Global.Me.info.player_id )

	-- register events

	ArkInventory:RegisterMessage( "LISTEN_STORAGE_EVENT" )

	ArkInventory:RegisterEvent( "PLAYER_ENTERING_WORLD", "LISTEN_PLAYER_ENTER" ) -- not really needed but seems to fix a bug where ace doesnt seem to init again
	ArkInventory:RegisterEvent( "PLAYER_LEAVING_WORLD", "LISTEN_PLAYER_LEAVE" ) --when the player logs out or the UI is reloaded.
	ArkInventory:RegisterEvent( "PLAYER_MONEY", "LISTEN_PLAYER_MONEY" )

	ArkInventory:RegisterEvent( "SKILL_LINES_CHANGED", "LISTEN_PLAYER_SKILLS" ) -- triggered when you gain or lose a skill, skillup, collapse/expand a skill header

	ArkInventory:RegisterEvent( "PLAYER_REGEN_DISABLED", "LISTEN_COMBAT_ENTER" ) -- player about to enter combat
	ArkInventory:RegisterEvent( "PLAYER_REGEN_ENABLED", "LISTEN_COMBAT_LEAVE" ) -- player left combat

	local bucket1 = ArkInventory.db.global.option.bucket[ArkInventory.Const.Location.Bag] or 0.5

	ArkInventory:RegisterBucketMessage( "LISTEN_BAG_UPDATE_BUCKET", bucket1 )
	ArkInventory:RegisterEvent( "BAG_UPDATE", "LISTEN_BAG_UPDATE" )
	ArkInventory:RegisterEvent( "ITEM_LOCK_CHANGED", "LISTEN_BAG_LOCK" )
	ArkInventory:RegisterBucketMessage( "LISTEN_BAG_UPDATE_COOLDOWN_BUCKET", bucket1 )
	ArkInventory:RegisterEvent( "BAG_UPDATE_COOLDOWN", "LISTEN_BAG_UPDATE_COOLDOWN" )

	ArkInventory:RegisterBucketMessage( "LISTEN_CHANGER_UPDATE_BUCKET", 1 )

	ArkInventory:RegisterEvent( "BANKFRAME_OPENED", "LISTEN_BANK_ENTER" )
	ArkInventory:RegisterEvent( "BANKFRAME_CLOSED", "LISTEN_BANK_LEAVE" )
	ArkInventory:RegisterEvent( "PLAYERBANKSLOTS_CHANGED", "LISTEN_BANK_UPDATE" ) -- a bag_update event for the bank (-1)
	ArkInventory:RegisterEvent( "PLAYERBANKBAGSLOTS_CHANGED", "LISTEN_BANK_SLOT" ) -- triggered when you purchase a new bank bag slot

	ArkInventory:RegisterEvent( "GUILDBANKFRAME_OPENED", "LISTEN_VAULT_ENTER" )
	ArkInventory:RegisterEvent( "GUILDBANKFRAME_CLOSED", "LISTEN_VAULT_LEAVE" )
	ArkInventory:RegisterBucketMessage( "LISTEN_VAULT_UPDATE_BUCKET", ArkInventory.db.global.option.bucket[ArkInventory.Const.Location.Vault] or 0.5 )
	ArkInventory:RegisterEvent( "GUILDBANKBAGSLOTS_CHANGED", "LISTEN_VAULT_UPDATE" )
	ArkInventory:RegisterEvent( "GUILDBANK_ITEM_LOCK_CHANGED", "LISTEN_VAULT_LOCK" )
	ArkInventory:RegisterEvent( "GUILDBANK_UPDATE_MONEY", "LISTEN_VAULT_MONEY" )
	ArkInventory:RegisterEvent( "GUILDBANK_UPDATE_TABS", "LISTEN_VAULT_TABS" )
	ArkInventory:RegisterEvent( "GUILDBANKLOG_UPDATE", "LISTEN_VAULT_LOG" )
	ArkInventory:RegisterEvent( "GUILDBANK_UPDATE_TEXT", "LISTEN_VAULT_INFO" )

	ArkInventory:RegisterBucketMessage( "LISTEN_INVENTORY_CHANGE_BUCKET", bucket1 )
	ArkInventory:RegisterEvent( "UNIT_INVENTORY_CHANGED", "LISTEN_INVENTORY_CHANGE" )
	ArkInventory:RegisterEvent( "UPDATE_INVENTORY_DURABILITY", "LISTEN_UPDATE_INVENTORY_DURABILITY" )

	ArkInventory:RegisterEvent( "MAIL_SHOW", "LISTEN_MAIL_ENTER" )
	ArkInventory:RegisterEvent( "MAIL_CLOSED", "LISTEN_MAIL_LEAVE" )
	ArkInventory:RegisterBucketMessage( "LISTEN_MAIL_UPDATE_BUCKET", bucket1 )
	ArkInventory:RegisterEvent( "MAIL_INBOX_UPDATE", "LISTEN_MAIL_UPDATE" )

	ArkInventory:RegisterEvent( "TRADE_SHOW", "LISTEN_TRADE_ENTER" )
	ArkInventory:RegisterEvent( "TRADE_CLOSED", "LISTEN_TRADE_LEAVE" )

	ArkInventory:RegisterEvent( "AUCTION_HOUSE_SHOW", "LISTEN_AUCTION_ENTER" )
	ArkInventory:RegisterEvent( "AUCTION_HOUSE_CLOSED", "LISTEN_AUCTION_LEAVE" )

	ArkInventory:RegisterEvent( "MERCHANT_SHOW", "LISTEN_MERCHANT_ENTER" )
	ArkInventory:RegisterEvent( "MERCHANT_CLOSED", "LISTEN_MERCHANT_LEAVE" )

	-- Useful for diagnosing taint/protected-action popups (e.g. disenchanting
	-- from custom bag buttons). Only outputs when ArkInventory debug mode is on.
	ArkInventory:RegisterEvent( "ADDON_ACTION_BLOCKED", "LISTEN_ADDON_ACTION_BLOCKED" )
	ArkInventory:RegisterEvent( "ADDON_ACTION_FORBIDDEN", "LISTEN_ADDON_ACTION_BLOCKED" )

	ArkInventory:RegisterEvent( "COMPANION_LEARNED", "LISTEN_COMPANION_UPDATE" )

	ArkInventory:RegisterEvent( "EQUIPMENT_SETS_CHANGED", "LISTEN_EQUIPMENT_SETS_CHANGED" )

	ArkInventory:RegisterEvent( "KNOWN_CURRENCY_TYPES_UPDATE", "LISTEN_CURRENCY_UPDATE" )
	ArkInventory:RegisterEvent( "CURRENCY_DISPLAY_UPDATE", "LISTEN_CURRENCY_UPDATE" )

	ArkInventory:RegisterBucketMessage( "LISTEN_QUEST_UPDATE_BUCKET", 3 ) -- update quest item glows.  not super urgent just get them there eventually
	ArkInventory:RegisterEvent( "QUEST_ACCEPTED", "LISTEN_QUEST_UPDATE" )
	ArkInventory:RegisterEvent( "UNIT_QUEST_LOG_CHANGED", "LISTEN_QUEST_UPDATE" )


	ArkInventory.db.RegisterCallback( ArkInventory, "OnProfileChanged", "OnProfileChanged" )
	ArkInventory.db.RegisterCallback( ArkInventory, "OnProfileCopied", "OnProfileChanged" )
	ArkInventory.db.RegisterCallback( ArkInventory, "OnProfileReset", "OnProfileChanged" )
	--ArkInventory.db.RegisterCallback( ArkInventory, "OnProfileDeleted", "OnProfileChanged" )
	--ArkInventory.db.RegisterCallback( ArkInventory, "OnDatabaseReset", "OnProfileChanged" )

	ArkInventory.ScanTradeskill( )
	ArkInventory.ScanLocation( )

	ArkInventory.LDB.Money:Update( )
	ArkInventory.LDB.Bags:Update( )
	ArkInventory.LDB.Ammo:Update( )
	ArkInventory.LDB.Currency:Update( )
	ArkInventory.LDB.Pets:Update( )
	ArkInventory.LDB.Mounts:Update( )

	ArkInventory.Output( string.format( "%s %s", ArkInventory.Global.Version, ArkInventory.Localise["ENABLED"] ) )

end

function ArkInventory.OnDisable( )

	--ArkInventory.Frame_Main_Hide( )

	ArkInventory.BlizzardAPIHooks( true )

	ArkInventory.Output( string.format( "%s %s", ArkInventory.Global.Version, ArkInventory.Localise["DISABLED"] ) )

end

function ArkInventory.DatabaseReset( )

	-- /ai db reset confirm

	ArkInventory.Frame_Main_Hide( )

	ArkInventory.db:ResetDB( "profile" )

	ArkInventory.Output( GREEN_FONT_COLOR_CODE, ArkInventory.Localise["SLASH_DB_RESET_COMPLETE_TEXT"] )

	ArkInventory.CategoryGenerate( )
	ArkInventory.LocationSetValue( nil, "resort", true )
	ArkInventory.Frame_Main_Generate( nil, ArkInventory.Const.Window.Draw.Recalculate )

end

function ArkInventory.nilStringEmpty( arg )
	if arg == nil then arg = "" end
	return tostring( arg )
end

function ArkInventory.nilStringText( arg )
	if arg == nil then arg = "nil" end
	return tostring( arg )
end

--function ArkInventory.round( n, dp )
--	local m = 10 ^ ( dp or 0 )
--	return math.floor( n * m + 0.5 ) / m
--end

function ArkInventory.ClassColourRGB( class )

	if not class then
		return
	end

	local ct = nil

	if class == "GUILD" then
		ct = { r = 1, g = 0.5, b = 0.15 }
	else
		ct = ( CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] ) or RAID_CLASS_COLORS[class]
		-- change ct and you'll taint it
	end

	if not ct then
		return
	end

	local c = { r = ct.r <= 1 and ct.r >= 0 and ct.r or 0, g = ct.g <= 1 and ct.g >= 0 and ct.g or 0, b = ct.b <= 1 and ct.b >= 0 and ct.b or 0 }

	return c

end

function ArkInventory.ClassColourCode( class )

	local c = ArkInventory.ClassColourRGB( class )

	if not c then
		return FONT_COLOR_CODE_CLOSE
	end

	return string.format( "|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255 )

end

function ArkInventory.ColourRGBtoCode( r, g, b )

	if not r or not g or not b then
		return FONT_COLOR_CODE_CLOSE
	end

	local r = r <= 1 and r >= 0 and r or 0
	local g = g <= 1 and g >= 0 and g or 0
	local b = b <= 1 and b >= 0 and b or 0

	return string.format( "|cff%02x%02x%02x", r * 255, g * 255, b * 255 )

end

function ArkInventory.ColourCodetoRGB( c )

	if not c then
		return 1, 1, 1
	end

	local a, r, g, b = strmatch( c, "|c(%x%x)(%x%x)(%x%x)(%x%x)" )

	a = tonumber( a ) / 255
	r = tonumber( r ) / 255
	g = tonumber( g ) / 255
	b = tonumber( b ) / 255

	return r, g, b, a

end

function ArkInventory.OutputSerialize( d )
	if d == nil then
		return "nil"
	elseif type( d ) == "number" then
		return tostring( d )
	elseif type( d ) == "string" then
		--return string.format( "%q", d )
		return d
	elseif type( d ) == "boolean" then
		if d then
			return "true"
		else
			return "false"
		end
	elseif type( d ) == "table" then
		local tmp = { }
		for k, v in pairs( d ) do
			table.insert( tmp, "[" .. ArkInventory.OutputSerialize( k ) .. "]=" .. ArkInventory.OutputSerialize( v ) )
		end
		return "{ " .. table.concat( tmp, ", " ) .. " }"
	else
		return "**" .. type( d ) or ArkInventory.Localise["UNKNOWN"] .. "**"
	end
end

local ArkInventory_TempOutputTable = { }

function ArkInventory.Output( ... )

	if not DEFAULT_CHAT_FRAME then
		return
	end

	table.wipe( ArkInventory_TempOutputTable )

	local n = select( '#', ... )
	for i = 1, n do
		local v = select( i, ... )
		table.insert( ArkInventory_TempOutputTable, ArkInventory.OutputSerialize( v ) )
	end

	ArkInventory:Print( table.concat( ArkInventory_TempOutputTable ) )

end

function ArkInventory.OutputDebug( ... )
	if ArkInventory.Const.Debug then
		ArkInventory.Output( "|cffffff9aDEBUG> ", ... )
	end
end

function ArkInventory.OutputWarning( ... )
	ArkInventory.Output( "|cfffa8000WARNING> ", ... )
end

function ArkInventory.OutputError( ... )
	ArkInventory.Output( RED_FONT_COLOR_CODE, "ERROR> ", ... )
end

function ArkInventory.OutputDebugModeSet( value )

	if ArkInventory.Const.Debug ~= value then

		local state = ArkInventory.Localise["ENABLED"]
		if not value then
			state = ArkInventory.Localise["DISABLED"]
		end

		ArkInventory.Const.Debug = value

		ArkInventory.Output( "debug mode is now ", state )

	end

end

function ArkInventory.BlizzardFrameInteractiveSet( frame, enabled )

	-- Recursively enable/disable mouse interaction on a Blizzard frame tree.
	-- Used to ensure hidden Blizzard UI panels (eg. GuildBankFrame) cannot
	-- capture hover/clicks and show tooltips through ArkInventory windows.
	if not frame then
		return
	end

	if frame.EnableMouse then
		frame:EnableMouse( enabled and true or false )
	end
	if frame.EnableMouseWheel then
		frame:EnableMouseWheel( enabled and true or false )
	end

	if frame.GetChildren then
		local children = { frame:GetChildren( ) }
		for _, child in ipairs( children ) do
			ArkInventory.BlizzardFrameInteractiveSet( child, enabled )
		end
	end

end

function ArkInventory:LISTEN_ADDON_ACTION_BLOCKED( event, addon, blocked )

	-- Event args differ slightly across clients; keep it defensive.
	-- Typical signatures:
	--   ADDON_ACTION_BLOCKED(addonName, functionName)
	--   ADDON_ACTION_FORBIDDEN(addonName, functionName)
	if not ArkInventory.Const.Debug then
		return
	end

	ArkInventory.OutputDebug( "Taint event:", event, ", addon=", addon or "?", ", blocked=", blocked or "?" )

end

function ArkInventory.LocationIsMonitored( loc_id ) -- listen for changes in this location
	return ArkInventory.Global.Me.monitor[loc_id]
end

function ArkInventory.LocationIsControlled( loc_id )
	return ArkInventory.Global.Me.control[loc_id]
end

function ArkInventory.LocationIsSaved( loc_id )
	return ArkInventory.Global.Me.save[loc_id]
end

function ArkInventory.DisplayName1( p )
	-- window titles (normal)
	return string.format( "%s\n%s > %s", p.name or ArkInventory.Localise["UNKNOWN"], p.faction_local or ArkInventory.Localise["UNKNOWN"], p.realm or ArkInventory.Localise["UNKNOWN"] )
end

function ArkInventory.DisplayName2( p )
	-- switch menu
	return string.format( "%s > %s > %s", p.realm or ArkInventory.Localise["UNKNOWN"], p.faction_local or ArkInventory.Localise["UNKNOWN"], p.name or ArkInventory.Localise["UNKNOWN"] )
end

function ArkInventory.DisplayName3( p )
	-- tooltip item count
	return string.format( "%s%s|r", ArkInventory.ClassColourCode( p.class ), p.name or ArkInventory.Localise["UNKNOWN"] )
end

function ArkInventory.DisplayName4( p )
	-- switch character
	return string.format( "%s%s (%s:%s) |cff7f7f7f[%s]|r", ArkInventory.ClassColourCode( p.class ), p.name or ArkInventory.Localise["UNKNOWN"], p.class_local or ArkInventory.Localise["UNKNOWN"], p.level or ArkInventory.Localise["UNKNOWN"], p.faction_local or ArkInventory.Localise["UNKNOWN"] )
end

function ArkInventory.DisplayName5( p )
	-- window titles (thin)
	return string.format( "%s", p.name or ArkInventory.Localise["UNKNOWN"] )
end

function ArkInventory.MemoryUsed( c )

	if c then
		collectgarbage( "stop" )
	end

	--UpdateAddOnMemoryUsage( )

	--local am = GetAddOnMemoryUsage( ArkInventory.Const.Program.Name ) * 1000
	local am = collectgarbage( "count" )

	if not c then
		collectgarbage( "restart" )
	end

	return am

end

function ArkInventory.ItemAgeUpdate( )
	return math.floor( time( date( '*t' ) ) / 60 ) -- minutes
end

function ArkInventory.ItemAgeGet( age )

	if age and type( age ) == "number" then

		local s = ArkInventory.Localise["DHMS"]

		local x = ArkInventory.ItemAgeUpdate( ) - age
		local m = x + 1 -- push seconds up so that items with less than a minute get displayed

		local d = math.floor( m / 1440 )
		m = math.floor( m - d * 1440 )
		local h = math.floor( m / 60 )
		m = math.floor( m - h * 60 )

		local t = ""

--[[
		if d > 0 then
			t = string.format( "%d%s ", d, string.sub( s, 1, 1 ) )
		end

		if h > 0 or ( d > 0 and m > 0 ) then
			t = string.format( "%s%d%s ", t, h, string.sub( s, 2, 2 ) )
		end

		if m > 0 and d == 0 then -- only show minutes if were not into days
			t = string.format( "%s%d%s", t, m, string.sub( s, 3, 3 ) )
		end
]]--

		if d > 0 then
			t = string.format( "%d:%d%s", d, h, string.sub( s, 1, 1 ) )
		elseif h > 0 then
			t = string.format( "%d:%d%s", h, m, string.sub( s, 2, 2 ) )
		else
			t = string.format( "%d%s", m, string.sub( s, 3, 3 ) )
		end

		return x, strtrim( t )

	end

	return false, ""

end

function ArkInventory.StartupChecks( )

	-- erase leftover partial data
	for p, pd in pairs( ArkInventory.db.realm.player.data ) do

		local wipe = false

		if pd.info and not pd.info.name then
			wipe = true
		end

		local c = 0
		for l, ld in pairs( pd.location ) do
			c = c + ld.slot_count
		end

		if c == 0 then
			wipe = true
		end

		if wipe then
			ArkInventory.EraseSavedData( p, nil, false )
		end

	end











	if true then return end

	for k, v in pairs( ArkInventory.Localise ) do

		if string.sub( k, 1, 13 ) == "WOW_ITEM_TYPE" then
			ArkInventory.Output( k, " = ", v )
		end

		if string.sub( k, 1, 9 ) == "WOW_SKILL" then
			ArkInventory.Output( k, " = ", v )
		end

	end

end
