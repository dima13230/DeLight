#extension GL_ARB_bindless_texture : enable

#define PI 3.14

// Define the maximum number of lights
#define MAX_LIGHTS 9
#define SHADOW_THRESHOLD 0

uniform vec4 lightsAmount;
// Array of light positions
uniform vec4 lightPositions[MAX_LIGHTS];
// Array of light colors
uniform vec4 lightColors[MAX_LIGHTS];
// Array of light radiuses
uniform vec4 lightRadiuses[MAX_LIGHTS];
// Array of light angles
uniform vec4 lightAngles[MAX_LIGHTS];
uniform vec4 lightEnabled[MAX_LIGHTS];

uniform mediump mat4 shadowmapViewProjs[MAX_LIGHTS];

uniform vec4 unlit;

uniform vec4 normal_set;
uniform vec4 normal_height;
uniform vec4 shininess;

uniform vec4 ambient_color;
uniform lowp vec4 tint;

uniform lowp vec4 size;
uniform lowp vec4 scale;
uniform lowp vec4 offset;

varying highp vec4 var_position;
varying mediump vec2 var_texcoord0;
varying mediump vec2 var_shadowmap_texcoord[MAX_LIGHTS];

uniform lowp sampler2D texture_sampler;

uniform lowp sampler2D shadowmap_sampler_0;
uniform lowp sampler2D shadowmap_sampler_1;
uniform lowp sampler2D shadowmap_sampler_2;
uniform lowp sampler2D shadowmap_sampler_3;
uniform lowp sampler2D shadowmap_sampler_4;
uniform lowp sampler2D shadowmap_sampler_5;
uniform lowp sampler2D shadowmap_sampler_6;
uniform lowp sampler2D shadowmap_sampler_7;
uniform lowp sampler2D shadowmap_sampler_8;

sampler2D select_shadowmap(int index) {
	if (index == 0) {
		return shadowmap_sampler_0;
	}
	else if (index == 1) {
		return shadowmap_sampler_1;
	}
	else if (index == 2) {
		return shadowmap_sampler_2;
	}
	else if (index == 3) {
		return shadowmap_sampler_3;
	}
	else if (index == 4) {
		return shadowmap_sampler_4;
	}
	else if (index == 5) {
		return shadowmap_sampler_5;
	}
	else if (index == 6) {
		return shadowmap_sampler_6;
	}
	else if (index == 7) {
		return shadowmap_sampler_7;
	}
	else if (index == 8) {
		return shadowmap_sampler_8;
	}
	else {
		return shadowmap_sampler_0;
	}
}

// Sample from the 1D distance map
float sample_from_distance_map(int i, vec2 coord, float r) {
	return step(r, texture2D(select_shadowmap(i), coord).r);
}

void main() {
	lowp vec2 uv = vec2(var_texcoord0.x *scale.x +offset.x, var_texcoord0.y *scale.y +offset.y);
	uv = vec2(mod(uv.x, size.x), mod(uv.y, size.y));
	// Sample the texture
	lowp vec4 texColor = texture2D(texture_sampler, uv);

	if (unlit.x > 0)
	{
		lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
		gl_FragColor = texture2D(texture_sampler, var_texcoord0.xy) * tint_pm;
		return;
	}
	
	vec3 normal = vec3(0.0, 0.0, 1.0);
	normal = normalize( ( (texColor.xyz) - 0.5) * 2.0 ) * normal_height.x;

	lowp vec4 finalColor = vec4(0);
	for (int i = 0; i < MAX_LIGHTS; ++i) {
		// webgl doesn't allow for-loops with non constant end value
		// we use this as a workaround
		if (i > lightsAmount.x) break;
		
		lowp vec4 color = vec4(lightColors[i].rgb, 1.0);

		if (lightEnabled[i].x == 0)
		continue;

		// Calculate the distance from the light
		lowp float distance = length(lightPositions[i].xyz - var_position.xyz);

		// Calculate the falloff curve
		lowp float falloffCurve = smoothstep(lightRadiuses[i].x, 0.0, distance);

		// Apply the falloff curve to the light color
		color *= vec4(falloffCurve, falloffCurve, falloffCurve, 1);

		if (normal_set.x == 1) {
			// Calculate the light direction
			lowp vec3 lightDir = normalize(lightPositions[i].xyz - var_position.xyz);

			// Calculate the diffuse lighting
			lowp float diffuse = max(dot(normal, lightDir), 0.0);

			// Calculate the specular lighting
			lowp vec3 viewDir = normalize(-var_position.xyz);
			lowp vec3 reflectDir = reflect(-lightDir, normal);
			lowp float specular = pow(max(dot(viewDir, reflectDir), 0.0), shininess.x);

			// Apply the diffuse and specular lighting to the light color
			color *= vec4(diffuse + 0.5 * specular);
		}
		// SHADOW MAP SEGMENT
		float theta = atan(var_shadowmap_texcoord[i].y, var_shadowmap_texcoord[i].x);
		theta = mod(theta, 2.0 * PI);
		float r = length(var_shadowmap_texcoord[i]);
		
		// The tex coord to sample our 1D lookup texture
		float coord = (theta + PI) / (2.0 * PI);
		vec2 tc = vec2(coord, 0.0);

		float lightCurve = sample_from_distance_map(i, tc, r);

		// FOR TESTING {
		//color = vec4(var_shadowmap_texcoord[i], 0.0, 1);
		//color = vec4(r);
		//color = vec4(theta);
		// }
		//color *= lightCurve;
		
		finalColor += color;
	}

	// Combine diffuse and texture color
	lowp vec4 diffuseColor = texColor * vec4(finalColor + ambient_color);

	gl_FragColor = diffuseColor;
}