#ifndef LIGHTWEIGHT_INPUT_INCLUDED
#define LIGHTWEIGHT_INPUT_INCLUDED

#define MAX_VISIBLE_LIGHTS 16

// Main light initialized without indexing
#define INITIALIZE_MAIN_LIGHT(light) \
    light.pos = _LightPosition; \
    light.color = _LightColor; \
    light.atten = _LightAttenuationParams; \
    light.spotDir = _LightSpotDir;

// Indexing might have a performance hit for old mobile hardware
#define INITIALIZE_LIGHT(light, lightIndex) \
                            light.pos = globalLightPos[lightIndex]; \
                            light.color = globalLightColor[lightIndex]; \
                            light.atten = globalLightAtten[lightIndex]; \
                            light.spotDir = globalLightSpotDir[lightIndex]

#if !(defined(_SINGLE_DIRECTIONAL_LIGHT) || defined(_SINGLE_SPOT_LIGHT) || defined(_SINGLE_POINT_LIGHT))
#define _MULTIPLE_LIGHTS
#endif

struct LightInput
{
    float4 pos;
    half4 color;
    float4 atten;
    half4 spotDir;
};

sampler2D _AttenuationTexture;

// Per object light list data
#ifdef _MULTIPLE_LIGHTS
half4 unity_LightIndicesOffsetAndCount;
half4 unity_4LightIndices0;

// The variables are very similar to built-in unity_LightColor, unity_LightPosition,
// unity_LightAtten, unity_SpotDirection as used by the VertexLit shaders, except here
// we use world space positions instead of view space.
half4 globalLightCount;
half4 globalLightColor[MAX_VISIBLE_LIGHTS];
float4 globalLightPos[MAX_VISIBLE_LIGHTS];
half4 globalLightSpotDir[MAX_VISIBLE_LIGHTS];
float4 globalLightAtten[MAX_VISIBLE_LIGHTS];
#else
float4 _LightPosition;
half4 _LightColor;
float4 _LightAttenuationParams;
half4 _LightSpotDir;
#endif

half _Shininess;
samplerCUBE _Cube;
half4 _ReflectColor;

struct LightweightVertexInput
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 texcoord : TEXCOORD0;
    float2 lightmapUV : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct LightweightVertexOutput
{
    float4 uv01 : TEXCOORD0; // uv01.xy: uv0, uv01.zw: uv1
    float4 posWS : TEXCOORD1;
#if _NORMALMAP
    half3 tangentToWorld0 : TEXCOORD2; // tangentToWorld matrix
    half3 tangentToWorld1 : TEXCOORD3; // tangentToWorld matrix
    half3 tangentToWorld2 : TEXCOORD4; // tangentToWorld matrix
#else
    half3 normal : TEXCOORD2;
#endif
    half4 viewDir : TEXCOORD5; // xyz: viewDir
    half4 fogCoord : TEXCOORD6; // x: fogCoord, yzw: vertexColor
    float4 hpos : SV_POSITION;
    UNITY_VERTEX_OUTPUT_STEREO
};

inline void NormalMap(LightweightVertexOutput i, out half3 normal)
{
#if _NORMALMAP
    half3 normalmap = UnpackNormal(tex2D(_BumpMap, i.uv01.xy));

    // glsl compiler will generate underperforming code by using a row-major pre multiplication matrix: mul(normalmap, i.tangentToWorld)
    // i.tangetToWorld was initialized as column-major in vs and here dot'ing individual for better performance.
    // The code below is similar to post multiply: mul(i.tangentToWorld, normalmap)
    normal = half3(dot(normalmap, i.tangentToWorld0), dot(normalmap, i.tangentToWorld1), dot(normalmap, i.tangentToWorld2));
#else
    normal = normalize(i.normal);
#endif
}

inline void SpecularGloss(half2 uv, half alpha, out half4 specularGloss)
{
#ifdef _SPECGLOSSMAP
    specularGloss = tex2D(_SpecGlossMap, uv);
#if defined(UNITY_COLORSPACE_GAMMA) && defined(LIGHTWEIGHT_LINEAR)
    specularGloss.rgb = LIGHTWEIGHT_GAMMA_TO_LINEAR(specularGloss.rgb);
#endif
#elif defined(_SPECGLOSSMAP_BASE_ALPHA)
    specularGloss = LIGHTWEIGHT_GAMMA_TO_LINEAR(tex2D(_SpecGlossMap, uv).rgb) * _SpecColor.rgb;
    specularGloss.a = alpha;
#else
    specularGloss = _SpecColor;
#endif
}

half2 MetallicGloss(float2 uv, half glossiness)
{
    half2 mg;

#ifdef _METALLICGLOSSMAP
#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
    mg.r = tex2D(_MetallicGlossMap, uv).r;
    mg.g = glossiness;
#else
    mg = tex2D(_MetallicGlossMap, uv).ra;
#endif
    mg.g *= _GlossMapScale;

#else // _METALLICGLOSSMAP

    mg.r = _Metallic;
#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
    mg.g = glossiness * _GlossMapScale;
#else
    mg.g = glossiness;
#endif
#endif

    return mg;
}

#endif