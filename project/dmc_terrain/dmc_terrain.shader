shader_type spatial;

uniform sampler2D u_texture_top : hint_albedo;
uniform sampler2D u_texture_sides : hint_albedo;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

vec3 get_triplanar_blend(vec3 world_normal) {
	vec3 blending = abs(world_normal);
	blending = normalize(max(blending, vec3(0.00001))); // Force weights to sum to 1.0
	float b = blending.x + blending.y + blending.z;
	return blending / vec3(b, b, b);
}

vec4 texture_triplanar(sampler2D tex, vec3 world_pos, vec3 blend) {
	vec4 xaxis = texture(tex, world_pos.yz);
	vec4 yaxis = texture(tex, world_pos.xz);
	vec4 zaxis = texture(tex, world_pos.xy);
	// blend the results of the 3 planar projections.
	return xaxis * blend.x + yaxis * blend.y + zaxis * blend.z;
}

void vertex() {
	v_world_pos = VERTEX;
	v_world_normal = NORMAL;
}

void fragment() {
	vec3 normal = v_world_normal;
	vec3 wpos = v_world_pos * 0.2;
	vec3 blending = get_triplanar_blend(normal);
	vec3 top_col = texture_triplanar(u_texture_top, wpos, blending).rgb;
	vec3 side_col = texture_triplanar(u_texture_sides, wpos, blending).rgb;
	float r = top_col.r;
	ALBEDO = mix(side_col, top_col, clamp(normal.y * 10.0 - 4.0 - 8.0*r, 0.0, 1.0));
}
