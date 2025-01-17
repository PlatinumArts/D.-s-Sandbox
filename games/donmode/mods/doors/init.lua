
--[[

Copyright (C) 2012 PilzAdam
  modified by BlockMen (added sounds, glassdoors[glass, obsidian glass], trapdoor)
Copyright (C) 2015 - Auke Kok <sofar@foo-projects.org>

--]]

-- our API object
doors = {}

-- private data
local _doors = {}
_doors.registered_doors = {}
_doors.registered_trapdoors = {}

-- returns an object to a door object or nil
function doors.get(pos)
	if _doors.registered_doors[minetest.get_node(pos).name] then
		-- A normal upright door
		return {
			pos = pos,
			open = function(self, player)
				if self:state() then
					return false
				end
				return _doors.door_toggle(self.pos, player)
			end,
			close = function(self, player)
				if not self:state() then
					return false
				end
				return _doors.door_toggle(self.pos, player)
			end,
			toggle = function(self, player)
				return _doors.door_toggle(self.pos, player)
			end,
			state = function(self)
				local state = minetest.get_meta(self.pos):get_int("state")
				return state %2 == 1
			end
		}
	elseif _doors.registered_trapdoors[minetest.get_node(pos).name] then
		-- A trapdoor
		return {
			pos = pos,
			open = function(self, player)
				if self:state() then
					return false
				end
				return _doors.trapdoor_toggle(self.pos, player)
			end,
			close = function(self, player)
				if not self:state() then
					return false
				end
				return _doors.trapdoor_toggle(self.pos, player)
			end,
			toggle = function(self, player)
				return _doors.trapdoor_toggle(self.pos, player)
			end,
			state = function(self)
				local name = minetest.get_node(pos).name
				return name:sub(-5) == "_open"
			end
		}
	else
		return nil
	end
end

-- this hidden node is placed on top of the bottom, and prevents
-- nodes from being placed in the top half of the door.
minetest.register_node("doors:hidden", {
	description = "Hidden Door Segment",
	-- can't use airlike otherwise falling nodes will turn to entities
	-- and will be forever stuck until door is removed.
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	-- has to be walkable for falling nodes to stop falling.
	walkable = true,
	pointable = false,
	diggable = false,
	buildable_to = false,
	floodable = false,
	drop = "",
	groups = {not_in_creative_inventory = 1},
	on_blast = function() end,
	tiles = {"doors_blank.png"},
	-- 1px transparent block inside door hinge near node top.
	nodebox = {
		type = "fixed",
		fixed = {-15/32, 13/32, -15/32, -13/32, 1/2, -13/32},
	},
	-- collision_box needed otherise selection box would be full node size
	collision_box = {
		type = "fixed",
		fixed = {-15/32, 13/32, -15/32, -13/32, 1/2, -13/32},
	},
})

-- table used to aid door opening/closing
local transform = {
	{
		{ v = "_a", param2 = 3 },
		{ v = "_a", param2 = 0 },
		{ v = "_a", param2 = 1 },
		{ v = "_a", param2 = 2 },
	},
	{
		{ v = "_b", param2 = 1 },
		{ v = "_b", param2 = 2 },
		{ v = "_b", param2 = 3 },
		{ v = "_b", param2 = 0 },
	},
	{
		{ v = "_b", param2 = 1 },
		{ v = "_b", param2 = 2 },
		{ v = "_b", param2 = 3 },
		{ v = "_b", param2 = 0 },
	},
	{
		{ v = "_a", param2 = 3 },
		{ v = "_a", param2 = 0 },
		{ v = "_a", param2 = 1 },
		{ v = "_a", param2 = 2 },
	},
}

