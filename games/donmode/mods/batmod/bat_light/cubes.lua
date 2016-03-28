--Bat White Light Cube
--------------------------------------------------------------------------------
minetest.register_node("bat_light:bat_light_cube_white", {
	description = "Bat Light Cube  White",
	tiles = {"bat_light_cube.png"},
	drawtype = "allfaces",
	paramtype = "none",
	groups = {snappy=2},
--	sunlight_propagates = true,
	light_source = 14,

})


--Crafts
---------------------------------------------------
--Bat Light Cube
minetest.register_craft({
	output = "bat_light:bat_light_cube_white 9",
	recipe = {
		{'bat_blocks:bat_color_white', 'bat_blocks:bat_color_white', 'bat_blocks:bat_color_white'},
		{'bat_blocks:bat_color_white', 'default:torch', 'bat_blocks:bat_color_white'},
		{'bat_blocks:bat_color_white', 'bat_blocks:bat_color_white', 'bat_blocks:bat_color_white'}
	}
})

--Bat Light Cube Yellow
--------------------------------------------------------------------------------
minetest.register_node("bat_light:bat_light_cube_yellow", {
	description = "Bat Light Cube Yellow",
	tiles = {"bat_light_cube_yellow.png"},
	drawtype = "allfaces",
	paramtype = "none",
	groups = {snappy=2},
	sunlight_propagates = true,
	light_source = 14,

})


--Crafts
---------------------------------------------------
--Bat Light Cube
minetest.register_craft({
	output = "bat_light:bat_light_cube_yellow 9",
	recipe = {
		{'bat_blocks:bat_color_yellow', 'bat_blocks:bat_color_yellow', 'bat_blocks:bat_color_yellow'},
		{'bat_blocks:bat_color_yellow', 'default:torch', 'bat_blocks:bat_color_yellow'},
		{'bat_blocks:bat_color_yellow', 'bat_blocks:bat_color_yellow', 'bat_blocks:bat_color_yellow'}
	}
})

--Bat Light Cube Red
--------------------------------------------------------------------------------
minetest.register_node("bat_light:bat_light_cube_red", {
	description = "Bat Light Cube Red",
	tiles = {"bat_light_cube_red.png"},
	drawtype = "allfaces",
	paramtype = "none",
	groups = {snappy=2},
	sunlight_propagates = true,
	light_source = 14,

})




--Crafts
---------------------------------------------------
--Bat Light Cube
minetest.register_craft({
	output = "bat_light:bat_light_cube_red 9",
	recipe = {
		{'bat_blocks:bat_color_red', 'bat_blocks:bat_color_red', 'bat_blocks:bat_color_red'},
		{'bat_blocks:bat_color_red', 'default:torch', 'bat_blocks:bat_color_red'},
		{'bat_blocks:bat_color_red', 'bat_blocks:bat_color_red', 'bat_blocks:bat_color_red'}
	}
})

--Bat Light Cube Blue
--------------------------------------------------------------------------------
minetest.register_node("bat_light:bat_light_cube_blue", {
	description = "Bat Light Cube Blue",
	tiles = {"bat_light_cube_blue.png"},
	drawtype = "allfaces",
	paramtype = "none",
	groups = {snappy=2},
	sunlight_propagates = true,
	light_source = 14,

})




--Crafts
---------------------------------------------------
--Bat Light Cube
minetest.register_craft({
	output = "bat_light:bat_light_cube_blue 9",
	recipe = {
		{'bat_blocks:bat_color_blue', 'bat_blocks:bat_color_blue', 'bat_blocks:bat_color_blue'},
		{'bat_blocks:bat_color_blue', 'default:torch', 'bat_blocks:bat_color_blue'},
		{'bat_blocks:bat_color_blue', 'bat_blocks:bat_color_blue', 'bat_blocks:bat_color_blue'}
	}
})

--Bat Light Cube Green
--------------------------------------------------------------------------------
minetest.register_node("bat_light:bat_light_cube_green", {
	description = "Bat Light Cube Green",
	tiles = {"bat_light_cube_green.png"},
	drawtype = "allfaces",
	paramtype = "none",
	groups = {snappy=2},
	sunlight_propagates = true,
	light_source = 14,

})




--Crafts
---------------------------------------------------
--Bat Light Cube
minetest.register_craft({
	output = "bat_light:bat_light_cube_green 9",
	recipe = {
		{'bat_blocks:bat_color_green', 'bat_blocks:bat_color_green', 'bat_blocks:bat_color_green'},
		{'bat_blocks:bat_color_green', 'default:torch', 'bat_blocks:bat_color_green'},
		{'bat_blocks:bat_color_green', 'bat_blocks:bat_color_green', 'bat_blocks:bat_color_green'}
	}
})

--Bat Light Cube Orange
--------------------------------------------------------------------------------
minetest.register_node("bat_light:bat_light_cube_orange", {
	description = "Bat Light Cube Orange",
	tiles = {"bat_light_cube_orange.png"},
	drawtype = "allfaces",
	paramtype = "none",
	groups = {snappy=2},
	sunlight_propagates = true,
	light_source = 14,

})




--Crafts
---------------------------------------------------
--Bat Light Cube
minetest.register_craft({
	output = "bat_light:bat_light_cube_orange 9",
	recipe = {
		{'bat_blocks:bat_color_orange', 'bat_blocks:bat_color_orange', 'bat_blocks:bat_color_orange'},
		{'bat_blocks:bat_color_orange', 'default:torch', 'bat_blocks:bat_color_orange'},
		{'bat_blocks:bat_color_orange', 'bat_blocks:bat_color_orange', 'bat_blocks:bat_color_orange'}
	}
})
