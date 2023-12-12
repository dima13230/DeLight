local core_ex = require("delight.utils.core_extended")

local M = {}

local lights = {}
local light_sprites = {}

local render_target_size = 0

local id = 0
local sprite_id = 0

local WHITE = vmath.vector4(1, 1, 1, 1)
local BLACKTRANSPARENT = vmath.vector4(0, 0, 0, 0)

local quad_pred = nil
local clear_color = nil

local MAX_LIGHT_COUNT = 9
local light_sprite_constants = nil

-- draw lights to quad with shadow_map as input texture
local function draw_light(light, view, projection)
	
	local window_width = render.get_window_width()
	local window_height = render.get_window_height()
	local size = math.max(window_width, window_height)

	render.set_viewport(0, 0, window_width, window_height)
	render.set_projection(projection)
	render.set_view(view)

	render.set_render_target(render.RENDER_TARGET_DEFAULT)
	render.enable_texture(0, light.shadowmap, render.BUFFER_COLOR_BIT)

	local constants = render.constant_buffer()
	constants.light_pos = vmath.vector4(light.position.x, light.position.y, light.position.z, 0)
	constants.size = vmath.vector4(light.size, 0, 0, 0)
	constants.color = light.color
	constants.falloff = vmath.vector4(light.falloff, 0, 0, 0)
	constants.angle = vmath.vector4(light.angle.x, light.angle.y, light.angle.z, light.angle.w)
	constants.draw_point = vmath.vector4(light.draw_point and 1 or 0, 0, 0, 0)
	constants.point_transparency = vmath.vector4(light.point_transparency, 0, 0, 0)

	render.draw(quad_pred, { constants = constants })
	
	render.disable_texture(0, light.shadowmap)
end

-- draw 1D shadow map containing distance to occluder
-- draw using the shadow_map.material
-- use the occluder_target as input
local function draw_shadow_map(light)
	-- Set viewport
	render.set_viewport(0, 0, light.size, 1)

	-- Set projection
	render.set_projection(vmath.matrix4_orthographic(0, light.size, 0, 1, -10, 10))

	-- Set view matrix to middle
	render.set_view(
	vmath.matrix4_look_at(
	vmath.vector3(-light.size_half, -light.size_half, 0),
	vmath.vector3(-light.size_half, -light.size_half, -1),
	vmath.vector3(0, 1, 0)))

	render.set_render_target_size(light.shadowmap, light.size, 1)
	render.set_render_target(light.shadowmap, { transient = { render.BUFFER_DEPTH_BIT } } )

	-- Clear then draw
	render.clear({[render.BUFFER_COLOR_BIT] = BLACKTRANSPARENT})

	render.enable_material("shadow_map")
	render.enable_texture(0, light.occluder, render.BUFFER_COLOR_BIT)

	-- Constants
	local constants = render.constant_buffer()
	constants.resolution = vmath.vector4(light.size)
	constants.size = vmath.vector4(light.size, light.size, 1, 0)

	render.draw(quad_pred, { constants = constants })

	-- Reset
	render.disable_texture(0, light.occluder)
	render.disable_material()
	render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

-- draw anything that should occlude light (ie with occluder predicate tag)
-- draw it to a low res render target (occluder_target)
local function draw_occluder(light, view, projection, occluder_predicate)
	render.set_render_target_size(light.occluder, light.size, light.size)

	-- Set viewport
	render.set_viewport(0, 0, light.size, light.size)

	-- Set projection so occluders fill the render target
	render.set_projection(vmath.matrix4_orthographic(0, light.size, 0, light.size, -5, 5))

	-- Set view matrix to light position
	render.set_view(
	vmath.matrix4_look_at(
	vmath.vector3(-light.size_half, -light.size_half, 0) + light.position,
	vmath.vector3(-light.size_half, -light.size_half, -1) + light.position,
	vmath.vector3(0, 1, 0)))

	-- Clear then draw
	render.set_render_target(light.occluder, { transient = { render.BUFFER_DEPTH_BIT } } )
	render.clear({[render.BUFFER_COLOR_BIT] = BLACKTRANSPARENT})

	-- Draw occluder
	render.set_depth_mask(false)
	render.disable_state(render.STATE_DEPTH_TEST)
	render.disable_state(render.STATE_STENCIL_TEST)
	render.enable_state(render.STATE_BLEND)
	render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)
	render.disable_state(render.STATE_CULL_FACE)

	render.draw(occluder_predicate)

	-- Reset render target
	render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

