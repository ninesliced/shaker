bool approx_equal(float a, float b, float epsilon) {
	return abs(a - b) < epsilon;
}

bool approx_equal_vec2(vec2 a, vec2 b, float epsilon) {
	return all(lessThan(abs(a - b), vec2(epsilon)));
}

bool approx_equal_vec3(vec3 a, vec3 b, float epsilon) {
	return all(lessThan(abs(a - b), vec3(epsilon)));
}

bool approx_equal_vec4(vec4 a, vec4 b, float epsilon) {
	return all(lessThan(abs(a - b), vec4(epsilon)));
}