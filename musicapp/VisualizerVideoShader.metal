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
    float midP = clamp(u.mid, 0.0, 1.0);
    float highP = clamp(u.high, 0.0, 1.0);
    float speedP = clamp(u.speed, 0.35, 2.5);

    float2 size = float2(u.viewWidth, u.viewHeight);
    float2 px = uv * size;

    float scanRow = floor(uv.y * u.viewHeight);
    float wobble = sin(u.time * 2.6 + scanRow * 0.035 + u.hue * 6.28) * (0.55 + bassP * 1.2);
    float jitter = sin(u.time * 10.5 + uv.y * 36.0) * highP * 0.32;
    float xOff = (wobble + jitter) * (0.55 + u.chroma * 44.0) * speedP;
    float yOff = sin(u.time * 0.88 + uv.x * 7.0 + u.grain * 4.0) * midP * speedP;

    float zoom = 1.0 + bassP * 0.035 * speedP;
    float2 centeredPx = px - size * 0.5;
    float2 warpedPx = centeredPx / zoom + size * 0.5 + float2(xOff, yOff);
    float2 warpedUV = warpedPx / size;

    float2 centered = uv - 0.5;
    centered.x *= viewAspect;
    float dist = length(centered);

    float chromaPx = u.chroma * u.viewWidth * (1.0 + highP * 2.2);
    float2 chromaOffset = float2(chromaPx, 0.0) / size;

    float3 center = videoTexture.sample(texSampler, warpedUV).rgb;
    float r = videoTexture.sample(texSampler, warpedUV + chromaOffset).r;
    float b = videoTexture.sample(texSampler, warpedUV - chromaOffset).b;
    float3 col = float3(r, center.g, b);

    float3 tint = hueShift(u.hue, 0.42, 0.12);
    col = mix(col, col * (1.0 + tint), 0.18 + bassP * 0.16);
    col = floor(col * 30.0) / 30.0;

    float g = hash21(px + float2(u.time * 37.7, u.time * 91.3));
    float g2 = hash21(px * 1.37 + float2(u.time * 13.0, 0.0));
    col += (g - 0.5) * u.grain * 0.24;
    col += (g2 - 0.5) * u.grain * 0.08;

    float scan = 0.93 + 0.07 * sin(uv.y * u.viewHeight * 3.14159);
    col *= scan;
    col *= 1.0 - dist * 0.30;

    float luma = dot(col, float3(0.299, 0.587, 0.114));
    col = mix(float3(luma), col, u.satBoost);

    return float4(clamp(col, 0.0, 1.0), 1.0);
}
