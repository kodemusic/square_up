shader_type canvas_item;

/// Base color tint for the entire cube
uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

/// Brightness multiplier for each face
uniform float top_brightness : hint_range(0.0, 2.0) = 1.2;     // Slightly lighter
uniform float left_brightness : hint_range(0.0, 2.0) = 1.0;    // Unchanged
uniform float right_brightness : hint_range(0.0, 2.0) = 0.8;   // Slightly darker

/// UV boundary thresholds for face detection
/// Adjust these if your texture layout differs
uniform float top_threshold_y : hint_range(0.0, 1.0) = 0.5;    // Top face is above this Y

void fragment() {
	// Sample the original texture
	vec4 tex_color = texture(TEXTURE, UV);

	// Determine which face this pixel belongs to based on UV coordinates
	float brightness = 1.0;

	// Top face: upper portion of texture (Y < threshold)
	if (UV.y < top_threshold_y) {
		brightness = top_brightness;
	}
	// Bottom half is divided between left and right faces
	else {
		// Left face: lower-left (X < 0.5)
		if (UV.x < 0.5) {
			brightness = left_brightness;
		}
		// Right face: lower-right (X >= 0.5)
		else {
			brightness = right_brightness;
		}
	}

	// Apply base color tint and brightness
	COLOR = tex_color * base_color * vec4(vec3(brightness), 1.0);
}
