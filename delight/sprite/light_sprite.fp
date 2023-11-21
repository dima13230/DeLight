#extension GL_ARB_bindless_texture : enable

#define PI 3.14

#define SHADOW_THRESHOLD 0.1

// Define the maximum number of lights
#define MAX_LIGHTS 9

// Array of light positions
uniform vec4 lightPositions[MAX_LIGHTS];

// Array of light colors
uniform vec4 lightColors[MAX_LIGHTS];

// Array of light radiuses
uniform vec4 lightRadiuses[MAX_LIGHTS];

// Array of light angles
uniform vec4 lightAngles[MAX_LIGHTS];

uniform vec4 lightEnabled[MAX_LIGHTS];

uniform vec4 normal_set;
uniform vec4 normal_height;
uniform vec4 shininess;

uniform vec4 ambient_color;
uniform lowp vec4 tint;
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

varying highp vec4 var_position;
varying mediump vec2 var_texcoord0;
varying mediump mat4 var_view_proj;

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

mat4 inverse(mat4 m) {
	mat4 inv;
	float det;

	inv[0][0] = m[1][1] * m[2][2] * m[3][3] - m[1][1] * m[2][3] * m[3][2] - m[1][2] * m[2][1] * m[3][3] + m[1][2] * m[2][3] * m[3][1] + m[1][3] * m[2][1] * m[3][2] - m[1][3] * m[2][2] * m[3][1];
	inv[0][1] = -m[0][1] * m[2][2] * m[3][3] + m[0][1] * m[2][3] * m[3][2] + m[0][2] * m[2][1] * m[3][3] - m[0][2] * m[2][3] * m[3][1] - m[0][3] * m[2][1] * m[3][2] + m[0][3] * m[2][2] * m[3][1];
	inv[0][2] = m[0][1] * m[1][2] * m[3][3] - m[0][1] * m[1][3] * m[3][2] - m[0][2] * m[1][1] * m[3][3] + m[0][2] * m[1][3] * m[3][1] + m[0][3] * m[1][1] * m[3][2] - m[0][3] * m[1][2] * m[3][1];
	inv[0][3] = -m[0][1] * m[1][2] * m[2][3] + m[0][1] * m[1][3] * m[2][2] + m[0][2] * m[1][1] * m[2][3] - m[0][2] * m[1][3] * m[2][1] - m[0][3] * m[1][1] * m[2][2] + m[0][3] * m[1][2] * m[2][1];

	inv[1][0] = -m[1][0] * m[2][2] * m[3][3] + m[1][0] * m[2][3] * m[3][2] + m[1][2] * m[2][0] * m[3][3] - m[1][2] * m[2][3] * m[3][0] - m[1][3] * m[2][0] * m[3][2] + m[1][3] * m[2][2] * m[3][0];
	inv[1][1] = m[0][0] * m[2][2] * m[3][3] - m[0][0] * m[2][3] * m[3][2] - m[0][2] * m[2][0] * m[3][3] + m[0][2] * m[2][3] * m[3][0] + m[0][3] * m[2][0] * m[3][2] - m[0][3] * m[2][2] * m[3][0];
	inv[1][2] = -m[0][0] * m[1][2] * m[3][3] + m[0][0] * m[1][3] * m[3][2] + m[0][2] * m[1][0] * m[3][3] - m[0][2] * m[1][3] * m[3][0] - m[0][3] * m[1][0] * m[3][2] + m[0][3] * m[1][2] * m[3][0];
	inv[1][3] = m[0][0] * m[1][2] * m[2][3] - m[0][0] * m[1][3] * m[2][2] - m[0][2] * m[1][0] * m[2][3] + m[0][2] * m[1][3] * m[2][0] + m[0][3] * m[1][0] * m[2][2] - m[0][3] * m[1][2] * m[2][0];

	inv[2][0] = m[1][0] * m[2][1] * m[3][3] - m[1][0] * m[2][3] * m[3][1] - m[1][1] * m[2][0] * m[3][3] + m[1][1] * m[2][3] * m[3][0] + m[1][3] * m[2][0] * m[3][1] - m[1][3] * m[2][1] * m[3][0];
	inv[2][1] = -m[0][0] * m[2][1] * m[3][3] + m[0][0] * m[2][3] * m[3][1] + m[0][1] * m[2][0] * m[3][3] - m[0][1] * m[2][3] * m[3][0] - m[0][3] * m[2][0] * m[3][1] + m[0][3] * m[2][1] * m[3][0];
	inv[2][2] = m[0][0] * m[1][1] * m[3][3] - m[0][0] * m[1][3] * m[3][1] - m[0][1] * m[1][0] * m[3][3] + m[0][1] * m[1][3] * m[3][0] + m[0][3] * m[1][0] * m[3][1] - m[0][3] * m[1][1] * m[3][0];
	inv[2][3] = -m[0][0] * m[1][1] * m[2][3] + m[0][0] * m[1][3] * m[2][1] + m[0][1] * m[1][0] * m[2][3] - m[0][1] * m[1][3] * m[2][0] - m[0][3] * m[1][0] * m[2][1] + m[0][3] * m[1][1] * m[2][0];

	inv[3][0] = -m[1][0] * m[2][1] * m[3][2] + m[1][0] * m[2][2] * m[3][1] + m[1][1] * m[2][0] * m[3][2] - m[1][1] * m[2][2] * m[3][0] - m[1][2] * m[2][0] * m[3][1] + m[1][2] * m[2][1] * m[3][0];
	inv[3][1] = m[0][0] * m[2][1] * m[3][2] - m[0][0] * m[2][2] * m[3][1] - m[0][1] * m[2][0] * m[3][2] + m[0][1] * m[2][2] * m[3][0] + m[0][2] * m[2][0] * m[3][1] - m[0][2] * m[2][1] * m[3][0];
	inv[3][2] = -m[0][0] * m[1][1] * m[3][2] + m[0][0] * m[1][2] * m[3][1] + m[0][1] * m[1][0] * m[3][2] - m[0][1] * m[1][2] * m[3][0] - m[0][2] * m[1][0] * m[3][1] + m[0][2] * m[1][1] * m[3][0];
	inv[3][3] = m[0][0] * m[1][1] * m[2][2] - m[0][0] * m[1][2] * m[2][1] - m[0][1] * m[1][0] * m[2][2] + m[0][1] * m[1][2] * m[2][0] + m[0][2] * m[1][0] * m[2][1] - m[0][2] * m[1][1] * m[2][0];

	det = m[0][0] * inv[0][0] + m[0][1] * inv[1][0] + m[0][2] * inv[2][0] + m[0][3] * inv[3][0];

	// Calculate determinant and divide by it
	det = 1.0 / det;

	// Multiply each element by the inverse of the determinant
	for (int i = 0; i < 4; i++) {
		for (int j = 0; j < 4; j++) {
			inv[i][j] *= det;
		}
	}

	return inv;
}


