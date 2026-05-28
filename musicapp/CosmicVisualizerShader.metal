#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

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

/// Cosmic VHS composite — nebula, starburst, CD, grain, chromatic fringe.
[[ stitchable ]]
half4 cosmicVHS(
    float2 position,
    half4 color,
    float width,
    float height,
    float time,
    float bass,
    float mid,
    float high,
    float hue,
    float bloom,
    float grainAmt,
    float chroma,
    float spinDeg,
    float satBoost
) {
    if (width < 1.0 || height < 1.0) {
        return half4(0.0, 0.0, 0.0, 1.0);
    }

    float2 uv = position / float2(width, height);
    float2 centered = uv - 0.5;
    float aspect = width / height;
    centered.x *= aspect;

    float spin = spinDeg * (3.14159265 / 180.0);
    float cs = cos(spin);
    float sn = sin(spin);
    float2 discUV = float2(centered.x * cs - centered.y * sn, centered.x * sn + centered.y * cs);

    float dist = length(centered);
    float bassP = clamp(bass, 0.0, 1.0);
    float midP = clamp(mid, 0.0, 1.0);
    float highP = clamp(high, 0.0, 1.0);

    // Nebula wash
    float2 nebCenter = float2(0.08 * sin(time * 0.31), -0.06 * cos(time * 0.27));
    float neb = exp(-length(centered - nebCenter) * (2.8 - midP * 0.9));
    float3 col = hueShift(hue, 0.72, 0.12 + neb * (0.55 + bassP * 0.35)) * neb;

    // Star field
    for (int i = 0; i < 18; i++) {
        float fi = float(i);
        float2 star = float2(
            hash21(float2(fi, 1.7)),
            hash21(float2(fi, 4.3))
        );
        star = star * 2.0 - 1.0;
        star.x *= aspect;
        float sd = length(centered - star * 0.42);
        float tw = 0.5 + 0.5 * sin(time * 3.1 + fi * 2.17);
        col += float3(1.0) * exp(-sd * 120.0) * (0.08 + highP * 0.12) * tw;
    }

    // Starburst rays
    float angle = atan2(centered.y, centered.x);
    float rays = abs(sin(angle * 6.0 + spin * 0.5));
    rays = pow(rays, 8.0);
    float flare = rays * exp(-dist * (3.2 - bassP * 1.1)) * bloom;
    col += hueShift(hue + 0.05, 0.65, 1.0) * flare * (0.35 + bassP * 0.4);

    // Spinning iridescent disc
    float discR = 0.19 + bassP * 0.04;
    float discD = length(discUV);
    float discMask = smoothstep(discR + 0.01, discR - 0.02, discD);
    float ang = atan2(discUV.y, discUV.x);
    float spec = 0.5 + 0.5 * sin(ang * 5.0 + spin * 2.0 + midP * 4.0);
    float3 discCol = mix(
        float3(0.92, 0.94, 0.98),
        hueShift(hue + 0.08, 0.55, 0.95),
        spec
    );
    col = mix(col, discCol, discMask);

    // Bloom bleed on highlights
    float lum = dot(col, float3(0.299, 0.587, 0.114));
    col += col * smoothstep(0.45, 1.0, lum) * bloom * (0.25 + bassP * 0.35);

    // VHS grain
    float g = hash21(position + float2(time * 47.0, time * 19.0));
    col += (g - 0.5) * grainAmt * 0.22;

    // Chromatic aberration on bright edges
    float2 ca = normalize(centered + 0.0001) * chroma * (0.002 + highP * 0.004) * dist;
    col.r += exp(-length(centered - ca) * 8.0) * highP * 0.08;
    col.b += exp(-length(centered + ca) * 8.0) * highP * 0.08;

    col = clamp(col, 0.0, 1.0);

    // Boost saturation for vivid VHS television look.
    float luma = dot(col, float3(0.299, 0.587, 0.114));
    col = mix(float3(luma), col, satBoost);

    return half4(half3(col), 1.0);
}

/// Geometric VHS warp — safe on AVPlayerLayer (distortionEffect, not layerEffect).
[[ stitchable ]]
float2 videoVHSWarp(
    float2 position,
    float width,
    float height,
    float time,
    float bass,
    float mid,
    float high,
    float hue,
    float grainAmt,
    float chroma,
    float speed
) {
    if (width < 1.0 || height < 1.0) {
        return position;
    }

    float2 size = float2(width, height);
    float2 uv = position / size;

    float bassP = clamp(bass, 0.0, 1.0);
    float midP = clamp(mid, 0.0, 1.0);
    float highP = clamp(high, 0.0, 1.0);
    float speedP = clamp(speed, 0.35, 2.5);

    float scanRow = floor(uv.y * height);
    float wobble = sin(time * 2.6 + scanRow * 0.035 + hue * 6.28) * (0.55 + bassP * 1.2);
    float jitter = sin(time * 10.5 + uv.y * 36.0) * highP * 0.32;
    float xOff = (wobble + jitter) * (0.55 + chroma * 44.0) * speedP;
    float yOff = sin(time * 0.88 + uv.x * 7.0 + grainAmt * 4.0) * midP * 1.0 * speedP;

    float zoom = 1.0 + bassP * 0.035 * speedP;
    float2 centered = position - size * 0.5;
    float2 warped = centered / zoom + size * 0.5;
    return warped + float2(xOff, yOff);
}

