//Alesan99
//MASTER 3D SHADER
//Phong Shading (from: g3d)
//Ortho & Perspective Shadow Mapping
//Metalic Reflection w/ Environment Map
//https://learnopengl.com/Lighting/Basic-Lighting
//http://www.opengl-tutorial.org/intermediate-tutorials/tutorial-16-shadow-mapping/

//Model and Camera
uniform mat4 projectionMatrix; //Camera Matrix (FOV, Aspect Ratio, etc.)
uniform mat4 viewMatrix; //Camera Transformation Matrix
uniform vec3 viewDir;
uniform vec3 viewPos;
uniform mat4 modelMatrix; //Model Transformaton Matrix
uniform mat4 modelMatrixInverse; //Inverse to calculate normals

varying vec3 normal; //Vertex Normal
varying vec3 vertColor; //Vertex Color
bool vertexColors = false;

//Lighting
uniform float ambientLight;
uniform float ambientLightAdd;
uniform vec3 ambientVector; //Sun Light

vec3 shadowColor = vec3(0.0,0.2,0.6);

uniform vec3 lightPos; //Point Light
vec4 lightColor = vec4(1.0,0.0,0.0,1.0);
varying vec3 vertPos; //vertex position (for point lights)

//float specularStrength = 0.15;
//float specularClarity = 8.0;

//Shadow Map
uniform mat4 shadowProjectionMatrix;
uniform mat4 shadowViewMatrix;
uniform vec3 shadowMapDir; //should be the same as ambientVector, but for this game im stylizing the lighting
//uniform sampler2DShadow shadowMap;
uniform Image shadowMapImage;
//uniform float shadowMapSize;
mat4 Bias = mat4( // change projected depth values from -1 - 1 to 0 - 1
	0.5, 0.0, 0.0, 0.5,
	0.0, 0.5, 0.0, 0.5,
	0.0, 0.0, 0.5, 0.5,
	0.0, 0.0, 0.0, 1.0
	);
float shadowBiasStrength = 0.00003;//0.00005; //Fixes Shadow Acne
varying vec4 project; //shadow projected vertex
bool smoothShadows = false; //Bilinear Filtering
//float smoothShadowSampleOff = 1.0/shadowMapSize; //offset of smoothing samples for shadow
uniform bool animated;

//Metal
//uniform bool metallic;
//uniform CubeImage environmentMap;

#ifdef VERTEX
	attribute vec4 VertexNormal;
	attribute vec4 VertexWeight;
	attribute vec4 VertexBone;
	uniform mat4 u_pose[16]; //100 bones crashes web version, only set to whats absolutely necessary
	//attribute vec3 VertexColor; //Not needed; Sent by LOVE automatically

	vec4 position(mat4 transform_projection, vec4 vertex_position)
	{
		normal = normalize(vec3(vec4(modelMatrixInverse*VertexNormal))); //interpolate normal

		if (animated == true) {
			mat4 skeleton = u_pose[int(VertexBone.x*255.0)] * VertexWeight.x +
				u_pose[int(VertexBone.y*255.0)] * VertexWeight.y +
				u_pose[int(VertexBone.z*255.0)] * VertexWeight.z +
				u_pose[int(VertexBone.w*255.0)] * VertexWeight.w;
			vertex_position = skeleton * vertex_position;
			mat4 transform = modelMatrix * skeleton;
			normal = normalize(mat3(transform) * vec3(VertexNormal));
		};
		
		if (vertexColors) { vertColor = vec3(VertexColor); }; //interpolate vertexColor

		project = vec4(shadowProjectionMatrix * shadowViewMatrix * modelMatrix * vertex_position * Bias); //projected position on shadowMap
		vertPos = vec3(modelMatrix * vertex_position);

		return projectionMatrix * viewMatrix * modelMatrix * vertex_position;
	}
#endif

#ifdef PIXEL

	vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
	{
		//IGNORE ALPHA
		vec4 texcolor = Texel(tex, texcoord);
		if (texcolor.a == 0.0) { discard; };
		texcolor = texcolor*color; //apply color
		if (vertexColors) { texcolor *= vec4(vertColor,1.0); }; //apply vertex color

		//METAL
		//if (metallic == true) {
		//	vec3 I = normalize(vertPos - viewPos);
		//	vec3 R = reflect(I, normalize(normal));
		//	texcolor = Texel(environmentMap, -R);
		//};

		//SMOOTH LIGHING (Phong Shading)
		vec3 lightDir = ambientVector; //Sun Light
		//vec3 lightDir = normalize(lightPos - vertPos); //Point Light
		float diffuse = max(dot(lightDir, normal), 0.0)+ambientLightAdd; //smooth lighting

		//SPECULAR LIGHT (Sun Light)
		//vec3 viewDir = normalize(viewPos - vertPos);
		//vec3 reflectDir = reflect(-lightDir, normal);  
		//float spec = pow(max(dot(viewDir, reflectDir), 0.0), specularClarity); //Change clarity for how much light scatters
		//float specular = specularStrength * spec;

		//TEST FOR SHADOW (Shadow Mapping)
		float shadowBias = shadowBiasStrength*tan(acos(clamp(dot(normal,shadowMapDir),0.0,1.0))); //invert when using front-face culling
		shadowBias = clamp(shadowBias, 0.0,0.01);

		float pixelDist = (project.z-shadowBias)/project.w; //How far this pixel is from the camera
		vec2 shadowMapCoord = ((project.xy)/project.w); //Where this vertex is on the shadowMap
		float shadowMapPixelDist;
		float inShadow;
		//SHADOW SMOOTHING
		if (smoothShadows == true) {
			//1. Unquote the stuff here
			//2. Unquote sampler2Dshadow
			//3. Unquote the depth sample mode in sun.lua
			//shadowMapPixelDist = shadow2DProj(shadowMap, project-shadowBias, shadowBias).r; //Closest pixel to camera according to shadowMap
			//inShadow = 1.0-shadowMapPixelDist;
		} else {
			shadowMapPixelDist = Texel(shadowMapImage, shadowMapCoord).r;
			inShadow = mix(float(shadowMapPixelDist < pixelDist),0.0,1.0-float((shadowMapCoord.x >= 0.0) && (shadowMapCoord.y >= 0.0) && (shadowMapCoord.x <= 1.0) && (shadowMapCoord.y <= 1.0))); //0.0;
		};

		//FINALIZE SHADOWS
		diffuse = min(1.0-inShadow*(1.0-ambientLight), diffuse); //shadow
		vec4 finalcolor = vec4(vec3(texcolor)*mix(shadowColor,vec3(1.0),max(diffuse, ambientLight)), 1.0);
		//vec4 finalcolor = vec4(vec3(texcolor)*mix(shadowColor,vec3(1.0),max(diffuse + specular*(1.0-inShadow), ambientLight)), 1.0);

		return finalcolor;
		//return vec4(vec3(inShadow),1.0);
		//return vec4(vec3(pixelDist),1.0);
		//return vec4(vec3(shadowMapPixelDist),1.0);
	}
#endif