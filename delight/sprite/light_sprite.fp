#extension GL_ARB_bindless_texture : enable

#define PI 3.14

// Define the maximum number of lights
#define MAX_LIGHTS 64
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
// Array with values of lights being on/off
uniform vec4 lightEnabled[MAX_LIGHTS];
// Array of light rotations
uniform vec4 lightRotations[MAX_LIGHTS];

uniform vec4 unlit;

uniform vec4 window_resolution;
uniform vec4 relative_resolution;

uniform vec4 normal_set;
uniform vec4 normal_height;
uniform vec4 shininess;

uniform vec4 ambient_color;
uniform lowp vec4 tint;

varying highp vec4 var_position;
varying mediump vec2 var_texcoord0;
varying mediump vec2 var_texcoord1;

uniform lowp sampler2D texture_sampler;
uniform lowp sampler2D normal_map;

void main() {
	// Sample the texture
	vec4 texColor = texture2D(texture_sampler, var_texcoord0);
	vec3 normalColor = texture2D(normal_map, var_texcoord1).rgb;

	if (unlit.x > 0)
	{
		lowp vec4 tint_pm = vec4(tint.xyz * tint.w, tint.w);
		gl_FragColor = texture2D(texture_sampler, var_texcoord0.xy) * tint_pm;
		return;
	}

	lowp vec4 finalColor = vec4(0);
	for (int i = 0; i < MAX_LIGHTS; ++i) {
		// webgl doesn't allow for-loops with non constant end value
		// we use this as a workaround
		if (i > lightsAmount.x) break;
		
		lowp vec4 color = vec4(lightColors[i].rgb, 1.0);

		if (lightEnabled[i].x == 0)
			continue;

		// Calculate the light direction
		vec2 lightPosition = relative_resolution.xy * lightPositions[i].xy / window_resolution.xy;
		//lowp vec3 light_dir = vec3(lightPosition - (gl_FragCoord.xy / window_resolution.xy), lightPositions[i].z);
		lowp vec3 light_dir = vec3(lightPositions[i].xy - var_position.xy, lightPositions[i].z); // first variant is more accurate but not fixed yet

		vec4 angle = lightAngles[i];

		float theta = atan(-light_dir.y, -light_dir.x);
		if (theta > angle.y || theta < angle.w || (theta > 0.0 && theta < angle.x) || (theta < 0.0 && theta > angle.z)) 
			continue;

		// Calculate the distance from the light
		lowp float distance = length(lightPositions[i].xyz - var_position.xyz);

		// Calculate the falloff curve
		lowp float falloffCurve = smoothstep(lightRadiuses[i].x, 0.0, distance);
		
		if (normal_set.x == 1) {
			
			//light_dir.x *= window_resolution.x / window_resolution.y;
			
			vec3 N = normalize(normalColor * 2.0 - 1.0);
			float D = length(light_dir);
			vec3 L = normalize(light_dir);
			
			// Calculate the diffuse lighting
			lowp vec3 diffuse = (lightColors[i].rgb * lightColors[i].a) * max(dot(N, L), 0.0);

			// Calculate the specular lighting
			vec3 V = normalize(-light_dir); // View direction
			vec3 R = reflect(-L, N); // Reflected light direction
			float specularIntensity = pow(max(dot(R, V), 0.0), shininess.x);
			vec3 specular = lightColors[i].rgb * specularIntensity;
			if (shininess.x == 0)
				specular = vec3(0);
			
			// Apply the diffuse and specular lighting to the light color
			color = vec4(diffuse * falloffCurve + specular * falloffCurve, 1); //  + specular * falloffCurve
		}
		else
		{
			// Apply the falloff curve to the light color
			color *= vec4(falloffCurve, falloffCurve, falloffCurve, 1);
		}
		
		finalColor += color;
	}

	// Combine diffuse and texture color
	lowp vec4 diffuseColor = texColor * vec4(finalColor + ambient_color);

	gl_FragColor = diffuseColor;
}