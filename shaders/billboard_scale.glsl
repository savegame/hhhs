//Alesan99
//Renders Sprite in 3D space that always faces Camera
//http://www.opengl-tutorial.org/intermediate-tutorials/billboards-particles/billboards/
uniform mat4 projectionMatrix;
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform vec3 modelScale;
uniform float canvasFlip; //(1: no canvas, -1: canvas) canvases flip the y coordinate, so this fixes it.

#ifdef VERTEX
	vec4 position(mat4 transform_projection, vec4 vertex_position)
	{
		mat4 modelView = viewMatrix * modelMatrix;
		
		// Column 0:
		modelView[0][0] = -modelScale[0];
		modelView[0][1] = 0.0;
		modelView[0][2] = 0.0;

		// Column 1:
		modelView[1][0] = 0.0;
		modelView[1][1] = -modelScale[1]*canvasFlip;
		modelView[1][2] = 0.0;

		// Column 2:
		modelView[2][0] = 0.0;
		modelView[2][1] = 0.0;
		modelView[2][2] = modelScale[2];
		
		return projectionMatrix *  modelView * vertex_position;
	}
#endif

#ifdef PIXEL
	vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
	{
		vec4 texcolor = Texel(tex, texcoord);
		if (texcolor.a == 0.0) { discard; }
		return vec4(texcolor)*color;
	}
#endif