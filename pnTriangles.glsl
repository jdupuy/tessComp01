#version 420 core

#ifdef _VERTEX_
layout(location = 0) in vec3 iPosition;
layout(location = 1) in vec3 iNormal;
layout(location = 2) in vec2 iTexCoord;

layout(location = 0) out vec3 oPosition;
layout(location = 1) out vec3 oNormal;
layout(location = 2) out vec2 oTexCoord;

void main()
{
	oPosition = iPosition;
	oNormal   = iNormal;
	oTexCoord = iTexCoord;
}

#endif // _VERTEX_

#ifdef _TESS_CONTROL_

layout(vertices=3) out;

uniform vec2 glu_TessLevels;

layout(location = 0) in vec3 iPosition[];
layout(location = 1) in vec3 iNormal[];
layout(location = 2) in vec2 iTexCoord[];

layout(location = 0) out vec3 oPosition[3];
layout(location = 3) out vec3 oNormal[3];
layout(location = 6) out vec2 oTexCoord[3];
layout(location = 9)   patch out float oB210[3];
layout(location = 12)  patch out float oB120[3];
layout(location = 15)  patch out float oB021[3];
layout(location = 18)  patch out float oB012[3];
layout(location = 21)  patch out float oB102[3];
layout(location = 24)  patch out float oB201[3];
layout(location = 27)  patch out float oB111[3];
layout(location = 30)  patch out float oN110[3];
layout(location = 33)  patch out float oN011[3];
layout(location = 36)  patch out float oN101[3];


float wij(int i, int j)
{
	return dot(iPosition[j] - iPosition[i], iNormal[i]);
}

float vij(int i, int j)
{
	vec3 Pj_minus_Pi    = iPosition[j] - iPosition[i];
	vec3 Ni_plus_Nj     = iNormal[i]+iNormal[j];
	return 2.0*dot(Pj_minus_Pi, Ni_plus_Nj)/dot(Pj_minus_Pi, Pj_minus_Pi);
}

void main()
{
	// get texcoord
	oPosition[gl_InvocationID] = iPosition[gl_InvocationID];
	oNormal[gl_InvocationID]   = iNormal[gl_InvocationID];
	oTexCoord[gl_InvocationID] = iTexCoord[gl_InvocationID];

	// set base 
	float P0 = iPosition[0][gl_InvocationID];
	float P1 = iPosition[1][gl_InvocationID];
	float P2 = iPosition[2][gl_InvocationID];
	float N0 = iNormal[0][gl_InvocationID];
	float N1 = iNormal[1][gl_InvocationID];
	float N2 = iNormal[2][gl_InvocationID];

	// compute control points (will be evaluated three times ...)
	oB210[gl_InvocationID] = (2.0*P0 + P1 - wij(0,1)*N0)/3.0;
	oB120[gl_InvocationID] = (2.0*P1 + P0 - wij(1,0)*N1)/3.0;
	oB021[gl_InvocationID] = (2.0*P1 + P2 - wij(1,2)*N1)/3.0;
	oB012[gl_InvocationID] = (2.0*P2 + P1 - wij(2,1)*N2)/3.0;
	oB102[gl_InvocationID] = (2.0*P2 + P0 - wij(2,0)*N2)/3.0;
	oB201[gl_InvocationID] = (2.0*P0 + P2 - wij(0,2)*N0)/3.0;
	float E = ( oB210[gl_InvocationID]
	          + oB120[gl_InvocationID]
	          + oB021[gl_InvocationID]
	          + oB012[gl_InvocationID]
	          + oB102[gl_InvocationID]
	          + oB201[gl_InvocationID] ) / 6.0;
	float V = (P0 + P1 + P2)/3.0;
	oB111[gl_InvocationID] = E + (E - V)*0.5;
	oN110[gl_InvocationID] = N0+N1-vij(0,1)*(P1-P0);
	oN011[gl_InvocationID] = N1+N2-vij(1,2)*(P2-P1);
	oN101[gl_InvocationID] = N2+N0-vij(2,0)*(P0-P2);

	// set tess levels
	gl_TessLevelOuter[gl_InvocationID] = glu_TessLevels.y;
	gl_TessLevelInner[0] = glu_TessLevels.x;
}

