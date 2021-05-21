﻿

Shader "Custom/Terrain" {
    Properties {
        _Albedo ("Albedo", Color) = (1, 1, 1)
        _TessellationEdgeLength ("Tessellation Edge Length", Range(1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "Height Map" {}
        [NoScaleOffset] _NormalMap ("Normal Map", 2D) = "Normal Map" {}
        _DisplacementStrength ("Displacement Strength", Range(0.1, 20000)) = 5
    }

    CGINCLUDE
        float _TessellationEdgeLength;
        float _DisplacementStrength;

        sampler2D _HeightMap;
        float4 _HeightMap_TexelSize;

        struct TessellationFactors {
            float edge[3] : SV_TESSFACTOR;
            float inside : SV_INSIDETESSFACTOR;
        };

        float TessellationHeuristic(float3 cp0, float3 cp1) {
            float edgeLength = distance(cp0, cp1);
            float3 edgeCenter = (cp0 + cp1) * 0.5;
            float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

            return edgeLength * _ScreenParams.y / (_TessellationEdgeLength * (viewDistance * 0.5));
        }
        bool TriangleIsBelowClipPlane(float3 p0, float3 p1, float3 p2, int planeIndex, float bias) {
            float4 plane = unity_CameraWorldClipPlanes[planeIndex];

            return dot(float4(p0, 1), plane) < bias && dot(float4(p1, 1), plane) < bias && dot(float4(p2, 1), plane) < bias;
        }

        bool cullTriangle(float3 p0, float3 p1, float3 p2, float bias) {
            return TriangleIsBelowClipPlane(p0, p1, p2, 0, bias) ||
                   TriangleIsBelowClipPlane(p0, p1, p2, 1, bias) ||
                   TriangleIsBelowClipPlane(p0, p1, p2, 2, bias) ||
                   TriangleIsBelowClipPlane(p0, p1, p2, 3, -0.9 * _DisplacementStrength);
        }
    ENDCG

    SubShader {
        Pass {
            Tags {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM
            
            #pragma target 5.0

            #define SHADOWS_SCREEN
            
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"
            
            #pragma vertex dummyvp
            #pragma hull hp
            #pragma domain dp
            #pragma geometry gp
            #pragma fragment fp

            float3 _Albedo;
            sampler2D _NormalMap;

            struct TessellationControlPoint {
                float4 vertex : INTERNALTESSPOS;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct VertexData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct v2g {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 shadowCoords : TEXCOORD1;
                float4 objectPos : TEXCOORD2;
            };

            TessellationControlPoint dummyvp(VertexData v) {
                TessellationControlPoint p;
                p.vertex = v.vertex;
                p.normal = v.normal;
                p.uv = v.uv;
                p.tangent = v.tangent;

                return p;
            }

            v2g vp(VertexData v) {
                v2g g;
                
                float displacement = tex2Dlod(_HeightMap, float4(v.uv, 0, 0)).r;
                displacement = displacement * _DisplacementStrength;
                
                v.vertex.xyz += v.normal * displacement;

                float3 gradient = tex2Dlod(_HeightMap, float4(v.uv, 0, 0)).yzw;
                g.normal = float3(gradient.x, 1, gradient.y);

                g.pos = UnityObjectToClipPos(v.vertex);
                g.objectPos = v.vertex;
                //g.normal = mul(unity_ObjectToWorld, v.normal);
                g.normal = normalize(g.normal);
                g.shadowCoords = v.vertex;
                g.shadowCoords.xy = (float2(g.pos.x, -g.pos.y) + g.pos.w) * 0.5;
                g.shadowCoords.zw = g.pos.zw;
                g.uv = v.uv;

                return g;
            }

            struct g2f {
                v2g data;
                float2 barycentricCoordinates : TEXCOORD9;
            };

            TessellationFactors PatchFunction(InputPatch<TessellationControlPoint, 3> patch) {
                float3 p0 = mul(unity_ObjectToWorld, patch[0].vertex);
                float3 p1 = mul(unity_ObjectToWorld, patch[1].vertex);
                float3 p2 = mul(unity_ObjectToWorld, patch[2].vertex);

                TessellationFactors f;
                float bias = -0.5 * _DisplacementStrength;
                if (cullTriangle(p0, p1, p2, bias)) {
                    f.edge[0] = f.edge[1] = f.edge[2] = f.inside = 0;
                } else {
                    f.edge[0] = TessellationHeuristic(p1, p2);
                    f.edge[1] = TessellationHeuristic(p2, p0);
                    f.edge[2] = TessellationHeuristic(p0, p1);
                    f.inside = (TessellationHeuristic(p1, p2) +
                                TessellationHeuristic(p2, p0) +
                                TessellationHeuristic(p1, p2)) * (1 / 3.0);
                }
                return f;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("integer")]
            [UNITY_patchconstantfunc("PatchFunction")]
            TessellationControlPoint hp(InputPatch<TessellationControlPoint, 3> patch, uint id : SV_OUTPUTCONTROLPOINTID) {
                return patch[id];
            }

            [maxvertexcount(3)]
            void gp(triangle v2g g[3], inout TriangleStream<g2f> stream) {
                g2f g0, g1, g2;
                g0.data = g[0];
                g1.data = g[1];
                g2.data = g[2];

                g0.barycentricCoordinates = float2(1, 0);
                g1.barycentricCoordinates = float2(0, 1);
                g2.barycentricCoordinates = float2(0, 0);

                stream.Append(g0);
                stream.Append(g1);
                stream.Append(g2);
            }

            #define DP_INTERPOLATE(fieldName) data.fieldName = \
                data.fieldName = patch[0].fieldName * barycentricCoordinates.x + \
                                 patch[1].fieldName * barycentricCoordinates.y + \
                                 patch[2].fieldName * barycentricCoordinates.z;               

            [UNITY_domain("tri")]
            v2g dp(TessellationFactors factors, OutputPatch<TessellationControlPoint, 3> patch, float3 barycentricCoordinates : SV_DOMAINLOCATION) {
                VertexData data;
                DP_INTERPOLATE(vertex)
                DP_INTERPOLATE(normal)
                DP_INTERPOLATE(tangent)
                DP_INTERPOLATE(uv)

                return vp(data);
            }

            float3 fp(g2f f) : SV_TARGET {
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float attenuation = tex2D(_ShadowMapTexture, f.data.shadowCoords.xy / f.data.shadowCoords.w);

                float3 grad = tex2D(_HeightMap, f.data.uv).yzw;
                float3 normal = normalize(float3(grad.x, 1, grad.y));

                float normalContribution = DotClamped(lightDir, normal);

                return _Albedo * attenuation * normalContribution;
            }

            ENDCG
        }

        Pass {
            Tags {
                "LightMode" = "ShadowCaster"
            }

            CGPROGRAM
            
            #pragma target 5.0

            #include "UnityStandardBRDF.cginc"
			#include "UnityStandardUtils.cginc"

            #pragma vertex dummyvp
            #pragma hull hp
            #pragma domain dp
            #pragma fragment fp

            struct ShadowTessControlPoint {
                float4 vertex : INTERNALTESSPOS;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct VertexData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            ShadowTessControlPoint dummyvp(VertexData v) {
                ShadowTessControlPoint p;
                p.vertex = v.vertex;
                p.normal = v.normal;
                p.uv = v.uv;

                return p;
            };

            v2f vp(VertexData v) {
                v2f f;
                float displacement = tex2Dlod(_HeightMap, float4(v.uv.xy, 0, 0)).r;
                displacement = displacement * _DisplacementStrength;
                v.normal = normalize(v.normal);
                v.vertex.xyz += v.normal * displacement;

                f.pos = UnityClipSpaceShadowCasterPos(v.vertex.xyz, v.normal);
                f.pos = UnityApplyLinearShadowBias(f.pos);
                f.uv = v.uv;

                return f;
            }

            TessellationFactors PatchFunction(InputPatch<ShadowTessControlPoint, 3> patch) {
                float3 p0 = mul(unity_ObjectToWorld, patch[0].vertex);
                float3 p1 = mul(unity_ObjectToWorld, patch[1].vertex);
                float3 p2 = mul(unity_ObjectToWorld, patch[2].vertex);

                TessellationFactors f;
                    f.edge[0] = TessellationHeuristic(p1, p2);
                    f.edge[1] = TessellationHeuristic(p2, p0);
                    f.edge[2] = TessellationHeuristic(p0, p1);
                    f.inside = (TessellationHeuristic(p1, p2) +
                                TessellationHeuristic(p2, p0) +
                                TessellationHeuristic(p1, p2)) * (1 / 3.0);
                
                return f;
            }

            [UNITY_domain("tri")]
            [UNITY_outputcontrolpoints(3)]
            [UNITY_outputtopology("triangle_cw")]
            [UNITY_partitioning("integer")]
            [UNITY_patchconstantfunc("PatchFunction")]
            ShadowTessControlPoint hp(InputPatch<ShadowTessControlPoint, 3> patch, uint id : SV_OUTPUTCONTROLPOINTID) {
                return patch[id];
            }

            #define DP_INTERPOLATE(fieldName) data.fieldName = \
                data.fieldName = patch[0].fieldName * barycentricCoordinates.x + \
                                 patch[1].fieldName * barycentricCoordinates.y + \
                                 patch[2].fieldName * barycentricCoordinates.z;

            [UNITY_domain("tri")]
            v2f dp(TessellationFactors factors, OutputPatch<ShadowTessControlPoint, 3> patch, float3 barycentricCoordinates : SV_DOMAINLOCATION) {
                VertexData data;
                DP_INTERPOLATE(vertex)
                DP_INTERPOLATE(normal)
                DP_INTERPOLATE(uv)

                return vp(data);
            }

            half4 fp() : SV_TARGET {
                return 0;
            }

            ENDCG
        }
    }
}