function _doors.door_toggle(pos, clicker)
	local meta = minetest.get_meta(pos)
	local def = minetest.registered_nodes[minetest.get_node(pos).name]
	local name = def.door.name

	local state = meta:get_string("state")
	if state == "" then
		-- fix up lvm-placed right-hinged doors, default closed
		if minetest.get_node(pos).name:sub(-2) == "_b" then
			state = 2
		end
	else
		state = tonumber(state)
	end

	if clicker and not minetest.check_player_privs(clicker, "protection_bypass") then
		local owner = meta:get_string("doors_owner")
		if owner ~= "" then
			if clicker:get_player_name() ~= owner then
				return false
			end
		end
	end

	local old = state
	-- until Lua-5.2 we have no bitwise operators :(
	if state % 2 == 1 then
		state = state - 1
	else
		state = state + 1
	end

	local dir = minetest.get_node(pos).param2
	if state % 2 == 0 then
		minetest.sound_play(def.door.sounds[1], {pos = pos, gain = 0.3, max_hear_distance = 10})
	else
		minetest.sound_play(def.door.sounds[2], {pos = pos, gain = 0.3, max_hear_distance = 10})
	end

	minetest.swap_node(pos, {
		name = name .. transform[state + 1][dir+1].v,
		param2 = transform[state + 1][dir+1].param2
	})
	meta:set_int("state", state)

	return true
end


local function on_place_node(place_to, newnode, placer, oldnode, itemstack, pointed_thing)
	-- Run script hook
	local _, callback
	for _, callback in ipairs(core.registered_on_placenodes) do
		-- Deepcopy pos, node and pointed_thing because callback can modify them
		local place_to_copy = {x = place_to.x, y = place_to.y, z = place_to.z}
		local newnode_copy = {name = newnode.name, param1 = newnode.param1, param2 = newnode.param2}
		local oldnode_copy = {name = oldnode.name, param1 = oldnode.param1, param2 = oldnode.param2}
		local pointed_thing_copy = {
			type  = pointed_thing.type,
			above = vector.new(pointed_thing.above),
			under = vector.new(pointed_thing.under),
			ref   = pointed_thing.ref,
		}
		callback(place_to_copy, newnode_copy, placer, oldnode_copy, itemstack, pointed_thing_copy)
	end
end

function doors.register(name, def)
	if not name:find(":") then
		name = "doors:" .. name
	end

	-- replace old doors of this type automatically
	minetest.register_abm({
		nodenames = {name.."_b_1", name.."_b_2"},
		interval = 7.0,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local l = tonumber(node.name:sub(-1))
			local meta = minetest.get_meta(pos)
			local h = meta:get_int("right") + 1
			local p2 = node.param2
			local replace = {
				{ { type = "a", state = 0 }, { type = "a", state = 3 } },
				{ { type = "b", state = 1 }, { type = "b", state = 2 } }
			}
			local new = replace[l][h]
			-- retain infotext and doors_owner fields
			minetest.swap_node(pos, {name = name .. "_" .. new.type, param2 = p2})
			meta:set_int("state", new.state)
			-- properly place doors:hidden at the right spot
			local p3 = p2
			if new.state >= 2 then
				p3 = (p3 + 3) % 4
			end
			if new.state % 2 == 1 then
				if new.state >= 2 then
					p3 = (p3 + 1) % 4
				else
					p3 = (p3 + 3) % 4
				end
			end
			-- wipe meta on top node as it's unused
			minetest.set_node({x = pos.x, y = pos.y + 1, z = pos.z},
				{name = "doors:hidden", param2 = p3})
		end
	})

	minetest.register_craftitem(":" .. name, {
		description = def.description,
		inventory_image = def.inventory_image,

		on_place = function(itemstack, placer, pointed_thing)
			local pos = nil

			if not pointed_thing.type == "node" then
				return itemstack
			end

			local node = minetest.get_node(pointed_thing.under)
			local pdef = minetest.registered_nodes[node.name]
			if pdef and pdef.on_rightclick then
				return pdef.on_rightclick(pointed_thing.under,
						node, placer, itemstack)
			end

			if pdef and pdef.buildable_to then
				pos = pointed_thing.under
			else
				pos = pointed_thing.above
				node = minetest.get_node(pos)
				pdef = minetest.registered_nodes[node.name]
				if not pdef or not pdef.buildable_to then
					return itemstack
				end
			end

			local above = { x = pos.x, y = pos.y + 1, z = pos.z }
			if not minetest.registered_nodes[minetest.get_node(above).name].buildable_to then
				return itemstack
			end

			local pn = placer:get_player_name()
			if minetest.is_protected(pos, pn) or minetest.is_protected(above, pn) then
				return itemstack
			end

			local dir = minetest.dir_to_facedir(placer:get_look_dir())

			local ref = {
				{ x = -1, y = 0, z = 0 },
				{ x = 0, y = 0, z = 1 },
				{ x = 1, y = 0, z = 0 },
				{ x = 0, y = 0, z = -1 },
			}

			local aside = {
				x = pos.x + ref[dir + 1].x,
				y = pos.y + ref[dir + 1].y,
				z = pos.z + ref[dir + 1].z,
			}

			local state = 0
			if minetest.get_item_group(minetest.get_node(aside).name, "door") == 1 then
				state = state + 2
				minetest.set_node(pos, {name = name .. "_b", param2 = dir})
				minetest.set_node(above, {name = "doors:hidden", param2 = (dir + 3) % 4})
			else
				minetest.set_node(pos, {name = name .. "_a", param2 = dir})
				minetest.set_node(above, {name = "doors:hidden", param2 = dir})
			end

			local meta = minetest.get_meta(pos)
			meta:set_int("state", state)

			if def.protected then
				local pn = placer:get_player_name()
				meta:set_string("doors_owner", pn)
				meta:set_string("infotext", "Owned by " .. pn)
			end

			if not minetest.setting_getbool("creative_mode") then
				itemstack:take_item()
			end

			on_place_node(pos, minetest.get_node(pos), placer, node, itemstack, pointed_thing)

			return itemstack
		end
	})

	local can_dig = function(pos, digger)
		if not def.protected then
			return true
		end
		if minetest.check_player_privs(digger, "protection_bypass") then
			return true
		end
		local meta = minetest.get_meta(pos)
		local name = ""
		if digger then
			name = digger:get_player_name()
		end
		return meta:get_string("doors_owner") == name
	end

	if not def.sounds then
		def.sounds = default.node_sound_wood_defaults()
	end

	if not def.sound_open then
		def.sound_open = "doors_door_open"
	end

	if not def.sound_close then
		def.sound_close = "doors_door_close"
	end

	def.groups.not_in_creative_inventory = 1
	def.groups.door = 1
	def.drop = name
	def.door = {
		name = name,
		sounds = { def.sound_close, def.sound_open },
	}

	def.on_rightclick = function(pos, node, clicker)
		_doors.door_toggle(pos, clicker)
	end
	def.after_dig_node = function(pos, node, meta, digger)
		minetest.remove_node({x = pos.x, y = pos.y + 1, z = pos.z})
		nodeupdate({x = pos.x, y = pos.y + 1, z = pos.z})
	end
	def.can_dig = function(pos, player)
		return can_dig(pos, player)
	end
	def.on_rotate = function(pos, node, user, mode, new_param2)
		return false
	end

	if def.protected then
		def.on_blast = function() end
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			-- hidden node doesn't get blasted away.
			minetest.remove_node({x = pos.x, y = pos.y + 1, z = pos.z})
			return {name}
		end
	end

	def.on_destruct = function(pos)
		minetest.remove_node({x = pos.x, y = pos.y + 1, z = pos.z})
	end

	minetest.register_node(":" .. name .. "_a", {
		description = def.description,
		visual = "mesh",
		mesh = "door_a.obj",
		tiles = def.tiles,
		drawtype = "mesh",
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		use_texture_alpha = true,
		walkable = true,
		is_ground_content = false,
		buildable_to = false,
		drop = def.drop,
		groups = def.groups,
		sounds = def.sounds,
		door = def.door,
		on_rightclick = def.on_rightclick,
		after_dig_node = def.after_dig_node,
		can_dig = def.can_dig,
		on_rotate = def.on_rotate,
		on_blast = def.on_blast,
		on_destruct = def.on_destruct,
		selection_box = {
			type = "fixed",
			fixed = { -1/2,-1/2,-1/2,1/2,3/2,-6/16}
		},
		collision_box = {
			type = "fixed",
			fixed = { -1/2,-1/2,-1/2,1/2,3/2,-6/16}
		},
	})

	minetest.register_node(":" .. name .. "_b", {
		description = def.description,
		visual = "mesh",
		mesh = "door_b.obj",
		tiles = def.tiles,
		drawtype = "mesh",
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		use_texture_alpha = true,
		walkable = true,
		is_ground_content = false,
		buildable_to = false,
		drop = def.drop,
		groups = def.groups,
		sounds = def.sounds,
		door = def.door,
		on_rightclick = def.on_rightclick,
		after_dig_node = def.after_dig_node,
		can_dig = def.can_dig,
		on_rotate = def.on_rotate,
		on_blast = def.on_blast,
		on_destruct = def.on_destruct,
		selection_box = {
			type = "fixed",
			fixed = { -1/2,-1/2,-1/2,1/2,3/2,-6/16}
		},
		collision_box = {
			type = "fixed",
			fixed = { -1/2,-1/2,-1/2,1/2,3/2,-6/16}
		},
	})

	if def.recipe then
		minetest.register_craft({
			output = name,
			recipe = def.recipe,
		})
	end

	_doors.registered_doors[name .. "_a"] = true
	_doors.registered_doors[name .. "_b"] = true
end

doors.register("door_wood", {
		tiles = {{ name = "doors_door_wood.png", backface_culling = true }},
		description = "Wooden Door",
		inventory_image = "doors_item_wood.png",
		groups = { snappy = 1, choppy = 2, oddly_breakable_by_hand = 2, flammable = 2 },
		recipe = {
			{"group:wood", "group:wood"},
			{"group:wood", "group:wood"},
			{"group:wood", "group:wood"},
		}
})

doors.register("door_steel", {
		tiles = {{ name = "doors_door_steel.png", backface_culling = true }},
		description = "Steel Door",
		inventory_image = "doors_item_steel.png",
		protected = true,
		groups = { snappy = 1, bendy = 2, cracky = 1, melty = 2, level = 2 },
		sound_open = "doors_steel_door_open",
		sound_close = "doors_steel_door_close",
		recipe = {
			{"default:steel_ingot", "default:steel_ingot"},
			{"default:steel_ingot", "default:steel_ingot"},
			{"default:steel_ingot", "default:steel_ingot"},
		}
})

doors.register("door_glass", {
		tiles = { "doors_door_glass.png"},
		description = "Glass Door",
		inventory_image = "doors_item_glass.png",
		groups = { snappy=1, cracky=1, oddly_breakable_by_hand=3 },
		sounds = default.node_sound_glass_defaults(),
		recipe = {
			{"default:glass", "default:glass"},
			{"default:glass", "default:glass"},
			{"default:glass", "default:glass"},
		}
})

doors.register("door_obsidian_glass", {
		tiles = { "doors_door_obsidian_glass.png" },
		description = "Obsidian Glass Door",
		inventory_image = "doors_item_obsidian_glass.png",
		groups = { snappy=1, cracky=1, oddly_breakable_by_hand=3 },
		sounds = default.node_sound_glass_defaults(),
		recipe = {
			{"default:obsidian_glass", "default:obsidian_glass"},
			{"default:obsidian_glass", "default:obsidian_glass"},
			{"default:obsidian_glass", "default:obsidian_glass"},
		},
})

-- Capture mods using the old API as best as possible.
function doors.register_door(name, def)
	if def.only_placer_can_open then
		def.protected = true
	end
	def.only_placer_can_open = nil

	local i = name:find(":")
	local modname = name:sub(1, i - 1)
	if not def.tiles then
		if def.protected then
			def.tiles = {{name = "doors_door_steel.png", backface_culling = true}}
		else
			def.tiles = {{name = "doors_door_wood.png", backface_culling = true}}
		end
		minetest.log("warning", modname .. " registered door \"" .. name .. "\" " ..
				"using deprecated API method \"doors.register_door()\" but " ..
				"did not provide the \"tiles\" parameter. A fallback tiledef " ..
				"will be used instead.")
	end

	doors.register(name, def)
end

----trapdoor----

function _doors.trapdoor_toggle(pos, clicker)
	if clicker and not minetest.check_player_privs(clicker, "protection_bypass") then
		local meta = minetest.get_meta(pos)
		local owner = meta:get_string("doors_owner")
		if owner ~= "" then
			if clicker:get_player_name() ~= owner then
				return false
			end
		end
	end

	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]

	if string.sub(node.name, -5) == "_open" then
		minetest.sound_play(def.sound_close, {pos = pos, gain = 0.3, max_hear_distance = 10})
		minetest.swap_node(pos, {name = string.sub(node.name, 1, string.len(node.name) - 5), param1 = node.param1, param2 = node.param2})
	else
		minetest.sound_play(def.sound_open, {pos = pos, gain = 0.3, max_hear_distance = 10})
		minetest.swap_node(pos, {name = node.name .. "_open", param1 = node.param1, param2 = node.param2})
	end
