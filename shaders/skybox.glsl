varying vec4 cubeTexCoord;

#ifdef VERTEX
	uniform mat4 projectionMatrix;
	uniform mat4 viewMatrix;
	//mat4 viewMatrixNoTranslation = mat4(mat3(viewMatrix)); //crashes web verions ;)
	vec4 position(mat4 transform_projection, vec4 vertex_position)
	{
		mat4 viewMatrixNoTranslation = mat4(mat3(viewMatrix));
		cubeTexCoord = vertex_position;
		return projectionMatrix * viewMatrixNoTranslation * vec4(vec3(vertex_position),1.0);
	}
#endif

#ifdef PIXEL
	uniform CubeImage texCube;
	vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
	{
		vec4 texcolor = Texel(texCube, -vec3(cubeTexCoord));
		if (texcolor.a == 0.0) { discard; }
		return vec4(texcolor)*color;
	}
#endif