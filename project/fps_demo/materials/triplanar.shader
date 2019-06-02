/******************************************************
This shader blends two separate top and side textures, each with their own triplanar mapped albedo, normal and ambient occlusion.

Texture A is the top surface.
Texture B are the sides and bottom.

The typical use case would be to have grass on top and a rocky surface on the sides and bottom of a terrain.

This version of the shader shows an obvious repeating pattern when wide, flat areas are textured. This is inevitable when stamping
the same texture over and over. Version 2 of this shader fixes this issue at the cost of additional texture lookups.

Last modified: 2019-08-15

******************************************************/

shader_type spatial;
render_mode diffuse_burley;

uniform bool		A_albedo_enabled = true;
uniform vec4 		A_albedo_tint : hint_color = vec4(1., 1., 1., 1.);
uniform sampler2D 	A_albedo_map : hint_albedo;
uniform bool		A_normal_enabled = true;
uniform sampler2D 	A_normal_map : hint_normal;
uniform float 		A_normal_strength : hint_range(-16., 16.0) = 1.;
uniform bool		A_ao_enabled = true;
uniform float 		A_ao_strength : hint_range(-1., 1.0) = 1.; 
uniform vec4 		A_ao_texture_channel = vec4(1., 0., 0., 0.);		// Use only one channel: Red, Green, Blue, Alpha
uniform sampler2D 	A_ao_map : hint_white;
uniform float 		A_tri_blend_sharpness : hint_range(0.001, 50.0) = 50.;
uniform int 		A_uv_tiles : hint_range(1, 16) = 1;
uniform vec3 		A_uv_offset;

uniform bool		B_albedo_enabled = true;
uniform vec4 		B_albedo_tint : hint_color = vec4(1., 1., 1., 1.);
uniform sampler2D 	B_albedo_map : hint_albedo;
uniform bool		B_normal_enabled = true;
uniform sampler2D 	B_normal_map : hint_normal;
uniform float 		B_normal_strength : hint_range(-16., 16.0) = 1.;
uniform bool		B_ao_enabled = true;
uniform float 		B_ao_strength : hint_range(-1., 1.0) = 1.; 
uniform vec4 		B_ao_texture_channel = vec4(1., 0., 0., 0.);		// Use only one channel: Red, Green, Blue, Alpha
uniform sampler2D 	B_ao_map : hint_white;
uniform float 		B_tri_blend_sharpness : hint_range(0.001, 50.0) = 50.;
uniform int 		B_uv_tiles : hint_range(1, 16) = 1;
uniform vec3 		B_uv_offset;

uniform float 		AB_mix1 : hint_range(-10., 0.) = -6.;
uniform float 		AB_mix2 : hint_range(-50., 50.) = -10.;

varying vec3 		A_uv_triplanar_pos;
varying vec3 		A_uv_power_normal;
varying vec3 		B_uv_triplanar_pos;
varying vec3 		B_uv_power_normal;
varying vec3 		v_world_normal;


void vertex() {
    TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
    TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
    TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
    TANGENT = normalize(TANGENT);
    BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
    BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
    BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
    BINORMAL = normalize(BINORMAL);

    A_uv_power_normal=pow(abs(NORMAL),vec3(A_tri_blend_sharpness));
    A_uv_power_normal/=dot(A_uv_power_normal,vec3(1.0));
    A_uv_triplanar_pos = VERTEX * float(A_uv_tiles) / (16.) + A_uv_offset;			//On VoxelTerrain 16 is 100% size, so uv_tile is multiples of 16. 
	A_uv_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
    B_uv_power_normal=pow(abs(NORMAL),vec3(B_tri_blend_sharpness));
    B_uv_power_normal/=dot(B_uv_power_normal,vec3(1.0));
    B_uv_triplanar_pos = VERTEX * float(B_uv_tiles) / (16.)  + B_uv_offset;
	B_uv_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
	v_world_normal = NORMAL;	
}


vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
        vec4 samp=vec4(0.0);
        samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
        samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
        samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
        return samp;
}


void fragment() {

	// Get normal used for mixing top A and sides B
	vec3 normal = normalize(v_world_normal);

	// Calculate Albedo 
	
	vec3 A_albedo, B_albedo;
	if(A_albedo_enabled) {
		ALBEDO = A_albedo = A_albedo_tint.rgb * triplanar_texture(A_albedo_map,A_uv_power_normal,A_uv_triplanar_pos).rgb;
	}
	if(B_albedo_enabled) {
		ALBEDO = B_albedo = B_albedo_tint.rgb * triplanar_texture(B_albedo_map,B_uv_power_normal,B_uv_triplanar_pos).rgb;
	}
	if(A_albedo_enabled==true && B_albedo_enabled==true) {
		ALBEDO = mix(B_albedo, A_albedo, clamp(AB_mix1 + 10.*normal.y + AB_mix2*A_albedo.b , 0., 1.));
	}


	// Calculate Ambient Occlusion
	
	float A_ao=1., B_ao=1.;
	if(A_ao_enabled) 
		AO = A_ao = dot(triplanar_texture(A_ao_map,A_uv_power_normal,A_uv_triplanar_pos),A_ao_texture_channel);
	if(B_ao_enabled)
		AO = B_ao = dot(triplanar_texture(B_ao_map,B_uv_power_normal,B_uv_triplanar_pos),B_ao_texture_channel);
	if(A_ao_enabled || B_ao_enabled) {
		AO = mix(B_ao, A_ao, clamp(AB_mix1 + 10.*normal.y + AB_mix2*A_albedo.b , 0., 1.));
		AO_LIGHT_AFFECT = mix(B_ao_strength, A_ao_strength, clamp(AB_mix1 + 10.*normal.y + AB_mix2*A_albedo.b , 0., 1.));
	}

	
	// Calculate Normals
	
	vec3 A_normal=vec3(0.5,0.5, 0.5);
	vec3 B_normal=vec3(0.5,0.5,0.5);	
	if(A_normal_enabled)
		A_normal = triplanar_texture(A_normal_map,A_uv_power_normal,A_uv_triplanar_pos).rgb;
	if(B_normal_enabled)
		B_normal = triplanar_texture(B_normal_map,B_uv_power_normal,B_uv_triplanar_pos).rgb;
	if(A_normal_enabled || B_normal_enabled) {
		NORMALMAP = mix(B_normal, A_normal, clamp(AB_mix1 + 10.*normal.y + AB_mix2*A_albedo.b , 0., 1.));
		NORMALMAP_DEPTH = mix(B_normal_strength, A_normal_strength, clamp(AB_mix1 + 10.*normal.y + AB_mix2*A_albedo.b , 0., 1.));
	}
}

