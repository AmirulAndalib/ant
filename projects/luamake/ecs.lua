local argn = select("#", ...)
if argn < 3 then
    print [[
at least 3 argument:
ecs.lua component.lua component.h package1, package2, ...
package1 and package2 are path to find *.ecs file
    ]]
    return
end
local component_lua, component_h = select(1, ...), select(2, ...)
local packages = {}
for i=3, select('#', ...) do
    packages[i-2] = select(i, ...)
end

local fs = require "bee.filesystem"

local function createEnv(class)
    local function dummy()
        return function ()
            local o = {}
            local mt = {}
            function mt:__index()
                return function ()
                    return o
                end
            end
            return setmetatable(o, mt)
        end
    end
    local function object(object_name)
        local c = {}
        class[object_name] = c
        return function (name)
            local cc = {}
            c[name] = cc

            local o = {}
            local mt = {}
            function mt:__index(key)
                return function (value)
                    if cc[key] then
                        table.insert(cc[key], value)
                    else
                        cc[key] = {value}
                    end
                    return o
                end
            end
            return setmetatable(o, mt)
        end
    end
    return {
        import = function() end,
        pipeline = dummy(),
        system = dummy(),
        policy = dummy(),
        interface = dummy(),
        component = object "component",
    }
end

local function loadComponents()
    local class = {}
    local env = createEnv(class)
    local function eval(filename)
        assert(loadfile(filename:string(), "t", env))()
    end
    for _, pkgpath in ipairs(packages) do
        for file in fs.pairs(pkgpath, "r") do
            if file:equal_extension "ecs" then
                eval(file)
            end
        end
    end

    local components = {}
    for name, info in pairs(class.component) do
        if not info.type then
            components[#components+1] = {name, "tag"}
        else
            local t = info.type[1]
            if t == "lua" then
                components[#components+1] = {name, "tag"}
            elseif t == "c" then
                components[#components+1] = {name, "c", info.field}
            else
                components[#components+1] = {name, t}
            end
        end
    end
    table.sort(components, function (a, b)
        return a[1] < b[1]
    end)
    return components
end

local components = loadComponents()


local out = {}

local function writefile(filename)
    local f <close> = assert(io.open(filename, "w"))
    f:write(table.concat(out, "\n"))
    out = {}
end

local function write(line)
    out[#out+1] = line
end

write "return {"
for _, info in ipairs(components) do
    local name = info[1]
    write(("\t%q,"):format(name))
end
write "}"
write ""
writefile(component_lua)

local TYPENAMES <const> = {
    int = "int32_t",
    int64 = "int64_t",
    dword = "uint32_t",
    word = "uint16_t",
    byte = "uint8_t",
    float = "float",
    userdata = "intptr_t",
}

do
    local id = 0x80000000
    local function write_id(name)
        id = id + 1
        write(("#define COMPONENT_%s 0x%08x"):format(name:upper(), id))
    end

    local function write_type(name, type)
        write(("typedef %s component_%s;"):format(TYPENAMES[type], name))
    end

    local function write_cstruct(name, fields)
        write(("struct component_%s {"):format(name))
        for _, field in ipairs(fields) do
            local name, typename = field:match "^([%w_]+):(%w+)$"
            write(("\t%s %s;"):format(TYPENAMES[typename], name))
        end
        write("};")
    end

    write "#pragma once"
    write ""
    write "#include <stdint.h>"
    write ""
    for _, info in ipairs(components) do
        write_id(info[1])
    end
    write ""
    for _, info in ipairs(components) do
        local name, type, fields = info[1], info[2], info[3]
        if type == "c" then
            write_cstruct(name, fields)
        elseif type ~= "tag" then
            write_type(name, type)
        end
    end
    write ""

    writefile(component_h .. "/component.h")
end

do
    write "#pragma once"
    write ""
    write "#include <stdint.h>"
    write ""
    write "namespace ant_ecs {"
    write ""
    write "struct REMOVED {};"
    write ""
    for _, info in ipairs(components) do
        local name, type, fields = info[1], info[2], info[3]
        if type == "c" then
            write(("struct %s {"):format(name))
            for _, field in ipairs(fields) do
                local name, typename = field:match "^([%w_]+):(%w+)$"
                write(("\t%s %s;"):format(TYPENAMES[typename], name))
            end
            write("};")
            write ""
        elseif type == "tag" then
            write(("struct %s {};"):format(name))
            write ""
        else
            write(("using %s = %s;"):format(name, TYPENAMES[type]))
            write ""
        end
    end
    write "}"
    write ""
    write "struct ant_ecs_component_id {"
    write "\tinline static int id = 0x80000000;"
    write "\tinline static int gen() {"
    write "\t\treturn id++;"
    write "\t}"
    write "};"
    write ""
    write "namespace ecs = ant_ecs;"
    write ""

    write "namespace ecs_api {"
    write ""
    write "template <typename T> struct component {};"
    write ""
    write "#define ECS_COMPONENT(NAME) \\"
    write "template <> struct component<ecs::##NAME> { \\"
    write "\tstatic inline const int id = ant_ecs_component_id::gen(); \\"
    write "\tstatic inline const char name[] = #NAME; \\"
    write "};"
    write ""
    write("ECS_COMPONENT(REMOVED)")
    for _, c in ipairs(components) do
        write("ECS_COMPONENT("..c[1]..")")
    end
    write ""
    write "#undef ECS_COMPONENT"
    write ""
    write "}"
    write ""

    writefile(component_h .. "/component.hpp")
end
