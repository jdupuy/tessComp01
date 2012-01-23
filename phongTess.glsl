#version 420 core

// Phong tess patch data
struct PhongPatch
{
	float termIJ;
	float termJK;
	float termIK;
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
layout(location=6) out PhongPatch oPhongPatch[3];

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
	oPhongPatch[gl_InvocationID].termIJ = PIi(0,Pj) + PIi(1,Pi);
	oPhongPatch[gl_InvocationID].termJK = PIi(1,Pk) + PIi(2,Pj);
	oPhongPatch[gl_InvocationID].termIK = PIi(2,Pi) + PIi(0,Pk);

	// tesselate
	gl_TessLevelOuter[gl_InvocationID] = uTessLevels;
	gl_TessLevelInner[0] = uTessLevels;
}

#endif // _TESS_CONTROL_

#ifdef _TESS_EVALUATION_
layout(triangles, fractional_odd_spacing, ccw) in;

layout(location=0) in vec3 iNormal[];
layout(location=3) in vec2 iTexCoord[];
layout(location=6) in PhongPatch iPhongPatch[];

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

	// build terms
	vec3 termIJ = vec3(iPhongPatch[0].termIJ,
	                   iPhongPatch[1].termIJ,
	                   iPhongPatch[2].termIJ);
	vec3 termJK = vec3(iPhongPatch[0].termJK,
	                   iPhongPatch[1].termJK,
	                   iPhongPatch[2].termJK);
	vec3 termIK = vec3(iPhongPatch[0].termIK,
	                   iPhongPatch[1].termIK,
	                   iPhongPatch[2].termIK);

	// phong tesselated pos
	vec3 phongPos   = tc2[0]*Pi
	                + tc2[1]*Pj
	                + tc2[2]*Pk
	                + tc1[0]*tc1[1]*termIJ
	                + tc1[1]*tc1[2]*termJK
	                + tc1[2]*tc1[0]*termIK;

	// final position
	vec3 finalPos = (1.0-uTessAlpha)*barPos + uTessAlpha*phongPos;
	gl_Position   = uModelViewProjection * vec4(finalPos,1.0);
}

#endif // _TESS_EVAL_

#ifdef _FRAGMENT_

layout(location=0) in vec3 iNormal;
layout(location=1) in vec2 iTexCoord;

layout(location=0) out vec4 oColour;

void main()
{
	vec3 N = normalize(iNormal);
	vec3 L = normalize(vec3(1.0));

#if defined _SHADED
	oColour = max(dot(N, L), 0.0)*texture(sSkin, iTexCoord);

#elif defined _WIRE
	oColour.rgb = vec3(0.0,1.0,0.0);

#elif defined _NORMAL
	oColour.rgb = abs(N);

#else
	oColour = texture(sSkin, iTexCoord);

#endif
}

#endif // _FRAGMENT_
