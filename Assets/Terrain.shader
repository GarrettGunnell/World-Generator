// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Terrain" {
    Properties {
        _Albedo ("Albedo", Color) = (1, 1, 1)
        _TessellationEdgeLength ("Tessellation Edge Length", Range(5, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "Height Map" {}
        _DisplacementStrength ("Displacement Strength", Range(0.1, 10000)) = 5
    }

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
            float _TessellationEdgeLength;
            float _DisplacementStrength;

            sampler2D _HeightMap;
            float4 _HeightMap_TexelSize;

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
                
                float displacement = tex2Dlod(_HeightMap, float4(v.uv, 0, 0));
                displacement = displacement * _DisplacementStrength;
                
                v.vertex.xyz += v.normal * displacement;

                g.pos = UnityObjectToClipPos(v.vertex);
                g.normal = mul(unity_ObjectToWorld, v.normal);
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

            struct TessellationFactors {
                float edge[3] : SV_TESSFACTOR;
                float inside : SV_INSIDETESSFACTOR;
            };

            float TessellationHeuristic(float3 cp0, float3 cp1) {
                float edgeLength = distance(cp0, cp1);
                float3 edgeCenter = (cp0 + cp1) * 0.5;
                float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

                return edgeLength * _ScreenParams.y / (_TessellationEdgeLength * viewDistance);
            }

            TessellationFactors PatchFunction(InputPatch<TessellationControlPoint, 3> patch) {
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

                float2 du = float2(_HeightMap_TexelSize.x * 0.5, 0);
                float u1 = tex2D(_HeightMap, f.data.uv - du);
                float u2 = tex2D(_HeightMap, f.data.uv + du);
                float3 tu = float3(1, u1 - u2, 0);

                float2 dv = float2(0, _HeightMap_TexelSize.y * 0.5);
                float v1 = tex2D(_HeightMap, f.data.uv - dv);
                float v2 = tex2D(_HeightMap, f.data.uv + dv);
                float3 tv = float3(0, v1 - v2, 1);

                f.data.normal = cross(tv, tu);
                float attenuation = tex2D(_ShadowMapTexture, f.data.shadowCoords.xy / f.data.shadowCoords.w);

                return _Albedo * attenuation * dot(lightDir, normalize(f.data.normal));
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

            #pragma vertex vp
            #pragma fragment fp

            struct VertexData {
                float4 position : POSITION;
                float3 normal : NORMAL;
            };

            float4 vp(VertexData v) : SV_POSITION {
                float4 position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);

                return UnityApplyLinearShadowBias(position);
            }

            half4 fp() : SV_TARGET {
                return 0;
            }

            ENDCG
        }
    }
}