local function draw_light_sprite(view, light_sprite_predicate)
	-- Draw occluder
	render.set_depth_mask(false)
	render.disable_state(render.STATE_DEPTH_TEST)
	render.disable_state(render.STATE_STENCIL_TEST)
	render.enable_state(render.STATE_BLEND)
	render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)
	render.disable_state(render.STATE_CULL_FACE)

	local constants = render.constant_buffer()

	constants.ambient_color = clear_color
	constants.lightsAmount = vmath.vector4(core_ex.tablelength(lights), 0, 0, 0)
	constants.lightPositions = core_ex.newtable(vmath.vector4(), MAX_LIGHT_COUNT)
	constants.lightColors = core_ex.newtable(vmath.vector4(), MAX_LIGHT_COUNT)
	constants.lightRadiuses = core_ex.newtable(vmath.vector4(), MAX_LIGHT_COUNT)
	constants.lightAngles = core_ex.newtable(vmath.vector4(), MAX_LIGHT_COUNT)
	constants.lightEnabled = core_ex.newtable(vmath.vector4(), MAX_LIGHT_COUNT)
	constants.shadowmapViewProjs = core_ex.newtable(vmath.matrix4(), MAX_LIGHT_COUNT)
	
	-- Assuming you have an array of light positions and colors
	for i, light in ipairs(lights) do
		constants.lightPositions[i] = vmath.vector4(light.position.x, light.position.y, light.position.z, 0)
		constants.lightColors[i] = vmath.vector4(light.color.x, light.color.y, light.color.z, light.color.w)
		constants.lightRadiuses[i] = vmath.vector4(light.radius, 0, 0, 0)
		constants.lightAngles[i] = vmath.vector4(light.angle.x, light.angle.y, light.angle.z, light.angle.w)
		constants.lightEnabled[i] = vmath.vector4(light.enabled and 1 or 0, 0, 0, 0)

		local viewMatrix = vmath.matrix4_look_at(
		vmath.vector3(-light.size_half, -light.size_half, 0),
		vmath.vector3(-light.size_half, -light.size_half, -1),
		vmath.vector3(0, 1, 0))
		
		local projectionMatrix = vmath.matrix4_orthographic(0, light.size, 0, 1, -10, 10)
		local viewProjMatrix = projectionMatrix * viewMatrix
		
		constants.shadowmapViewProjs[i] = viewProjMatrix
	end

	render.set_render_target(render.RENDER_TARGET_DEFAULT)
	for i, light in pairs(lights) do
		if light.enabled then
			if light.shadowmap then
				render.enable_texture(i, light.shadowmap, render.BUFFER_COLOR_BIT)
			end
		end
	end
	render.draw(light_sprite_predicate, {constants = constants})
	for i, light in pairs(lights) do
		if light.enabled then
			if light.shadowmap then
				render.disable_texture(i)
			end
		end
	end
end

local function create_occluder(light, size)
	local params = {
		format = render.FORMAT_RGBA,
		width = size,
		height = size,
		min_filter = render.FILTER_LINEAR,
		mag_filter = render.FILTER_LINEAR,
		u_wrap = render.WRAP_CLAMP_TO_EDGE,
		v_wrap = render.WRAP_CLAMP_TO_EDGE
	}
	local rt = render.render_target({[render.BUFFER_COLOR_BIT] = params})
	if not light then return rt end
	light.occluder = rt
end
	
local function resize_occluder(light, size)
	render.set_render_target_size(light.occluder, size, size)
