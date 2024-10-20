
//#define VOXEL_OCTAHEDRAL_NORMAL_ENCODING
//#define VOXEL_VIRTUAL_TEXTURE_USE_TEXTURE_ARRAY

// These uniforms are assigned internally by the voxel engine.
group_uniforms voxel;
// TODO Godot is not binding integer samplers properly.
// See https://github.com/godotengine/godot/issues/57841
// TODO Workaround using float texelFetch doesnt't work either...
// See https://github.com/godotengine/godot/issues/31732
//uniform usampler2D u_normalmap_lookup;
uniform sampler2D u_voxel_cell_lookup : filter_nearest;

#ifdef VOXEL_VIRTUAL_TEXTURE_USE_TEXTURE_ARRAY
uniform sampler2DArray u_voxel_normalmap_atlas;
#else
uniform sampler2D u_voxel_normalmap_atlas;
uniform int u_voxel_virtual_texture_tile_size;
#endif

uniform float u_voxel_virtual_texture_fade;
uniform float u_voxel_cell_size;
uniform int u_voxel_block_size;
// This is used when falling back on a virtual texture from a parent mesh.
// The texture will cover a larger cube, so we use this information
// to query only inside a sub-region.
// (x, y, z) is offset, (w) is scale.
uniform vec4 u_voxel_virtual_texture_offset_scale;
group_uniforms;

vec2 pad_uv(vec2 uv, float amount) {
	return uv * (1.0 - 2.0 * amount) + vec2(amount);
}

#ifdef VOXEL_OCTAHEDRAL_NORMAL_ENCODING

// https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
vec3 octahedron_decode(vec2 f) {
	f = f * 2.0 - 1.0;
	// https://twitter.com/Stubbesaurus/status/937994790553227264
	vec3 n = vec3(f.x, f.y, 1.0 - abs(f.x) - abs(f.y));
	float t = clamp(-n.z, 0.0, 1.0);
	// GLSL didn't accept the vector version of this. Any impact?
	n.x += n.x >= 0.0 ? -t : t;
	n.y += n.y >= 0.0 ? -t : t;
	return /*f == vec2(0.0) ? vec3(0.0) : */normalize(n);
}

#endif

