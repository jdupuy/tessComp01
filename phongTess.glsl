#version 420 core

// Phong tess patch data
struct PhongPatch
{
	float PIi_Pj[3];
	float PIj_Pi[3];
	float PIj_Pk[3];
	float PIk_Pj[3];
	float PIk_Pi[3];
	float PIi_Pk[3];
};

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

layout(location = 0)   out vec3 oNormal;
layout(location = 1)   out vec2 oTexCoord;

void main()
{
	gl_Position.xyz = iPosition;
	oNormal         = iNormal;
	oTexCoord       = iTexCoord;
}

#endif // _VERTEX_

#ifdef _TESS_CONTROL_

layout(vertices=3) out;

layout(location = 0)   in vec3 iNormal[];
layout(location = 1)   in vec2 iTexCoord[];

layout(location=0) out vec3 oNormal[3];
layout(location=3) out vec2 oTexCoord[3];
layout(location=6) patch out PhongPatch oPhongPatch;

#define Pi  gl_in[0].gl_Position.xyz
#define Pj  gl_in[1].gl_Position.xyz
#define Pk  gl_in[2].gl_Position.xyz

float PIi(int i, vec3 q)
{
	vec3 q_minus_p = q - gl_in[i].gl_Position.xyz;
	return q[gl_InvocationID] - dot(q_minus_p, iNormal[i])
	                          * iNormal[i][gl_InvocationID];
}

void main()
{
	// get data
	gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
	oNormal[gl_InvocationID]   = iNormal[gl_InvocationID];
	oTexCoord[gl_InvocationID] = iTexCoord[gl_InvocationID];

	// compute patch data
	oPhongPatch.PIi_Pj[gl_InvocationID] = PIi(0,Pj);
	oPhongPatch.PIj_Pi[gl_InvocationID] = PIi(1,Pi);
	oPhongPatch.PIj_Pk[gl_InvocationID] = PIi(1,Pk);
	oPhongPatch.PIk_Pj[gl_InvocationID] = PIi(2,Pj);
	oPhongPatch.PIk_Pi[gl_InvocationID] = PIi(2,Pi);
	oPhongPatch.PIi_Pk[gl_InvocationID] = PIi(0,Pk);

	// tesselate
	gl_TessLevelOuter[gl_InvocationID] = uTessLevels;
	gl_TessLevelInner[0] = uTessLevels;
}

#endif // _TESS_CONTROL_

#ifdef _TESS_EVALUATION_
layout(triangles, fractional_odd_spacing, ccw) in;

layout(location=0) in vec3 iNormal[];
layout(location=3) in vec2 iTexCoord[];
layout(location=6) patch in PhongPatch iPhongPatch;

layout(location=0) out vec3 oNormal;
layout(location=1) out vec2 oTexCoord;

#define Pi  gl_in[0].gl_Position.xyz
#define Pj  gl_in[1].gl_Position.xyz
#define Pk  gl_in[2].gl_Position.xyz
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

	// build phong tess constants
	vec3 term1 = vec3(iPhongPatch.PIi_Pj[0] + iPhongPatch.PIj_Pi[0],
	                  iPhongPatch.PIi_Pj[1] + iPhongPatch.PIj_Pi[1],
	                  iPhongPatch.PIi_Pj[2] + iPhongPatch.PIj_Pi[2]);
	vec3 term2 = vec3(iPhongPatch.PIj_Pk[0] + iPhongPatch.PIk_Pj[0],
	                  iPhongPatch.PIj_Pk[1] + iPhongPatch.PIk_Pj[1],
	                  iPhongPatch.PIj_Pk[2] + iPhongPatch.PIk_Pj[2]);
	vec3 term3 = vec3(iPhongPatch.PIk_Pi[0] + iPhongPatch.PIi_Pk[0],
	                  iPhongPatch.PIk_Pi[1] + iPhongPatch.PIi_Pk[1],
	                  iPhongPatch.PIk_Pi[2] + iPhongPatch.PIi_Pk[2]);

	// phong tesselated pos
	vec3 phongPos   = tc2[0]*Pi
	                + tc2[1]*Pj
	                + tc2[2]*Pk
	                + tc1[0]*tc1[1]*(term1)
	                + tc1[1]*tc1[2]*(term2)
	                + tc1[2]*tc1[0]*(term3);

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
