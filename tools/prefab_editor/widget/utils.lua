local imgui     = require "imgui"
local m = {}

local function ONCE(t, s)
    if not s then return t end
end
local windiwsBegin = imgui.windows.Begin
local windiwsEnd = setmetatable({}, { __close = imgui.windows.End })

function m.imgui_windows(...)
	windiwsBegin(...)
	return ONCE, windiwsEnd, nil, windiwsEnd
end

function m.imguiBeginToolbar()
    imgui.windows.PushStyleColor(imgui.enum.StyleCol.Button, 0, 0, 0, 0)
    imgui.windows.PushStyleColor(imgui.enum.StyleCol.ButtonActive, 0, 0, 0, 0)
    imgui.windows.PushStyleColor(imgui.enum.StyleCol.ButtonHovered, 0.5, 0.5, 0.5, 0)
    imgui.windows.PushStyleVar(imgui.enum.StyleVar.ItemSpacing, 4, 0)
    imgui.windows.PushStyleVar(imgui.enum.StyleVar.FramePadding, 0, 0)
end

function m.imguiEndToolbar()
    imgui.windows.PopStyleVar(2)
    imgui.windows.PopStyleColor(3)
end

local function imgui_tooltip(text, wrap)
    if imgui.util.IsItemHovered() then
        imgui.widget.BeginTooltip()
        imgui.widget.TextWrapped(text, wrap or 200)
        imgui.widget.EndTooltip()
    end
end

function m.imguiToolbar(icon, tooltip, active)
    local bg_col
    if active then
        bg_col = {0, 0, 0, 1}
    else
        bg_col = {0.2, 0.2, 0.2, 1}
    end
    local r = imgui.widget.ImageButton(icon.handle, icon.texinfo.width, icon.texinfo.height,
                {frame_padding = 2, bg_col = bg_col, tint_col = {1.0, 1.0, 1.0, 1.0}})
    if tooltip then
        imgui_tooltip(tooltip)
    end
    return r
end

local message = {
    
}
function m.message_box(msg)
    message[#message + 1] = msg
end

local message_pop_id = "Message Box"
function m.show_message_box()
    if #message < 1 then return end
    local level = 1
    local function do_show_message(msg)
        imgui.windows.OpenPopup(msg.title)
        local change, opened = imgui.windows.BeginPopupModal(msg.title, imgui.flags.Window{"AlwaysAutoResize"})
        if change then
            imgui.widget.Text(msg.info)
            level = level + 1
            if level <= #message then
                do_show_message(message[level])
            end
            if imgui.widget.Button("Close") then
                message[level - 1] = nil
                imgui.windows.CloseCurrentPopup()
            end
            imgui.windows.EndPopup()
        end
    end
    do_show_message(message[level])
end

local rhwi          = import_package 'ant.render'.hwi
local stringify     = import_package "ant.serialize".stringify
local filedialog    = require 'filedialog'
function m.get_saveas_path(filetype, extension)
    local dialog_info = {
        Owner = rhwi.native_window(),
        Title = "Save As..",
        FileTypes = {filetype, "*"..extension}
    }
    local ok, path = filedialog.save(dialog_info)
    if ok then
        path = string.gsub(path, "\\", "/") .. extension
        local pos = string.find(path, "%"..extension)
        if #path > pos + #extension - 1 then
            path = string.sub(path, 1, pos + #extension - 1)
        end
        --utils.write_file(path, stringify(data))
        return path
    end
end
return m