void main() {
	// Sample the texture
	lowp vec4 texColor = texture2D(texture_sampler, var_texcoord0);

	vec3 normal = vec3(0.0, 0.0, 1.0);
	normal = normalize( ( (texColor.xyz) - 0.5) * 2.0 ) * normal_height.x;

	// Accumulate lighting contributions
	lowp int arlen = 0;
	for (; arlen < MAX_LIGHTS; ++arlen) {
		// Break if no more lights
		if (lightPositions[arlen] == vec4(0.0) && lightColors[arlen] == vec4(0.0) && lightRadiuses[arlen] == vec4(0.0)) {
			break;
		}
	}

	lowp vec4 finalColor = vec4(0);
	for (int i = 0; i < arlen; ++i) {
		lowp vec4 color = vec4(lightColors[i].rgb, 1.0);

		if (lightEnabled[i].x == 0)
		continue;

		// Calculate the distance from the light
		lowp float distance = length(lightPositions[i].xyz - var_position.xyz);

		// Calculate the falloff curve
		lowp float falloffCurve = smoothstep(lightRadiuses[i].x, 0.0, distance);

		// Apply the falloff curve to the light color
		color *= vec4(falloffCurve);

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
		// Adjust for viewport
		//vec2 shadowmap_uv = (var_position.xy - shadowmapViewports[i].xy) / shadowmapViewports[i].zw;

		// Sample from the shadow map
		//float shadow_intensity = texture2D(select_shadowmap(i), shadowmap_uv).r;

		mat4 inverseSpriteProjection = inverse(var_view_proj);
		// Transform sprite position to the light's view space
		vec4 lightSpacePosition = inverseSpriteProjection * var_position;

		// Use only the x and y components for shadow mapping
		vec2 shadowTexCoords = lightSpacePosition.xy / lightSpacePosition.w;

		// Calculate the direction from the light to the sprite
		vec3 lightToSpriteDir = normalize(lightPositions[i].xyz - var_position.xyz);

		// Calculate the angle between the light direction and the sprite normal
		lowp float theta = atan(lightToSpriteDir.y, lightToSpriteDir.x);

		// Calculate shadow map coordinates
		lowp float shadowCoord = theta / (2.0 * PI);

		// Sample from the specified shadow map
		float shadow_intensity = texture2D(select_shadowmap(i), vec2(shadowCoord, 0.5)).r;
		
		if (shadow_intensity > SHADOW_THRESHOLD)
		{
			color = vec4(shadow_intensity);
		}
		
		finalColor += color;
	}

	// Combine diffuse and texture color
	lowp vec4 diffuseColor = texColor * vec4(finalColor + ambient_color);

	gl_FragColor = diffuseColor;
}