end

function doors.register_trapdoor(name, def)
	local name_closed = name
	local name_opened = name.."_open"

	local function check_player_priv(pos, player)
		if not def.protected or minetest.check_player_privs(player, "protection_bypass") then
			return true
		end
		local meta = minetest.get_meta(pos)
		local pn = player:get_player_name()
		return meta:get_string("doors_owner") == pn
	end

	def.on_rightclick = function(pos, node, clicker)
		_doors.trapdoor_toggle(pos, clicker)
	end

	-- Common trapdoor configuration
	def.drawtype = "nodebox"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.is_ground_content = false
	def.can_dig = check_player_priv

	if def.protected then
		def.after_place_node = function(pos, placer, itemstack, pointed_thing)
			local pn = placer:get_player_name()
			local meta = minetest.get_meta(pos)
			meta:set_string("doors_owner", pn)
			meta:set_string("infotext", "Owned by "..pn)

			return minetest.setting_getbool("creative_mode")
		end

		def.on_blast = function() end
	else
		def.on_blast = function(pos, intensity)
			minetest.remove_node(pos)
			minetest.remove_node({ x = pos.x, y = pos.y + 1, z = pos.z})
			return { name }
		end
	end

	if not def.sounds then
		def.sounds = default.node_sound_wood_defaults()
	end

	if not def.sound_open then
		def.sound_open = "doors_door_open"
	end

	if not def.sound_close then
		def.sound_close = "doors_door_close"
	end

	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_closed.node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -6/16, 0.5}
	}
	def_closed.selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -6/16, 0.5}
	}
	def_closed.tiles = { def.tile_front, def.tile_front, def.tile_side, def.tile_side,
		def.tile_side, def.tile_side }

	def_opened.node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, 6/16, 0.5, 0.5, 0.5}
	}
	def_opened.selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, 6/16, 0.5, 0.5, 0.5}
	}
	def_opened.tiles = { def.tile_side, def.tile_side,
			def.tile_side .. '^[transform3',
			def.tile_side .. '^[transform1',
			def.tile_front, def.tile_front }

	def_opened.drop = name_closed
	def_opened.groups.not_in_creative_inventory = 1

	minetest.register_node(name_opened, def_opened)
	minetest.register_node(name_closed, def_closed)

	_doors.registered_trapdoors[name_opened] = true
	_doors.registered_trapdoors[name_closed] = true
