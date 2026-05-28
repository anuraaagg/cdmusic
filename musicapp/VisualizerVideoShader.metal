#include <metal_stdlib>
using namespace metal;

struct VisualizerUniforms {
    float time;
    float bass;
    float mid;
    float high;
    float hue;
    float grain;
    float chroma;
    float speed;
    float satBoost;
    float viewWidth;
    float viewHeight;
    float videoWidth;
    float videoHeight;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

static float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float3 hueShift(float hue, float sat, float bri) {
    float h = fract(hue) * 6.0;
    float c = bri * sat;
    float x = c * (1.0 - abs(fmod(h, 2.0) - 1.0));
    float m = bri - c;
    float3 rgb;
    if (h < 1.0) rgb = float3(c, x, 0.0);
    else if (h < 2.0) rgb = float3(x, c, 0.0);
    else if (h < 3.0) rgb = float3(0.0, c, x);
    else if (h < 4.0) rgb = float3(0.0, x, c);
    else if (h < 5.0) rgb = float3(x, 0.0, c);
    else rgb = float3(c, 0.0, x);
    return rgb + m;
}

static float2 aspectFillUV(float2 uv, float viewAspect, float videoAspect) {
    if (videoAspect <= 0.0001 || viewAspect <= 0.0001) {
        return uv;
    }
    float2 result = uv;
    if (videoAspect > viewAspect) {
        float scale = viewAspect / videoAspect;
        result.x = (uv.x - 0.5) / scale + 0.5;
    } else {
        float scale = videoAspect / viewAspect;
        result.y = (uv.y - 0.5) / scale + 0.5;
    }
    return result;
}

vertex VertexOut visualizerVideoVertex(uint vid [[vertex_id]]) {
    const float2 positions[4] = { {-1.0, -1.0}, {1.0, -1.0}, {-1.0, 1.0}, {1.0, 1.0} };
    const float2 uvs[4] = { {0.0, 1.0}, {1.0, 1.0}, {0.0, 0.0}, {1.0, 0.0} };

    VertexOut out;
    out.position = float4(positions[vid], 0.0, 1.0);
    out.uv = uvs[vid];
    return out;
}

/// Clean VHS grade — stable picture, subtle fringe + grain (no heavy warp).
fragment float4 visualizerVideoFragment(
    VertexOut in [[stage_in]],
    texture2d<float> videoTexture [[texture(0)]],
    constant VisualizerUniforms& u [[buffer(0)]]
) {
    constexpr sampler texSampler(filter::linear, address::clamp_to_edge);

    float viewAspect = u.viewWidth / max(u.viewHeight, 1.0);
    float videoAspect = u.videoWidth / max(u.videoHeight, 1.0);
    float2 uv = aspectFillUV(in.uv, viewAspect, videoAspect);

    float bassP = clamp(u.bass, 0.0, 1.0);
    float highP = clamp(u.high, 0.0, 1.0);

    float2 centered = uv - 0.5;
    centered.x *= viewAspect;
    float dist = length(centered);

    // Occasional tracking-line shimmer — sub-pixel, not full-frame morph.
    float trackY = fract(u.time * 0.11);
    float nearTrack = exp(-abs(uv.y - trackY) * 28.0);
    float2 sampleUV = uv;
    sampleUV.x += nearTrack * sin(u.time * 9.0 + uv.y * 40.0) * 0.00035 * (0.4 + bassP * 0.6);

    // Edge-weighted chromatic fringe (1–2 px feel), not global split.
    float edge = smoothstep(0.28, 0.82, dist);
    float2 chromaOffset = float2(u.chroma * edge * (0.55 + highP * 0.45), 0.0);

    float3 center = videoTexture.sample(texSampler, sampleUV).rgb;
    float r = videoTexture.sample(texSampler, sampleUV + chromaOffset).r;
    float b = videoTexture.sample(texSampler, sampleUV - chromaOffset).b;
    float3 col = float3(r, center.g, b);

    // Gentle channel tint — color grade, not a second image.
    float3 tint = hueShift(u.hue, 0.22, 0.05);
    col = mix(col, col + tint * 0.06, 0.10 + bassP * 0.06);

    // Fine film grain (shader only — keep overlays light).
    float2 px = uv * float2(u.viewWidth, u.viewHeight);
    float g = hash21(px + float2(u.time * 19.0, u.time * 7.0));
    col += (g - 0.5) * u.grain * 0.09;

    // Soft tube falloff.
    col *= 1.0 - dist * 0.16;

    float luma = dot(col, float3(0.299, 0.587, 0.114));
    col = mix(float3(luma), col, u.satBoost);

    return float4(clamp(col, 0.0, 1.0), 1.0);
}