/// Per-pixel VHS grade — works as colorEffect on video (no layer sampling).
[[ stitchable ]]
half4 videoVHSColor(
    float2 position,
    half4 color,
    float width,
    float height,
    float time,
    float bass,
    float mid,
    float high,
    float hue,
    float grainAmt,
    float chroma,
    float satBoost
) {
    if (width < 1.0 || height < 1.0) {
        return color;
    }

    float2 uv = position / float2(width, height);
    float2 centered = uv - 0.5;
    centered.x *= width / height;
    float dist = length(centered);

    float bassP = clamp(bass, 0.0, 1.0);
    float highP = clamp(high, 0.0, 1.0);

    float3 col = float3(color.rgb);

    float edge = smoothstep(0.12, 0.58, dist);
    col.r += edge * chroma * 42.0 * (0.5 + highP);
    col.b -= edge * chroma * 42.0 * (0.5 + highP);

    float3 tint = hueShift(hue, 0.42, 0.12);
    col = mix(col, col * (1.0 + tint), 0.18 + bassP * 0.16);

    col = floor(col * 30.0) / 30.0;

    float g = hash21(position + float2(time * 37.7, time * 91.3));
    float g2 = hash21(position * 1.37 + float2(time * 13.0, 0.0));
    col += (g - 0.5) * grainAmt * 0.24;
    col += (g2 - 0.5) * grainAmt * 0.08;

    float scan = 0.93 + 0.07 * sin(uv.y * height * 3.14159);
    col *= scan;
    col *= 1.0 - dist * 0.30;

    float luma = dot(col, float3(0.299, 0.587, 0.114));
    col = mix(float3(luma), col, satBoost);

    col = clamp(col, 0.0, 1.0);
    return half4(half3(col), color.a);
}

/// Post-process for bundled visualizer clips — warp, chroma, grain (no procedural rays).
[[ stitchable ]]
half4 videoVHS(
    float2 position,
    SwiftUI::Layer layer,
    float width,
    float height,
    float time,
    float bass,
    float mid,
    float high,
    float hue,
    float grainAmt,
    float chroma,
    float satBoost
) {
    if (width < 1.0 || height < 1.0) {
        return half4(0.0, 0.0, 0.0, 1.0);
    }

    float2 size = float2(width, height);
    float2 uv = position / size;
    float aspect = width / height;
    float2 centered = uv - 0.5;
    centered.x *= aspect;
    float dist = length(centered);

    float bassP = clamp(bass, 0.0, 1.0);
    float midP = clamp(mid, 0.0, 1.0);
    float highP = clamp(high, 0.0, 1.0);

    float scanRow = floor(uv.y * size.y);
    float wobble = sin(time * 2.6 + scanRow * 0.035) * (0.6 + bassP * 1.4);
    float jitter = sin(time * 10.5 + uv.y * 36.0) * highP * 0.35;
    float xOff = (wobble + jitter) * (0.7 + chroma * 36.0);
    float yOff = sin(time * 0.88 + uv.x * 7.0) * midP * 1.1;

    float zoom = 1.0 + bassP * 0.04;
    float2 centeredPx = position - size * 0.5;
    float2 samplePos = centeredPx / zoom + size * 0.5;
    samplePos.x += xOff;
    samplePos.y += yOff;

    float chromaPx = chroma * size.x * (1.0 + highP * 2.2);
    half4 center = layer.sample(samplePos);
    half r = layer.sample(samplePos + float2(chromaPx, 0.0)).r;
    half b = layer.sample(samplePos - float2(chromaPx, 0.0)).b;
    float3 col = float3(r, center.g, b);

    float3 tint = hueShift(hue, 0.38, 0.14);
    col = mix(col, col * (1.0 + tint), 0.16 + bassP * 0.14);

    col = floor(col * 30.0) / 30.0;

    float g = hash21(position + float2(time * 37.7, time * 91.3));
    float g2 = hash21(position * 1.37 + float2(time * 13.0, 0.0));
    col += (g - 0.5) * grainAmt * 0.26;
    col += (g2 - 0.5) * grainAmt * 0.09;

    float scan = 0.93 + 0.07 * sin(uv.y * size.y * 3.14159);
    col *= scan;
    col *= 1.0 - dist * 0.34;

    float luma = dot(col, float3(0.299, 0.587, 0.114));
    col = mix(float3(luma), col, satBoost);

    col = clamp(col, 0.0, 1.0);
    return half4(half3(col), center.a);
}
