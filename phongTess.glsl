#version 420 core

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

uniform vec2 glu_TessLevels;

layout(location = 0)   in vec3 iPosition[];
layout(location = 1)   in vec3 iNormal[];
layout(location = 2)   in vec2 iTexCoord[];

out vec3 PIi_pj[3];
out vec3 PIj_pi[3];
out vec3 PIj_pk[3];
out vec3 PIk_pj[3];
out vec3 PIk_pi[3];
out vec3 PIi_pk[3];
out vec3 position[3];
out vec3 normal[3];
out vec2 texCoord[3];

#define Pi iPosition[0]
#define Pj iPosition[1]
#define Pk iPosition[2]

vec3 PIi(int i, vec3 q)
{
    vec3 q_minus_p = q - iPosition[i];
    return q - dot(q_minus_p, iNormal[i])*iNormal[i];
//    return q - q_minus_p* iNormal[i]*iNormal[i];
}

void main()
{
    // get texcoord
    position[gl_InvocationID] = iPosition[gl_InvocationID];
    normal[gl_InvocationID]   = iNormal[gl_InvocationID];
    texCoord[gl_InvocationID] = iTexCoord[gl_InvocationID];

    // compute control points
//    if(gl_InvocationID==0)
//    {
    PIi_pj[gl_InvocationID] = PIi(0,Pj);
    PIj_pi[gl_InvocationID] = PIi(1,Pi);
    PIj_pk[gl_InvocationID] = PIi(1,Pk);
    PIk_pj[gl_InvocationID] = PIi(2,Pj);
    PIk_pi[gl_InvocationID] = PIi(2,Pi);
    PIi_pk[gl_InvocationID] = PIi(0,Pk);

//    }

    // tesselate
    gl_TessLevelOuter[gl_InvocationID] = glu_TessLevels.y;
    gl_TessLevelInner[0] = glu_TessLevels.x;
}

#endif // _TESS_CONTROL_

#ifdef _TESS_EVALUATION_
layout(triangles, fractional_odd_spacing, ccw) in;

uniform mat4 glu_ModelView;
uniform mat4 glu_ModelViewProjection;
//uniform float glu_Alpha;    // must lie in [0,1]

in vec3 PIi_pj[];
in vec3 PIj_pi[];
in vec3 PIj_pk[];
in vec3 PIk_pj[];
in vec3 PIk_pi[];
in vec3 PIi_pk[];
in vec3 position[];
in vec3 normal[];
in vec2 texCoord[];

out vec3 l;
out vec3 n;
out vec2 uv;

#define pi  position[0]
#define pj  position[1]
#define pk  position[2]

void main()
{
    vec3 tc1 = gl_TessCoord;
    vec3 tc2 = tc1*tc1;

    uv  = gl_TessCoord[0]*texCoord[0] + gl_TessCoord[1]*texCoord[1] + gl_TessCoord[2]*texCoord[2];
    n   = gl_TessCoord[0]*normal[0] + gl_TessCoord[1]*normal[1] + gl_TessCoord[2]*normal[2];
    n   = normalize((glu_ModelView * vec4(n,0.0)).xyz);
	l 	= normalize((glu_ModelView * vec4(3.0,2.0,2.0,0.0)).xyz);
    // barycentric position
//    vec3 barPos = gl_TessCoord[0]*pi + gl_TessCoord[1]*pj + gl_TessCoord[2]*pk;
    // phong tesselated pos
    vec3 phongPos   = tc2[0]*pi
                    + tc2[1]*pj
                    + tc2[2]*pk
                    + tc1[0]*tc1[1]*(PIi_pj[0]+PIj_pi[0])
                    + tc1[1]*tc1[2]*(PIj_pk[0]+PIk_pj[0])
                    + tc1[2]*tc1[0]*(PIk_pi[0]+PIi_pk[0]);
    // compute final position
//    vec3 finalPos = (1.0-glu_Alpha)*barPos + glu_Alpha*phongPos;
    vec3 finalPos = phongPos;
    gl_Position = glu_ModelViewProjection * vec4(finalPos,1.0);
}


#endif // _TESS_EVAL_

#ifdef _FRAGMENT_

uniform sampler2D gls_Diffuse;
//uniform vec3 glu_LightPos;
//uniform vec3 glu_CamPos;

in vec3 l;
in vec3 n;
in vec2 uv;

out vec4 color;

void main()
{
	vec3 L = normalize(l);
	vec3 N = normalize(n);
	color = max(dot(N, L), 0.0)*texture(gls_Diffuse, uv.xy);
//    color.rgb = abs(N);
}

#endif // _FRAGMENT_