#endif // _TESS_CONTROL_

#ifdef _TESS_EVALUATION_
layout(triangles, fractional_odd_spacing, ccw) in;

uniform mat4 glu_ModelViewProjection;

layout(location = 0) in vec3 iPosition[];
layout(location = 3) in vec3 iNormal[];
layout(location = 6) in vec2 iTexCoord[];
layout(location = 9)   patch in float iB210[3];
layout(location = 12)  patch in float iB120[3];
layout(location = 15)  patch in float iB021[3];
layout(location = 18)  patch in float iB012[3];
layout(location = 21)  patch in float iB102[3];
layout(location = 24)  patch in float iB201[3];
layout(location = 27)  patch in float iB111[3];
layout(location = 30)  patch in float iN110[3];
layout(location = 33)  patch in float iN011[3];
layout(location = 36)  patch in float iN101[3];


layout(location = 0) out vec3 oNormal;
layout(location = 1) out vec2 oTexCoord;

#define b300    iPosition[0]
#define b030    iPosition[1]
#define b003    iPosition[2]
#define n200    iNormal[0]
#define n020    iNormal[1]
#define n002    iNormal[2]

void main()
{
	vec3 uvw        = gl_TessCoord;
	vec3 uvwSquared = uvw*uvw;
	vec3 uvwCubed   = uvwSquared*uvw;

	// extract control points
	vec3 b210 = vec3(iB210[0], iB210[1], iB210[2]);
	vec3 b120 = vec3(iB120[0], iB120[1], iB120[2]);
	vec3 b021 = vec3(iB021[0], iB021[1], iB021[2]);
	vec3 b012 = vec3(iB012[0], iB012[1], iB012[2]);
	vec3 b102 = vec3(iB102[0], iB102[1], iB102[2]);
	vec3 b201 = vec3(iB201[0], iB201[1], iB201[2]);
	vec3 b111 = vec3(iB111[0], iB111[1], iB111[2]);

	// extract control normals
	vec3 n110 = normalize(vec3(iN110[0], iN110[1], iN110[2]));
	vec3 n011 = normalize(vec3(iN011[0], iN011[1], iN011[2]));
	vec3 n101 = normalize(vec3(iN101[0], iN101[1], iN101[2]));

	oTexCoord  = gl_TessCoord[2]*iTexCoord[0]
	           + gl_TessCoord[0]*iTexCoord[1]
	           + gl_TessCoord[1]*iTexCoord[2];
	oNormal    = n200*uvwSquared[2]
	           + n020*uvwSquared[0]
	           + n002*uvwSquared[1]
	           + n110*uvw[2]*uvw[0]
	           + n011*uvw[0]*uvw[1]
	           + n101*uvw[2]*uvw[1];

	// save some computations
	uvwSquared *= 3.0;

	// compute final position
	vec3 pos  = b300*uvwCubed[2]
	          + b030*uvwCubed[0]
	          + b003*uvwCubed[1]
	          + b210*uvwSquared[2]*uvw[0]
	          + b120*uvwSquared[0]*uvw[2]
	          + b201*uvwSquared[2]*uvw[1]
	          + b021*uvwSquared[0]*uvw[1]
	          + b102*uvwSquared[1]*uvw[2]
	          + b012*uvwSquared[1]*uvw[0]
	          + b111*6.0*uvw[0]*uvw[1]*uvw[2];

//    pos = gl_TessCoord[0]*b300 + gl_TessCoord[1]*b030 + gl_TessCoord[2]*b003;

	gl_Position = glu_ModelViewProjection * vec4(pos,1.0);
}


#endif // _TESS_EVAL_

#ifdef _FRAGMENT_

uniform sampler2D gls_Diffuse;

layout(location = 0) in vec3 iNormal;
layout(location = 1) in vec2 iTexCoord;

layout(location = 0) out vec4 color;

void main()
{
	vec3 N = normalize(iNormal);
	vec3 L = normalize(vec3(1.0,1.0,1.0));
	color = max(dot(N, L), 0.0)*texture(gls_Diffuse, iTexCoord.st);
//    color.rgb = abs(N);
}

#endif // _FRAGMENT_
