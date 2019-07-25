local native = require "window.native"
local window = require "window"

local inputmgr = import_package "ant.inputmgr"
local keymap = inputmgr.keymap

local assetutil = import_package "ant.asset".util
local renderpkg = import_package "ant.render"
local viewidmgr = renderpkg.viewidmgr
local rhwi = renderpkg.hardware_interface
local bgfx = require "bgfx"

local imgui = require "imgui"
local platform = require "platform"
local font = imgui.font
local Font = platform.font
local imguiIO = imgui.IO

local LOGERROR = __ANT_RUNTIME__ and log.error or print
local debug_update = __ANT_RUNTIME__ and require 'runtime.debug'

local iq = inputmgr.queue()

local callback = {}

local width, height
local packages, systems
local world
local world_update

local ui_viewid = viewidmgr.generate "ui"

local function imgui_resize(width, height)
	local xdpi, ydpi = rhwi.dpi()
	local xscale = math.floor(xdpi/96.0+0.5)
	local yscale = math.floor(ydpi/96.0+0.5)
	imgui.resize(width/xscale, height/yscale, xscale, yscale)
end

function callback.init(nwh, context, w, h)
	width, height = w, h

	imgui.create(nwh)
	rhwi.init {
		nwh = nwh,
		context = context,
		width = width,
		height = height,
	}
	
	local ocornut_imgui = assetutil.shader_loader {
		vs = "/pkg/ant.imgui/shader/vs_ocornut_imgui",
		fs = "/pkg/ant.imgui/shader/fs_ocornut_imgui",
	}
	local imgui_image = assetutil.shader_loader {
		vs = "/pkg/ant.imgui/shader/vs_imgui_image",
		fs = "/pkg/ant.imgui/shader/fs_imgui_image",
	}

	imgui.viewid(ui_viewid);
	imgui.program(
		ocornut_imgui.prog,
		imgui_image.prog,
		ocornut_imgui.uniforms.s_tex.handle,
		imgui_image.uniforms.u_imageLodEnabled.handle
	)
	imgui_resize(width, height)
	imgui.keymap(native.keymap)
	window.set_ime(imgui.ime_handle())
	if platform.OS == "Windows" then
		font.Create { { Font "黑体" ,     18, "\x20\x00\xFF\xFF\x00"} }
	elseif platform.OS == "macOS" then
		font.Create { { Font "华文细黑" , 18, "\x20\x00\xFF\xFF\x00"} }
	else -- iOS
		font.Create { { Font "Heiti SC" , 18, "\x20\x00\xFF\xFF\x00"} }
	end

	local su = import_package "ant.scene".util
	world = su.start_new_world(iq, width, height, packages, systems)
	world_update = su.loop(world, {
		update = {"timesystem", "message_system"}
	})
end

function callback.error(err)
	LOGERROR(err)
end

function callback.mouse_wheel(x, y, delta)
	imgui.mouse_wheel(x, y, delta)
	if not imguiIO.WantCaptureMouse then
		iq:push("mouse_wheel", x, y, delta)
	end
end

function callback.mouse(x, y, what, state)
	imgui.mouse(x, y, what, state)
	if not imguiIO.WantCaptureMouse then
		iq:push("mouse", x, y, inputmgr.translate_mouse_button(what), inputmgr.translate_mouse_state(state))
	end
end

local touchid

function callback.touch(x, y, id, state)
	if state == 1 then
		if not touchid then
			touchid = id
			imgui.mouse(x, y, 1, state)
		end
	elseif state == 2 then
		if touchid == id then
			imgui.mouse(x, y, 1, state)
		end
	elseif state == 3 then
		if touchid == id then
			imgui.mouse(x, y, 1, state)
			touchid = nil
		end
	end
	if not imguiIO.WantCaptureMouse then
		iq:push("touch", x, y, id, inputmgr.translate_mouse_state(state))
	end
end

function callback.keyboard(key, press, state)
	imgui.key_state(key, press, state)
	if not imguiIO.WantCaptureKeyboard then
		iq:push("keyboard", keymap[key], press, inputmgr.translate_key_state(state))
	end 
end

callback.char = imgui.input_char

function callback.size(width,height,_)
	imgui_resize(width,height)
	iq:push("resize", width,height)
	rhwi.reset(nil, width, height)
end

function callback.exit()
	imgui.destroy()
	rhwi.shutdown()
    print "exit"
end

function callback.update()
	if debug_update then debug_update() end
	if world_update then
		world_update()
		bgfx.frame()
	end
end

local function start(m1, m2)
	packages, systems = m1, m2
	window.register(callback)
	native.create(1024, 768, "Hello")
    native.mainloop()
end

return {
    start = start
}
