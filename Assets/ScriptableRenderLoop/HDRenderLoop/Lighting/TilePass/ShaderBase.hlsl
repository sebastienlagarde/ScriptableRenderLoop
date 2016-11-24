#ifndef __SHADERBASE_H__
#define __SHADERBASE_H__

#ifdef SHADER_API_PSSL

#ifndef Texture2DMS
	#define Texture2DMS		MS_Texture2D
#endif

#ifndef SampleCmpLevelZero
	#define SampleCmpLevelZero				SampleCmpLOD0
#endif

#ifndef firstbithigh
	#define firstbithigh		FirstSetBit_Hi
#endif

#endif

float FetchDepth(Texture2D depthTexture, uint2 pixCoord)
{
    return 1 - LOAD_TEXTURE2D(depthTexture, uint3(pixCoord.xy, 0)).x;
}

float FetchDepthMSAA(Texture2DMS<float> depthTexture, uint2 pixCoord, uint sampleIdx)
{
    return 1 - LOAD_TEXTURE2D_MSAA(depthTexture, uint3(pixCoord.xy, 0), sampleIdx).x;
}

#endif