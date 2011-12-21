#version 420 core

#ifndef _WIRE
uniform sampler2D sSkin;
#endif

uniform float uTessLevels;
uniform float uTessAlpha;
uniform mat4  uModelViewProjection;

#ifdef _VERTEX_
layout(location = 0)   in vec3 iPosition;
layout(location = 1)   in vec3 iNormal;
layout(location = 2)   in vec2 iTexCoord;

layout(location = 0)   out vec3 oPosition;
layout(location = 1)   out vec3 oNormal;
layout(location = 2)   out vec2 oTexCoord;

void main()
{
	oPosition = iPosition;
	oNormal   = iNormal;
	oTexCoord = iTexCoord;
}

#endif // _VERTEX_

#ifdef _TESS_CONTROL_

layout(vertices=3) out;

layout(location = 0)   in vec3 iPosition[];
layout(location = 1)   in vec3 iNormal[];
layout(location = 2)   in vec2 iTexCoord[];

layout(location=0) out vec3 oPosition[3];
layout(location=3) out vec3 oNormal[3];
layout(location=6) out vec2 oTexCoord[3];
layout(location=9)  patch out vec3 oPIi_Pj[3];
layout(location=12) patch out vec3 oPIj_Pi[3];
layout(location=15) patch out vec3 oPIj_Pk[3];
layout(location=18) patch out vec3 oPIk_Pj[3];
layout(location=21) patch out vec3 oPIk_Pi[3];
layout(location=24) patch out vec3 oPIi_Pk[3];

#define Pi iPosition[0]
#define Pj iPosition[1]
#define Pk iPosition[2]

vec3 PIi(int i, vec3 q)
{
	vec3 q_minus_p = q - iPosition[i];
	return q - dot(q_minus_p, iNormal[i])*iNormal[i];
}

void main()
{
	// get texcoord
	oPosition[gl_InvocationID] = iPosition[gl_InvocationID];
	oNormal[gl_InvocationID]   = iNormal[gl_InvocationID];
	oTexCoord[gl_InvocationID] = iTexCoord[gl_InvocationID];

	oPIi_Pj[gl_InvocationID] = PIi(0,Pj);
	oPIj_Pi[gl_InvocationID] = PIi(1,Pi);
	oPIj_Pk[gl_InvocationID] = PIi(1,Pk);
	oPIk_Pj[gl_InvocationID] = PIi(2,Pj);
	oPIk_Pi[gl_InvocationID] = PIi(2,Pi);
	oPIi_Pk[gl_InvocationID] = PIi(0,Pk);

	// tesselate
	gl_TessLevelOuter[gl_InvocationID] = uTessLevels;
	gl_TessLevelInner[0] = uTessLevels;
}

#endif // _TESS_CONTROL_

#ifdef _TESS_EVALUATION_
layout(triangles, fractional_odd_spacing, ccw) in;

layout(location=0) in vec3 iPosition[];
layout(location=3) in vec3 iNormal[];
layout(location=6) in vec2 iTexCoord[];
layout(location=9)  patch in vec3 iPIi_Pj[3];
layout(location=12) patch in vec3 iPIj_Pi[3];
layout(location=15) patch in vec3 iPIj_Pk[3];
layout(location=18) patch in vec3 iPIk_Pj[3];
layout(location=21) patch in vec3 iPIk_Pi[3];
layout(location=24) patch in vec3 iPIi_Pk[3];

layout(location=0) out vec3 oNormal;
layout(location=1) out vec2 oTexCoord;

#define Pi  iPosition[0]
#define Pj  iPosition[1]
#define Pk  iPosition[2]
#define tc1 gl_TessCoord

void main()
{
	// precompute squared tesscoords
	vec3 tc2 = tc1*tc1;

	// compute texcoord and normal
	oTexCoord = gl_TessCoord[0]*iTexCoord[0]
	          + gl_TessCoord[1]*iTexCoord[1]
	          + gl_TessCoord[2]*iTexCoord[2];
	oNormal   = gl_TessCoord[0]*iNormal[0]
	          + gl_TessCoord[1]*iNormal[1]
	          + gl_TessCoord[2]*iNormal[2];

	// interpolated position
	vec3 barPos = gl_TessCoord[0]*Pi
	            + gl_TessCoord[1]*Pj
	            + gl_TessCoord[2]*Pk;

	// phong tesselated pos
	vec3 phongPos   = tc2[0]*Pi
	                + tc2[1]*Pj
	                + tc2[2]*Pk
	                + tc1[0]*tc1[1]*(iPIi_Pj[0]+iPIj_Pi[0])
	                + tc1[1]*tc1[2]*(iPIj_Pk[0]+iPIk_Pj[0])
	                + tc1[2]*tc1[0]*(iPIk_Pi[0]+iPIi_Pk[0]);

	// final position
	vec3 finalPos = (1.0-uTessAlpha)*barPos + uTessAlpha*phongPos;
	gl_Position   = uModelViewProjection * vec4(finalPos,1.0);
}

#endif // _TESS_EVAL_

#ifdef _FRAGMENT_

layout(location=0) in vec3 iNormal;
layout(location=1) in vec2 iTexCoord;

layout(location=0) out vec4 oColor;

void main()
{
#ifndef _WIRE
	vec3 N = normalize(iNormal);
	vec3 L = normalize(vec3(1.0));
	oColor = max(dot(N, L), 0.0)*texture(sSkin, iTexCoord);
//	oColor.rgb = abs(N);
#else
	oColor.rgb = vec3(0.0,1.0,0.0);
#endif
}

#endif // _FRAGMENT_
