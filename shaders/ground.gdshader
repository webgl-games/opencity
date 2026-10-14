shader_type spatial;
render_mode cull_back, diffuse_burley;

// Asphalt with lane markings painted procedurally on the road grid,
// so no texture file and no extra geometry for the road lines.

uniform vec3 asphalt_colour : source_color = vec3(0.20, 0.20, 0.22);
uniform vec3 paint_colour : source_color = vec3(0.78, 0.78, 0.72);
uniform float block_size = 46.0;
uniform float world_extent = 322.0;
uniform float line_width = 0.16;
uniform float dash_length = 4.0;
uniform float dash_gap = 4.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Distance to the nearest road centreline along one axis.
float centreline_distance(float v) {
	float f = mod(v + world_extent * 0.5, block_size);
	return min(f, block_size - f);
}

// 1.0 on a dash, 0.0 in the gap.
float dash(float along) {
	float period = dash_length + dash_gap;
	return step(mod(along, period), dash_length);
}

void fragment() {
	float dx = centreline_distance(world_pos.x);
	float dz = centreline_distance(world_pos.z);

	float paint = 0.0;

	// North-south road: line runs along Z, dashes measured along Z.
	if (dx < line_width) {
		paint = max(paint, dash(world_pos.z));
	}
	// East-west road.
	if (dz < line_width) {
		paint = max(paint, dash(world_pos.x));
	}

	// Don't paint through the middle of intersections.
	if (dx < 6.0 && dz < 6.0) {
		paint = 0.0;
	}

	ALBEDO = mix(asphalt_colour, paint_colour, paint);
	ROUGHNESS = mix(0.95, 0.55, paint);
}
