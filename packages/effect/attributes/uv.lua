local mathpkg = import_package "ant.math"
local mu = mathpkg.util

return {
    init = function (world, emittereid, attrib)
        local emitter = world[emittereid]._emitter
        emitter.uv_speed = mu.random(attrib.speed_range)
    end,
    update = function (world, emittereid, attrib, deltatime)
        local iqc = world:interface "ant.render|iquadcache"
        local emitter = world[emittereid]._emitter
        local delta_uv = emitter.uv_speed * deltatime

        for ii=1, emitter.quad_count do
            local vertexoffset = (ii-1) * 4
            for jj=1, 4 do
                local vertexidx = vertexoffset + jj
                local u, v = iqc.vertex_texcoord(vertexidx)
                iqc.set_vertex_texcoord(vertexidx, u+delta_uv, v+delta_uv)
            end
        end
    end
}