shader_type canvas_item;

uniform vec3 color_a : source_color;
uniform vec3 color_b : source_color;
uniform float tile_size;

float checkerboard(vec2 p, float size) {
	return mod(dot(floor(p * size), vec2(1)), 2.0) * 0.5;
}

void fragment() {
	COLOR.a = 1.0;
	vec2 scaled_uv = UV;
	COLOR.rgb = mix(color_a, color_b, checkerboard(scaled_uv, tile_size));
}
