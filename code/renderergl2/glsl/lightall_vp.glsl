attribute vec4 attr_TexCoord0;
#if defined(USE_LIGHTMAP) || defined(USE_TCGEN)
attribute vec4 attr_TexCoord1;
#endif
attribute vec4 attr_Color;

attribute vec4 attr_Position;
attribute vec3 attr_Normal;

#if defined(USE_VERT_TANGENT_SPACE)
attribute vec3 attr_Tangent;
attribute vec3 attr_Bitangent;
#endif

#if defined(USE_VERTEX_ANIMATION)
attribute vec4 attr_Position2;
attribute vec3 attr_Normal2;
  #if defined(USE_VERT_TANGENT_SPACE)
attribute vec3 attr_Tangent2;
attribute vec3 attr_Bitangent2;
  #endif
#endif

#if defined(USE_LIGHT) && !defined(USE_LIGHT_VECTOR)
attribute vec3 attr_LightDirection;
#endif

#if defined(USE_TCGEN) || defined(USE_NORMALMAP) || defined(USE_LIGHT) && !defined(USE_FAST_LIGHT)
uniform vec3   u_ViewOrigin;
#endif

#if defined(USE_TCGEN)
uniform int    u_TCGen0;
uniform vec3   u_TCGen0Vector0;
uniform vec3   u_TCGen0Vector1;
#endif

#if defined(USE_TCMOD)
uniform vec4   u_DiffuseTexMatrix;
uniform vec4   u_DiffuseTexOffTurb;
#endif

uniform mat4   u_ModelViewProjectionMatrix;
uniform vec4   u_BaseColor;
uniform vec4   u_VertColor;

#if defined(USE_MODELMATRIX)
uniform mat4   u_ModelMatrix;
#endif

#if defined(USE_VERTEX_ANIMATION)
uniform float  u_VertexLerp;
#endif

#if defined(USE_LIGHT_VECTOR)
uniform vec4   u_LightOrigin;
  #if defined(USE_FAST_LIGHT)
uniform vec3   u_DirectedLight;
uniform vec3   u_AmbientLight;
uniform float  u_LightRadius;
  #endif
#endif

#if defined(USE_PRIMARY_LIGHT) || defined(USE_SHADOWMAP)
uniform vec4  u_PrimaryLightOrigin;
#endif

varying vec2   var_DiffuseTex;

#if defined(USE_LIGHTMAP)
varying vec2   var_LightTex;
#endif

#if defined(USE_TCGEN) || defined(USE_NORMALMAP) || (defined(USE_LIGHT) && !defined(USE_FAST_LIGHT))
varying vec3   var_SampleToView;
#endif

varying vec4   var_Color;

#if defined(USE_NORMALMAP) && !defined(USE_VERT_TANGENT_SPACE)
varying vec3   var_Position;
#endif


#if !defined(USE_FAST_LIGHT)
varying vec3   var_Normal;
  #if defined(USE_VERT_TANGENT_SPACE)
varying vec3   var_Tangent;
varying vec3   var_Bitangent;
  #endif
#endif

#if defined(USE_LIGHT_VERTEX) && !defined(USE_FAST_LIGHT)
varying vec3   var_VertLight;
#endif

#if defined(USE_LIGHT) && !defined(USE_DELUXEMAP) && !defined(USE_FAST_LIGHT)
varying vec3   var_LightDirection;
#endif

#if defined(USE_PRIMARY_LIGHT) || defined(USE_SHADOWMAP)
varying vec3   var_PrimaryLightDirection;
#endif

#if defined(USE_TCGEN)
vec2 GenTexCoords(int TCGen, vec3 position, vec3 normal, vec3 TCGenVector0, vec3 TCGenVector1)
{
	vec2 tex = attr_TexCoord0.st;

	if (TCGen == TCGEN_LIGHTMAP)
	{
		tex = attr_TexCoord1.st;
	}
	else if (TCGen == TCGEN_ENVIRONMENT_MAPPED)
	{
		vec3 viewer = normalize(u_ViewOrigin - position);
		tex = -reflect(viewer, normal).yz * vec2(0.5, -0.5) + 0.5;
	}
	else if (TCGen == TCGEN_VECTOR)
	{
		tex = vec2(dot(position, TCGenVector0), dot(position, TCGenVector1));
	}
	
	return tex;
}
#endif

#if defined(USE_TCMOD)
vec2 ModTexCoords(vec2 st, vec3 position, vec4 texMatrix, vec4 offTurb)
{
	float amplitude = offTurb.z;
	float phase = offTurb.w;
	vec2 st2 = vec2(dot(st, texMatrix.xz), dot(st, texMatrix.yw)) + offTurb.xy;

	vec3 offsetPos = vec3(0); //position / 1024.0;
	offsetPos.x += offsetPos.z;
	
	vec2 texOffset = sin((offsetPos.xy + vec2(phase)) * 2.0 * M_PI);
	
	return st2 + texOffset * amplitude;	
}
#endif


