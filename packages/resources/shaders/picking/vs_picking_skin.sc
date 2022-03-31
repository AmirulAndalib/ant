$input a_position, a_weight, a_indices

/*
 * Copyright 2011-2018 Branimir Karadzic. All rights reserved.
 * License: https://github.com/bkaradzic/bgfx#license-bsd-2-clause
 */

#include <bgfx_shader.sh>
#include "common/curve_world.sh"
#include "common/transform.sh"

#if CURVE_WORLD
uniform mat4 u_viewcamera_viewmat;
uniform mat4 u_viewcamera_inv_viewmat;
#endif //CURVE_WORLD

void main()
{
#if CURVE_WORLD
	vec3 posWS = mul(get_world_matrix(), vec4(a_position, 1.0)).xyz;
	posWS = curve_world_offset(posWS, u_viewcamera_viewmat, u_viewcamera_inv_viewmat);
	gl_Position   = mul(u_viewProj, vec4(posWS, 1.0));
#else
	gl_Position = mul(u_modelViewProj, vec4(a_position, 1.0));
#endif //CURVE_WORLD
	
}