end

doors.register_trapdoor("doors:trapdoor", {
	description = "Trapdoor",
	inventory_image = "doors_trapdoor.png",
	wield_image = "doors_trapdoor.png",
	tile_front = "doors_trapdoor.png",
	tile_side = "doors_trapdoor_side.png",
	groups = {snappy=1, choppy=2, oddly_breakable_by_hand=2, flammable=2, door=1},
})

doors.register_trapdoor("doors:trapdoor_steel", {
	description = "Steel Trapdoor",
	inventory_image = "doors_trapdoor_steel.png",
	wield_image = "doors_trapdoor_steel.png",
	tile_front = "doors_trapdoor_steel.png",
	tile_side = "doors_trapdoor_steel_side.png",
	protected = true,
	sound_open = "doors_steel_door_open",
	sound_close = "doors_steel_door_close",
	groups = {snappy=1, bendy=2, cracky=1, melty=2, level=2, door=1},
})

minetest.register_craft({
	output = 'doors:trapdoor 2',
	recipe = {
		{'group:wood', 'group:wood', 'group:wood'},
		{'group:wood', 'group:wood', 'group:wood'},
		{'', '', ''},
	}
})

minetest.register_craft({
	output = 'doors:trapdoor_steel',
	recipe = {
		{'default:steel_ingot', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot'},
	}
})


----fence gate----

function doors.register_fencegate(name, def)
	local fence = {
		description = def.description,
		drawtype = "mesh",
		tiles = { def.texture },
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		is_ground_content = false,
		drop = name .. "_closed",
		connect_sides = { "left", "right" },
		groups = def.groups,
		sounds = def.sounds,
		on_rightclick = function(pos, clicker)
			local node = minetest.get_node(pos)
			local node_def = minetest.registered_nodes[node.name]
			minetest.swap_node(pos, {name = node_def.gate, param2 = node.param2})
			minetest.sound_play(node_def.sound, {pos = pos, gain = 0.3,
				max_hear_distance = 8})
		end,
		selection_box = {
			type = "fixed",
			fixed = {-1/2, -1/2, -1/4, 1/2, 1/2, 1/4},
		},
	}

	if not fence.sounds then
		fence.sounds = default.node_sound_wood_defaults()
	end

	fence.groups.fence = 1

	local fence_closed = table.copy(fence)
	fence_closed.mesh = "doors_fencegate_closed.obj"
	fence_closed.gate = name .. "_open"
	fence_closed.sound = "doors_fencegate_open"
	fence_closed.collision_box = {
		type = "fixed",
		fixed = {-1/2, -1/2, -1/4, 1/2, 1/2, 1/4},
	}

	local fence_open = table.copy(fence)
	fence_open.mesh = "doors_fencegate_open.obj"
	fence_open.gate = name .. "_closed"
	fence_open.sound = "doors_fencegate_close"
	fence_open.groups.not_in_creative_inventory = 1
	fence_open.collision_box = {
		type = "fixed",
		fixed = {{-1/2, -1/2, -1/4, -3/8, 1/2, 1/4},
			{-5/8, -3/8, -14/16, -3/8, 3/8, 0}},
	}

	minetest.register_node(":" .. name .. "_closed", fence_closed)
	minetest.register_node(":" .. name .. "_open", fence_open)

	minetest.register_craft({
		output = name .. "_closed",
		recipe = {
			{"default:stick", def.material, "default:stick"},
			{"default:stick", def.material, "default:stick"}
		}
	})
end

doors.register_fencegate("doors:gate_wood", {
	description = "Wooden Fence Gate",
	texture = "default_wood.png",
	material = "default:wood",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2}
})

doors.register_fencegate("doors:gate_acacia_wood", {
	description = "Acacia Fence Gate",
	texture = "default_acacia_wood.png",
	material = "default:acacia_wood",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2}
})

doors.register_fencegate("doors:gate_junglewood", {
	description = "Junglewood Fence Gate",
	texture = "default_junglewood.png",
	material = "default:junglewood",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2}
})

doors.register_fencegate("doors:gate_pine_wood", {
	description = "Pine Fence Gate",
	texture = "default_pine_wood.png",
	material = "default:pine_wood",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2}
})

doors.register_fencegate("doors:gate_aspen_wood", {
	description = "Aspen Fence Gate",
	texture = "default_aspen_wood.png",
	material = "default:aspen_wood",
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2}
})
