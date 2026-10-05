shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

// Spikeball-style net fabric: circular cutout, slight concave sag,
// wrapped over the rim tube, square mesh holes.
uniform vec4 net_color : source_color = vec4(0.02, 0.02, 0.02, 1.0);
uniform float radius = 0.70; // reaches into the rim tube so it reads as "wrapped"
uniform float plane_size = 1.5; // must match PlaneMesh size
uniform float sag = 0.06; // center dip in meters
uniform float cells = 45.0; // holes per meter (~2.2cm holes)
uniform float strand_width = 0.14; // strand thickness as fraction of a cell
// Impact dent: set from net.gd on every catch, decays back to zero.
uniform vec2 impact_pos = vec2(99.0, 99.0); // meters, fabric-local
uniform float impact_dent = 0.0; // meters of dip at the impact point

void vertex() {
	vec2 p = (UV - 0.5) * plane_size;
	float rn = clamp(length(p) / radius, 0.0, 1.0);
	VERTEX.y -= sag * (1.0 - rn * rn);
	float id = distance(p, impact_pos);
	VERTEX.y -= impact_dent * exp(-id * id / 0.015);
}

void fragment() {
	vec2 g = UV * plane_size * cells;
	float r = length((UV - 0.5) * plane_size);
	if (r > radius) {
		discard;
	}
	vec2 f = fract(g);
	if (f.x > strand_width && f.y > strand_width) {
		discard;
	}
	ALBEDO = net_color.rgb;
	ROUGHNESS = 1.0;
}
