shader_type spatial;

uniform sampler2D u_albedo : filter_nearest_mipmap, repeat_enable;

varying flat vec2 v_flow_dir;
//varying flat float v_debug_flowstate;

void vertex() {
	vec2 src_uv = UV;
	//v_debug_flowstate = src_uv.y;

	vec2 uv = VERTEX.xz;
	if (round(src_uv.x) == 0.0) {
		uv = VERTEX.zy;
		uv.y *= -1.0;
	} else if(round(src_uv.x) == 2.0) {
		uv = VERTEX.xy;
		uv.y *= -1.0;
	}

	vec2 flow_dir = vec2(0.0);
	if (src_uv.y < 7.99) {
		float angle = src_uv.y * (TAU / 8.0);
		flow_dir = vec2(-cos(angle), sin(angle));
	}

	uv += TIME * flow_dir;

	if (src_uv.y < 7.99) {
		v_flow_dir = flow_dir;
	} else {
		v_flow_dir = vec2(1.0, 0.0);
	}
	UV = uv;
}

void fragment() {
	vec2 tx = v_flow_dir;
	vec2 ty = vec2(v_flow_dir.y, -v_flow_dir.x);
	vec2 uv = tx * UV.x + ty * UV.y;
	ALBEDO = texture(u_albedo, uv).rgb;
	ALPHA = 0.5;
	//ALBEDO = vec3(0.0, float(round(v_debug_flowstate) == 6.0), 0.0);
}

