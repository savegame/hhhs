uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 modelMatrixInverse;
uniform mat4 viewMatrix;
uniform float ambientLight;
uniform float ambientLightAdd;
uniform vec3 ambientVector;

varying vec3 normal;

#ifdef VERTEX
	attribute vec4 VertexNormal;

	vec4 position(mat4 transform_projection, vec4 vertex_position)
	{
		normal = vec3(vec4(modelMatrixInverse*VertexNormal));
		return projectionMatrix * viewMatrix * modelMatrix * vertex_position;
	}
#endif

#ifdef PIXEL
	vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
	{
		vec4 texcolor = Texel(tex, texcoord);
		if (texcolor.a == 0.0) { discard; }

		float light = max(dot(normalize(ambientVector), normal), 0.0)+ambientLightAdd;
		texcolor.rgb *= max(light, ambientLight);

		return vec4(texcolor)*color;
	}
#endif