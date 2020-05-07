shader_type spatial;
//render_mode skip_vertex_transform;

uniform sampler2D u_texture_top : hint_albedo;
uniform sampler2D u_texture_sides : hint_albedo;
uniform int u_transition_mask;

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

float get_hash(vec2 c) {
	return fract(sin(dot(c.xy, vec2(12.9898,78.233))) * 43758.5453);
}

vec3 get_transvoxel_position(vec3 vertex_pos, vec4 vertex_col) {

	int border_mask = int(vertex_col.a);
	int cell_border_mask = border_mask & 63; // Which sides the cell is touching
	int vertex_border_mask = (border_mask >> 6) & 63; // Which sides the vertex is touching

	// If the vertex is near a side where there is a low-resolution neighbor,
	// move it to secondary position
	int m = u_transition_mask & (cell_border_mask & 63);
	float t = float(m != 0);

	// If the vertex lies on one or more sides, and at least one side has no low-resolution neighbor,
	// don't move the vertex.
	t *= float((vertex_border_mask & ~u_transition_mask) == 0);

	// Position to use when border mask matches
	vec3 secondary_position = vertex_col.rgb;
	return mix(vertex_pos, secondary_position, t);
}

void vertex() {
	//VERTEX = get_transvoxel_position(VERTEX, COLOR);
	
	//VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	//VERTEX = floor(VERTEX * 100.0) * 0.01;

	vec3 world_pos = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_pos = world_pos;
	v_world_normal = NORMAL;

	// int border_mask = int(COLOR.a);
	// int cell_border_mask = border_mask & 63; // Which sides the cell is touching
	// int vertex_border_mask = (border_mask >> 6) & 63; // Which sides the vertex is touching
	// COLOR = vec4(float(cell_border_mask != 0), float(vertex_border_mask != 0), 0.0, 1.0);
}

void fragment() {

	vec3 normal = v_world_normal;//normalize(v_world_normal);
	vec3 wpos = v_world_pos * 0.2;
	vec3 blending = get_triplanar_blend(normal);
	vec3 top_col = texture_triplanar(u_texture_top, wpos, blending).rgb;
	vec3 side_col = texture_triplanar(u_texture_sides, wpos, blending).rgb;
	float r = top_col.r;
	ALBEDO = mix(side_col, top_col, clamp(normal.y * 10.0 - 4.0 - 8.0*r, 0.0, 1.0));

	//ALBEDO = COLOR.rgb * 0.2;
}
