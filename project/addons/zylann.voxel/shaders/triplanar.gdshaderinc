
vec3 get_triplanar_blend(vec3 world_normal, float sharpness) {
	// TODO `pow` is an expensive function, maybe there should be an alternative
	vec3 blending = pow(abs(world_normal), vec3(sharpness));
	return blending / (blending.x + blending.y + blending.z);
}

vec4 texture_triplanar(sampler2D tex, vec3 world_pos, vec3 blend) {
	vec4 xaxis = texture(tex, world_pos.yz);
	vec4 yaxis = texture(tex, world_pos.xz);
	vec4 zaxis = texture(tex, world_pos.xy);
	// blend the results of the 3 planar projections.
	return xaxis * blend.x + yaxis * blend.y + zaxis * blend.z;
}

vec4 texture_array_triplanar(sampler2DArray tex, vec3 world_pos, vec3 blend, float i) {
    vec4 xaxis = texture(tex, vec3(world_pos.yz, i));
    vec4 yaxis = texture(tex, vec3(world_pos.xz, i));
    vec4 zaxis = texture(tex, vec3(world_pos.xy, i));
    // blend the results of the 3 planar projections.
    return xaxis * blend.x + yaxis * blend.y + zaxis * blend.z;
}

// TODO Tangents helper
