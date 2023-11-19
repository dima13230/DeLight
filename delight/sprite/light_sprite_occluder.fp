#extension GL_ARB_bindless_texture : enable

#define PI 3.14

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

uniform vec4 edge_threshold;
uniform vec4 occluder_rim_factor;

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
		lowp float theta = atan(var_texcoord0.y, var_texcoord0.x);

		lowp vec4 color = vec4(lightColors[i].rgb, 1.0);

		// Continue if not inside angle
		if (theta > lightAngles[i].y || theta < lightAngles[i].w || (theta > 0.0 && theta < lightAngles[i].x) || (theta < 0.0 && theta > lightAngles[i].z)) 
		continue;

		if (lightEnabled[i].x == 0)
		continue;

		// Calculate the distance from the light
		lowp float distance = length(lightPositions[i].xyz - var_position.xyz);

		// Calculate the falloff curve
		lowp float falloffCurve = smoothstep(lightRadiuses[i].x / 3, 0.0, distance);

		// Sobel edge detection kernel
		float kernel[9] = float[](-1, -2, -1, -2, 12, -2, -1, -2, -1);

		// Calculate the depth of the current pixel
		float currentDepth = texture2D(texture_sampler, var_texcoord0).r;

		// Calculate the weighted sum of neighbors using the Sobel kernel
		float sum = 0.0;
		for (int i = 0; i < 3; ++i) {
			for (int j = 0; j < 3; ++j) {
				vec2 offset = vec2(float(i - 1), float(j - 1)) / textureSize(texture_sampler, 0);
				float neighborDepth = texture2D(texture_sampler, var_texcoord0 + offset).r;
				sum += kernel[i * 3 + j] * neighborDepth;
			}
		}

		// If the weighted sum is above a threshold, it's an edge pixel
		float isEdge = step(edge_threshold.x, abs(sum));
		
		// Apply the falloff curve to the light color
		color *= vec4(falloffCurve * isEdge);

		// Calculate the rim factor based on the dot product between normal and light direction
		lowp float rimFactor = smoothstep(0.0, 0.1, occluder_rim_factor.x - length(lightPositions[i].xy - var_position.xy) / lightRadiuses[i].x);
		
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

		color *= rimFactor;
		
		// Sample the shadow map
		lowp vec2 shadowMapCoord = (lightPositions[i].xy + var_position.xy) * 0.5;
		float shadow = texture2D(select_shadowmap(i), shadowMapCoord).r;

		// Apply the shadow to the light color
		//color *= vec4(shadow);

		finalColor += color;
	}

	// Combine diffuse and texture color
	lowp vec4 diffuseColor = texColor * vec4(finalColor + ambient_color);
	
	gl_FragColor = diffuseColor;
}