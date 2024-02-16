#define PI 3.14159

// User defined
uniform mediump vec4 falloff;
uniform lowp vec4 color;
uniform mediump vec4 angle;
uniform mediump vec4 size;
uniform lowp vec4 draw_point;
uniform lowp vec4 point_transparency;

uniform lowp sampler2D texture_sampler;

varying mediump vec2 var_texcoord0;

// Sample from the 1D distance map
float sample_from_distance_map(vec2 coord, float r) {
	return step(r, texture2D(texture_sampler, coord).r);
}

void main(void) {
	float theta = atan(var_texcoord0.y, var_texcoord0.x);

	// Discard if not inside angle
	if (theta > angle.y)
	{
		discard;
	}
	else if (theta < angle.w)
	{
		gl_FragColor = vec4(0, 1, 0, 1);
		return;
	}
	else if (theta - angle.z > 0 && theta < angle.x)
	{
		discard;
	}
	else if (theta - angle.z < 0 && theta > angle.z)
	{
		discard;
	}

	// Rectangular to polar
	// r = 0.0 on top of light
	// r = 1.0 as far away from the light as possible
	float r = length(var_texcoord0);

	// The tex coord to sample our 1D lookup texture
	float coord = (theta + PI) / (2.0 * PI);
	vec2 tc = vec2(coord, 0.0);
	
	float lightCurve = sample_from_distance_map(tc, r);
	float falloffCurve = smoothstep(1.0, 0.0, r * falloff.x);

	// Multiply the summed amount by our distance, which gives us a radial falloff
	// Then multiply by vertex (light) color  
	if (draw_point.x == 1)
		gl_FragColor = color * vec4(1, 1, 1, lightCurve * falloffCurve * point_transparency.x);
}