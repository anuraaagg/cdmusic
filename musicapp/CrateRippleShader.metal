#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Crate vinyl tap — slow, diffuse bulge (low speed / low frequency) reads as soft water, not shock.
constant float kAmplitude = 2.1;
constant float kFrequency = 6.2;
constant float kDecay = 2.05;
constant float kSpeed = 440.0;

static float2 rippleOffset(float2 position, float2 origin, float time) {
    float2 delta = position - origin;
    float dist = length(delta);

    if (dist < 0.001 || time <= 0.0) {
        return float2(0.0);
    }

    float wavefront = time * kSpeed;
    float phase = dist - wavefront;
    /// Very wide band so one slow swell dominates instead of crisp rings.
    float envelope = exp(-abs(phase) * 0.0032) * exp(-time * kDecay);
    float wave = sin(phase * kFrequency * 0.0068) * envelope;

    float2 dir = delta / dist;
    return dir * wave * kAmplitude * 0.28;
}

static float2 barrelOffset(float2 position, float width, float height, float velocity) {
    if (width < 1.0 || height < 1.0) {
        return float2(0.0);
    }

    float2 uv = position / float2(width, height);
    float2 centered = uv - 0.5;

    float strength = clamp(abs(velocity) * 0.000045, 0.0, 0.022);
    float skew = clamp(velocity * 0.000018, -0.014, 0.014);

    float x2 = centered.x * centered.x;
    centered.y *= 1.0 + strength * (1.0 - x2 * 1.35);
    centered.x += skew * (1.0 - abs(centered.y) * 1.4);

    float2 warpedUV = centered + 0.5;
    return (warpedUV - uv) * float2(width, height);
}

/// Tap ripples + scroll barrel warp.
[[ stitchable ]]
float2 crateVinylDistortion(
    float2 position,
    float4 wave0,
    float4 wave1,
    float4 wave2,
    float4 wave3,
    float width,
    float height,
    float velocity
) {
    float2 offset = barrelOffset(position, width, height, velocity);

    if (wave0.z > 0.0) { offset += rippleOffset(position, wave0.xy, wave0.z); }
    if (wave1.z > 0.0) { offset += rippleOffset(position, wave1.xy, wave1.z); }
    if (wave2.z > 0.0) { offset += rippleOffset(position, wave2.xy, wave2.z); }
    if (wave3.z > 0.0) { offset += rippleOffset(position, wave3.xy, wave3.z); }

    return position + offset;
}

/// Horizontal motion streak on fast flings.
[[ stitchable ]]
half4 crateMotionBlur(
    float2 position,
    SwiftUI::Layer layer,
    float width,
    float height,
    float velocity
) {
    float blurAmount = clamp(abs(velocity) * 0.00032, 0.0, 16.0);
    if (blurAmount < 0.35) {
        return layer.sample(position);
    }

    float2 dir = float2(-sign(velocity), 0.0);
    if (dir.x == 0.0) {
        dir.x = 1.0;
    }

    half4 accum = half4(0.0);
    float weightSum = 0.0;
    const int sampleCount = 6;

    for (int i = -sampleCount; i <= sampleCount; i++) {
        float t = float(i) / float(sampleCount);
        float w = 1.0 - abs(t);
        float2 samplePos = position + dir * blurAmount * t;
        accum += layer.sample(samplePos) * w;
        weightSum += w;
    }

    return accum / max(weightSum, 0.001);
}