vec3 get_voxel_normal_model(vec3 vertex_pos_model, out vec3 debug) {
	float cell_size = u_voxel_cell_size;
	int block_size = u_voxel_block_size; // May rename this `block_resolution`?

#ifdef VOXEL_VIRTUAL_TEXTURE_USE_TEXTURE_ARRAY
	int normalmap_tile_size = textureSize(u_voxel_normalmap_atlas, 0).x;
#else
	int normalmap_tile_size = u_voxel_virtual_texture_tile_size;
#endif
	
	vec3 cell_posf = vertex_pos_model / cell_size;
	cell_posf = cell_posf * u_voxel_virtual_texture_offset_scale.w + u_voxel_virtual_texture_offset_scale.xyz;
	ivec3 cell_pos = ivec3(floor(cell_posf));
	vec3 cell_fract = fract(cell_posf);
	
	int cell_index = cell_pos.x + cell_pos.y * block_size + cell_pos.z * block_size * block_size;
	int lookup_sqri = textureSize(u_voxel_cell_lookup, 0).x;//int(ceil(sqrt(float(block_size * block_size * block_size))));
	ivec2 lookup_pos = ivec2(cell_index % lookup_sqri, cell_index / lookup_sqri);
	//uvec3 lookup_value = texelFetch(u_voxel_cell_lookup, lookup_pos, 0).rgb;
	//vec3 lookup_valuef = texelFetch(u_voxel_cell_lookup, lookup_pos, 0).rgb;
	vec2 lookup_valuef = texture(u_voxel_cell_lookup, (vec2(lookup_pos) + vec2(0.5)) / float(lookup_sqri)).rg;
	ivec2 lookup_value = ivec2(round(lookup_valuef * 255.0));
	int tile_index = lookup_value.r | ((lookup_value.g & 0x3f) << 8);
	int tile_direction = lookup_value.g >> 6;
	
	vec2 tile_texcoord = vec2(0.0);
	// TODO Could do it non-branching with weighted addition
	switch(tile_direction) {
		case 0:
			tile_texcoord = cell_fract.zy;
			break;
		case 1:
			tile_texcoord = cell_fract.xz;
			break;
		case 2:
			tile_texcoord = cell_fract.xy;
			break;
	}
	//float debug_cmp = 0.5+0.5*clamp(3.0*sin(TIME * 2.0), -1.0, 1.0);
	// Half a pixel
	float padding = 0.5 / float(normalmap_tile_size);
	tile_texcoord = pad_uv(tile_texcoord, padding);

#ifdef VOXEL_VIRTUAL_TEXTURE_USE_TEXTURE_ARRAY
	vec3 encoded_normal = texture(u_voxel_normalmap_atlas, vec3(tile_texcoord, float(tile_index))).rgb;
#else
	// The maximum number of layers in texture arrays can be reached quickly with block size 32,
	// so we use a 2D texture instead
	ivec2 atlas_size = textureSize(u_voxel_normalmap_atlas, 0);
	int tiles_per_row = atlas_size.x / normalmap_tile_size;
	ivec2 tile_pos_pixels = ivec2(tile_index % tiles_per_row, tile_index / tiles_per_row) * normalmap_tile_size;
	vec2 atlas_texcoord = (vec2(tile_pos_pixels) + float(normalmap_tile_size) * tile_texcoord) / vec2(atlas_size);
	vec3 encoded_normal = texture(u_voxel_normalmap_atlas, atlas_texcoord).rgb;
#endif

#ifdef VOXEL_OCTAHEDRAL_NORMAL_ENCODING
	// 2) Octahedral
	vec3 tile_normal_model = octahedron_decode(encoded_normal.rg);
#else
	// 1) XYZ
	vec3 tile_normal_model = 2.0 * encoded_normal - vec3(1.0);
#endif

	//debug = vec3(float(cell_size == 4.0), float(cell_size == 8.0), float(cell_size == 16.0));
	debug = encoded_normal;
	//debug = 0.5 + 0.5 * tile_normal_model;

	return tile_normal_model;
}

vec3 get_voxel_normal_view(vec3 vertex_pos_model, vec3 geometry_normal_view, mat4 model_to_view) {
	if (u_voxel_cell_size == 0.0) {
		// Virtual texture not available in this mesh
		return geometry_normal_view;
	}
	vec3 debug;
	vec3 tile_normal_model = get_voxel_normal_model(vertex_pos_model, debug);
	vec3 tile_normal_view = (model_to_view * vec4(tile_normal_model, 0.0)).xyz;
	// In some edge cases the normal can be invalid (length close to zero), causing black artifacts.
	// Workaround this by falling back on the geometry normal.
	// Also apply fading.
	vec3 normal = mix(geometry_normal_view, tile_normal_view, 
		u_voxel_virtual_texture_fade * dot(tile_normal_view, tile_normal_view));
	return normal;
}

vec3 get_voxel_normal_view_model(vec3 vertex_pos_model, 
		vec3 geometry_normal_view, mat4 model_to_view, 
		vec3 geometry_normal_model, out vec3 out_normal_model) {
	if (u_voxel_cell_size == 0.0) {
		// Virtual texture not available in this mesh
		out_normal_model = geometry_normal_model;
		return geometry_normal_view;
	}
	vec3 debug;
	vec3 tile_normal_model = get_voxel_normal_model(vertex_pos_model, debug);
	vec3 tile_normal_view = (model_to_view * vec4(tile_normal_model, 0.0)).xyz;
	// In some edge cases the normal can be invalid (length close to zero), causing black artifacts.
	// Workaround this by falling back on the geometry normal.
	// Also apply fading.
	vec3 normal = mix(geometry_normal_view, tile_normal_view, 
		u_voxel_virtual_texture_fade * dot(tile_normal_view, tile_normal_view));

	// TODO Normalize this one?
	// The view-space normal is normalized by Godot after assigning to `NORMAL`,
	// but the model normal is useful for other things such as texturing,
	// and due to interpolation it may need normalization.
	out_normal_model = mix(geometry_normal_model, tile_normal_model, 
		u_voxel_virtual_texture_fade * dot(tile_normal_model, tile_normal_model));

	return normal;
}
