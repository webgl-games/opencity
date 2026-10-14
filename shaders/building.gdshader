shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Procedural building facade: window grid, some of them lit.
// Cheap enough to run on every building without a single texture file.

uniform vec3 wall_colour : source_color = vec3(0.45, 0.44, 0.42);
uniform vec3 roof_colour : source_color = vec3(0.20, 0.20, 0.22);
uniform vec3 window_colour : source_color = vec3(0.07, 0.09, 0.13);
uniform vec3 window_lit_colour : source_color = vec3(1.0, 0.86, 0.58);
uniform float building_height = 20.0;
uniform float floor_height = 3.4;
uniform float window_span = 2.6;
uniform float lit_ratio = 0.22;
uniform float seed = 0.0;

varying vec3 local_pos;
varying vec3 local_normal;

void vertex() {
	local_pos = VERTEX;
	local_normal = NORMAL;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.3) * 43758.5453);
}

void fragment() {
	bool is_wall = abs(local_normal.y) < 0.5;

	vec3 albedo = is_wall ? wall_colour : roof_colour;
	float rough = 0.85;
	float metal = 0.0;
	float lit = 0.0;

	if (is_wall) {
		// Horizontal axis depends on which wall we're on.
		float horiz = abs(local_normal.x) > 0.5 ? local_pos.z : local_pos.x;
		// Shift so the window rows start from the pavement, not the mid-point.
		float vert = local_pos.y + building_height * 0.5;

		vec2 cell = vec2(floor(horiz / window_span), floor(vert / floor_height));
		vec2 f = vec2(fract(horiz / window_span), fract(vert / floor_height));

		// Leave the ground floor as solid frontage.
		bool above_ground_floor = vert > floor_height;
		bool in_window = f.x > 0.16 && f.x < 0.84 && f.y > 0.22 && f.y < 0.78;

		if (in_window && above_ground_floor) {
			if (hash(cell) < lit_ratio) {
				albedo = window_lit_colour;
				lit = 1.0;
			} else {
				albedo = window_colour;
			}
			rough = 0.12;
			metal = 0.35;
		} else if (f.y < 0.06) {
			// Slim band between floors, breaks up flat walls.
			albedo *= 0.82;
		}
	}

	ALBEDO = albedo;
	ROUGHNESS = rough;
	METALLIC = metal;
	EMISSION = window_lit_colour * lit * 1.4;
}
