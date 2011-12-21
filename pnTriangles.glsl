#version 420 core

// PN patch data
struct PnPatch
{
	float b210[3];
	float b120[3];
	float b021[3];
	float b012[3];
	float b102[3];
	float b201[3];
	float b111[3];
	float n110[3];
	float n011[3];
	float n101[3];
};

#ifndef _WIRE
uniform sampler2D sSkin;
#endif

uniform mat4 uModelViewProjection;
uniform float uTessLevels;
uniform float uTessAlpha;

#ifdef _VERTEX_
layout(location = 0) in vec3 iPosition;
layout(location = 1) in vec3 iNormal;
layout(location = 2) in vec2 iTexCoord;

layout(location = 0) out vec3 oNormal;
layout(location = 1) out vec2 oTexCoord;

void main()
{
	gl_Position.xyz = iPosition;
	oNormal         = iNormal;
	oTexCoord       = iTexCoord;
}

#endif // _VERTEX_

#ifdef _TESS_CONTROL_

layout(vertices=3) out;

layout(location = 0) in vec3 iNormal[];
layout(location = 1) in vec2 iTexCoord[];

layout(location = 0) out vec3 oNormal[3];
layout(location = 3) out vec2 oTexCoord[3];
layout(location = 6) patch out PnPatch oPnPatch;

float wij(int i, int j)
{
	return dot(gl_in[j].gl_Position.xyz - gl_in[i].gl_Position.xyz, iNormal[i]);
}

float vij(int i, int j)
{
	vec3 Pj_minus_Pi = gl_in[j].gl_Position.xyz
	                 - gl_in[i].gl_Position.xyz;
	vec3 Ni_plus_Nj  = iNormal[i]+iNormal[j];
	return 2.0*dot(Pj_minus_Pi, Ni_plus_Nj)/dot(Pj_minus_Pi, Pj_minus_Pi);
}

void main()
{
	// get texcoord
	gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
	oNormal[gl_InvocationID]            = iNormal[gl_InvocationID];
	oTexCoord[gl_InvocationID]          = iTexCoord[gl_InvocationID];

	// set base 
	float P0 = gl_in[0].gl_Position[gl_InvocationID];
	float P1 = gl_in[1].gl_Position[gl_InvocationID];
	float P2 = gl_in[2].gl_Position[gl_InvocationID];
	float N0 = iNormal[0][gl_InvocationID];
	float N1 = iNormal[1][gl_InvocationID];
	float N2 = iNormal[2][gl_InvocationID];

	// compute control points (will be evaluated three times ...)
	oPnPatch.b210[gl_InvocationID] = (2.0*P0 + P1 - wij(0,1)*N0)/3.0;
	oPnPatch.b120[gl_InvocationID] = (2.0*P1 + P0 - wij(1,0)*N1)/3.0;
	oPnPatch.b021[gl_InvocationID] = (2.0*P1 + P2 - wij(1,2)*N1)/3.0;
	oPnPatch.b012[gl_InvocationID] = (2.0*P2 + P1 - wij(2,1)*N2)/3.0;
	oPnPatch.b102[gl_InvocationID] = (2.0*P2 + P0 - wij(2,0)*N2)/3.0;
	oPnPatch.b201[gl_InvocationID] = (2.0*P0 + P2 - wij(0,2)*N0)/3.0;
	float E = ( oPnPatch.b210[gl_InvocationID]
	          + oPnPatch.b120[gl_InvocationID]
	          + oPnPatch.b021[gl_InvocationID]
	          + oPnPatch.b012[gl_InvocationID]
	          + oPnPatch.b102[gl_InvocationID]
	          + oPnPatch.b201[gl_InvocationID] ) / 6.0;
	float V = (P0 + P1 + P2)/3.0;
	oPnPatch.b111[gl_InvocationID] = E + (E - V)*0.5;
	oPnPatch.n110[gl_InvocationID] = N0+N1-vij(0,1)*(P1-P0);
	oPnPatch.n011[gl_InvocationID] = N1+N2-vij(1,2)*(P2-P1);
	oPnPatch.n101[gl_InvocationID] = N2+N0-vij(2,0)*(P0-P2);

	// set tess levels
	gl_TessLevelOuter[gl_InvocationID] = uTessLevels;
	gl_TessLevelInner[0] = uTessLevels;
}

#endif // _TESS_CONTROL_

