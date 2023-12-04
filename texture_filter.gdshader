shader_type canvas_item;

uniform sampler2D tex;
uniform int filter;

vec4 texture_nearest(sampler2D t, vec2 uv) {
	vec2 size = vec2(textureSize(t, 0));
	uv = round(uv * size) / size;
	return texture(t, uv);
}

vec4 texture_linear(sampler2D t, vec2 uv) {
	return texture(t, uv);
}

vec4 cubic(float v)
{
    vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) * (1.0/6.0);
}

vec4 texture_bicubic(sampler2D sampler, vec2 texCoords)
{
	int lod = 0;
	vec2 texSize = vec2(textureSize(sampler, lod));
	vec2 invTexSize = 1.0 / texSize;

	texCoords = texCoords * texSize - 0.5;


	vec2 fxy = fract(texCoords);
	texCoords -= fxy;

	vec4 xcubic = cubic(fxy.x);
	vec4 ycubic = cubic(fxy.y);

	vec4 c = texCoords.xxyy + vec2 (-0.5, +1.5).xyxy;

	vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
	vec4 offset = c + vec4 (xcubic.yw, ycubic.yw) / s;

	offset *= invTexSize.xxyy;

	vec4 sample0 = textureLod(sampler, offset.xz, float(lod));
	vec4 sample1 = textureLod(sampler, offset.yz, float(lod));
	vec4 sample2 = textureLod(sampler, offset.xw, float(lod));
	vec4 sample3 = textureLod(sampler, offset.yw, float(lod));

	float sx = s.x / (s.x + s.y);
	float sy = s.z / (s.z + s.w);

	return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

void fragment() {
	vec4 t;
	switch(filter) {
		case 0:
			t = texture_nearest(tex, UV);
			break;
		case 1:
			t = texture_linear(tex, UV);
			break;
		case 2:
			t = texture_bicubic(tex, UV);
			break;
	}
	COLOR = t;
}