void main()
{
#if defined(USE_VERTEX_ANIMATION)
	vec4 position  = mix(attr_Position, attr_Position2, u_VertexLerp);
	vec3 normal    = normalize(mix(attr_Normal,    attr_Normal2,    u_VertexLerp));
  #if defined(USE_VERT_TANGENT_SPACE)
	vec3 tangent   = normalize(mix(attr_Tangent,   attr_Tangent2,   u_VertexLerp));
	vec3 bitangent = normalize(mix(attr_Bitangent, attr_Bitangent2, u_VertexLerp));
  #endif
#else
	vec4 position  = attr_Position;
	vec3 normal    = attr_Normal;
  #if defined(USE_VERT_TANGENT_SPACE)
	vec3 tangent   = attr_Tangent;
	vec3 bitangent = attr_Bitangent;
  #endif
#endif

	gl_Position = u_ModelViewProjectionMatrix * position;

#if (defined(USE_LIGHTMAP) || defined(USE_LIGHT_VERTEX)) && !defined(USE_DELUXEMAP) && !defined(USE_FAST_LIGHT)
	vec3 L = attr_LightDirection;
#endif
	
#if defined(USE_MODELMATRIX)
	position  = u_ModelMatrix * position;
	normal    = (u_ModelMatrix * vec4(normal, 0.0)).xyz;
  #if defined(USE_VERT_TANGENT_SPACE)
	tangent   = (u_ModelMatrix * vec4(tangent, 0.0)).xyz;
	bitangent = (u_ModelMatrix * vec4(bitangent, 0.0)).xyz;
  #endif

  #if defined(USE_LIGHTMAP) && !defined(USE_DELUXEMAP) && !defined(USE_FAST_LIGHT)
	L = (u_ModelMatrix * vec4(L, 0.0)).xyz;
  #endif
#endif

#if defined(USE_NORMALMAP) && !defined(USE_VERT_TANGENT_SPACE)
	var_Position = position.xyz;
#endif

#if defined(USE_TCGEN) || defined(USE_NORMALMAP) || (defined(USE_LIGHT) && !defined(USE_FAST_LIGHT))
	var_SampleToView = u_ViewOrigin - position.xyz;
#endif

#if defined(USE_TCGEN)
	vec2 texCoords = GenTexCoords(u_TCGen0, position.xyz, normal, u_TCGen0Vector0, u_TCGen0Vector1);
#else
	vec2 texCoords = attr_TexCoord0.st;
#endif

#if defined(USE_TCMOD)
	var_DiffuseTex = ModTexCoords(texCoords, position.xyz, u_DiffuseTexMatrix, u_DiffuseTexOffTurb);
#else
	var_DiffuseTex = texCoords;
#endif

#if defined(USE_LIGHTMAP)
	var_LightTex = attr_TexCoord1.st;
#endif

#if !defined(USE_FAST_LIGHT)
	var_Normal = normal;
  #if defined(USE_VERT_TANGENT_SPACE)
	var_Tangent = tangent;
	var_Bitangent = bitangent;
  #endif
#endif

#if defined(USE_LIGHT) && !defined(USE_DELUXEMAP)
  #if defined(USE_LIGHT_VECTOR)
	vec3 L = u_LightOrigin.xyz - (position.xyz * u_LightOrigin.w);
  #endif
  #if !defined(USE_FAST_LIGHT)
	var_LightDirection = L;
  #endif
#endif
	
#if defined(USE_LIGHT_VERTEX) && !defined(USE_FAST_LIGHT)
	var_VertLight = u_VertColor.rgb * attr_Color.rgb;
	var_Color.rgb = vec3(1.0);
	var_Color.a = u_VertColor.a * attr_Color.a + u_BaseColor.a;
#else
	var_Color = u_VertColor * attr_Color + u_BaseColor;
#endif

#if defined(USE_LIGHT_VECTOR) && defined(USE_FAST_LIGHT)
  #if defined(USE_INVSQRLIGHT)
	float intensity = 1.0 / dot(L, L);
  #else
	float intensity = clamp((1.0 - dot(L, L) / (u_LightRadius * u_LightRadius)) * 1.07, 0.0, 1.0);
  #endif
	float NL = clamp(dot(normal, normalize(L)), 0.0, 1.0);

	var_Color.rgb *= u_DirectedLight * intensity * NL + u_AmbientLight;
#endif

#if defined(USE_PRIMARY_LIGHT) || defined(USE_SHADOWMAP)
	var_PrimaryLightDirection = u_PrimaryLightOrigin.xyz - (position.xyz * u_PrimaryLightOrigin.w);
#endif	
}