#ifdef _TESS_EVALUATION_
layout(triangles, fractional_odd_spacing, ccw) in;

layout(location = 0) in vec3 iNormal[];
layout(location = 3) in vec2 iTexCoord[];
layout(location = 6) patch in PnPatch iPnPatch;

layout(location = 0) out vec3 oNormal;
layout(location = 1) out vec2 oTexCoord;

#define b300    gl_in[0].gl_Position.xyz
#define b030    gl_in[1].gl_Position.xyz
#define b003    gl_in[2].gl_Position.xyz
#define n200    iNormal[0]
#define n020    iNormal[1]
#define n002    iNormal[2]
#define uvw     gl_TessCoord

void main()
{
	vec3 uvwSquared = uvw*uvw;
	vec3 uvwCubed   = uvwSquared*uvw;

	// extract control points
	vec3 b210 = vec3(iPnPatch.b210[0], iPnPatch.b210[1], iPnPatch.b210[2]);
	vec3 b120 = vec3(iPnPatch.b120[0], iPnPatch.b120[1], iPnPatch.b120[2]);
	vec3 b021 = vec3(iPnPatch.b021[0], iPnPatch.b021[1], iPnPatch.b021[2]);
	vec3 b012 = vec3(iPnPatch.b012[0], iPnPatch.b012[1], iPnPatch.b012[2]);
	vec3 b102 = vec3(iPnPatch.b102[0], iPnPatch.b102[1], iPnPatch.b102[2]);
	vec3 b201 = vec3(iPnPatch.b201[0], iPnPatch.b201[1], iPnPatch.b201[2]);
	vec3 b111 = vec3(iPnPatch.b111[0], iPnPatch.b111[1], iPnPatch.b111[2]);

	// extract control normals
	vec3 n110 = normalize(vec3(iPnPatch.n110[0],
	                           iPnPatch.n110[1],
	                           iPnPatch.n110[2]));
	vec3 n011 = normalize(vec3(iPnPatch.n011[0],
	                           iPnPatch.n011[1],
	                           iPnPatch.n011[2]));
	vec3 n101 = normalize(vec3(iPnPatch.n101[0],
	                           iPnPatch.n101[1],
	                           iPnPatch.n101[2]));

	// compute texcoords
	oTexCoord  = gl_TessCoord[2]*iTexCoord[0]
	           + gl_TessCoord[0]*iTexCoord[1]
	           + gl_TessCoord[1]*iTexCoord[2];

	// normal
	vec3 barNormal = gl_TessCoord[2]*iNormal[0]
	               + gl_TessCoord[0]*iNormal[1]
	               + gl_TessCoord[1]*iNormal[2];
	vec3 pnNormal  = n200*uvwSquared[2]
	               + n020*uvwSquared[0]
	               + n002*uvwSquared[1]
	               + n110*uvw[2]*uvw[0]
	               + n011*uvw[0]*uvw[1]
	               + n101*uvw[2]*uvw[1];
	oNormal = uTessAlpha*pnNormal + (1.0-uTessAlpha)*barNormal; // should we normalize ?

	// compute interpolated pos
	vec3 barPos = gl_TessCoord[2]*b300
	            + gl_TessCoord[0]*b030
	            + gl_TessCoord[1]*b003;

	// save some computations
	uvwSquared *= 3.0;

	// compute PN position
	vec3 pnPos  = b300*uvwCubed[2]
	            + b030*uvwCubed[0]
	            + b003*uvwCubed[1]
	            + b210*uvwSquared[2]*uvw[0]
	            + b120*uvwSquared[0]*uvw[2]
	            + b201*uvwSquared[2]*uvw[1]
	            + b021*uvwSquared[0]*uvw[1]
	            + b102*uvwSquared[1]*uvw[2]
	            + b012*uvwSquared[1]*uvw[0]
	            + b111*6.0*uvw[0]*uvw[1]*uvw[2];

	// final position and normal
	vec3 finalPos = (1.0-uTessAlpha)*barPos + uTessAlpha*pnPos;
	gl_Position   = uModelViewProjection * vec4(finalPos,1.0);
}

#endif // _TESS_EVAL_

#ifdef _FRAGMENT_

layout(location = 0) in vec3 iNormal;
layout(location = 1) in vec2 iTexCoord;

layout(location = 0) out vec4 oColor;

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
