shader_type spatial;
//render_mode skip_vertex_transform;

uniform sampler2D u_texture_top : source_color;
uniform sampler2D u_texture_sides : source_color;

// From Voxel Tools API
uniform int u_transition_mask;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

vec3 get_triplanar_blend(vec3 world_normal, float sharpness) {
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

float get_hash(vec2 c) {
	return fract(sin(dot(c.xy, vec2(12.9898,78.233))) * 43758.5453);
}

float get_transvoxel_secondary_factor(int idata) {
	int cell_border_mask = (idata >> 0) & 63; // Which sides the cell is touching
	int vertex_border_mask = (idata >> 8) & 63; // Which sides the vertex is touching
	//int vertex_border_mask = (idata >> 6) & 63; // Which sides the vertex is touching
	// If the vertex is near a side where there is a low-resolution neighbor,
	// move it to secondary position
	int m = u_transition_mask & cell_border_mask;
	float t = float(m != 0);
	// If the vertex lies on one or more sides, and at least one side has no low-resolution neighbor,
	// don't move the vertex.
	t *= float((vertex_border_mask & ~u_transition_mask) == 0);
	
	// Debugging
	//t *= 0.5 + 0.5 * sin(TIME * 4.0);

	//t *= 2.0;

	return t;
}

vec3 get_transvoxel_position(vec3 vertex_pos, vec4 fdata) {
	int idata = floatBitsToInt(fdata.a);
	//int idata = int(fdata.a);

	// Move vertices to smooth transitions
	float secondary_factor = get_transvoxel_secondary_factor(idata);
	vec3 secondary_position = fdata.xyz;
	vec3 pos = mix(vertex_pos, secondary_position, secondary_factor);
	//vec3 pos = vertex_pos;

	// If the mesh combines transitions and the vertex belongs to a transition,
	// when that transition isn't active we change the position of the vertices so
	// all triangles will be degenerate and won't be visible.
	// This is an alternative to rendering them separately,
	// which has less draw calls and less mesh resources to create in Godot.
	// Ideally I would tweak the index buffer like LOD does but Godot does not
	// expose anything to use it that way.
	int itransition = (idata >> 16) & 0xff; // Is the vertex on a transition mesh?
	float transition_cull = float(itransition == 0 || (itransition & u_transition_mask) != 0);
	pos *= transition_cull;

	//pos *= float(itransition == 0);

	return pos;
}

void vertex() {
	VERTEX = get_transvoxel_position(VERTEX, CUSTOM0);
	//VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	//VERTEX = floor(VERTEX * 100.0) * 0.01;

	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_pos = world_pos;
	v_world_normal = NORMAL;

	// COLOR = mix(vec4(1.0), vec4(1.0, 0.0, 0.0, 1.0), 
	// 	get_transvoxel_secondary_factor(floatBitsToInt(CUSTOM0.a)));
}

void fragment() {
	//vec3 normal = v_world_normal;
	vec3 normal = normalize(v_world_normal);
	vec3 wpos = v_world_pos * 0.2;

	float topness_midlevel = 0.5;
	float topness_smoothness = 0.04;
	float topness_min = topness_midlevel - topness_smoothness;
	float topness_max = topness_midlevel + topness_smoothness;
	float topness = smoothstep(topness_min, topness_max, normal.y);

	float triplanar_sharpness = 8.0;
	vec3 blending = get_triplanar_blend(normal, triplanar_sharpness);

	// TODO After quick tests I was unable to figure out which is fastest between those 3 versions.
	// But I'm sure there is a difference...
	// 1)
	// vec3 top_col = topness > 0.0 ? texture_triplanar(u_texture_top, wpos, blending).rgb : vec3(0.0);
	// vec3 side_col = topness < 1.0 ? texture_triplanar(u_texture_sides, wpos, blending).rgb : vec3(0.0);
	// 2)
	vec3 top_col = texture_triplanar(u_texture_top, wpos, blending).rgb;
	vec3 side_col = texture_triplanar(u_texture_sides, wpos, blending).rgb;
	// 3)
	// vec3 top_col = biplanar(u_texture_top, wpos, normal, 8.0).rgb;
	// vec3 side_col = biplanar(u_texture_sides, wpos, normal, 8.0).rgb;

	float r = top_col.r;
	ALBEDO = mix(side_col, top_col, topness);
	//ALBEDO = top_col;
	//ALBEDO *= COLOR.rgb;
}
