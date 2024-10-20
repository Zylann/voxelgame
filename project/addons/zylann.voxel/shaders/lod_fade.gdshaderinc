
// These uniforms are assigned internally by the voxel engine.
group_uniforms voxel;
uniform vec2 u_lod_fade;
group_uniforms;

float get_hash(vec2 c) {
	return fract(sin(dot(c.xy, vec2(12.9898,78.233))) * 43758.5453);
}

bool get_lod_fade_discard(vec2 screen_uv) {
	// Terrible impl but can surely be optimized
	float h = get_hash(screen_uv);
	//ALBEDO = vec3(u_lod_fade.x, u_lod_fade.y, 0.0);
	vec2 lod_fade = u_lod_fade;
	//lod_fade = vec2(0.0);
	if (lod_fade.y > 0.5) {
		// Fade in
		return lod_fade.x < h;
	} else {
		// Fade out
		return lod_fade.x > h;
	}
}