end

local function create_shadowmap(light, size)
	local params = {
		format = render.FORMAT_RGBA,
		width = size,
		height = 1,
		min_filter = render.FILTER_LINEAR,
		mag_filter = render.FILTER_LINEAR,
		u_wrap = render.WRAP_CLAMP_TO_EDGE,
		v_wrap = render.WRAP_CLAMP_TO_EDGE
	}
	local rt = render.render_target({[render.BUFFER_COLOR_BIT] = params})
	if not light then return rt end
	light.shadowmap = rt
end

local function resize_shadowmap(light, size)
	render.set_render_target_size(light.shadowmap, size, 1)
end


function M.init(config)
	local width = render.get_window_width()
	local height = render.get_window_height()
	render_target_size = math.max(width, height)
	quad_pred = render.predicate({ "light_quad" })
	clear_color = vmath.vector4(0,0,0,1)
end

function M.set_clear_color(color)
	clear_color = color
end

function M.draw(view, projection, occluder_predicate, light_sprite_predicate)
	local width = render.get_window_width()
	local height = render.get_window_height()
	local size = math.max(width, height)
	local size_changed = render_target_size ~= size
	render_target_size = size
	
	for i,light in pairs(lights) do
		if light.remove then
			render.delete_render_target(light.occluder)
			render.delete_render_target(light.shadowmap)
			lights[light.id] = nil
		elseif light.enabled then
			if not light.occluder then create_occluder(light, size) end
			if not light.shadowmap then create_shadowmap(light, size) end
			if size_changed then
				resize_occluder(light, size)
				resize_shadowmap(light, size)
			end
			local light_size = math.ceil(light.radius * 2)
			light.size = light_size
			light.size_half = light_size / 2
			if light.size >= 1 then
				draw_occluder(light, view, projection, occluder_predicate)
				draw_shadow_map(light)
				draw_light(light, view, projection)
			end
		end
	end
	draw_light_sprite(view, light_sprite_predicate)
end


function M.add(properties)
	assert(properties)
	assert(properties.radius, "You must specify a radius")
	assert(properties.position, "You must specify a position")

	id = id + 1

	lights[id] = {
		id = id,
		position = properties.position,
		color = properties.color or WHITE,
		angle = properties.angle or 360,
		radius = properties.radius,
		enabled = properties.enabled,
		draw_point = properties.draw_point,
		point_transparency = properties.point_transparency,
		falloff = properties.falloff,
		occluder = nil,
		shadowmap = nil,
	}

	return id
end

function M.add_sprite(properties)
	assert(properties)

	sprite_id = sprite_id + 1
	light_sprites[sprite_id] = {
		id = sprite_id,
		position = properties.position,
		size = properties.size,
		normal_map = properties.normal_map,
	}

	return sprite_id
end

function M.remove(id)
	assert(id)
	assert(lights[id], "Unable to find light")
	local light = lights[id]
	light.remove = true
end

function M.remove_sprite(id)
	assert(id)
	assert(light_sprites[id], "Unable to find sprite")
	local sprite = light_sprites[id]
	light_sprites.remove = true
end

function M.set_light_radius(id, radius)
	assert(id)
	assert(lights[id], "Unable to find light")
	assert(radius, "You must provide a radius")
	local light = lights[id]
	light.radius = radius
end

function M.set_position(id, position)
	assert(id)
	assert(lights[id], "Unable to find light")
	assert(position, "You must provide a position")
	lights[id].position = position
end

function M.set_angle(id, angle)
	assert(id)
	assert(lights[id], "Unable to find light")
	assert(angle, "You must provide an angle")
	lights[id].angle = angle
end

function M.set_color(id, color)
	assert(id)
	assert(lights[id], "Unable to find light")
	assert(color, "You must provide a color")
	lights[id].color = color
end

function M.set_enabled(id, enabled)
	assert(id)
	assert(lights[id], "Unable to find light")
	lights[id].enabled = enabled
end

return M