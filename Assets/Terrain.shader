Shader "Custom/Terrain" {
    Properties {
        _Albedo ("Albedo", Color) = (1, 1, 1)
        _TessellationEdgeLength ("Tessellation Edge Length", Range(5, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "Height Map" {}
        _DisplacementStrength ("Displacement Strength", Range(0.1, 10)) = 5
    }

    SubShader {

        Pass {
            CGPROGRAM

            #pragma target 5.0
            
            #pragma vertex dummyvp
            #pragma hull hp
            #pragma domain dp
            #pragma geometry gp
            #pragma fragment fp

            float3 _Albedo;
            float _TessellationEdgeLength;
            float _DisplacementStrength;

            sampler2D _HeightMap;

            struct TessellationControlPoint {
                float4 vertex : INTERNALTESSPOS;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct VertexData {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct v2g {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
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
                v.normal = normalize(v.normal);
                v.vertex.xyz += v.normal * displacement;

                g.pos = UnityObjectToClipPos(v.vertex);
                g.normal = mul(unity_ObjectToWorld, v.normal);
                g.normal = normalize(g.normal);
                g.tangent = v.tangent;

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

            float4 fp(g2f f) : SV_TARGET {
                return float4(_Albedo, 1);
            }

            ENDCG
        }
    }
}
