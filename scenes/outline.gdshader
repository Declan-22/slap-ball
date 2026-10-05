shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled;

// Toon outline pass. Assign as material_overlay on any GeometryInstance3D:
// back faces push out along their normals and render flat near-black,
// framing the object with a cartoony outline.
uniform float thickness = 0.012; // meters

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = vec3(0.01, 0.01, 0.015);
}
