shader_type spatial;

#include "res://addons/zylann.voxel/shaders/transvoxel.gdshaderinc"
//#include "res://addons/zylann.voxel/shaders/virtual_texturing.gdshaderinc"
#include "res://addons/zylann.voxel/shaders/triplanar.gdshaderinc"
//#include "res://addons/zylann.voxel/shaders/lod_fade.gdshaderinc"
#include "res://addons/zylann.voxel/shaders/voxel_texturing.gdshaderinc"

uniform sampler2DArray u_albedo_array : source_color;

varying vec3 v_world_pos;
varying vec4 v_material_indices;
varying vec4 v_material_weights;


void vertex() {
	VERTEX = get_transvoxel_position(VERTEX, CUSTOM0);

	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Indices are integer values so we can decode them as-is
    v_material_indices = decode_8bit_vec4(CUSTOM1.x);

    // Weights must be in [0..1] so we divide them
    v_material_weights = decode_8bit_vec4(CUSTOM1.y) / 255.0;
}

void fragment() {
	vec3 normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;

    // Define a texture scale for convenience.
    // We can use an array instead if different scales per index is needed.
    float uv_scale = 1.0;

	vec3 wpos = v_world_pos * uv_scale;

    // Sample the 4 blending textures, all with triplanar mapping.
    // We can re-use the same triplanar blending factors for all of them so separating that part
    // of the function improves performance a little.
    vec3 blending = get_triplanar_blend(normal, 1.0);
    vec3 col0 = texture_array_triplanar(u_albedo_array, wpos, blending, v_material_indices.x).rgb;
    vec3 col1 = texture_array_triplanar(u_albedo_array, wpos, blending, v_material_indices.y).rgb;
    vec3 col2 = texture_array_triplanar(u_albedo_array, wpos, blending, v_material_indices.z).rgb;
    vec3 col3 = texture_array_triplanar(u_albedo_array, wpos, blending, v_material_indices.w).rgb;

    // Get weights and make sure they are normalized.
    // We may add a tiny safety margin so we can afford some degree of error.
    vec4 weights = v_material_weights;
    weights /= (weights.x + weights.y + weights.z + weights.w + 0.00001);

    // Calculate albedo
    vec3 col =
        col0 * weights.r +
        col1 * weights.g +
        col2 * weights.b +
        col3 * weights.a;

    ALBEDO = col;
//	ALBEDO = vec3(v_material_weights.rgb);
}
